library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi;
use axi.axis.all;
use axi.axi4.all;

entity axis_elastic_join is
    generic (
        N : positive := 2
    );
    port (
        aclk        : in std_logic;
        areset_n    : in std_logic;
        s           : inout axis_array_t (0 to N-1) := (others => AXIS_S_INIT);
        m           : inout axis_array_t (0 to N-1) := (others => AXIS_M_INIT)
    );
end axis_elastic_join;

architecture behavioral of axis_elastic_join is
    signal ready_vec : std_logic_vector (0 to N-1) := (others => '0');
    signal valid_vec : std_logic_vector (0 to N-1) := (others => '0');
    signal m_ready_vec : std_logic_vector (0 to N-1) := (others => '0');
    signal valid : std_logic := '0';
    signal ready : std_logic := '0';
    signal b : axis_payload_array_t (0 to N-1) := (others => AXIS_PAYLOAD_ZERO_INIT);
begin

    G0 : for i in 0 to N-1 generate
    begin

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                ready_vec(i) <= '1';
                valid_vec(i) <= '0';
                b(i) <= AXIS_PAYLOAD_ZERO_INIT;
            else
                if valid_vec(i) = '0' then
                    if ready_vec(i) = '1' then
                        if s(i).tvalid = '1' then
                            valid_vec(i) <= '1';
                            ready_vec(i) <= '0';
                            b(i) <= s(i).tdata;
                        end if;
                    end if;
                else
                    if valid = '1' and ready = '1' then
                        valid_vec(i) <= '0';
                        ready_vec(i) <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

        s(i).tready <= ready_vec(i);
        m_ready_vec(i) <= m(i).tready;
        m(i).tvalid <= valid;
        m(i).tdata  <= b(i);

    end generate G0;

    valid <= and valid_vec;
    ready <= and m_ready_vec;

end architecture;
