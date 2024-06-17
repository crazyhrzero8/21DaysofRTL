// Fifo TB

module day19_tb ();

  localparam DATA_W = 16;
  localparam DEPTH  = 8;
  logic              clk;
  logic              reset;
  logic              push_i;
  logic[DATA_W-1:0]  push_data_i;
  logic              pop_i;
  logic[DATA_W-1:0]  pop_data_o;
  logic              full_o;
  logic              empty_o;
  integer            i;
  
  day19 #(
    .DEPTH(DEPTH), 
    .DATA_W(DATA_W)
  ) tc(.*);
  
  initial begin
    clk = 1'b1;
    forever #1 clk = ~clk;
  end
  
  initial begin
    reset   <= 1'b1;
    push_i  <= 1'b0;
    pop_i   <= 1'b0;
    #5;
    reset   <= 1'b0;
    #10;
    // Make fifo full
    for (i=0; i<DEPTH; i++) begin
      push_i      <= 1'b1;
      push_data_i <= $urandom_range(0, 2**DATA_W-1);
      #5;
    end
    push_i <= 1'b0;
    #10;
    // Make fifo empty
    for (i=0; i<DEPTH; i++) begin
      pop_i      <= 1'b1;
      #5;
    end
    pop_i <= 1'b0;
    #10; 
    push_i      <= 1'b1;
    push_data_i <= $urandom_range(0, 2**DATA_W-1);
    #5;
    push_i      <= 1'b0;
    // Push and pop both
    for (i=0; i<DEPTH; i++) begin
      push_i      <= 1'b1;
      pop_i       <= 1'b1;
      push_data_i <= $urandom_range(0, 2**DATA_W-1);
      #5;
    end
    pop_i <= 1'b0;
    push_i<= 1'b0;
    #10;
    $finish();
  end

endmodule
