`default_nettype none
module tt_um_sky1 (
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
    reg [7:0] instruction_mem [0:18];
    reg [7:0] B,C;
    reg [1:0] state;
    reg [7:0] opcode;
    reg [7:0] operand;
    reg Zero;

    parameter FETCH = 2'b00, DECODE = 2'b01, EXECUTE = 2'b10, HALT = 2'b11;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 0;
            AC <= 0;
            state <= FETCH;
            opcode <= 0;
            operand <= 0;
            B <= 0;
            C <= 0; 
            Zero <= 0;
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
                        if((opcode == 8'h07)||(opcode == 8'h08)||(opcode == 8'h09)||(opcode == 8'h0A)||(opcode == 8'h0E)
                        ||(opcode == 8'h0F)||(opcode == 8'h10)||(opcode == 8'h11)||(opcode == 8'h12)||(opcode == 8'h13)
                           ||(opcode == 8'h16)||(opcode == 8'h17)||(opcode == 8'h18)||(opcode == 8'h19)||(opcode == 8'h20) )begin
                            state <= EXECUTE;
                        end
                        else begin  // Immediate
                        operand <= instruction_mem[PC];  // operand get
                        PC <= PC + 1;
                        state <= EXECUTE;
                        end
                    end

                    EXECUTE: begin
                        case (opcode)
                            8'h01: AC <= operand;         // MVI A
                            8'h02: AC <= AC + operand;    // ADDI
                            8'h03: AC <= AC - operand;    // SUBI
                            8'h04: AC <= AC & operand;    // ANDI
                            8'h05: AC <= AC | operand;    // ORI
                            8'h06: AC <= AC ^ operand;    // XORI
                            8'h07: AC <= ~AC;             // NOT
                            8'h08: AC <= AC << 1;         // SHL
                            8'h09: AC <= AC >> 1;         // SHR
                            8'h0A: state <= HALT;         // HALT
                            
                            8'h0B: B <= operand;         // MVI B
                            8'h0C: C <= operand;         // MVI C 
                            8'h0D: PC <= PC + operand[4:0];    //JMP addr
                            8'h0E: AC <= AC + 1;  // INR A
                            8'h0F: AC <= AC - 1;  // DCR A
                            8'h10: B <= B + 1;   // INR  B
                            8'h11: B <= B - 1;   // DCR B
                            8'h12: C <= C + 1;   // INR C
                            8'h13: C <= C - 1;   // DCR C
                            8'h14: if(Zero == 1'b0) begin PC <= PC + operand[4:0]; end // JNZ addr
                            8'h15: if(Zero == 1'b1) begin PC <= PC + operand[4:0]; end // JZ addr
                            8'h16: if(AC == 8'h00) begin Zero <= 1; end else begin Zero <= 0; end   // AC Check 0
                            8'h17: AC <= AC + B; //ADD B
                            8'h18: AC <= AC + C; //ADD C
                            8'h19: B <= B + C;  // BBC
                            8'h20: AC <= AC -1:  // SUB C
            
                            

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
