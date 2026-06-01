library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_dma is
    generic (
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 10;
        ID_WIDTH   : integer := 8
    );
    port (
        aclk        : in std_logic;
        areset_n    : in std_logic;

        -- Write Address Channel
        s_axi_awaddr    : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
        s_axi_awburst   : out   std_logic_vector(1 downto 0);
        s_axi_awid      : out   std_logic_vector(ID_WIDTH-1 downto 0);
        s_axi_awlen     : out   std_logic_vector(7 downto 0);
        s_axi_awprot    : out   std_logic_vector(2 downto 0);
        s_axi_awready   : in    std_logic;
        s_axi_awsize    : out   std_logic_vector(2 downto 0);
        s_axi_awuser    : out   std_logic_vector(3 downto 0); -- non standard AXI specification
        s_axi_awvalid   : out   std_logic;

        -- Write Data Channel
        s_axi_wdata     : out   std_logic_vector(DATA_WIDTH-1 downto 0);
        s_axi_wlast     : out   std_logic;
        s_axi_wready    : in    std_logic;
        s_axi_wstrb     : out   std_logic_vector((DATA_WIDTH/8)-1 downto 0);
        s_axi_wvalid    : out   std_logic;

        -- Write Response Channel
        s_axi_bid       : in    std_logic_vector(ID_WIDTH-1 downto 0);
        s_axi_bready    : out   std_logic;
        s_axi_bresp     : in    std_logic_vector(1 downto 0);
        s_axi_bvalid    : in    std_logic;

        -- Read Address Channel
        s_axi_araddr    : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
        s_axi_arburst   : out   std_logic_vector(1 downto 0);
        s_axi_arid      : out   std_logic_vector(ID_WIDTH-1 downto 0);
        s_axi_arlen     : out   std_logic_vector(7 downto 0);
        s_axi_arprot    : out   std_logic_vector(2 downto 0);
        s_axi_arready   : in    std_logic;
        s_axi_arsize    : out   std_logic_vector(2 downto 0);
        s_axi_aruser    : out   std_logic_vector(3 downto 0); -- non standard AXI specification
        s_axi_arvalid   : out   std_logic;

        -- Read Data Channel
        s_axi_rdata     : in    std_logic_vector(DATA_WIDTH-1 downto 0);
        s_axi_rid       : in    std_logic_vector(ID_WIDTH-1 downto 0);
        s_axi_rlast     : in    std_logic;
        s_axi_rready    : out   std_logic;
        s_axi_rresp     : in    std_logic_vector(1 downto 0);
        s_axi_rvalid    : in    std_logic
    );
end axi_dma;

architecture behavioral of axi_dma is

    signal awaddr_reg    : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal awburst_reg   : std_logic_vector(1 downto 0);
    signal awid_reg      : std_logic_vector(ID_WIDTH-1 downto 0);
    signal awlen_reg     : std_logic_vector(7 downto 0);
    signal awprot_reg    : std_logic_vector(2 downto 0);
    signal awsize_reg    : std_logic_vector(2 downto 0);
    signal awuser_reg    : std_logic_vector(3 downto 0);
    signal awvalid_reg   : std_logic;

    signal wdata_reg     : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal wlast_reg     : std_logic;
    signal wstrb_reg     : std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    signal wvalid_reg    : std_logic;

    signal araddr_reg    : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal arburst_reg   : std_logic_vector(1 downto 0);
    signal arid_reg      : std_logic_vector(ID_WIDTH-1 downto 0);
    signal arlen_reg     : std_logic_vector(7 downto 0);
    signal arprot_reg    : std_logic_vector(2 downto 0);
    signal arsize_reg    : std_logic_vector(2 downto 0);
    signal aruser_reg    : std_logic_vector(3 downto 0);
    signal arvalid_reg   : std_logic;

    signal bready_reg    : std_logic;
    signal rready_reg    : std_logic;
    
    type axi_master_state is (IDLE, WADDR, WDATA, WRESP, RMEM, RDATA);
    signal axi_m_wstate : axi_master_state := IDLE;

    constant AXI_OKAY : std_logic_vector(1 downto 0) := "00";
    constant AXI_ERR  : std_logic_vector(1 downto 0) := "10";

    signal reg_ld_base_addr_l   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_base_addr_u   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_x_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_x_stride      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_y_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_y_stride      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_z_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_ld_z_stride      : std_logic_vector(31 downto 0) := (others => '0');

    signal reg_st_base_addr_l   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_base_addr_u   : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_x_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_x_stride      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_y_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_y_stride      : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_z_size        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_st_z_stride      : std_logic_vector(31 downto 0) := (others => '0');

    signal ld_data              : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_addr_d            : std_logic_vector(63 downto 0) := (others => '0');
    signal ld_x_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_y_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_z_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_x_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_y_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal ld_z_count_q         : std_logic_vector(31 downto 0) := (others => '0');

    signal st_data              : std_logic_vector(31 downto 0) := (others => '0');
    signal st_addr_d            : std_logic_vector(63 downto 0) := (others => '0');
    signal st_x_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_y_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_z_count_d         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_x_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_y_count_q         : std_logic_vector(31 downto 0) := (others => '0');
    signal st_z_count_q         : std_logic_vector(31 downto 0) := (others => '0');
begin

    ld_addr_d <= std_logic_vector(
        unsigned(reg_ld_base_addr_u & reg_ld_base_addr_l)  +
        unsigned(ld_x_count_q) * unsigned(reg_ld_x_stride) +
        unsigned(ld_y_count_q) * unsigned(reg_ld_y_stride) +
        unsigned(ld_z_count_q) * unsigned(reg_ld_z_stride)
    );

    ld_x_count_d <= std_logic_vector(unsigned(ld_x_count_q) + 1);
    ld_y_count_d <= std_logic_vector(unsigned(ld_y_count_q) + 1);
    ld_z_count_d <= std_logic_vector(unsigned(ld_z_count_q) + 1);

    st_addr_d <= std_logic_vector(
        unsigned(reg_st_base_addr_u & reg_st_base_addr_l)  +
        unsigned(st_x_count_q) * unsigned(reg_st_x_stride) +
        unsigned(st_y_count_q) * unsigned(reg_st_y_stride) +
        unsigned(st_z_count_q) * unsigned(reg_st_z_stride)
    );

    st_x_count_d <= std_logic_vector(unsigned(st_x_count_q) + 1);
    st_y_count_d <= std_logic_vector(unsigned(st_y_count_q) + 1);
    st_z_count_d <= std_logic_vector(unsigned(st_z_count_q) + 1);

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                axi_m_wstate <= IDLE;
            else
                case axi_m_wstate is
                when IDLE   =>
                    axi_m_wstate <= WADDR;
                when WADDR  =>
                    st_addr_q   <= st_addr_d;
                    awaddr_reg  <= st_addr_d;
                    awvalid_reg <= '1'
                    if axi_awready = '1' then
                        axi_m_wstate <= WDATA;
                    end if;
                when WDATA  =>
                    axi_m_wstate <= WRESP;
                    bready_reg   <= '1';
                when WRESP  =>
                    axi_m_wstate WRESP;
                    if axi_bvalid = '1' and axi_bresp = AXI_OKAY then
                        axi_m_wstate <= WADDR;
                        st_x_count_q <= st_x_count_d;
                        st_y_count_q <= st_y_count_d;
                        st_z_count_q <= st_z_count_d;
                    end if;
                when others =>
                end case;
            end if;
        end if;
    end process;

end architecture behavioral;