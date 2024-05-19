// A simple TB for mux

module day1_tb ();

  reg [7:0]    a_i;
  reg [7:0]    b_i;
  reg          sel_i;
  wire [7:0]    y_o;

  
  day1 tc(.*);
  
  initial begin
    for(int i=0;i<10;i++) begin 
      a_i = $urandom_range(0,8'hFF);
      b_i = $urandom_range(0,8'hFF);
      sel_i = $random%2;
      #5;
    end
    $finish();
  end
endmodule
