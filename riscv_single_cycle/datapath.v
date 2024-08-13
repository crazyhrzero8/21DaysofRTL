module datapath (
//global inputs
input wire clk,
input wire rst,
//instr memory inputs 
input wire [31:0] instr,
//data memory inputs
input wire [31:0] read_data,
//CU inputs
input wire [1:0]  PCsrc,
input wire [1:0]  immsrc,
input wire        ALUsrc,
input wire [1:0]  ALUctrl,
input wire [1:0]  resultsrc,
input wire        regwr,
//instr memory outputs
output wire [31:0] PC,
//data memory outputs
output wire        zero,
output wire [31:0] ALUout,
output wire [31:0] write_data
);

wire [31:0] PCnext , PCplus4 , PCtarget ;
wire [31:0] result ;
wire [31:0] SrcA , SrcB ;
wire [31:0] immext ;


flip_flop #(32) u_ff(
.clk(clk),
.rst(rst),
.d(PCnext), 
.q(PC) 
);
mux3x1 #(32) u_pcmux (
.sel(PCsrc)   ,
.in0(PCplus4) , 
.in1(PCtarget) , 
.in2( {ALUout[31:1],1'b0} ),
.out(PCnext) 
);

Reg_file u_regf (
.clk(clk),
.rst(rst),
.Addr1(instr[19:15]),
.Addr2(instr[24:20]),
.Addr3(instr[11:7]),
.wd3(result), 
.we3(regwr),
.rd1(SrcA), 
.rd2(write_data)
);

Sign_ext u_signext(
.in(instr[31:7]),
.opcode(immsrc),
.out(immext) 
);

mux2x1 #(32) u_alumux (
.sel(ALUsrc)   ,
.in0(write_data) , 
.in1(immext) , 
.out(SrcB) 
);

adder u_adderplus4 (
.in1(PC), 
.in2(32'd4),
.out(PCplus4) 
);

adder u_addertarget (
.in1(PC), 
.in2(immext), 
.out(PCtarget) 
);

Alu u_ALU (
.ALUctrl(ALUctrl) ,  
.A(SrcA) , 
.B(SrcB) , 
.ALUout(ALUout) ,
.zero(zero)
);

mux3x1 #(32) u_resultmux (
.sel(resultsrc)   ,
.in0(ALUout) , 
.in1(read_data) , 
.in2(PCplus4),
.out(result)
);

endmodule 