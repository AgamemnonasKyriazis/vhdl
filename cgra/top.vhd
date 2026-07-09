library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library axi;
use axi.axis.all;
use axi.axi4.all;

entity top is
    port (
        clk        : in std_logic;
        reset_n    : in std_logic;

        -- Write Address Channel
        m0_axi_awaddr    : out   std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
        m0_axi_awburst   : out   std_logic_vector(1 downto 0) := (others => '0');
        m0_axi_awid      : out   std_logic_vector(AXI_ID_WIDTH-1 downto 0) := (others => '0');
        m0_axi_awlen     : out   std_logic_vector(7 downto 0) := (others => '0');
        m0_axi_awprot    : out   std_logic_vector(2 downto 0) := (others => '0');
        m0_axi_awready   : in    std_logic;
        m0_axi_awsize    : out   std_logic_vector(2 downto 0) := (others => '0');
        m0_axi_awuser    : out   std_logic_vector(3 downto 0) := (others => '0'); -- non standard AXI specification
        m0_axi_awvalid   : out   std_logic := '0';
        -- Write Data Channel
        m0_axi_wdata     : out   std_logic_vector(AXI_DATA_WIDTH-1 downto 0) := (others => '0');
        m0_axi_wlast     : out   std_logic := '0';
        m0_axi_wready    : in    std_logic;
        m0_axi_wstrb     : out   std_logic_vector(AXI_STRB_WIDTH-1 downto 0) := (others => '0');
        m0_axi_wvalid    : out   std_logic := '0';
        -- Write Response Channel
        m0_axi_bid       : in    std_logic_vector(AXI_ID_WIDTH-1 downto 0);
        m0_axi_bready    : out   std_logic := '0';
        m0_axi_bresp     : in    std_logic_vector(1 downto 0);
        m0_axi_bvalid    : in    std_logic;
        -- Read Address Channel
        m0_axi_araddr    : out   std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
        m0_axi_arburst   : out   std_logic_vector(1 downto 0) := (others => '0');
        m0_axi_arid      : out   std_logic_vector(AXI_ID_WIDTH-1 downto 0)  := (others => '0');
        m0_axi_arlen     : out   std_logic_vector(7 downto 0) := (others => '0');
        m0_axi_arprot    : out   std_logic_vector(2 downto 0) := (others => '0');
        m0_axi_arready   : in    std_logic;
        m0_axi_arsize    : out   std_logic_vector(2 downto 0) := (others => '0');
        m0_axi_aruser    : out   std_logic_vector(3 downto 0) := (others => '0'); -- non standard AXI specification
        m0_axi_arvalid   : out   std_logic := '0';
        -- Read Data Channel
        m0_axi_rdata     : in    std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
        m0_axi_rid       : in    std_logic_vector(AXI_ID_WIDTH-1 downto 0);
        m0_axi_rlast     : in    std_logic;
        m0_axi_rready    : out   std_logic := '0';
        m0_axi_rresp     : in    std_logic_vector(1 downto 0);
        m0_axi_rvalid    : in    std_logic
    );
end top;

architecture behavioral of top is

    signal aclk     : std_logic;
    signal areset_n : std_logic;
    signal enable   : std_logic := '0';

    constant N_SLAVES    : integer := 6;
    constant N_MASTERS   : integer := 7;
    constant SEL_NUMBITS : integer := integer(ceil(log2(real(N_SLAVES+1))));

    signal err : std_logic;

    signal s : axis_array_t (0 to N_SLAVES-1) := (others => AXIS_S_INIT);
    signal m : axis_array_t (0 to N_MASTERS-1) := (others => AXIS_M_INIT);
    signal p : axi4_t := AXI4_M_INIT;


     component ic
        generic (
            N_SLAVES    : integer;
            N_MASTERS   : integer
        );
        port (
            aclk        : in    std_logic;
            areset_n    : in    std_logic;
            s           : inout axis_array_t (0 to N_SLAVES-1);
            m           : inout axis_array_t (0 to N_MASTERS-1)
        );
    end component ic;

     component ls
        generic (
            DATA_WIDTH : integer
        );
        port (
            aclk        : in std_logic;
            areset_n    : in std_logic;
            sI          : inout axis_t := AXIS_S_INIT;
            mO          : inout axis_t := AXIS_M_INIT;
            mM          : inout axi4_t := AXI4_M_INIT;
            enable_i    : in std_logic;
            bd_ld_x_p   : out std_logic_vector(31 downto 0);
            bd_ld_y_p   : out std_logic_vector(31 downto 0);
            bd_ld_z_p   : out std_logic_vector(31 downto 0);
            bd_st_x_p   : out std_logic_vector(31 downto 0);
            bd_st_y_p   : out std_logic_vector(31 downto 0);
            bd_st_z_p   : out std_logic_vector(31 downto 0)
        );
    end component ls;

     component fn
        generic (
            DATA_WIDTH : integer
        );
        port (
            aclk        : in std_logic;
            areset_n    : in std_logic;
            sA          : inout axis_t := AXIS_S_INIT;
            sB          : inout axis_t := AXIS_S_INIT;
            mC          : inout axis_t := AXIS_M_INIT
        );
    end component fn;

begin

    u0_ic : ic
    generic map(
        N_SLAVES    => N_SLAVES,
        N_MASTERS   => N_MASTERS
    )
    port map (
        aclk        => aclk,
        areset_n    => areset_n,
        -- AXIS Data Routing
        s           => s,
        m           => m
    );

    u0_ls : ls
    generic map (
        DATA_WIDTH      => 32
    )
    port map (
        aclk            => aclk,
        areset_n        => areset_n,
        sI              => m(0),
        mO              => s(0),
        mM              => p,

        enable_i        => enable
    );

    u0_fn : fn
    generic map(
        DATA_WIDTH  => 32
    )
    port map (
        aclk        => aclk,
        areset_n    => areset_n,
        sA          => m(4),
        sB          => m(5),
        mC          => s(4)
    );


    -- Write Address Channel
    m0_axi_awaddr  <= p.awaddr;
    m0_axi_awburst <= p.awburst;
    m0_axi_awid    <= p.awid;
    m0_axi_awlen   <= p.awlen;
    m0_axi_awprot  <= p.awprot;
    p.awready      <= m0_axi_awready;
    m0_axi_awsize  <= p.awsize;
    m0_axi_awuser  <= p.awuser;
    m0_axi_awvalid <= p.awvalid;

    -- Write Data Channel
    m0_axi_wdata   <= p.wdata;
    m0_axi_wlast   <= p.wlast;
    p.wready       <= m0_axi_wready;
    m0_axi_wstrb   <= p.wstrb;
    m0_axi_wvalid  <= p.wvalid;

    -- Write Response Channel
    p.bid          <= m0_axi_bid;
    m0_axi_bready  <= p.bready;
    p.bresp        <= m0_axi_bresp;
    p.bvalid       <= m0_axi_bvalid;

    -- Read Address Channel
    m0_axi_araddr  <= p.araddr;
    m0_axi_arburst <= p.arburst;
    m0_axi_arid    <= p.arid;
    m0_axi_arlen   <= p.arlen;
    m0_axi_arprot  <= p.arprot;
    p.arready      <= m0_axi_arready;
    m0_axi_arsize  <= p.arsize;
    m0_axi_aruser  <= p.aruser;
    m0_axi_arvalid <= p.arvalid;

    -- Read Data Channel
    p.rdata        <= m0_axi_rdata;
    p.rid          <= m0_axi_rid;
    p.rlast        <= m0_axi_rlast;
    m0_axi_rready  <= p.rready;
    p.rresp        <= m0_axi_rresp;
    p.rvalid       <= m0_axi_rvalid;
end architecture;