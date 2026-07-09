library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

library axi;
use axi.axis.all;
use axi.axi4.all;

entity axis_xbar_s_to_m is
    generic (
        N_SLAVES    : integer := 6;
        N_MASTERS   : integer := 7;
        SEL_NUMBITS : integer := integer(ceil(log2(real(N_SLAVES+1))))
    );
    port (
        aclk      : in    std_logic;
        areset_n  : in    std_logic;
        s         : inout axis_array_t (0 to N_SLAVES-1)  := (others => AXIS_S_INIT);
        m         : inout axis_array_t (0 to N_MASTERS-1) := (others => AXIS_M_INIT)
    );
end axis_xbar_s_to_m;

architecture behavioral of axis_xbar_s_to_m is

    -- Slave-Select configuration as select bit of multiplexers
    -- axis_master_port (0) <= select_from (axis_slave_ports, sel(0))
    -- axis_master_port (1) <= select_from (axis_slave_ports, sel(1))
    -- ...
    type sel_array_t is array (0 to N_MASTERS-1) of std_logic_vector (SEL_NUMBITS-1 downto 0);
    signal sel : sel_array_t := (
        -- Default configuration select VP for all masters
        -- others => (std_logic_vector(to_unsigned(N_SLAVES, SEL_NUMBITS)))
        0 => "100",
        1 => "110",
        2 => "110",
        3 => "110",
        4 => "000",
        5 => "000",
        6 => "110"
    );

    -- Virtual Port (VP)
    -- Always the Nth Slave Port
    -- Always ready (blackhole)
    constant axis_virtual_port : axis_t := (
        tready => '1',
        tvalid => '0',
        tdata  => AXIS_PAYLOAD_ZERO_INIT
    );

    signal m_mux : axis_array_t (0 to N_MASTERS-1) := (others => AXIS_M_INIT);
    signal m_reg : axis_array_t (0 to N_MASTERS-1) := (others => AXIS_M_INIT);
    
    signal sI : axis_array_t (0 to N_SLAVES) := (others => AXIS_S_INIT);

begin

    process(all) is
    begin
        for i in 0 to N_SLAVES-1 loop
            s(i).tready   <= sI(i).tready;
            sI(i).tvalid  <= s(i).tvalid;
            sI(i).tdata   <= s(i).tdata;
        end loop;
        sI(N_SLAVES).tready <= axis_virtual_port.tready;
        sI(N_SLAVES).tvalid <= axis_virtual_port.tvalid;
        sI(N_SLAVES).tdata  <= axis_virtual_port.tdata;
    end process;

    process (all) is
    begin
        for i in 0 to N_MASTERS-1 loop
            m_mux(i).tready <= m_reg(i).tready;
            m_mux(i).tvalid <= sI(to_integer(unsigned(sel(i)))).tvalid;
            m_mux(i).tdata  <= sI(to_integer(unsigned(sel(i)))).tdata;
        end loop;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                for i in 0 to N_MASTERS-1 loop
                    m_reg(i).tready <= '0';
                end loop;
            else
                for i in 0 to N_MASTERS-1 loop
                    if m_reg(i).tvalid = '0' then
                        m_reg(i).tready <= '1';
                        if m_mux(i).tvalid = '1' and sI(to_integer(unsigned(sel(i)))).tready = '1' then
                            m_reg(i).tready <= '0';
                        end if;
                    else
                        m_reg(i).tready <= '0';
                    end if;
                end loop;
            end if;
        end if;
    end process;

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                for i in 0 to N_MASTERS-1 loop
                    m_reg(i).tdata  <= AXIS_PAYLOAD_ZERO_INIT;
                    m_reg(i).tvalid <= '0';
                end loop;
            else
                for i in 0 to N_MASTERS-1 loop
                    if m_reg(i).tvalid = '0' then
                        if m_mux(i).tvalid = '1' and sI(to_integer(unsigned(sel(i)))).tready = '1' then
                            m_reg(i).tdata  <= m_mux(i).tdata;
                            m_reg(i).tvalid <= '1';
                        end if;
                    else
                        if m_reg(i).tvalid = '1' and m(i).tready = '1' then
                            m_reg(i).tvalid <= '0';
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    process (all) is
        variable s_tready_v : std_logic_vector (N_SLAVES downto 0) := (others => '0');
        variable sel_vector : std_logic_vector (N_SLAVES downto 0) := (others => '0');
    begin
        s_tready_v   := (others => '1');

        for i in 0 to N_MASTERS-1 loop
            sel_vector := (others => '0');
            sel_vector(to_integer(unsigned(sel(i)))) := '1';
            for j in 0 to N_SLAVES loop
                if sel_vector(j) = '1' then
                    s_tready_v(j) := s_tready_v(j) and m_mux(i).tready;
                else
                    s_tready_v(j) := s_tready_v(j) and '1';
                end if;
            end loop;
        end loop;

        for s_idx in 0 to N_SLAVES-1 loop
            sI(s_idx).tready <= s_tready_v(s_idx);
        end loop;
    end process;

    process (all) is
    begin
        for i in 0 to N_MASTERS-1 loop
            m(i).tdata  <= m_reg(i).tdata;
            m(i).tvalid <= m_reg(i).tvalid;
        end loop;
    end process;

end architecture behavioral;