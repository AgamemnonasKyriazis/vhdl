library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- library axi;
-- use axi.axi4_pkg.all;

entity axi_ram is
    generic (
        DATA_WIDTH : INTEGER := 32;
        ADDR_WIDTH : INTEGER := 10;
        ID_WIDTH   : INTEGER := 8
    );
    port (
        aclk            : in    STD_LOGIC;
        areset_n        : in    STD_LOGIC;

        -- s_axi4_io       : inout axi4_t;

        -- Write Address Channel
        s_axi_awaddr    : in    STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
        s_axi_awburst   : in    STD_LOGIC_VECTOR(1 downto 0);
        s_axi_awid      : in    STD_LOGIC_VECTOR(ID_WIDTH-1 downto 0);
        s_axi_awlen     : in    STD_LOGIC_VECTOR(7 downto 0);
        s_axi_awprot    : in    STD_LOGIC_VECTOR(2 downto 0);
        s_axi_awready   : out   STD_LOGIC;
        s_axi_awsize    : in    STD_LOGIC_VECTOR(2 downto 0);
        s_axi_awuser    : in    STD_LOGIC_VECTOR(3 downto 0); -- non standard AXI specification
        s_axi_awvalid   : in    STD_LOGIC;

        -- Write Data Channel
        s_axi_wdata     : in    STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        s_axi_wlast     : in    STD_LOGIC;
        s_axi_wready    : out   STD_LOGIC;
        s_axi_wstrb     : in    STD_LOGIC_VECTOR((DATA_WIDTH/8)-1 downto 0);
        s_axi_wvalid    : in    STD_LOGIC;

        -- Write Response Channel
        s_axi_bid       : out   STD_LOGIC_VECTOR(ID_WIDTH-1 downto 0);
        s_axi_bready    : in    STD_LOGIC;
        s_axi_bresp     : out   STD_LOGIC_VECTOR(1 downto 0);
        s_axi_bvalid    : out   STD_LOGIC;

        -- Read Address Channel
        s_axi_araddr    : in    STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
        s_axi_arburst   : in    STD_LOGIC_VECTOR(1 downto 0);
        s_axi_arid      : in    STD_LOGIC_VECTOR(ID_WIDTH-1 downto 0);
        s_axi_arlen     : in    STD_LOGIC_VECTOR(7 downto 0);
        s_axi_arprot    : in    STD_LOGIC_VECTOR(2 downto 0);
        s_axi_arready   : out   STD_LOGIC;
        s_axi_arsize    : in    STD_LOGIC_VECTOR(2 downto 0);
        s_axi_aruser    : in    STD_LOGIC_VECTOR(3 downto 0); -- non standard AXI specification
        s_axi_arvalid   : in    STD_LOGIC;

        -- Read Data Channel
        s_axi_rdata     : out   STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        s_axi_rid       : out   STD_LOGIC_VECTOR(ID_WIDTH-1 downto 0);
        s_axi_rlast     : out   STD_LOGIC;
        s_axi_rready    : in    STD_LOGIC;
        s_axi_rresp     : out   STD_LOGIC_VECTOR(1 downto 0);
        s_axi_rvalid    : out   STD_LOGIC
    );
end axi_ram;

architecture behavioral of axi_ram is

    constant STRB_WIDTH : INTEGER := DATA_WIDTH/8;
    constant ADDR_LSB : INTEGER := integer(ceil(log2(real(STRB_WIDTH))));

    type ram is array (0 to (2**(ADDR_WIDTH-ADDR_LSB))-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal mem : ram := (others => (others => '0'));

    function mem_index (
        addr : in STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0))        
        return INTEGER is 
            variable addr_algn : INTEGER := 0;
    begin
        addr_algn := to_integer(shift_right(unsigned(addr), ADDR_LSB));
        return addr_algn;
    end function mem_index;

    signal re    : STD_LOGIC := '0';
    signal we    : STD_LOGIC := '0';

    type axi_state is (IDLE, WDATA, WRESP, RMEM, RDATA);
    signal state : axi_state := IDLE;

    constant AXI_OKAY : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant AXI_ERR  : STD_LOGIC_VECTOR(1 downto 0) := "10";

    signal axi_awaddr_reg : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal axi_awid_reg   : STD_LOGIC_VECTOR(ID_WIDTH-1 downto 0) := (others => '0');

    signal axi_araddr_reg : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal axi_arid_reg   : STD_LOGIC_VECTOR(ID_WIDTH-1 downto 0) := (others => '0');

    signal axi_awready  : STD_LOGIC := '0';
    signal axi_wready   : STD_LOGIC := '0';
    signal axi_bid      : STD_LOGIC_VECTOR(ID_WIDTH-1 downto 0) := (others => '0');
    signal axi_bresp    : STD_LOGIC_VECTOR(1 downto 0) := AXI_OKAY;
    signal axi_bvalid   : STD_LOGIC := '0';
    signal axi_arready  : STD_LOGIC := '0';
    signal axi_rdata    : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others => '0');
    signal axi_rid      : STD_LOGIC_VECTOR(ID_WIDTH-1 downto 0) := (others => '0');
    signal axi_rresp    : STD_LOGIC_VECTOR(1 downto 0) := AXI_OKAY;
    signal axi_rlast    : STD_LOGIC := '1';
    signal axi_rvalid   : STD_LOGIC := '0';

begin

    axi_bid <= axi_awid_reg;
    axi_rid <= axi_arid_reg;

    s_axi_awready   <= axi_awready;
    s_axi_wready    <= axi_wready;
    s_axi_bid       <= axi_bid;
    s_axi_bresp     <= axi_bresp;
    s_axi_bvalid    <= axi_bvalid;
    s_axi_arready   <= axi_arready;
    s_axi_rdata     <= axi_rdata;
    
    s_axi_rid       <= axi_rid;

    s_axi_rresp     <= axi_rresp;
    s_axi_rlast     <= axi_rlast;
    s_axi_rvalid    <= axi_rvalid;

    re <= '1' when state = RMEM else '0';
    we <= axi_wready and s_axi_wvalid;

    AXI_FSM : process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                state <= IDLE;
            else
                case state is
                    when IDLE   =>
                        if (s_axi_awvalid and axi_awready) = '1' then
                            state <= WDATA;
                        elsif (s_axi_arvalid and axi_arready) = '1' then
                            state <= RMEM;
                        else
                            state <= IDLE;
                        end if;
                    when WDATA  =>
                        if (s_axi_wvalid and axi_wready) = '1' then
                            state <= WRESP;
                        else
                            state <= WDATA;
                        end if;
                    when WRESP  =>
                        if (s_axi_bready and axi_bvalid) = '1' then
                            state <= IDLE;
                        else
                            state <= WRESP;
                        end if;
                    when RMEM   =>
                        state <= RDATA;
                    when RDATA  =>
                        if (s_axi_rready and axi_rvalid) = '1' then
                            state <= IDLE;
                        else
                            state <= RDATA;
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process AXI_FSM;

    AXI_SIGNAL : process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axi_awready   <= '0';
                axi_wready    <= '0';
                axi_bresp     <= "00";
                axi_bvalid    <= '0';
                axi_arready   <= '1';
                axi_rresp     <= "00";
                axi_rvalid    <= '0';
            else
                case state is
                    when IDLE   =>
                        axi_wready    <= '0';
                        axi_bresp     <= "00";
                        axi_bvalid    <= '0';
                        axi_rresp     <= "00";
                        axi_rvalid    <= '0';
                        axi_arready   <= '1';
                        axi_awready   <= '0';
                        if s_axi_awvalid = '1' then
                            axi_arready   <= '0';
                            axi_awready   <= '1';
                        elsif s_axi_arvalid = '1' then
                            axi_rresp     <= AXI_OKAY;
                        end if;
                    when WDATA  =>
                        axi_wready        <= '1';
                        if we = '1' then
                            axi_bvalid    <= '1';
                        end if;
                    when WRESP  =>
                        axi_awready   <= '0';
                        axi_wready    <= '0';
                        axi_bresp     <= AXI_OKAY;
                        if (s_axi_bready and axi_bvalid) = '1' then
                            axi_bvalid    <= '0';
                        end if;
                    when RMEM =>
                        axi_rvalid <= '1';
                    when RDATA  =>
                        if s_axi_rready = '1' then
                            axi_rvalid    <= '0';
                        end if;
                        axi_rresp     <= AXI_OKAY;
                        axi_arready   <= '0';
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process AXI_SIGNAL;

    AXI_W_REG : process (aclk)
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axi_awaddr_reg <= (others => '0');
                axi_awid_reg   <= (others => '0');
            else
                if (s_axi_awvalid and axi_awready) = '1' then
                    axi_awaddr_reg <= s_axi_awaddr;
                    axi_awid_reg   <= s_axi_awid;
                end if;
            end if;
        end if;
    end process AXI_W_REG;

    AXI_R_REG : process (aclk)
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axi_araddr_reg <= (others => '0');
                axi_arid_reg <= (others => '0');
            else
                if (s_axi_arvalid and axi_arready) = '1' then
                    axi_araddr_reg <= s_axi_araddr;
                    axi_arid_reg <= s_axi_arid;
                end if;
            end if;
        end if;
    end process AXI_R_REG;

    AXI_MEM : process (aclk)
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axi_rdata <= (others => '0');
            elsif re = '1' then
                axi_rdata <= mem (mem_index(axi_araddr_reg));
            elsif we = '1' then
                for i in 0 to STRB_WIDTH-1 loop
                    if s_axi_wstrb(i) = '1' then
                        mem (mem_index(axi_awaddr_reg)) (((i+1)*8)-1 downto (i*8) ) <= s_axi_wdata( ((i+1)*8)-1 downto (i*8) );
                    end if;
                end loop;
            end if;
        end if;
    end process AXI_MEM;

end behavioral;