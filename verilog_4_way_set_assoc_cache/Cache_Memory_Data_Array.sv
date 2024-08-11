module Cache_Memory_Data_Array #(
    parameter loctn_bits = 4,         // 16 ENTRIES, DEFAULT SPECS
    parameter offset_bits = 2,        // TO CHOOSE A WORD FROM A BLOCK SIZE = 4 MEMORY WORDS, DEFAULT SPECS
    parameter block_size = 128,       // DEFAULT SPECS, = DATA BUS WIDTH OF THE MEMORY SYSTEM
    parameter mem_word_size = 32,     // WORD SIZE OF MEMORY BANKS, DEFAULT SPECS
    parameter proc_word_size = 32,    // WORD SIZE FOR OUR PROCESSOR DATA BUS, DEFAULT SPECS
    parameter blk_0_offset = 127,     // CACHE BLOCK ---> |BLOCK 0 | BLOCK 1 | BLOCK 2| BLOCK 3|
    parameter blk_1_offset = 95,
    parameter blk_2_offset = 63,
    parameter blk_3_offset = 31
)(
    input wire clock,                 // CACHE CLOCK SAME AS PROCESSOR CLOCK      
    input wire refill,                // MISS, REFILL CACHE USING DATA FROM MEMORY
    input wire update,                // HIT, UPDATE CACHE USING DATA FROM PROCESSOR
    input wire [loctn_bits-1:0] index, // INDEX SELECTION
    input wire [offset_bits-1:0] offset, // OFFSET SELECTION
    input wire [block_size-1:0] data_from_mem, // DATA FROM MEMORY
    input wire [proc_word_size-1:0] write_data, // DATA FROM PROCESSOR
    output reg [proc_word_size-1:0] read_data  // DATA TO PROCESSOR
);

    // USER DEFINED DATA TYPE: RAM
    reg [mem_word_size-1:0] cache_memory [(2**(loctn_bits+offset_bits))-1:0]; // Declare cache memory array

    always @(posedge clock) begin
        if (update) begin // HIT, UPDATE CACHE BLOCK USING WORD FROM PROCESSOR
            cache_memory[{index, offset}] <= write_data;
        end else if (refill) begin // MISS, REFILL CACHE BLOCK USING DATA BLOCK FROM MEMORY
            cache_memory[{index, 2'b00}] <= data_from_mem[blk_0_offset:blk_1_offset+1];
            cache_memory[{index, 2'b01}] <= data_from_mem[blk_1_offset:blk_2_offset+1];
            cache_memory[{index, 2'b10}] <= data_from_mem[blk_2_offset:blk_3_offset+1];
            cache_memory[{index, 2'b11}] <= data_from_mem[blk_3_offset:0];
        end
        read_data <= cache_memory[{index, offset}]; // READ WORD FROM CACHE, ALWAYS AVAILABLE
    end

endmodule