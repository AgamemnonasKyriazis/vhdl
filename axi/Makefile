TOPLEVEL_LANG = vhdl
SIM = ghdl
SIM_ARGS = --wave=wave.ghw

VHDL_SOURCES_axi = $(PWD)/axi/axi4_pkg.vhd
VHDL_SOURCES = $(PWD)/axi_ram.vhd

COCOTB_TOPLEVEL = axi_ram
COCOTB_TEST_MODULES = axi_ram_tb

include $(shell cocotb-config --makefiles)/Makefile.sim