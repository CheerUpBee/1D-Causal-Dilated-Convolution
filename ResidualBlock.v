`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/04 18:55:07
// Design Name: 
// Module Name: ResidualBlock
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module ResidualBlock #(
    parameter integer DILATION = 1,
    parameter integer KERNEL_SIZE = 2,
    parameter integer RESIDUAL_CHANNELS = 512,
    parameter integer SKIP_CHANNELS = 512,
    parameter integer INPUT_CHANNELS = 256
)(
    input clk,
    input reset,
    input signed [INPUT_CHANNELS-1:0] x,
    input [1:0] conv1x1_h_write, // bit 1 : residual output path, bit 0 : skip connection path
    input [15:0] conv1x1_h_index_in,
    input [15:0] conv1x1_h_index_out,
    input [15:0] conv1x1_h_value,
    output wire signed [16 * RESIDUAL_CHANNELS:0] residual_out,
    output wire signed [16 * SKIP_CHANNELS:0] skip_out
    );
    
    
    wire signed [15:0] conv_out; // layer output
    wire signed [15:0] filter_out[0:RESIDUAL_CHANNELS-1];
    wire signed [RESIDUAL_CHANNELS*16-1:0] y_filter;
    wire signed [RESIDUAL_CHANNELS*16-1:0] y_gate;

    wire signed [15:0] gate_out[0:RESIDUAL_CHANNELS-1];
    reg signed [15:0] filter_tanh_out[0:RESIDUAL_CHANNELS-1];
    reg signed [15:0] gate_sigmoid_out[0:RESIDUAL_CHANNELS-1];
    wire signed [RESIDUAL_CHANNELS * 16 - 1 : 0] z;
    wire signed [15:0] residual_conv1x1_out;

    wire signed [15:0] residual_in[0:RESIDUAL_CHANNELS-1];
    
    integer i;

    genvar gi;
    
    DilatedCausal1DConv #(
        .INPUT_CHANNELS(RESIDUAL_CHANNELS),
        .OUTPUT_CHANNELS(RESIDUAL_CHANNELS),
        .KERNEL_SIZE(KERNEL_SIZE),
        .DILATION(DILATION)
    ) filter(
        .clk(clk),
        .reset(reset),
        .x(x),
        .y(y_filter)
    );
    
    DilatedCausal1DConv #(
        .INPUT_CHANNELS(RESIDUAL_CHANNELS),
        .OUTPUT_CHANNELS(RESIDUAL_CHANNELS),
        .KERNEL_SIZE(KERNEL_SIZE),
        .DILATION(DILATION)        
    ) gate(
        .clk(clk),
        .reset(reset),
        .x(x),
        .tanh_value(y_gate)
    );

    generate
        for (gi = 0; gi < RESIDUAL_CHANNELS - 1; gi = gi + 1) begin : connection
            assign filter_out[gi] = y_filter[gi * 16 + 15 : gi * 16];
            assign gate_out[gi] = y_gate[gi * 16 + 15 : gi * 16];
        end
    endgenerate


    generate
        for (gi = 0; gi < RESIDUAL_CHANNELS; gi = gi + 1) begin
            TanhLUT tanh_lut(
                .x(filter_out[gi]),
                .tanh_value(filter_tanh_out[gi])
            );
            SigmoidLUT sigmoid_lut(
                .x(gate_out[gi]),
                .sigmoid_value(gate_sigmoid_out[gi])
            );
        end
    endgenerate
    
    Conv1x1 #(
        .INPUT_CHANNELS(RESIDUAL_CHANNELS),
        .OUTPUT_CHANNELS(SKIP_CHANNELS)
    ) residual_conv1x1 (
        .clk(clk),
        .reset(reset),
        .x(z),
        .h_write(conv1x1_h_write[1]),
        .h_index_in(conv1x1_h_index_in),
        .h_index_out(conv1x1_h_index_out),
        .h_value(conv1x1_h_value),
        .y(residual_conv1x1_out)
    );
    
        Conv1x1 #(
        .INPUT_CHANNELS(RESIDUAL_CHANNELS),
        .OUTPUT_CHANNELS(SKIP_CHANNELS)
    ) skip_conv1x1 (
        .clk(clk),
        .reset(reset),
        .x(z),
        .h_write(conv1x1_h_write[0]),
        .h_index_in(conv1x1_h_index_in),
        .h_index_out(conv1x1_h_index_out),
        .h_value(conv1x1_h_value),
        .y(skip_out)
    );
    
// z = tanh(W_f,k * x) (.) sigmoid(W_g,k * x), (.) is elemental-wise multiplication, * is convolution
generate
    for(gi = 0; gi < RESIDUAL_CHANNELS; gi = gi + 1) begin
        assign z[gi * 16 + 15:gi * 16] = filter_tanh_out[gi] * gate_sigmoid_out[gi];
    end
endgenerate

// summing input value and conv1x1_residual output value
generate    
    for(gi = 0; gi < RESIDUAL_CHANNELS; gi = gi + 1) begin
        assign residual_out[gi * 16 + 15 : gi * 16] = z[gi * 16 + 15 : gi * 16];
    end
endgenerate
    
endmodule
