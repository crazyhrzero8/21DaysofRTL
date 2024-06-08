Design and verify a sequence detector to detect the following sequence: 1110_1101_1011

Interface Definition

Overlapping sequences should be detected

The module should have the following interface:

input     wire        clk,

input     wire        reset,

input     wire        x_i,    -> Serial input

output    wire        det_o   -> Output asserted when sequence is detected

Challenge

Try solving this problem which deals with designing a sequence generator!