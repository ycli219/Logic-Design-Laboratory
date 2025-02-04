`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/04 19:21:23
// Design Name: 
// Module Name: lab5
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

module clock_divider( //clock of 100Hz  代表0.01秒
    input clk,
    output wire clk_div
    );
    
    reg [19:0] cnt;
    parameter n = 20;
    
    always @(posedge clk) begin
        if(cnt < 1000000-1'b1) begin
            cnt <= cnt + 1'b1;
        end else begin
            cnt <= 20'd0;
        end
    end
    assign clk_div = cnt[n-1];
endmodule

//=========================================

module lab5(
    input clk,
    input rst,
    input BTNL,
    input BTNR,
    input BTNU,
    input BTND,
    input BTNC,
    output reg [15:0] LED,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY
    );
    
    //=========================================
    
    wire global_clk;
    clock_divider m1(clk,global_clk);
    
    wire pb_de_BTNL;
    wire pb_de_BTNR;
    wire pb_de_BTNU;
    wire pb_de_BTND;
    wire pb_de_BTNC;
    
    debounce U1(pb_de_BTNL , BTNL , global_clk);
    debounce U2(pb_de_BTNR , BTNR , global_clk);
    debounce U3(pb_de_BTNU , BTNU , global_clk);
    debounce U4(pb_de_BTND , BTND , global_clk);
    debounce U5(pb_de_BTNC , BTNC , global_clk);
    
    wire pulse_BTNL;
    wire pulse_BTNR;
    wire pulse_BTNU;
    wire pulse_BTND;
    wire pulse_BTNC;
    
    onepulse W1(pb_de_BTNL , global_clk , pulse_BTNL);
    onepulse W2(pb_de_BTNR , global_clk , pulse_BTNR);
    onepulse W3(pb_de_BTNU , global_clk , pulse_BTNU);
    onepulse W4(pb_de_BTND , global_clk , pulse_BTND);
    onepulse W5(pb_de_BTNC , global_clk , pulse_BTNC);
    
    //=========================================
    
    reg [19:0] frequency_cnt = 20'd0;
    wire [1:0] frequency;
    
    always@(posedge clk) begin
        frequency_cnt <= frequency_cnt + 20'd1;
    end    
    
    assign frequency = frequency_cnt[19:18];
    
    //=========================================
    
    reg [3:0] BCD0 = 4'd15; //global variables definition !
    reg [3:0] BCD1 = 4'd15;
    reg [3:0] BCD2 = 4'd15;
    reg [3:0] BCD3 = 4'd15;
    reg [3:0] type;
    reg [3:0] amount;
    reg [5:0] price;
    reg [5:0] deposite;
    reg [5:0] changes;
    reg [9:0] counter = 10'd0; // 算flashing的 算到100 代表1秒
    reg flashing = 1'b0; // 控制LED亮暗
    
    reg [12:0] count_5sec = 13'd0;
    
    reg [3:0] states = 4'd0;
    reg [3:0] states_next;
    reg [3:0] value;
    
    //=========================================
    
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
                value <= BCD2;
                DIGIT <= 4'b1011;
            end
            2'b11: begin
                value <= BCD3;
                DIGIT <= 4'b0111;
            end
            default: begin
                value <= BCD0;
                DIGIT <= 4'b1110;
            end
        endcase
    end
    
    //=========================================
    
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
            4'd11: DISPLAY = 7'b0111111; // dash
            4'd12: DISPLAY = 7'b0001000; // A
            4'd13: DISPLAY = 7'b1000110; // C
            4'd14: DISPLAY = 7'b0010010; // S
            4'd15: DISPLAY = 7'b1111111; // 全暗
            default: DISPLAY = 7'b1111111;
        endcase
    end
    
    //=========================================
    
    always @(posedge clk) begin
        states <= states_next;
    end
    
    always @(posedge rst or posedge global_clk) begin
        if(rst == 1'b1) begin
            counter <= 10'd0;
            flashing <= 1'b1;
            states_next <= 4'd0;
            
            LED <= 16'b0000000000000000;
            BCD0 <= 4'd15;
            BCD1 <= 4'd15;
            BCD2 <= 4'd15;
            BCD3 <= 4'd15;
        end else begin
            case(states)
                4'd0: begin // idle
                    if(pulse_BTNL == 1'b1) begin // child (go to type)
                        states_next <= 4'd1;
                        type <= 4'd13;
                    end else if(pulse_BTNC == 1'b1) begin // student (go to type)
                        states_next <= 4'd1;
                        type <= 4'd14;
                    end else if(pulse_BTNR == 1'b1) begin // adult (go to type)
                        states_next <= 4'd1;
                        type <= 4'd12;
                    end else begin
                        states_next <= 4'd0;
                    end
                    
                    if(counter == 100) begin
                        counter <= 0;
                        flashing <= ~flashing;
                    end
                    else counter <= counter + 1;
                    
                    if(flashing == 1'b1) begin
                        BCD0 = 4'd11;
                        BCD1 = 4'd11;
                        BCD2 = 4'd11;
                        BCD3 = 4'd11;
                        LED <= 16'b1111111111111111;
                    end else begin
                        BCD0 = 4'd15;
                        BCD1 = 4'd15;
                        BCD2 = 4'd15;
                        BCD3 = 4'd15;
                        LED <= 16'b0000000000000000;
                    end
                end
                
                4'd1: begin // type
                    if(pulse_BTNU == 1'b1) begin // go to amount
                        states_next <= 4'd2;
                        amount <= 4'd1;
                    end else if(pulse_BTND == 1'b1) begin // go to idle
                        states_next <= 4'd0;
                        counter <= 10'd0;
                        flashing <= 1'b1;
                    end else begin
                        states_next <= 4'd1;
                        if(pulse_BTNL == 1'b1) begin // child
                            type <= 4'd13;
                        end else if(pulse_BTNC == 1'b1) begin // student
                            type <= 4'd14;
                        end else if(pulse_BTNR == 1'b1) begin // adult
                            type <= 4'd12;
                        end
                    end
                    
                    LED <= 16'b0000000000000000;
                    if(type == 4'd13) begin
                        BCD0 = 4'd5;
                        BCD1 = 4'd0;
                    end else if(type == 4'd14) begin
                        BCD0 = 4'd0;
                        BCD1 = 4'd1;
                    end else if(type == 4'd12) begin
                        BCD0 = 4'd5;
                        BCD1 = 4'd1;
                    end
                    BCD2 = 4'd15;
                    BCD3 = type;
                end
                
                4'd2: begin // amount
                    if(pulse_BTNU == 1'b1) begin // go to payment
                        states_next <= 4'd3;
                        deposite <= 6'd0;
                        if(type == 4'd12) price <= 15 * amount;
                        else if(type == 4'd13) price <= 5 * amount;
                        else if(type == 4'd14) price <= 10 * amount;
                    end else if(pulse_BTND == 1'b1) begin // go to idle
                        states_next <= 4'd0;
                        counter <= 10'd0;
                        flashing <= 1'b1;
                    end else begin
                        states_next <= 4'd2;
                        if(pulse_BTNL == 1'b1) begin // -
                            if(amount > 4'd1) amount <= amount - 1;
                        end else if(pulse_BTNR == 1'b1) begin // +
                            if(amount < 4'd3) amount <= amount + 1;
                        end
                    end
                    
                    BCD0 <= amount;
                    BCD1 <= 4'd15;
                    BCD2 <= 4'd15;
                    BCD3 <= type;
                end
                
                4'd3: begin // payment
                    if(deposite >= price) begin // go to release
                        states_next <= 4'd4;
                        changes <= deposite - price;
                        counter <= 10'd0;
                        flashing <= 1'b1;
                        count_5sec <= 13'd0;
                    end else if(pulse_BTND == 1'b1) begin // go to change
                        states_next <= 4'd5;
                        changes <= deposite;
                        counter <= 0;
                    end else begin
                        states_next <= 4'd3;
                        if(pulse_BTNL == 1'b1) begin // +1
                            deposite <= deposite + 1;
                        end else if(pulse_BTNC == 1'b1) begin // +5
                            deposite <= deposite + 5;
                        end else if(pulse_BTNR == 1'b1) begin // +10
                            deposite <= deposite + 10;
                        end
                    end
                    
                    BCD0 <= price % 10;
                    BCD1 <= price / 10;
                    BCD2 <= deposite % 10;
                    BCD3 <= deposite / 10;
                end
                
                4'd4: begin // release
                    if(counter == 100) begin
                        counter <= 0;
                        flashing <= ~flashing;
                    end
                    else counter <= counter + 1;
                    
                    if(flashing == 1'b1) LED <= 16'b1111111111111111;
                    else LED <= 16'b0000000000000000;
                    
                    
                    if(count_5sec >= 500) begin // go to change
                        states_next <= 4'd5;
                        counter <= 0;
                    end else begin
                        states_next <= 4'd4;
                    end
                    
                    count_5sec <= count_5sec + 1;
                    
                    BCD0 <= amount;
                    BCD1 <= 4'd15;
                    BCD2 <= 4'd15;
                    BCD3 <= type;
                end
                
                4'd5: begin // change
                    LED <= 16'b0000000000000000;
                    BCD0 <= changes % 10;
                    BCD1 <= changes / 10;
                    BCD2 <= 4'd15;
                    BCD3 <= 4'd15;
                    
                    if(changes == 0) begin // go to idle
                        if(counter == 100) begin
                            states_next <= 4'd0;
                            counter <= 10'd0;
                            flashing <= 1'b1;
                        end else states_next <= 4'd5;
                    end else begin
                        if(counter == 100) begin
                            if(changes >= 5) changes <= changes - 5;
                            else if(changes >= 1) changes <= changes - 1;
                        end
                        states_next <= 4'd5;
                    end
                    
                    if(counter == 100) counter <= 0;
                    else counter <= counter + 1;
                end
                
                4'd6: begin
                    if(counter == 100) begin
                        states_next <= 4'd0;
                        counter <= 0;
                        flashing <= 1'b0;
                    end else begin
                        states_next <= 4'd6;
                        counter <= counter + 1;
                    end
                    LED <= 16'b1111111111111111;
                    BCD0 <= 4'd11;
                    BCD1 <= 4'd11;
                    BCD2 <= 4'd11;
                    BCD3 <= 4'd11;
                end
                
                default: begin
                    states_next <= 4'd6;
                    counter <= 0;
                    LED <= 16'b1111111111111111;
                    BCD0 <= 4'd11;
                    BCD1 <= 4'd11;
                    BCD2 <= 4'd11;
                    BCD3 <= 4'd11;
                end
            endcase
        end
    end
endmodule