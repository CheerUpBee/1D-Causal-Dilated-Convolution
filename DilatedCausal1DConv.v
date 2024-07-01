`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Seoultech
// Engineer: YAE JOON OH
// 
// Create Date: 2024/07/02 00:06:48
// Module Name: DilatedCausal1DConv
// Project Name: Wavenet for FPGA
//////////////////////////////////////////////////////////////////////////////////


module DilatedCausal1DConv(
    input clk,
    input reset,
    input wire signed [7:0] x, // 8-bit input signal
    output reg signed [7:0] y // 8-bit output signal
    );
    
    parameter [3:0] dilation_factor = 4'd2;
    parameter integer KERNEL_SIZE = 3;
    
    reg signed [7:0] h [0:KERNEL_SIZE-1];
    
    reg signed [7:0] x_delay [0:(dilation_factor*(KERNEL_SIZE-1))];
    
    reg signed [15:0] mul [0:KERNEL_SIZE-1];
    
    reg signed [15:0] sum;
    
    integer i;
    
    initial begin
        for (i=0;i<KERNEL_SIZE;i=i+1)begin
            h[i]=8'sh01+i; // just for test
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            for (i = 0; i <= (dilation_factor*(KERNEL_SIZE-1)); i = i + 1) begin
                x_delay[i] <= 8'sh0;
            end           
            sum <= 16'sh0;
            y <= 8'sh0;  
        end
        
        else begin
            for(i=(dilation_factor*(KERNEL_SIZE-1)); i>0; i=i-1) begin
                x_delay[i] <= x_delay[i-1];
            end
            x_delay[0] <= x;
        end
    end
always @(*) begin
    sum = 0;
    for (i = 0; i < KERNEL_SIZE; i = i + 1) begin
        sum = sum + mul[i];
    end
end

always @(*) begin
    for(i=0; i< KERNEL_SIZE; i = i + 1) begin
        mul[i] = x_delay[dilation_factor * i] * h[i];
    end
end

always @(*) begin
        if(sum >= 127) begin
            y <= 8'd127;
        end
        
        else if(sum <=-128) begin
            y <= -8'd128;
        end
        else begin
            y <= sum[7:0];
        end    
end
    
endmodule
