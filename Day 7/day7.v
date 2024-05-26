// LFSR
module day7 (
  input     wire      clk,
  input     wire      reset,

  output    wire[3:0] lfsr_o
);

  reg [3:0]lfsr_ff;
  reg [3:0]nxt_lfsr;

  always@(posedge clk or posedge reset) 
    if(reset) 
      lfsr_ff <= 4'hE;
    else
      lfsr_ff <= nxt_lfsr;

  assign nxt_lfsr = {lfsr_ff[2:0], lfsr_ff[1] ^ lfsr_ff[3]};
  assign lfsr_o = lfsr_ff;

endmodule

/* 
  wire [3:0]internal_reg;

  assign lfsr_o =  internal_reg;

  always @ (posedge clk or negedge reset)
  begin
    if (reset)
      internal_reg <= 4'hE;
    else
      internal_reg <= {internal_reg[2:0], internal_reg[3]^ internal_reg[1]};
  end
endmodule
*/