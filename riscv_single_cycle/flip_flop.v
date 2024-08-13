module flip_flop #(
parameter n = 32
)(
input wire clk,
input wire rst,
input wire [n-1:0] d,
output reg [n-1:0] q
);

always@(posedge clk or posedge rst) begin
  if(rst) begin
      q <= 0 ;
    end
  else begin
      q <= d ; 
    end
end

endmodule

    

