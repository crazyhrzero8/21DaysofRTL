module mux3x1 #(
parameter n = 32
)(
input wire [1:0] sel   ,
input wire [n-1:0] in0 , in1 , in2,
output reg [n-1:0] out
);

always@(*) begin
  if(sel == 2'b10 ) begin
	    out = in2 ;
	  end
  else if (sel == 2'b01) begin
	    out = in1 ;
	  end
  else if (sel == 2'b00) begin
	    out = in0 ;
	  end   
  else begin
	    out = in0 ; 
	  end
end

endmodule 
