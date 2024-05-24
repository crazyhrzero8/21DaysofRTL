// Simple ALU TB

module day4_tb ();

  reg [7:0]a_i;
  reg [7:0]b_i;
  reg [2:0]op_i;
  wire [7:0]alu_o;
  
  day4 tc(.*);
  
  initial begin
    a_i = 10;
    b_i = 10;
    op_i = 0;
    #5;
    a_i = 11;
    b_i = 1;
    op_i = 3;
    #5;
    $finish();
  end

endmodule
