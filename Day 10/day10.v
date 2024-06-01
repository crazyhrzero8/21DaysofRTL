// Counter with a load
module day10 (
  input     wire          clk,
  input     wire          reset,
  input     wire          load_i,
  input     wire[3:0]     load_val_i,
  output    wire[3:0]     count_o
);
  
  reg [3:0]load_ff;
  reg [3:0]cnt_ff;
  wire [3:0]nxt_cnt;
  
  always@(posedge clk or posedge reset) begin
    if(reset)
      load_ff <= 4'h0;
    else if(load_i) 
      load_ff <= load_val_i;
    else 
      load_ff <= 4'h0;
  end
  
  always@(posedge clk or posedge reset) begin
    if(reset)
      cnt_ff <= 4'h0;
    else 
      cnt_ff <= nxt_cnt;
  end
  
  assign nxt_cnt = load_i ? load_val_i : 
            (cnt_ff == 4'hF) ? load_ff : 
                         cnt_ff + 4'h1 ; 
  assign count_o = cnt_ff; 
  
endmodule