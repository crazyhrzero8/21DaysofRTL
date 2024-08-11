`include "Cache_Controller.v"
`include "Cache_Memory_Data_Array.v"
`include "Main_Memory_System.v"

module top #(
      parameter no_of_banks = 4,           // DEFAULT SPECS, NO OF MEMORY BANKS
    parameter bank_sel_bits = 2,         // DEFAULT SPECS, NO. OF BITS TO SELECT BANK
    parameter bank_addr_width = 8,       // DEFAULT SPECS FROM MEMORY BANK
    parameter mem_word_size = 32,     // WORD SIZE OF MEMORY BANKS, DEFAULT SPECS
    parameter proc_word_size = 32,    // WORD SIZE FOR OUR PROCESSOR DATA BUS, DEFAULT SPECS
    parameter blk_0_offset = 127,     // CACHE BLOCK ---> |BLOCK 0 | BLOCK 1 | BLOCK 2| BLOCK 3|
    parameter blk_1_offset = 95,
    parameter blk_2_offset = 63,
    parameter blk_3_offset = 31,
  
  
  
    // DEFAULT SPECS FROM PROCESSOR
    parameter data_bus_width = 32,
    parameter addr_bus_width = 32,
    // DEFAULT SPECS FROM CACHE CONTROLLER
    parameter INDEX_BITS = 2,
    parameter TAG_BITS = 6,
    parameter SET_OFFSET_BITS = 2,
    // DEFAULT SPECS FROM CACHE MEMORY DATA ARRAY
    parameter loctn_bits = 4,
    parameter offset_bits = 2,
    parameter block_size = 128,
    // DEFAULT SPECS FROM MAIN MEMORY
    parameter bulk_read_size = 128,
    parameter bank_word_size = 32,
    parameter addr_width = 10,
    // OTHERS DERIVED FROM ABOVE SPECS
    parameter tag_offset = 9, // LOCAL ADDRESS --> | TAG  | INDEX | OFFSET |
    parameter index_offset = 3,
    parameter block_offset = 1
)(
    input wire clock,                // GLOBAL CLOCK
    input wire reset,                // GLOBAL ASYNC RESET
    input wire [addr_bus_width-1:0] addr,  // ADDRESS BUS
    output wire [data_bus_width-1:0] rdata, // DATA BUS FOR READ
    input wire [data_bus_width-1:0] wdata,  // DATA BUS FOR WRITE
    input wire flush,                // FLUSH CACHE LINES
    input wire rd,                   // READ SIGNAL FROM PROCESSOR
    input wire wr,                   // WRITE SIGNAL FROM PROCESSOR
    output wire stall                // STALL SIGNAL TO PROCESSOR
);

    // INTERCONNECT SIGNALS
    wire [addr_width-1:0] addr_local; // LOCALLY ADDRESSABLE MEMORY SPACE

    // FOR MAIN MEMORY CONNECTIONS
    wire ready_inter;
    wire [block_size-1:0] data_from_mem_inter;  
    wire rd_inter_mem;
    wire wr_inter_mem;

    // FOR CACHE DATA ARRAY CONNECTIONS
    wire refill_inter;
    wire update_inter;
    wire [INDEX_BITS + SET_OFFSET_BITS - 1:0] index_inter;

    // SUB MODULES
    Cache_Controller #(
        .INDEX_BITS(INDEX_BITS),
        .TAG_BITS(TAG_BITS),
        .SET_OFFSET_BITS(SET_OFFSET_BITS)
    ) Inst_Cache_Controller (
        .clock(clock),
        .reset(reset),
        .flush(flush),
        .rd(rd),
        .wr(wr),
        .index(addr_local[index_offset:block_offset+1]),
        .tag(addr_local[tag_offset:index_offset+1]),
        .ready(ready_inter),
        .loctn(index_inter),
        .refill(refill_inter),
        .update(update_inter),
        .read_from_mem(rd_inter_mem),
        .write_to_mem(wr_inter_mem),
        .stall(stall)
    );

    Cache_Memory_Data_Array #(
      .mem_word_size(mem_word_size),
      .proc_word_size(proc_word_size),
      .blk_0_offset(blk_0_offset),
      .blk_1_offset(blk_1_offset),
      .blk_2_offset(blk_2_offset),
      .blk_3_offset(blk_3_offset),
        .loctn_bits(loctn_bits),
        .offset_bits(offset_bits),
        .block_size(block_size),
        .data_bus_width(data_bus_width)
    ) Inst_Cache_Memory_Data_Array (
        .clock(clock),
        .refill(refill_inter),
        .update(update_inter),
        .index(index_inter),
        .offset(addr_local[block_offset:0]),
        .data_from_mem(data_from_mem_inter),
        .write_data(wdata),
        .read_data(rdata)
    );

    Main_Memory_System #(
      .no_of_banks(no_of_banks),
      .bank_sel_bits(bank_sel_bits),
      .bank_addr_width(bank_addr_width),
        .addr_width(addr_width),
        .bank_word_size(bank_word_size),
        .bulk_read_size(bulk_read_size)
    ) Inst_Main_Memory_System (
        .clock(clock),
        .reset(reset),
        .rd(rd_inter_mem),
        .wr(wr_inter_mem),
        .addr(addr_local),
        .data_in(wdata),
        .data_out(data_from_mem_inter),
        .data_ready(ready_inter)
    );

    assign addr_local = addr[addr_width-1:0];

endmodule