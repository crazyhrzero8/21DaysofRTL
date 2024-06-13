module day15_tb ();

  localparam NUM_REQUESTERS = 2;
  reg clk;
  reg reset;
  reg [NUM_REQUESTERS-1:0] req_i;
  wire [NUM_REQUESTERS-1:0] gnt_o;
  integer i;

  day15 #(.NUM_REQUESTERS(NUM_REQUESTERS)) tc(.clk(clk),.reset(reset),.req_i(req_i),.gnt_o(gnt_o));
  
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    reset = 1;
    req_i = 0;
    #5;
    reset = 0;
    for(i=0; i<32; i=i+1) begin
      req_i = $urandom_range(0, 2**NUM_REQUESTERS-1);
      #5;
    end
    $finish();
  end
  
endmodule
