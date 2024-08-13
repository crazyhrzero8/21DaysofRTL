module Alu (
input wire [1:0] ALUctrl ,  
input wire [31:0] A , B   ,
output reg [31:0] ALUout,
output wire       zero
);

assign zero = (ALUout == 0)? 1 : 0 ;

always@(*) begin
   case(ALUctrl)
     2'b00:  ALUout = A + B ;
     2'b01:  ALUout = A - B ;
     2'b10:  ALUout = A & B ;
     2'b11:  ALUout = A | B ;
     default:  ALUout = 'h0 ;
   endcase
end

endmodule 
