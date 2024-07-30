`timescale 1ns / 1ps

module spi(
    input wire clk,
    input wire reset,
    input wire [15:0] datain,
    input wire [15:0] dataout,
    output wire spi_cs_l,
    output wire spi_clk,
    output wire spi_data,
    input wire master_data,
    output [4:0] counter
);

    reg [15:0] MOSI;
    reg [4:0] count;
    reg cs_l;
    reg sclk;
    reg [1:0] state;
    reg [15:0] MISO;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MOSI <= 16'b0;
            MISO <= 16'b0;
            count <= 5'd16;
            cs_l <= 1'b1;
            sclk <= 1'b0;
            state <= 2'b00;
        end
        else begin
            case (state)
                2'b00: begin //ideal
                    sclk <= 1'b0;
                    cs_l <= 1'b1;
                    state <= 2'b10;
                end
                2'b01: begin //full duplex transmission (read+write)
                    sclk <= 1'b0;
                    cs_l <= 1'b0;
                    MOSI <= datain[count-1];
                    MISO <= dataout[count-1];
                    count <= count - 1;
                    state <= 2'b10;
                end
                2'b10: begin //condition for next state
                    sclk <= 1'b1;
                    if (count > 0)
                        state <= 2'b01;
                    else begin
                        count <= 5'd16;
                        state <= 2'b00;
                    end
                end
                default: state <= 2'b00;
            endcase
        end
    end

    assign spi_cs_l = cs_l;
    assign spi_clk = sclk;
    assign spi_data = MOSI;
    assign master_data = MISO;
    assign counter = count;

endmodule
