import struct
from random import randint
import logging

import numpy as np
import matplotlib.pyplot as plt

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import (Timer, RisingEdge, ClockCycles, with_timeout, Event)
from cocotb.types import LogicArray

import cocotbext
from cocotbext.axi import (AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor, AxiStreamFrame)
from cocotbext.axi import (AxiBus, AxiMaster, AxiRam, AxiLiteBus, AxiLiteMaster)

N = 8

np.random.seed(10)

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.tcdm = AxiRam(AxiBus.from_prefix(dut, "m0_axi"), dut.aclk, dut.areset_n, reset_active_level=False, size=1024)

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
async def cgra_test(dut):
    tb = TB(dut)

    tb.dut.areset_n.value = 1

    cocotb.start_soon(Clock(tb.dut.aclk, 10, unit="ns").start())

    await reset_dut(tb.dut)

    st_base_addr = 0x20    
    st_x_size    = N
    st_x_stride  = 4
    st_y_size    = 1
    st_y_stride  = 0
    st_z_size    = 1
    st_z_stride  = 0

    ld_base_addr = 0x00
    ld_x_size    = N
    ld_x_stride  = 4
    ld_y_size    = 1
    ld_y_stride  = 0
    ld_z_size    = 1
    ld_z_stride  = 0

    tb.dut.u0_ls.reg_st_base_addr_l.value = st_base_addr & 0xFFFFFFFF
    tb.dut.u0_ls.reg_st_base_addr_u.value = (st_base_addr >> 32) & 0xFFFFFFFF
    tb.dut.u0_ls.reg_st_x_size.value = st_x_size
    tb.dut.u0_ls.reg_st_x_stride.value = st_x_stride
    tb.dut.u0_ls.reg_st_y_size.value = st_y_size
    tb.dut.u0_ls.reg_st_y_stride.value = st_y_stride
    tb.dut.u0_ls.reg_st_z_size.value = st_z_size
    tb.dut.u0_ls.reg_st_z_stride.value = st_z_stride

    tb.dut.u0_ls.reg_ld_base_addr_l.value = ld_base_addr & 0xFFFFFFFF
    tb.dut.u0_ls.reg_ld_base_addr_u.value = (ld_base_addr >> 32) & 0xFFFFFFFF
    tb.dut.u0_ls.reg_ld_x_size.value = ld_x_size
    tb.dut.u0_ls.reg_ld_x_stride.value = ld_x_stride
    tb.dut.u0_ls.reg_ld_y_size.value = ld_y_size
    tb.dut.u0_ls.reg_ld_y_stride.value = ld_y_stride
    tb.dut.u0_ls.reg_ld_z_size.value = ld_z_size
    tb.dut.u0_ls.reg_ld_z_stride.value = ld_z_stride

    for idx in range(0, N, 1):
        d = idx+1
        d = d | (d << 4) | (d << 8) | (d << 12) | (d << 16) | (d << 20) | (d << 24) | (d << 28)
        tb.tcdm.write(idx<<2, struct.pack('<I', d))

    await Timer(1, unit='ms')

    tb.dut.enable.value = 1
    await Timer(120, unit='ns')
    tb.dut.enable.value = 0
    await Timer(200, unit='ns')
    tb.dut.enable.value = 1
    await Timer(1, unit='ms')

    # cocotb.log.info(f"reg_st_x_count_ss: {int(dut.reg_st_x_count_ss.value)}")
    # cocotb.log.info(f"reg_st_y_count_ss: {int(dut.reg_st_y_count_ss.value)}")
    # cocotb.log.info(f"reg_st_z_count_ss: {int(dut.reg_st_z_count_ss.value)}")
    # cocotb.log.info(f"reg_ld_x_count_ss: {int(dut.reg_ld_x_count_ss.value)}")
    # cocotb.log.info(f"reg_ld_y_count_ss: {int(dut.reg_ld_y_count_ss.value)}")
    # cocotb.log.info(f"reg_ld_z_count_ss: {int(dut.reg_ld_z_count_ss.value)}")

    # cocotb.log.info(f"Current State: {dut.axi_m_wstate.value}")
    # cocotb.log.info(f"Current internal X count: {int(dut.st_x_count_q.value)}")
    # cocotb.log.info(f"Last generated AXI address: {hex(int(dut.m_axi_awaddr.value))}")

    cocotb.log.info(f"RAM content hex dump:")
    tb.tcdm.hexdump(0x00, 128)

    expected = bytearray()
    for idx in range(0, N, 1):
        src = idx + 1
        src = src | (src << 4) | (src << 8) | (src << 12) | (src << 16) | (src << 20) | (src << 24) | (src << 28)
        d = (src + src) & 0xFFFFFFFF
        expected.extend(struct.pack('<I', d))

    ram_contents = bytes(tb.tcdm.read(st_base_addr, N * 4))
    assert ram_contents == bytes(expected)
