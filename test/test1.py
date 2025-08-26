# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def write_instr(dut, addr, data):
    """Task to write instruction into memory"""
    dut.ui_in.value = (1 << 7) | (addr & 0xF)  # ui_in[7]=1 (WE), lower 4 bits = addr
    dut.uio_in.value = data
    await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start Cocotb Testbench")

    # Setup clock (10ns period = 100 MHz)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = (1<<7)
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    dut._log.info("Loading Program into Instruction Memory")

    # --- Program load ---
    # Multiplication of 5x5 = 25
    program = [
        (0, 0x01),  # MVI A
        (1, 0x05),  # 05
        (2, 0x0C),  # MVI C
        (3, 0x05),  # 05
        (4, 0x0B),  # MVI B
        (5, 0x00),  # 00
        (6, 0x1A),  # BBC (B = B + C)
        (7, 0x0F),  # DCR A
        (8, 0x14),  # JNZ ADDR
        (9, 0x1C),  # PC = 10 - 4 = 6 (BBC) 
        (10, 0x18),  # ADD B
        (11, 0x0A),  # HALT
    ]

    for addr, data in program:
        await write_instr(dut, addr, data)

    # Deassert write enable (ui_in[7] = 0)
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 2)

    dut._log.info("Running CPU")

    # Run CPU for 50 cycles
    await ClockCycles(dut.clk, 150)

    # Example check: accumulator AC should be (5 * 5) = 25 at end
    result = int(dut.uo_out.value)
    dut._log.info(f"Final Accumulator = {result}")
    assert result == 25, f"Expected AC=25, but got {result}"
