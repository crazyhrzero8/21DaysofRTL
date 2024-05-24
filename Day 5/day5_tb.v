// Simple TB

module day5_tb ();

  reg clk;
  reg reset;
  wire [7:0]cnt_o;
  
  day5 tc(.*);
  
  initial begin
    clk = 1'b1;
    forever #2.5 clk = ~clk;
  end
  
  initial begin
    #0;
    reset=1;
    #5;
    reset=0;
    #15;
    reset=1;
    #5;
    $finish();
  end

endmodule
