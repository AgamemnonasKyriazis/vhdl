TOPLEVEL_LANG = vhdl
SIM = ghdl
EXTRA_ARGS = --std=08
SIM_ARGS = --wave=wave.ghw

PKG = $(PWD)/../pkg

VHDL_SOURCES_general = $(PKG)/general/general.vhd

VHDL_SOURCES_axi  = $(PKG)/axi/axis.vhd
VHDL_SOURCES_axi += $(PKG)/axi/axi4.vhd

VHDL_SOURCES += $(PWD)/axis_elastic_buffer.vhd
VHDL_SOURCES += $(PWD)/regfile.vhd
VHDL_SOURCES += $(PWD)/ic.vhd
VHDL_SOURCES += $(PWD)/fn.vhd
VHDL_SOURCES += $(PWD)/ls.vhd
VHDL_SOURCES += $(PWD)/top.vhd

COCOTB_TOPLEVEL = top
COCOTB_TEST_MODULES = cgra_tb

include $(shell cocotb-config --makefiles)/Makefile.sim
