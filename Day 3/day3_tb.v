// Simple edge detector TB

module day3_tb ();

  reg clk;
  reg reset;

  reg a_i;
  integer i;
  wire rising_edge_o;
  wire falling_edge_o;
  
  day3 tc(.clk(clk),.reset(reset),.a_i(a_i),.rising_edge_o(rising_edge_o),.falling_edge_o(falling_edge_o));
  
  initial begin
		clk=0;
		forever #2.5 clk=~clk;
	end
  
  initial begin
		reset=1;
		a_i=0;
		#5; reset=0;
		a_i=1;
		#5;
		a_i=0;
		#5;
		a_i=1;
		reset=1;
		#5;
		reset =0;
		for(i=0; i<20; i=i+1) begin
    	#5; a_i = $random % 2;
    end
		#20;
		$finish();
	end

	initial begin
  	$monitor("%0t %0d %0d %0d %0d %0d ", $time, clk, reset, a_i, rising_edge_o, falling_edge_o);
	end

endmodule
