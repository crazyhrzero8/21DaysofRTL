// Different DFF

module day2 (
  input     clk,
  input     reset,

  input     d_i,

  output    reg q_norst_o,
  output    reg q_syncrst_o,
  output    reg q_asyncrst_o
);

  always@(posedge clk) begin
      q_norst_o <= d_i;
  end
  
  always@(posedge clk) begin
    if(reset)
      q_syncrst_o <= 1'b0;
    else
      q_syncrst_o <= d_i;
  end
  
  always@(posedge clk or posedge reset) begin
    if(reset)
      q_asyncrst_o <= 1'b0;
    else 
      q_asyncrst_o <= d_i;
  end
  // it has to be noted that it has some linting issues
endmodule
