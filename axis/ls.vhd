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
            sel0        : in    std_logic_vector(SEL_NUMBITS-1 downto 0);
            sel1        : in    std_logic_vector(SEL_NUMBITS-1 downto 0);
            sel2        : in    std_logic_vector(SEL_NUMBITS-1 downto 0);
            sel3        : in    std_logic_vector(SEL_NUMBITS-1 downto 0);
            s           : inout axis_array_t (0 to N_SLAVES-1);
            m           : inout axis_array_t (0 to N_MASTERS-1);
            err         : out   std_logic
        );
    end component axis_xbar_s_to_m;

    signal s : axis_array_t (0 to N_SLAVES-1)  := (others => AXIS_S_INIT);
    signal m : axis_array_t (0 to N_MASTERS-1) := (others => AXIS_M_INIT);

    signal sel0 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "000";
    signal sel1 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "001";
    signal sel2 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "100";
    signal sel3 : std_logic_vector(SEL_NUMBITS-1 downto 0) := "001";

    signal err  : std_logic;

begin

    u0_axis_xbar_s_to_m : axis_xbar_s_to_m
        generic map(
            N_SLAVES    => N_SLAVES,
            N_MASTERS   => N_MASTERS
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
            s           => s;
            m           => m;
            -- Error Status out
            err         => err
        );


    s(0).tdata  <= s0_tdata;
    s(0).tvalid <= s0_tvalid;
    s0_tready   <= s(0).tready;

    s(1).tdata  <= s1_tdata;
    s(1).tvalid <= s1_tvalid;
    s1_tready   <= s(1).tready;

    s(2).tdata  <= s2_tdata;
    s(2).tvalid <= s2_tvalid;
    s2_tready   <= s(2).tready;

    s(3).tdata  <= s3_tdata;
    s(3).tvalid <= s3_tvalid;
    s3_tready   <= s(3).tready;

    -- s(4).tdata
    -- s(4).tvalid
    -- tready

    m0_tdata    <= m(0).tdata;
    m0_valid    <= m(0).tvalid;
    m(0).tready <= m0_tready;

    m1_tdata    <= m(1).tdata;
    m1_tvalid   <= m(1).tvalid;
    m(1).tready <= m1_tready;

    m2_tdata    <= m(2).tdata;
    m2_tvalid   <= m(2).tvalid;
    m(2).tready <= m2_tready;

    m3_tdata    <= m(3).tdata;
    m3_tvalid   <= m(3).tvalid;
    m(3).tready <= m3_tready;

end architecture behavioral;
