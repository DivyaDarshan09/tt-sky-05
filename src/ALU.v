module ALU (
    input wire [7:0] A,      
    input wire [7:0] B,
    input  wire    sub,     // 0 = Add, 1 = Subtract
    output [7:0] Sum, 
    output       Cout,    // Carry flag
    output       Ovf,     // Overflow flag
    output       ZERO
);

    wire [7:0] B_in;
    wire Cin;
    wire I_Carry;

    // If subtracting, invert B and set Cin=1
    assign B_in = sub ? ~B : B;
    assign Cin  = sub ? 1'b1 : 1'b0;

    // Perform addition
    assign {I_Carry, Sum} = A + B_in + {7'b0000000,Cin};
    assign Cout = sub ? ~(I_Carry) : (I_Carry);

    // Signed overflow detection
    assign Ovf = (A[7] == B_in[7]) && (Sum[7] != A[7]);
    assign ZERO = (Sum == 8'h0);
endmodule
