`timescale 1ns / 1ps
//definitions for the FSM
typedef enum logic {PrRd = 1'b0, //Processor_Read (input to FSM)
                    PrWr = 1'b1 //Processor_Write (input to FSM)
                    } Pr_Op; //Processor Operations
                       
typedef enum bit[1:0] {Modified = 2'b11, //It's declared as bit, thus un-initialized block will by-default be in Invalid state
                       Exclusive = 2'b10,
                       Shared = 2'b01,
                       Invalid = 2'b00} MESI; //Binary State Encoding
                       
typedef enum logic[2:0]{BusRd = 3'b000, //read request to a Cache block requested by another processor
                       BusRdX = 3'b001, //write request to a Cache block requested by another processor that doesn't already have the block
                       BusUpgr = 3'b010, //write request to a Cache block requested by another processor that already has that cache block residing in its own cache
                       FlushOpt = 3'b011, //An entire cache block is put on the bus
                       Fill = 3'b100, //Shared memory to Cache transfer
                       NotValid = 3'b111
                       } bus_transaction_id; //Possible bus transactions                                         

//The multiprocessor system under consideration, has 4 cores
module MESI_FSM #( //This will be embeded in the cache controller
    //parameter L1_latency = 2,
    //parameter shared_memory_latency = 12,
    parameter Cache_Block_Size = 8, //i.e. 1 Byte
    parameter host_pid = 2'b10 //physical host id or block
	)( //Processor ID
    input logic clk, //clock signal
    input logic resetn, //Negetive Reset or active low
    input Pr_Op Core_Op, //processor operations- core
    output logic PrHlt, //Processor_Halt (output to Processor)
    input logic [3:0] pr_addr, //Processor generated address (4-bits)
    output logic [Cache_Block_Size-1:0] Cache_output, //If Cache_Hit, give the correponding Cache block as output
    input logic [Cache_Block_Size-1:0] Cache_input, //Data to be stored/written in Store instructions
	//addr_bits = 4 bits [2-bit(tag) + 2-bit(index) (Note that it is a Byte addressable cache) 
    //Bus Size = 2-bit(pid) + 3-bit(bus_transaction_id) + 2-bit(tag of transfered data if any) + 2-bit(index of transfered data if any) + Cache_Block_Size (transfered Cache block if any)
    input logic [(2+3+2+2+Cache_Block_Size)-1:0] bus_in, //Input_Bus
    output logic [(2+3+2+2+Cache_Block_Size)-1:0] bus_out, //Input_Bus
    input logic flag_in, //Input flag to indicate the bus is valid
    output logic flag_out //Output flag to validate the bus
    );
    
    //Each processor have its own L1 cache of following dimensions
    logic [Cache_Block_Size-1:0] L1_Cache [0:3]; //L1_cache has a (Cache_Block_Size)-bits Cache block and 4 such blocks
    logic [1:0] tag_directory [0:3]; //There will be 2-bit tag for each Cache Block
    MESI Cache_Status [0:3]; //There will be additional 2-bits for storing status of each block i.e. one of MESI state
    
    //Extracting tag, index, and offset from Processor generated Address (pr_addr)
    //logic offset;
    logic [1:0] index;
    logic [1:0] tag;
    assign tag = pr_addr[3:2];
    assign index = pr_addr[1:0];
    //assign offset = pr_addr[0:0];
    
    //extracting different parts from the shared bus
    logic [1:0] guest_pid; //pid of the processor which has put a request on the bus 
    bus_transaction_id trans_id; //Id of the request on the bus transaction
    logic [1:0] bus_tag; //tag bits of the Cache block transferred on the bus (if any)
    logic [1:0] bus_index; //index bits of the Cache block transferred on the bus (if any)
    logic [Cache_Block_Size-1:0] bus_data; //Cach Block transferred from either mem/Cache (if any)
    
    //It is important to note that, bus_tag and bus_data are transferred only in Case of Flush, FlushOpt,and Fill. In the rest of the cases, only pid, trans_id are of use.
    assign guest_pid = bus_in[(2+3+2+2+Cache_Block_Size)-1:(2+3+2+2+Cache_Block_Size)-2]; //i.e. first 2-bits
    //assign trans_id = bus_transaction_id'(bus[(2+3+2+2+Cache_Block_Size)-3:(2+3+2+2+Cache_Block_Size)-5]); //i.e. the next 3-bits (TypeCasting is NOT Synthesizable)
    assign bus_tag = bus_in[(2+3+2+2+Cache_Block_Size)-6:(2+3+2+2+Cache_Block_Size)-7]; //i.e. the next 2-bits
    assign bus_index = bus_in[(2+3+2+2+Cache_Block_Size)-8:(2+3+2+2+Cache_Block_Size)-9]; //i.e. the next 2-bits
    assign bus_data = bus_in[Cache_Block_Size-1:0]; //i.e. the rest of the Cache_Block_Size
    
    always_comb begin
        case (bus_in[(2+3+2+2+Cache_Block_Size)-3:(2+3+2+2+Cache_Block_Size)-5])
            3'b000: trans_id = BusRd;
            3'b001: trans_id = BusRdX;
            3'b010: trans_id = BusUpgr;
            3'b011: trans_id = FlushOpt;
            3'b100: trans_id = Fill;
            default: trans_id = NotValid; //Indicating InValid Transaction
        endcase
    end
    
    //MESI [1:0] y, Y; //State variables: present and Next states variables respectively 
    
    //As this is a Bus-Shared snooping protocol, only one of the 4 processors will have acces to the Bus at a time
    bit [1:0] bus_access_counter;
    bit [3:0] invalid_state_counter;
    
    //Helper Function to identify Cache Hit/Miss
    function logic is_hit(input logic [1:0] _tag_, input logic [1:0] _index_);
        return((Cache_Status[_index_] != Invalid) && (tag_directory[index] == _tag_));
    endfunction
    
    //Next State and Output combinatory logic 
    always_ff@(posedge clk)
        begin 
            if(!resetn) begin //Active low reset
                Cache_Status[0] = Invalid; Cache_Status[1] = Invalid; Cache_Status[2] = Invalid; Cache_Status[3] = Invalid; //At Reset invalidate all the Cache_Statuses
                bus_access_counter = 2'b00; //i.e. at reset Processo 0 will have access to the bus
                invalid_state_counter = 3'b00; //i.e., at reset counter is initiated to 0
                flag_out = 1'b0; 
                PrHlt = 1'b0;
            end
            else begin
                bus_access_counter = bus_access_counter + 1; //i.e., Bus access will be updated every ClK cycle.
                //#0.2 flag_out = 1'b0; //This is What we want, So this is how we'll create it as timing control is NOT allowed inside always_ff
                //flag_out = (^bus_access_counter)? 1'b0 : flag_out;
                //$display("[time = %d] host_pid = %d, bus_tag = %d, bus_index = %d, flag_in = %d, Core_Op = %d, is_hit = %d",$time,host_pid,bus_tag,bus_index,flag_in,Core_Op,is_hit(bus_tag, bus_index));
                //%%%%%%%%%%%% Bus Requests %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if((guest_pid != host_pid) && is_hit(bus_tag, bus_index) && (flag_in)) begin //Check if the Bus request is Not generated by the local processor itself! and if the local processor has the Cache block concerned in the bus request
                    case(Cache_Status[bus_index])
                        Modified: begin 
                            case(trans_id)
                                BusRd: begin 
                                    //It will first downgrade the status to "Shared"   
                                    Cache_Status[bus_index] = Shared;
                                    //Then, it will transferred the copy of that block to that processor, as it's the only modified copy available
                                    bus_out = {host_pid, FlushOpt, bus_tag, bus_index, L1_Cache[bus_index]};
                                    flag_out = 1'b1; 
                                end
                                BusRdX: begin 
                                    //It will first downgrade the status to "Invalid"   
                                    Cache_Status[bus_index] = Invalid;
                                    //Then, it will transferred the copy of that block to that processor, as it's the only modified copy available
                                    bus_out = {host_pid, FlushOpt, bus_tag, bus_index, L1_Cache[bus_index]};
                                    flag_out = 1'b1;
                                end 
                            endcase
                        end
                        Exclusive: begin 
                            case(trans_id)
                                BusRd: begin 
                                    //It will downgrade the status to "Shared"   
                                    Cache_Status[bus_index] = Shared;
                                end
                                BusRdX: begin 
                                    //It will downgrade the status to "Invalid"   
                                    Cache_Status[bus_index] = Invalid;
                                end 
                            endcase
                        end
                        Shared: begin 
                            case(trans_id)
                                BusRd: begin end //Do Nothing!
                                BusRdX: begin 
                                    //It will downgrade the status to "Invalid"   
                                    Cache_Status[bus_index] = Invalid;
                                end
                                BusUpgr: begin 
                                    //It will downgrade the status to "Invalid"   
                                    Cache_Status[bus_index] = Invalid;
                                end  
                            endcase    
                        end
                        Invalid: begin
                            if(PrHlt == 1'b1) begin //i.e. If Processor is in Halt, due to earlier PrRd/PrWr request on the Invalid Cache Block
                                case(trans_id) 
                                    FlushOpt: begin //Some other Processor has that Cache block in Modified state, it has put that in the Bus
                                        PrHlt = 1'b0; //Remove the Halt   
                                        case(Core_Op)
                                            PrRd: begin 
                                                L1_Cache[bus_index] = bus_data;  
                                                Cache_output = L1_Cache[bus_index];
                                                Cache_Status[index] = Shared; //Change status from Invalid to Shared(S)
                                            end
                                            PrWr: begin 
                                                L1_Cache[bus_index] = Cache_input; 
                                                tag_directory[index] = bus_tag;
                                                Cache_Status[index] = Modified; //Change status from Invalid to Modified(M)
                                            end
                                        endcase
                                        
                                    end
                                endcase
                            end     
                        end
                    endcase
                end
                //Cache Replacement 
                else if((guest_pid != host_pid) && (!is_hit(bus_tag, bus_index)) && (flag_in)) begin 
                    if(PrHlt == 1'b1) begin //i.e. If Processor is in Halt, due to earlier PrRd/PrWr request on the Invalid Cache Block
                                //$display("bus_tag = %d, bus_index = %d, flag_in = %d, Core_Op = %d",bus_tag,bus_index,flag_in,Core_Op);
                                case(trans_id) 
                                    FlushOpt: begin //Some other Processor has that Cache block in Modified state, it has put that in the Bus
                                        PrHlt = 1'b0; //Remove the Halt   
                                        case(Core_Op)
                                            PrRd: begin 
                                                L1_Cache[bus_index] = bus_data;  
                                                tag_directory[index] = bus_tag;
                                                Cache_output = L1_Cache[bus_index];
                                                Cache_Status[index] = Shared; //Change status from Invalid to Shared(S)
                                            end
                                            PrWr: begin 
                                                L1_Cache[bus_index] = Cache_input; 
                                                tag_directory[index] = bus_tag;
                                                Cache_Status[index] = Modified; //Change status from Invalid to Modified(M)
                                            end
                                        endcase
                                        
                                    end
                                     
                                endcase
                            end     
                end
                //------------- Processor Requests -----------------------------------------
                if(is_hit(tag, index)) begin //Check if Cache Hit
                    case(Cache_Status[index])
                        Modified: begin
                                case(Core_Op)
                                PrRd: begin
                                        Cache_output = L1_Cache[index];  //Read to the block is a Cache Hit 
                                    end   
                                PrWr: begin 
                                    L1_Cache[index] = Cache_input; //Write to the block is a Cache Hit
                                    tag_directory[index] = tag;
                                end   
                        endcase
                        //if(bus_access_counter == host_pid) begin //First Check if the processor has access to the Bus
                        end
                            
                        Exclusive: begin
                                case(Core_Op)
                                PrRd: begin
                                        Cache_output = L1_Cache[index];  //Read to the block is a Cache Hit 
                                    end   
                                PrWr: begin 
                                    L1_Cache[index] = Cache_input; //Write to the block is a Cache Hit
                                    tag_directory[index] = tag;
                                    Cache_Status[index] = Modified; //State transition from Exclusive to (M)Modified
                                end   
                                endcase
                                
                               //if(bus_access_counter == host_pid) begin //First Check if the processor has access to the Bus
                        end
                        
                        Shared: begin
                                case(Core_Op)
                                PrRd: begin
                                        Cache_output = L1_Cache[index];  //Read to the block is a Cache Hit 
                                    end   
                                PrWr: begin 
                                    bus_out = {host_pid, BusUpgr, tag, index, 8'bx}; //Issues BusUpgr signal on the bus.
                                    flag_out = 1'b1;
                                    L1_Cache[index] = Cache_input; //Write to the block is a Cache Hit
                                    tag_directory[index] = tag;
                                    Cache_Status[index] = Modified; //State transition to (M)Modified.
                                end   
                                endcase
                                
                               //if(bus_access_counter == host_pid) begin //First Check if the processor has access to the Bus
                        end
                        
                        Invalid: begin
                                case(Core_Op)
                                PrRd: begin
                                        bus_out = {host_pid, BusRd, tag, index, 8'bx}; //Issue BusRd to the bus
                                        flag_out = 1'b1;
                                        PrHlt = 1'b1; //I.e. Halt the Processor, untill data is received
                                        if(invalid_state_counter == 3'b010) begin //After waiting for 2 cycles, i.e. No. of processors
                                            //Then, it will request the data from the Shared_Memory
                                            bus_out = {host_pid, Fill, tag, index, 8'b11111111}; //Cache_Block_Size = 8
                                            flag_out = 1'b1;
                                            L1_Cache[index] = 8'b11111111;
                                            tag_directory[index] = tag;
                                            Cache_output = L1_Cache[index];  //Read to the block is a Cache Hit    
                                            Cache_Status[index] = Exclusive; //Change status from Invalid to Exclusive(E)
                                            PrHlt = 1'b0; //Remove the Halt 
                                            invalid_state_counter = 0;         
                                        end
                                        else
                                            invalid_state_counter = invalid_state_counter + 1;
    
                                    end   
                                    PrWr: begin 
                                        bus_out = {host_pid, BusRdX, tag, index, 8'bx}; //Issue BusRdX signal on the bus
                                        flag_out = 1'b1;
                                        PrHlt = 1'b1; //I.e. Halt the Processor, untill data is received
                                        //Wait for 4 cycles, if Data is NOT received via FlashOpt (i.e. from any other processor), Memory will fetch the data and put on the bus via issuing Fill request
                                        if(invalid_state_counter == 3'b010) begin //After waiting for 4 cycles
                                            //Then, it will request the data from the Shared_Memory
                                            bus_out = {host_pid, Fill, tag, index, 8'b11111111}; //Cache_Block_Size = 8
                                            flag_out = 1'b1;
                                            L1_Cache[index] = 8'b11111111;  
                                            tag_directory[index] = tag;
                                            L1_Cache[index] = Cache_input;  //Read to the block is a Cache Hit  
                                            tag_directory[index] = tag;  
                                            Cache_Status[index] = Modified; //Change status from Invalid to Shared(S)
                                            PrHlt = 1'b0; //Remove the Halt 
                                            invalid_state_counter = 0;         
                                        end
                                        else
                                            invalid_state_counter = invalid_state_counter + 1;
    
                                    end   
                                endcase    
                        end
                        
                        default: begin 
                            //Y <= 2'bxx; Z <= Z; 
                                 end      
                    endcase
                end
                else begin//If Cache Miss
                    case(Core_Op)
                        PrRd: begin
                                bus_out = {host_pid, BusRd, tag, index, 8'bx}; //Issue BusRd to the bus
                                flag_out = 1'b1;
                                PrHlt = 1'b1; //I.e. Halt the Processor, untill data is received
                                if(invalid_state_counter == 3'b010) begin //After waiting for 2 cycles, i.e. No. of processors
                                    //Then, it will request the data from the Shared_Memory
                                    bus_out = {host_pid, Fill, tag, index, 8'b11111111}; //Cache_Block_Size = 8
                                    flag_out = 1'b1;
                                    L1_Cache[index] = 8'b11111111;
                                    tag_directory[index] = tag;
                                    Cache_output = L1_Cache[index];  //Read to the block is a Cache Hit    
                                    Cache_Status[index] = (tag == bus_tag && index == bus_index)? Shared : Exclusive; //Change status from Invalid to Exclusive(E) only if other Core does NOT have the copy otherwise, change it to Shared
                                    PrHlt = 1'b0; //Remove the Halt 
                                    invalid_state_counter = 0;         
                                end
                                else
                                    invalid_state_counter = invalid_state_counter + 1;
    
                            end   
                            PrWr: begin 
                                bus_out = {host_pid, BusRdX, tag, index, 8'bx}; //Issue BusRdX signal on the bus
                                flag_out = 1'b1;
                                PrHlt = 1'b1; //I.e. Halt the Processor, untill data is received
                                //Wait for 4 cycles, if Data is NOT received via FlashOpt (i.e. from any other processor), Memory will fetch the data and put on the bus via issuing Fill request
                                if(invalid_state_counter == 3'b010) begin //After waiting for 4 cycles
                                    //Then, it will request the data from the Shared_Memory
                                    bus_out = {host_pid, Fill, tag, index, 8'b11111111}; //Cache_Block_Size = 8
                                    flag_out = 1'b1;
                                    L1_Cache[index] = 8'b11111111;  
                                    tag_directory[index] = tag;
                                    L1_Cache[index] = Cache_input;  //Read to the block is a Cache Hit  
                                    tag_directory[index] = tag;  
                                    Cache_Status[index] = Modified; //Change status from Invalid to Shared(S)
                                    PrHlt = 1'b0; //Remove the Halt 
                                    invalid_state_counter = 0;         
                                end
                                else
                                    invalid_state_counter = invalid_state_counter + 1;
    
                            end   
                    endcase
//                    //Then, it will request the data from the Shared_Memory
//                    bus_out = {host_pid, Fill, tag, index, 8'b11111111}; //Cache_Block_Size = 8
//                    L1_Cache[index] = 8'b11111111;
//                    tag_directory[index] = tag;     
//                    Cache_Status[index] = Exclusive ;
                end 
		flag_out = 1'b0;
            end
        end
        
endmodule
