module day11_tb ();

  reg clk;
  reg reset;
  reg [3:0]parallel_i;
  wire empty_o;
  wire serial_o;
  wire valid_o;
  integer i;
  
  day11 tc(.*);
  
  initial begin
    clk = 1'b1;
    forever #2.5 clk = ~clk;
  end

  initial begin 
    #0;
    reset=1;
    parallel_i = 4'h0;
    #5;
    reset = 0;
    for(i=0; i<40; i=i+1) begin
      #5; 
      parallel_i = $urandom_range(0,4'hF);
    end
    $finish();
  end
  
endmodule
