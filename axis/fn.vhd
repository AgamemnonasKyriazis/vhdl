library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use IEEE.math_real.all;

library axis;
use axis.axis_pkg.all;

entity fn is
    generic (
        DATA_WIDTH : integer := 32
    );
    port (
        aclk        : in std_logic;
        areset_n    : in std_logic;

        s0_tdata    : in    std_logic_vector(31 downto 0);
        s0_tvalid   : in    std_logic;
        s0_tready   : out   std_logic := '0';
        s0_tlast    : in    std_logic;
        s0_tkeep    : in    std_logic_vector(3 downto 0);
        s0_tid      : in    std_logic_vector(7 downto 0);
        s0_tdest    : in    std_logic_vector(7 downto 0);
        s0_tuser    : in    std_logic_vector(7 downto 0);

        s1_tdata    : in    std_logic_vector(31 downto 0);
        s1_tvalid   : in    std_logic;
        s1_tready   : out   std_logic := '0';
        s1_tlast    : in    std_logic;
        s1_tkeep    : in    std_logic_vector(3 downto 0);
        s1_tid      : in    std_logic_vector(7 downto 0);
        s1_tdest    : in    std_logic_vector(7 downto 0);
        s1_tuser    : in    std_logic_vector(7 downto 0);

        s2_tdata    : in    std_logic_vector(31 downto 0);
        s2_tvalid   : in    std_logic;
        s2_tready   : out   std_logic := '0';
        s2_tlast    : in    std_logic;
        s2_tkeep    : in    std_logic_vector(3 downto 0);
        s2_tid      : in    std_logic_vector(7 downto 0);
        s2_tdest    : in    std_logic_vector(7 downto 0);
        s2_tuser    : in    std_logic_vector(7 downto 0);

        s3_tdata    : in    std_logic_vector(31 downto 0);
        s3_tvalid   : in    std_logic;
        s3_tready   : out   std_logic := '0';
        s3_tlast    : in    std_logic;
        s3_tkeep    : in    std_logic_vector(3 downto 0);
        s3_tid      : in    std_logic_vector(7 downto 0);
        s3_tdest    : in    std_logic_vector(7 downto 0);
        s3_tuser    : in    std_logic_vector(7 downto 0);

        m0_tdata    : out   std_logic_vector(31 downto 0);
        m0_tvalid   : out   std_logic := '0';
        m0_tready   : in    std_logic;
        m0_tlast    : out   std_logic;
        m0_tkeep    : out   std_logic_vector(3 downto 0);
        m0_tid      : out   std_logic_vector(7 downto 0);
        m0_tdest    : out   std_logic_vector(7 downto 0);
        m0_tuser    : out   std_logic_vector(7 downto 0);

        m1_tdata    : out   std_logic_vector(31 downto 0);
        m1_tvalid   : out   std_logic := '0';
        m1_tready   : in    std_logic;
        m1_tlast    : out   std_logic;
        m1_tkeep    : out   std_logic_vector(3 downto 0);
        m1_tid      : out   std_logic_vector(7 downto 0);
        m1_tdest    : out   std_logic_vector(7 downto 0);
        m1_tuser    : out   std_logic_vector(7 downto 0);

        m2_tdata    : out   std_logic_vector(31 downto 0);
        m2_tvalid   : out   std_logic := '0';
        m2_tready   : in    std_logic;
        m2_tlast    : out   std_logic;
        m2_tkeep    : out   std_logic_vector(3 downto 0);
        m2_tid      : out   std_logic_vector(7 downto 0);
        m2_tdest    : out   std_logic_vector(7 downto 0);
        m2_tuser    : out   std_logic_vector(7 downto 0);

        m3_tdata    : out   std_logic_vector(31 downto 0);
        m3_tvalid   : out   std_logic := '0';
        m3_tready   : in    std_logic;
        m3_tlast    : out   std_logic;
        m3_tkeep    : out   std_logic_vector(3 downto 0);
        m3_tid      : out   std_logic_vector(7 downto 0);
        m3_tdest    : out   std_logic_vector(7 downto 0);
        m3_tuser    : out   std_logic_vector(7 downto 0)
    );
end fn;

architecture behavioral of fn is

    constant N_SLAVES    : integer := 5;
    constant N_MASTERS   : integer := 4;
    constant SEL_NUMBITS : integer := integer(ceil(log2(real(N_SLAVES))));

    component axis_xbar_s_to_m
        generic (
            N_SLAVES    : integer;
            N_MASTERS   : integer
        );
        port (
            aclk        : in    std_logic;
            areset_n    : in    std_logic;
            sel0        : in    std_logic_vector (SEL_NUMBITS-1 downto 0);
            sel1        : in    std_logic_vector (SEL_NUMBITS-1 downto 0);
            sel2        : in    std_logic_vector (SEL_NUMBITS-1 downto 0);
            sel3        : in    std_logic_vector (SEL_NUMBITS-1 downto 0);
            s           : inout axis_array_t (0 to N_SLAVES-1);
            m           : inout axis_array_t (0 to N_MASTERS-1);
            err         : out   std_logic
        );
    end component axis_xbar_s_to_m;

    signal s : axis_array_t (0 to N_SLAVES-1);
    signal m : axis_array_t (0 to N_MASTERS-1);

    signal s0_i : axis_t := AXIS_S_INIT;
    signal s1_i : axis_t := AXIS_S_INIT;
    signal s2_i : axis_t := AXIS_S_INIT;
    signal s3_i : axis_t := AXIS_S_INIT;
    signal s4_i : axis_t := AXIS_S_INIT;

    signal m0_i : axis_t := AXIS_M_INIT;
    signal m1_i : axis_t := AXIS_M_INIT;
    signal m2_i : axis_t := AXIS_M_INIT;
    signal m3_i : axis_t := AXIS_M_INIT;

    signal sel0 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "000";
    signal sel1 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "001";
    signal sel2 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "100";
    signal sel3 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "001";

    signal err  : std_logic;

    signal fu_a_tdata   : std_logic_vector(31 downto 0) := (others => '0');
    signal fu_a_tvalid  : std_logic := '0';
    signal fu_a_tready  : std_logic := '0';
    signal fu_a_tlast   : std_logic := '0';
    signal fu_a_tkeep   : std_logic_vector(3 downto 0) := (others => '0');
    signal fu_a_tid     : std_logic_vector(7 downto 0) := (others => '0');
    signal fu_a_tdest   : std_logic_vector(7 downto 0) := (others => '0');
    signal fu_a_tuser   : std_logic_vector(7 downto 0) := (others => '0');

    signal fu_b_tdata   : std_logic_vector(31 downto 0) := (others => '0');
    signal fu_b_tvalid  : std_logic := '0';
    signal fu_b_tready  : std_logic := '0';
    signal fu_b_tlast   : std_logic := '0';
    signal fu_b_tkeep   : std_logic_vector(3 downto 0) := (others => '0');
    signal fu_b_tid     : std_logic_vector(7 downto 0) := (others => '0');
    signal fu_b_tdest   : std_logic_vector(7 downto 0) := (others => '0');
    signal fu_b_tuser   : std_logic_vector(7 downto 0) := (others => '0');

    signal fu_tdata     : std_logic_vector(31 downto 0) := (others => '0');
    signal fu_tvalid    : std_logic := '0';
    signal fu_tready    : std_logic := '0';
    signal fu_tlast     : std_logic := '0';
    signal fu_tkeep     : std_logic_vector(3 downto 0) := (others => '0');
    signal fu_tid       : std_logic_vector(7 downto 0) := (others => '0');
    signal fu_tdest     : std_logic_vector(7 downto 0) := (others => '0');
    signal fu_tuser     : std_logic_vector(7 downto 0) := (others => '0');

    signal both_inputs_valid : std_logic := '0';
    signal input_a_valid : std_logic := '0';
    signal input_b_valid : std_logic := '0';
    signal input_a_data_buf : std_logic_vector(31 downto 0) := (others => '0');
    signal input_b_data_buf : std_logic_vector(31 downto 0) := (others => '0');
begin

    DBG : process(aclk)
    begin
        if rising_edge(aclk) and both_inputs_valid = '1' then
            report "Both inputs are valid, ready to process. " & 
            "s0_tdata (dec)=" & integer'image(to_integer(unsigned(input_a_data_buf))) & 
            " s1_tdata (dec)=" & integer'image(to_integer(unsigned(input_b_data_buf)));
        end if;
    end process;

    u0_axis_xbar_s_to_m : axis_xbar_s_to_m
        generic map(
            N_SLAVES  => 5,
            N_MASTERS => 4
        )
        port map (
            aclk        => aclk,
            areset_n    => areset_n,

            -- Configuration Control Routing
            sel0        => sel0,
            sel1        => sel1,
            sel2        => sel2,
            sel3        => sel3,

            -- AXIS Data Routing
            s(0)        => s0_i,
            s(1)        => s1_i,
            s(2)        => s2_i,
            s(3)        => s3_i,
            s(4)        => s4_i,

            m(0)        => m0_i,
            m(1)        => m1_i,
            m(2)        => m2_i,
            m(3)        => m3_i,

            -- Error Status out
            err         => err
        );

    -- s0-s3 are connected to the PE inputs.
    s0_i.tdata   <= s0_tdata;
    s0_i.tvalid  <= s0_tvalid;
    s0_tready    <= s0_i.tready;
    s0_i.tlast   <= s0_tlast;
    s0_i.tkeep   <= s0_tkeep;
    s0_i.tid     <= s0_tid;
    s0_i.tdest   <= s0_tdest;
    s0_i.tuser   <= s0_tuser;

    s1_i.tdata   <= s1_tdata;
    s1_i.tvalid  <= s1_tvalid;
    s1_tready    <= s1_i.tready;
    s1_i.tlast   <= s1_tlast;
    s1_i.tkeep   <= s1_tkeep;
    s1_i.tid     <= s1_tid;
    s1_i.tdest   <= s1_tdest;
    s1_i.tuser   <= s1_tuser;
    
    s2_i.tdata   <= s2_tdata;
    s2_i.tvalid  <= s2_tvalid;
    s2_tready    <= s2_i.tready;
    s2_i.tlast   <= s2_tlast;
    s2_i.tkeep   <= s2_tkeep;
    s2_i.tid     <= s2_tid;
    s2_i.tdest   <= s2_tdest;
    s2_i.tuser   <= s2_tuser;

    s3_i.tdata   <= s3_tdata;
    s3_i.tvalid  <= s3_tvalid;
    s3_tready    <= s3_i.tready;
    s3_i.tlast   <= s3_tlast;
    s3_i.tkeep   <= s3_tkeep;
    s3_i.tid     <= s3_tid;
    s3_i.tdest   <= s3_tdest;
    s3_i.tuser   <= s3_tuser;

    -- m2 of XBAR is connected to m0 of the PE output.
    m2_i.tready   <= m0_tready;
    m0_tdata      <= m2_i.tdata;
    m0_tvalid     <= m2_i.tvalid;
    m0_tlast      <= m2_i.tlast;
    m0_tkeep      <= m2_i.tkeep;
    m0_tid        <= m2_i.tid;
    m0_tdest      <= m2_i.tdest;
    m0_tuser      <= m2_i.tuser;

    -- Which XBAR mX ports connect to the function unit (FU) inputs.
    -- m0 is connected to FU input A.
    fu_a_tdata   <= m0_i.tdata;
    fu_a_tvalid  <= m0_i.tvalid;
    m0_i.tready  <= fu_a_tready;
    fu_a_tlast   <= m0_i.tlast;
    fu_a_tkeep   <= m0_i.tkeep;
    fu_a_tid     <= m0_i.tid;
    fu_a_tdest   <= m0_i.tdest;
    fu_a_tuser   <= m0_i.tuser;

    -- m1 is connected to FU input B.
    fu_b_tdata   <= m1_i.tdata;
    fu_b_tvalid  <= m1_i.tvalid;
    m1_i.tready  <= fu_b_tready;
    fu_b_tlast   <= m1_i.tlast;
    fu_b_tkeep   <= m1_i.tkeep;
    fu_b_tid     <= m1_i.tid;
    fu_b_tdest   <= m1_i.tdest;
    fu_b_tuser   <= m1_i.tuser;

    -- and s4 is connected to the FU output.
    s4_i.tdata    <= fu_tdata;
    s4_i.tvalid   <= fu_tvalid;
    fu_tready     <= s4_i.tready;
    s4_i.tlast    <= fu_tlast;
    s4_i.tkeep    <= fu_tkeep;
    s4_i.tid      <= fu_tid;
    s4_i.tdest    <= fu_tdest;
    s4_i.tuser    <= fu_tuser;

    -- XBAR m3 is connected to FN m1
    m3_i.tready   <= m1_tready;
    m1_tdata      <= m3_i.tdata;
    m1_tvalid     <= m3_i.tvalid;
    m1_tlast      <= m3_i.tlast;
    m1_tkeep      <= m3_i.tkeep;
    m1_tid        <= m3_i.tid;
    m1_tdest      <= m3_i.tdest;
    m1_tuser      <= m3_i.tuser;

    process(aclk)
    begin
        if (rising_edge(aclk)) then
            if areset_n = '0' then
                fu_a_tready <= '1';
            else
                if fu_a_tvalid = '1' and fu_a_tready = '1' and input_a_valid = '0' then
                    fu_a_tready <= '0';
                    input_a_data_buf <= fu_a_tdata; -- Buffer the input data for later use
                end if;

                if both_inputs_valid = '1' then
                    fu_a_tready <= '1';
                end if;
            end if;
        end if;
    end process;

    process(aclk)
    begin
        if (rising_edge(aclk)) then
            if areset_n = '0' then
                fu_b_tready <= '1';
            else
                if fu_b_tvalid = '1' and fu_b_tready = '1' and input_b_valid = '0' then
                    fu_b_tready <= '0';
                    input_b_data_buf <= fu_b_tdata; -- Buffer the input data for later use
                end if;

                if both_inputs_valid = '1' then
                    fu_b_tready <= '1';
                end if;
            end if;
        end if;
    end process;

    process(aclk)
    begin
        if (rising_edge(aclk)) then
            if areset_n = '0' then
                input_a_valid <= '0';
                input_b_valid <= '0';
            else
                if both_inputs_valid = '1' then
                    input_a_valid <= '0';
                    input_b_valid <= '0';
                else
                    if fu_a_tvalid = '1' and fu_a_tready = '1' then
                        input_a_valid <= '1';
                    end if;

                    if fu_b_tvalid = '1' and fu_b_tready = '1' then
                        input_b_valid <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    both_inputs_valid <= input_a_valid and input_b_valid;

    process(aclk)
    begin
        if (rising_edge(aclk)) then
            if areset_n = '0' then
                fu_tdata <= (others => '0');
                fu_tvalid <= '0';
            else
                if both_inputs_valid = '1' then
                    fu_tdata    <= std_logic_vector(unsigned(input_a_data_buf) + unsigned(input_b_data_buf));
                    fu_tvalid   <= '1';
                    fu_tlast    <= '1';
                elsif fu_tvalid = '1' and fu_tready = '1' then
                    fu_tvalid <= '0';
                else
                    fu_tvalid <= fu_tvalid;
                end if;

            end if;
        end if;
    end process;

end architecture behavioral;