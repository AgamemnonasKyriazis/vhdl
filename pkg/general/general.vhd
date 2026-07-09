library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library axi;
use axi.axis.all;

package general is

    constant DATA_WIDTH : integer := 32;
    constant DATA_STRB  : integer := DATA_WIDTH/8;

    -- Register File
    constant N_REGS : natural range 1 to 32 := 8;
    constant REG_SEL_WIDTH : integer := integer(ceil(log2(real(N_REGS))));

    type regfile_write_in_t is record
        sel  : std_logic_vector(REG_SEL_WIDTH-1 downto 0);
        data : axis_payload_t;
        we   : std_logic;
        strb : std_logic_vector(DATA_STRB-1 downto 0);
    end record;

    type regfile_read_in_t is record
        sel  : std_logic_vector(REG_SEL_WIDTH-1 downto 0);
    end record;

    type regfile_read_out_t is record
        data : axis_payload_t;
    end record;

    type regfile_write_in_array_t is array (natural range <>) of regfile_write_in_t;
    type regfile_read_in_array_t  is array (natural range <>) of regfile_read_in_t;
    type regfile_read_out_array_t is array (natural range <>) of regfile_read_out_t;

end package general;

package body general is
end package body general;
