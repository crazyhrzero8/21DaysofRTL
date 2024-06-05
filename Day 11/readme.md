Design and verify a 4-bit parallel to serial converter with valid and empty indications

Interface Definition

The module should have the following interface:

input     wire      clk,

input     wire      reset,

output    wire      empty_o,    -> Should be asserted when all of the bits are given out serially

input     wire[3:0] parallel_i, -> Parallel input vector
  
output    wire      serial_o,   -> Serial bit output

output    wire      valid_o     -> Serial bit is valid

Challenge

# Try solving this problem which deals with designing a parameterised parallel to serial converter with valid-ready interface on both paralle and the serial interface.