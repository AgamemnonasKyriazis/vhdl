library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library general;
use general.general.all;

library axi;
use axi.axis.all;

entity regfile is
    generic (
        N_W_PORTS : natural range 1 to natural'high := 1;
        N_R_PORTS : natural range 1 to natural'high := 1
    );
    port (
        clk     : in std_logic;
        rst_n   : in std_logic;
        
        -- Write Interface Array
        w_ports : in  regfile_write_in_array_t (0 to N_W_PORTS-1);
        
        -- Read Interface Array
        r_reqs  : in  regfile_read_in_array_t (0 to N_R_PORTS-1);
        r_resps : out regfile_read_out_array_t (0 to N_R_PORTS-1)
    );
end regfile;

architecture behavioral of regfile is

    type reg_array_t is array (0 to N_REGS - 1) of axis_payload_t;
    signal registers : reg_array_t;

begin

    -- =========================================================================
    -- Write Process (Synchronous)
    -- =========================================================================
    p_write : process(clk, rst_n)
        variable v_addr : integer;
    begin
        if rst_n = '0' then
            -- Reset all registers to zero
            registers <= (others => AXIS_PAYLOAD_ZERO_INIT);
            
        elsif rising_edge(clk) then
            -- Iterate through every write port
            for i in 0 to N_W_PORTS - 1 loop
                if w_ports(i).we = '1' then
                    
                    v_addr := to_integer(unsigned(w_ports(i).sel));
                    
                    -- Implement Write Strobe (Assuming 1 strobe bit per 8 bits of data)
                    for b in 0 to DATA_STRB - 1 loop
                        if w_ports(i).strb(b) = '1' then
                            registers(v_addr).tdata( ((b + 1) * 8) - 1 downto (b * 8) ) 
                                <= w_ports(i).data.tdata( ((b + 1) * 8) - 1 downto (b * 8) );
                        end if;
                    end loop;
                    registers(v_addr).tlast <= w_ports(i).data.tlast;
                    registers(v_addr).tkeep <= w_ports(i).data.tkeep;
                    registers(v_addr).tid   <= w_ports(i).data.tid;
                    registers(v_addr).tdest <= w_ports(i).data.tdest;
                    registers(v_addr).tuser <= w_ports(i).data.tuser;
                    
                end if;
            end loop;
        end if;
    end process p_write;

    -- =========================================================================
    -- Read Process (Combinational)
    -- =========================================================================
    -- Using VHDL-2008 'process(all)' to automatically infer sensitivity list
    p_read : process(all)
        variable v_addr : integer;
    begin
        -- Iterate through every read port
        for i in 0 to N_R_PORTS - 1 loop
            v_addr := to_integer(unsigned(r_reqs(i).sel));
            r_resps(i).data <= registers(v_addr);
        end loop;
    end process p_read; 

end architecture;
