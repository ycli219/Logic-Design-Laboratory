`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/28 20:44:24
// Design Name: 
// Module Name: lab2_1
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


module lab2_1(
    input clk,
    input rst,
    output reg [5:0] out);
    
    reg [5:0] out_next;
    reg [31:0] index;
    reg flag;
    
    always @* begin
        if(out == 6'b000000) begin
            out_next = 6'b000001;
            index = 1;
            flag = 1;
        end else if(out == 6'b111111) begin
            out_next = 6'b111110;
            index = 1;
            flag = 0;
        end else begin
            index = index + 1;
            if(flag == 1) begin
                out_next = (out > index) ? out-index : out+index;
            end else begin
                out_next = out - (2**(index-1));
            end
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if(rst == 1'b1) begin
            out <= 0;
            index <= 1;
            flag <= 1;
        end else begin
            out <= out_next;
        end
    end
endmodule
