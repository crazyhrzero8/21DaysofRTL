`include "Memory_Bank.v"

module Main_Memory_System #(
    parameter bulk_read_size = 128,     // DEFAULT SPECS, DATA WIDTH OF THE MEMORY SYSTEM
    parameter no_of_banks = 4,           // DEFAULT SPECS, NO OF MEMORY BANKS
    parameter bank_sel_bits = 2,         // DEFAULT SPECS, NO. OF BITS TO SELECT BANK
    parameter bank_word_size = 32,       // DEFAULT SPECS FROM MEMORY BANK
    parameter bank_addr_width = 8,       // DEFAULT SPECS FROM MEMORY BANK
    parameter addr_width = 10             // DEFAULT SPECS, LAST TWO BITS SELECT THE BANK
)(
    input wire clock,                     // MEMORY CLOCK 
    input wire reset,                     // ASYNC RESET SIGNAL
    input wire rd,                        // READ SIGNAL 
    input wire wr,                        // WRITE SIGNAL		  
    input wire [addr_width-1:0] addr,    // ADDRESS INPUT
    input wire [bank_word_size-1:0] data_in,    // DATA INPUT FOR WRITE
    output reg [bulk_read_size-1:0] data_out,    // DATA OUT FOR READ
    output reg data_ready                 // TO ACKNOWLEDGE THE END OF DATA PROCESSING
);

    // Internal signals
    wire [bank_word_size-1:0] data_out_0;
    wire [bank_word_size-1:0] data_out_1;
    wire [bank_word_size-1:0] data_out_2;
    wire [bank_word_size-1:0] data_out_3;
    wire data_ready_0;
    wire data_ready_1;
    wire data_ready_2;
    wire data_ready_3;
    reg [no_of_banks-1:0] wr_demux;      // DE-MUX TO SELECT BANK TO WHICH WRITE HAPPENS

    // Memory Bank component declaration
    Memory_Bank Memory_Bank_0 (
        .clock(clock),
        .reset(reset),
        .rd(rd),
        .wr(wr_demux[3]),
        .addr(addr[addr_width-1:bank_sel_bits]), // LAST BITS SELECT BANK
        .data_in(data_in),
        .data_out(data_out_0),
        .data_ready(data_ready_0)
    );

    Memory_Bank Memory_Bank_1 (
        .clock(clock),
        .reset(reset),
        .rd(rd),
        .wr(wr_demux[2]),
        .addr(addr[addr_width-1:bank_sel_bits]),
        .data_in(data_in),
        .data_out(data_out_1),
        .data_ready(data_ready_1)
    );

    Memory_Bank Memory_Bank_2 (
        .clock(clock),
        .reset(reset),
        .rd(rd),
        .wr(wr_demux[1]),
        .addr(addr[addr_width-1:bank_sel_bits]),
        .data_in(data_in),
        .data_out(data_out_2),
        .data_ready(data_ready_2)
    );

    Memory_Bank Memory_Bank_3 (
        .clock(clock),
        .reset(reset),
        .rd(rd),
        .wr(wr_demux[0]),
        .addr(addr[addr_width-1:bank_sel_bits]),
        .data_in(data_in),
        .data_out(data_out_3),
        .data_ready(data_ready_3)
    );

    // Process to de-multiplex the write signal to the corresponding bank
    always @(*) begin
        wr_demux = 4'b0000; // Default to no write
        case (addr[bank_sel_bits-1:0])
            2'b00: wr_demux[3] = wr;
            2'b01: wr_demux[2] = wr;
            2'b10: wr_demux[1] = wr;
            2'b11: wr_demux[0] = wr;
            default: wr_demux = 4'b0000;
        endcase
    end

    // Combine data outputs from memory banks
    always @(*) begin
        data_out = {data_out_3, data_out_2, data_out_1, data_out_0}; // Concatenating outputs
        data_ready = data_ready_0 | data_ready_1 | data_ready_2 | data_ready_3; // Data ready signal
    end

endmodule