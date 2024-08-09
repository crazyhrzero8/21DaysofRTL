`timescale 1ns / 1ps

module alu #(
    parameter DataBits = 8
	)(
    input [DataBits-1:0] a,
    input [DataBits-1:0] b,
    input sub_bAdd,
    output [DataBits-1:0] result,
    output carry_flag,
    output zero_flag
    );

wire [DataBits:0]expanded_result;
assign expanded_result = a+(sub_bAdd ? ~b + 1 : b);
assign result = expanded_result[DataBits-1:0];
assign carry_flag = expanded_result[DataBits];
assign zero_flag = expanded_result[DataBits-1:0] == 0;

endmodule
