 module Sign_ext (
input wire [31:7] in,
input wire [1:0] opcode,
output reg [31:0] out
);

always@(*) begin
  case(opcode)
    2'b00 : //I-type instruction
    out = { {20{in[31]}} , in[31:20] } ;
    2'b01 : //S-type instruction
    out = { {20{in[31]}} , in[31:25] , in[11:7] } ;
    2'b10 : //B-type instruction
    out = { {20{in[31]}} , in[7] , in[31:25] , in[11:8] , 1'b0} ;
    2'b11 : //J-type instruction
    out = { {12{in[31]}} , in[19:12] , in[20] , in[30:21] , 1'b0} ;
    default : out = 32'hxxxxxxxx ;
  endcase
end

endmodule