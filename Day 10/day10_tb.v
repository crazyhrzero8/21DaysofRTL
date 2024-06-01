module day10_tb ();

  reg clk;
  reg reset;
  reg load_i;
  reg [3:0]load_val_i;
  wire [3:0]count_o; 
  integer i; 
  integer cycle;
  
  day10 tc(.*);
  
  initial begin
    clk = 1;
    forever #2.5 clk = ~clk;
  end
  
  initial begin
    #0; 
    reset = 1;
    load_i = 0;
    load_val_i = 4'h0;
    #5;
    reset = 0;
    for(i=0; i<5; i=i+1) begin
      load_i = 1;
      load_val_i = 2*i-1;
      cycle = 4'hF - load_val_i[3:0];
      #5;
      load_i = 0;
      while(cycle) begin
        cycle = cycle - 1;
        #5;
      end
    end
    $finish();
  end
  
endmodule
