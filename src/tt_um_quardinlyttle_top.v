module tt_um_quardinlyttle_top (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

AQALU alu(ui_in[7:6], ui_in[5:4], ui_in[3:0],uio_out[7:0],clk,rst_n); //interface AQALU with Tiny Tape Out.

assign uio_oe = 8'b11111111; //assign bidrectional as outputs.
assign uo_out =0;

endmodule

module AQALU(A,B,Opcode,Output,clock, reset);

input [1:0] A,B;
input [3:0] Opcode;
input clock, reset;
output reg [7:0] Output;

wire [3:0] adderWire, subWire, mulWire;
wire [1:0] compWire;
wire [7:0] runningSumWire;

	TwoBitAdder adder({1'b0,A},{1'b0,B},adderWire,1'b0);
	TwoBitAdder subtract({1'b0,A},{1'b1,~B},subWire,1'b1);
multiplier mulitply(A,B,mulWire);
comparator compare(A,B, compWire);
runningSum sumboi({A,B},clock,runningSumWire, reset);

always @(*)
begin
	case(Opcode)
		4'b0000: Output= {6'b000000,A&B}; //And Opcode
		4'b0001: Output= {6'b000000, A|B}; //Or Opcode
		4'b0010: Output= {4'b0000,~A,~B}; //Not Opcode- Treats it as 4 bit input
		4'b0011: Output= {6'b000000,A^B}; //XOR Opcode
		4'b0100: Output= {6'b000000,~(A&B)};  //NAND Opcode
		4'b0101: Output= {6'b000000,~(A|B)}; //NOR Opcode
		4'b0110: Output= {6'b000000,~(A^B)}; //XNOR Opcode
		4'b0111: Output= {4'b0000,adderWire}; //Addition Opcode
		4'b1000: Output= {4'b0000,subWire};	//Subtract Opcode
		4'b1001: Output= {4'b0000,mulWire}; //Multiplication Opcode
		4'b1010: Output= {6'b000000,compWire}; //Compare Opcode; 2'b10 when A is greater than B, 2'b01 when B is greater than A. 2'b11 when equal.
		4'b1011: Output= {4'b0000,A,B} << 1; //Shift Left logic
		4'b1100: Output= {4'b0000,A,B} >> 1; //Shift Right Logic
		4'b1101: Output= {4'b0000,A,B} <<< 1; //Shift Left Arithmetic
		4'b1110: Output= {4'b0000,A,B} >>> 1; //Shift Right Arithmetic
		4'b1111: Output= runningSumWire; //Running Sum Opcode- Adds the number on the input to the current output result.
	endcase
end

endmodule


module TwoBitAdder(A,B, Sum,Cin); //Adder module created from fulladder

input Cin;
input [2:0] A,B;//A-0,1 B-2,3
output [3:0] Sum;

wire carry0, carry1;

fulladder adder1(A[0],B[0],Cin,Sum[0],carry0);
fulladder adder2(A[1], B[1],carry0,Sum[1],carry1);
fulladder adder3(A[2], B[2],carry1,Sum[2],Sum[3]);


endmodule


module fulladder(A,B,Cin,Sum,Cout); //Single bit adder block

input A, B, Cin;
output Cout, Sum;

wire and1, and2, and3;

xor(Sum, A, B, Cin);
and(and1, A, B);
and(and2, Cin, A);
and(and3, Cin, B);

or(Cout, and1, and2, and3);

endmodule

module multiplier(A,B,Result); 

//Multiplication module for 2 two bit inputs. Implemented via Kmap.

input [1:0] A,B;
output [3:0] Result;

wire and2_0, and2_1, and1_0, and1_1, and1_2, and1_3;

and(Result[3],A[1],A[0],B[1],B[0]); //M3
and(and2_0,A[1],~A[0],B[1]); //M2 first minterm
and(and2_1,A[1],B[1],~B[0]); //M2 second minterm
or(Result[2], and2_0, and2_1); //M2 final
and(and1_0,A[1],~B[1],B[0]); //M1 first minterm
and(and1_1,A[1], ~A[0], B[0]); //M1 second minterm
and(and1_2,~A[1], A[0], B[1]); //M1 third minterm
and(and1_3,A[0],B[1],~B[0]); //M1 fourth minterm
or(Result[1], and1_0, and1_1, and1_2, and1_3); //M1 final
and(Result[0], A[0], B[0]); //M0

endmodule


module comparator (A,B,Result);
//Using a comparator where 2'b11 = equal, 2'b10 means A is greater and 2'b01 means B is greater.

input [1:0] A,B;
output [1:0] Result;

wire c1_0, c1_1, c1_2, c1_3, c1_4, c0_0, c0_1, c0_2, c0_3, c0_4;

and(c1_0,~B[1],~B[0]);
and(c1_1,A[0],~B[1]);
and(c1_2, A[1],A[0]);
and(c1_3, A[1],~B[0]);
and(c1_4, A[1], ~B[1]);
or(Result[1], c1_0,c1_1,c1_2,c1_3,c1_4);

and(c0_0,~A[1],~A[0]);
and(c0_1, B[1], B[0]);
and(c0_2, ~A[1], B[0]);
and(c0_3, ~A[1], B[1]);
and(c0_4, ~A[0], B[1]);
or(Result[0], c0_0, c0_1, c0_2, c0_3, c0_4); 

endmodule

module runningSum (A, clk, Result, rst);

input [3:0] A;
input clk, rst;
output reg [7:0] Result;

reg [25:0] counter;

always @(posedge clk, posedge rst)
	begin
		if(rst==1)
		begin
			counter <=0;
			Result <=0;
		end
		else if (counter == 26'd50_000_000) //Tiny tape out has a 10MHz clock
		begin	
			counter <= 0;
			Result <= Result+A;
		end
		else
			counter<= counter +1;
		end
		
endmodule	

			

