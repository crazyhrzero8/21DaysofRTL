// Memory TB

module day17_tb ();

  logic        clk;
  logic        reset;
  logic        req_i;
  logic        req_rnw_i;
  logic   [9:0]req_addr_i;
  logic  [31:0]req_wdata_i;
  logic        req_ready_o;
  logic  [31:0]req_rdata_o;
  logic        val;
  
  logic [9:0][9:0]addr_list;
  integer txn;

  day17 tc(.*);
  
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    reset = 1'b1;
    req_i = 1'b0;
    req_rnw_i = 1'b0;
    #5;
    reset = 1'b1;
    for (txn=0; txn<20; txn++) begin
      // Write 10 transactions
      req_i       <= 1'b1;
      req_rnw_i   <= 0;
      req_addr_i  <= $urandom_range(0, 1023);
      addr_list[txn] = req_addr_i;
      req_wdata_i <= $urandom_range(0, 32'hFFFF);
      // Wait for ready
      while (~req_ready_o) begin
        #5;
      end
      req_i <= 1'b0;
      #5;
    end
    for (txn=0; txn<20; txn++) begin
      req_i       <= 1'b1;
      req_rnw_i   <= 1;
      req_addr_i  <= addr_list[txn];
      req_wdata_i <= $urandom_range(0, 32'hFFFF);
      // Wait for ready
      while (~req_ready_o) begin
        #5;
      end
      req_i <= 1'b0;
      #5;
    end
    $finish();
  end

endmodule
