//Here, 2 cores have been considered and hence 2 L1 Caches have defined

// one thing to notice is it doesnt have any type of output!
module MESI_protocol(
    clk,
	Pr_Rd_1,
	Bus_Rd_C_1,
	Bus_Rd_IC_1,
	Pr_Wr_1,
	Bus_RdX_1,
	Bus_Upgr_1,
	Flush_1,
	Flush_Opt_1,
	Cache1_pointer,
	Cache2_pointer,
	effective_address_1,
	Pr_Rd_2,
	Bus_Rd_C_2,
	Bus_Rd_IC_2,
	Pr_Wr_2,
	Bus_RdX_2,
	Bus_Upgr_2,
	Flush_2,
	Flush_Opt_2,
	effective_address_2
);   

input clk;  //Clock signal

//Control Signals
input Pr_Rd_1;    //When processor wants to read data
input Bus_Rd_C_1;  //When one Cache wants to read data from another cache
input Bus_Rd_IC_1;  //When processor reads a data that is exclusive to itself--- "E" state
input Pr_Wr_1;    //processor wants to write something onto its' Cache
input Bus_RdX_1;  //When there's a write miss and processor has to fetch the cache address first before writing onto it
input Bus_Upgr_1;  //used to make the other Caches containing the same address "Invalid" while data is being written down by one processor onto its Cache
input Flush_1;     //used to perform Write-Back to the main memory
input Flush_Opt_1;     //I believe Flush and Flush_Opt are the same
input [31:0] effective_address_1; //Effective Address that has been calculated by the Processor 

input Pr_Rd_2;    //When processor wants to read data
input Bus_Rd_C_2;  //When one Cache wants to read data from aother cache
input Bus_Rd_IC_2;  //When processor reads a data that is exclusive to itself--- "E" state
input Pr_Wr_2;    //processor wants to write something onto its' Cache
input Bus_RdX_2;  //When there's a write miss and processor has to fetch the cache address first before writing onto it
input Bus_Upgr_2;  //used to make the other Caches containing the same address "Invalid" while data is being written down by one processor onto its Cache
input Flush_2;     //used to perform Write-Back to the main memory
input Flush_Opt_2;     //I believe Flush and Flush_Opt are the same
input [31:0] effective_address_2; //Effective Address that has been calculated by the Processor 

input [1:0] Cache1_pointer;          //to point to the row of Cache that will be opearted upon
input [1:0] Cache2_pointer;          //to keep count as to how many rows are filled

//Memory resources
reg [31:0] Memory_data [1:32];     //Data stored in Main Memory

reg [31:0] Cache1_data [0:3];      //Data stored in Cache of Processor 1
reg [31:0] Cache1_addr [0:3];      //Address stored in Cache of Processor 1
reg [1:0] Cache1_state [0:3];      //State of the Cache (for a particular address) of Processor 1

reg [31:0] Cache2_data [0:3];      //Data stored in Cache of Processor 2
reg [31:0] Cache2_addr [0:3];      //Address stored in Cache of Processor 2
reg [1:0] Cache2_state [0:3];      //State of the Cache (for a particular address) of Processor 2


//Pipelined Registers for LOAD/STORE Opeartions
reg [31:0] LD1_data;       //Data from Main Memory or Cache is loaded onto this pipelined register (when processor 1 is active) from which it's written back 
reg [31:0] ST1_data;       //Data from this pipelined register (when processor 1 is active) is stored in the Cache with the same efective address 
reg [31:0] LD2_data;       //Data from Main Memory or Cache is loaded onto this pipelined register (when processor 2 is active) from which it's written back 
reg [31:0] ST2_data;       //Data from this pipelined register (when processor 2 is active) is stored in the Cache with the same effective address 


initial 
begin
    Cache1_state[0]=2'b00; Cache1_state[1]=2'b00;  Cache1_state[2]=2'b00;  Cache1_state[3]=2'b00;  
    Cache2_state[0]=2'b00; Cache2_state[1]=2'b00;  Cache2_state[2]=2'b00;  Cache2_state[3]=2'b00; 
    //Pr_Rd=0; Bus_Rd_C=0; Bus_Rd_IC=0; Pr_Wr=0; Bus_RdX=0; Bus_Upgr=0; Flush=0; Flush_Opt=0; 
    ST1_data=15; ST2_data=10;
    //Cache1_pointer=0; Cache2_pointer=0;  
    //effective_address=5;
    Memory_data[5]=8;
end

 //Assuming Processor 1 is the working processor and Processor 2 is the non-working processor
 //***Also, indeces of Cache1_data, Cache1_addr, etc. ate left blank because the address or index will be 
 //***obtained from the Tomasulo when we integrate it with this MESI protocol

always@(posedge clk)
begin
   case(Cache1_state[Cache1_pointer])                       //State Machine for current working processor (assuming working processor is Processor 1)
       2'b00: begin                           //Cache is in the "I" state
                 if(Pr_Rd_1==1 && Bus_Rd_IC_1==1) //If effective address is not found in the Caches of both the processors, then it must be in Memory
                    begin
                       Cache1_data[Cache1_pointer]=Memory_data[effective_address_1];  //Fetch data from Memory and store it in the Cache of working processor
                       Cache1_addr[Cache1_pointer]=effective_address_1;  //Fetch address from Memory and store it in the Cache of working processor
                       LD1_data=Memory_data[effective_address_1];       //Fetch data from Memory and send it to the working processor
                       Cache1_state[Cache1_pointer]=2'b01;         //Change state from "I" to "E"
                    end   
                 else if(Pr_Rd_1==1 && Bus_Rd_C_1==1)    //If effective address is found in the Cache of the other processor and is not in "I" state
                    begin
                       LD1_data=Cache2_data[Cache2_pointer];       //Fetch data from that cache to the current working processor
                       Cache1_data[Cache1_pointer]= Cache2_data[Cache2_pointer]; //Fetch data from that Cache to the Cache of the current working processor
                       Cache1_addr[Cache1_pointer]= effective_address_1;  //Fetch address from that Cache to the Cache of the current working processor
                       Cache1_state[Cache1_pointer]=2'b10;         //Change state from "I" to "S
                    end 
                 else if(Pr_Wr_1==1 && Bus_RdX_1==1)     //If processor wants to write into the Cache but there's a Cache miss
                    begin
                       Cache1_data[Cache1_pointer]=ST1_data;       //Store data into Cache
                       Cache1_addr[Cache1_pointer]=effective_address_1;  //Store effective address into the Cache
                       Cache1_state[Cache1_pointer]=2'b11;              //Change state from "I" to "M"
                    end      
              end 
       2'b01: begin                                //Cache is in state "E"
                 if(Pr_Rd_1==1)             //If the current working processor just wants to read the data that is already present in its Cache 
                    begin
                       LD1_data=Cache1_data[Cache1_pointer];  //Fetch the required data from Cache
                       Cache1_state[Cache1_pointer]=2'b01;    //Cache remains in the same "E" state
                    end
                 else if(Pr_Wr_1==1)             //If the current working processor wants to write something onto its' Cache 
                    begin
                       Cache1_data[Cache1_pointer]=ST1_data;  //Store data from processor onto the Cache
                       Cache1_state[Cache1_pointer]=2'b11;    //Change state from "E" to "M"
                    end
              end 
       2'b10: begin                           //Cache is in state "S"
                 if(Pr_Rd_1==1)           //If the current working processor just wants to read the data that is already present in its Cache 
                    begin
                       LD1_data=Cache1_data[Cache1_pointer];  //Fetch the required data from Cache
                       Cache1_state[Cache1_pointer]=2'b10;    //Cache remains in the same "S" state
                    end 
                 else if(Pr_Wr_1==1 && Bus_Upgr_1==1)  //If the current working processor wants to write something onto its' Cache
                    begin
                       Cache1_data[Cache1_pointer]=ST1_data;   //Store data from processor onto the Cache
                       Cache1_state[Cache1_pointer]=2'b11;     //Change state from "S" to "M"
                    end   
              end  
       2'b11: begin                       //Cache is in state "M"
                 if(Pr_Rd_1==1)             //If the current working processor just wants to read the data that has just been written onto its' Cache
                    begin
                       LD1_data=Cache1_data[Cache1_pointer];    //Fetch the required data from Cache
                       Cache1_state[Cache1_pointer]=2'b11;      //Cache remains in the same "M" state
                    end
                 else if(Pr_Wr_1==1)         //If the current working processor wants to write something onto its' Cache
                    begin
                       Cache1_data[Cache1_pointer]=ST1_data;    //Store data from processor onto the Cache
                       Cache1_state[Cache1_pointer]=2'b11;       //Cache remains in the same "M" state
                    end   
              end                  
   endcase

   case(Cache2_state[Cache2_pointer])           //State Machine for the other Processor
       2'b00: begin               //Cache of the other processor is in the "I" state
                 if(Bus_Rd_IC_1==1)     //If the effective address is not found in both the Caches and data has to be fetched from Memory
                   Cache2_state[Cache2_pointer]=2'b00;  //Cache remains in same "I" state
                 else if(Bus_RdX_1==1)   //If there's a Write miss for working processor
                   Cache2_state[Cache2_pointer]=2'b00;  //Cache remains in same "I" state
                 else if(Bus_Upgr_1==1)   //If there's something being written by the working processor
                   Cache2_state[Cache2_pointer]=2'b00;   //Cache remains in the same "I" state 
              end
       2'b01: begin              //Cache of the other processor is in the "E"
                 if(Bus_RdX_1==1 && Flush_Opt_1==1)  //If there's a write miss for the current working processor, data of the other processor has
                    begin                       // to be written back to the Main Memory before the working processor writes new data onto its' Cache
                       Memory_data[effective_address_1]=Cache2_data[Cache2_pointer];  //Data present in the other processor's cache is being written back
                       Cache2_state[Cache2_pointer]=2'b00;          //And state changes from "E" to "I" as working processor is doing "Write" operation
                    end 
                 else if(Bus_Rd_C_1==1 && Flush_Opt_1==1)  //Cache of working processor fetches data from the cahe of other processor
                    begin
                       Cache1_data[Cache1_pointer]=Cache2_data[Cache2_pointer];  //Fetch data from the other Cache
                       Memory_data[effective_address_1]=Cache2_data[Cache2_pointer];  //Write back to Memory as well
                       Cache2_state[Cache2_pointer]=2'b10;       //Change state from "E" to "S"
                    end   
              end  
       2'b10: begin                      //Cache of the other processor is in the "S" state
                 if(Bus_Rd_C_1==1 && Flush_Opt_1==1)  //Cache of working processor fetches data from the cahe of other processor
                    begin
                       Memory_data[effective_address_1]=Cache2_data[Cache2_pointer]; //Write back takes place
                       Cache2_state[Cache2_pointer]=2'b10;     //Cache remains in the "S" state
                    end
                 else if(Bus_RdX_1==1 && Flush_Opt_1==1)  //write miss encountered by the working processor in its' own Cache
                    begin
                       Memory_data[effective_address_1]=Cache2_data[Cache2_pointer];  //write back before going into "I" state
                       Cache2_state[Cache2_pointer]=2'b00;     //state changes to "I" state
                    end   
                 else if(Bus_Upgr_1==1)     //Working processor wants to write onto its' cache and wants to inavlid other Caches containing same address
                    begin
                       Memory_data[effective_address_1]=Cache2_data[Cache2_pointer];  //Write back happens before going into "I" state
                       Cache2_state[Cache2_pointer]=2'b00;   //Cache of othe rprocessor goes into the "I" state
                    end   
              end    
       2'b11: begin                   //Cache of other processor is in the "M" state
                 if(Bus_Rd_C_1==1 && Flush_1==1)   //working processor now wants to read the data that had been written just now by other processor to its' own cache
                    begin
                       Memory_data[effective_address_1]=Cache2_data[Cache2_pointer]; //wite back to the memory before going into "S" state
                       Cache2_state[Cache2_pointer]=2'b10;   //change of the state of the other cache to "S" cache
                    end
                 else if(Bus_RdX_1==1 && Flush_1==1)  //write miss encountered by the working processor
                    begin
                       Memory_data[effective_address_1]=Cache2_data[Cache2_pointer];  //write back needs to happen before it goes into the "I" state 
                       Cache2_state[Cache2_pointer]=2'b00;   //cache goes into the "I" state
                    end    
              end               
   endcase
   //Pr_Rd<=0; Bus_Rd_C<=0; Bus_Rd_IC<=0; Pr_Wr<=0; Bus_RdX<=0; Bus_Upgr<=0; Flush<=0; Flush_Opt<=0; 

 case(Cache2_state[Cache2_pointer])                       //State Machine for current working processor (assuming working processor is Processor 1)
       2'b00: begin                           //Cache is in the "I" state
                 if(Pr_Rd_2==1 && Bus_Rd_IC_2==1) //If effective address is not found in the Caches of both the processors, then it must be in Memory
                    begin
                       Cache2_data[Cache2_pointer]=Memory_data[effective_address_2];  //Fetch data from Memory and store it in the Cache of working processor
                       Cache2_addr[Cache2_pointer]=effective_address_2;  //Fetch address from Memory and store it in the Cache of working processor
                       LD2_data=Memory_data[effective_address_2];       //Fetch data from Memory and send it to the working processor
                       Cache2_state[Cache2_pointer]=2'b01;         //Change state from "I" to "E"
                    end   
                 else if(Pr_Rd_2==1 && Bus_Rd_C_2==1)    //If effective address is found in the Cache of the other processor and is not in "I" state
                    begin
                       LD2_data=Cache1_data[Cache1_pointer];       //Fetch data from that cache to the current working processor
                       Cache2_data[Cache2_pointer]= Cache1_data[Cache1_pointer]; //Fetch data from that Cache to the Cache of the current working processor
                       Cache2_addr[Cache2_pointer]= effective_address_2;  //Fetch address from that Cache to the Cache of the current working processor
                       Cache2_state[Cache2_pointer]=2'b10;         //Change state from "I" to "S
                    end 
                 else if(Pr_Wr_2==1 && Bus_RdX_2==1)     //If processor wants to write into the Cache but there's a Cache miss
                    begin
                       Cache2_data[Cache2_pointer]=ST2_data;       //Store data into Cache
                       Cache2_addr[Cache2_pointer]=effective_address_2;  //Store effective address into the Cache
                       Cache2_state[Cache2_pointer]=2'b11;              //Change state from "I" to "M"
                    end      
              end 
       2'b01: begin                                //Cache is in state "E"
                 if(Pr_Rd_2==1)             //If the current working processor just wants to read the data that is already present in its Cache 
                    begin
                       LD2_data=Cache2_data[Cache2_pointer];  //Fetch the required data from Cache
                       Cache2_state[Cache2_pointer]=2'b01;    //Cache remains in the same "E" state
                    end
                 else if(Pr_Wr_2==1)             //If the current working processor wants to write something onto its' Cache 
                    begin
                       Cache2_data[Cache2_pointer]=ST2_data;  //Store data from processor onto the Cache
                       Cache2_state[Cache2_pointer]=2'b11;    //Change state from "E" to "M"
                    end
              end 
       2'b10: begin                           //Cache is in state "S"
                 if(Pr_Rd_2==1)           //If the current working processor just wants to read the data that is already present in its Cache 
                    begin
                       LD2_data=Cache2_data[Cache2_pointer];  //Fetch the required data from Cache
                       Cache2_state[Cache2_pointer]=2'b10;    //Cache remains in the same "S" state
                    end 
                 else if(Pr_Wr_2==1 && Bus_Upgr_2==1)  //If the current working processor wants to write something onto its' Cache
                    begin
                       Cache2_data[Cache2_pointer]=ST2_data;   //Store data from processor onto the Cache
                       Cache2_state[Cache2_pointer]=2'b11;     //Change state from "S" to "M"
                    end   
              end  
       2'b11: begin                       //Cache is in state "M"
                 if(Pr_Rd_2==1)             //If the current working processor just wants to read the data that has just been written onto its' Cache
                    begin
                       LD2_data=Cache2_data[Cache2_pointer];    //Fetch the required data from Cache
                       Cache2_state[Cache2_pointer]=2'b11;      //Cache remains in the same "M" state
                    end
                 else if(Pr_Wr_2==1)         //If the current working processor wants to write something onto its' Cache
                    begin
                       Cache2_data[Cache2_pointer]=ST2_data;    //Store data from processor onto the Cache
                       Cache2_state[Cache2_pointer]=2'b11;       //Cache remains in the same "M" state
                    end   
              end                  
   endcase

   case(Cache1_state[Cache1_pointer])           //State Machine for the other Processor
       2'b00: begin               //Cache of the other processor is in the "I" state
                 if(Bus_Rd_IC_2==1)     //If the effective address is not found in both the Caches and data has to be fetched from Memory
                   Cache1_state[Cache1_pointer]=2'b00;  //Cache remains in same "I" state
                 else if(Bus_RdX_2==1)   //If there's a Write miss for working processor
                   Cache1_state[Cache1_pointer]=2'b00;  //Cache remains in same "I" state
                 else if(Bus_Upgr_2==1)   //If there's something being written by the working processor
                   Cache1_state[Cache1_pointer]=2'b00;   //Cache remains in the same "I" state 
              end
       2'b01: begin              //Cache of the other processor is in the "E"
                 if(Bus_RdX_2==1 && Flush_Opt_2==1)  //If there's a write miss for the current working processor, data of the other processor has
                    begin                       // to be written back to the Main Memory before the working processor writes new data onto its' Cache
                       Memory_data[effective_address_2]=Cache1_data[Cache1_pointer];  //Data present in the other processor's cache is being written back
                       Cache1_state[Cache1_pointer]=2'b00;          //And state changes from "E" to "I" as working processor is doing "Write" operation
                    end 
                 else if(Bus_Rd_C_2==1 && Flush_Opt_2==1)  //Cache of working processor fetches data from the cahe of other processor
                    begin
                       Cache2_data[Cache2_pointer]=Cache1_data[Cache1_pointer];  //Fetch data from the other Cache
                       Memory_data[effective_address_2]=Cache1_data[Cache1_pointer];  //Write back to Memory as well
                       Cache1_state[Cache1_pointer]=2'b10;       //Change state from "E" to "S"
                    end   
              end  
       2'b10: begin                      //Cache of the other processor is in the "S" state
                 if(Bus_Rd_C_2==1 && Flush_Opt_2==1)  //Cache of working processor fetches data from the cahe of other processor
                    begin
                       Memory_data[effective_address_2]=Cache1_data[Cache1_pointer]; //Write back takes place
                       Cache1_state[Cache1_pointer]=2'b10;     //Cache remains in the "S" state
                    end
                 else if(Bus_RdX_2==1 && Flush_Opt_2==1)  //write miss encountered by the working processor in its' own Cache
                    begin
                       Memory_data[effective_address_2]=Cache1_data[Cache1_pointer];  //write back before going into "I" state
                       Cache1_state[Cache1_pointer]=2'b00;     //state changes to "I" state
                    end   
                 else if(Bus_Upgr_2==1)     //Working processor wants to write onto its' cache and wants to inavlid other Caches containing same address
                    begin
                       Memory_data[effective_address_2]=Cache1_data[Cache1_pointer];  //Write back happens before going into "I" state
                       Cache1_state[Cache1_pointer]=2'b00;   //Cache of othe rprocessor goes into the "I" state
                    end   
              end    
       2'b11: begin                   //Cache of other processor is in the "M" state
                 if(Bus_Rd_C_2==1 && Flush_2==1)   //working processor now wants to read the data that had been written just now by other processor to its' own cache
                    begin
                       Memory_data[effective_address_2]=Cache1_data[Cache1_pointer]; //wite back to the memory before going into "S" state
                       Cache1_state[Cache1_pointer]=2'b10;   //change of the state of the other cache to "S" cache
                    end
                 else if(Bus_RdX_2==1 && Flush_2==1)  //write miss encountered by the working processor
                    begin
                       Memory_data[effective_address_2]=Cache1_data[Cache1_pointer];  //write back needs to happen before it goes into the "I" state 
                       Cache1_state[Cache1_pointer]=2'b00;   //cache goes into the "I" state
                    end    
              end               
   endcase

end

endmodule
