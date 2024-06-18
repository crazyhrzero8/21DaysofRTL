// Find second bit set from LSB for a N-bit vector

module day21 #(
  parameter WIDTH = 12
)(
  input       wire [WIDTH-1:0]  vec_i,
  input       wire [WIDTH-1:0]  second_bit_o

);

  logic [WIDTH-1:0] first_bit;
  logic [WIDTH-1:0] masked_vec;

  // Find the first bit set
  day14 #(.NUM_PORTS(WIDTH)) find_first (
    .req_i          (vec_i),
    .gnt_o          (first_bit)
  );

  // Mask the first bit
  assign masked_vec = vec_i & ~first_bit;

  // Do a find first set on the masked vector to get second bit set
  day14 #(.NUM_PORTS(WIDTH)) find_second (
    .req_i          (masked_vec),
    .gnt_o          (second_bit_o)
  );

endmodule

// Priority arbiter
// port[0] - highest priority

module day14 #(
  parameter NUM_PORTS = 4
)(
    input      wire[NUM_PORTS-1:0] req_i,
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