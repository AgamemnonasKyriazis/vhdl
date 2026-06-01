library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use IEEE.math_real.all;
library axis;
use axis.axis_pkg.all;

entity axis_xbar_s_to_m is
    generic (
        N_SLAVES    : integer := 5;
        N_MASTERS   : integer := 4;
        SEL_NUMBITS : integer := integer(ceil(log2(real(N_SLAVES))))
    );
    port (
        aclk      : in    std_logic;
        areset_n  : in    std_logic;
        
        sel0      : in    std_logic_vector (SEL_NUMBITS-1 downto 0);
        sel1      : in    std_logic_vector (SEL_NUMBITS-1 downto 0);
        sel2      : in    std_logic_vector (SEL_NUMBITS-1 downto 0);
        sel3      : in    std_logic_vector (SEL_NUMBITS-1 downto 0);
        
        s         : inout axis_array_t (0 to N_SLAVES-1)  := (others => AXIS_S_INIT);
        m         : inout axis_array_t (0 to N_MASTERS-1) := (others => AXIS_M_INIT);
        
        err       : out std_logic
    );
end axis_xbar_s_to_m;

architecture behavioral of axis_xbar_s_to_m is
    signal m_mux : axis_array_t (0 to N_MASTERS-1) := (others => AXIS_M_INIT);
    signal m_reg : axis_array_t (0 to N_MASTERS-1) := (others => AXIS_M_INIT);
    type sel_array_t is array (0 to N_MASTERS-1) of std_logic_vector (SEL_NUMBITS-1 downto 0);
    signal sel   : sel_array_t;
    signal is_valid : std_logic_vector(0 to N_MASTERS-1) := (others => '0'); 
begin

    err <= '0';

    sel(0) <= sel0;
    sel(1) <= sel1;
    sel(2) <= sel2;
    sel(3) <= sel3;

    process (all) is
    begin
        for i in 0 to N_MASTERS-1 loop
            m_mux(i).tdata  <= (others => 'L');
            m_mux(i).tvalid <= 'L';
            m_mux(i).tready <= m_reg(i).tready;
            -- Multiplexed values
            m_mux(i).tdata  <= s(to_integer(unsigned(sel(i)))).tdata;
            m_mux(i).tvalid <= s(to_integer(unsigned(sel(i)))).tvalid;
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
                    if is_valid(i) = '0' then
                        m_reg(i).tready <= '1';
                        if m_mux(i).tvalid = '1' and s(to_integer(unsigned(sel(i)))).tready = '1' then
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
                    m_reg(i).tvalid <= '0';
                    m_reg(i).tdata  <= (others => '0');
                    is_valid(i)     <= '0';
                end loop;
            else
                for i in 0 to N_MASTERS-1 loop
                    if is_valid(i) = '0' then
                        if m_mux(i).tvalid = '1' and s(to_integer(unsigned(sel(i)))).tready = '1' then
                            m_reg(i).tvalid <= '1';
                            m_reg(i).tdata  <= m_mux(i).tdata;
                            is_valid(i)     <= '1';
                        end if;
                    else
                        if m_reg(i).tvalid = '1' and m(i).tready = '1' then
                            m_reg(i).tvalid <= '0';
                            is_valid(i)     <= '0';
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    process (all) is
        variable s_tready_v   : std_logic_vector (N_SLAVES-1 downto 0) := (others => '0');
        variable sel_vector : std_logic_vector (N_SLAVES-1 downto 0) := (others => '0');
    begin
        s_tready_v   := (others => '1');

        for i in 0 to 3 loop
            sel_vector := (others => '0');
            sel_vector(to_integer(unsigned(sel(i)))) := '1';
            for j in 0 to 4 loop
                if sel_vector(j) = '1' then
                    s_tready_v(j) := s_tready_v(j) and m_mux(i).tready;
                else
                    s_tready_v(j) := s_tready_v(j) and '1';
                end if;
            end loop;
        end loop;

        for s_idx in 0 to 4 loop
            s(s_idx).tready <= s_tready_v(s_idx);
        end loop;
    end process;

    process (all) is
    begin
        for i in 0 to 3 loop
            m(i).tdata  <= m_reg(i).tdata;
            m(i).tvalid <= m_reg(i).tvalid;
        end loop;
    end process;

    -- m(0).tdata;
    -- m(0).tvalid;
    m(0).tlast    <= '1';
    m(0).tkeep    <= (others => '1');
    m(0).tid      <= (others => '0');
    m(0).tdest    <= (others => '0');
    m(0).tuser    <= (others => '0');

    -- m(1).tdata;
    -- m(1).tvalid;
    m(1).tlast    <= '1';
    m(1).tkeep    <= (others => '1');
    m(1).tid      <= (others => '0');
    m(1).tdest    <= (others => '0');
    m(1).tuser    <= (others => '0');

    -- m(2).tdata;
    -- m(2).tvalid;
    m(2).tlast    <= '1';
    m(2).tkeep    <= (others => '1');
    m(2).tid      <= (others => '0');
    m(2).tdest    <= (others => '0');
    m(2).tuser    <= (others => '0');

    -- m(3).tdata;
    -- m(3).tvalid;
    m(3).tlast    <= '1';
    m(3).tkeep    <= (others => '1');
    m(3).tid      <= (others => '0');
    m(3).tdest    <= (others => '0');
    m(3).tuser    <= (others => '0');

end architecture behavioral;