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

    axi_master = AxiMaster(AxiBus.from_prefix(dut, "s_axi"), dut.aclk, dut.areset_n, reset_active_level=False)

    addr =  [_ << 2 for _ in range(N)]
    wdata = [struct.pack("I", np.random.randint(0, np.iinfo(np.uint32).max, dtype=np.uint32)) for _ in range(N)]

    for i in range(N):
        cocotb.log.info(f"WRITE start addr=0x{addr[i]:08x}")
        await with_timeout(axi_master.write(addr[i], wdata[i]), 200, "ns")
        cocotb.log.info(f"WRITE done  addr=0x{addr[i]:08x}")

    for i in range(N):
        cocotb.log.info(f"READ  start addr=0x{addr[i]:08x}")
        resp = await with_timeout(axi_master.read(addr[i], 4), 200, "ns")
        cocotb.log.info(f"READ  done  addr=0x{addr[i]:08x} data={resp.data!r} resp={resp.resp}")
        assert wdata[i] == resp.data

    await Timer(3, unit='ms')
