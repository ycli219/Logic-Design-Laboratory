`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/08 16:31:29
// Design Name: 
// Module Name: lab3_1
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


module clock_divider #(parameter n=25) (
    input clk,
    output reg clk_div
    );
    
    reg [31:0] count = 32'b0;
    always @(posedge clk) begin
        count <= count + 1'b1;
        if(count >= (2**n)-1) count <= 32'b0;
        clk_div <= (count < (2**n)/2) ? 1'b1 : 1'b0;
    end
endmodule

module lab3_1(
    input clk,
    input rst,
    input en,
    input speed,
    output reg [15:0] led
    );
    
    wire bits_24;
    wire bits_27;
    wire clock;
    reg flag;
    clock_divider #(24) m1(clk,bits_24);
    clock_divider #(27) m2(clk,bits_27);
    
    assign clock = (flag==1) ? bits_27 : bits_24;
    
    always @* begin
        if(speed == 1'b1) flag <= 1;
        else flag <= 0;
    end
    
    always @(posedge clock or posedge rst) begin
            if(rst == 1'b1) begin
                led <= 16'b1111111111111111;
            end else if(en == 1'b1) begin
                led <= ~led;
            end
    end
    
    
   
endmodule
