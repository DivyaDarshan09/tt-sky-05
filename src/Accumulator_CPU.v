module Accumulator_CPU(
    input clk, reset,
    input we,   
    input [3:0] instr_addr,    
    input [11:0] instr_in,          // Instruction input (4-bit opcode + 8-bit operand)
    output reg [7:0] AC,
    output reg [3:0] PC 
);

    reg [11:0] instruction_mem [0:9];
    reg [1:0] state;
    reg [3:0] opcode;
    reg [7:0] operand;

    parameter FETCH = 2'b00, DECODE = 2'b01, EXECUTE = 2'b10, HALT = 2'b11;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 0;
            AC <= 0;
            state <= FETCH;
        end else begin
            if (we) begin
                instruction_mem[instr_addr] <= instr_in;
            end else begin
                case (state)
                    FETCH: begin
                        {opcode, operand} <= instruction_mem[PC];
                        PC <= PC + 1;
                        state <= DECODE;
                    end

                    DECODE: begin
                        state <= EXECUTE;
                    end

                    EXECUTE: begin
                        case (opcode)
                            4'b0001: AC <= operand;         // LOAD
                            4'b0010: AC <= AC + operand;    // ADD
                            4'b0011: AC <= AC - operand;    // SUB
                            4'b0100: AC <= AC & operand;    // AND
                            4'b0101: AC <= AC | operand;    // OR
                            4'b0110: AC <= AC ^ operand;    // XOR
                            4'b0111: AC <= ~AC;             // NOT
                            4'b1000: AC <= AC << 1;         // SHL
                            4'b1001: AC <= AC >> 1;         // SHR
                            4'b1010: state <= HALT;         // HALT
                            default: ;
                        endcase
                        if (opcode != 4'b1010)
                            state <= FETCH;
                    end

                    HALT: begin
                        state <= HALT;
                    end
                endcase
            end
        end
    end
endmodule
