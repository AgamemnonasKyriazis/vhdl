import numpy as np
import matplotlib.pyplot as plt
import struct
from random import randint
import logging
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ClockCycles, ReadOnly, NextTimeStep, with_timeout
from cocotbext.axi import AxiBus, AxiMaster, AxiRam, AxiLiteBus, AxiLiteMaster

N = 3

async def wait_10ns():
    cocotb.log.info("About to wait for 10 ns")
    await Timer(10, unit='ns')
    cocotb.log.info("Simulation time has advanced by 10 ns")

async def reset_dut(dut, cycles=2):
    # Assert reset
    dut.areset_n.value = 0
    # Hold reset for a few clock cycles
    await ClockCycles(dut.aclk, cycles)
    # Deassert reset
    dut.areset_n.value = 1
    await RisingEdge(dut.aclk)
    assert dut.areset_n.value, 1
    await RisingEdge(dut.aclk)

@cocotb.test()
async def test_all_input_combinations(dut):
    dut.areset_n.value = 1

    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())

    await reset_dut(dut)

    axi_ram = AxiRam(AxiBus.from_prefix(dut, "m_axi"), dut.aclk, dut.areset_n, reset_active_level=False, size=1024)

    st_base_addr = 0x10    
    st_x_size    = 4
    st_x_stride  = 4
    st_y_size    = 4
    st_y_stride  = st_x_size * 4
    st_z_size    = 1
    st_z_stride  = 0

    ld_base_addr = 0x00
    ld_x_size    = 8
    ld_x_stride  = 4
    ld_y_size    = 1
    ld_y_stride  = 0
    ld_z_size    = 1
    ld_z_stride  = 0

    dut.reg_st_base_addr_l.value = st_base_addr & 0xFFFFFFFF
    dut.reg_st_base_addr_u.value = (st_base_addr >> 32) & 0xFFFFFFFF
    dut.reg_st_x_size.value = st_x_size
    dut.reg_st_x_stride.value = st_x_stride
    dut.reg_st_y_size.value = st_y_size
    dut.reg_st_y_stride.value = st_y_stride
    dut.reg_st_z_size.value = st_z_size
    dut.reg_st_z_stride.value = st_z_stride

    dut.reg_ld_base_addr_l.value = ld_base_addr & 0xFFFFFFFF
    dut.reg_ld_base_addr_u.value = (ld_base_addr >> 32) & 0xFFFFFFFF
    dut.reg_ld_x_size.value = ld_x_size
    dut.reg_ld_x_stride.value = ld_x_stride
    dut.reg_ld_y_size.value = ld_y_size
    dut.reg_ld_y_stride.value = ld_y_stride
    dut.reg_ld_z_size.value = ld_z_size
    dut.reg_ld_z_stride.value = ld_z_stride

    axi_ram.write(0x0000, struct.pack('<I', 0xDEADBEEF))
    axi_ram.write(0x0004, struct.pack('<I', 0xDEADBEEF))
    axi_ram.write(0x0008, struct.pack('<I', 0xDEADBEEF))
    axi_ram.write(0x000C, struct.pack('<I', 0xDEADBEEF))

    dut.reg_command.value = 1

    await Timer(3, unit='ms')

    dut.reg_command.value = 2

    await Timer(3, unit='ms')

    dut.reg_command.value = 3

    await Timer(50, unit='ns')

    cocotb.log.info(f"reg_st_x_count_ss: {int(dut.reg_st_x_count_ss.value)}")
    cocotb.log.info(f"reg_st_y_count_ss: {int(dut.reg_st_y_count_ss.value)}")
    cocotb.log.info(f"reg_st_z_count_ss: {int(dut.reg_st_z_count_ss.value)}")
    cocotb.log.info(f"reg_ld_x_count_ss: {int(dut.reg_ld_x_count_ss.value)}")
    cocotb.log.info(f"reg_ld_y_count_ss: {int(dut.reg_ld_y_count_ss.value)}")
    cocotb.log.info(f"reg_ld_z_count_ss: {int(dut.reg_ld_z_count_ss.value)}")

    cocotb.log.info(f"Current State: {dut.axi_m_wstate.value}")
    cocotb.log.info(f"Current internal X count: {int(dut.st_x_count_q.value)}")
    cocotb.log.info(f"Last generated AXI address: {hex(int(dut.m_axi_awaddr.value))}")

    total_bytes_expected = st_x_size * st_x_stride
    ram_contents = axi_ram.read(st_base_addr, total_bytes_expected)
    
    cocotb.log.info(f"RAM content hex dump at 0x{st_base_addr:02x}:")
    axi_ram.hexdump(st_base_addr, total_bytes_expected)

    assert len(ram_contents) == total_bytes_expected