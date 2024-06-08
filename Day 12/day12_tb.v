module day12_tb ();

  reg clk; 
  reg reset;
  reg x_i;
  wire det_o;
  integer i;
  //reg [11:0]seq = 12'b1110_1101_1011;
  day12 tc(.*);
  
  /*
  initial begin
    clk = 1'b1;
    forever #2 clk = ~clk;
  end
  
  initial begin
    #0;
    reset = 1;
    x_i = 0;
    #5;
    reset = 0;
    //for(i=0; i<20; i=i+1) begin
    //  #5; x_i = seq[i];
    //end
    for(i=0; i<30; i=i+1) begin
      #5; x_i = $random%2;
    end
    $finish();
  end

  initial begin
reset= 1;
    x_i=0;
#4; reset= 0;
    #4; x_i = 1;
    #4; x_i = 1;
    #4; x_i = 1;
    #4; x_i = 0;
    #4; x_i = 1;
    #4; x_i = 1;
    #4; x_i = 0;
    #4; x_i = 1;
    #4; x_i = 1;
    #4; x_i = 0;
    #4; x_i = 1;
    #4; x_i = 1;
    for (i=20; i>0; i=i-1) begin
x_i= $random%2;
#1;
end
#20;
$finish();
end
*/
  
  always begin
    clk = 1'b1;
    #5;
    clk = 1'b0;
    #5;
  end

  reg [11:0] seq = 12'b1110_1101_1011;

  initial begin
    reset = 1'b1;
    x_i = 1'b1;
    @(posedge clk);
    reset = 1'b0;
    @(posedge clk);
    for (int i=0; i<12; i=i+1) begin
      x_i = seq[i];
      @(posedge clk);
    end
    for (int i=0; i<12; i=i+1) begin
      x_i = $random%2;
      @(posedge clk);
    end
    $finish();
  end
  
endmodule
