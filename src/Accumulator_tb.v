`include "Accumulator_CPU.v"
module Accumulator_tb;
    reg clk, reset, we;
    reg [3:0] instr_addr; 
    reg [11:0] instr_in; 
    wire [7:0] AC;
    wire [3:0] PC;

    // Instantiate the CPU
    Accumulator_CPU uut (
        .clk(clk),
        .reset(reset),
        .we(we),
        .instr_addr(instr_addr),
        .instr_in(instr_in),
        .AC(AC),
        .PC(PC)
    );

    // Clock Generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Dump file for waveform debugging
        $dumpfile("cpu_test.vcd");
        $dumpvars(0, tb);

        // Initialize signals
        clk = 0;
        reset = 1;
        we = 1;
        instr_addr = 0;
        instr_in = 0;

        #10 reset = 0; // Release reset

        // Load Instructions into Memory
        #10 we = 1; instr_addr = 4'd0; instr_in = 12'b000100000011; // LOAD 3
        #10 we = 1; instr_addr = 4'd1; instr_in = 12'b001000000101; // ADD 5
        #10 we = 1; instr_addr = 4'd2; instr_in = 12'b001100000010; // SUB 2
        #10 we = 1; instr_addr = 4'd3; instr_in = 12'b101000000000; // HALT
        #10 we = 0; // Stop writing instructions

        // Run Simulation
        #200;
        $finish; // End Simulation
    end

    // --------------------------
    // Print Log only once per instruction
    // --------------------------
    reg [3:0] prevPC;
    initial prevPC = 4'hF; // init to invalid PC

    always @(posedge clk) begin
        if (PC !== prevPC) begin
            $display("Time=%0t | PC=%0d | AC=%0d", $time, PC, AC);
            prevPC <= PC;
        end
    end

endmodule
