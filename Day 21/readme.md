Design and verify a module which finds the second bit set from LSB for a N-bit vector.

Interface Definition:

Output should be produced in a single cycle

Output must be one-hot or zero

The module should have the following interface:

module day21 #(

  parameter WIDTH = 12

)(

    input  wire [WIDTH-1:0] vec_i,

    output wire [WIDTH-1:0] second_bit_o

);