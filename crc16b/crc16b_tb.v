// tb 
module crc16b_tb; 
reg clk; 
reg rst; 
reg crc_en; 
reg [7:0]data_in; 
wire [15:0]crc_out; 

crc16b dut(.clk(clk), .rst(rst), .data_in(data_in), .crc_en(crc_en), .crc_out(crc_out)); 

initial begin 
    clk = 0;
	forever #5 clk = ~clk;
end

initial begin 
    rst = 1; 
    #10; 
    rst = 0; 
    data_in = 8'b1010_1010; 
    crc_en = 1; 
    #10; 
    data_in = 8'b0011_0110;
    $finish();
end 

initial begin
    $monitor("Time: %0t, data: %0b, clk: %0d", $time, data_in, clk);
end

initial begin
    $dumpfile("crc.vcd");
    $dumpvars;
end

endmodule 