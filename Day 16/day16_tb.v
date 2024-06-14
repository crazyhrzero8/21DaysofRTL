// APB Master TB

module day16_tb ();

  logic        clk;
  logic        reset;

  logic[1:0]   cmd_i;

  logic        psel_o;
  logic        penable_o;
  logic[31:0]  paddr_o;
  logic        pwrite_o;
  logic[31:0]  pwdata_o;
  logic        pready_i;
  logic[31:0]  prdata_i;
  integer i,j;
  
  day16 tc(.*);
  
  initial begin
    clk = 1'b1;
    forever #5 clk = ~clk;
  end
  
  initial begin
    reset = 1;
    pready_i = 0;
    cmd_i = 0;
    #10;
    reset = 0; 
    cmd_i = 0;
    repeat(5)
      prdata_i = $urandom_range(0, 4'hF);
    for(i=0; i<10; i++) begin
      cmd_i = i%2 ? 2'b10 : 2'b01;
      prdata_i = $urandom_range(0, 4'hF);
      while(~pready_i | ~psel_o) 
        #10;
    end
    $finish();
  end

endmodule
