library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axis_pkg is

  -- AXI Stream data width
  constant AXIS_DATA_WIDTH : integer := 32;

  -- AXI Stream user signal width
  constant AXIS_USER_WIDTH : integer := 8;

  -- AXI Stream ID signal width
  constant AXIS_ID_WIDTH : integer := 8;

  -- AXI Stream destination signal width
  constant AXIS_DEST_WIDTH : integer := 8;

  type axis_t is record
    tdata  : std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
    tvalid : std_logic;
    tready : std_logic;
    tlast  : std_logic;
    tkeep  : std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
    tid    : std_logic_vector(AXIS_ID_WIDTH-1 downto 0);
    tdest  : std_logic_vector(AXIS_DEST_WIDTH-1 downto 0);
    tuser  : std_logic_vector(AXIS_USER_WIDTH-1 downto 0);
  end record axis_t;

  type axis_array_t is array (natural range <>) of axis_t;

  constant AXIS_S_INIT : axis_t := (
    tdata  => (others => 'Z'),
    tvalid => 'Z',
    tready => 'L',
    tlast  => 'Z',
    tkeep  => (others => 'Z'),
    tid    => (others => 'Z'),
    tdest  => (others => 'Z'),
    tuser  => (others => 'Z')
  );

  constant AXIS_M_INIT : axis_t := (
    tdata  => (others => 'L'),
    tvalid => 'L',
    tready => 'Z',
    tlast  => 'L',
    tkeep  => (others => 'L'),
    tid    => (others => 'L'),
    tdest  => (others => 'L'),
    tuser  => (others => 'L')
  );

end package axis_pkg;

package body axis_pkg is

end package body axis_pkg;