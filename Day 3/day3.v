 // An edge detector

module day3 (
  input     wire    clk,
  input     wire    reset,

  input     wire    a_i,

  output    wire    rising_edge_o,
  output    wire    falling_edge_o
);

  reg a_i_delay;
  
  always@(posedge clk or posedge reset) begin
    if(reset)
      a_i_delay <= 1'b0;
    else
      a_i_delay <= a_i;
  end
  
  assign falling_edge_o = a_i_delay & ~a_i;
  assign rising_edge_o = ~a_i_delay & a_i;

endmodule
