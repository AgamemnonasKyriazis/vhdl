TOPLEVEL_LANG = vhdl
SIM = ghdl
EXTRA_ARGS = --std=08
SIM_ARGS = --wave=wave.ghw

VHDL_SOURCES_axis = $(PWD)/axis/axis_pkg.vhd
VHDL_SOURCES = 	axis_xbar_s_to_m.vhd \
				$(PWD)/fn.vhd

COCOTB_TOPLEVEL = fn
COCOTB_TEST_MODULES = axi_stream_tb

include $(shell cocotb-config --makefiles)/Makefile.sim