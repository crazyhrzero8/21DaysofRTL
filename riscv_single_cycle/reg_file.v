module Reg_file (
input wire       clk,
input wire       rst,
input wire [4:0] Addr1,
input wire [4:0] Addr2,
input wire [4:0] Addr3,
input wire [31:0] wd3,
input wire        we3,
output reg [31:0] rd1,
output reg [31:0] rd2
);

reg [31:0] temp [0:31] ;
integer i ;

//clocked writing 
always@(posedge clk or posedge rst)
begin
  if(rst)
    begin
      for(i=0 ; i < 16 ; i = i+1)
      begin
        temp[i] <= 'h0 ;
      end
    end
  if(we3)
    begin
      temp[Addr3] <= wd3 ;
    end
end

//combinational reading
always@(*) begin
  if(Addr1 == 0) begin
       rd1 = 0 ; 
    end
  else begin
       rd1 = temp[Addr1] ;
    end
    
  if(Addr2 == 0) begin
       rd2 = 0 ; 
    end
  else begin
       rd2 = temp[Addr2] ;
    end
end

endmodule
