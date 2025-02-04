`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/26 15:21:50
// Design Name: 
// Module Name: lab1_1
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


module lab1_1 (a , b , dir , d);
    input [3:0] a;
    input [1:0] b;
    input dir;
    output reg [3:0] d;
    
    always @* begin
        if (dir == 0) d = a << b;
        else d = a >> b;
    end
endmodule
