// Simple APB TB

module day18_tb ();

  logic        clk;
  logic        reset;

  logic        psel_i;
  logic        penable_i;
  logic[9:0]   paddr_i;
  logic        pwrite_i;
  logic[31:0]  pwdata_i;
  logic[31:0]  prdata_o;
  logic        pready_o;
  logic        val;

  logic [9:0] [9:0] rand_addr_list;
  integer i;
  
  day18 tc(.*);
  
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    reset     <= 1'b1;
    psel_i    <= 1'b0;
    penable_i <= 1'b0;
    #5;
    reset     <= 1'b0;
    #5;
    // Send 10 write transactions to random addresses
    for (i=0; i<10; i++) begin
      psel_i  <= 1'b1;      // ST_SETUP
      #5;
      penable_i <= 1'b1;    // ST_ACCESS
      paddr_i   <= $urandom_range(0, 10'h3FF);
      pwrite_i  <= 1'b1;    // Write
      pwdata_i  <= $urandom_range(0, 16'hFFFF);
      // Wait for PREADY
      while (~(psel_i & penable_i & pready_o)) 
        #5;
      psel_i    <= 1'b0;
      penable_i <= 1'b0;
      rand_addr_list[i] = paddr_i;
      #5;
    end

    // Send 10 read transactions to the write addresses
    for (i=0; i<10; i++) begin
      psel_i  <= 1'b1;      // ST_SETUP
      #5;
      penable_i <= 1'b1;    // ST_ACCESS
      paddr_i   <= rand_addr_list[i];
      pwrite_i  <= 1'b0;    // READ
      pwdata_i  <= $urandom_range(0, 16'hFFFF);
      // Wait for PREADY
      while (~(psel_i & penable_i & pready_o)) 
        #5; //if you are using @(posedge clk) you will see a bit difference in the waveform
      psel_i    <= 1'b0;
      penable_i <= 1'b0;
      #5;
    end
    $finish();
  end

endmodule
