`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Company: Seoultech
// Engineer: YAE JOON OH
// 
// Create Date: 2024/07/02 17:40:37
// Module Name: tb_CausalConv
// 
//////////////////////////////////////////////////////////////////////////////////


module Simple1DConv(
    input clk,
    input reset,
    input wire signed [7:0] x,
    output reg signed [7:0] y,
    
    input h_write,
    input [3:0] h_index,
    input [7:0] h_value
    );
    parameter integer KERNEL_SIZE = 3;
    integer i;
    
    reg signed [7:0] x_delay[0:KERNEL_SIZE-1];
    reg signed [7:0] h[0:KERNEL_SIZE-1];
    
    reg signed [15:0] sum;
    reg signed [15:0] mul[0:KERNEL_SIZE-1];
    
    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            for(i=0; i<KERNEL_SIZE; i=i+1) begin
                x_delay[i] <= 8'd0;
            end

        end
        
        else begin
            for(i=1; i<KERNEL_SIZE; i=i+1) begin
                x_delay[i] <= x_delay[i-1];
            end
            x_delay[0] <= x; 
        end
    end
    
    always @ (posedge clk or posedge reset) begin // filter coef.
        if(reset) begin
            for(i=0; i<KERNEL_SIZE; i=i+1) begin
                h[i] <= 8'd1 + i;
            end
        end
        
        else begin
            if(h_write == 1) begin
                h[h_index] <= h_value;
            end
        end
    end
    
    always @ (*) begin // weighted sum
        for(i=0; i<KERNEL_SIZE; i=i+1) begin
            mul[i] = x_delay[i] * h[i];
        end
        sum = 0;
        for(i=0; i<KERNEL_SIZE; i=i+1) begin
            sum = sum + mul[i];
        end
    end
    
    always @ (posedge clk or posedge reset) begin
        if(reset) begin
            y <= 0;
        end
        else begin
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
    end
endmodule
