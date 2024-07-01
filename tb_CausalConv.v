`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Seoultech
// Engineer: YAE JOON OH
// 
// Create Date: 2024/07/02 02:15:39
// Module Name: tb_CausalConv

//////////////////////////////////////////////////////////////////////////////////

module tb_CausalConv();
    parameter CLK_PERIOD = 10;
    reg clk, reset;
    reg [7:0] x;
    wire [7:0] y;
    DilatedCausal1DConv DUT (
        .x(x),
        .clk(clk),
        .reset(reset),
        .y(y)
    );
    
    
    initial begin
        clk=0;
        forever #(CLK_PERIOD/2) clk=~clk;
    end
    
    initial begin
        reset = 1;
        x = 8'd0;
        # (2*CLK_PERIOD);
        reset = 0;
        
        x = 8'd1; # (CLK_PERIOD);
        x = 8'd2; # (CLK_PERIOD);
        x = 8'd3; # (CLK_PERIOD);
        x = 8'd4; # (CLK_PERIOD);
        x = 8'd10; # (CLK_PERIOD);
        x = 8'd9; # (CLK_PERIOD);
        x = 8'd8; # (CLK_PERIOD);
        x = 8'd7; # (CLK_PERIOD);
        x = 8'd6; # (CLK_PERIOD);
        x = 8'd0; # (CLK_PERIOD);
        x = 8'd1; # (CLK_PERIOD);
        x = 8'd1; # (CLK_PERIOD);
        
        # (3 * CLK_PERIOD);
        $stop;
    end

endmodule
