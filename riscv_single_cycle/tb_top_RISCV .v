`timescale 1ps/1fs 
module tb_top_RISCV();

localparam n = 10;
localparam m = 32;
reg clk ;
reg rst ; 
wire [n-1:0] addr; 
wire [m-1:0] write_data;
wire         memwr ;
wire [31:0]  read_data;
wire [31:0]  PC;
wire [31:0]  instr;

//instantiations for top, instructions and data controls
top_RISCV #(10,32) u_top (
.clk(clk),
.rst(rst), 
.addr(addr), 
.write_data(write_data),
.memwr(memwr),
.read_data(read_data),
.PC(PC),
.instr(instr)
);

instr_rom #(10,32) u_ins_rom (
.addr(PC[9:0]),
.read_data(instr)
);

data_ram #(10,32) u_data_ram (
.clk(clk),
.rst(rst),
.we(memwr),
.addr(addr),
.write_data(write_data),
.read_data(read_data)
);

initial begin
  clk = 0 ;
  forever #500 clk = ~clk ;
end

initial 
begin 
  rst = 1'b1  ;
  #1000 
  rst = 1'b0 ;
end

always@(negedge clk)
begin
  if(memwr)
    begin
      if(write_data == 2 && addr == 96)
        begin
          $display("time = %0t , write_data = %4d %0h,  addr = %8d %0h,testcase1 passed (first sw)", $time , write_data , addr) ;
        end
      else if(write_data == 4 && addr == 92)
        begin
          $display("time = %0t , write_data = %4d %0h,  addr = %8d %0h,testcase2 passed (second sw)", $time , write_data , addr) ;
          $stop ;
        end
      else
        begin
          $display("time = %0t , write_data = %4d %0h,  addr = %8d %0h,testcase1,2 failed", $time , write_data , addr) ;
          $stop ;
        end
    end
end

endmodule
