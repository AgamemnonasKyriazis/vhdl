library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_8bit is
    generic (N : INTEGER := 8);
    port (
        reset_n : in STD_LOGIC;
        clk : in STD_LOGIC;
        a : in UNSIGNED(7 downto 0);
        b : in UNSIGNED(7 downto 0);
        r : out UNSIGNED(7 downto 0);
        c : out STD_LOGIC
    );
end adder_8bit;

architecture rtl of adder_8bit is
    -- signal c_sig : STD_LOGIC_VECTOR(1 to N-1);

    -- COMPONENT full_adder is
    -- port(
    --     i_bit1  : in STD_LOGIC;
    --     i_bit2  : in STD_LOGIC;
    --     i_carry : in STD_LOGIC;
    --     --
    --     o_sum   : out STD_LOGIC;
    --     o_carry : out STD_LOGIC
    -- );
    -- end COMPONENT;

    signal res_int : UNSIGNED(8 downto 0) := (others => '0') ;

begin

    -- FA0:full_adder port map (
    --     a(0), b(0), '0', r(0), c_sig(1)
    -- );

    -- G_0 : for i in 1 to N-2 generate
    --         FAi:full_adder port map (a(i), b(i), c_sig(i), r(i), c_sig(i+1));
    -- end generate;

    -- FAl:full_adder port map (a(N-1), b(N-1), c_sig(N-1), r(N-1), c);

    res_int <= ('0' & a) + ('0' & b);

    D_RES : process (clk) is
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                r <= (others => '0');
                c <= '0';
            else
                r <= res_int(7 downto 0);
                c <= res_int(8);
            end if;
        end if;
    end process D_RES;

end architecture;