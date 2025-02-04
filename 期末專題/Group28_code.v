module demo_1(
   input clk,
   input rst,
   inout PS2_CLK, //有改
   inout PS2_DATA, //有改 
   input start, //有改
   output [3:0] vgaRed,
   output [3:0] vgaGreen,
   output [3:0] vgaBlue,
   output hsync,
   output vsync,
   output [3:0] DIGIT,
   output [6:0] DISPLAY
   //tput [15:0] led
   );

    wire clk_25MHz;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480
    
    
    parameter [12:0] color1 [0:13] = {
    12'h7d3, 12'h812, 12'hc50, 12'hb28, 12'h721, 12'h39e, 12'h888, 12'h546, 12'h753, 12'he49, 12'hb81, 12'h491, 12'hda5, 12'h903
    };
   
    parameter [12:0] color2 [0:13] = {
    12'h6c2, 12'h923, 12'hd61, 12'ha17, 12'h832, 12'h4af, 12'h889, 12'h657, 12'h864, 12'hf5a, 12'hc92, 12'h380, 12'hc94, 12'ha14
    };
    
    /*parameter [12:0] color2 [0:13] = {
    12'hfff, 12'hfff, 12'hfff, 12'hfff, 12'hfff, 12'hfff, 12'hfff, 12'hfff, 12'hfff, 12'hfff, 12'hfff, 12'hfff, 12'hfff, 12'hfff
    };*/
    
    reg [6:0] r;
    wire [6:0] rrr;
    wire [6:0] random;
    reg [2:0] level, level_next;
    wire [11:0] rand_color;
    wire [11:0] norm_color;
    
    wire [9:0] count;
    //reg [3:0] counter;
    
    //assign level = (counter <= 4'd2) ? (3'd2):( (counter <= 4'd5) ? (3'd3):( (counter <= 4'd8) ? (3'd4):( (counter <= 4'd11) ? (3'd5):(3'd6) ) ) );
    
    assign random = r%36;//(level == 3'd2) ? (r%4):( (level == 3'd3) ? (r%9):( (level == 3'd4) ? (r%16):( (level == 3'd5) ? (r%25) : (r%36) ) ) ); // 答案在哪個位置
    assign rand_color = color1[r%14];
    assign norm_color = color2[r%14];
    
    parameter [8:0] KEY_CODES [0:4] = {
		//9'b0_0010_1001,	// space => 29
		9'b0_0001_1100,	// 左 => 1C
		9'b0_0001_1101,	// 上 => 1D
		9'b0_0001_1011,	// 下 => 1B
		9'b0_0010_0011,	// 右 =>  23
		9'b0_0010_1001	// enter => 29
	};
	
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;
	reg [3:0] key_num;
	
	KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	always @ (*) begin
		case (last_change)
			KEY_CODES[00] : key_num = 4'b0000;
			KEY_CODES[01] : key_num = 4'b0001;
			KEY_CODES[02] : key_num = 4'b0010;
			KEY_CODES[03] : key_num = 4'b0011;
			KEY_CODES[04] : key_num = 4'b0100;
			//KEY_CODES[05] : key_num = 4'b0101;
			default: key_num = 4'b1111;
		endcase
	end
	
	reg [2:0] x_p;// = 3'd1;
	reg [2:0] y_p;// = 3'd1;
	
	reg enter;// = 1'd0;
	reg flag;// = 1'd0;
	
	reg level_change;
	
	/*
	always @(posedge clk) begin
	   if(rst) begin
	       level <= 2;
	   end else begin
	       level <= level_next;
	   end
	end*/
	/*
	always @* begin
	   if(count < 200) begin
	           level = 6;
	       end else if(count < 300) begin
	           level = 5;
	       end else if(count < 400) begin
	           level = 4;
	       end else if(count < 500) begin
	           level = 3;
	       end
	end*/
	
	
	always @(posedge clk or posedge rst) begin
	   if(rst == 1) begin
	       //prev_level <= 2;
	       //level_change <= 0;
	       level <= 3'd6;
	       flag <= 1'd0;
	       x_p <= 3'd0;
	       y_p <= 3'd0;
	       enter <= 0;
	       //counter <= 0;
	   end
	   else begin
	       //flag <= 0;
	       //enter <= 0;
	       //level <= (counter <= 4'd2) ? (3'd2):( (counter <= 4'd5) ? (3'd3):( (counter <= 4'd8) ? (3'd4):( (counter <= 4'd11) ? (3'd5):(3'd6) ) ) );
	       /*prev_level <= level;
	       if(count < 200) begin
	           level <= 6;
	       end else if(count < 300) begin
	           level <= 5;
	       end else if(count < 400) begin
	           level <= 4;
	       end else if(count < 500) begin
	           level <= 3;
	       end*/
	       if(been_ready && key_down[last_change] == 1'b1 && count != 0 && start == 1) begin
	           if(key_num != 4'b1111) begin
	               if(key_num == 4'b0000) begin //左
	                   if(x_p > 3'd0) x_p <= x_p - 1;
	               end
	               else if(key_num == 4'b0001) begin //上
	                   if(y_p > 3'd0) y_p <= y_p - 1;
	               end
	               else if(key_num == 4'b0010) begin //下
	                   if(level == 3'd2) begin
	                       if(y_p < 3'd1) y_p <= y_p + 1;
	                   end
	                   else if(level == 3'd3) begin
	                       if(y_p < 3'd2) y_p <= y_p + 1;
	                   end
	                   else if(level == 3'd4) begin
	                       if(y_p < 3'd3) y_p <= y_p + 1;
	                   end
	                   else if(level == 3'd5) begin
	                       if(y_p < 3'd4) y_p <= y_p + 1;
	                   end
	                   else if(level == 3'd6) begin
	                       if(y_p < 3'd5) y_p <= y_p + 1;
	                   end
	               end
	               else if(key_num == 4'b0011) begin //右
	                   if(level == 3'd2) begin
	                       if(x_p < 3'd1) x_p <= x_p + 1;
	                   end
	                   else if(level == 3'd3) begin
	                       if(x_p < 3'd2) x_p <= x_p + 1;
	                   end
	                   else if(level == 3'd4) begin
	                       if(x_p < 3'd3) x_p <= x_p + 1;
	                   end
	                   else if(level == 3'd5) begin
	                       if(x_p < 3'd4) x_p <= x_p + 1;
	                   end
	                   else if(level == 3'd6) begin
	                       if(x_p < 3'd5) x_p <= x_p + 1;
	                   end
	               end
	               else if(key_num == 4'b0100) begin //enter
	                   if(flag == 0) begin
	                       flag <= 1'b1;
	                       enter <= 1'b1;
	                       r <= rrr;
	                   end else if( (y_p*(level)) + x_p == random /*flag == 1*/) begin
                           enter <= 1'b1;
                           r <= rrr;
                           //if(level < 6) level_next <= level_next + 1;
                           //if(counter < 14) counter <= counter + 1;
                           //else counter <= counter;
                           //level <= level + 1;
	                   end /*else if(count < 200 && (y_p*6) + x_p == random ) begin
                           enter <= 1'b1;
                           r <= rrr;
                       end else if(count < 300 && (y_p*5) + x_p == random) begin
                           enter <= 1'b1;
                           r <= rrr;
                       end else if(count < 400 && (y_p*4) + x_p == random) begin
                           enter <= 1'b1;
                           r <= rrr;
                       end else if(count < 500 && (y_p*3) + x_p == random) begin
                           enter <= 1'b1;
                           r <= rrr;
                       end else if((y_p*2) + x_p == random) begin
                           enter <= 1'b1;
                           r <= rrr;
                       end*/
	                   else begin
	                       enter <= 0;
	                       r <= r;
	                   end
	               end
	           end
	       end else begin
	           enter <= 0;
	           x_p <= x_p;
	           y_p <= y_p;
	           flag <= flag;
	           //counter <= counter;
	       end
	   end
	end
    
    
    clock_divider clk_wiz_0_inst(
        .clk(clk),
        .clk1(clk_25MHz)
    );

    pixel_gen pixel_gen_inst(
        .clk(clk),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .valid(valid),
        .random(random), //有改
        .rand_color(rand_color), //有改
        .norm_color(norm_color), //有改
        .level(level), //有改
        .x_p(x_p),
        .y_p(y_p),
        .count(count),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue)
    );

    vga_controller vga_inst(
        .pclk(clk_25MHz),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );

    
    LFSR rand_gen(
        clk,
        rst,
        //enter,
        rrr
    );
    
    timer timer_display(
        clk,
        rst,
        start,
        count,
        DIGIT,
        DISPLAY
    );
    
endmodule


module LFSR(
    input wire clk,
    input wire rst,
    //input wire enter,
    output reg [6:0] random
    //output reg [15:0] led
    );
    
    //always @(posedge clk or posedge rst)
      //  begin if (rst == 1'b1) begin
        //    random[15:0] <= 16'b1010110011100001;
            //led <= 0;
        //end else /*if(enter == 1)*/ begin
        //    random[14:0] <= random[15:1];
        //    random[15] <= random[5] ^ (random[3] ^ (random[2] ^ random[0]));
            //led <= random;
        //end else begin
        //    random <= random;
        //end
    //end
    always @(posedge clk) begin
        random <= random + 1;
    end
    
    
endmodule


module decimal_clock_divider(
    input clk,
    output clock_100ms
    );
    reg c = 1;
    reg [23:0] cnt;
    wire [23:0] cnt_next;
    //initial c = 1;
    always @(posedge clk) begin
        cnt <= cnt_next;
        if(cnt == 4999999) c <= ~c;
        else c <= c;
    end
    
    assign cnt_next = ((cnt == 4999999) ? 0 : cnt + 1);
    assign clock_100ms = c;
endmodule


module clock_divider3 #(parameter n=25) (
    input clk,
    output clk_div);
    // add your design here
    reg [n-1:0] cnt, cnt_next;
    always @(posedge clk) begin
        cnt <= cnt_next;
    end
    
    always @* begin
        cnt_next = cnt + 1;
    end
    
    initial begin
        cnt = 1;
    end
    assign clk_div = cnt[n-1];
endmodule


module clock_divider(clk1, clk);
input clk;
output clk1;

reg [1:0] num;
wire [1:0] next_num;

always @(posedge clk) begin
  num <= next_num;
end

assign next_num = num + 1'b1;
assign clk1 = num[1];

endmodule


module pixel_gen(
   input clk,
   input [9:0] h_cnt,
   input [9:0] v_cnt,
   input valid,
   input [6:0] random, //有改
   input [11:0] rand_color, //有改
   input [11:0] norm_color, //有改
   input [2:0] level, //有改
   input [2:0] x_p, //有改
   input [2:0] y_p, //有改
   input [9:0] count,
   output reg [3:0] vgaRed,
   output reg [3:0] vgaGreen,
   output reg [3:0] vgaBlue
   );
   
   wire [9:0] h_center;
   wire [9:0] v_center;
   
    assign h_center = (x_p) * (640/level) + (320/level);
    assign v_center = (y_p) * (480/level) + (240/level);
    clock_divider3 #(.n(28)) cd28(clk, clk28);
    
    always @(*) begin
        if(!valid || (clk28 == 1 && count == 0)) begin
            {vgaRed, vgaGreen, vgaBlue} = 0;
        end
        else if( ((h_center-8 <= h_cnt) && (h_cnt < h_center+8)) && ((v_center-8 <= v_cnt) && (v_cnt < v_center+8)) ) begin
            {vgaRed, vgaGreen, vgaBlue} = 0;
        end
        else if(level == 3'd2) begin
            if( ((10<=h_cnt) && (h_cnt<310)) && ((10<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 0) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<310)) && ((250<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 2) ? rand_color : norm_color);
            end
            else if( ((330<=h_cnt) && (h_cnt<630)) && ((10<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 1) ? rand_color : norm_color);
            end
            else if( ((330<=h_cnt) && (h_cnt<630)) && ((250<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 3) ? rand_color : norm_color);
            end
            else begin
                {vgaRed, vgaGreen, vgaBlue} = 0;
            end
        end
        else if(level == 3'd3) begin
            if( ((10<=h_cnt) && (h_cnt<203)) && ((10<=v_cnt) && (v_cnt<150)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 0) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<203)) && ((170<=v_cnt) && (v_cnt<310)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 3) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<203)) && ((330<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 6) ? rand_color : norm_color);
            end
            else if( ((223<=h_cnt) && (h_cnt<416)) && ((10<=v_cnt) && (v_cnt<150)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 1) ? rand_color : norm_color);
            end
            else if( ((223<=h_cnt) && (h_cnt<416)) && ((170<=v_cnt) && (v_cnt<310)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 4) ? rand_color : norm_color);
            end
            else if( ((223<=h_cnt) && (h_cnt<416)) && ((330<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 7) ? rand_color : norm_color);
            end
            else if( ((436<=h_cnt) && (h_cnt<629)) && ((10<=v_cnt) && (v_cnt<150)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 2) ? rand_color : norm_color);
            end
            else if( ((436<=h_cnt) && (h_cnt<629)) && ((170<=v_cnt) && (v_cnt<310)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 5) ? rand_color : norm_color);
            end
            else if( ((436<=h_cnt) && (h_cnt<629)) && ((330<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 8) ? rand_color : norm_color);
            end
            else begin
                {vgaRed, vgaGreen, vgaBlue} = 0;
            end
        end
        else if(level == 3'd4) begin
            if( ((10<=h_cnt) && (h_cnt<150)) && ((10<=v_cnt) && (v_cnt<110)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 0) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<150)) && ((130<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 4) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<150)) && ((250<=v_cnt) && (v_cnt<350)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 8) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<150)) && ((370<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 12) ? rand_color : norm_color);
            end
            else if( ((170<=h_cnt) && (h_cnt<310)) && ((10<=v_cnt) && (v_cnt<110)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 1) ? rand_color : norm_color);
            end
            else if( ((170<=h_cnt) && (h_cnt<310)) && ((130<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 5) ? rand_color : norm_color);
            end
            else if( ((170<=h_cnt) && (h_cnt<310)) && ((250<=v_cnt) && (v_cnt<350)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 9) ? rand_color : norm_color);
            end
            else if( ((170<=h_cnt) && (h_cnt<310)) && ((370<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 13) ? rand_color : norm_color);
            end
            else if( ((330<=h_cnt) && (h_cnt<470)) && ((10<=v_cnt) && (v_cnt<110)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 2) ? rand_color : norm_color);
            end
            else if( ((330<=h_cnt) && (h_cnt<470)) && ((130<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 6) ? rand_color : norm_color);
            end
            else if( ((330<=h_cnt) && (h_cnt<470)) && ((250<=v_cnt) && (v_cnt<350)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 10) ? rand_color : norm_color);
            end
            else if( ((330<=h_cnt) && (h_cnt<470)) && ((370<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 14) ? rand_color : norm_color);
            end
            else if( ((490<=h_cnt) && (h_cnt<630)) && ((10<=v_cnt) && (v_cnt<110)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 3) ? rand_color : norm_color);
            end
            else if( ((490<=h_cnt) && (h_cnt<630)) && ((130<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 7) ? rand_color : norm_color);
            end
            else if( ((490<=h_cnt) && (h_cnt<630)) && ((250<=v_cnt) && (v_cnt<350)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 11) ? rand_color : norm_color);
            end
            else if( ((490<=h_cnt) && (h_cnt<630)) && ((370<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 15) ? rand_color : norm_color);
            end
            else begin
                {vgaRed, vgaGreen, vgaBlue} = 0;
            end
        end
        else if(level == 3'd5) begin
            if( ((10<=h_cnt) && (h_cnt<118)) && ((10<=v_cnt) && (v_cnt<86)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 0) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<118)) && ((106<=v_cnt) && (v_cnt<182)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 5) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<118)) && ((202<=v_cnt) && (v_cnt<278)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 10) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<118)) && ((298<=v_cnt) && (v_cnt<374)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 15) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<118)) && ((394<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 20) ? rand_color : norm_color);
            end
            else if( ((138<=h_cnt) && (h_cnt<246)) && ((10<=v_cnt) && (v_cnt<86)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 1) ? rand_color : norm_color);
            end
            else if( ((138<=h_cnt) && (h_cnt<246)) && ((106<=v_cnt) && (v_cnt<182)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 6) ? rand_color : norm_color);
            end
            else if( ((138<=h_cnt) && (h_cnt<246)) && ((202<=v_cnt) && (v_cnt<278)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 11) ? rand_color : norm_color);
            end
            else if( ((138<=h_cnt) && (h_cnt<246)) && ((298<=v_cnt) && (v_cnt<374)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 16) ? rand_color : norm_color);
            end
            else if( ((138<=h_cnt) && (h_cnt<246)) && ((394<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 21) ? rand_color : norm_color);
            end
            else if( ((266<=h_cnt) && (h_cnt<374)) && ((10<=v_cnt) && (v_cnt<86)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 2) ? rand_color : norm_color);
            end
            else if( ((266<=h_cnt) && (h_cnt<374)) && ((106<=v_cnt) && (v_cnt<182)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 7) ? rand_color : norm_color);
            end
            else if( ((266<=h_cnt) && (h_cnt<374)) && ((202<=v_cnt) && (v_cnt<278)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 12) ? rand_color : norm_color);
            end
            else if( ((266<=h_cnt) && (h_cnt<374)) && ((298<=v_cnt) && (v_cnt<374)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 17) ? rand_color : norm_color);
            end
            else if( ((266<=h_cnt) && (h_cnt<374)) && ((394<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 22) ? rand_color : norm_color);
            end
            else if( ((394<=h_cnt) && (h_cnt<502)) && ((10<=v_cnt) && (v_cnt<86)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 3) ? rand_color : norm_color);
            end
            else if( ((394<=h_cnt) && (h_cnt<502)) && ((106<=v_cnt) && (v_cnt<182)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 8) ? rand_color : norm_color);
            end
            else if( ((394<=h_cnt) && (h_cnt<502)) && ((202<=v_cnt) && (v_cnt<278)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 13) ? rand_color : norm_color);
            end
            else if( ((394<=h_cnt) && (h_cnt<502)) && ((298<=v_cnt) && (v_cnt<374)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 18) ? rand_color : norm_color);
            end
            else if( ((394<=h_cnt) && (h_cnt<502)) && ((394<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 23) ? rand_color : norm_color);
            end
            else if( ((522<=h_cnt) && (h_cnt<630)) && ((10<=v_cnt) && (v_cnt<86)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 4) ? rand_color : norm_color);
            end
            else if( ((522<=h_cnt) && (h_cnt<630)) && ((106<=v_cnt) && (v_cnt<182)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 9) ? rand_color : norm_color);
            end
            else if( ((522<=h_cnt) && (h_cnt<630)) && ((202<=v_cnt) && (v_cnt<278)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 14) ? rand_color : norm_color);
            end
            else if( ((522<=h_cnt) && (h_cnt<630)) && ((298<=v_cnt) && (v_cnt<374)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 19) ? rand_color : norm_color);
            end
            else if( ((522<=h_cnt) && (h_cnt<630)) && ((394<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 24) ? rand_color : norm_color);
            end
            else begin
                {vgaRed, vgaGreen, vgaBlue} = 0;
            end
        end
        else if(level == 3'd6) begin
            if( ((10<=h_cnt) && (h_cnt<96)) && ((10<=v_cnt) && (v_cnt<70)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 0) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<96)) && ((90<=v_cnt) && (v_cnt<150)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 6) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<96)) && ((170<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 12) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<96)) && ((250<=v_cnt) && (v_cnt<310)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 18) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<96)) && ((330<=v_cnt) && (v_cnt<390)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 24) ? rand_color : norm_color);
            end
            else if( ((10<=h_cnt) && (h_cnt<96)) && ((410<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 30) ? rand_color : norm_color);
            end
            else if( ((116<=h_cnt) && (h_cnt<202)) && ((10<=v_cnt) && (v_cnt<70)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 1) ? rand_color : norm_color);
            end
            else if( ((116<=h_cnt) && (h_cnt<202)) && ((90<=v_cnt) && (v_cnt<150)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 7) ? rand_color : norm_color);
            end
            else if( ((116<=h_cnt) && (h_cnt<202)) && ((170<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 13) ? rand_color : norm_color);
            end
            else if( ((116<=h_cnt) && (h_cnt<202)) && ((250<=v_cnt) && (v_cnt<310)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 19) ? rand_color : norm_color);
            end
            else if( ((116<=h_cnt) && (h_cnt<202)) && ((330<=v_cnt) && (v_cnt<390)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 25) ? rand_color : norm_color);
            end
            else if( ((116<=h_cnt) && (h_cnt<202)) && ((410<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 31) ? rand_color : norm_color);
            end
            else if( ((222<=h_cnt) && (h_cnt<308)) && ((10<=v_cnt) && (v_cnt<70)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 2) ? rand_color : norm_color);
            end
            else if( ((222<=h_cnt) && (h_cnt<308)) && ((90<=v_cnt) && (v_cnt<150)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 8) ? rand_color : norm_color);
            end
            else if( ((222<=h_cnt) && (h_cnt<308)) && ((170<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 14) ? rand_color : norm_color);
            end
            else if( ((222<=h_cnt) && (h_cnt<308)) && ((250<=v_cnt) && (v_cnt<310)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 20) ? rand_color : norm_color);
            end
            else if( ((222<=h_cnt) && (h_cnt<308)) && ((330<=v_cnt) && (v_cnt<390)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 26) ? rand_color : norm_color);
            end
            else if( ((222<=h_cnt) && (h_cnt<308)) && ((410<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 32) ? rand_color : norm_color);
            end
            else if( ((328<=h_cnt) && (h_cnt<414)) && ((10<=v_cnt) && (v_cnt<70)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 3) ? rand_color : norm_color);
            end
            else if( ((328<=h_cnt) && (h_cnt<414)) && ((90<=v_cnt) && (v_cnt<150)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 9) ? rand_color : norm_color);
            end
            else if( ((328<=h_cnt) && (h_cnt<414)) && ((170<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 15) ? rand_color : norm_color);
            end
            else if( ((328<=h_cnt) && (h_cnt<414)) && ((250<=v_cnt) && (v_cnt<310)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 21) ? rand_color : norm_color);
            end
            else if( ((328<=h_cnt) && (h_cnt<414)) && ((330<=v_cnt) && (v_cnt<390)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 27) ? rand_color : norm_color);
            end
            else if( ((328<=h_cnt) && (h_cnt<414)) && ((410<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 33) ? rand_color : norm_color);
            end
            else if( ((434<=h_cnt) && (h_cnt<520)) && ((10<=v_cnt) && (v_cnt<70)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 4) ? rand_color : norm_color);
            end
            else if( ((434<=h_cnt) && (h_cnt<520)) && ((90<=v_cnt) && (v_cnt<150)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 10) ? rand_color : norm_color);
            end
            else if( ((434<=h_cnt) && (h_cnt<520)) && ((170<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 16) ? rand_color : norm_color);
            end
            else if( ((434<=h_cnt) && (h_cnt<520)) && ((250<=v_cnt) && (v_cnt<310)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 22) ? rand_color : norm_color);
            end
            else if( ((434<=h_cnt) && (h_cnt<520)) && ((330<=v_cnt) && (v_cnt<390)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 28) ? rand_color : norm_color);
            end
            else if( ((434<=h_cnt) && (h_cnt<520)) && ((410<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 34) ? rand_color : norm_color);
            end
            else if( ((540<=h_cnt) && (h_cnt<626)) && ((10<=v_cnt) && (v_cnt<70)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 5) ? rand_color : norm_color);
            end
            else if( ((540<=h_cnt) && (h_cnt<626)) && ((90<=v_cnt) && (v_cnt<150)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 11) ? rand_color : norm_color);
            end
            else if( ((540<=h_cnt) && (h_cnt<626)) && ((170<=v_cnt) && (v_cnt<230)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 17) ? rand_color : norm_color);
            end
            else if( ((540<=h_cnt) && (h_cnt<626)) && ((250<=v_cnt) && (v_cnt<310)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 23) ? rand_color : norm_color);
            end
            else if( ((540<=h_cnt) && (h_cnt<626)) && ((330<=v_cnt) && (v_cnt<390)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 29) ? rand_color : norm_color);
            end
            else if( ((540<=h_cnt) && (h_cnt<626)) && ((410<=v_cnt) && (v_cnt<470)) ) begin
                {vgaRed, vgaGreen, vgaBlue} = ((random == 35) ? rand_color : norm_color);
            end
            else begin
                {vgaRed, vgaGreen, vgaBlue} = 0;
            end
        end
        else begin
            {vgaRed, vgaGreen, vgaBlue} = 0;
        end
   end
endmodule


module vga_controller (
    input wire pclk, reset,
    output wire hsync, vsync, valid,
    output wire [9:0]h_cnt,
    output wire [9:0]v_cnt
    );

    reg [9:0]pixel_cnt;
    reg [9:0]line_cnt;
    reg hsync_i,vsync_i;

    parameter HD = 640;
    parameter HF = 16;
    parameter HS = 96;
    parameter HB = 48;
    parameter HT = 800; 
    parameter VD = 480;
    parameter VF = 10;
    parameter VS = 2;
    parameter VB = 33;
    parameter VT = 525;
    parameter hsync_default = 1'b1;
    parameter vsync_default = 1'b1;

    always @(posedge pclk)
        if (reset)
            pixel_cnt <= 0;
        else
            if (pixel_cnt < (HT - 1))
                pixel_cnt <= pixel_cnt + 1;
            else
                pixel_cnt <= 0;

    always @(posedge pclk)
        if (reset)
            hsync_i <= hsync_default;
        else
            if ((pixel_cnt >= (HD + HF - 1)) && (pixel_cnt < (HD + HF + HS - 1)))
                hsync_i <= ~hsync_default;
            else
                hsync_i <= hsync_default; 

    always @(posedge pclk)
        if (reset)
            line_cnt <= 0;
        else
            if (pixel_cnt == (HT -1))
                if (line_cnt < (VT - 1))
                    line_cnt <= line_cnt + 1;
                else
                    line_cnt <= 0;

    always @(posedge pclk)
        if (reset)
            vsync_i <= vsync_default; 
        else if ((line_cnt >= (VD + VF - 1)) && (line_cnt < (VD + VF + VS - 1)))
            vsync_i <= ~vsync_default; 
        else
            vsync_i <= vsync_default; 

    assign hsync = hsync_i;
    assign vsync = vsync_i;
    assign valid = ((pixel_cnt < HD) && (line_cnt < VD));

    assign h_cnt = (pixel_cnt < HD) ? pixel_cnt : 10'd0;
    assign v_cnt = (line_cnt < VD) ? line_cnt : 10'd0;

endmodule


module KeyboardDecoder(
	output reg [511:0] key_down,
	output wire [8:0] last_change,
	output reg key_valid,
	inout wire PS2_DATA,
	inout wire PS2_CLK,
	input wire rst,
	input wire clk
    );
    
    parameter [1:0] INIT			= 2'b00;
    parameter [1:0] WAIT_FOR_SIGNAL = 2'b01;
    parameter [1:0] GET_SIGNAL_DOWN = 2'b10;
    parameter [1:0] WAIT_RELEASE    = 2'b11;
    
	parameter [7:0] IS_INIT			= 8'hAA;
    parameter [7:0] IS_EXTEND		= 8'hE0;
    parameter [7:0] IS_BREAK		= 8'hF0;
    
    reg [9:0] key;		// key = {been_extend, been_break, key_in}
    reg [1:0] state;
    reg been_ready, been_extend, been_break;
    
    wire [7:0] key_in;
    wire is_extend;
    wire is_break;
    wire valid;
    wire err;
    
    wire [511:0] key_decode = 1 << last_change;
    assign last_change = {key[9], key[7:0]};
    
    KeyboardCtrl_0 inst (
		.key_in(key_in),
		.is_extend(is_extend),
		.is_break(is_break),
		.valid(valid),
		.err(err),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	OnePulse op (
		.signal_single_pulse(pulse_been_ready),
		.signal(been_ready),
		.clock(clk)
	);
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		state <= INIT;
    		been_ready  <= 1'b0;
    		been_extend <= 1'b0;
    		been_break  <= 1'b0;
    		key <= 10'b0_0_0000_0000;
    	end else begin
    		state <= state;
			been_ready  <= been_ready;
			been_extend <= (is_extend) ? 1'b1 : been_extend;
			been_break  <= (is_break ) ? 1'b1 : been_break;
			key <= key;
    		case (state)
    			INIT : begin
    					if (key_in == IS_INIT) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready  <= 1'b0;
							been_extend <= 1'b0;
							been_break  <= 1'b0;
							key <= 10'b0_0_0000_0000;
    					end else begin
    						state <= INIT;
    					end
    				end
    			WAIT_FOR_SIGNAL : begin
    					if (valid == 0) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready <= 1'b0;
    					end else begin
    						state <= GET_SIGNAL_DOWN;
    					end
    				end
    			GET_SIGNAL_DOWN : begin
						state <= WAIT_RELEASE;
						key <= {been_extend, been_break, key_in};
						been_ready  <= 1'b1;
    				end
    			WAIT_RELEASE : begin
    					if (valid == 1) begin
    						state <= WAIT_RELEASE;
    					end else begin
    						state <= WAIT_FOR_SIGNAL;
    						been_extend <= 1'b0;
    						been_break  <= 1'b0;
    					end
    				end
    			default : begin
    					state <= INIT;
						been_ready  <= 1'b0;
						been_extend <= 1'b0;
						been_break  <= 1'b0;
						key <= 10'b0_0_0000_0000;
    				end
    		endcase
    	end
    end
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		key_valid <= 1'b0;
    		key_down <= 511'b0;
    	end else if (key_decode[last_change] && pulse_been_ready) begin
    		key_valid <= 1'b1;
    		if (key[8] == 0) begin
    			key_down <= key_down | key_decode;
    		end else begin
    			key_down <= key_down & (~key_decode);
    		end
    	end else begin
    		key_valid <= 1'b0;
			key_down <= key_down;
    	end
    end

endmodule


module timer(
    input clk,
    input rst,
    input start,
    output reg [9:0] count,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY
    );
    
    reg [1:0] d;
    //reg [9:0] count;
    reg [3:0] value0, value1, value2;
    
    decimal_clock_divider cd100ms(clk, clk100ms);
    clock_divider3 #(.n(12)) cd12(clk, clk12);
    
    
    always @(posedge clk100ms or posedge rst) begin
        if(rst == 1) begin
            count <= 600;
        end else if(start == 0 || count == 0) begin
            count <= count;
        end else begin
            count <= count -1;
        end
    end
    always @* begin
        value0 = count % 10;
        value1 = (count / 10) % 10;
        value2 = count / 100;
    end
    
    always @(posedge clk12) begin
        case (DIGIT)
            4'b1110: begin
                d = 1;
                DIGIT = 4'b1101;
            end
            4'b1101: begin
                d = 2;
                DIGIT = 4'b1011;
            end
            4'b1011: begin
                d = 3;
                DIGIT = 4'b0111;
            end
            4'b0111: begin
                d = 0;
                DIGIT = 4'b1110;
            end
            default: begin
                d = 0;
                DIGIT = 4'b1101;
            end
        endcase
    end
    always @* begin
        case (d)
            0: begin
                case (value0)
                    4'd0: DISPLAY = 7'b100_0000;
                    4'd1: DISPLAY = 7'b111_1001;
                    4'd2: DISPLAY = 7'b010_0100;
                    4'd3: DISPLAY = 7'b011_0000;
                    4'd4: DISPLAY = 7'b001_1001;
                    4'd5: DISPLAY = 7'b001_0010;
                    4'd6: DISPLAY = 7'b000_0010;
                    4'd7: DISPLAY = 7'b111_1000;
                    4'd8: DISPLAY = 7'b000_0000;
                    4'd9: DISPLAY = 7'b001_0000;
                    default: DISPLAY = 7'b111_1111;
                endcase
            end
            1: begin
                case (value1)
                    4'd0: DISPLAY = 7'b100_0000;
                    4'd1: DISPLAY = 7'b111_1001;
                    4'd2: DISPLAY = 7'b010_0100;
                    4'd3: DISPLAY = 7'b011_0000;
                    4'd4: DISPLAY = 7'b001_1001;
                    4'd5: DISPLAY = 7'b001_0010;
                    4'd6: DISPLAY = 7'b000_0010;
                    4'd7: DISPLAY = 7'b111_1000;
                    4'd8: DISPLAY = 7'b000_0000;
                    4'd9: DISPLAY = 7'b001_0000;
                    default: DISPLAY = 7'b111_1111;
                endcase
            end
            2: begin
                case (value2)
                    4'd0: DISPLAY = 7'b100_0000;
                    4'd1: DISPLAY = 7'b111_1001;
                    4'd2: DISPLAY = 7'b010_0100;
                    4'd3: DISPLAY = 7'b011_0000;
                    4'd4: DISPLAY = 7'b001_1001;
                    4'd5: DISPLAY = 7'b001_0010;
                    4'd6: DISPLAY = 7'b000_0010;
                    4'd7: DISPLAY = 7'b111_1000;
                    4'd8: DISPLAY = 7'b000_0000;
                    4'd9: DISPLAY = 7'b001_0000;
                    default: DISPLAY = 7'b111_1111;
                endcase
            end
            3: begin
                DISPLAY = 7'b100_0000;
            end
            default: DISPLAY = 7'b111_1111;
        endcase
    end
endmodule


