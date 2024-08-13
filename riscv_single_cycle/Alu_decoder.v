module Alu_decoder (
input wire [1:0]  ALUop,
input wire [2:0]  funct3,
input wire        funct7_5,
input wire        op_5,
output reg [1:0] ALUctrl
);

always@(*) begin
  case(ALUop)
    2'b00 : //adding for lw,sw,jalr
    begin
      ALUctrl = 2'b00 ;
    end
    2'b01 : //subtructing for beq,bne
    begin
      ALUctrl = 2'b01 ; 
    end
    2'b10 : //R,I-type instructions
    begin
      case(funct3)
        3'b000 : 
        begin
        if({op_5,funct7_5} == 3'b11) begin
              ALUctrl = 2'b01 ; //subtraction for sub
            end
          else begin
              ALUctrl = 2'b00 ; //adding for add,addi
            end
        end
        3'b111 : ALUctrl = 2'b10 ;//anding for and,andi
        3'b110 : ALUctrl = 2'b11 ;//oring for or,ori 
        default : ALUctrl = 2'bxx ;
      endcase
    end
    default : ALUctrl = 2'bxx ; 
  endcase
end

endmodule 
