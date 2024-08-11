Cache controller module:

--                    - Single-banked Write-Through Cache Controller

--                    - Addresses 16 entries/Cache Lines, 256 bytes Associative Mapped Cache

--                    - 4 Sets, each Set has 4 Cache Lines

--                    - Tree-PLRU Algorithm as Cache Replacement Policy

--                    - No-write allocate(Write-Around) Policy

--                    - No Write Buffer, or other optimisations

--							 - Tag Array incorporated

--                    - Assuming address placed on the 0th cycle,

--                      READ HIT   --> Net Access Time = 3 cycles

--                      WRITE HIT  --> Net Access Time = 5 cycles cz of Write-Through Scheme

--			READ MISS  --> 4 stall cycles Penalty, Net Access Time = 7 cycles

--                      WRITE MISS --> Net Access Time = 5 cycles

-- Performance      : Max. freq = 110 MHz @Balanced Optimisation Synthesis Goal 

-- Comments         : Tag memory array is implemented in Flip-Flops


Cache memory data array: 

--                    - 256 bytes single-bank cache, inferred using Flip-Flops

--                    - Max. depth of 16 entries, block/cache line size = 16 bytes (four 32-bit words)

--                    - Initially two cycles latency for consecutive read, then data read every cycle

--                    - #R/W PROTOCOL WITH PROCESSOR AS FOLLOWS (READ = 2 CYCLES, WRITE = 1 CYCLES)

--                      1st cycle --> address placed, rd/wr signal asserted by processor

--			2nd cycle --> data available/written

--			3rd cycle --> data read by processor--
		
--                    - Writes/Reads one word at a time from processor

--                    - Accepts 16 bytes block from Main Memory

--                    Comments: 128*16 = 2048 Flip-flops generated for the cache memory

--                    if slow synthesis, reduce memory size by decrementing ix


Memory Banks: 

Infers a XST Block RAM of 1 kB, 32-bit data, 256 addressable locations

read, write latency = 1 clock cycle 

Comments: Synthesisablity of default values on mem array depends on the board and tool

Mem array tested to infer Block RAM only on Xilinx FPGAs

If distributed RAM/flipflops are inferred, memory size may have to be reduced 

depending on the availability of resources on FPGA, it will reduce routing time


Main Memory Systems: 
-- Default Specs    : - Consists of four memory banks of 1 kB each. Total size = 4 kB.
--                    - Interleaved Memory System.
--							 - #R/W PROTOCOL WITH MASTER AS FOLLOWS (READ = 4 CYCLES, WRITE = 4 CYCLES)	
--                      1st cycle --> address placed, rd/wr signal asserted by the master
--							   2nd cycle --> data available/written, asserts data ready signal
--							   3rd cycle --> data acknowledged by the master by negating rd/wr signal
--                      4th cycle --> de-asserts data ready signal
--                      5th cycle --> next address may be placed
--								Master can place the next address on the 4th cycle as well (3 CYCLE OPERATION) 
--                    - Writes only one word to one location at a time
--							 - Reads are bulk of 4 words together, through higher bandwidth bus
-- Comments         : Pay attention to the dependencies in the code to memory banks and their number


Top: 
-- Description      : Top Module that integrates the following Modules:
--							 - Cache Controller
--							 - Cache Memory Data Array
--							 - Main Memory System
-- Test stats       : - Block RAM inferred for Main Memory
--                    - Flip-flops inferred for Cache Memory Data Array
--						    - Placement effort: Standard, Design goal applied: Balanced                    
--                    - HDL optimisations: Max. fanout = 50, Reg. duplication ON, Eq. Reg removal OFF
--                    - Timing verified for a Maxm. clk frq of operation: 100 MHz


tb_top: 
-- Description   : This TB models a non-pipelined processor which generates memory read/write
--                 requests to the Cache Controller frequently. It is assumed that same clock
--                 drives all the modules in the test environment.
--                 CPI of the processor is assumed to be = 4 + Memory Access Cycles
-- Comments      : Test bench numerics are bound to changes in DUT.
