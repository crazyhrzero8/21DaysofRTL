Design and verify a read/write system described below:

Writes should have higher priority than reads

Sytem should be able to buffer 16 read or write requests to avoid any loss

System must use APB master/slave protocol to communicate to memory interface

ARB-->FIFO-->APBM<-->APBS(rd_valid_o, rd_data_o) 

The idea behind this problem is to exercise how a complex system can be created by connecting various small blocks together

Interface Definition

The module should have the following interface:

module day20 (

  input       wire        clk,

  input       wire        reset,

  input       wire        read_i,       - Sends a read request when asserted

  input       wire        write_i,      - Sends a write request when asserted

  output      wire        rd_valid_o,   - Should be asserted whenever read data is valid

  output      wire[31:0]  rd_data_o     - Read data

);