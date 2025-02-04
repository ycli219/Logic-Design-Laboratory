`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/29 13:56:49
// Design Name: 
// Module Name: lab2_2
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


module lab2_2(
    input clk,
    input rst,
    input carA,
    input carB,
    output reg [2:0] lightA,
    output reg [2:0] lightB);
    parameter [5:0] AG_BR = 6'b001100;
    parameter [5:0] AY_BR = 6'b010100;
    parameter [5:0] AR_BG = 6'b100001;
    parameter [5:0] AR_BY = 6'b100010;
    reg [5:0] state;
    reg [5:0] next_state;
    reg [31:0] count;
    
    /*always @(posedge clk or posedge rst) begin
        if(rst == 1'b1) begin
            state = AG_BR;
            count = 0;
        end else begin
            case (state)
                AG_BR: begin
                    if({carA,carB} == 2'b11 || {carA,carB} == 2'b10 || {carA,carB} == 2'b00) begin
                        count = count + 1;
                        state = AG_BR;
                    end else if({carA,carB} == 2'b01) begin
                        if(count >= 2) begin
                            state = AY_BR;
                        end else begin
                            count = count + 1;
                            state = AG_BR;
                        end
                    end
                end
                
                AY_BR: begin
                    state = AR_BG;
                    count = 0;
                end
                
                AR_BG: begin
                    if({carA,carB} == 2'b11 || {carA,carB} == 2'b01 || {carA,carB} == 2'b00) begin
                        count = count + 1;
                        state = AR_BG;
                    end else if({carA,carB} == 2'b10) begin
                        if(count >= 2) begin
                            state = AR_BY;
                        end else begin
                            count = count + 1;
                            state = AR_BG;
                        end
                    end
                end
                
                AR_BY: begin
                    count = 0;
                    state = AG_BR;
                end
            endcase
        end
    end
    
    always @(state) begin
        case(state)
            AG_BR: begin {lightA , lightB} = AG_BR; end
            AY_BR: begin {lightA , lightB} = AY_BR; end
            AR_BG: begin {lightA , lightB} = AR_BG; end
            AR_BY: begin {lightA , lightB} = AR_BY; end
        endcase
    end*/
    
    always @* begin
        case (state)
            AG_BR: begin
                if( {carA,carB} == 2'b11 || {carA,carB} == 2'b10 || {carA,carB} == 2'b00 ) begin
                    next_state = AG_BR;
                end else if ( {carA,carB} == 2'b01 ) begin
                    if ( count >= 2 ) begin
                        next_state = AY_BR;
                        count = 0;
                    end else begin
                        next_state = AG_BR;
                    end
                end
            end
            
            AY_BR: begin
                next_state = AR_BG;
                count = 0;
            end
            
            AR_BG: begin
                if( {carA,carB} == 2'b11 || {carA,carB} == 2'b01 || {carA,carB} == 2'b00 ) begin
                    next_state = AR_BG;
                end else if ( {carA,carB} == 2'b10 ) begin
                    if ( count >= 2 ) begin
                        next_state = AR_BY;
                        count = 0;
                    end else begin
                        next_state = AR_BG;
                    end
                end
            end
            
            AR_BY: begin
                next_state = AG_BR;
                count = 0;
            end
        endcase
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst == 1'b1) begin
            state = AG_BR;
            {lightA , lightB} = AG_BR;
            count = 1;
        end else begin
            count = count + 1;
            state = next_state;
            {lightA , lightB} = next_state;
        end
    end
    
endmodule
