// TB

module day20_tb ();

  logic        clk;
  logic        reset;
  logic        read_i;
  logic        write_i;
  logic        rd_valid_o;
  logic  [31:0]rd_data_o;
  integer      i;
  
  day20 tc(.*);
  
  initial begin
    clk = 1'b0;
    forever #1 clk = !clk;
  end
  
  initial begin
    reset     <= 1'b1;
    read_i    <= 1'b0;
    write_i   <= 1'b0;
    #5;
    reset <= 1'b0;
    #5;
    for (i=0; i<512; i++) begin
      read_i    <= $urandom_range(25,50)%2;
      write_i   <= $urandom_range(0, 25)%2;
      #5;
    end
    $finish();
  end

endmodule
