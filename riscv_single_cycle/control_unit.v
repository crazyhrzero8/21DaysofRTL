module control_unit(
//instr memory inputs
input wire [6:0]  op,
input wire [2:0]  funct3,
input wire        funct7_5,
//Alu inputs
input wire        zero,
//datapath outputs
output wire [1:0]  PCsrc,
output wire [1:0]  immsrc,
output wire        ALUsrc,
output wire [1:0]  ALUctrl,
output wire [1:0]  resultsrc,
output wire        regwr,
//data memory output
output wire       memwr
);

wire [1:0] ALUop ;
wire       jump;
wire       jalr;
wire       branch;
wire       zero_new ;

assign zero_new = (funct3[0] && op == 7'b1100011)? !zero : zero ; 

assign PCsrc = {jalr, ((zero_new & branch) | jump) } ; 

main_decoder u_md (
.op(op),
.jump(jump),
.jalr(jalr),
.branch(branch),
.immsrc(immsrc),
.ALUsrc(ALUsrc),
.ALUop(ALUop), //
.resultsrc(resultsrc),
.regwr(regwr),
.memwr(memwr)
); 

Alu_decoder u_ad (
.ALUop(ALUop),
.funct3(funct3),
.funct7_5(funct7_5),
.op_5(op[5]),
.ALUctrl(ALUctrl)
);


endmodule
