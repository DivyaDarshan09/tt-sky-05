`default_nettype none
module tt_um_sky1(
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire   ena,
    input  wire   clk,
    input  wire   rst_n  
    
);
//we , instr
    wire [4:0] instr_addr = ui_in[4:0];    
    wire [7:0] instr_in = uio_in[7:0];        // Instruction input (8-bit opcode + 8-bit operand) in 2 PCs or 2 cycles like 8085
    reg [7:0] AC;
    reg [4:0] PC;
    wire we = ui_in[7];
    assign uio_oe = 8'h00;
    assign uio_out = 8'h00;
    assign uo_out = AC;
    reg [7:0] instruction_mem [0:31];
    reg [1:0] state;
    reg [7:0] opcode;
    reg [7:0] operand;

    parameter FETCH = 2'b00, DECODE = 2'b01, EXECUTE = 2'b10, HALT = 2'b11;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 0;
            AC <= 0;
            state <= FETCH;
            opcode <= 0;
            operand <= 0;
        end else begin
            if (we) begin
                instruction_mem[instr_addr] <= instr_in;
            end else begin
                case (state)
                    FETCH: begin
                        opcode <= instruction_mem[PC]; // opcode get
                        PC <= PC + 1;
                        state <= DECODE;
                    end

                    DECODE: begin
                        operand <= instruction_mem[PC];  // operand get
                        PC <= PC + 1;
                        state <= EXECUTE;
                    end

                    EXECUTE: begin
                        case (opcode)
                            8'h01: AC <= operand;         // LOAD
                            8'h02: AC <= AC + operand;    // ADD
                            8'h03: AC <= AC - operand;    // SUB
                            8'h04: AC <= AC & operand;    // AND
                            8'h05: AC <= AC | operand;    // OR
                            8'h06: AC <= AC ^ operand;    // XOR
                            8'h07: AC <= ~AC;             // NOT
                            8'h08: AC <= AC << 1;         // SHL
                            8'h09: AC <= AC >> 1;         // SHR
                            8'h0A: state <= HALT;         // HALT
                            default: state <= HALT;
                        endcase
                        if (opcode != 8'h0A)
                            state <= FETCH;
                    end

                    HALT: begin
                        state <= HALT;
                    end
                endcase
            end
        end
    end
    wire _unused = &{ena,ui_in[6:5]};
endmodule
