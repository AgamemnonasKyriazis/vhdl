library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use IEEE.math_real.all;

library axis;
use axis.axis_pkg.all;

entity ls is
    generic (
        DATA_WIDTH      : integer := 32;
        AXI_DATA_WIDTH  : integer := 32;
        AXI_ADDR_WIDTH  : integer := 10;
        AXI_ID_WIDTH    : integer := 8
    );
    port (
        aclk            : in std_logic;
        areset_n        : in std_logic;

        --
        s0_tdata        : in    std_logic_vector(31 downto 0);
        s0_tvalid       : in    std_logic;
        s0_tready       : out   std_logic := '0';
        s0_tlast        : in    std_logic;
        s0_tkeep        : in    std_logic_vector(3 downto 0);
        s0_tid          : in    std_logic_vector(7 downto 0);
        s0_tdest        : in    std_logic_vector(7 downto 0);
        s0_tuser        : in    std_logic_vector(7 downto 0);
        --
        s1_tdata        : in    std_logic_vector(31 downto 0);
        s1_tvalid       : in    std_logic;
        s1_tready       : out   std_logic := '0';
        s1_tlast        : in    std_logic;
        s1_tkeep        : in    std_logic_vector(3 downto 0);
        s1_tid          : in    std_logic_vector(7 downto 0);
        s1_tdest        : in    std_logic_vector(7 downto 0);
        s1_tuser        : in    std_logic_vector(7 downto 0);
        --
        s2_tdata        : in    std_logic_vector(31 downto 0);
        s2_tvalid       : in    std_logic;
        s2_tready       : out   std_logic := '0';
        s2_tlast        : in    std_logic;
        s2_tkeep        : in    std_logic_vector(3 downto 0);
        s2_tid          : in    std_logic_vector(7 downto 0);
        s2_tdest        : in    std_logic_vector(7 downto 0);
        s2_tuser        : in    std_logic_vector(7 downto 0);
        --
        s3_tdata        : in    std_logic_vector(31 downto 0);
        s3_tvalid       : in    std_logic;
        s3_tready       : out   std_logic := '0';
        s3_tlast        : in    std_logic;
        s3_tkeep        : in    std_logic_vector(3 downto 0);
        s3_tid          : in    std_logic_vector(7 downto 0);
        s3_tdest        : in    std_logic_vector(7 downto 0);
        s3_tuser        : in    std_logic_vector(7 downto 0);

        --
        m0_tdata        : out   std_logic_vector(31 downto 0) := (others => '0');
        m0_tvalid       : out   std_logic := '0';
        m0_tready       : in    std_logic;
        m0_tlast        : out   std_logic := '0';
        m0_tkeep        : out   std_logic_vector(3 downto 0) := (others => '0');
        m0_tid          : out   std_logic_vector(7 downto 0) := (others => '0');
        m0_tdest        : out   std_logic_vector(7 downto 0) := (others => '0');
        m0_tuser        : out   std_logic_vector(7 downto 0) := (others => '0');
        --
        m1_tdata        : out   std_logic_vector(31 downto 0) := (others => '0');
        m1_tvalid       : out   std_logic := '0';
        m1_tready       : in    std_logic;
        m1_tlast        : out   std_logic := '0';
        m1_tkeep        : out   std_logic_vector(3 downto 0) := (others => '0');
        m1_tid          : out   std_logic_vector(7 downto 0) := (others => '0');
        m1_tdest        : out   std_logic_vector(7 downto 0) := (others => '0');
        m1_tuser        : out   std_logic_vector(7 downto 0) := (others => '0');
        --
        m2_tdata        : out   std_logic_vector(31 downto 0) := (others => '0');
        m2_tvalid       : out   std_logic := '0';
        m2_tready       : in    std_logic;
        m2_tlast        : out   std_logic := '0';
        m2_tkeep        : out   std_logic_vector(3 downto 0) := (others => '0');
        m2_tid          : out   std_logic_vector(7 downto 0) := (others => '0');
        m2_tdest        : out   std_logic_vector(7 downto 0) := (others => '0');
        m2_tuser        : out   std_logic_vector(7 downto 0) := (others => '0');
        -- 
        m3_tdata        : out   std_logic_vector(31 downto 0) := (others => '0');
        m3_tvalid       : out   std_logic := '0';
        m3_tready       : in    std_logic;
        m3_tlast        : out   std_logic := '0';
        m3_tkeep        : out   std_logic_vector(3 downto 0) := (others => '0');
        m3_tid          : out   std_logic_vector(7 downto 0) := (others => '0');
        m3_tdest        : out   std_logic_vector(7 downto 0) := (others => '0');
        m3_tuser        : out   std_logic_vector(7 downto 0) := (others => '0');

        -- Write Address Channel
        m_axi_awaddr    : out   std_logic_vector(AXI_ADDR_WIDTH-1 downto 0)     := (others => '0');
        m_axi_awburst   : out   std_logic_vector(1 downto 0)                    := (others => '0');
        m_axi_awid      : out   std_logic_vector(AXI_ID_WIDTH-1 downto 0)       := (others => '0');
        m_axi_awlen     : out   std_logic_vector(7 downto 0)                    := (others => '0');
        m_axi_awprot    : out   std_logic_vector(2 downto 0)                    := (others => '0');
        m_axi_awready   : in    std_logic;
        m_axi_awsize    : out   std_logic_vector(2 downto 0)                    := (others => '0');
        m_axi_awuser    : out   std_logic_vector(3 downto 0)                    := (others => '0'); -- non standard AXI specification
        m_axi_awvalid   : out   std_logic := '0';
        -- Write Data Channel
        m_axi_wdata     : out   std_logic_vector(AXI_DATA_WIDTH-1 downto 0)     := (others => '0');
        m_axi_wlast     : out   std_logic                                       := '0';
        m_axi_wready    : in    std_logic;
        m_axi_wstrb     : out   std_logic_vector((AXI_DATA_WIDTH/8)-1 downto 0) := (others => '0');
        m_axi_wvalid    : out   std_logic                                       := '0';
        -- Write Response Channel
        m_axi_bid       : in    std_logic_vector(AXI_ID_WIDTH-1 downto 0);
        m_axi_bready    : out   std_logic                                       := '0';
        m_axi_bresp     : in    std_logic_vector(1 downto 0);
        m_axi_bvalid    : in    std_logic;
        -- Read Address Channel
        m_axi_araddr    : out   std_logic_vector(AXI_ADDR_WIDTH-1 downto 0)     := (others => '0');
        m_axi_arburst   : out   std_logic_vector(1 downto 0)                    := (others => '0');
        m_axi_arid      : out   std_logic_vector(AXI_ID_WIDTH-1 downto 0)       := (others => '0');
        m_axi_arlen     : out   std_logic_vector(7 downto 0)                    := (others => '0');
        m_axi_arprot    : out   std_logic_vector(2 downto 0)                    := (others => '0');
        m_axi_arready   : in    std_logic;
        m_axi_arsize    : out   std_logic_vector(2 downto 0)                    := (others => '0');
        m_axi_aruser    : out   std_logic_vector(3 downto 0)                    := (others => '0'); -- non standard AXI specification
        m_axi_arvalid   : out   std_logic                                       := '0';
        -- Read Data Channel
        m_axi_rdata     : in    std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
        m_axi_rid       : in    std_logic_vector(AXI_ID_WIDTH-1 downto 0);
        m_axi_rlast     : in    std_logic;
        m_axi_rready    : out   std_logic                                   := '0';
        m_axi_rresp     : in    std_logic_vector(1 downto 0);
        m_axi_rvalid    : in    std_logic
    );
end ls;

architecture behavioral of ls is

    constant N_SLAVES    : integer := 5;
    constant N_MASTERS   : integer := 4;
    constant SEL_NUMBITS : integer := integer(ceil(log2(real(N_SLAVES))));

    component axis_xbar_s_to_m
        generic (
            N_SLAVES    : integer;
            N_MASTERS   : integer
        );
        port (
            aclk        : in    std_logic;
            areset_n    : in    std_logic;
            sel0        : in    std_logic_vector(SEL_NUMBITS-1 downto 0);
            sel1        : in    std_logic_vector(SEL_NUMBITS-1 downto 0);
            sel2        : in    std_logic_vector(SEL_NUMBITS-1 downto 0);
            sel3        : in    std_logic_vector(SEL_NUMBITS-1 downto 0);
            s           : inout axis_array_t (0 to N_SLAVES-1);
            m           : inout axis_array_t (0 to N_MASTERS-1);
            err         : out   std_logic
        );
    end component axis_xbar_s_to_m;

    signal s : axis_array_t (0 to N_SLAVES-1)  := (others => AXIS_S_INIT);
    signal m : axis_array_t (0 to N_MASTERS-1) := (others => AXIS_M_INIT);

    signal sel0 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "000";
    signal sel1 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "001";
    signal sel2 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "100";
    signal sel3 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "001";

    signal err  : std_logic;

    -- AXI4
    signal awaddr_reg    : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal awburst_reg   : std_logic_vector(1 downto 0) := (others => '0');
    signal awid_reg      : std_logic_vector(ID_WIDTH-1 downto 0) := (others => '0');
    signal awlen_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal awprot_reg    : std_logic_vector(2 downto 0) := (others => '0');
    signal awsize_reg    : std_logic_vector(2 downto 0) := (others => '0');
    signal awuser_reg    : std_logic_vector(3 downto 0) := (others => '0');
    signal awvalid_reg   : std_logic := '0';

    signal wdata_reg     : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal wlast_reg     : std_logic := '0';
    signal wstrb_reg     : std_logic_vector((DATA_WIDTH/8)-1 downto 0) := (others => '0');
    signal wvalid_reg    : std_logic := '0';

    signal araddr_reg    : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal arburst_reg   : std_logic_vector(1 downto 0) := (others => '0');
    signal arid_reg      : std_logic_vector(ID_WIDTH-1 downto 0) := (others => '0');
    signal arlen_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal arprot_reg    : std_logic_vector(2 downto 0) := (others => '0');
    signal arsize_reg    : std_logic_vector(2 downto 0) := (others => '0');
    signal aruser_reg    : std_logic_vector(3 downto 0) := (others => '0');
    signal arvalid_reg   : std_logic := '0';

    signal bready_reg    : std_logic := '0';
    signal rready_reg    : std_logic := '0';
    
    type axi_master_state is (IDLE, WADDR, WDATA, WRESP, WSTOP, RADDR, RDATA, RSTOP);
    signal axi_m_wstate : axi_master_state := IDLE;
    signal axi_m_rstate : axi_master_state := IDLE;

    constant AXI_OKAY : std_logic_vector(1 downto 0) := "00";
    constant AXI_ERR  : std_logic_vector(1 downto 0) := "10";

    -- Command register []
    type dma_command is (NOOP, CONFIGURE, EXECUTE, PREEMPT, RESET);
    signal reg_command          : dma_command := NOOP;

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
    signal ld_x_last_d          : std_logic := '0';
    signal ld_y_last_d          : std_logic := '0';
    signal ld_z_last_d          : std_logic := '0';

    signal st_data              : std_logic_vector(31 downto 0) := (others => '1');
    signal st_addr_d            : std_logic_vector(63 downto 0) := (others => '0');
    signal st_addr_q            : std_logic_vector(63 downto 0) := (others => '0');
    signal st_x_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_y_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_z_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_x_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_y_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_z_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_x_last_d          : std_logic := '0';
    signal st_y_last_d          : std_logic := '0';
    signal st_z_last_d          : std_logic := '0';

begin

    u0_axis_xbar_s_to_m : axis_xbar_s_to_m
        generic map(
            N_SLAVES    => N_SLAVES,
            N_MASTERS   => N_MASTERS
        )
        port map (
            aclk        => aclk,
            areset_n    => areset_n,
            -- Configuration Control Routing
            sel0        => sel0,
            sel1        => sel1,
            sel2        => sel2,
            sel3        => sel3,
            -- AXIS Data Routing
            s           => s;
            m           => m;
            -- Error Status out
            err         => err
        );


    s(0).tdata  <= s0_tdata;
    s(0).tvalid <= s0_tvalid;
    s0_tready   <= s(0).tready;

    s(1).tdata  <= s1_tdata;
    s(1).tvalid <= s1_tvalid;
    s1_tready   <= s(1).tready;

    s(2).tdata  <= s2_tdata;
    s(2).tvalid <= s2_tvalid;
    s2_tready   <= s(2).tready;

    s(3).tdata  <= s3_tdata;
    s(3).tvalid <= s3_tvalid;
    s3_tready   <= s(3).tready;

    -- s(4).tdata
    -- s(4).tvalid
    -- tready

    m0_tdata    <= m(0).tdata;
    m0_valid    <= m(0).tvalid;
    m(0).tready <= m0_tready;

    m1_tdata    <= m(1).tdata;
    m1_tvalid   <= m(1).tvalid;
    m(1).tready <= m1_tready;

    m2_tdata    <= m(2).tdata;
    m2_tvalid   <= m(2).tvalid;
    m(2).tready <= m2_tready;

    m3_tdata    <= m(3).tdata;
    m3_tvalid   <= m(3).tvalid;
    m(3).tready <= m3_tready;


    ld_x_last_d <= '1' when unsigned(ld_x_count_q) = (unsigned(reg_ld_x_size) - 1) else '0';
    ld_y_last_d <= '1' when unsigned(ld_y_count_q) = (unsigned(reg_ld_y_size) - 1) else '0';
    ld_z_last_d <= '1' when unsigned(ld_z_count_q) = (unsigned(reg_ld_z_size) - 1) else '0';

    ld_addr_d <= std_logic_vector(
        unsigned(reg_ld_base_addr_u & reg_ld_base_addr_l)  +
        unsigned(ld_x_count_q) * unsigned(reg_ld_x_stride) +
        unsigned(ld_y_count_q) * unsigned(reg_ld_y_stride) +
        unsigned(ld_z_count_q) * unsigned(reg_ld_z_stride)
    );

    process (ld_x_count_q, ld_x_last_d) is
    variable x_count_next : unsigned(31 downto 0) := (others => '0');
    begin
        x_count_next := unsigned(ld_x_count_q) + 1;

        if ld_x_last_d = '1' then
            x_count_next := (others => '0');
        end if;

        ld_x_count_d <= std_logic_vector(x_count_next);
    end process;

    process (ld_y_count_q, ld_x_last_d, ld_y_last_d) is
    variable y_count_next : unsigned(31 downto 0) := (others => '0');
    begin
        y_count_next := unsigned(ld_y_count_q);

        if ld_x_last_d = '1' then
            y_count_next := y_count_next + 1;
        end if;

        if ld_y_last_d = '1' then
            y_count_next := (others => '0');
        end if;

        ld_y_count_d <= std_logic_vector(y_count_next);
    end process;
    
    process (ld_z_count_q, ld_x_last_d, ld_y_last_d, ld_z_last_d) is
    variable z_count_next : unsigned(31 downto 0) := (others => '0');
    begin
        z_count_next := unsigned(ld_z_count_q);

        if ld_x_last_d = '1' and ld_y_last_d = '1' then
            z_count_next := z_count_next + 1;
        end if;

        if ld_z_last_d = '1' then
            z_count_next := (others => '0');
        end if;

        ld_z_count_d <= std_logic_vector(z_count_next);
    end process;

    st_x_last_d <= '1' when unsigned(st_x_count_q) = (unsigned(reg_st_x_size) - 1) else '0';
    st_y_last_d <= '1' when unsigned(st_y_count_q) = (unsigned(reg_st_y_size) - 1) else '0';
    st_z_last_d <= '1' when unsigned(st_z_count_q) = (unsigned(reg_st_z_size) - 1) else '0';

    st_addr_d <= std_logic_vector(
        unsigned(reg_st_base_addr_u & reg_st_base_addr_l)  +
        unsigned(st_x_count_q) * unsigned(reg_st_x_stride) +
        unsigned(st_y_count_q) * unsigned(reg_st_y_stride) +
        unsigned(st_z_count_q) * unsigned(reg_st_z_stride)
    );

    process (st_x_count_q, st_x_last_d) is
        variable x_count_next : unsigned(31 downto 0) := (others => '0');
    begin
        x_count_next := unsigned(st_x_count_q) + 1;

        if st_x_last_d = '1' then
            x_count_next := (others => '0');
        end if;

        st_x_count_d <= std_logic_vector(x_count_next);
    end process;

    process (st_y_count_q, st_x_last_d, st_y_last_d) is
        variable y_count_next : unsigned(31 downto 0) := (others => '0');
    begin
        y_count_next := unsigned(st_y_count_q);

        if st_x_last_d = '1' then
            y_count_next := y_count_next + 1;
        end if;

        if st_x_last_d = '1' and st_y_last_d = '1' then
            y_count_next := (others => '0');
        end if;

        st_y_count_d <= std_logic_vector(y_count_next);
    end process;

    process (st_z_count_q, st_x_last_d, st_y_last_d, st_z_last_d) is
        variable z_count_next : unsigned(31 downto 0) := (others => '0');
    begin
        z_count_next := unsigned(st_z_count_q);

        if st_x_last_d = '1' and st_y_last_d = '1' then
            z_count_next := z_count_next + 1;
        end if;

        if st_x_last_d = '1' and st_y_last_d = '1' and st_z_last_d = '1' then
            z_count_next := (others => '0');
        end if;

        st_z_count_d <= std_logic_vector(z_count_next);
    end process;

    process (aclk) is
    begin
        -- Inside your architecture initialization or reset block:
        awburst_reg <= "01";    -- INCR burst type
        awsize_reg  <= "010";   -- 4 bytes (32-bit data width)
        awlen_reg   <= x"00";   -- 00 + 1 = 1 single transfer
        awid_reg    <= x"00";   -- Transaction ID 0
        awprot_reg  <= "000";   -- Normal, secure, data
        awuser_reg  <= "0000";  -- Clear user sideband flags
        -- During the WDATA state:
        wstrb_reg   <= "1111";  -- Write all 4 bytes of the 32-bit word
        wlast_reg   <= '1';     -- This single transfer is the last transfer

        arburst_reg <= "01";
        arsize_reg  <= "010";
        arlen_reg   <= x"00";
        arid_reg    <= x"00";
        arprot_reg  <= "000";
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axi_m_wstate <= IDLE;
            else
                case axi_m_wstate is
                when IDLE   =>
                    if reg_command = EXECUTE then
                        axi_m_wstate <= WADDR;
                        st_x_count_q <= reg_st_x_count_pl;
                        st_y_count_q <= reg_st_y_count_pl;
                        st_z_count_q <= reg_st_z_count_pl;
                    end if;
                when WADDR  =>
                    if st_x_last_d = '1' and st_y_last_d = '1' and st_z_last_d = '1' then
                        axi_m_wstate <= WSTOP;
                    else
                        st_addr_q   <= st_addr_d;
                        awaddr_reg  <= st_addr_d(ADDR_WIDTH-1 downto 0);
                        wdata_reg   <= x"11223344";
                        awvalid_reg <= '1';
                        if m_axi_awready = '1' and awvalid_reg = '1' then
                            -- report "Writing " & "addr (hex)=" & to_hstring(awaddr_reg) & " data (hex)=" & to_hstring(wdata_reg);
                            axi_m_wstate <= WDATA;
                            wvalid_reg <= '1';
                            awvalid_reg <= '0';
                        end if;
                    end if;
                when WDATA  =>
                    axi_m_wstate <= WDATA;
                    if m_axi_wready = '1' and wvalid_reg = '1' then
                        axi_m_wstate <= WRESP;
                        bready_reg <= '1';
                    end if;
                when WRESP  =>
                    axi_m_wstate <= WRESP;
                    awvalid_reg <= '0';
                    wvalid_reg <= '0';
                    if m_axi_bvalid = '1' and m_axi_bresp = AXI_OKAY then
                        axi_m_wstate <= WADDR;
                        st_x_count_q <= st_x_count_d;
                        st_y_count_q <= st_y_count_d;
                        st_z_count_q <= st_z_count_d;
                        bready_reg <= '0';
                    end if;
                when others =>
                end case;
            end if;
        end if;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axi_m_rstate <= IDLE;
            else
                case axi_m_rstate is
                when IDLE   =>
                    if reg_command = EXECUTE then
                        -- axi_m_rstate <= RADDR;
                        ld_x_count_q <= reg_ld_x_count_pl;
                        ld_y_count_q <= reg_ld_y_count_pl;
                        ld_z_count_q <= reg_ld_z_count_pl;
                    end if;
                when RADDR  =>
                    if unsigned(ld_x_count_q) = unsigned(reg_ld_x_size) then
                        axi_m_rstate <= RSTOP;
                    else
                        arvalid_reg <= '1';
                        ld_addr_q <= ld_addr_d;
                        araddr_reg <= ld_addr_d(ADDR_WIDTH-1 downto 0);
                        if arvalid_reg = '1' and m_axi_arready = '1' then
                            axi_m_rstate <= RDATA;
                            rready_reg <= '1';
                            arvalid_reg <= '0';
                        end if;
                    end if;
                when RDATA  =>
                    if m_axi_rvalid = '1' and rready_reg = '1' then
                        axi_m_rstate <= RADDR;
                        -- report "Reading " & "addr (hex)=" & to_hstring(araddr_reg) & " data (hex)=" & to_hstring(m_axi_rdata);
                        ld_x_count_q <= ld_x_count_d;
                        ld_y_count_q <= ld_y_count_d;
                        ld_z_count_q <= ld_z_count_d;
                        rready_reg <= '0';
                    end if;
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
                if reg_command = PREEMPT then
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
        end if;
    end process;

    -- Internal registers to AXI Output Ports
    m_axi_awaddr  <= awaddr_reg;
    m_axi_awburst <= awburst_reg;
    m_axi_awid    <= awid_reg;
    m_axi_awlen   <= awlen_reg;
    m_axi_awprot  <= awprot_reg;
    m_axi_awsize  <= awsize_reg;
    m_axi_awuser  <= awuser_reg;
    m_axi_awvalid <= awvalid_reg;

    m_axi_wdata   <= wdata_reg;
    m_axi_wlast   <= wlast_reg;
    m_axi_wstrb   <= wstrb_reg;
    m_axi_wvalid  <= wvalid_reg;

    m_axi_bready  <= bready_reg;

    m_axi_araddr  <= araddr_reg;
    m_axi_arburst <= arburst_reg;
    m_axi_arid    <= arid_reg;
    m_axi_arlen   <= arlen_reg;
    m_axi_arprot  <= arprot_reg;
    m_axi_arsize  <= arsize_reg;
    m_axi_aruser  <= aruser_reg;
    m_axi_arvalid <= arvalid_reg;

    m_axi_rready  <= rready_reg;

end architecture behavioral;
