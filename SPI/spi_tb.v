`timescale 1ns / 1ps
module spi_tb;

reg clk;
reg reset;
reg [15:0]datain;
reg [15:0]dataout;

wire spi_cs_l;
wire spi_clk;
wire spi_data;
wire master_data;
wire [4:0]counter;

spi dut(
.clk(clk),
.reset(reset),
.counter(counter),
.datain(datain),
.dataout(dataout),
.spi_cs_l(spi_cs_l),
.spi_clk(spi_clk),
.spi_data(spi_data),
.master_data(master_data)
);

initial
begin
clk = 0;
reset = 1;
datain = 0;
dataout= 0;
forever #5 clk =~clk;
end

initial
begin
#10 reset =1'b0;
#10 datain = 16'hA569; dataout = 16'h3425;
#335 datain= 16'h2563; dataout = 16'h0001;
#335 datain= 16'h9B63; dataout = 16'hA569;
#335 datain= 16'h6A61; dataout = 16'h9B22;
end
 
endmodule