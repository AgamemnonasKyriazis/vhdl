library ieee;
use ieee.std_logic_1164.all;

package axi4 is

    constant AXI_DATA_WIDTH : integer := 32;
    constant AXI_STRB_WIDTH : integer := AXI_DATA_WIDTH/8;
    constant AXI_ADDR_WIDTH : integer := 10;
    constant AXI_ID_WIDTH   : integer := 8;
    
    constant AXI_OKAY   : std_logic_vector(1 downto 0) := "00";
    constant AXI_DECERR : std_logic_vector(1 downto 0) := "10";

    type axi4_t is record
        -- Write Address Channel
        awaddr  : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
        awburst : std_logic_vector(1 downto 0);
        awid    : std_logic_vector(AXI_ID_WIDTH-1 downto 0);
        awlen   : std_logic_vector(7 downto 0);
        awprot  : std_logic_vector(2 downto 0);
        awready : std_logic;
        awsize  : std_logic_vector(2 downto 0);
        awuser  : std_logic_vector(3 downto 0);
        awvalid : std_logic;
        -- Write Data Channel
        wdata   : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
        wlast   : std_logic;
        wready  : std_logic;
        wstrb   : std_logic_vector(AXI_STRB_WIDTH-1 downto 0);
        wvalid  : std_logic;
        -- Write Response Channel
        bid     : std_logic_vector(AXI_ID_WIDTH-1 downto 0);
        bready  : std_logic;
        bresp   : std_logic_vector(1 downto 0);
        bvalid  : std_logic;
        -- Read Address Channel
        araddr  : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
        arburst : std_logic_vector(1 downto 0);
        arid    : std_logic_vector(AXI_ID_WIDTH-1 downto 0);
        arlen   : std_logic_vector(7 downto 0);
        arprot  : std_logic_vector(2 downto 0);
        arready : std_logic;
        arsize  : std_logic_vector(2 downto 0);
        aruser  : std_logic_vector(3 downto 0);
        arvalid : std_logic;
        -- Read Data Channel
        rdata   : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
        rid     : std_logic_vector(AXI_ID_WIDTH-1 downto 0);
        rlast   : std_logic;
        rready  : std_logic;
        rresp   : std_logic_vector(1 downto 0);
        rvalid  : std_logic;
    end record axi4_t;

    constant AXI4_M_INIT : axi4_t := (
        -- Write Address Channel
        awaddr  => (others => 'L'),  -- output
        awburst => (others => 'L'),  -- output
        awid    => (others => 'L'),  -- output
        awlen   => (others => 'L'),  -- output
        awprot  => (others => 'L'),  -- output
        awready => 'Z',              -- input
        awsize  => (others => 'L'),  -- output
        awuser  => (others => 'L'),  -- output
        awvalid => 'L',              -- output
        -- Write Data Channel
        wdata   => (others => 'L'),  -- output
        wlast   => 'L',              -- output
        wready  => 'Z',              -- input
        wstrb   => (others => 'L'),  -- output
        wvalid  => 'L',              -- output
        -- Write Response Channel
        bid     => (others => 'Z'),  -- input
        bready  => 'L',              -- output
        bresp   => (others => 'Z'),  -- input
        bvalid  => 'Z',              -- input
        -- Read Address Channel
        araddr  => (others => 'L'),  -- output
        arburst => (others => 'L'),  -- output
        arid    => (others => 'L'),  -- output
        arlen   => (others => 'L'),  -- output
        arprot  => (others => 'L'),  -- output
        arready => 'Z',              -- input
        arsize  => (others => 'L'),  -- output
        aruser  => (others => 'L'),  -- output
        arvalid => 'L',              -- output
        -- Read Data Channel
        rdata   => (others => 'Z'),  -- input
        rid     => (others => 'Z'),  -- input
        rlast   => 'Z',              -- input
        rready  => 'L',              -- output
        rresp   => (others => 'Z'),  -- input
        rvalid  => 'Z'               -- input
    );

    constant AXI4_S_INIT : axi4_t := (
        -- Write Address Channel
        awaddr  => (others => 'Z'),  -- input
        awburst => (others => 'Z'),  -- input
        awid    => (others => 'Z'),  -- input
        awlen   => (others => 'Z'),  -- input
        awprot  => (others => 'Z'),  -- input
        awready => 'L',              -- output
        awsize  => (others => 'Z'),  -- input
        awuser  => (others => 'Z'),  -- input
        awvalid => 'Z',              -- input
        -- Write Data Channel
        wdata   => (others => 'Z'),  -- input
        wlast   => 'Z',              -- input
        wready  => 'L',              -- output
        wstrb   => (others => 'Z'),  -- input
        wvalid  => 'Z',              -- input
        -- Write Response Channel
        bid     => (others => 'L'),  -- output
        bready  => 'Z',              -- input
        bresp   => (others => 'L'),  -- output
        bvalid  => 'L',              -- output
        -- Read Address Channel
        araddr  => (others => 'Z'),  -- input
        arburst => (others => 'Z'),  -- input
        arid    => (others => 'Z'),  -- input
        arlen   => (others => 'Z'),  -- input
        arprot  => (others => 'Z'),  -- input
        arready => 'L',              -- output
        arsize  => (others => 'Z'),  -- input
        aruser  => (others => 'Z'),  -- input
        arvalid => 'Z',              -- input
        -- Read Data Channel
        rdata   => (others => 'L'),  -- output
        rid     => (others => 'L'),  -- output
        rlast   => 'L',              -- output
        rready  => 'Z',              -- input
        rresp   => (others => 'L'),  -- output
        rvalid  => 'L'               -- output
    );

end package axi4;

package body axi4 is

end package body axi4;