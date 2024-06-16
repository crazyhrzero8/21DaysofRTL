// APB Slave

module day18 (
  input         wire        clk,
  input         wire        reset,
  input         wire        psel_i,
  input         wire        penable_i,
  input         wire[9:0]   paddr_i,
  input         wire        pwrite_i,
  input         wire[31:0]  pwdata_i,
  output        wire[31:0]  prdata_o,
  output                    val,
  output        wire        pready_o
);

  wire apb_req;
  assign apb_req = psel_i & penable_i;
  
  day17 memory(
    .clk(clk),
    .reset(reset),
    .req_i(apb_req),
    .req_rnw_i(~pwrite_i),
    .req_addr_i(paddr_i),
    .req_wdata_i(pwdata_i),
    .req_ready_o(pready_o),
    .val(val),
    .req_rdata_o(prdata_o)
  );

endmodule


// A memory interface

module day17 (
  input       wire        clk,
  input       wire        reset,
  input       wire        req_i,  //valid req inp remains asserted until ready is seen
  input       wire        req_rnw_i,    // 1 - read, 0 - write
  input       wire[9:0]   req_addr_i,  //4 bit memory address
  input       wire[31:0]  req_wdata_i,  //32 bit write data as given in question
  output      wire        val,  //to connect the missing port of falling edge
  output      wire        req_ready_o,  //ready out when req accepted
  output      wire[31:0]  req_rdata_o  //read data from memory
  
);

  // question is to make the valid high when there is a possibility to go high 
  // for random delay theres given with lfsr generation
  
  logic [15:0][31:0]mem; //16x32 bits wide memory given 
  
  logic [3:0]cnt_ff;
  logic [3:0]nxt_cnt;
  
  logic mem_rd;
  logic mem_wr;
  logic req_rise;
  logic [3:0]lfsr_val;
  logic [3:0]cnt;
  
  assign mem_rd = req_i & req_rnw_i;
  assign mem_wr = req_i & ~req_rnw_i;
  
  always@(posedge clk or posedge reset) begin
    if(reset)
      cnt_ff <= 4'h0;
    else 
      cnt_ff <= nxt_cnt;
  end
  
  assign nxt_cnt = req_rise ? lfsr_val :cnt_ff + 4'h1;
  assign cnt = cnt_ff;
  
  always@(posedge clk) begin
    if(mem_wr & ~|cnt)
      mem[req_addr_i] <= req_wdata_i;
  end
  
  assign req_rdata_o = mem[req_addr_i] & {32{mem_rd}};
  assign req_ready_o = ~|cnt;
  
  day3 risingedge(
    .clk(clk),
    .reset(reset),
    .a_i(req_i),
    .rising_edge_o(req_rise),
    .falling_edge_o(val)
  );
  
  day7 lfsr(
    .clk(clk),
    .reset(reset),
    .lfsr_o(lfsr_val)
  );

endmodule

// An edge detector
module day3 (
  input     wire    clk,
  input     wire    reset,

  input     wire    a_i,

  output    wire    rising_edge_o,
  output    wire    falling_edge_o
);

  reg a_i_delay;
  
  always@(posedge clk or posedge reset) begin
    if(reset)
      a_i_delay <= 1'b0;
    else
      a_i_delay <= a_i;
  end
  
  assign falling_edge_o = a_i_delay & ~a_i;
  assign rising_edge_o = ~a_i_delay & a_i;

endmodule

// LFSR
module day7 (
  input     wire      clk,
  input     wire      reset,

  output    wire[3:0] lfsr_o
);

  reg [3:0]lfsr_ff;
  reg [3:0]nxt_lfsr;

  always@(posedge clk or posedge reset) 
    if(reset) 
      lfsr_ff <= 4'hE;
    else
      lfsr_ff <= nxt_lfsr;

  assign nxt_lfsr = {lfsr_ff[2:0], lfsr_ff[1] ^ lfsr_ff[3]};
  assign lfsr_o = lfsr_ff;

endmodule
