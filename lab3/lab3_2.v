`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/08 20:10:38
// Design Name: 
// Module Name: lab3_2
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

module lab3_2(
    input clk,
    input rst,
    input en,
    input dir,
    output reg [15:0] led
    );
    reg [1:0] state = 2'b00;
    reg [1:0] state_next;
    reg [15:0] led_next;
    reg [47:0] led_next_2; //
    reg [3:0] count_6 = 4'b0000;
    reg [6:0] adders = 7'b1000000; 
    
    reg [47:0] tool = 48'b000000000000000010101010101010100000000000000000;
    
    wire bits_25;
    clock_divider #(25) m1(clk,bits_25);
    
    always @* begin
        case(state)
            2'b00 : begin
                if(count_6 >= 4'b1100) begin
                    led_next = 16'b1010101010101010;
                    state_next = 2'b01;
                end else begin
                    led_next = ~led;
                    state_next = 2'b00;
                end
            end
            
            2'b01 : begin
                if(led == 16'b0000000000000000) begin
                    led_next_2 = 48'b000000000000000000000001100000000000000000000000;
                    state_next = 2'b10;
                end else begin
                    if(dir == 1'b1) begin
                        led_next_2 = tool << 1; //
                    end else begin
                        led_next_2 = tool >> 1; //
                    end
                    state_next = 2'b01;
                end
            end
            
            2'b10 : begin
                if(led == 16'b1111111111111111) begin
                    led_next = 16'b0000000000000000;
                    state_next = 2'b00;
                end else if(led == 16'b0000000000000000) begin
                    if(dir == 1'b1) begin
                        led_next = 16'b0000000000000000;
                    end else begin
                        led_next = 16'b0000000110000000;
                    end
                    state_next = 2'b10;
                end else begin
                    if(dir == 1'b0) begin
                        led_next = { led[15:8]*2 + 1 , led[7:0] + adders };
                    end else begin
                        led_next = { led[15:8] >> 1 , led[7:0] << 1 };
                    end
                    state_next = 2'b10;
                end
            end
        endcase
    end
    
    always @(posedge bits_25 or posedge rst) begin
        if(rst == 1'b1) begin
            led <= 16'b1111111111111111;
            state <= 2'b00;
            count_6 <= 4'b0000;
        end else if(en == 1'b1) begin
            if(state == 2'b10) begin
                if(state_next == 2'b00) count_6 <= 4'b0000;
                else if(dir == 1'b0) begin
                    if(led == 16'b0000000000000000) adders <= 7'b1000000;
                    else adders <= adders >> 1;
                end
            end else if(state == 2'b01) begin
                if(state_next == 2'b10) adders <= 7'b1000000;
                else if(state_next == 2'b01) begin
                    if(dir == 1'b1) tool <= tool << 1;
                    else tool <= tool >> 1;
                end
            end else if(state == 2'b00) begin
                if(state_next == 2'b01) tool <= 48'b000000000000000010101010101010100000000000000000; //
                count_6 <= count_6 + 4'b0001;
            end
            
            led <= (state == 2'b01) ? led_next_2[31:16] : led_next;
            state <= state_next;
        end
    end
    
endmodule
