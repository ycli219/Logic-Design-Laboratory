`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/24 13:00:47
// Design Name: 
// Module Name: lab4_1
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

//===============================================

module lab4_1(
    input clk,
    input rst,
    input en,
    input dir,
    input speed_up,
    input speed_down,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output reg max,
    output reg min
    );
    
    //===============================================debounce
    
    wire pb_de_en;
    wire pb_de_dir;
    wire pb_de_speed_up;
    wire pb_de_speed_down;
    
    debounce U2(pb_de_en , en , clk);
    debounce U3(pb_de_dir , dir , clk);
    debounce U4(pb_de_speed_up , speed_up , clk);
    debounce U5(pb_de_speed_down , speed_down , clk);
    
    //===============================================one pulse
    
    wire pulse_en;
    wire pulse_speed_up;
    wire pulse_speed_down;
    
    onepulse W2(pb_de_en , clk , pulse_en);
    onepulse W3(pb_de_speed_up , clk , pulse_speed_up);
    onepulse W4(pb_de_speed_down , clk , pulse_speed_down);
    
    //===============================================

    wire clk_25;
    wire clk_26;
    wire clk_27;
    wire global_clk;
    clock_divider #(23) m1(clk,clk_25);
    clock_divider #(24) m2(clk,clk_26);
    clock_divider #(25) m3(clk,clk_27);
    
    reg [19:0] frequency_cnt = 20'd0;
    wire [1:0] frequency;
    reg [3:0] BCD0 = 4'd0;
    reg [3:0] BCD1 = 4'd0;
    reg [3:0] value;
    reg [1:0] speed = 1'd0;
    reg resume = 1'b0;
    wire count_up = 1'b1;
    
    //===============================================
    
    assign global_clk = (speed == 2'd2) ? clk_25 : ((speed == 2'd1) ? clk_26 : clk_27);
    
    //===============================================

    always@(posedge clk) begin
        frequency_cnt <= frequency_cnt + 20'd1;
    end    
    
    assign frequency = frequency_cnt[19:18];
    
    //===============================================
    
    always@(posedge clk or posedge rst) begin
        if(rst == 1'b1) begin
            resume <= 1'b0;
            speed <= 2'd0;
        end else begin
            if(pulse_en == 1'b1) resume <= ~resume;
            else resume <= resume;
            
            if(pulse_speed_up == 1'b1) begin
                if(speed == 2'd2) speed <= 2'd2;
                else speed <= speed + 2'd1;
            end else if(pulse_speed_down == 1'b1) begin
                if(speed == 2'd0) speed <= 2'd0;
                else speed <= speed - 2'd1;
            end
        end  
    end
    
    //===============================================
    
    always@(posedge global_clk or posedge rst) begin
       if(rst == 1'b1) begin
           BCD0 <= 4'd0;
           BCD1 <= 4'd0;
           min <= 1'd0;
           max <= 1'd0;
       end else begin
            if(resume == 1'b0) begin
                BCD0 <= BCD0;
                BCD1 <= BCD1;
            end else if(resume == 1'b1) begin
                if((BCD0 == 4'd9 && BCD1 == 4'd9 && pb_de_dir == 1'b0) || (BCD0 == 4'd0 && BCD1 == 4'd0 && pb_de_dir == 1'b1)) begin
                    BCD0 <= BCD0;
                    BCD1 <= BCD1;
                end else begin
                    if(pb_de_dir == 1'b0) begin
                        if(BCD0 !== 4'd9) begin
                            BCD0 <= BCD0 + 4'd1;
                            BCD1 <= BCD1;
                        end else if(BCD0 == 4'd9 && BCD1 !== 4'd9) begin
                            BCD0 <= 4'd0;
                            BCD1 <= BCD1 + 4'd1;
                        end
                    end else if(pb_de_dir == 1'b1) begin
                        if(BCD0 !== 4'd0) begin
                            BCD0 <= BCD0 - 4'd1;
                            BCD1 <= BCD1;
                        end else if(BCD0 == 4'd0 && BCD1 !== 4'd0) begin
                            BCD0 <= 4'd9;
                            BCD1 <= BCD1 - 4'd1;
                        end
                    end
       
                    if(BCD0 == 4'd1 && BCD1 == 4'd0 && pb_de_dir == 1'b1) min <= 1'b1;
                    else min <= 1'b0;                    
                    
                    if(BCD0 == 4'd8 && BCD1 == 4'd9 && pb_de_dir == 1'b0) max <= 1'b1;
                    else max <= 1'b0;   
                end                              
            end
        end
    end
    
    //===============================================
    
    always @(*) begin
        case (frequency)
            2'b00: begin
                value <= BCD0;
                DIGIT <= 4'b1110;
            end
            2'b01: begin
                value <= BCD1;
                DIGIT <= 4'b1101;
            end
            2'b10: begin
                value <= (resume == 1'b0) ? 4'd11 : ((pb_de_dir == 1'b0) ? 4'd11 : 4'd12);
                DIGIT <= 4'b1011;
            end
            2'b11: begin
                value <= (speed == 2'd2) ? 4'd2 : ((speed == 2'd1) ? 4'd1 : 4'd0);
                DIGIT <= 4'b0111;
            end
            default: begin
                value <= BCD0;
                DIGIT <= 4'b1110;
            end
        endcase
    end
    
    //===============================================
    
    always @* begin
        case (value)
            4'd0: DISPLAY = 7'b1000000;
            4'd1: DISPLAY = 7'b1111001;
            4'd2: DISPLAY = 7'b0100100;
            4'd3: DISPLAY = 7'b0110000;
            4'd4: DISPLAY = 7'b0011001;
            4'd5: DISPLAY = 7'b0010010;
            4'd6: DISPLAY = 7'b0000010;
            4'd7: DISPLAY = 7'b1111000;
            4'd8: DISPLAY = 7'b0000000;
            4'd9: DISPLAY = 7'b0010000;
            4'd11: DISPLAY = 7'b1011100; // up arrow
            4'd12: DISPLAY = 7'b1100011; // down arrow
            default: DISPLAY = 7'b1111111;
        endcase
    end
    
    //===============================================
endmodule










