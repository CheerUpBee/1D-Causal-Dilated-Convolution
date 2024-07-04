`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Seoultech
// Engineer: YAE JOON OH
// 
// Create Date: 2024/07/02 00:06:48
// Module Name: DilatedCausal1DConv
// Project Name: Wavenet for FPGA
//////////////////////////////////////////////////////////////////////////////////


module DilatedCausal1DConv #(
    parameter integer DILATION_FACTOR = 1,
    parameter integer KERNEL_SIZE = 2,
    parameter integer INPUT_CHANNELS = 512,
    parameter integer OUTPUT_CHANNELS = 512
)(
    input clk,
    input reset,
    input wire signed [7:0] x[0:INPUT_CHANNELS-1], // 8-bit input signal
    output reg signed [7:0] y[0:OUTPUT_CHANNELS-1], // 8-bit output signal
    
    input h_write,
    input [7:0] h_index_channel,
    input [7:0] h_index_filter,
    input [7:0] h_value    
    );
    

    
    reg signed [7:0] h [0:INPUT_CHANNELS-1][0:KERNEL_SIZE-1];
    
    reg signed [7:0] x_delay [0:INPUT_CHANNELS-1][0:(DILATION_FACTOR*(KERNEL_SIZE-1))];
    
    reg signed [15:0] mul [0:INPUT_CHANNELS-1][0:KERNEL_SIZE-1];
    
    reg signed [15:0] sum [0:OUTPUT_CHANNELS-1];
    
    integer i,j;
    
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
        for(i = 0; i <= INPUT_CHANNELS-1; i= i+1) begin
            for (j = 0; j <= (DILATION_FACTOR*(KERNEL_SIZE-1)); j = j + 1) begin
                x_delay[i][j] <= 8'sh0;
            end           
            sum[i] <= 16'sh0; 
        end
    end
        
        else begin
        for(i = 0; i <= INPUT_CHANNELS-1; i= i+1) begin
            for(j=(DILATION_FACTOR*(KERNEL_SIZE-1)); j>0; j=j-1) begin
                x_delay[i][j] <= x_delay[i][j-1];
            end
            x_delay[i][0] <= x[i][0];
        end
    end
end
    
    always @ (posedge clk or posedge reset) begin // filter coef.
        if(reset) begin
            for(i = 0; i <= INPUT_CHANNELS-1; i= i+1) begin
                for(j=0; j<KERNEL_SIZE; j=j+1) begin
                    h[i][j] <= 8'd1 + j;
                end
            end
        end
        
        else begin
            if(h_write == 1) begin
                h[h_index_channel][h_index_filter] <= h_value;
            end
        end
    end    
    
always @(*) begin
    for(i = 0; i <= INPUT_CHANNELS-1; i= i+1) begin
        sum[i] = 0;
        for (j = 0; j < KERNEL_SIZE; j = j + 1) begin
            sum[i] = sum[i] + mul[i][j];
        end
     end
end

always @(*) begin
    for(i = 0; i <= INPUT_CHANNELS-1; i= i+1) begin
        for(j=0; j< KERNEL_SIZE; j = j + 1) begin
            mul[i][j] = x_delay[i][DILATION_FACTOR * j] * h[i][j];
        end
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        for(i = 0; i <= OUTPUT_CHANNELS-1; i= i+1) begin
            y[i] = 8'sh0;
        end
    end
    
    else begin
        for(i = 0; i <= OUTPUT_CHANNELS-1; i= i+1) begin
            if(sum[i] >= 127) begin
                y[i] <= 8'd127;
            end
        
            else if(sum[i] <=-128) begin
                y[i] <= -8'd128;
            end
            else begin
                y[i] <= sum[i][7:0];
            end
        end    
    end
end
    
endmodule
