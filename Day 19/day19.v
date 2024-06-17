// Parameterized fifo with 2 methods

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

/*

//using fsm logic, way more structured
module day19 #(
  parameter DEPTH   = 4,
  parameter DATA_W  = 1
)(
  input         wire              clk,
  input         wire              reset,

  input         wire              push_i,
  input         wire[DATA_W-1:0]  push_data_i,

  input         wire              pop_i,
  output        wire[DATA_W-1:0]  pop_data_o,

  output        wire              full_o,
  output        wire              empty_o
);

  parameter ST_PUSH = 2'b01;
  parameter ST_POP = 2'b10;
  parameter ST_BOTH = 2'b11;
  parameter PTR_W = $clog2(DEPTH);
  
  logic [PTR_W:0]nxt_rd_ptr;
  logic [PTR_W:0]rd_ptr_q;
  logic [PTR_W:0]nxt_wr_ptr;
  logic [PTR_W:0]wr_ptr_q;
  logic [DATA_W-1:0]fifo_pop_data;
  logic [DEPTH-1:0][DATA_W-1:0]fifo_mem;
  
  //pointer updation
  always@(posedge clk or posedge reset) begin
    if(reset) begin
      rd_ptr_q <= {PTR_W+1{1'b0}};
      wr_ptr_q <= {PTR_W+1{1'b0}};
    end
    else begin
      rd_ptr_q <= nxt_rd_ptr;
      wr_ptr_q <= nxt_wr_ptr;
    end
  end
  
  //states updation
  always@(*) begin
    nxt_wr_ptr = rd_ptr_q;
    nxt_wr_ptr = wr_ptr_q;
    fifo_pop_data = fifo_mem[rd_ptr_q[PTR_W-1:0]];
    case({pop_i, push_i})
      ST_PUSH: begin
        nxt_wr_ptr = wr_ptr_q + {{PTR_W{1'b0}}, 1'b1}; //incrementing the next ptr
      end
      ST_POP: begin
        nxt_rd_ptr = rd_ptr_q + {{PTR_W{1'b0}}, 1'b1}; //incrementing the read pointer
        fifo_pop_data = fifo_mem[rd_ptr_q[PTR_W-1:0]]; //driving the pop data
      end
      ST_BOTH: begin
        nxt_wr_ptr = wr_ptr_q + {{PTR_W{1'b0}}, 1'b1};
        nxt_rd_ptr = rd_ptr_q + {{PTR_W{1'b0}}, 1'b1};
      end
    endcase
  end
  
  //fifo storage and outputs
  always@(posedge clk) begin
    if(push_i)
      fifo_mem[wr_ptr_q[PTR_W-1:0]] <= push_data_i;
  end
  
  assign pop_data_o = fifo_pop_data; //to give out the reg to wire
  // to check the full and empty wire flag using the msb/lsb condition
  assign full_o = (rd_ptr_q[PTR_W] != wr_ptr_q[PTR_W]) & (rd_ptr_q[PTR_W-1:0] == wr_ptr_q[PTR_W-1:0]); 
  assign empty_o = (rd_ptr_q[PTR_W:0] == wr_ptr_q[PTR_W:0]);
  
endmodule

*/