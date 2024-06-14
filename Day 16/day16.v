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
