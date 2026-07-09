library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axis;
use axis.axis_pkg.all;

entity axis_elastic_buffer_flat is
    port (
        aclk      : in  std_logic;
        areset_n  : in  std_logic;

        -- Slave (input) side : upstream drives payload, DUT drives ready
        s_tdata   : in  std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
        s_tvalid  : in  std_logic;
        s_tready  : out std_logic;
        s_tlast   : in  std_logic;
        s_tkeep   : in  std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
        s_tid     : in  std_logic_vector(AXIS_ID_WIDTH-1 downto 0);
        s_tdest   : in  std_logic_vector(AXIS_DEST_WIDTH-1 downto 0);
        s_tuser   : in  std_logic_vector(AXIS_USER_WIDTH-1 downto 0);

        -- Master (output) side : DUT drives payload, downstream drives ready
        m_tdata   : out std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
        m_tvalid  : out std_logic;
        m_tready  : in  std_logic;
        m_tlast   : out std_logic;
        m_tkeep   : out std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
        m_tid     : out std_logic_vector(AXIS_ID_WIDTH-1 downto 0);
        m_tdest   : out std_logic_vector(AXIS_DEST_WIDTH-1 downto 0);
        m_tuser   : out std_logic_vector(AXIS_USER_WIDTH-1 downto 0);

        -- Backdoor : pure outputs (no handshake)
        bd_tdata  : out std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
        bd_tvalid : out std_logic;
        bd_tlast  : out std_logic;
        bd_tkeep  : out std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
        bd_tid    : out std_logic_vector(AXIS_ID_WIDTH-1 downto 0);
        bd_tdest  : out std_logic_vector(AXIS_DEST_WIDTH-1 downto 0);
        bd_tuser  : out std_logic_vector(AXIS_USER_WIDTH-1 downto 0)
    );
end entity axis_elastic_buffer_flat;

architecture wrap of axis_elastic_buffer_flat is

    signal s_rec  : axis_t := AXIS_S_INIT;
    signal m_rec  : axis_t := AXIS_M_INIT;
    signal bd_rec : axis_t := AXIS_M_INIT;

    component axis_elastic_buffer
        port (
            aclk     : in std_logic;
            areset_n : in std_logic;
            s        : inout axis_t := AXIS_S_INIT;
            m        : inout axis_t := AXIS_M_INIT;
            bd       : inout axis_t
        );
    end component axis_elastic_buffer;

begin

    ----------------------------------------------------------------------
    -- Flat -> record (drive the fields the slave side consumes)
    -- s_tready is driven BY the DUT, so we don't drive it here.
    ----------------------------------------------------------------------
    s_rec.tdata  <= s_tdata;
    s_rec.tvalid <= s_tvalid;
    s_rec.tlast  <= s_tlast;
    s_rec.tkeep  <= s_tkeep;
    s_rec.tid    <= s_tid;
    s_rec.tdest  <= s_tdest;
    s_rec.tuser  <= s_tuser;

    -- m_tready is driven externally; push it into the master record.
    -- m payload fields are driven BY the DUT, so we don't drive them here.
    m_rec.tready <= m_tready;

    ----------------------------------------------------------------------
    -- Record -> flat (read the fields the DUT produces)
    ----------------------------------------------------------------------
    s_tready  <= s_rec.tready;

    m_tdata   <= m_rec.tdata;
    m_tvalid  <= m_rec.tvalid;
    m_tlast   <= m_rec.tlast;
    m_tkeep   <= m_rec.tkeep;
    m_tid     <= m_rec.tid;
    m_tdest   <= m_rec.tdest;
    m_tuser   <= m_rec.tuser;

    bd_tdata  <= bd_rec.tdata;
    bd_tvalid <= bd_rec.tvalid;
    bd_tlast  <= bd_rec.tlast;
    bd_tkeep  <= bd_rec.tkeep;
    bd_tid    <= bd_rec.tid;
    bd_tdest  <= bd_rec.tdest;
    bd_tuser  <= bd_rec.tuser;

    ----------------------------------------------------------------------
    -- DUT instance
    ----------------------------------------------------------------------
    dut : axis_elastic_buffer
        port map (
            aclk     => aclk,
            areset_n => areset_n,
            s        => s_rec,
            m        => m_rec,
            bd       => bd_rec
        );

end architecture wrap;