/*
// Detecting a big sequence - 1110_1101_1011
module day12 (
  input     wire        clk,
  input     wire        reset,
  input     wire        x_i,
  output    wire        det_o
);

  reg [11:0] shift;
  wire [11:0] next_reg;
  
  always@(posedge clk or posedge reset) begin
    if(reset)
      shift <= 12'h0;
    else 
      shift <= next_reg;
  end
  
  //shifting one by one to the next inp to check 
  assign next_reg = {shift[10:0], x_i};
  //output becomes true if the condition matches
  assign det_o = {shift[11:0] == 12'b1110_1101_1011};

endmodule
*/

//fsm method
module day12 (
  input wire clk,
  input wire reset,
  input wire x_i,
  output reg det_o
);

  parameter S0 = 4'b0000;
  parameter S1 = 4'b0001;
  parameter S2 = 4'b0010;
  parameter S3 = 4'b0011;
  parameter S4 = 4'b0100;
  parameter S5 = 4'b0101;
  parameter S6 = 4'b0110;
  parameter S7 = 4'b0111;
  parameter S8 = 4'b1000;
  parameter S9 = 4'b1001;
  parameter S10 = 4'b1010;
  parameter S11 = 4'b1011;
  //parameter S12 = 4'b1100;

  reg [3:0] state, next_state;

  // State transition logic
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= S0;
    end else begin
      state <= next_state;
    end
  end

  // Next state logic
  always @(*) begin
    case (state)
      S0: next_state <= x_i ? S1 : S0;
      S1: next_state <= x_i ? S2 : S0;
      S2: next_state <= x_i ? S3 : S0;
      S3: next_state <= x_i ? S3 : S4;
      S4: next_state <= x_i ? S4 : S0;
      S5: next_state <= x_i ? S6 : S0;
      S6: next_state <= x_i ? S3 : S7;
      S7: next_state <= x_i ? S8 : S0;
      S8: next_state <= x_i ? S9 : S0;
      S9: next_state <= x_i ? S3 : S10;
      S10: next_state <= x_i ? S11 : S0;
      S11: next_state <= x_i ? S2 : S0;
      default: next_state <= S0;
    endcase
  end

  // Output logic
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      det_o <= 1'b0;
    end else begin
      if (state == S11 && x_i) begin
        det_o <= 1'b1;
      end else begin
        det_o <= 1'b0;
      end
    end
  end

endmodule
