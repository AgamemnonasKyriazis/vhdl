library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity axilt_ram is
    generic (
        DATA_WIDTH : INTEGER := 32;
        ADDR_WIDTH : INTEGER := 10
    );
    port (
        aclk            : in    STD_LOGIC;
        areset_n        : in    STD_LOGIC;
        
        s_axilt_awaddr  : in    STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
        s_axilt_awvalid : in    STD_LOGIC;
        s_axilt_awready : out   STD_LOGIC;

        s_axilt_wdata   : in    STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        s_axilt_wstrb   : in    STD_LOGIC_VECTOR((DATA_WIDTH/8)-1 downto 0);
        s_axilt_wvalid  : in    STD_LOGIC;
        s_axilt_wready  : out   STD_LOGIC;

        s_axilt_bresp   : out   STD_LOGIC_VECTOR(1 downto 0);
        s_axilt_bvalid  : out   STD_LOGIC;
        s_axilt_bready  : in    STD_LOGIC;

        s_axilt_araddr  : in    STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
        s_axilt_arvalid : in    STD_LOGIC;
        s_axilt_arready : out   STD_LOGIC;

        s_axilt_rdata   : out   STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        s_axilt_rresp   : out   STD_LOGIC_VECTOR(1 downto 0);
        s_axilt_rvalid  : out   STD_LOGIC;
        s_axilt_rready  : in    STD_LOGIC
    );
end axilt_ram;

architecture behavioural of axilt_ram is

    constant STRB_WIDTH : INTEGER := DATA_WIDTH/8;
    constant ADDR_LSB : INTEGER := integer(ceil(log2(real(STRB_WIDTH))));

    type ram is array (0 to (2**(ADDR_WIDTH-ADDR_LSB))-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal mem : ram := (others => (others => '0'));

    type axilt_state is (IDLE, WDATA, WRESP, RDATA);
    signal state : axilt_state := IDLE;

    constant AXI_OKAY : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant AXI_ERR  : STD_LOGIC_VECTOR(1 downto 0) := "10";

    signal axilt_awready    : STD_LOGIC := '0';
    signal axilt_wready     : STD_LOGIC := '0';
    signal axilt_bresp      : STD_LOGIC_VECTOR(1 downto 0) := AXI_OKAY;
    signal axilt_bvalid     : STD_LOGIC := '0';
    signal axilt_arready    : STD_LOGIC := '0';
    signal axilt_rdata      : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others => '0');
    signal axilt_rresp      : STD_LOGIC_VECTOR(1 downto 0) := AXI_OKAY;
    signal axilt_rvalid     : STD_LOGIC := '0';


    function mem_index (
        axilt_addr : in STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0))        
        return INTEGER is 
            variable axilt_idx : INTEGER := 0;
    begin
        axilt_idx := to_integer(shift_right(unsigned(axilt_addr), ADDR_LSB));
        return axilt_idx;
    end function mem_index;

    signal re    : STD_LOGIC := '0';
    signal we    : STD_LOGIC := '0';

begin

    AXI_STATE : process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                state <= IDLE;
            else
            case state is
                when IDLE   =>
                    if s_axilt_awvalid = '1' then
                        state <= WDATA;
                    elsif s_axilt_arvalid = '1' then
                        state <= RDATA;
                    else
                        state <= IDLE;
                    end if;
                when WDATA  =>
                    if (s_axilt_wvalid and axilt_wready) = '1' then
                        state <= WRESP;
                    else
                        state <= WDATA;
                    end if;
                when WRESP  =>
                    if (s_axilt_bready and axilt_bvalid) = '1' then
                        state <= IDLE;
                    else
                        state <= WRESP;
                    end if;
                when RDATA  =>
                    if (s_axilt_rready and axilt_rvalid) = '1' then
                        state <= IDLE;
                    else
                        state <= RDATA;
                    end if;
                when others =>
                    null;
            end case;
            end if;
        end if;
    end process AXI_STATE;

    AXI_SIGNAL : process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axilt_awready   <= '0';
                axilt_wready    <= '0';
                axilt_bresp     <= "00";
                axilt_bvalid    <= '0';
                axilt_arready   <= '1';
                axilt_rresp     <= "00";
                axilt_rvalid    <= '0';
            else
                case state is
                    when IDLE   =>
                        axilt_wready    <= '0';
                        axilt_bresp     <= "00";
                        axilt_bvalid    <= '0';
                        axilt_rresp     <= "00";
                        axilt_rvalid    <= '0';
                        axilt_arready   <= '1';
                        axilt_awready   <= '0';
                        if s_axilt_awvalid = '1' then
                            axilt_arready   <= '0';
                            axilt_awready   <= '1';
                        elsif s_axilt_arvalid = '1' then
                            axilt_rvalid    <= '1';
                            axilt_rresp     <= AXI_OKAY;
                        end if;
                    when WDATA  =>
                        axilt_wready        <= '1';
                        if we = '1' then
                            axilt_bvalid    <= '1';
                        end if;
                    when WRESP  =>
                        axilt_awready   <= '0';
                        axilt_wready    <= '0';
                        axilt_bvalid    <= '0';
                        axilt_bresp     <= AXI_OKAY;
                    when RDATA  =>
                        axilt_rvalid    <= '0';
                        axilt_rresp     <= AXI_OKAY;
                        axilt_arready   <= '0';
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process AXI_SIGNAL;

    s_axilt_awready   <= axilt_awready;
    s_axilt_wready    <= axilt_wready;
    s_axilt_bresp     <= axilt_bresp;
    s_axilt_bvalid    <= axilt_bvalid;
    s_axilt_arready   <= axilt_arready;
    s_axilt_rdata     <= axilt_rdata;
    s_axilt_rresp     <= axilt_rresp;
    s_axilt_rvalid    <= axilt_rvalid;

    re <= axilt_arready and s_axilt_arvalid;
    we <= axilt_wready and s_axilt_wvalid;

    PMEM : process (aclk)
    begin
        if rising_edge(aclk) then
            if (areset_n = '0') then
                axilt_rdata <= (others => '0');
            elsif re = '1' then
                axilt_rdata <= mem (mem_index(s_axilt_araddr));
            elsif we = '1' then
                for i in 0 to STRB_WIDTH-1 loop
                    if s_axilt_wstrb(i) = '1' then
                        mem (mem_index(s_axilt_awaddr)) (((i+1)*8)-1 downto (i*8) ) <= 
                            s_axilt_wdata( ((i+1)*8)-1 downto (i*8) );
                    end if;
                end loop;
            end if;
        end if;
    end process PMEM;

end behavioural;