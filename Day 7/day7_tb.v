module day7_tb ();

  reg clk;
  reg reset;
  wire [3:0] lfsr_o;
  integer i;
  
  day7 tc(.*);
  
  initial begin
    clk = 1'b1;
    forever #2.5 clk = ~clk;
  end
  
  initial begin
    #0;       
    reset = 1;
    #5;
    reset = 0;
    for(i=0; i<20; i++) begin
      #5; reset=$urandom_range(0,1);
    end
    $finish();
  end

endmodule
