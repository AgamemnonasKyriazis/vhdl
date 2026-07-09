library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axis is

  -- AXI Stream data width
  constant AXIS_DATA_WIDTH  : integer := 32;
  -- AXI Stream user signal width
  constant AXIS_USER_WIDTH  : integer := 8;
  -- AXI Stream ID signal width
  constant AXIS_ID_WIDTH    : integer := 8;
  -- AXI Stream destination signal width
  constant AXIS_DEST_WIDTH  : integer := 8;
  -- AXI Stream keep width
  constant AXIS_KEEP_WIDTH  : integer := (AXIS_DATA_WIDTH/8);

  type axis_payload_t is record
    tdata  : std_logic_vector (AXIS_DATA_WIDTH-1 downto 0);
    tlast  : std_logic;
    tkeep  : std_logic_vector (AXIS_KEEP_WIDTH-1 downto 0);
    tid    : std_logic_vector (AXIS_ID_WIDTH-1 downto 0);
    tdest  : std_logic_vector (AXIS_DEST_WIDTH-1 downto 0);
    tuser  : std_logic_vector (AXIS_USER_WIDTH-1 downto 0);
  end record axis_payload_t;

  type axis_payload_array_t is array (natural range <>) of axis_payload_t;

  type axis_t is record
    tready : std_logic;
    tvalid : std_logic;
    tdata  : axis_payload_t;
  end record axis_t;

  type axis_array_t is array (natural range <>) of axis_t;

  constant AXIS_S_INIT : axis_t := (
    tready => 'L',
    tvalid => 'Z',
    tdata  => (
      tdata => (others => 'Z'),
      tlast  => 'Z',
      tkeep  => (others => 'Z'),
      tid    => (others => 'Z'),
      tdest  => (others => 'Z'),
      tuser  => (others => 'Z')
    )
  );

  constant AXIS_M_INIT : axis_t := (
    tready => 'Z',
    tvalid => 'L',
    tdata  => (
      tdata => (others => 'L'),
      tlast  => 'L',
      tkeep  => (others => 'L'),
      tid    => (others => 'L'),
      tdest  => (others => 'L'),
      tuser  => (others => 'L')
    )
  );

  constant AXIS_PAYLOAD_ZERO_INIT : axis_payload_t := (
    tdata => (others => '0'),
    tlast => '0',
    tkeep => (others => '0'),
    tid   => (others => '0'),
    tdest => (others => '0'),
    tuser => (others => '0')
  );

end package axis;

package body axis is

end package body axis;