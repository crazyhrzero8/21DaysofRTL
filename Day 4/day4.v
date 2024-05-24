// A simple ALU

module day4 (
  input     logic [7:0]   a_i,
  input     logic [7:0]   b_i,
  input     logic [2:0]   op_i,

  output    logic [7:0]   alu_o
);

  localparam add = 3'b000;
  localparam sub = 3'b001;
  localparam sll = 3'b010;
  localparam lsr = 3'b011;
  localparam and_op = 3'b100;
  localparam or_op = 3'b101;
  localparam xor_op = 3'b110;
  localparam eql = 3'b111; 
  
  //reg carry; //did not use the carry with add because of latch inferred and shows signal not used in lint check

  always_comb begin
    case(op_i[2:0]) 
      add: {alu_o} = {a_i[7:0]} + {b_i[7:0]}; 
      sub: alu_o = a_i[7:0] - b_i[7:0];
      sll: alu_o = a_i[7:0] << b_i[2:0];
      lsr: alu_o = a_i[7:0] >> b_i[2:0];
      and_op: alu_o = a_i[7:0] & b_i[7:0];
      or_op: alu_o = a_i[7:0] | b_i[7:0];
      xor_op: alu_o = a_i[7:0] ^ b_i[7:0];
      eql: alu_o = {7'h0, a_i == b_i};
      default: alu_o = 8'b0;
    endcase
  end

endmodule
