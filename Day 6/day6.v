// Simple shift register

module day6(
  input     wire        clk,
  input     wire        reset,
  input     wire        x_i,      // Serial input

  output    wire[3:0]   sr_o
);

  reg [3:0]sr_ff;
  reg [3:0]nxt_sr;
  
  always@(posedge clk or posedge reset) begin
    if(reset) 
      sr_ff <= 4'b0;
    else 
      sr_ff <= nxt_sr;
  end

  assign nxt_sr = {sr_ff[2:0], x_i};
  assign sr_o = sr_ff;
  
endmodule
