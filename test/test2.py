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
    # Division 10/2  = 5
    program = [
        (0, 0x01),  # MVI A
        (1, 0x0A),  # 0A
        (2, 0x0C),  # MVI C
        (3, 0x02),  # 02
        (4, 0x20),  # SUB C
        (5, 0x10),  # INR B
        (6, 0x16),  # AC CHECK 0
        (7, 0x14),  # JNZ ADDR
        (8, 0x1B),  # PC = PC - 5
        (9, 0x17),  # ADD B
        (10, 0x0A),  # HALT
    ]

    for addr, data in program:
        await write_instr(dut, addr, data)

    # Deassert write enable (ui_in[7] = 0)
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 2)

    dut._log.info("Running CPU")

    # Run CPU for 50 cycles
    await ClockCycles(dut.clk, 150)

    # Example check: accumulator AC should be (10 / 2) = 5 at end
    result = int(dut.uo_out.value)
    dut._log.info(f"Final Accumulator = {result}")
    assert result == 5, f"Expected AC=5, but got {result}"
