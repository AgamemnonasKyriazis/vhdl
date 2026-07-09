library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library axi;
use axi.axis.all;
use axi.axi4.all;

entity ls is
    generic (
        DATA_WIDTH  : integer := 32
    );
    port (
        aclk        : in std_logic;
        areset_n    : in std_logic;
        sI          : inout axis_t := AXIS_S_INIT;
        mO          : inout axis_t := AXIS_M_INIT;
        mM          : inout axi4_t := AXI4_M_INIT;

        enable_i    : in  std_logic;

        bd_ld_x_p   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        bd_ld_y_p   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        bd_ld_z_p   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        bd_st_x_p   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        bd_st_y_p   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        bd_st_z_p   : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end ls;

architecture behavioral of ls is

    -- AXI4
    signal awaddr_reg    : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal awburst_reg   : std_logic_vector(1 downto 0) := (others => '0');
    signal awid_reg      : std_logic_vector(AXI_ID_WIDTH-1 downto 0) := (others => '0');
    signal awlen_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal awprot_reg    : std_logic_vector(2 downto 0) := (others => '0');
    signal awsize_reg    : std_logic_vector(2 downto 0) := (others => '0');
    signal awuser_reg    : std_logic_vector(3 downto 0) := (others => '0');
    signal awvalid_reg   : std_logic := '0';

    signal wdata_reg     : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal wlast_reg     : std_logic := '0';
    signal wstrb_reg     : std_logic_vector(AXI_STRB_WIDTH-1 downto 0) := (others => '0');
    signal wvalid_reg    : std_logic := '0';

    signal araddr_reg    : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal arburst_reg   : std_logic_vector(1 downto 0) := (others => '0');
    signal arid_reg      : std_logic_vector(AXI_ID_WIDTH-1 downto 0) := (others => '0');
    signal arlen_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal arprot_reg    : std_logic_vector(2 downto 0) := (others => '0');
    signal arsize_reg    : std_logic_vector(2 downto 0) := (others => '0');
    signal aruser_reg    : std_logic_vector(3 downto 0) := (others => '0');
    signal arvalid_reg   : std_logic := '0';

    signal bready_reg    : std_logic := '0';
    signal rready_reg    : std_logic := '0';

    type loop_controller_3d_state_t is (IDLE, EXEC, INCR, DONE, HALT);
    signal ld_lc_state_q, st_lc_state_q : loop_controller_3d_state_t := IDLE;
    signal ld_lc_state_d, st_lc_state_d : loop_controller_3d_state_t := IDLE;

    type axi_master_state is (WADDR, WDATA, WRESP, WSTOP, RADDR, RDATA, RWAIT, RSTOP);
    signal axi_m_wstate : axi_master_state := WADDR;
    signal axi_m_rstate : axi_master_state := RADDR;

    type cmp_op_t is (LT, LE, GT, GE, NE, EQ);

    function compare(op : cmp_op_t; idx, lim : signed) return boolean is
    begin
    case op is
        when LT => return idx <  lim;
        when LE => return idx <= lim;
        when GT => return idx >  lim;
        when GE => return idx >= lim;
        when NE => return idx /= lim;
        when EQ => return idx  = lim;
    end case;
    end function;

    -- LOAD path configuration registers
    signal reg_ld_base_addr_l   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_base_addr_u   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_x_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_x_stride      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_y_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_y_stride      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_z_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_z_stride      : std_logic_vector(31 downto 0) := (others => '0');

    -- LOAD path count preload registers
    signal reg_ld_x_count_pl    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_y_count_pl    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_z_count_pl    : std_logic_vector(31 downto 0) := (others => '0');

    -- LOAD path count snapshot registers
    signal reg_ld_x_count_ss    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_y_count_ss    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_z_count_ss    : std_logic_vector(31 downto 0) := (others => '0');
    
    -- WRITE path configuration registers
    signal reg_st_base_addr_l   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_base_addr_u   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_x_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_x_stride      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_y_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_y_stride      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_z_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_z_stride      : std_logic_vector(31 downto 0) := (others => '0');

    -- WRITE path preload registers
    signal reg_st_x_count_pl    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_y_count_pl    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_z_count_pl    : std_logic_vector(31 downto 0) := (others => '0');

    -- WRITE path snapshot registers
    signal reg_st_x_count_ss    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_y_count_ss    : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_z_count_ss    : std_logic_vector(31 downto 0) := (others => '0');

    signal ld_data              : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_addr_d            : std_logic_vector(63 downto 0) := (others => '0');
    signal ld_addr_q            : std_logic_vector(63 downto 0) := (others => '0');
    signal ld_x_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_y_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_z_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_x_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_y_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_z_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_done              : std_logic := '0';
    signal ld_loop_nonempty     : boolean   := FALSE;
    signal ld_trans_count       : unsigned(31 downto 0) := (others => '0');

    signal st_data              : std_logic_vector(31 downto 0) := (others => '1');
    signal st_addr_d            : std_logic_vector(63 downto 0) := (others => '0');
    signal st_addr_q            : std_logic_vector(63 downto 0) := (others => '0');
    signal st_x_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_y_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_z_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_x_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_y_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_z_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_done              : std_logic := '0';
    signal st_loop_nonempty     : boolean   := FALSE;
    signal st_trans_count       : unsigned(31 downto 0) := (others => '0');
begin

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                ld_trans_count <= (others => '0');
                st_trans_count <= (others => '0');
            else
                if mM.bvalid = '1' and bready_reg = '1' and wlast_reg = '1' then
                    st_trans_count <= st_trans_count + 1;
                end if;

                if mM.rvalid = '1' and rready_reg = '1' and mM.rlast = '1' then
                    ld_trans_count <= ld_trans_count + 1;
                end if;

            end if;
        end if;
    end process;

    process (all) is
    begin
        -- Inside your architecture initialization or reset block:
        awburst_reg <= "01";    -- INCR burst type
        awsize_reg  <= "010";   -- 4 bytes (32-bit data width)
        awlen_reg   <= x"00";   -- 00 + 1 = 1 single transfer
        awid_reg    <= std_logic_vector(resize(st_trans_count, AXIS_ID_WIDTH));
        awprot_reg  <= "000";   -- Normal, secure, data
        awuser_reg  <= "0000";  -- Clear user sideband flags
        -- During the WDATA state:
        wstrb_reg   <= "1111";  -- Write all 4 bytes of the 32-bit word
        wlast_reg   <= '1';     -- This single transfer is the last transfer
        -- Read Channel
        arburst_reg <= "01";
        arsize_reg  <= "010";
        arlen_reg   <= x"00";
        arid_reg    <= std_logic_vector(resize(ld_trans_count, AXIS_ID_WIDTH));
        arprot_reg  <= "000";


        mO.tvalid       <= '1' when mM.rvalid = '1' else '0';
        mO.tdata.tdata  <= mM.rdata;
        mO.tdata.tlast  <= mM.rlast;
        mO.tdata.tid    <= mM.rid;
    end process;

    ld_loop_nonempty <=
        compare(LT, signed(reg_ld_x_count_pl), signed(reg_ld_x_size)) and
        compare(LT, signed(reg_ld_y_count_pl), signed(reg_ld_y_size)) and
        compare(LT, signed(reg_ld_z_count_pl), signed(reg_ld_z_size));

    ld_addr_d <= std_logic_vector(
        unsigned(reg_ld_base_addr_u & reg_ld_base_addr_l)  +
        unsigned(ld_x_count_q) * unsigned(reg_ld_x_stride) +
        unsigned(ld_y_count_q) * unsigned(reg_ld_y_stride) +
        unsigned(ld_z_count_q) * unsigned(reg_ld_z_stride)
    );

    process (all) is
    variable x_count_next : signed(31 downto 0) := (others => '0');
    variable y_count_next : signed(31 downto 0) := (others => '0');
    variable z_count_next : signed(31 downto 0) := (others => '0');
    begin
        ld_done <= '0';

        x_count_next := signed(ld_x_count_q);
        y_count_next := signed(ld_y_count_q);
        z_count_next := signed(ld_z_count_q);

        ld_x_count_d <= std_logic_vector(x_count_next);
        ld_y_count_d <= std_logic_vector(y_count_next);
        ld_z_count_d <= std_logic_vector(z_count_next);

        x_count_next := signed(ld_x_count_q) + 1;
        if compare(LT, x_count_next, signed(reg_ld_x_size)) then
            ld_x_count_d <= std_logic_vector(x_count_next);
        else
            ld_x_count_d <= reg_ld_x_count_pl;
            y_count_next := signed(ld_y_count_q) + 1;
            if compare(LT, y_count_next, signed(reg_ld_y_size)) then
                ld_y_count_d <= std_logic_vector(y_count_next);
            else
                ld_y_count_d <= reg_ld_y_count_pl;
                z_count_next := signed(ld_z_count_q) + 1;
                if compare(LT, z_count_next, signed(reg_ld_z_size)) then
                    ld_z_count_d <= std_logic_vector(z_count_next);
                else
                    ld_done <= '1';
                end if;
            end if;
        end if;
    end process;

    st_loop_nonempty <=
        compare(LT, signed(reg_st_x_count_pl), signed(reg_st_x_size)) and
        compare(LT, signed(reg_st_y_count_pl), signed(reg_st_y_size)) and
        compare(LT, signed(reg_st_z_count_pl), signed(reg_st_z_size));

    st_addr_d <= std_logic_vector(
        unsigned(reg_st_base_addr_u & reg_st_base_addr_l)  +
        unsigned(st_x_count_q) * unsigned(reg_st_x_stride) +
        unsigned(st_y_count_q) * unsigned(reg_st_y_stride) +
        unsigned(st_z_count_q) * unsigned(reg_st_z_stride)
    );

    process (all) is
    variable x_count_next : signed(31 downto 0) := (others => '0');
    variable y_count_next : signed(31 downto 0) := (others => '0');
    variable z_count_next : signed(31 downto 0) := (others => '0');
    begin
        st_done <= '0';

        x_count_next := signed(st_x_count_q);
        y_count_next := signed(st_y_count_q);
        z_count_next := signed(st_z_count_q);

        st_x_count_d <= std_logic_vector(x_count_next);
        st_y_count_d <= std_logic_vector(y_count_next);
        st_z_count_d <= std_logic_vector(z_count_next);

        x_count_next := signed(st_x_count_q) + 1;
        if compare(LT, x_count_next, signed(reg_st_x_size)) then
            st_x_count_d <= std_logic_vector(x_count_next);
        else
            st_x_count_d <= reg_st_x_count_pl;
            y_count_next := signed(st_y_count_q) + 1;
            if compare(LT, y_count_next, signed(reg_st_y_size)) then
                st_y_count_d <= std_logic_vector(y_count_next);
            else
                st_y_count_d <= reg_st_y_count_pl;
                z_count_next := signed(st_z_count_q) + 1;
                if compare(LT, z_count_next, signed(reg_st_z_size)) then
                    st_z_count_d <= std_logic_vector(z_count_next);
                else
                    st_done <= '1';
                end if;
            end if;
        end if;
    end process;

    process (all) is
    variable all_iter_done : boolean := FALSE;
    variable one_iter_done : boolean := FALSE;
    begin
        all_iter_done := st_done = '1';
        one_iter_done := bready_reg = '1' and mM.bvalid = '1' and mM.bresp = AXI_OKAY;

        case st_lc_state_q is
        when IDLE   =>
            if enable_i = '1' then
                if st_loop_nonempty then
                    st_lc_state_d <= EXEC;
                else
                    st_lc_state_d <= DONE;
                end if;
            end if;
        when EXEC   =>
            if one_iter_done then
                if all_iter_done then
                    st_lc_state_d <= DONE;
                else
                    st_lc_state_d <= INCR;
                end if;
            else
                st_lc_state_d <= EXEC;
            end if;
        when INCR   =>
            if enable_i = '1' then
                st_lc_state_d <= EXEC;
            else
                st_lc_state_d <= HALT;
            end if;
        when DONE   =>
            st_lc_state_d <= DONE;
        when HALT   =>
            if enable_i = '1' then
                st_lc_state_d <= EXEC;
            else
                st_lc_state_d <= HALT;
            end if;
        when others =>
            st_lc_state_d <= st_lc_state_q;
        end case;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                st_lc_state_q <= IDLE;
            else
                st_lc_state_q <= st_lc_state_d;
            end if;
        end if;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                st_x_count_q <= (others => '0');
                st_y_count_q <= (others => '0');
                st_z_count_q <= (others => '0');
            else
                if st_lc_state_q = IDLE and st_lc_state_d = EXEC then
                    st_x_count_q <= reg_st_x_count_pl;
                    st_y_count_q <= reg_st_y_count_pl;
                    st_z_count_q <= reg_st_z_count_pl;
                elsif st_lc_state_q = INCR then
                    st_x_count_q <= st_x_count_d;
                    st_y_count_q <= st_y_count_d;
                    st_z_count_q <= st_z_count_d;
                else
                    st_x_count_q <= st_x_count_q;
                    st_y_count_q <= st_y_count_q;
                    st_z_count_q <= st_z_count_q;
                end if;
            end if;
        end if; 
    end process;

    sI.tready <= '1' when st_lc_state_q = EXEC and axi_m_wstate = WDATA and wvalid_reg = '0' else '0';

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axi_m_wstate <= WADDR;
                awvalid_reg <= '0';
                wvalid_reg <= '0';
                bready_reg <= '0';
            elsif st_lc_state_q = EXEC then
                case axi_m_wstate is
                when WADDR  =>
                    st_addr_q   <= st_addr_d;
                    awaddr_reg  <= st_addr_d(AXI_ADDR_WIDTH-1 downto 0);
                    awvalid_reg <= '1';

                    if mM.awready = '1' and awvalid_reg = '1' then
                        axi_m_wstate <= WDATA;
                        awvalid_reg <= '0';
                    end if;

                when WDATA  =>
                    axi_m_wstate <= WDATA;
                    
                    if wvalid_reg = '0' then
                        wvalid_reg <= sI.tvalid;
                        if sI.tvalid = '1' then
                            wdata_reg <= sI.tdata.tdata;
                        end if;
                    end if;
                    
                    if mM.wready = '1' and wvalid_reg = '1' then
                        axi_m_wstate <= WRESP;
                        wvalid_reg <= '0';
                        bready_reg <= '1';
                    end if;
                when WRESP  =>
                    axi_m_wstate <= WRESP;
                    awvalid_reg <= '0';
                    wvalid_reg <= '0';
                    if mM.bvalid = '1' and mM.bresp = AXI_OKAY then
                        bready_reg <= '0';
                        axi_m_wstate <= WADDR;
                    end if;
                when others =>
                end case;
            end if;
        end if;
    end process;

    process (all) is
    variable one_iter_done : boolean := FALSE;
    variable all_iter_done : boolean := FALSE;
    begin
        one_iter_done := mM.rvalid = '1' and rready_reg = '1';
        all_iter_done := ld_done = '1';

        case (ld_lc_state_q) is
        when IDLE =>
            if enable_i = '1' then
                if ld_loop_nonempty then
                    ld_lc_state_d <= EXEC;
                else
                    ld_lc_state_d <= DONE;
                end if;
            end if;
        when EXEC =>
            if one_iter_done then
                if all_iter_done then
                    ld_lc_state_d <= DONE;
                else
                    ld_lc_state_d <= INCR;
                end if;
            else
                ld_lc_state_d <= EXEC;
            end if;
        when INCR =>
            if enable_i = '1' then
                ld_lc_state_d <= EXEC;
            else
                ld_lc_state_d <= HALT;
            end if;
        when DONE =>
            ld_lc_state_d <= DONE;
        when HALT =>
            if enable_i = '1' then
                ld_lc_state_d <= EXEC;
            else
                ld_lc_state_d <= HALT;
            end if;
        when others =>
            ld_lc_state_d <=ld_lc_state_q;
        end case;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                ld_lc_state_q <= IDLE;
            else
                ld_lc_state_q <= ld_lc_state_d;
            end if;
        end if;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                ld_x_count_q <= (others => '0');
                ld_y_count_q <= (others => '0');
                ld_z_count_q <= (others => '0');
            else
                if ld_lc_state_q = IDLE and ld_lc_state_d = EXEC then
                    ld_x_count_q <= reg_ld_x_count_pl;
                    ld_y_count_q <= reg_ld_y_count_pl;
                    ld_z_count_q <= reg_ld_z_count_pl;
                elsif ld_lc_state_q = INCR then
                    ld_x_count_q <= ld_x_count_d;
                    ld_y_count_q <= ld_y_count_d;
                    ld_z_count_q <= ld_z_count_d;
                else
                    ld_x_count_q <= ld_x_count_q;
                    ld_y_count_q <= ld_y_count_q;
                    ld_z_count_q <= ld_z_count_q;
                end if;
            end if;
        end if; 
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axi_m_rstate <= RADDR;
            elsif ld_lc_state_q = EXEC then
                case axi_m_rstate is
                when RADDR  =>
                    arvalid_reg <= '1';
                    ld_addr_q <= ld_addr_d;
                    araddr_reg <= ld_addr_d(AXI_ADDR_WIDTH-1 downto 0);
                    if arvalid_reg = '1' and mM.arready = '1' then
                        axi_m_rstate <= RDATA;
                        rready_reg <= mO.tready;
                        arvalid_reg <= '0';
                    end if;
                when RDATA  =>
                    rready_reg <= mO.tready;
                    if mM.rvalid = '1' and rready_reg = '1' then
                        rready_reg <= '0';
                        axi_m_rstate <= RADDR;
                    end if;
                when RWAIT  =>
                    
                when others =>
                end case;
            end if;
        end if;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                -- WRITE path snapshot counter registers
                reg_st_x_count_ss <= (others => '0');
                reg_st_y_count_ss <= (others => '0');
                reg_st_z_count_ss <= (others => '0');
                -- READ path snapshot counter registers
                reg_ld_x_count_ss <= (others => '0');
                reg_ld_y_count_ss <= (others => '0');
                reg_ld_z_count_ss <= (others => '0');
            else
                -- WRITE path capture counter registers
                reg_st_x_count_ss <= st_x_count_q;
                reg_st_y_count_ss <= st_y_count_q;
                reg_st_z_count_ss <= st_z_count_q;
                -- READ path capture counter registers
                reg_ld_x_count_ss <= ld_x_count_q;
                reg_ld_y_count_ss <= ld_y_count_q;
                reg_ld_z_count_ss <= ld_z_count_q;
                -- report "captured snapshot";
            end if;
        end if;
    end process;

    -- Internal registers to AXI Output Ports
    mM.awaddr  <= awaddr_reg;
    mM.awburst <= awburst_reg;
    mM.awid    <= awid_reg;
    mM.awlen   <= awlen_reg;
    mM.awprot  <= awprot_reg;
    mM.awsize  <= awsize_reg;
    mM.awuser  <= awuser_reg;
    mM.awvalid <= awvalid_reg;

    mM.wdata   <= wdata_reg;
    mM.wlast   <= wlast_reg;
    mM.wstrb   <= wstrb_reg;
    mM.wvalid  <= wvalid_reg;

    mM.bready  <= bready_reg;

    mM.araddr  <= araddr_reg;
    mM.arburst <= arburst_reg;
    mM.arid    <= arid_reg;
    mM.arlen   <= arlen_reg;
    mM.arprot  <= arprot_reg;
    mM.arsize  <= arsize_reg;
    mM.aruser  <= aruser_reg;
    mM.arvalid <= arvalid_reg;

    mM.rready  <= rready_reg;

end architecture behavioral;
