library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi;
use axi.axis.all;

entity axis_skid_buffer is
    port (
        aclk     : in    std_logic;
        areset_n : in    std_logic;
        s        : inout axis_t := AXIS_S_INIT;
        m        : inout axis_t := AXIS_M_INIT;
        bd       : out   axis_payload_t := (
            tdata  => (others => '0'),
            tlast  => '0',
            tkeep  => (others => '0'),
            tid    => (others => '0'),
            tdest  => (others => '0'),
            tuser  => (others => '0')
        );
        bd_full : out std_logic := '0'
    );
end axis_skid_buffer;

architecture behavioral of axis_skid_buffer is

    type mode_t is (BPS, BUF);
    signal mode : mode_t := BPS;
    signal full : std_logic := '0';

    signal buf : axis_payload_t := (
        tdata  => (others => '0'),
        tlast  => '0',
        tkeep  => (others => '0'),
        tid    => (others => '0'),
        tdest  => (others => '0'),
        tuser  => (others => '0')
    );
    signal buf_valid : std_logic := '0';

begin

    mode <= BUF when full = '1' else BPS;

    s.tready <= not full;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                full <= '0';
            else
                if m.tready = '0' then
                    if s.tvalid = '1' then
                        full <= '1';
                    end if;
                else
                    if full = '1' then
                        full <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                buf_valid <= '0';
                buf <= AXIS_PAYLOAD_ZERO_INIT;
            else
                if full = '0' then
                    buf_valid <= s.tvalid;
                    buf <= s.tdata;
                end if;
            end if;
        end if;
    end process;

    process (all) is
    begin
        if mode = BPS then
            m.tvalid <= s.tvalid;
            m.tdata  <= s.tdata;
        else
            m.tvalid <= buf_valid;
            m.tdata  <= buf;
        end if;
    end process;

    bd_full <= full;
    bd <= buf;


end architecture;