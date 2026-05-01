library ieee;
use ieee.std_logic_1164.all;

package axi4_pkg is

    constant DATA_WIDTH : INTEGER := 32;
    constant ADDR_WIDTH : INTEGER := 10;
    
    type axi4_aw_t is record
        -- AXI4 Lite
        addr    : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
        prot    : STD_LOGIC_VECTOR(2 downto 0);
        valid   : STD_LOGIC;
        ready   : STD_LOGIC;
        -- AXI4 Full
        id      : STD_LOGIC_VECTOR(7 downto 0);
        -- BurstLength = AXILen + 1
        len     : STD_LOGIC_VECTOR(7 downto 0);
        -- Bytes in transfer = 2 ** AXISize
        size    : STD_LOGIC_VECTOR(2 downto 0);
        -- AXIBurst Binary Encoded
        burst   : STD_LOGIC_VECTOR(1 downto 0);
        lock    : STD_LOGIC;
        -- AXICache One-hot
        cache   : STD_LOGIC_VECTOR(3 downto 0);
        qos     : STD_LOGIC_VECTOR(3 downto 0);
        region  : STD_LOGIC_VECTOR(3 downto 0);
        user    : STD_LOGIC_VECTOR(3 downto 0);
    end record axi4_aw_t;

    type axi4_dw_t is record
        -- AXI4 Lite
        data    : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        strb    : STD_LOGIC_VECTOR((DATA_WIDTH/4)-1 downto 0);
        valid   : STD_LOGIC;
        ready   : STD_LOGIC;
        -- AXI4 Full
        last    : STD_LOGIC;
    end record axi4_dw_t;

    type axi4_bw_t is record
        -- AXI4 Lite
        resp   : STD_LOGIC_VECTOR(1 downto 0);
        ready  : STD_LOGIC;
        valid  : STD_LOGIC;
        -- AXI4 Full
        id     : STD_LOGIC_VECTOR(7 downto 0);
    end record axi4_bw_t;

    type axi4_ar_t is record
        -- AXI4 Lite
        addr   : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
        prot   : STD_LOGIC_VECTOR(2 downto 0);
        valid  : STD_LOGIC;
        ready  : STD_LOGIC;
        -- AXI4 Full
        id     : STD_LOGIC_VECTOR(7 downto 0);
        -- BurstLength = AXILen + 1
        len    : STD_LOGIC_VECTOR(7 downto 0);
        -- Bytes in transfer = 2 ** AXISize
        size   : STD_LOGIC_VECTOR(2 downto 0);
        -- AXIBurst Binary Encoded
        burst  : STD_LOGIC_VECTOR(1 downto 0);
        lock   : STD_LOGIC;
        -- AXICache One-hot
        cache  : STD_LOGIC_VECTOR(3 downto 0);
        qos    : STD_LOGIC_VECTOR(3 downto 0);
        region : STD_LOGIC_VECTOR(3 downto 0);
        user   : STD_LOGIC_VECTOR(3 downto 0); -- non standard AXI specification
    end record axi4_ar_t;

    type axi4_dr_t is record
        -- AXI4 Lite
        data    : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        valid   : STD_LOGIC;
        ready   : STD_LOGIC;
        -- AXI4 Full
        id      : STD_LOGIC_VECTOR(7 downto 0);
        last    : STD_LOGIC;
        resp    : STD_LOGIC_VECTOR(1 downto 0);
    end record axi4_dr_t;

    type axi4_t is record
        aw : axi4_aw_t; -- Address Write Channel
        dw : axi4_dw_t; -- Data Write Channel
        bw : axi4_bw_t; -- Write Respone Channel
        ar : axi4_ar_t; -- Address Read Channel
        dr : axi4_dr_t; -- Data Read Channel
    end record axi4_t;

end package axi4_pkg;

package body axi4_pkg is

end package body axi4_pkg;