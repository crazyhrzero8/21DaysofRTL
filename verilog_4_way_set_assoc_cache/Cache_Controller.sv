module Cache_Controller #(
    parameter INDEX_BITS = 2,            // 4 SETS BY DEFAULT
    parameter SET_OFFSET_BITS = 2,        // 4 ELEMENTS/CACHE LINES PER SET BY DEFAULT
    parameter TAG_BITS = 6                 // DERIVED FROM DEFAULT SPECS OF ADDRESS BUS WIDTH (10 - 2 - 2 = 6)
)(
    input wire clock,                     // MAIN CLOCK
    input wire reset,                     // ASYNC RESET
    input wire flush,                     // TO FLUSH THE CACHE DATA ARRAY, INVALIDATE ALL LINES
    input wire rd,                        // READ REQUEST FROM PROCESSOR
    input wire wr,                        // WRITE REQUEST FROM PROCESSOR
    input wire [INDEX_BITS-1:0] index,   // INDEX OF THE ADDRESS REQUESTED
    input wire [TAG_BITS-1:0] tag,       // TAG OF THE ADDRESS REQUESTED
    input wire ready,                     // DATA READY SIGNAL FROM MEMORY
    output reg [INDEX_BITS + SET_OFFSET_BITS - 1:0] loctn, // LOCATION OF DATA IN CACHE DATA ARRAY
    output reg refill,                    // REFILL SIGNAL TO DATA ARRAY
    output reg update,                    // UPDATE SIGNAL TO DATA ARRAY
    output reg read_from_mem,             // READ SIGNAL TO DATA MEMORY
    output reg write_to_mem,              // WRITE SIGNAL TO DATA MEMORY
    output reg stall                       // SIGNAL TO STALL THE PROCESSOR
);

// Internal signals
reg [7:0] STATE = 8'b00000000;           // STATE SIGNAL
reg HIT = 1'b0;                          // SIGNAL TO INDICATE HIT
reg MISS = 1'b0;                         // SIGNAL TO INDICATE MISS
reg [INDEX_BITS + SET_OFFSET_BITS - 1:0] loctn_loc; // LOCAL FOR loctn

// User-defined types (using arrays)
reg [TAG_BITS:0] tag_array [0:(1 << (INDEX_BITS + SET_OFFSET_BITS)) - 1]; // RAM as TAG ARRAY
reg [1:0] S_ptr [(1 << INDEX_BITS) - 1:0]; // SET POINTER/BASE POINTER FOR EACH SET
reg [1:0] L_ptr [(1 << INDEX_BITS) - 1:0]; // LEFT POINTER FOR EACH SET
reg [1:0] R_ptr [(1 << INDEX_BITS) - 1:0]; // RIGHT POINTER FOR EACH SET

// Additional internal signals for user variables
reg [TAG_BITS:0] temp_tag;                     // Temporary tag variable
integer temp_index;                             // Temporary index variable
integer temp_index_00;                          // Temporary index for 00
integer temp_index_01;                          // Temporary index for 01
integer temp_index_10;                          // Temporary index for 10
integer temp_index_11;                          // Temporary index for 11
reg [INDEX_BITS + SET_OFFSET_BITS - 1:0] index_00; // Index for 00
reg [INDEX_BITS + SET_OFFSET_BITS - 1:0] index_01; // Index for 01
reg [INDEX_BITS + SET_OFFSET_BITS - 1:0] index_10; // Index for 10
reg [INDEX_BITS + SET_OFFSET_BITS - 1:0] index_11; // Index for 11

// Process block
always @(posedge clock or posedge reset) begin
    if (reset) begin
        // RESETTING INTERNAL SIGNALS
        STATE <= 8'b00000000; 
        HIT <= 1'b0;
        MISS <= 1'b0;
        loctn_loc <= {INDEX_BITS + SET_OFFSET_BITS{1'b0}};
        tag_array <= '{default: {TAG_BITS{1'b0}}}; // Reset all entries
        S_ptr <= '{default: 2'b00};                 // Reset all PLRU pointers
        L_ptr <= '{default: 2'b00};
        R_ptr <= '{default: 2'b00};
        
        // RESETTING OUT PORT SIGNALS    
        stall <= 1'b0;
        read_from_mem <= 1'b0;
        write_to_mem <= 1'b0;
        refill <= 1'b0;
        update <= 1'b0;
    end else begin
        if (flush) begin // HIGH PRIORITY SIGNAL TO FLUSH ENTIRE CACHE
            tag_array <= '{default: {TAG_BITS{1'b0}}}; // INVALIDATE ALL CACHE LINES
            S_ptr <= '{default: 2'b00};                 // RESET ALL PLRU POINTERS
            L_ptr <= '{default: 2'b00};
            R_ptr <= '{default: 2'b00};
        end else begin
            case (STATE)
                8'h00: begin // INIT STATE
                    temp_tag <= {1'b1, tag}; // Assuming valid bit is added
                    index_00 <= {index, 2'b00};
                    index_01 <= {index, 2'b01};
                    index_10 <= {index, 2'b10};
                    index_11 <= {index, 2'b11};
                    temp_index <= index;

                    temp_index_00 <= temp_index; // Assuming direct mapping for simplicity
                    temp_index_01 <= temp_index;
                    temp_index_10 <= temp_index;
                    temp_index_11 <= temp_index;

                    // Check for hits
                    if ((temp_tag ^ tag_array[temp_index_00]) == {TAG_BITS{1'b0}}) begin
                        loctn_loc <= index_00; 
                        HIT <= 1'b1;
                        MISS <= 1'b0;
                    end else if ((temp_tag ^ tag_array[temp_index_01]) == {TAG_BITS{1'b0}}) begin
                        loctn_loc <= index_01;
                        HIT <= 1'b1;
                        MISS <= 1'b0;
                    end else if ((temp_tag ^ tag_array[temp_index_10]) == {TAG_BITS{1'b0}}) begin
                        loctn_loc <= index_10;
                        HIT <= 1'b1;
                        MISS <= 1'b0;
                    end else if ((temp_tag ^ tag_array[temp_index_11]) == {TAG_BITS{1'b0}}) begin
                        loctn_loc <= index_11;
                        HIT <= 1'b1;
                        MISS <= 1'b0;
                    end else begin
                        MISS <= 1'b1;
                        HIT <= 1'b0;

                        // Update PLRU pointers
                        if (S_ptr[temp_index] == 2'b00) begin
                            loctn_loc <= {index, S_ptr[temp_index], L_ptr[temp_index]};
                            S_ptr[temp_index] <= 2'b01;
                            L_ptr[temp_index] <= ~L_ptr[temp_index];
                        end else begin
                            loctn_loc <= {index, S_ptr[temp_index], R_ptr[temp_index]};
                            S_ptr[temp_index] <= 2'b00;
                            R_ptr[temp_index] <= ~R_ptr[temp_index];                                     
                        end
                    end

                    // State transition based on read/write requests
                    if (rd || wr) begin
                        STATE <= 8'h01; // To HIT/MISS ANALYSE STATE
                    end else begin
                        STATE <= 8'h00; // Stay in the same state
                        HIT <= 1'b0;
                        MISS <= 1'b0;
                    end
                end

                8'h01: begin // HIT/MISS ANALYSE STATE
                    if (HIT) begin
                        if (wr) begin // WRITE HIT
                            stall <= 1'b1; // STALL BECAUSE OF MAIN MEMORY ACCESS
                            update <= 1'b1; // UPDATES CACHE
                            refill <= 1'b0;   
                            write_to_mem <= 1'b1; // INITIATE WRITE TO MEMORY
                            read_from_mem <= 1'b0;
                            STATE <= 8'h02; // GO TO WRITE HIT STATE
                        end else begin // READ HIT, NOTHING TO DO
                            STATE <= 8'h07; // GO TO GLOBAL WAIT STATE
                        end
                        
                        // Update PLRU pointers
                        S_ptr[temp_index] <= ~loctn_loc[1]; 
                        L_ptr[temp_index] <= (~loctn_loc[1] & ~loctn_loc[0]) | 
                                             (loctn_loc[1] & L_ptr[temp_index]);
                        R_ptr[temp_index] <= (loctn_loc[1] & ~loctn_loc[0]) | 
                                             (~loctn_loc[1] & R_ptr[temp_index]);
                    end else begin // MISS
                        if (rd) begin // READ MISS
                            stall <= 1'b1; // STALL BECAUSE OF MAIN MEMORY ACCESS
                            update <= 1'b0;   
                            refill <= 1'b0;   
                            write_to_mem <= 1'b0;
                            read_from_mem <= 1'b1; // INITIATE READ FROM MEMORY
                            STATE <= 8'h03; // GO TO READ MISS STATE
                        end else begin // WRITE MISS
                            stall <= 1'b1; // STALL BECAUSE OF MAIN MEMORY ACCESS
                            update <= 1'b0; // NO UPDATE ON CACHE
                            refill <= 1'b0;
                            write_to_mem <= 1'b1; // INITIATE WRITE TO MEMORY
                            read_from_mem <= 1'b0;
                            STATE <= 8'h02; // GO TO WRITE MISS STATE
                        end
                    end
                end

                8'h02: begin // WRITE HIT/MISS STATE
                    update <= 1'b0; // STOP UPDATING CACHE
                    refill <= 1'b0;
                    if (ready) begin // IF READY, ACKNOWLEDGE THE MEMORY
                        stall <= 1'b0; // SIGNAL PROCESSOR THAT NEW REQUEST CAN BE INITIATED
                        write_to_mem <= 1'b0; // ACKNOWLEDGING THE MEMORY
                        read_from_mem <= 1'b0;
                        STATE <= 8'h07; // GO TO GLOBAL WAIT STATE
                    end else begin
                        STATE <= 8'h02; // WAIT HERE
                    end
                end

                8'h03: begin // READ MISS STATE
                    if (ready) begin
                        read_from_mem <= 1'b0; // ACKNOWLEDGING MEMORY
                        write_to_mem <= 1'b0;
                        refill <= 1'b1; // INITIATE REFILLING CACHE DATA ARRAY
                        update <= 1'b0;
                        STATE <= 8'h04; // GO TO REFILL/STALL DE-ASSERT STATE
                    end else begin
                        STATE <= 8'h03; // WAIT HERE
                    end
                end

                8'h04: begin // REFILL/STALL DE-ASSERT STATE
                    refill <= 1'b0;
                    update <= 1'b0;
                    tag_array[loctn_loc] <= {1'b1, tag}; // UPDATE TAG ARRAY
                    stall <= 1'b0;
                    STATE <= 8'h07; // GO TO GLOBAL WAIT STATE	
                end

                8'h07: begin // GLOBAL WAIT STATE
                    HIT <= 1'b0;
                    MISS <= 1'b0;
                    stall <= 1'b0;
                    refill <= 1'b0;
                    update <= 1'b0;
                    read_from_mem <= 1'b0;
                    write_to_mem <= 1'b0;

                    // CHECK IF PROCESSOR FINISHED CURRENT REQUEST
                    if (~wr && ~rd) begin  
                        STATE <= 8'h00; // GO TO INIT STATE
                    end else begin
                        STATE <= 8'h07;
                    end		
                end

                default: begin
                    STATE <= 8'h00; // Default case to reset state
                end
            endcase
        end
    end
end

// Assigning local signal to the output port
assign loctn = loctn_loc;

endmodule