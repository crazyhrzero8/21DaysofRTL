// Round robin arbiter

module day15 #(
  parameter NUM_REQUESTERS = 4
)(
  input clk,
  input reset,
  input wire [NUM_REQUESTERS-1:0] req_i,
  output logic [NUM_REQUESTERS-1:0] gnt_o
);

  // Use mask to identify the last grant
  logic [NUM_REQUESTERS-1:0] mask_q;
  logic [NUM_REQUESTERS-1:0] nxt_mask;

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      mask_q <= {NUM_REQUESTERS{1'b1}};
    else
      mask_q <= nxt_mask;
  end

  // Next mask based on the current grant
  always@(*) begin
    nxt_mask = mask_q;
    if (|gnt_o) begin: mask
      for (int i = 0; i < NUM_REQUESTERS; i++) begin
        if (gnt_o[i]) begin
          nxt_mask = {NUM_REQUESTERS{1'b1}} << (i + 1);
          disable mask;
        end
      end
    end else begin
      nxt_mask = {NUM_REQUESTERS{1'b1}};
    end
  end

  // Generate the masked requests
  logic [NUM_REQUESTERS-1:0] mask_req;

  assign mask_req = req_i & mask_q;

  logic [NUM_REQUESTERS-1:0] mask_gnt;
  logic [NUM_REQUESTERS-1:0] raw_gnt;

  // Generate grants for req and masked req
  day14 #(NUM_REQUESTERS) maskedGnt (.req_i(mask_req), .gnt_o(mask_gnt));
  day14 #(NUM_REQUESTERS) rawGnt    (.req_i(req_i),    .gnt_o(raw_gnt));

  // Final grant based on mask req
  assign gnt_o = |mask_req ? mask_gnt : raw_gnt;

endmodule

// Priority arbiter
// port[0] - highest priority

module day14 #(
  parameter NUM_REQUESTERS = 4
)(
    input       wire[NUM_REQUESTERS-1:0] req_i,
    output      reg[NUM_REQUESTERS-1:0] gnt_o   // One-hot grant signal
);

  generate
    genvar i;
    always@(*) gnt_o[0] = req_i[0];
  //reg [NUM_PORTS-1:0]gnt;
  //assign gnt_o[0] = req_i[0]; //first priority
  //genvar i;
    for(i=1; i<NUM_REQUESTERS; i=i+1) begin
      always@(*) gnt_o[i] = req_i[i] & ~(|req_i[i-1:0]); //linting error solved here
    end
  endgenerate

endmodule







/*

module day15 #(
    parameter  NUM_PORTS = 4
) (
    input   logic                    clk     ,
    input   logic                    reset   ,
  input   logic   [NUM_PORTS-1:0]    req_i     ,
  output  logic   [NUM_PORTS-1:0]    gnt_o
);

localparam N = NUM_PORTS;
  localparam W = $clog2(NUM_PORTS);

logic [N-1:0] req_masked;
logic [N-1:0] mask_flag;
logic [N-1:0] grant_masked;
logic [N-1:0] grant_unmasked;
logic         all_req_flag;
logic [W-1:0] ptr;
logic [W-1:0] hit_ptr;

// mask last hit bit and low bit
generate
    genvar i;
    for(i=0;i<N;i=i+1) begin: HIT_POINTER_RECORD
        assign mask_flag[i] = (i > ptr) ? 1'b1 : 1'b0;
    end
endgenerate

// only bits higher than last hit take part
assign req_masked = req_i & mask_flag;

// simple priority
assign grant_masked[N-1:0] = req_masked & (~(req_masked-1));

// simple priority, all request join
  assign grant_unmasked[N-1:0] = req_i & (~(req_i-1));

// if higher bits are not valid, grant_mask will all zero, so all bits join arb
assign all_req_flag = ~(|req_masked);
assign gnt_o = ({N{all_req_flag}} & grant_unmasked) | grant_masked;

  assign hit_ptr = onehot2bin(gnt_o[W-1:0]);

// pointer update
  always @(posedge clk or negedge reset) begin
  if (reset) begin
      ptr <= (N - 1);
    end 
    else if (|req_i) begin
        ptr <= hit_ptr;
    end
end

// convert onehot to binary
  function automatic bit onehot2bin(input reg[W-1:0]onehot);
    int onehot2bin = 0;
    //genvar i;
    for (i=0; i<N; i=i+1) begin
        if (onehot[i]) 
          onehot2bin = i;
    end
endfunction

endmodule







module day15 #(
    parameter  NUM_PORTS = 4
) (
    input   logic                    clk     ,
    input   logic                    reset   ,
    input   logic   [NUM_PORTS-1:0]  req_i   ,
    output  logic   [NUM_PORTS-1:0]  gnt_o
);

localparam N = NUM_PORTS;
localparam W = $clog2(NUM_PORTS);

logic [N-1:0] req_masked;
logic [N-1:0] mask_flag;
logic [N-1:0] grant_masked;
logic [N-1:0] grant_unmasked;
logic         all_req_flag;
logic [W-1:0] ptr;
logic [W-1:0] hit_ptr;

// mask last hit bit and low bit
generate
    genvar i;
    for(i=0;i<N;i=i+1) begin: HIT_POINTER_RECORD
        assign mask_flag[i] = (i > ptr) ? 1'b1 : 1'b0;
    end
endgenerate

// only bits higher than last hit take part
assign req_masked = req_i & mask_flag;

// simple priority
assign grant_masked = req_masked & (~(req_masked - 1'b1));

// simple priority, all request join
assign grant_unmasked = req_i & (~(req_i - 1'b1));

// if higher bits are not valid, grant_mask will all zero, so all bits join arb
assign all_req_flag = ~(|req_masked);
assign gnt_o = ({N{all_req_flag}} & grant_unmasked) | grant_masked;

assign hit_ptr = onehot2bin(grant_masked);

// pointer update
always @(posedge clk or negedge reset) begin
    if (reset) begin
        ptr <= (N - 1);
    end 
    else if (|req_i) begin
        ptr <= hit_ptr;
    end
end

// convert onehot to binary
function automatic logic [$clog2(N)-1:0] onehot2bin(input logic [N-1:0] onehot);
    onehot2bin = 0;
    for (i=0; i<N; i=i+1) begin
        if (onehot[i]) 
            onehot2bin = i;
    end
endfunction

endmodule










// Arbiter module
module Arbiter #(
    parameter NumRequests = 8
) (
    input logic [NumRequests-1:0] request,
    output logic [NumRequests-1:0] grant
);

logic [NumRequests-1:0] grantReg;
logic [NumRequests-1:0] grantNext;

  always@(*) begin
    grantNext = grantReg;
    for (int i = 0; i < NumRequests; i++) begin
        if (request[i]) begin
            grantNext[i] = 1'b1;
            for (int j = i + 1; j < NumRequests; j++) begin
                grantNext[j] = 1'b0;
            end
        end
    end
end

always_ff @(posedge grantReg[0]) begin
    grant <= grantNext;
end

always_ff @(posedge grantReg[0]) begin
    grantReg <= grantNext;
end

endmodule

// Round-Robin Arbiter module
module day15 #(
    parameter NumRequests = 8
) (
    input logic clk,
    input logic reset,
  input logic [NumRequests-1:0] req_i,
  output logic [NumRequests-1:0] gnt_o
);

logic [NumRequests-1:0] mask, maskNext;
logic [NumRequests-1:0] maskedReq;
logic [NumRequests-1:0] unmaskedGrant;
logic [NumRequests-1:0] maskedGrant;

assign maskedReq = req_i & mask;

Arbiter #(
    .NumRequests(NumRequests)
) arbiter (
  .request(req_i),
    .grant(unmaskedGrant)
);

Arbiter #(
    .NumRequests(NumRequests)
) maskedArbiter (
    .request(maskedReq),
    .grant(maskedGrant)
);

assign gnt_o = (maskedReq == '0) ? unmaskedGrant : maskedGrant;

  //reg grantGiven; 
  always@(*) begin
  if (gnt_o == '0) begin
    maskNext = mask;
  end
  else begin
    maskNext = '1;
    //grantGiven = 1'b0;
    for (int i = 0; i < NumRequests; i++) begin
      maskNext[i] = 1'b0;
      //if (gnt_o[i]) 
        //grantGiven = 1'b1;
    end
  end
end

  always_ff @(posedge clk or negedge reset) begin
    if (reset) mask <= '1;
    else mask <= maskNext;
end

endmodule









`timescale 1ns / 1ps


module day15
#(
    parameter  NumRequests    =   4
)(
     input              clk
    ,input              reset
  ,input  [2**NumRequests-1:0]  req_i
  ,output [2**NumRequests-1:0]  gnt_o
);

//Thermo-Fixed Priority Encoders
//0 - High Priority
//1 - Whole Vector
wire    [2**NumRequests-1:0]  tfpe [NumRequests:0][1:0];

//High Priority Grant select
//0 - Whole vector
//1 - High Priority
wire                hp_gnt;

//FF to store thermo mask from the previous
//arbitration case
reg     [2**NumRequests-1:0]  mask;

//Thermo-encoded grant before being converted
//into one-hot
wire    [2**NumRequests-1:0]  th_gnt;

//Masked request
wire    [2**NumRequests-1:0]  req_masked;

always @(posedge clk)
if (reset)          mask <= 0;
else                mask <= th_gnt; 

assign req_masked = req_i & mask;

genvar i, j, k;
generate
for (j = 0; j < 2; j = j + 1) begin
    for (k = 0; k < NumRequests+1; k = k + 1) begin
        for (i = 0; i < 2**NumRequests; i = i + 1) begin
    
        //Level = 0
        if (k == 0) begin
            if (j == 0)
                if ((i % 2) == 1)   assign tfpe[k][j][i] = req_masked[i];
                else                assign tfpe[k][j][i] = req_masked[i] | req_masked[i+1];
            else
              if ((i % 2) == 1)   assign tfpe[k][j][i] = req_i[i];
          else                assign tfpe[k][j][i] = req_i[i] | req_i[i+1];
        end
     
        //Level = W
        else if (k == NumRequests) begin
            if (i == 0 | i == (2**NumRequests-1)) assign tfpe[k][j][i] = tfpe[k-1][j][i];
            else if ((i % 2) == 1)      assign tfpe[k][j][i] = tfpe[k-1][j][i] | tfpe[k-1][j][i+1];
            else                        assign tfpe[k][j][i] = tfpe[k-1][j][i];
        end
    
        //0 < Level < W
        else begin
            if (((i % 2) == 1) | ((i > (2**NumRequests-2**k-1)))) assign tfpe[k][j][i] =  tfpe[k-1][j][i];
            else                                        assign tfpe[k][j][i] =  tfpe[k-1][j][i] | tfpe[k-1][j][i+(2**k)];
        end
        
        end
    end
end
endgenerate

assign hp_gnt = |tfpe[NumRequests][0];
assign th_gnt = hp_gnt ? tfpe[NumRequests][0] : tfpe[NumRequests][1];

//Pre-grant is an intermediate signal to convert
//thermo-encoding into one-hot encoding
reg [2**NumRequests:0] pre_gnt;
  always@(*)
    pre_gnt = {1'b0, th_gnt} ^ {th_gnt, 1'b1};
assign gnt_o = pre_gnt[2**NumRequests:1];

endmodule


*/
