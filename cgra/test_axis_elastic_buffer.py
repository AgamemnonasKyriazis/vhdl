# # test_axis_elastic_buffer.py
# import cocotb
# from cocotb.clock import Clock
# from cocotb.triggers import RisingEdge, ClockCycles
# from cocotb.regression import TestFactory

# from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamFrame

import struct
import random
from random import randint
import logging

import numpy as np
import matplotlib.pyplot as plt

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import (Timer, RisingEdge, ClockCycles, with_timeout, Event)

import cocotbext
from cocotbext.axi import (AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor, AxiStreamFrame)

# # ----------------------------------------------------------------------------
# # Bus binding
# #
# # cocotbext-axi resolves signal names via AxiStreamBus.from_prefix(dut, "s"),
# # which looks for s_tvalid, s_tready, s_tdata, etc.
# #
# # Your DUT uses VHDL records (s.tvalid). GHDL flattens record fields with a
# # '.' separator in the VPI hierarchy, NOT an underscore, so from_prefix won't
# # find them automatically. Two options:
# #   (A) add a flat wrapper entity (recommended, see note at bottom), then bind
# #       to the wrapper's flat ports below.
# #   (B) build the AxiStreamBus manually from explicit signal handles.
# #
# # This script assumes a flat wrapper exposing s_*, m_*, bd_* signals.
# # If you bind directly to records, swap to the manual-handle version noted
# # at the bottom.
# # ----------------------------------------------------------------------------

# CLK_PERIOD_NS = 10


# async def reset_dut(dut):
#     dut.areset_n.value = 0
#     await ClockCycles(dut.aclk, 5)
#     dut.areset_n.value = 1
#     await RisingEdge(dut.aclk)


# async def run_test(dut, payload_lengths, backpressure=False, idle_inserter=False):
#     cocotb.start_soon(Clock(dut.aclk, CLK_PERIOD_NS, units="ns").start())

#     source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s"), dut.aclk, dut.areset_n, reset_active_level=False)
#     sink   = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m"), dut.aclk, dut.areset_n, reset_active_level=False)

#     # Backpressure: randomly deassert m_tready to exercise FULL/skid path
#     if backpressure:
#         sink.set_pause_generator(_rand_pause())
#     if idle_inserter:
#         source.set_pause_generator(_rand_pause())

#     await reset_dut(dut)

#     sent = []
#     for length in payload_lengths:
#         data = bytes(random.randint(0, 255) for _ in range(length))
#         frame = AxiStreamFrame(tdata=data)
#         await source.send(frame)
#         sent.append(data)

#     # Drain
#     received = []
#     for _ in sent:
#         rx = await sink.recv()
#         received.append(bytes(rx.tdata))

#     await ClockCycles(dut.aclk, 10)

#     # Check ordering + integrity
#     assert received == sent, (
#         f"Data mismatch.\n  sent={sent}\n  recv={received}"
#     )

#     dut._log.info(f"PASS: {len(sent)} frames matched "
#                   f"(backpressure={backpressure}, idle={idle_inserter})")


def _rand_pause():
    while True:
        yield random.random() < 0.9


# # --- Individual named tests -------------------------------------------------

# @cocotb.test()
# async def test_single_beats_clean(dut):
#     """No backpressure, single-byte frames, full throughput."""
#     await run_test(dut, payload_lengths=[1] * 16, backpressure=False)


# @cocotb.test()
# async def test_backpressure(dut):
#     """Random m_tready deassertion forces the skid/FULL path."""
#     await run_test(dut, payload_lengths=[1] * 32, backpressure=True)


# @cocotb.test()
# async def test_idle_source(dut):
#     """Random gaps in s_tvalid; checks EMPTY<->BUSY behaviour."""
#     await run_test(dut, payload_lengths=[1] * 32, idle_inserter=True)


# @cocotb.test()
# async def test_stress(dut):
#     """Both sides bursty — the case that exposes data loss / dup bugs."""
#     await run_test(dut, payload_lengths=[1] * 200,
#                    backpressure=True, idle_inserter=True)


N = 10

np.random.seed(10)

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.dut.areset_n.value = 1
        self.source_a = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s"), dut.aclk, dut.areset_n, reset_active_level=False)
        self.sink_a   = AxiStreamSink  (AxiStreamBus.from_prefix(dut, "m"), dut.aclk, dut.areset_n, reset_active_level=False)

async def feed_stream(source, data_list):
    for i, val in enumerate(data_list):
        # Random delay before sending the next frame
        await ClockCycles(source.clock, np.random.randint(3, 30))
        await source.send(AxiStreamFrame(tdata=val, tid=i, tkeep=[1 for _ in range(32//8)], tdest=0x0, tuser=0x0))

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
    # data_a = np.random.randint(0, np.iinfo(np.int32).max - 1, size=N, dtype=np.uint32)
    data_a = [
        struct.pack("<I", (i & 0xF) * 0x11111111)
        for i in range(N)
    ]
    print(data_a)

    cocotb.log.info(f"Data A: {data_a}")

    await Timer(40, unit='ns')

    dut._log.info(f"m_tdata width = {len(dut.m_tdata)}")
    dut._log.info(f"m_tkeep width = {len(dut.m_tkeep)}")

    tb.sink_a.set_pause_generator(_rand_pause())
    cocotb.start_soon(feed_stream(tb.source_a, data_a))

    await Timer(200, unit='ns')

    for i in range(N):
        out_frame = await with_timeout(tb.sink_a.recv(), 20000, 'ns')
        expected = data_a[i]
        actual = bytes(out_frame.tdata)
        assert actual == expected, f"beat {i}: got {actual.hex()}, want {expected.hex()}"

    await Timer(2000, unit='ns')