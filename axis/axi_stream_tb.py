import struct
from random import randint
import logging

import numpy as np
import matplotlib.pyplot as plt

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import (Timer, RisingEdge, ClockCycles, with_timeout, Event)

import cocotbext
from cocotbext.axi import (AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor, AxiStreamFrame)

N = 10

np.random.seed(10)

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.dut.areset_n.value = 1
        self.source_a = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s0"), dut.aclk, dut.areset_n, reset_active_level=False)
        self.source_b = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s1"), dut.aclk, dut.areset_n, reset_active_level=False)
        self.source_c = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s2"), dut.aclk, dut.areset_n, reset_active_level=False)
        self.source_d = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s3"), dut.aclk, dut.areset_n, reset_active_level=False)
        self.sink_a   = AxiStreamSink  (AxiStreamBus.from_prefix(dut, "m0"), dut.aclk, dut.areset_n, reset_active_level=False)
        self.sink_b   = AxiStreamSink  (AxiStreamBus.from_prefix(dut, "m1"), dut.aclk, dut.areset_n, reset_active_level=False)

async def feed_stream(source, data_list):
    for val in data_list:
        # Random delay before sending the next frame
        await ClockCycles(source.clock, np.random.randint(3, 30))
        await source.send(AxiStreamFrame(val.tobytes()))

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
async def testbench(dut):
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    await reset_dut(dut)
    tb = TB(dut)
    # await tb.reset()
    await Timer(10, unit='ns')
    data_a = np.random.randint(0, np.iinfo(np.int32).max - 1, size=N, dtype=np.uint32)
    data_b = np.random.randint(0, np.iinfo(np.int32).max - 1, size=N, dtype=np.uint32)

    cocotb.log.info(f"Data A: {data_a}")
    cocotb.log.info(f"Data B: {data_b}")

    await Timer(40, unit='ns')

    cocotb.log.info(f"Configuration Err: {dut.err.value}")

    cocotb.start_soon(feed_stream(tb.source_a, data_a))
    cocotb.start_soon(feed_stream(tb.source_b, data_b))

    await Timer(200, unit='ns')

    for i in range(N):
        out_frame = await with_timeout(tb.sink_a.recv(), 2000, 'ns')
        expected = data_a[i] + data_b[i]
        actual = int.from_bytes(out_frame.tdata, 'little')
        cocotb.log.info(f"Received frame {i}: expected={expected}, actual={actual}")
        assert actual == expected

        out_frame = await with_timeout(tb.sink_b.recv(), 2000, 'ns')
        expected  = data_b[i]
        actual = int.from_bytes(out_frame.tdata, 'little')
        cocotb.log.info(f"Received frame {i}: expected={expected}, actual={actual}")
        assert actual == expected

    await Timer(2000, unit='ns')