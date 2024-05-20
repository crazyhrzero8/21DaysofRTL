// DFF TB

module day2_tb ();

  reg clk;
  reg reset;
  reg d_i;
  wire q_norst_o;
  wire q_syncrst_o;
  wire q_asyncrst_o;

  day2 DAY2 (.*);

  initial clk = 1'b1;
  always begin
    #5; clk = 1'b0;
  end

  initial begin
    #0; reset = 1'b1;
    #2; d_i = 1'b0;
    #2; reset = 1'b0;
    #5; d_i = 1'b1;
    #1; reset = 1'b1;
    #1; reset = 1'b0;
    $finish();
  end

endmodule