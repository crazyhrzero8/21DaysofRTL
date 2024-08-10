//***Performing R1, W1, R2, W2, R1 operations***//
`timescale 1ps/1ps

module MESI_tb;

reg clk;

reg Pr_Rd_1;
reg Bus_Rd_C_1;
reg Bus_Rd_IC_1;
reg Pr_Wr_1;
reg Bus_RdX_1;
reg Bus_Upgr_1;
reg Flush_1;
reg Flush_Opt_1;
reg [31:0] effective_address_1;
reg Pr_Rd_2;
reg Bus_Rd_C_2;
reg Bus_Rd_IC_2;
reg Pr_Wr_2;
reg Bus_RdX_2;
reg Bus_Upgr_2;
reg Flush_2;
reg Flush_Opt_2;
reg [31:0] effective_address_2;
reg [1:0] Cache1_pointer;
reg [1:0] Cache2_pointer;

MESI_protocol dut(clk,Pr_Rd_1,Bus_Rd_C_1,Bus_Rd_IC_1,Pr_Wr_1,Bus_RdX_1,Bus_Upgr_1,Flush_1,Flush_Opt_1,Cache1_pointer,Cache2_pointer,effective_address_1,Pr_Rd_2,Bus_Rd_C_2,Bus_Rd_IC_2,Pr_Wr_2,Bus_RdX_2,Bus_Upgr_2,Flush_2,Flush_Opt_2,effective_address_2);

initial 
begin
    $dumpfile("MESI_tb.vcd");
    $dumpvars(0, MESI_tb);

    clk=1;
    Cache1_pointer=0; Cache2_pointer=0;
    effective_address_1=5;
    effective_address_2=5;
    Pr_Rd_2=0; Bus_Rd_C_2=0; Bus_Rd_IC_2=0; Pr_Wr_2=0; Bus_RdX_2=0; Bus_Upgr_2=0; Flush_2=0; Flush_Opt_2=0;
    Pr_Rd_1=0; Bus_Rd_C_1=0; Bus_Rd_IC_1=0; Pr_Wr_1=0; Bus_RdX_1=0; Bus_Upgr_1=0; Flush_1=0; Flush_Opt_1=0; #10;

    Pr_Rd_1=1; Bus_Rd_IC_1=1; #5; Pr_Rd_1=0; Bus_Rd_IC_1=0; #5;
    Pr_Wr_1=1; Bus_Upgr_1=1; #5; Pr_Wr_1=0; Bus_Upgr_1=0; #5;
    Pr_Rd_2=1; Bus_Rd_C_2=1; Flush_2=1; #5; Pr_Rd_2=0; Bus_Rd_C_2=0; Flush_2=0; #5; 
    Pr_Wr_2=1; Bus_Upgr_2=1; #5; Pr_Wr_2=0; Bus_Upgr_2=0; #5;
    Pr_Rd_1=1; Bus_Rd_C_1=1; Flush_1=1; #5; Pr_Rd_1=0; Bus_Rd_C_1=0; Flush_1=0; #5;
end

always 
#5 clk=~clk;

initial begin
$monitor("Time %0t clk %0d \n======", $time, clk);
$monitor(Cache1_pointer, Cache2_pointer, effective_address_1, effective_address_2, Pr_Rd_1, Pr_Rd_2, Pr_Wr_1, Pr_Wr_2, Bus_RdX_1, Bus_RdX_2, Bus_Rd_C_1, Bus_Rd_C_2, Bus_Rd_IC_1, Bus_Rd_IC_2, Bus_Upgr_1, Bus_Upgr_2,Flush_1,Flush_2,Flush_Opt_1,Flush_Opt_2);
end

endmodule
