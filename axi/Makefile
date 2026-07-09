TOPLEVEL_LANG = vhdl
SIM = ghdl
SIM_ARGS = --wave=wave.ghw
EXTRA_ARGS = --std=08
VHDL_SOURCES_axi = $(PWD)/axi4/axi4_pkg.vhd

.PHONY: ram dma

ram:
	$(MAKE) sim \
	VHDL_SOURCES="$(COMMON_SOURCES) $(PWD)/axi_ram.vhd" \
	TOPLEVEL=axi_ram \
	MODULE=axi_ram_tb

dma:
	$(MAKE) sim \
	VHDL_SOURCES="$(COMMON_SOURCES) $(PWD)/axi_dma.vhd" \
	TOPLEVEL=axi_dma \
	MODULE=axi_dma_tb

include $(shell cocotb-config --makefiles)/Makefile.sim