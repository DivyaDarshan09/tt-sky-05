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
    reg [7:0] instruction_mem [0:21];
    reg [7:0] B,C;
    reg [1:0] state;
    reg [7:0] opcode;
    reg [7:0] operand;
    reg Zero,Carry,Overflow;

    parameter FETCH = 2'b00, DECODE = 2'b01, EXECUTE = 2'b10, HALT = 2'b11;
    // Instruction Opcodes
    localparam 
        MVI_A   = 8'h01,  // Move Immediate to A
        ADDI    = 8'h02,  // Add Immediate
        SUBI    = 8'h03,  // Sub Immediate
        ANDI    = 8'h04,  // AND Immediate
        ORI     = 8'h05,  // OR Immediate
        XORI    = 8'h06,  // XOR Immediate
        NOTA    = 8'h07,  // NOT A
        SHL     = 8'h08,  // Shift Left A
        SHR     = 8'h09,  // Shift Right A
        HLT    = 8'h0A,  // HALT

        MVI_B   = 8'h0B,  // Move Immediate to B
        MVI_C   = 8'h0C,  // Move Immediate to C
        JMP     = 8'h0D,  // Jump by offset
        INR_A   = 8'h0E,  // Increment A
        DCR_A   = 8'h0F,  // Decrement A
        INR_B   = 8'h10,  // Increment B
        DCR_B   = 8'h11,  // Decrement B
        INR_C   = 8'h12,  // Increment C
        DCR_C   = 8'h13,  // Decrement C

        JNZ     = 8'h14,  // Jump if Zero==0
        JZ      = 8'h15,  // Jump if Zero==1
        JNC     = 8'h16,  // Jump if Carry==0
        JC      = 8'h17,  // Jump if Carry==1
        ADD_B   = 8'h18,  // A = A + B
        ADD_C   = 8'h19,  // A = A + C
        BBC  = 8'h1A,  // B = B + C
        SUB_B   = 8'h1B,  // A = A - B
        SUB_C   = 8'h1C,  // A = A - C  
        JNO = 8'h1D,  // Jump if Overflow==0
        JO = 8'h1E;   // Jump if Overflow==1

    // Wires for ADD, SUB, INR, DCR Based Op
    //wire is_add = (opcode == ADDI)  || (opcode == ADD_B) || (opcode == ADD_C) || (opcode == BBC);
    wire is_sub = (opcode == SUBI)  || (opcode == SUB_B) || (opcode == SUB_C);
    wire is_inr = (opcode == INR_A) || (opcode == INR_B) || (opcode == INR_C);
    wire is_dcr = (opcode == DCR_A) || (opcode == DCR_B) || (opcode == DCR_C);

    // ---------------- ALU input selection ----------------
    wire [7:0] ALU_A =
        (opcode == ADDI || opcode == SUBI) ? AC :
        (opcode == ADD_B || opcode == ADD_C || opcode == SUB_B || opcode == SUB_C) ? AC :
        (opcode == BBC) ? B :
        (opcode == INR_A || opcode == DCR_A) ? AC :
        (opcode == INR_B || opcode == DCR_B) ? B  :
        (opcode == INR_C || opcode == DCR_C) ? C  :
        8'h00;

    wire [7:0] ALU_B =
        (opcode == ADDI || opcode == SUBI) ? operand :
        (opcode == ADD_B || opcode == SUB_B)  ? B :
        (opcode == ADD_C || opcode == SUB_C) ? C :
        (opcode == BBC) ? C :
        (is_inr || is_dcr) ? 8'h01 :     // +1 for INR, -1 via alu_sub for DCR
        8'h00;

    // SUB and DCR enable
    wire ALU_sub = is_sub || is_dcr;

    // ALU Sum Output
    wire [7:0] ALU_sum;
    wire CY,Z,OVF;
    ALU ALU1(
        .A   (ALU_A),
        .B   (ALU_B),
        .sub (ALU_sub),
        .Sum (ALU_sum),
        .Cout(CY),
        .Ovf (OVF),
        .ZERO(Z)
    );


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 0;
            AC <= 0;
            state <= FETCH;
            opcode <= 0;
            operand <= 0;
            B <= 0;
            C <= 0; 
            Carry    <= 0;
            Overflow <= 0;
            Zero     <= 0;
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
                        if((opcode == NOTA)||(opcode == SHL)||(opcode == SHR)||(opcode == HLT)||(opcode == INR_A)
                        ||(opcode == DCR_A)||(opcode == INR_B)||(opcode == DCR_B)||(opcode == INR_C)||(opcode == DCR_C)
                        ||(opcode == ADD_B)||(opcode == ADD_C)||(opcode == BBC)||(opcode == SUB_B)||(opcode == SUB_C)) begin
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
                            MVI_A:  AC <= operand;
                            ADDI:   begin AC <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            SUBI:   begin AC <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            ANDI:   AC <= AC & operand;
                            ORI:    AC <= AC | operand;
                            XORI:   AC <= AC ^ operand;
                            NOTA:   AC <= ~AC;
                            SHL:    AC <= AC << 1;
                            SHR:    AC <= AC >> 1;
                            HLT:   state <= HALT;

                            MVI_B:  B <= operand;
                            MVI_C:  C <= operand;
                            JMP:    PC <= PC + operand[4:0];
                            INR_A:  begin AC <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            DCR_A:  begin AC <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            INR_B:  begin B  <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            DCR_B:  begin B  <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            INR_C:  begin C  <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            DCR_C:  begin C  <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            JNZ: if(Zero == 1'b0) begin PC <= PC + operand[4:0]; end // JNZ addr
                            JZ: if(Zero == 1'b1) begin PC <= PC + operand[4:0]; end // JZ addr
                            JNC: if(Carry == 1'b0) begin PC <= PC + operand[4:0]; end // JNC addr
                            JC: if(Carry == 1'b1) begin PC <= PC + operand[4:0]; end // JC addr
                            ADD_B:  begin AC <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            ADD_C:  begin AC <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            BBC:    begin B  <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            SUB_B:  begin AC <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            SUB_C:  begin AC <= ALU_sum; Carry <= CY ; Zero <= Z; Overflow <= OVF; end
                            JNO: if(Overflow == 1'b0) begin PC <= PC + operand[4:0]; end // JNO addr
                            JO: if(Overflow == 1'b1) begin PC <= PC + operand[4:0]; end // JO addr
                            

                            
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
