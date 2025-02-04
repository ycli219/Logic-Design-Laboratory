`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/26 18:30:01
// Design Name: 
// Module Name: lab1_2
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
 

module lab1_2(a , b , aluctr , d);
    input [3:0] a;
    input [1:0] b;
    input [1:0] aluctr;
    output wire [3:0] d;
    
    wire [3:0] flag;
    wire [3:0] flag2;
    
    wire tmp;
    assign tmp = aluctr[0];
    lab1_1 m1(a,b,tmp,flag);
    
    assign flag2 = (aluctr[0]) ? (a - b) : (a + b);
    
    assign d = (aluctr[1]) ? flag2 : flag;
endmodule
