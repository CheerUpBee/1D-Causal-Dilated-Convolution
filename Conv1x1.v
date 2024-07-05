`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Seoultech
// Engineer: YAE JOON OH
// 
// Create Date: 2024/07/05 19:40:45
// Project Name: Wavenet for FPGA
// Module Name: Conv1x1
// Revision 0.01 - File Created

// 
//////////////////////////////////////////////////////////////////////////////////


module Conv1x1 #(
    parameter INPUT_CHANNELS = 512,
    parameter OUTPUT_CHANNELS = 256
)(
    input clk,
    input reset,
    input signed [INPUT_CHANNELS * 8 - 1 : 0] x,
    input h_write,
    input signed [7:0] h_value,
    input [7:0] h_index_in,
    input [7:0] h_index_out,
    output signed [OUTPUT_CHANNELS * 8 - 1 : 0] y
    );
    
    wire [15:0] mul[0:OUTPUT_CHANNELS - 1];
    reg signed [7:0] h[0 : OUTPUT_CHANNELS - 1];
    genvar gi, gj;
    integer i;
    always @ (posedge clk or negedge reset) begin
        if (reset) begin
            for(i = 0; i < OUTPUT_CHANNELS - 1; i = i + 1) begin
                h[i] <= 1;
            end
        end
        else begin
            if(h_write) begin
                h[h_index_in][h_index_out] <= h_value;
            end 
        end
    end
    
    for(gi = 0; gi < INPUT_CHANNELS -1; gi = gi + 1) begin
        for(gj = 0; gj < OUTPUT_CHANNELS - 1; gj = gj + 1) begin
            assign y[gj * 8 + 7 : gj * 8] = x[gi] * h[gj];
        end
    end
    
    for (gi = 0; gi < OUTPUT_CHANNELS - 1; gi = gi + 1) begin
        assign y[gi] = mul[gi] >= 16'd127 ? 8'd127 : (mul[gi] <= -16'd128 ? -8'd128 : mul[gi]); // clipping result
    end

endmodule
