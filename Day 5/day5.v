// Odd counter

module day5 (
  input     wire        clk,
  input     wire        reset,

  output    logic[7:0]  cnt_o
);

  wire [7:0]cnt;
  
  always@(posedge clk or posedge reset) begin
    if(reset) 
      cnt_o <= 8'h1;
    else 
      cnt_o <= cnt;
  end
  
  assign cnt=cnt_o+8'h2;

endmodule
