module Memory_Bank #(
    parameter word_size = 32,        // DEFAULT SPECS
    parameter addr_width = 8         // DEFAULT SPECS
)(
    input wire clock,                // MEMORY CLOCK      
    input wire reset,                // ASYNC RESET SIGNAL    
    input wire rd,                   // READ SIGNAL 
    input wire wr,                   // WRITE SIGNAL		  
    input wire [addr_width-1:0] addr, // ADDRESS INPUT
    input wire [word_size-1:0] data_in, // DATA INPUT FOR WRITE
    output reg [word_size-1:0] data_out, // DATA OUT FOR READ
    output reg data_ready            // TO ACKNOWLEDGE THE END OF DATA PROCESSING
);

    // USER DEFINED DATA TYPE: RAM
    reg [word_size-1:0] data_memory [0:(2**addr_width)-1]; // Declare memory array

    // FUNCTION TO FILL MEMORY WITH DEFAULT VALUES 0 TO 255 FOR LOCATIONS 0 TO 255
    integer i;
    initial begin
        for (i = 0; i < 2**addr_width; i = i + 1) begin
            data_memory[i] = i; // Initialize memory with values 0 to 255
        end
    end

    // Memory access process
    always @(posedge clock) begin
        if (wr) begin
            data_memory[addr] <= data_in;  // SYNCHRONOUS WRITE
            data_out <= data_memory[addr];  // SYNCHRONOUS READ
        end else if (rd) begin
            data_out <= data_memory[addr];  // SYNCHRONOUS READ
        end else begin
            data_out <= data_memory[addr];  // SYNCHRONOUS READ
        end
    end

    // Data ready process
    always @(posedge clock or negedge reset) begin
        if (!reset) begin // ACTIVE LOW ASYNC RESET
            data_ready <= 0;
        end else begin
            if (wr || rd) begin
                data_ready <= 1; // DATA IS WRITTEN OR CAN BE READ, ACKNOWLEDGE THE PROCESSOR
            end else begin
                data_ready <= 0;
            end
        end
    end

endmodule