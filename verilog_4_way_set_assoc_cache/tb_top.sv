`timescale 1ns / 1ps

module tb_top;

// Parameters
localparam no_of_banks = 4;
localparam bank_sel_bits = 2;
localparam bank_addr_width = 8;
localparam mem_word_size = 32;
localparam proc_word_size = 32;
localparam blk_0_offset = 127;
localparam blk_1_offset = 95;
localparam blk_2_offset = 63;
localparam blk_3_offset = 31;
localparam data_bus_width = 32;
localparam addr_bus_width = 32;
localparam INDEX_BITS = 2;
localparam TAG_BITS = 6;
localparam SET_OFFSET_BITS = 2;
localparam loctn_bits = 4;
localparam offset_bits = 2;
localparam block_size = 128;
localparam bulk_read_size = 128;
localparam bank_word_size = 32;
localparam addr_width = 10;

// Testbench signals
reg clock;
reg reset;
reg [addr_bus_width-1:0] addr;
reg [data_bus_width-1:0] wdata;
reg flush;
reg rd;
reg wr;
wire [data_bus_width-1:0] rdata;
wire stall;

// Instantiate the Top module
top #(
    .no_of_banks(no_of_banks),
    .bank_sel_bits(bank_sel_bits),
    .bank_addr_width(bank_addr_width),
    .mem_word_size(mem_word_size),
    .proc_word_size(proc_word_size),
    .blk_0_offset(blk_0_offset),
    .blk_1_offset(blk_1_offset),
    .blk_2_offset(blk_2_offset),
    .blk_3_offset(blk_3_offset),
    .data_bus_width(data_bus_width),
    .addr_bus_width(addr_bus_width),
    .INDEX_BITS(INDEX_BITS),
    .TAG_BITS(TAG_BITS),
    .SET_OFFSET_BITS(SET_OFFSET_BITS),
    .loctn_bits(loctn_bits),
    .offset_bits(offset_bits),
    .block_size(block_size),
    .bulk_read_size(bulk_read_size),
    .bank_word_size(bank_word_size),
    .addr_width(addr_width)
) uut (
    .clock(clock),
    .reset(reset),
    .addr(addr),
    .rdata(rdata),
    .wdata(wdata),
    .flush(flush),
    .rd(rd),
    .wr(wr),
    .stall(stall)
);

// Clock generation
always begin
    #5 clock = ~clock; // Toggle clock every 5 ns
end

// Test procedure
initial begin
    // Initialize signals
    clock = 0;
    reset = 1;
    flush = 0;
    rd = 0;
    wr = 0;
    addr = 0;
    wdata = 0;

    // Reset the system
    #10 reset = 0;

    // Test 1: Write to cache
    addr = 32'h00000000; // Address to write
    wdata = 32'hDEADBEEF; // Data to write
    wr = 1; // Set write signal
    #10; // Wait for a clock cycle
    wr = 0; // Clear write signal
    #10; // Wait to ensure the write completes

    // Test 2: Read from cache
    addr = 32'h00000000; // Address to read
    rd = 1; // Set read signal
    $display("Read Data at rd=1: %h", rdata); // Display read data
    #10; // Wait for a clock cycle
    rd = 0; // Clear read signal
    #10; // Wait to ensure the read completes
    $display("Read Data: %h", rdata); // Display read data

    // Test 3: Write to another address
    addr = 32'h00000004; // Address to write
    wdata = 32'hBAADF00D; // Data to write
    wr = 1; // Set write signal
    #10; // Wait for a clock cycle
    wr = 0; // Clear write signal
    #10; // Wait to ensure the write completes

    // Test 4: Read from the second address
    addr = 32'h00000004; // Address to read
    rd = 1; // Set read signal
    #10; // Wait for a clock cycle
    rd = 0; // Clear read signal
    #10; // Wait to ensure the read completes
    $display("Read Data: %h", rdata); // Display read data

    // Test 5: Flush cache
    flush = 1; // Set flush signal
    #10; // Wait for a clock cycle
    flush = 0; // Clear flush signal

    // Test 6: Read after flush
    addr = 32'h00000000; // Address to read
    rd = 1; // Set read signal
    #10; // Wait for a clock cycle
    rd = 0; // Clear read signal
    #10; // Wait to ensure the read completes
    $display("Read Data after flush: %h", rdata); // Display read data

    // Finish simulation
    #10;
    $finish;
end
  
  initial begin
    $monitor("time %0t clk %0d reset %0d flush %0d rd %0h wr %0h addr %0h wdata %0h rdata %0h stall %0h",$time, clock, reset, flush, rd, wr, addr, wdata, rdata,stall);
  end
  
  initial begin
    $dumpfile("cache.vcd");
    $dumpvars;
  end

endmodule