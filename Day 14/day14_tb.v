module day14_tb ();

  localparam NUM_PORTS = 16;
  reg [NUM_PORTS-1:0] req_i;
  wire [NUM_PORTS-1:0] gnt_o;
  integer i;

  day14 #(NUM_PORTS) tc(.*);
  
  initial begin
    for(i=0; i<32; i=i+1) begin
      req_i = $urandom_range(0, 2**NUM_PORTS-1);
      #5;
    end
  end
  
endmodule
