library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

library axi;
use axi.axis.all;
use axi.axi4.all;

entity fn is
    generic (
        DATA_WIDTH : integer := 32
    );
    port (
        aclk        : in std_logic;
        areset_n    : in std_logic;
        sA          : inout axis_t := AXIS_S_INIT;
        sB          : inout axis_t := AXIS_S_INIT;
        mC          : inout axis_t := AXIS_M_INIT
    );
end fn;

architecture behavioral of fn is

    signal a_and_b_valid : std_logic := '0';
    signal alu_r : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    type alu_opcode_t is (ALU_ADD, ALU_SUB, ALU_MUL, ALU_SRL, ALU_SLL);
    signal alu_opcode : alu_opcode_t := ALU_ADD;
    signal ready : std_logic := '0';
begin

    sA.tready <= mC.tready and a_and_b_valid;
    sB.tready <= mC.tready and a_and_b_valid;

    a_and_b_valid <= sA.tvalid and sB.tvalid;

    ALU : process (all) is
    variable a : unsigned(DATA_WIDTH-1 downto 0) := (others => '0');
    variable b : unsigned(DATA_WIDTH-1 downto 0) := (others => '0');
    variable shamt : natural range 0 to DATA_WIDTH-1 := 0;
    variable r : unsigned(DATA_WIDTH-1 downto 0) := (others => '0');
    begin
        r := (others => '0');

        if a_and_b_valid = '1' then
            a  := unsigned(sA.tdata.tdata);
            b  := unsigned(sB.tdata.tdata);
            shamt := to_integer(unsigned(sB.tdata.tdata(4 downto 0)));

            case alu_opcode is
                when ALU_SUB => r := a - b;
                when ALU_MUL => r := resize(a * b, r'length);
                when ALU_SRL => r := shift_right(a, shamt);
                when ALU_SLL => r := shift_left(a, shamt);
                when others  => r := a + b;
            end case;
        end if;

        alu_r <= std_logic_vector(r);
    end process;

    mC.tdata <= (
    tdata => alu_r,
    tlast => sA.tdata.tlast and sB.tdata.tlast,
    tkeep => sA.tdata.tkeep and sB.tdata.tkeep,
    tid   => sA.tdata.tid   and sB.tdata.tid,
    tdest => sA.tdata.tdest and sB.tdata.tdest,
    tuser => sA.tdata.tuser and sB.tdata.tuser
    );
    mC.tvalid <= a_and_b_valid;

end architecture behavioral;
