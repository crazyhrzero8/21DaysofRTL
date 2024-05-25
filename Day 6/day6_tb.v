// simple tb

module day6_tb ();

  reg clk;
  reg reset;
  reg x_i;
  wire [3:0]sr_o;
  
  integer i;
  
  day6 tc(.*);
  
  initial begin
    clk = 1'b1;
    forever #2.5 clk = ~clk;
  end
  
  initial begin
    #0;
    reset = 1;
    #5; 
    reset = 0; 
    x_i = 1;
    #5;
    x_i = 1;
    for(i=0; i<20; i++) begin
      #5; x_i = $urandom_range(0,1);
      #10; reset = $urandom_range(0,1);
    end
    $finish();
  end

endmodule
