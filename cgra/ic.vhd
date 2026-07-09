library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library axi;
use axi.axis.all;
use axi.axi4.all;

entity ic is
    generic (
        N_SLAVES    : integer := 6;
        N_MASTERS   : integer := 7
    );
    port (
        aclk      : in    std_logic;
        areset_n  : in    std_logic;
        s         : inout axis_array_t (0 to N_SLAVES-1)  := (others => AXIS_S_INIT);
        m         : inout axis_array_t (0 to N_MASTERS-1) := (others => AXIS_M_INIT)
    );
end ic;

architecture behavioral of ic is

    constant N_CTX : integer := 5;
    constant N_CTX_NUMBITS : integer := integer(ceil(log2(real(N_CTX))));

    constant SEL_NUMBITS : integer := integer(ceil(log2(real(N_SLAVES+1))));
    constant SEL_VP : std_logic_vector (SEL_NUMBITS-1 downto 0) := std_logic_vector(to_unsigned(N_SLAVES, SEL_NUMBITS)); -- virtual port
    constant VP_IDX : integer := N_SLAVES;
    constant VP : axis_payload_t := AXIS_PAYLOAD_ZERO_INIT;
    -- Slave-Select configuration as select bit of multiplexers
    -- axis_master_port (0) <= select_from (axis_slave_ports, sel(0))
    -- axis_master_port (1) <= select_from (axis_slave_ports, sel(1))
    -- ...

    signal ctx_c : unsigned (N_CTX_NUMBITS-1 downto 0) := (others => '0');
    signal ctx_n : unsigned (N_CTX_NUMBITS-1 downto 0) := to_unsigned(3, N_CTX_NUMBITS);

    type sel_array_t is array (0 to N_CTX-1, 0 to N_MASTERS-1) of std_logic_vector (SEL_NUMBITS-1 downto 0);
    signal sel : sel_array_t := (
        -- Default configuration select VP for all masters
        0 => (
            0 => SEL_VP,
            1 => SEL_VP,
            2 => SEL_VP,
            3 => SEL_VP,
            4 => "000",
            5 => "000",
            6 => SEL_VP
        ),
        1 => (
            0 => "100",
            1 => SEL_VP,
            2 => SEL_VP,
            3 => SEL_VP,
            4 => "000",
            5 => "000",
            6 => SEL_VP
        ),
        2 => (
            0 => "100",
            1 => SEL_VP,
            2 => SEL_VP,
            3 => SEL_VP,
            4 => SEL_VP,
            5 => SEL_VP,
            6 => SEL_VP
        ),
        others => (
            others => SEL_VP
        )
    );

    impure function s_port_dec (m_idx : integer) return integer is
    variable selected_slave : integer range 0 to N_SLAVES := 0;
    begin
        selected_slave := to_integer(unsigned(sel(to_integer(ctx_c), m_idx)));
        return selected_slave;
    end function;

    signal fire : std_logic := '0';

    component axis_elastic_buffer is
        generic (
            DEPTH : natural range 2 to 8 := 4
        );
        port (
            aclk        : in std_logic;
            areset_n    : in std_logic;
            s           : inout axis_t := AXIS_S_INIT;
            m           : inout axis_t := AXIS_M_INIT
        );
    end component;

    signal sE : axis_array_t (0 to N_SLAVES-1) := (others => AXIS_M_INIT);
    signal mE : axis_array_t (0 to N_MASTERS-1) := (others => AXIS_S_INIT);
begin

    process (aclk) is
    begin
        if rising_edge(aclk) then
            if areset_n = '0' then
                ctx_c <= (others => '0');
            else
                if fire = '1' then
                    if ctx_c < ctx_n - 1 then
                        ctx_c <= ctx_c + 1;
                    else
                        ctx_c <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;

    SLAVE_PORT_ELASTIC_BUFFER_GENERATOR : for i in 0 to N_SLAVES-1 generate
        uX : axis_elastic_buffer
        generic map (
            DEPTH => 2
        )
        port map(
            aclk => aclk,
            areset_n => areset_n,
            s => s(i),
            m => sE(i) 
        );
    end generate;

    MASTER_PORT_ELASTIC_BUFFER_GENERATOR : for i in 0 to N_MASTERS-1 generate
        uM : axis_elastic_buffer
        generic map (
            DEPTH => 2
        )
        port map(
            aclk => aclk,
            areset_n => areset_n,
            s => mE(i),
            m => m(i) 
        );
    end generate;

    process (all) is
        variable selected_slave : integer := 0;
        variable slave_selected : boolean := FALSE;
        variable all_slaves_valid : boolean := TRUE;
        variable all_masters_ready : boolean := TRUE;
    begin
        all_slaves_valid := TRUE;
        for m_idx in 0 to N_MASTERS-1 loop
            selected_slave := s_port_dec(m_idx);
            if selected_slave /= VP_IDX then
                all_slaves_valid := all_slaves_valid and sE(selected_slave).tvalid = '1';
            end if;
        end loop;

        all_masters_ready := TRUE;
        for m_idx in 0 to N_MASTERS-1 loop
            selected_slave := s_port_dec(m_idx);
            if selected_slave /= VP_IDX then
                all_masters_ready := all_masters_ready and mE(m_idx).tready = '1';
            end if;
        end loop;

        for m_idx in 0 to N_MASTERS-1 loop
            selected_slave := s_port_dec(m_idx);
            if selected_slave = VP_IDX then
                mE(m_idx).tdata  <= VP;
                mE(m_idx).tvalid <= '0';
            else
                mE(m_idx).tdata  <= sE(selected_slave).tdata;
                mE(m_idx).tvalid <= '1' when all_slaves_valid and all_masters_ready else '0';
            end if;
        end loop;

        for s_idx in 0 to N_SLAVES-1 loop
            slave_selected := FALSE;
            for m_idx in 0 to N_MASTERS-1 loop
                if s_port_dec(m_idx) = s_idx then
                    slave_selected := TRUE;
                end if;
            end loop;
            if slave_selected then
                sE(s_idx).tready <= '1' when all_slaves_valid and all_masters_ready else '0';
            else
                sE(s_idx).tready <= '0';
            end if;
        end loop;

        fire <= '1' when all_slaves_valid and all_masters_ready else '0';
    end process;

end architecture behavioral;
