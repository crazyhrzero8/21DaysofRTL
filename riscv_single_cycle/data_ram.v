module data_ram #(
parameter n = 10 , m = 32 
)(
input wire    clk,
input wire    rst,
input wire    we,
input wire [n-1:0] addr,
input wire [m-1:0] write_data,
output wire [m-1:0] read_data
);

reg [m-1:0] mem [0:2**(n-2)-1] ; //n-2 for word addressable memory
integer i ; 

always@(posedge clk or posedge rst)
begin
  if(rst) begin
      for(i=0 ; i < 2**(n-2) ; i = i+1) begin
        mem[i] <= 'h0 ;
      end
  end
  else if(we) begin
      mem[addr[n-1:2]] <= write_data ; //[n-1:2] for word addressable memory
    end
end

assign read_data = mem[addr[n-1:2]] ; //[n-1:2] for word addressable memory

endmodule 