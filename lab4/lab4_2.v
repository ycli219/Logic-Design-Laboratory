`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/25 02:16:14
// Design Name: 
// Module Name: lab4_2
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


module clock_divider(
    input clk,
    output wire clk_div
    );
    
    reg [23:0] cnt;
    parameter n = 24;
    
    always @(posedge clk) begin
        if(cnt < 10000000-1'b1) begin
            cnt <= cnt + 1'b1;
        end else begin
            cnt <= 24'd0;
        end
    end
    assign clk_div = cnt[n-1];
endmodule


module lab4_2 (
    input clk,
    input rst,
    input en,
    input input_number, //
    input enter, // 
    input count_down, //
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output wire led0
    );
    
    wire global_clk;
    clock_divider m2(clk,global_clk);
    
    //===============================================debounce
    
    wire pb_de_input_number;
    wire pb_de_enter;
    wire pb_de_count_down;
    
    debounce U2(pb_de_input_number , input_number , clk);
    debounce U3(pb_de_enter , enter , clk);
    debounce U4(pb_de_count_down , count_down , clk);
    
    //===============================================one pulse
    
    wire pulse_input_number;
    wire pulse_enter;
    wire pulse_count_down;
    
    onepulse W2(pb_de_input_number , global_clk , pulse_input_number);
    onepulse W3(pb_de_enter , clk , pulse_enter);
    onepulse W4(pb_de_count_down , clk , pulse_count_down);
    
    //===============================================
    
    reg [19:0] frequency_cnt = 20'd0;
    wire [1:0] frequency;
    
    always@(posedge clk) begin
        frequency_cnt <= frequency_cnt + 20'd1;
    end    
    
    assign frequency = frequency_cnt[19:18];
    
    //===============================================
    
    reg [3:0] BCD0 = 4'd11;
    reg [3:0] BCD1 = 4'd11;
    reg [3:0] BCD2 = 4'd11;
    reg [3:0] BCD3 = 4'd11;
    
    reg [3:0] record0;
    reg [3:0] record1;
    reg [3:0] record2;
    reg [3:0] record3;
    
    reg [3:0] states = 4'd0;
    reg [3:0] states_next;
    reg [3:0] value;
    reg resume; // count state palse or not
    reg count_up = 1'b1; // counting up or down
    
    reg [2:0] enter_time = 3'd0;
    
    assign led0 = (count_up == 1'b1) ? 1'b0 : 1'b1;
    
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
            4'd11: DISPLAY = 7'b0111111; // dash
            default: DISPLAY = 7'b1111111;
        endcase
    end
    
    //===============================================
    
    always@(posedge clk or posedge rst) begin
        if(rst == 1'b1) begin // direction setting state
            states <= 4'd0;
            count_up <= 1'b1;
            enter_time <= 3'd0;
        end else begin
            if(en == 1'b0) resume <= 1'b0; // when counting state , pause
            else resume <= 1'b1;
            
            if(pulse_count_down == 1'b1 && states == 4'd0) count_up <= ~count_up;
            
            if(pulse_enter == 1'b1) enter_time <= enter_time + 1'b1;
            
            states <= states_next;
        end  
    end
    
    //===============================================
    
    
    
    always @(posedge global_clk) begin
        case (states)
            4'd0: begin //direction setting state
                if(enter_time == 3'd1) begin
                    states_next <= 4'd1;
                    BCD0 <= 4'd0;
                    BCD1 <= 4'd0;
                    BCD2 <= 4'd0;
                    BCD3 <= 4'd0;
                end else begin
                    states_next <= 4'd0;
                    BCD0 <= 4'd11;
                    BCD1 <= 4'd11;
                    BCD2 <= 4'd11;
                    BCD3 <= 4'd11;
                end
            end
            
            4'd1: begin //number setting state
                if(enter_time == 3'd1) begin
                    if(pulse_input_number == 1'b1) begin
                        if(BCD3 == 4'd1) BCD3 <= 4'd0;
                        else BCD3 <= BCD3 + 1'd1;
                    end else begin
                        BCD3 <= BCD3;
                    end
                    BCD0 <= 4'd0;
                    BCD1 <= 4'd0;
                    BCD2 <= 4'd0;
                    states_next <= 4'd1;
                    record3 <= BCD3;
                end else if(enter_time == 3'd2) begin
                    if(pulse_input_number == 1'b1) begin
                        if(BCD2 == 4'd5) BCD2 <= 4'd0;
                        else BCD2 <= BCD2 + 1'd1;
                    end else begin
                        BCD2 <= BCD2;
                    end
                    BCD0 <= 4'd0;
                    BCD1 <= 4'd0;
                    BCD3 <= BCD3;
                    states_next <= 4'd1;
                    record2 <= BCD2;
                end else if(enter_time == 3'd3) begin
                    if(pulse_input_number == 1'b1) begin
                        if(BCD1 == 4'd9) BCD1 <= 4'd0;
                        else BCD1 <= BCD1 + 1'd1;
                    end else begin
                        BCD1 <= BCD1;
                    end
                    BCD0 <= 4'd0;
                    BCD2 <= BCD2;
                    BCD3 <= BCD3;
                    states_next <= 4'd1;
                    record1 <= BCD1;
                end else if(enter_time == 3'd4) begin
                    if(pulse_input_number == 1'b1) begin
                        if(BCD0 == 4'd9) BCD0 <= 4'd0;
                        else BCD0 <= BCD0 + 1'd1;
                    end else begin
                        BCD0 <= BCD0;
                    end
                    BCD1 <= BCD1;
                    BCD2 <= BCD2;
                    BCD3 <= BCD3;
                    states_next <= 4'd1;
                    record0 <= BCD0;
                end else if(enter_time == 3'd5) begin
                    states_next <= 4'd2;
                    if(count_up == 1'b1) begin
                        BCD0 <= 4'd0;
                        BCD1 <= 4'd0;
                        BCD2 <= 4'd0;
                        BCD3 <= 4'd0;
                    end else if(count_up == 1'b0) begin
                        BCD0 <= BCD0;
                        BCD1 <= BCD1;
                        BCD2 <= BCD2;
                        BCD3 <= BCD3;
                    end
                end
            end
            
            4'd2: begin //ccounting state
                states_next <= 4'd2;
                if(resume == 1'b1) begin //count
                    if(count_up == 1'b1) begin // up
                        if((BCD0 == record0) && (BCD1 == record1) && (BCD2 == record2) && (BCD3 == record3)) begin
                            BCD0 <= BCD0;
                            BCD1 <= BCD1;
                            BCD2 <= BCD2;
                            BCD3 <= BCD3;
                        end else begin
                            if(BCD0 !== 4'd9) begin
                                BCD0 <= BCD0 +1'd1;
                                BCD1 <= BCD1;
                                BCD2 <= BCD2;
                                BCD3 <= BCD3;
                            end else begin
                                if(BCD1 !== 4'd9) begin
                                    BCD0 <= 4'd0;
                                    BCD1 <= BCD1 + 1'd1;
                                    BCD2 <= BCD2;
                                    BCD3 <= BCD3;
                                end else begin
                                    if(BCD2 !== 4'd5) begin
                                        BCD0 <= 4'd0;
                                        BCD1 <= 4'd0;
                                        BCD2 <= BCD2 + 1'd1;
                                        BCD3 <= BCD3;
                                    end else begin
                                        if(BCD3 !== 4'd1) begin
                                            BCD0 <= 4'd0;
                                            BCD1 <= 4'd0;
                                            BCD2 <= 4'd0;
                                            BCD3 <= BCD3 + 1'd1;
                                        end
                                    end
                                end
                            end
                        end
                    end else if(count_up == 1'b0) begin // down
                        if((BCD0 == 4'd0) && (BCD1 == 4'd0) && (BCD2 == 4'd0) && (BCD3 == 4'd0)) begin
                            BCD0 <= BCD0;
                            BCD1 <= BCD1;
                            BCD2 <= BCD2;
                            BCD3 <= BCD3;
                        end else begin
                            if(BCD0 !== 4'd0) begin
                                BCD0 <= BCD0 - 1'd1;
                                BCD1 <= BCD1;
                                BCD2 <= BCD2;
                                BCD3 <= BCD3;
                            end else begin
                                if(BCD1 !== 4'd0) begin
                                    BCD0 <= 4'd9;
                                    BCD1 <= BCD1 - 1'd1;
                                    BCD2 <= BCD2;
                                    BCD3 <= BCD3;
                                end else begin
                                    if(BCD2 !== 4'd0) begin
                                        BCD0 <= 4'd9;
                                        BCD1 <= 4'd9;
                                        BCD2 <= BCD2 - 1'd1;
                                        BCD3 <= BCD3;
                                    end else begin
                                        if(BCD3 !== 4'd0) begin
                                            BCD0 <= 4'd9;
                                            BCD1 <= 4'd9;
                                            BCD2 <= 4'd5;
                                            BCD3 <= BCD3 - 1'd1;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end else if(resume == 1'b0) begin //pause
                    BCD0 <= BCD0;
                    BCD1 <= BCD1;
                    BCD2 <= BCD2;
                    BCD3 <= BCD3;
                end
            end
            
            default: begin
                states_next <= 4'd0;
                BCD0 <= 4'd11;
                BCD1 <= 4'd11;
                BCD2 <= 4'd11;
                BCD3 <= 4'd11;
            end
        endcase
    end
endmodule
