module top_RISCV #(
parameter n = 10 , m = 32
)(
input wire clk,
input wire rst,
output wire [n-1:0] addr,
output wire [m-1:0] write_data,
output wire        memwr,
output wire [31:0] read_data,
output wire [31:0] PC,
output wire [31:0] instr
);

wire [1:0]  PCsrc ;
wire [1:0]  immsrc ;
wire        ALUsrc ;
wire [1:0]  ALUctrl ;
wire [1:0]  resultsrc ;
wire        regwr ;
wire        zero ; 
wire [31:0] ALUout ;
//wire [31:0] PC ;
//wire [31:0] instr ;
//wire [31:0] read_data ; 

assign addr = ALUout[9:0] ;

datapath u_dp (
.clk(clk),
.rst(rst),
//instr memory inputs 
.instr(instr), 
//data memory inputs
.read_data(read_data), 
//CU inputs
.PCsrc(PCsrc),
.immsrc(immsrc),
.ALUsrc(ALUsrc),
.ALUctrl(ALUctrl),
.resultsrc(resultsrc),
.regwr(regwr),
//instr memory outputs
.PC(PC),
//data memory outputs
.zero(zero),
.ALUout(ALUout),
.write_data(write_data)
);

control_unit u_cu (
.op(instr[6:0]),
.funct3(instr[14:12]),
.funct7_5(instr[30]),
//Alu inputs
.zero(zero),
//datapath outputs
.PCsrc(PCsrc),
.immsrc(immsrc),
.ALUsrc(ALUsrc),
.ALUctrl(ALUctrl),
.resultsrc(resultsrc),
.regwr(regwr),
//data memory output
.memwr(memwr)
);

endmodule