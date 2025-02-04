`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/19 15:57:41
// Design Name: 
// Module Name: lab6
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

//=============================================== clock_divider

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

//=============================================== lab06

module lab06(
    input wire clk,
    input wire rst,
    inout wire PS2_CLK,
    inout wire PS2_DATA,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output wire [15:0] LED
    );
    //=============================================== clock
    
    wire global_clk;
    clock_divider #(26) m1(clk , global_clk);
    
    reg [19:0] frequency_cnt = 20'd0;
    wire [1:0] frequency;
    always@(posedge clk) begin
        frequency_cnt <= frequency_cnt + 20'd1;
    end
    assign frequency = frequency_cnt[19:18];
    
    //=============================================== variables
    
    reg [3:0] value;
    
    reg [3:0] states = 4'd0;
    reg [3:0] states_next;
    
    reg [1:0] B1_passenger = 2'd0;
    reg [1:0] B2_passenger = 2'd0;
    reg [1:0] passenger_on_bus = 2'd0;
    
    reg [1:0] B1_passenger_v2 = 2'b00;
    reg [1:0] B2_passenger_v2 = 2'b00;
    
    reg getoff_bus = 1'b0;
    reg geton_bus = 1'b0;
    reg up_hill = 1'b1;
    reg pay_ornot = 1'b0;
    
    wire [1:0] B1_LED;
    wire [1:0] B2_LED;
    wire [1:0] bus_LED;
    reg [6:0] bus_location = 7'b0000001;
    
    reg [4:0] gas = 5'd0;
    reg [6:0] revenue = 7'd0;
    reg minus_gas = 1'b1;
    
    //=============================================== LED
    
    assign B1_LED = ( B1_passenger_v2 == 2'b11 ) ? 2'b11 : ( (B1_passenger_v2 == 2'b10) ? 2'b10 : 2'b00 );
    assign B2_LED = ( B2_passenger_v2 == 2'b11 ) ? 2'b11 : ( (B2_passenger_v2 == 2'b10) ? 2'b10 : 2'b00 );
    assign bus_LED = ( passenger_on_bus == 2'b11 ) ? 2'b11 : ( (passenger_on_bus == 2'b10) ? 2'b10 : 2'b00 );
    assign LED = { B1_LED , 1'b0 , B2_LED , bus_LED , 2'b00 , bus_location };
    
    //=============================================== 7-segment
    
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
            default: DISPLAY = 7'b1000000;
        endcase
    end
    
    always @(*) begin
        case (frequency)
            2'b00: begin
                value <= revenue % 10;
                DIGIT <= 4'b1110;
            end
            2'b01: begin
                value <= revenue / 10;
                DIGIT <= 4'b1101;
            end
            2'b10: begin
                value <= gas % 10;
                DIGIT <= 4'b1011;
            end
            2'b11: begin
                value <= gas / 10;
                DIGIT <= 4'b0111;
            end
            default: begin
                value <= revenue % 10;
                DIGIT <= 4'b1110;
            end
        endcase
    end
    
    //=============================================== keyboard
    
    wire [511:0] key_down;
	wire [8:0] last_change;
	reg [3:0] key_num;
	wire been_ready;
    
    parameter [8:0] KEY_CODES [0:19] = {
		9'b0_0100_0101,	// 0 => 45
		9'b0_0001_0110,	// 1 => 16
		9'b0_0001_1110,	// 2 => 1E
		9'b0_0010_0110,	// 3 => 26
		9'b0_0010_0101,	// 4 => 25
		9'b0_0010_1110,	// 5 => 2E
		9'b0_0011_0110,	// 6 => 36
		9'b0_0011_1101,	// 7 => 3D
		9'b0_0011_1110,	// 8 => 3E
		9'b0_0100_0110,	// 9 => 46
		
		9'b0_0111_0000, // right_0 => 70
		9'b0_0110_1001, // right_1 => 69
		9'b0_0111_0010, // right_2 => 72
		9'b0_0111_1010, // right_3 => 7A
		9'b0_0110_1011, // right_4 => 6B
		9'b0_0111_0011, // right_5 => 73
		9'b0_0111_0100, // right_6 => 74
		9'b0_0110_1100, // right_7 => 6C
		9'b0_0111_0101, // right_8 => 75
		9'b0_0111_1101  // right_9 => 7D
	};
	
	KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	always @* begin
		case (last_change)
			KEY_CODES[00] : key_num = 4'b0000;
			KEY_CODES[01] : key_num = 4'b0001;
			KEY_CODES[02] : key_num = 4'b0010;
			KEY_CODES[03] : key_num = 4'b0011;
			KEY_CODES[04] : key_num = 4'b0100;
			KEY_CODES[05] : key_num = 4'b0101;
			KEY_CODES[06] : key_num = 4'b0110;
			KEY_CODES[07] : key_num = 4'b0111;
			KEY_CODES[08] : key_num = 4'b1000;
			KEY_CODES[09] : key_num = 4'b1001;
			KEY_CODES[10] : key_num = 4'b0000;
			KEY_CODES[11] : key_num = 4'b0001;
			KEY_CODES[12] : key_num = 4'b0010;
			KEY_CODES[13] : key_num = 4'b0011;
			KEY_CODES[14] : key_num = 4'b0100;
			KEY_CODES[15] : key_num = 4'b0101;
			KEY_CODES[16] : key_num = 4'b0110;
			KEY_CODES[17] : key_num = 4'b0111;
			KEY_CODES[18] : key_num = 4'b1000;
			KEY_CODES[19] : key_num = 4'b1001;
			default		  : key_num = 4'b1111;
		endcase
	end
	
	//=============================================== change state
	
	always @(posedge clk) begin
        states <= states_next;
        
        if(states_next == 4'd7) begin
            B1_passenger_v2 <= 2'b00;
            B2_passenger_v2 <= 2'b00;
        end
        if(states == 4'd0) begin
            if(B1_passenger == 0) B1_passenger_v2 <= 2'b00;
            else if(B1_passenger == 1) B1_passenger_v2 <= B1_passenger_v2;
            B2_passenger_v2 <= B2_passenger_v2;
        end else if(states == 4'd6) begin
            if(B2_passenger == 0) B2_passenger_v2 <= 2'b00;
            else if(B2_passenger == 1) B2_passenger_v2 <= B2_passenger_v2;
            B1_passenger_v2 <= B1_passenger_v2;
        end
	    
        if(been_ready && key_down[last_change] == 1'b1) begin
                if(key_num != 4'b1111) begin
                    if(key_num == 4'b0001) begin
                        if(B1_passenger_v2 == 2'b11) B1_passenger_v2 <= 2'b11;
                        else if(B1_passenger_v2 == 2'b10) B1_passenger_v2 <= 2'b11;
                        else if(B1_passenger_v2 == 2'b00) B1_passenger_v2 <= 2'b10;
                    end else if(key_num == 4'b0010) begin
                        if(B2_passenger_v2 == 2'b11) B2_passenger_v2 <= 2'b11;
                        else if(B2_passenger_v2 == 2'b10) B2_passenger_v2 <= 2'b11;
                        else if(B2_passenger_v2 == 2'b00) B2_passenger_v2 <= 2'b10;
                    end
                end
        end
    end
    
    //=============================================== FSM
    
    always @(posedge rst or posedge global_clk) begin
        if(rst == 1'b1) begin
            states_next <= 4'd7;
            B1_passenger <= 1;
            B2_passenger <= 1;
            passenger_on_bus <= 2'd0;
            getoff_bus <= 1'b0;
            geton_bus <= 1'b0;
            up_hill <= 1'b1;
            pay_ornot <= 1'b0;
            bus_location <= 7'b0000001;
            gas <= 5'd0;
            revenue <= 7'd0;
            minus_gas <= 1'b1;
        end else begin
            
                if(states == 4'd0) begin
                    up_hill <= 1;
                    states_next <= 4'd0;
                    bus_location <= 7'b0000001;
                    
                    if(minus_gas == 1'b0 && passenger_on_bus != 0) begin
                        if(passenger_on_bus == 2'b11) gas <= gas - 10;
                        else if(passenger_on_bus == 2'b10) gas <= gas - 5;
                        minus_gas <= 1'b1;
                    end else begin
                        minus_gas <= 1'b1;
                        if( passenger_on_bus != 0 && getoff_bus == 0 ) begin // 車上有人 ， 還沒下過車
                            if(passenger_on_bus == 2'b11) passenger_on_bus <= 2'b10;
                            else if(passenger_on_bus == 2'b10) passenger_on_bus <= 2'b00;
                            
                            if( passenger_on_bus == 0 ) getoff_bus <= 1; // 下過車了
                        end else begin
                            getoff_bus <= 1; // 本來就沒乘客 ， 也是下過車了
                            if( B1_passenger_v2 != 0 && geton_bus == 0 ) begin // 有人在等車 ， 還沒上過車
                                passenger_on_bus <= B1_passenger_v2;
                                B1_passenger <= 0;
                                geton_bus <= 1; // 上過車了
                            end else begin
                                B1_passenger <= 1;
                                if( geton_bus == 1'b1 && pay_ornot == 1'b0) begin // 真的有乘客上車 ， 還沒付錢
                                    if(passenger_on_bus == 2'b11) begin // 付錢
                                        if(revenue + 60 >= 90) revenue <= 90;
                                        else revenue <= revenue + 60;
                                    end else if(passenger_on_bus == 2'b10) begin
                                        if(revenue + 30 >= 90) revenue <= 90;
                                        else revenue <= revenue + 30;
                                    end
                                    pay_ornot <= 1'b1; // 付過錢了
                                    
                                    if( gas < 20 ) states_next <= 4'd0;
                                    else states_next <= 4'd1;
                                end else begin
                                    if( pay_ornot == 1'b1 && gas < 20 ) begin // 付過錢了 ， 要加油
                                        revenue <= revenue - 10;
                                        if( gas + 10 >= 20 ) begin
                                            gas <= 20;
                                            states_next <= 4'd1;
                                        end else begin
                                            gas <= gas + 10;
                                            if( revenue >= 10 ) states_next <= 4'd0;
                                            else states_next <= 4'd1;
                                        end
                                    end else begin
                                        if( B2_passenger_v2 != 2'd0 ) states_next <= 4'd1;
                                    end
                                end
                            end
                        end
                    end
                end
                
                else if(states == 4'd1) begin
                    bus_location <= 7'b0000010;
                    if(up_hill == 1) states_next <= 4'd2;
                    else if(up_hill == 0) begin
                        states_next <= 4'd0;
                        getoff_bus <= 0;
                        geton_bus <= 0;
                        pay_ornot <= 0;
                        minus_gas <= 1'b0;
                    end
                end
                
                else if(states == 4'd2) begin
                    bus_location <= 7'b0000100;
                    if(up_hill == 1) begin
                        states_next <= 4'd3;
                        minus_gas <= 1'b0;
                    end
                    else if(up_hill == 0) states_next <= 4'd1;
                end
                
                else if(states == 4'd3) begin
                    bus_location <= 7'b0001000;
                    if(minus_gas == 1'b0 && passenger_on_bus != 0) begin
                        if(passenger_on_bus == 2'b11) gas <= gas - 10;
                        else if(passenger_on_bus == 2'b10) gas <= gas - 5;
                        minus_gas <= 1'b1;
                    end else begin
                        minus_gas <= 1'b1;
                        if( passenger_on_bus > 0 && revenue >= 10 && gas < 20 ) begin
                            revenue <= revenue - 10;
                            if( gas + 10 >= 20 ) begin
                                gas <= 20;
                                if(up_hill == 1) states_next <= 4'd4;
                                else if(up_hill == 0) states_next <= 4'd2;
                            end else begin
                                gas <= gas + 10;
                                if( revenue >= 10 ) states_next <= 4'd3;
                                else begin
                                    if(up_hill == 1) states_next <= 4'd4;
                                    else if(up_hill == 0) states_next <= 4'd2;
                                end
                            end
                        end else begin
                            if(up_hill == 1) states_next <= 4'd4;
                            else if(up_hill == 0) states_next <= 4'd2;
                        end
                    end
                end
                
                else if(states == 4'd4) begin
                    bus_location <= 7'b0010000;
                    if(up_hill == 1) states_next <= 4'd5;
                    else if(up_hill == 0) begin
                        states_next <= 4'd3;
                        minus_gas <= 1'b0;
                    end
                end
                
                else if(states == 4'd5) begin
                    bus_location <= 7'b0100000;
                    if(up_hill == 1) begin
                        states_next <= 4'd6;
                        getoff_bus <= 0;
                        geton_bus <= 0;
                        pay_ornot <= 0;
                        minus_gas <= 1'b0;
                    end
                    else if(up_hill == 0) states_next <= 4'd4;
                end
                
                else if(states == 4'd6) begin
                    up_hill <= 0;
                    states_next <= 4'd6;
                    bus_location <= 7'b1000000;
                    
                    if(minus_gas == 1'b0 && passenger_on_bus != 0) begin
                        if(passenger_on_bus == 2'b11) gas <= gas - 10;
                        else if(passenger_on_bus == 2'b10) gas <= gas - 5;
                        minus_gas <= 1'b1;
                    end else begin
                        minus_gas <= 1'b1;
                        if( passenger_on_bus != 0 && getoff_bus == 0 ) begin // 車上有人 ， 還沒下過車
                            if(passenger_on_bus == 2'b11) passenger_on_bus <= 2'b10;
                            else if(passenger_on_bus == 2'b10) passenger_on_bus <= 2'b00;
                            
                            if( passenger_on_bus == 0 ) getoff_bus <= 1; // 下過車了
                        end else begin
                            getoff_bus <= 1; // 本來就沒乘客 ， 也是下過車了
                            if( B2_passenger_v2 != 0 && geton_bus == 0 ) begin // 有人在等車 ， 還沒上過車
                                passenger_on_bus <= B2_passenger_v2;
                                B2_passenger <= 0;
                                geton_bus <= 1; // 上過車了
                            end else begin
                                B2_passenger <= 1;
                                if( geton_bus == 1 && pay_ornot == 0) begin // 真的有乘客上車 ， 還沒付錢
                                    if(passenger_on_bus == 2'b11) begin // 付錢
                                        if(revenue + 40 >= 90) revenue <= 90;
                                        else revenue <= revenue + 40;
                                    end else if(passenger_on_bus == 2'b10) begin
                                        if(revenue + 20 >= 90) revenue <= 90;
                                        else revenue <= revenue + 20;
                                    end
                                    pay_ornot <= 1; // 付過錢了
                                    
                                    if( gas < 20 ) states_next <= 4'd6;
                                    else states_next <= 4'd5;
                                end else begin
                                    if( pay_ornot == 1 && gas < 20 ) begin // 付過錢了 ， 要加油
                                        revenue <= revenue - 10;
                                        if( gas + 10 >= 20 ) begin
                                            gas <= 20;
                                            states_next <= 4'd5;
                                        end else begin
                                            gas <= gas + 10;
                                            if( revenue >= 10 ) states_next <= 4'd6;
                                            else states_next <= 4'd5;
                                        end
                                    end else begin
                                        if( B1_passenger_v2 != 0 ) states_next <= 4'd5;
                                    end
                                end
                            end
                        end
                    end
                end
                
                else begin
                    states_next <= 4'd0;
                    B1_passenger <= 1;
                    B2_passenger <= 1;
                    passenger_on_bus <= 0;
                    getoff_bus <= 0;
                    geton_bus <= 0;
                    up_hill <= 1;
                    pay_ornot <= 0;
                    bus_location <= 7'b0000001;
                    gas <= 0;
                    revenue <= 0;
                    minus_gas <= 1'b1;
                end
        end
    end
    
endmodule










