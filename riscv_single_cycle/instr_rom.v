module instr_rom #(
parameter n = 10 , m = 32 
)(
input wire [n-1:0] addr,
output wire [m-1:0] read_data
);

reg [m-1:0] mem [0:2**(n-2)-1] ; //n-2 for word addressable memory

//reading the testcases from the file
initial begin 
  $readmemh("testcases.txt", mem);
end

assign read_data = mem[addr[n-1:2]] ; //[n-1:2] for word addressable memory

endmodule 

