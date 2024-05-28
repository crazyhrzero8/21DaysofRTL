module day8_tb();

  localparam BIN_W = 8;
  localparam ONE_HOT_W = 32;
  
  reg [BIN_W - 1:0] bin_i;
  wire [ONE_HOT_W - 1:0] one_hot_o;
  integer i;
  
  day8 #(BIN_W, ONE_HOT_W) day8 (.*);
  
  initial begin
    #0; bin_i = 0;
    for(i=0; i<64; i=i+1) begin
      #5; bin_i = $urandom_range(0, 'hF);
    end
    $finish();
  end

endmodule
