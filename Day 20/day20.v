// A useless system
//Lint error occurs here if you try to compile this code due to val

module day20 (
  input       wire        clk,
  input       wire        reset,
  input       wire        read_i, //sending a read req
  input       wire        write_i, //sending a write req
  output      wire        rd_valid_o, //high when read data is valid
  output      wire[31:0]  rd_data_o //read data
);
  
  logic rd_gnt;
  logic wr_gnt;
  logic push;
  logic pop;
  logic [1:0]push_data;
  logic [1:0]pop_data;
  logic full;
  logic empty;
  logic psel;
  logic penable;
  logic pwrite;
  logic [31:0]paddr;
  logic [31:0]pwdata;
  logic pready;
  logic [31:0]prdata;
  
  assign push = |{rd_gnt, wr_gnt};
  assign push_data = {wr_gnt, rd_gnt};
  assign pop = ~empty & ~(psel & penable);
  assign rd_valid_o = pready & ~pwrite;
  assign rd_data_o = {32{rd_valid_o}} & prdata;

  //Question is to make this in a flow below, 
  //ARB-->FIFO-->APBM<-->APBS(rd_valid_o, rd_data_o) 
  day14 #(.NUM_PORTS(2)) arbiter(
    .req_i({read_i, write_i}),
    .gnt_o({rd_gnt, wr_gnt})
  );
  
  day19 #(.DEPTH(16), .DATA_W(2)) FIFO(
    .clk(clk),
    .reset(reset),
    .push_i(push),
    .push_data_i(push_data),
    .pop_i(pop),
    .pop_data_o(pop_data),
    .full_o(full),
    .empty_o(empty)
  );

  // Instantiate the APB Master
  day16 apb_master (
    .clk(clk),
    .reset(reset),
    .cmd_i(pop_data),
    .psel_o(psel),
    .penable_o(penable),
    .paddr_o(paddr),
    .pwrite_o(pwrite),
    .pwdata_o(pwdata),
    .pready_i(pready),
    .prdata_i(prdata)
  );

  // Instantiate the APB Slave
  day18 apb_slave (
    .clk(clk),
    .reset(reset),
    .psel_i(psel),
    .penable_i(penable),
    .paddr_i(paddr[9:0]),
    .pwrite_i(pwrite),
    .pwdata_i(pwdata),
    .pready_o(pready),
    .prdata_o(prdata)
  );

endmodule

// Priority arbiter
// port[0] - highest priority

module day14 #(
  parameter NUM_PORTS = 4
)(
    input       wire[NUM_PORTS-1:0] req_i,
    output      reg[NUM_PORTS-1:0] gnt_o   // One-hot grant signal
);

  generate
    genvar i;
    always@(*) gnt_o[0] = req_i[0];
  //reg [NUM_PORTS-1:0]gnt;
  //assign gnt_o[0] = req_i[0]; //first priority
  //genvar i;
    for(i=1; i<NUM_PORTS; i=i+1) begin
      always@(*) gnt_o[i] = req_i[i] & ~(|req_i[i-1:0]); //linting error solved here
    end
  endgenerate

endmodule

// APB Master

// TB should drive a cmd_i input decoded as:
//  - 2'b00 - No-op
//  - 2'b01 - Read from address 0xDEAD_CAFE
//  - 2'b10 - Increment the previously read data and store it to 0xDEAD_CAFE

module day16 (
  input       wire        clk,
  input       wire        reset,
  input       wire[1:0]   cmd_i,
  input       wire        pready_i,
  input       wire[31:0]  prdata_i,
  
  output      wire        psel_o,
  output      wire        penable_o,
  output      wire[31:0]  paddr_o,
  output      wire        pwrite_o,
  output      wire[31:0]  pwdata_o
);

  typedef enum logic [1:0]{ST_IDLE = 2'b00, ST_SETUP = 2'b01, ST_ACCESS = 2'b10}apb_state_t;
  
  apb_state_t nxt_t;
  apb_state_t state_q;
  
  logic [31:0]rdata_q;
  
  always@(posedge clk or posedge reset) begin
    if(reset)
      state_q <= ST_IDLE;
    else
      state_q <= nxt_t;
  end
  
  always@(*) begin
    nxt_t = state_q;
    case(state_q)
      ST_IDLE : if(|cmd_i)
                  nxt_t = ST_SETUP;
                else
                  nxt_t = ST_IDLE;
      ST_SETUP : nxt_t = ST_ACCESS;
      ST_ACCESS : if(pready_i) nxt_t = ST_IDLE;
      default : nxt_t = state_q;
    endcase
  end 
  
  always@(posedge clk or posedge reset) begin //capturing the read data to store it for next write
    if(reset)
      rdata_q <= 32'h0;
    else if(penable_o && pready_i)
      rdata_q <= prdata_i;
    else rdata_q <= 0;
  end
  
  assign psel_o = (state_q == ST_SETUP) | (state_q == ST_ACCESS);
  assign penable_o = (state_q == ST_ACCESS);
  assign pwrite_o = cmd_i[1];
  assign paddr_o = 32'hDEAD_CAFE;
  assign pwdata_o = rdata_q + 32'h1;

endmodule

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

//using parameter and simple approach
module day19 #(
  parameter DEPTH   = 4,
  parameter DATA_W  = 1
)(
  input         wire              clk,
  input         wire              reset,
  input         wire              push_i,
  input         wire[DATA_W-1:0]  push_data_i,
  input         wire              pop_i,
  output reg    [DATA_W-1:0]      pop_data_o,
  output reg                      full_o,
  output reg                      empty_o
);

  // Calculate address width based on depth
  localparam ADDR_W = $clog2(DEPTH);

  // FIFO memory
  reg [DATA_W-1:0] fifo_mem[0:DEPTH-1];

  // Read and write pointers
  reg [ADDR_W-1:0] rd_ptr;
  reg [ADDR_W-1:0] wr_ptr;

  // FIFO count
  reg [ADDR_W:0] fifo_count;

  // Combinational logic for full and empty signals
  always @(*) begin
    full_o  = (fifo_count == DEPTH);
    empty_o = (fifo_count == 0);
  end

  // Sequential logic for FIFO operations
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      // Reset pointers and count
      rd_ptr     <= 0;
      wr_ptr     <= 0;
      fifo_count <= 0;
      pop_data_o <= 0;
    end 
    else begin
      // Push data into the FIFO
      if (push_i && !full_o) begin
        fifo_mem[wr_ptr] <= push_data_i;
        wr_ptr           <= wr_ptr + 1;
        fifo_count       <= fifo_count + 1;
      end

      // Pop data from the FIFO
      if (pop_i && !empty_o) begin
        pop_data_o <= fifo_mem[rd_ptr];
        rd_ptr     <= rd_ptr + 1;
        fifo_count <= fifo_count - 1;
      end
    end
  end

endmodule
