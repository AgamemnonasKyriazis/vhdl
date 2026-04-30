from random import randint
import logging
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ClockCycles, ReadOnly, NextTimeStep

async def wait_10ns():
    cocotb.log.info("About to wait for 10 ns")
    await Timer(10, unit='ns')
    cocotb.log.info("Simulation time has advanced by 10 ns")

async def reset_dut(dut, cycles=2):
    # Drive known values before releasing reset
    dut.a.value = 0
    dut.b.value = 0

    # Assert reset
    dut.reset_n.value = 0

    # Hold reset for a few clock cycles
    await ClockCycles(dut.clk, cycles)

    # Deassert reset
    dut.reset_n.value = 1

    await RisingEdge(dut.clk)

    assert dut.reset_n.value, 1

@cocotb.test()
async def test_all_input_combinations(dut):
    
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)
    
    # Exhaustive 1-bit full-adder test: 2^3 = 8 cases
    N_TESTS = 100
    expected_sum = 0
    expected_carry = 0
    for _ in range(N_TESTS):

        await RisingEdge(dut.clk)

        a = randint(0, 255)
        b = randint(0, 255)
        dut.a.value = a
        dut.b.value = b

        # Wait a tiny amount of simulation time for signals to settle
        # await Timer(1, unit="ns")
        # await wait_10ns()
        await RisingEdge(dut.clk)
        await ReadOnly()

        got_sum = int(dut.r.value)
        got_carry = int(dut.c.value)

        expected_sum = (a+b) % 256
        expected_carry = 1 if a+b > 255 else 0

        assert got_sum == expected_sum, (
            f"SUM mismatch for a={a}, b={b}: "
            f"got {got_sum}, expected {expected_sum}"
        )

        assert got_carry == expected_carry, (
            f"CARRY mismatch for a={a}, b={b}: "
            f"got {got_carry}, expected {expected_carry}"
        )

        cocotb.log.info(f"{a}, {b} = {got_sum}, {got_carry}")