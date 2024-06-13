module day15_tb ();

  localparam NUM_REQUESTERS = 2;
  reg [NUM_REQUESTERS-1:0] req_i;
  wire [NUM_REQUESTERS-1:0] gnt_o;
  integer i;

  day15 #(.NUM_REQUESTERS(NUM_REQUESTERS)) tc(.clk(clk),.reset(reset),.req_i(req_i),.gnt_o(gnt_o));
  
  initial begin
    for(i=0; i<32; i=i+1) begin
      req_i = $urandom_range(0, 2**NUM_REQUESTERS-1);
      #5;
    end
  end
  
endmodule
