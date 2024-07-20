
//-----------------------------------------------------------------------------
// Serial CRC module for
// data[7:0] ==> is for 8 bits 
// crc[15:0]=1+x^2+x^15+x^16; ==> is for crc data-bus width 8 bits and polynomial width 16 bits

module crc16b(
    input clk,
	input rst,
    input [7:0]data_in,
    input crc_en,
    output [15:0]crc_out
	);

reg [15:0]lfsr_q;
reg [15:0]lfsr_c;

// assignment for output 
assign crc_out = lfsr_q;

// registers allocated with lfsr for each bit in crc polynomial using xor operation
always @(*) begin
    lfsr_c[0] = lfsr_q[8] ^ lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    lfsr_c[1] = lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    lfsr_c[2] = lfsr_q[8] ^ lfsr_q[9] ^ data_in[0] ^ data_in[1];
    lfsr_c[3] = lfsr_q[9] ^ lfsr_q[10] ^ data_in[1] ^ data_in[2];
    lfsr_c[4] = lfsr_q[10] ^ lfsr_q[11] ^ data_in[2] ^ data_in[3];
    lfsr_c[5] = lfsr_q[11] ^ lfsr_q[12] ^ data_in[3] ^ data_in[4];
    lfsr_c[6] = lfsr_q[12] ^ lfsr_q[13] ^ data_in[4] ^ data_in[5];
    lfsr_c[7] = lfsr_q[13] ^ lfsr_q[14] ^ data_in[5] ^ data_in[6];
    lfsr_c[8] = lfsr_q[0] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_in[6] ^ data_in[7];
    lfsr_c[9] = lfsr_q[1] ^ lfsr_q[15] ^ data_in[7];
    lfsr_c[10] = lfsr_q[2];
    lfsr_c[11] = lfsr_q[3];
    lfsr_c[12] = lfsr_q[4];
    lfsr_c[13] = lfsr_q[5];
    lfsr_c[14] = lfsr_q[6];
    lfsr_c[15] = lfsr_q[7] ^ lfsr_q[8] ^ lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
 end 

// selection depending on the lfsr regs 
always @(posedge clk, posedge rst) begin
    if(rst) begin
        lfsr_q <= {16{1'b0}};
    end
    else begin
        lfsr_q <= crc_en ? lfsr_c : lfsr_q;
    end
end 
endmodule 

//-----------------------------------------------------------------------//

// //16 bits of parallel CRC 
// 
// module CRC_16_parallel( 
//   input clk,
//   input rst,
//   input load,
//   input d_finish,
//   input reg [7:0]crc_in,
//   output reg [7:0]crc_out
// );
// 
// // 3 states for parameter 
// parameter idle = 2'b00;
// parameter compute = 2'b01;
// parameter finish = 2'b10;
// 
// reg [15:0] crc_reg;
// reg [1:0] count;  
// reg [1:0] state; 
// wire [15:0] next_crc_reg; 
// 
// //since it is 16 bits of parallel crc 
// assign next_crc_reg[0] = (^crc_in[7:0]) ^ (^crc_reg[15:8]); 
// assign next_crc_reg[1] = (^crc_in[6:0]) ^ (^crc_reg[15:9]); 
// assign next_crc_reg[2] = crc_in[7] ^ crc_in[6] ^ crc_reg[9] ^ crc_reg[8]; 
// assign next_crc_reg[3] = crc_in[6] ^ crc_in[5] ^ crc_reg[10] ^ crc_reg[9]; 
// assign next_crc_reg[4] = crc_in[5] ^ crc_in[4] ^ crc_reg[11] ^ crc_reg[10]; 
// assign next_crc_reg[5] = crc_in[4] ^ crc_in[3] ^ crc_reg[12] ^ crc_reg[11]; 
// assign next_crc_reg[6] = crc_in[3] ^ crc_in[2] ^ crc_reg[13] ^ crc_reg[12]; 
// assign next_crc_reg[7] = crc_in[2] ^ crc_in[1] ^ crc_reg[14] ^ crc_reg[13]; 
// assign next_crc_reg[8] = crc_in[1] ^ crc_in[0] ^ crc_reg[15] ^ crc_reg[14] ^ crc_reg[0]; 
// assign next_crc_reg[9] = crc_in[0] ^ crc_reg[15] ^ crc_reg[1]; 
// assign next_crc_reg[14:10] = crc_reg[6:2]; 
// assign next_crc_reg[15] = (^crc_in[7:0]) ^ (^crc_reg[15:7]); 
// 
// // clock configurations with state configurations 
// always@(posedge clk) 
// begin 
//     case(state) 
// 	    idle:begin 
// 	        if(load) 
// 			    state <= compute; 
// 			else
//             	state <= idle; 
//         end
// 		compute:begin 
// 		    if(d_finish) 
// 			    state <= finish;
// 			else
// 			    state <= compute; 
// 		end 
//         finish:begin 
//             if(count==2)
//                 state <= idle; 
//             else 
//                 state <= finish; 
//         end 
//     endcase 
// end 
// 
// // state with output configurations 
// always@(posedge clk or negedge rst) begin 
//     if(rst) begin 
//         crc_reg[15:0] <= 16'hFFFF; 
//         state <= idle; 
//         count <= 2'b00; 
//     end 
//     else 
//     case(state) 
//         idle:begin 
//             crc_reg[15:0] <= 16'h0000; 
//         end 
//         compute:begin 
//             crc_reg[15:0]<= next_crc_reg[15:0]; 
//             crc_out[7:0] <= crc_in[7:0]; 
//         end 
//         finish:begin 
//             crc_reg[15:0] <= {crc_reg[7:0],8'b0000_0000}; 
//             crc_out[7:0] <= crc_reg[15:8]; 
// 			count <= count + 1;
//         end 
//     endcase 
// end
// endmodule 