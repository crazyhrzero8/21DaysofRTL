`timescale 1ns / 1ps          

module top_tb_mesi ( );
    parameter Cache_Block_Size = 8 ; //i.e. 1 Byte
    parameter host_pid = 2'b00 ; //Processor ID
    logic clk ; //clock signal
    logic resetn ; //Negetive Reset
    Pr_Op core_op1, core_op2 ; //processor operations
    logic PrHlt1, PrHlt2 ; //Processor_Halt (output to Processor)
    //addr_bits = 4 bits [2-bit(tag) + 2-bit(index) (Note that it is a Byte addressable cache)
    logic [3:0] pr_addr1,pr_addr2  ; //Processor generated address (4-bits)
    logic [Cache_Block_Size-1:0] Cache_output1, Cache_output2 ; //If Cache_Hit, give the correponding Cache block as output
    logic [Cache_Block_Size-1:0] Cache_input1, Cache_input2 ; //Data to be stored/written in Store instructions
    //Bus Size = 2-bit(pid) + 3-bit(bus_transaction_id) + 2-bit(tag of transfered data if any) + 2-bit(index of transfered data if any) + Cache_Block_Size (transfered Cache block if any)
    logic [(2+3+2+2+Cache_Block_Size)-1:0] bus12 ; //Bus
    logic [(2+3+2+2+Cache_Block_Size)-1:0] bus21 ; //Bus
    logic flag21, flag12; //Flags to validate the Bus

	MESI_FSM #(Cache_Block_Size,host_pid) core1( clk, resetn, core_op1, PrHlt1, pr_addr1, Cache_output1, Cache_input1, bus21, bus12, flag21, flag12);
	
	initial clk = 1'b0 ;
	always #1 clk = ~clk ;

	initial begin //%%%%%%%%%%%%%%%%%%%%%%% CORE - 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		// initial reset phase 
		resetn = 1'b0 ; 
		#3;
		// start _ fetching data in initialisation _ non-conflicting data 
		// all PrRd miss but all new data exclusive
		// core 1, core 2 : all exclusive
		resetn = 1'b1 ; //As it's just initiated after reset, Data should be fetched from the Memory
		do begin core_op1 = PrRd ; pr_addr1 = 4'b0000;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Exclusive, CachOutput = 8'hffff
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0001;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Exclusive, CachOutput = 8'hffff      
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0010;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Exclusive, CachOutput = 8'hffff      
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0011;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Exclusive, CachOutput = 8'hffff 
		
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0000;                     
		#1.2; end while(PrHlt1); //Cache-Hit -> Cache_Status[00] = Exclusive, CachOutput = 8'hffff
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0100;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Core2 -> Cache_Status[00] = Shared, CachOutput = 10  
		#4 do begin core_op1 = PrWr ; pr_addr1 = 4'b0100; Cache_input1 = 30;  
		#1.2; end while(PrHlt1); //Cache-Hit -> Put BusUpgrade request -> Cache_Status[00] = Modified, CachOutput = 30
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0011;                     
		#1.2; end while(PrHlt1); //Cache-Hit -> Cache_Status[00] = Exclusive, CachOutput = 8'hffff 

        // reset 
		resetn = 1'b0 ; #3;

 		// start _ fetching data in initialisation _ conflicting data 
 		// all PrRd miss but all new data shared 
 		// core 1 , core 2 : all shared
        resetn = 1'b1; 
        
        do begin core_op1 = PrRd ; pr_addr1 = 4'b0000;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Shared (As Core2 is also fetching), CachOutput = 8'hffff
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0001;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Shared (As Core2 is also fetching), CachOutput = 8'hffff      
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0010;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Shared (As Core2 is also fetching), CachOutput = 8'hffff      
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0011;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Shared (As Core2 is also fetching), CachOutput = 8'hffff 
        
        // reset 
		resetn = 1'b0 ; #3;

 		// start _ fetching data in initialisation _ conflicting data (delayed)
 		// all PrRd miss, but data found in neighbour core
 		// initially exclusive then state changed to shared
 		
 		// core 1 : one exclusive, three shared
 		// core 2 : one exclusive, three shared  
		resetn = 1'b1 ; 
		
		do begin core_op1 = PrRd ; pr_addr1 = 4'b1111;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[11] = Exclusive, CachOutput = 8'hffff
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0000;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Shared (As Core2 is also fetching), CachOutput = 8'hffff      
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0001;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[01] = Shared (As Core2 is also fetching), CachOutput = 8'hffff      
		#4 do begin core_op1 = PrRd ; pr_addr1 = 4'b0010;                     
		#1.2; end while(PrHlt1); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[10] = Shared (As Core2 is also fetching), CachOutput = 8'hffff 
        
        
	end
	
	initial begin
	 $monitor("Time %0t clk %0d, resetn %0d, core_op1 %0d, PrHlt1 %0d, pr_addr1 %0d, Cache_output1 %0d, Cache_input1 %0d, bus21 %0d, bus12 %0d, flag21 %0d, flag12 %0d",$time, clk, resetn, core_op1, PrHlt1, pr_addr1, Cache_output1, Cache_input1, bus21, bus12, flag21, flag12);
	end
	
	MESI_FSM #(8,1) core2( clk, resetn, core_op2, PrHlt2, pr_addr2, Cache_output2, Cache_input2, bus12, bus21, flag12, flag21);
	
	initial begin //%%%%%%%%%%%%%%%%%%%%%%% CORE - 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		#3;
		do begin core_op2 = PrRd ; pr_addr2 = 4'b0100;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Exclusive, CachOutput = 8'hffff
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0101;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Exclusive, CachOutput = 8'hffff
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0110;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Exclusive, CachOutput = 8'hffff
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0111;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Exclusive, CachOutput = 8'hffff
		
		#4 do begin core_op2 = PrWr ; pr_addr2 = 4'b0100; Cache_input2 = 10;  
		#2.1; end while(PrHlt2); //Cache-Hit -> Put BusUpgrade request -> Cache_Status[00] = Modified, CachOutput = 10
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0100;                     
		#2.1; end while(PrHlt2); //Cache-Hit -> Cache_Status[00] = Shared (As Core-1 is fetching the same data), CachOutput = 10
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0100;                     
		#2.1; end while(PrHlt2); //Cache-Hit -> Cache_Status[00] = Invalid,->Put BusRd request -> Fetched from Core1 -> Cache_Status[00] = Shared -> CachOutput = 10
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0111;                     
		#2.1; end while(PrHlt2); //Cache-Hit -> Cache_Status[00] = Exclusive -> CachOutput = 8'hffff

		// reset 
		#3

 		// start _ fetching data in initialisation _ conflicting data 
 		// all PrRd miss but all new data shared 
 		// core 1 , core 2 : all shared
        #4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0000;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Shared (As Core2 is also fetching), CachOutput = 8'hffff
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0001;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Shared (As Core2 is also fetching), CachOutput = 8'hffff
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0010;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Shared (As Core2 is also fetching), CachOutput = 8'hffff
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0011;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Shared (As Core2 is also fetching), CachOutput = 8'hffff
        
        // reset 
		#10

 		// start _ fetching data in initialisation _ conflicting data (delayed)
 		// all PrRd miss, but data found in neighbour core
 		// initially exclusive then state changed to shared
 		
 		// core 1 : one exclusive, three shared
 		// core 2 : one exclusive, three shared  
		
        #4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0000;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[00] = Shared (As Core2 is also fetching), CachOutput = 8'hffff
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0001;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[01] = Shared (As Core2 is also fetching), CachOutput = 8'hffff
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0010;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[10] = Shared (As Core2 is also fetching), CachOutput = 8'hffff
		#4 do begin core_op2 = PrRd ; pr_addr2 = 4'b0011;                     
		#2.1; end while(PrHlt2); //Cache-Miss -> Put BusRd request -> Fetched from Mem -> Cache_Status[11] = Exclusive, CachOutput = 8'hffff
	end
	
	initial begin 
	   #160 $finish();
	end
	
	initial begin
	   $dumpfile("dump.vcd");
	   $dumpvars;
	end

endmodule
