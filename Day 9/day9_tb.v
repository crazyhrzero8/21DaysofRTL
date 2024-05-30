module day9_tb ();

  localparam VEC_W = 5;
  reg [VEC_W -1:0] bin_i;
  wire [VEC_W -1:0] gray_o;
  integer i;
  
  day9 #(VEC_W) tc (.*);
  
  initial begin
    #0; bin_i = 0;
    for(i=0; i<2**VEC_W; i=i+1) begin
      #5; bin_i = i;
    end
    $finish();
  end

endmodule
