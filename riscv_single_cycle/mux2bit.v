module mux2x1 #(
parameter n = 32
)(
input wire sel   ,
input wire [n-1:0] in0 , in1 ,
output reg [n-1:0] out
);

always@(*) begin
  if(sel) begin
	    out = in1 ;
	  end
  else begin 
	    out = in0 ; 
	  end
end

endmodule 
