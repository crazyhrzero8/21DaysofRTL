Design and verify a 4-bit linear feedback shift register where the bit0 of the register is driven by the XOR of the LFSR register bit1 and bit3

Interface Definition

The module should have the following interface:

input     wire      clk,

input     wire      reset,

output    wire[3:0] lfsr_o