library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi;
use axi.axis.all;

entity axis_elastic_buffer is
    generic (
        DEPTH : natural range 2 to 8 := 4
    );
    port (
        aclk        : in std_logic;
        areset_n    : in std_logic;
        s           : inout axis_t := AXIS_S_INIT;
        m           : inout axis_t := AXIS_M_INIT
    );
end axis_elastic_buffer;

architecture behavioral of axis_elastic_buffer is
    signal buf : axis_payload_array_t (DEPTH-1 downto 0) := (others => (AXIS_PAYLOAD_ZERO_INIT));
    signal wptr : unsigned (31 downto 0) := (others => '0');
    signal rptr : unsigned (31 downto 0) := (others => '0');
    signal wpar : std_logic := '0';
    signal rpar : std_logic := '0'; 
    signal fallthrough_tdata  : axis_payload_t := AXIS_PAYLOAD_ZERO_INIT;
    signal fallthrough_tvalid : std_logic := '0';
    signal full  : std_logic := '0';
    signal empty : std_logic := '0';
    signal insert : std_logic := '0';
    signal remove : std_logic := '0';
    signal m_valid_i : std_logic := '0';
begin

    full  <= '1' when (wptr = rptr) and (wpar /= rpar) else '0';
    empty <= '1' when (wptr = rptr) and (wpar  = rpar) else '0';

    m_valid_i <= '1' when empty = '0' or s.tvalid = '1' else '0';

    insert <= '1' when s.tvalid = '1' and (full = '0' or remove = '1') else '0';
    remove  <= '1' when m.tready = '1' and m_valid_i = '1' else '0';

    DBG : process (aclk) is
    begin
        if rising_edge(aclk) then
            if insert = '1' then
                report "WRITING " & to_hstring(s.tdata.tdata);
            end if;
        end if;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if insert = '1' and (full = '0' or remove = '1') then
                buf(to_integer(wptr)) <= s.tdata;
            end if;
        end if;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                wptr <= (others => '0');
                wpar <= '0';
            else
                if insert = '1' and (full = '0' or remove = '1') then
                    if wptr = DEPTH-1 then
                        wptr <= (others => '0');
                        wpar <= not wpar;
                    else
                        wptr <= wptr + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                rptr <= (others => '0');
                rpar <= '0';
            else
                if remove = '1' and (empty = '0' or insert = '1') then
                    if rptr = DEPTH-1 then
                        rptr <= (others => '0');
                        rpar <= not rpar;
                    else
                        rptr <= rptr + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (all) is
    begin
        m.tvalid <= m_valid_i;
        if empty = '1' then
            m.tdata <= s.tdata;
        else
            m.tdata <= buf(to_integer(rptr));
        end if;
    end process;

    s.tready <= not full or remove;

end architecture;
