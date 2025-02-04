`define silence   32'd50000000
`define sil   32'd50000000
`define do   32'd262
`define re   32'd294
`define mi   32'd330
`define fa   32'd349
`define so   32'd392  
`define la   32'd440
`define si   32'd494   

`define hdo  32'd524   
`define hre  32'd588  
`define hmi  32'd660  
`define hfa  32'd698  
`define hso  32'd784

module lab8(
    clk,        // clock from crystal
    rst,        // BTNC: active high reset
    _play,      // SW0: Play/Pause
    _mute,      // SW1: Mute
    _slow,      // SW2: Slow
    _music,     // SW3: Music
    _mode,      // SW15: Mode
    _volUP,     // BTNU: Vol up
    _volDOWN,   // BTND: Vol down
    _higherOCT, // BTNR: Oct higher
    _lowerOCT,  // BTNL: Oct lower
    PS2_DATA,   // Keyboard I/O
    PS2_CLK,    // Keyboard I/O
    _led,       // LED: [15:13] octave & [4:0] volume
    audio_mclk, // master clock
    audio_lrck, // left-right clock
    audio_sck,  // serial clock
    audio_sdin, // serial audio data input
    DISPLAY,    // 7-seg
    DIGIT       // 7-seg
);

    // I/O declaration
    input clk; 
    input rst; 
    input _play, _mute, _slow, _music, _mode; 
    input _volUP, _volDOWN, _higherOCT, _lowerOCT; 
    inout PS2_DATA; 
	inout PS2_CLK; 
    output [15:0] _led; 
    output audio_mclk; 
    output audio_lrck; 
    output audio_sck; 
    output audio_sdin; 
    output reg [6:0] DISPLAY; 
    output reg [3:0] DIGIT;
    
    // my variable
    reg [2:0] volume = 3'd3;
    reg [2:0] octave = 3'd2;
    wire [2:0] led15_13;
    wire [4:0] led4_0;
    
    wire led4;
    wire led3;
    wire led2;
    wire led1;
    wire led0;
    assign led4 = (volume >= 3'd5) ? 1'b1 : 1'b0;
    assign led3 = (volume >= 3'd4) ? 1'b1 : 1'b0;
    assign led2 = (volume >= 3'd3) ? 1'b1 : 1'b0;
    assign led1 = (volume >= 3'd2) ? 1'b1 : 1'b0;
    assign led0 = (volume >= 3'd1) ? 1'b1 : 1'b0;
    assign led15_13 = (octave == 3'd3) ? (3'b100) : ((octave == 3'd2) ? (3'b010):(3'b001));
    assign led4_0 = (_mute == 1'b1) ? (5'b00000) : ({led4,led3,led2,led1,led0});
    
    // Modify these
    assign _led = {led15_13 , 8'b00000000 , led4_0}; 
    //assign DIGIT = 4'b0000;
    //assign DISPLAY = 7'b0111111;

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;

    reg [11:0] ibeatNum;        // Beat counter
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    // clkDiv22
    wire clkDiv22;
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for keyboard and audio
    
    wire clkDiv15;
    clock_divider #(.n(15)) clock_15(.clk(clk), .clk_div(clkDiv15));
    
    wire _volUP_de;
    wire _volUP_one;
    wire _volDOWN_de;
    wire _volDOWN_one;
    wire _higherOCT_de;
    wire _higherOCT_one;
    wire _lowerOCT_de;
    wire _lowerOCT_one;
    
    debounce d1( _volUP_de , _volUP , clk); // 常эclk 常эclk 常эclk 常эclk 常эclk 常эclk 常эclk 常эclk 
    onepulse o1( _volUP_de , clk , _volUP_one);
    
    debounce d2( _volDOWN_de , _volDOWN , clk);
    onepulse o2( _volDOWN_de , clk , _volDOWN_one);
    
    debounce d3( _higherOCT_de , _higherOCT , clk);
    onepulse o3( _higherOCT_de , clk , _higherOCT_one);
    
    debounce d4( _lowerOCT_de , _lowerOCT , clk);
    onepulse o4( _lowerOCT_de , clk , _lowerOCT_one);
   
    always @(posedge clk or posedge rst) begin
        if(rst == 1'b1) begin
            volume <= 3'd3;
            octave <= 3'd2;
        end else begin
            if(_volUP_one == 1'b1) begin
                if(volume < 3'd5) volume <= volume + 3'd1;
                else volume <= volume;
            end else if(_volDOWN_one == 1'b1) begin
                if(volume > 3'd1) volume <= volume - 3'd1;
                else volume <= volume;
            end
            
            if(_higherOCT_one == 1'b1) begin
                if(octave < 3'd3) octave <= octave + 3'd1;
                else octave <= octave;
            end else if(_lowerOCT_one == 1'b1) begin
                if(octave > 3'd1) octave <= octave - 3'd1;
                else octave <= octave;
            end
        end
    end
    
    
    reg [3:0] value;
    reg [19:0] frequency_cnt = 20'd0;
    wire [1:0] frequency;
    
    always@(posedge clk) begin
        frequency_cnt <= frequency_cnt + 20'd1;
    end    
    assign frequency = frequency_cnt[19:18];
    
    reg [3:0] BCD0; // 璶э 璶э 璶э 璶э 璶э 璶э 璶э 璶э 璶э 璶э 璶э 璶э 璶э 璶э 璶э
    always @(*) begin
        case (frequency)
            2'b00: begin
                value <= BCD0;
                DIGIT <= 4'b1110;
            end
            2'b01: begin
                value <= 4'd11;
                DIGIT <= 4'b1101;
            end
            2'b10: begin
                value <= 4'd11;
                DIGIT <= 4'b1011;
            end
            2'b11: begin
                value <= 4'd11;
                DIGIT <= 4'b0111;
            end
            default: begin
                value <= BCD0;
                DIGIT <= 4'b1110;
            end
        endcase
    end
    always @* begin
        case (value)
            4'd0: DISPLAY = 7'b1000110; // C
            4'd1: DISPLAY = 7'b0100001; // D
            4'd2: DISPLAY = 7'b0000110; // E
            4'd3: DISPLAY = 7'b0001110; // F
            4'd4: DISPLAY = 7'b0010000; // G
            4'd5: DISPLAY = 7'b0001000; // A
            4'd6: DISPLAY = 7'b0000011; // B
            4'd11: DISPLAY = 7'b0111111; // dash
            default: DISPLAY = 7'b1111111;
        endcase
    end
    
    always @* begin
        if(freqR == `hdo || freqR == `do) BCD0 = 4'd0;
        else if(freqR == `hre || freqR == `re) BCD0 = 4'd1;
        else if(freqR == `hmi || freqR == `mi) BCD0 = 4'd2;
        else if(freqR == `hfa || freqR == `fa) BCD0 = 4'd3;
        else if(freqR == `hso || freqR == `so) BCD0 = 4'd4;
        else if(freqR == `la) BCD0 = 4'd5;
        else if(freqR == `si) BCD0 = 4'd6;
        else BCD0 = 4'd11;
    end
    
    
    // 龄絃
    wire [511:0] key_down;
	wire [8:0] last_change;
	reg [3:0] key_num;
	wire been_ready;
    parameter [8:0] KEY_CODES [0:6] = {
		9'b0_0001_1100,	// A=> 1C
		9'b0_0001_1011,	// S=> 1B
		9'b0_0010_0011,	// D => 23
		9'b0_0010_1011,	// F => 2B
		9'b0_0011_0100,	// G => 34
		9'b0_0011_0011,	// H => 33
		9'b0_0011_1011	// J => 3B
	};
    KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk) // ぃ絋﹚ ぃ絋﹚ ぃ絋﹚ ぃ絋﹚ ぃ絋﹚ ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚ぃ絋﹚
	);
	/*
	always @* begin
		case (last_change)
			KEY_CODES[00] : key_num = 4'b0000;
			KEY_CODES[01] : key_num = 4'b0001;
			KEY_CODES[02] : key_num = 4'b0010;
			KEY_CODES[03] : key_num = 4'b0011;
			KEY_CODES[04] : key_num = 4'b0100;
			KEY_CODES[05] : key_num = 4'b0101;
			KEY_CODES[06] : key_num = 4'b0110;
			default : key_num = 4'b1111;
		endcase
	end
    */
    
    
    
    // play control play control play control play control play control play control play control play control play control
    parameter LEN = 512;
    reg [11:0] next_ibeat;
    reg music_1or2 = 1'b0;
    reg [1:0] counter = 1'b0;
    
    wire aa;
    wire ss;
    wire dd;
    wire ff;
    wire gg;
    wire hh;
    wire jj;
    assign aa = /*(ss==1 || dd==1 || ff==1 || gg==1 || hh==1 || jj==1) ? 0 : */((key_down[KEY_CODES[00]] == 1'b1) ? 1'b1 : 1'b0);
    assign ss = /*(aa==1 || dd==1 || ff==1 || gg==1 || hh==1 || jj==1) ? 0 : */((key_down[KEY_CODES[01]] == 1'b1) ? 1'b1 : 1'b0);
    assign dd = /*(aa==1 || ss==1 || ff==1 || gg==1 || hh==1 || jj==1) ? 0 : */((key_down[KEY_CODES[02]] == 1'b1) ? 1'b1 : 1'b0);
    assign ff = /*(aa==1 || ss==1 || dd==1 || gg==1 || hh==1 || jj==1) ? 0 : */((key_down[KEY_CODES[03]] == 1'b1) ? 1'b1 : 1'b0);
    assign gg = /*(aa==1 || ss==1 || dd==1 || ff==1 || hh==1 || jj==1) ? 0 : */((key_down[KEY_CODES[04]] == 1'b1) ? 1'b1 : 1'b0);
    assign hh = /*(aa==1 || ss==1 || dd==1 || ff==1 || gg==1 || jj==1) ? 0 : */((key_down[KEY_CODES[05]] == 1'b1) ? 1'b1 : 1'b0);
    assign jj = /*(aa==1 || ss==1 || dd==1 || ff==1 || gg==1 || hh==1) ? 0 : */((key_down[KEY_CODES[06]] == 1'b1) ? 1'b1 : 1'b0);
    
    reg [11:0] record;
    reg flag = 1'b0;
	always @(posedge clkDiv22 or posedge rst) begin
		if(rst) begin
			ibeatNum <= 0;
			counter <= 0;
			//record <= 0;
		end else begin
		    counter <= counter + 1'b1;
		    
		    
		    if(_mode == 1'b1) begin //  贾
		        if(flag==1) begin
                    ibeatNum = record;
                    flag <= 0;
		        end
		        
		        if(music_1or2 != _music) begin
		            music_1or2 <= _music;
		            ibeatNum = 0;
		            counter <= 2'd0;
		            //record <= 0;
		        end else begin
                    if(_play == 1'b1) begin 
                        if(_slow == 1'b1) begin
                            if(counter == 2'd2) begin
                                counter <= 2'd0;
                                if(ibeatNum + 1 < LEN) ibeatNum = ibeatNum + 1;
                                else ibeatNum = 0;
                            end else begin
                                ibeatNum = ibeatNum;
                            end
                        end else begin
                            counter <= 2'd0;
                            if(ibeatNum + 1 < LEN) ibeatNum = ibeatNum + 1;
                            else ibeatNum = 0;
                        end
                    end else begin
                        ibeatNum = ibeatNum;
                    end
                    //record <= ibeatNum;
                end
            end else begin // 龄絃
                if(flag==0) begin
                    record = ibeatNum;
                    flag = 1;
                end
                
                if(aa == 1) ibeatNum = 12'd0;
                else if(ss == 1) ibeatNum = 12'd1;
                else if(dd == 1) ibeatNum = 12'd2;
                else if(ff == 1) ibeatNum = 12'd3;
                else if(gg == 1) ibeatNum = 12'd4;
                else if(hh == 1) ibeatNum = 12'd5;
                else if(jj == 1) ibeatNum = 12'd6;
                else ibeatNum = 12'd7;
            end
		end
	end
    
    
    
    
    
    
    
    
    /*
    // Player Control
    // [in]  reset, clock, _play, _slow, _music, and _mode
    // [out] beat number
    player_control #(.LEN(128)) playerCtrl_00 ( 
        .clk(clkDiv22),
        .reset(rst),
        ._play(1'b1),
        ._slow(1'b0), 
        ._mode(1'b0),
        .ibeat(ibeatNum)
    );
    */

    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    music_example music_00 (
        .ibeatNum(ibeatNum),
        .en(_play),
        .mode(_mode),
        .music(_music),
        .toneL(freqL),
        .toneR(freqR)
    );

    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freq_outL = (octave == 3) ? (50000000 / (_mute ? `silence : freqL*2)) : ((octave == 1) ? (50000000 / (_mute ? `silence : freqL/2)) : (50000000 / (_mute ? `silence : freqL)));
    assign freq_outR = (octave == 3) ? (50000000 / (_mute ? `silence : freqR*2)) : ((octave == 1) ? (50000000 / (_mute ? `silence : freqR/2)) : (50000000 / (_mute ? `silence : freqR)));

    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(freq_outL), 
        .note_div_right(freq_outR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );

    // Speaker controller
    speaker_control sc(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );

endmodule


module note_gen(
    clk, // clock from crystal
    rst, // active high reset
    volume, 
    note_div_left, // div for note generation
    note_div_right,
    audio_left,
    audio_right
);

    // I/O declaration
    input clk; // clock from crystal
    input rst; // active low reset
    input [2:0] volume;
    input [21:0] note_div_left, note_div_right; // div for note generation
    output reg [15:0] audio_left, audio_right;

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    // clk_cnt, clk_cnt_2, b_clk, c_clk
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
    
    // clk_cnt_next, b_clk_next
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    // clk_cnt_next_2, c_clk_next
    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end
    
    always @* begin
        if(note_div_left == 22'd1) begin
            audio_left = 16'h0000;
        end else begin
            if(volume == 1) audio_left = (b_clk == 1'b0) ? 16'hFF38 : 16'hC8; //200
            else if(volume == 2) audio_left = (b_clk == 1'b0) ? 16'hF380 : 16'hC80; //3200
            else if(volume == 3) audio_left = (b_clk == 1'b0) ? 16'hE7C8 : 16'h1838; //6200
            else if(volume == 4) audio_left = (b_clk == 1'b0) ? 16'hDC10 : 16'h23F0; //9200
            else if(volume == 5) audio_left = (b_clk == 1'b0) ? 16'hD058 : 16'h2FA8; //12200
            else audio_left = 16'h0000;
        end
    end
    
    always @* begin
        if(note_div_right == 22'd1) begin
            audio_right = 16'h0000;
        end else begin
            if(volume == 1) audio_right = (c_clk == 1'b0) ? 16'hFF38 : 16'hC8;
            else if(volume == 2) audio_right = (c_clk == 1'b0) ? 16'hF380 : 16'hC80;
            else if(volume == 3) audio_right = (c_clk == 1'b0) ? 16'hE7C8 : 16'h1838;
            else if(volume == 4)audio_right = (c_clk == 1'b0) ? 16'hDC10 : 16'h23F0;
            else if(volume == 5) audio_right = (c_clk == 1'b0) ? 16'hD058 : 16'h2FA8;
            else audio_right = 16'h0000;
        end
    end
endmodule







module music_example (
	input [11:0] ibeatNum,
	input en,
	input mode,
	input music,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);

    always @* begin
        if(mode == 1) begin
            if(music == 0) begin
                if(en == 1) begin
                    case(ibeatNum)
                        12'd0: toneR = `hso;     12'd1: toneR = `hso;
                        12'd2: toneR = `hso;     12'd3: toneR = `hso;
                        
                        12'd4: toneR = `hso;     12'd5: toneR = `hso;
                        12'd6: toneR = `hso;     12'd7: toneR = `hso;
                        
                        12'd8: toneR = `hmi;     12'd9: toneR = `hmi;
                        12'd10: toneR = `hmi;     12'd11: toneR = `hmi;
                        
                        12'd12: toneR = `hmi;     12'd13: toneR = `hmi;
                        12'd14: toneR = `hmi;     12'd15: toneR = `sil;
                        
                        12'd16: toneR = `hmi;     12'd17: toneR = `hmi;
                        12'd18: toneR = `hmi;     12'd19: toneR = `hmi;
                        
                        12'd20: toneR = `hmi;     12'd21: toneR = `hmi;
                        12'd22: toneR = `hmi;     12'd23: toneR = `hmi;
                        
                        12'd24: toneR = `hmi;     12'd25: toneR = `hmi;
                        12'd26: toneR = `hmi;     12'd27: toneR = `hmi;
                        
                        12'd28: toneR = `hmi;     12'd29: toneR = `hmi;
                        12'd30: toneR = `hmi;     12'd31: toneR = `hmi;
                        
                        12'd32: toneR = `hfa;     12'd33: toneR = `hfa;
                        12'd34: toneR = `hfa;     12'd35: toneR = `hfa;
                        
                        12'd36: toneR = `hfa;     12'd37: toneR = `hfa;
                        12'd38: toneR = `hfa;     12'd39: toneR = `hfa;
                        
                        12'd40: toneR = `hre;     12'd41: toneR = `hre;
                        12'd42: toneR = `hre;     12'd43: toneR = `hre;
                        
                        12'd44: toneR = `hre;     12'd45: toneR = `hre;
                        12'd46: toneR = `hre;     12'd47: toneR = `sil;
                        
                        12'd48: toneR = `hre;     12'd49: toneR = `hre;
                        12'd50: toneR = `hre;     12'd51: toneR = `hre;
                        
                        12'd52: toneR = `hre;     12'd53: toneR = `hre;
                        12'd54: toneR = `hre;     12'd55: toneR = `hre;
                        
                        12'd56: toneR = `hre;     12'd57: toneR = `hre;
                        12'd58: toneR = `hre;     12'd59: toneR = `hre;
                        
                        12'd60: toneR = `hre;     12'd61: toneR = `hre;
                        12'd62: toneR = `hre;     12'd63: toneR = `hre;
                        
                        //----------------------------------------------
                        
                        12'd64: toneR = `hdo;     12'd65: toneR = `hdo;
                        12'd66: toneR = `hdo;     12'd67: toneR = `hdo;
                        
                        12'd68: toneR = `hdo;     12'd69: toneR = `hdo;
                        12'd70: toneR = `hdo;     12'd71: toneR = `hdo;
                        
                        12'd72: toneR = `hre;     12'd73: toneR = `hre;
                        12'd74: toneR = `hre;     12'd75: toneR = `hre;
                        
                        12'd76: toneR = `hre;     12'd77: toneR = `hre;
                        12'd78: toneR = `hre;     12'd79: toneR = `hre;
                        
                        12'd80: toneR = `hmi;     12'd81: toneR = `hmi;
                        12'd82: toneR = `hmi;     12'd83: toneR = `hmi;
                        
                        12'd84: toneR = `hmi;     12'd85: toneR = `hmi;
                        12'd86: toneR = `hmi;     12'd87: toneR = `hmi;
                        
                        12'd88: toneR = `hfa;     12'd89: toneR = `hfa;
                        12'd90: toneR = `hfa;     12'd91: toneR = `hfa;
                        
                        12'd92: toneR = `hfa;     12'd93: toneR = `hfa;
                        12'd94: toneR = `hfa;     12'd95: toneR = `hfa;
                        
                        12'd96: toneR = `hso;     12'd97: toneR = `hso;
                        12'd98: toneR = `hso;     12'd99: toneR = `hso;
                        
                        12'd100: toneR = `hso;     12'd101: toneR = `hso;
                        12'd102: toneR = `hso;     12'd103: toneR = `sil;
                        
                        12'd104: toneR = `hso;     12'd105: toneR = `hso;
                        12'd106: toneR = `hso;     12'd107: toneR = `hso;
                        
                        12'd108: toneR = `hso;     12'd109: toneR = `hso;
                        12'd110: toneR = `hso;     12'd111: toneR = `sil;
                        
                        12'd112: toneR = `hso;     12'd113: toneR = `hso;
                        12'd114: toneR = `hso;     12'd115: toneR = `hso;
                        
                        12'd116: toneR = `hso;     12'd117: toneR = `hso;
                        12'd118: toneR = `hso;     12'd119: toneR = `hso;
                        
                        12'd120: toneR = `hso;     12'd121: toneR = `hso;
                        12'd122: toneR = `hso;     12'd123: toneR = `hso;
                        
                        12'd124: toneR = `hso;     12'd125: toneR = `hso;
                        12'd126: toneR = `hso;     12'd127: toneR = `sil;
                        
                        //-----------------------------------------------
                        
                        12'd128: toneR = `hso;     12'd129: toneR = `hso;
                        12'd130: toneR = `hso;     12'd131: toneR = `hso;
                        
                        12'd132: toneR = `hso;     12'd133: toneR = `hso;
                        12'd134: toneR = `hso;     12'd135: toneR = `hso;
                        
                        12'd136: toneR = `hmi;     12'd137: toneR = `hmi;
                        12'd138: toneR = `hmi;     12'd139: toneR = `hmi;
                        
                        12'd140: toneR = `hmi;     12'd141: toneR = `hmi;
                        12'd142: toneR = `hmi;     12'd143: toneR = `sil;
                        
                        12'd144: toneR = `hmi;     12'd145: toneR = `hmi;
                        12'd146: toneR = `hmi;     12'd147: toneR = `hmi;
                        
                        12'd148: toneR = `hmi;     12'd149: toneR = `hmi;
                        12'd150: toneR = `hmi;     12'd151: toneR = `hmi;
                        
                        12'd152: toneR = `hmi;     12'd153: toneR = `hmi;
                        12'd154: toneR = `hmi;     12'd155: toneR = `hmi;
                        
                        12'd156: toneR = `hmi;     12'd157: toneR = `hmi;
                        12'd158: toneR = `hmi;     12'd159: toneR = `hmi;
                        
                        12'd160: toneR = `hfa;     12'd161: toneR = `hfa;
                        12'd162: toneR = `hfa;     12'd163: toneR = `hfa;
                        
                        12'd164: toneR = `hfa;     12'd165: toneR = `hfa;
                        12'd166: toneR = `hfa;     12'd167: toneR = `hfa;
                        
                        12'd168: toneR = `hre;     12'd169: toneR = `hre;
                        12'd170: toneR = `hre;     12'd171: toneR = `hre;
                        
                        12'd172: toneR = `hre;     12'd173: toneR = `hre;
                        12'd174: toneR = `hre;     12'd175: toneR = `sil;
                        
                        12'd176: toneR = `hre;     12'd177: toneR = `hre;
                        12'd178: toneR = `hre;     12'd179: toneR = `hre;
                        
                        12'd180: toneR = `hre;     12'd181: toneR = `hre;
                        12'd182: toneR = `hre;     12'd183: toneR = `hre;
                        
                        12'd184: toneR = `hre;     12'd185: toneR = `hre;
                        12'd186: toneR = `hre;     12'd187: toneR = `hre;
                        
                        12'd188: toneR = `hre;     12'd189: toneR = `hre;
                        12'd190: toneR = `hre;     12'd191: toneR = `hre;
                        
                        //-----------------------------------------------
                        
                        12'd192: toneR = `hdo;     12'd193: toneR = `hdo;
                        12'd194: toneR = `hdo;     12'd195: toneR = `hdo;
                        
                        12'd196: toneR = `hdo;     12'd197: toneR = `hdo;
                        12'd198: toneR = `hdo;     12'd199: toneR = `hdo;
                        
                        12'd200: toneR = `hmi;     12'd201: toneR = `hmi;
                        12'd202: toneR = `hmi;     12'd203: toneR = `hmi;
                        
                        12'd204: toneR = `hmi;     12'd205: toneR = `hmi;
                        12'd206: toneR = `hmi;     12'd207: toneR = `hmi;
                        
                        12'd208: toneR = `hso;     12'd209: toneR = `hso;
                        12'd210: toneR = `hso;     12'd211: toneR = `hso;
                        
                        12'd212: toneR = `hso;     12'd213: toneR = `hso;
                        12'd214: toneR = `hso;     12'd215: toneR = `sil;
                        
                        12'd216: toneR = `hso;     12'd217: toneR = `hso;
                        12'd218: toneR = `hso;     12'd219: toneR = `hso;
                        
                        12'd220: toneR = `hso;     12'd221: toneR = `hso;
                        12'd222: toneR = `hso;     12'd223: toneR = `hso;
                        
                        12'd224: toneR = `hmi;     12'd225: toneR = `hmi;
                        12'd226: toneR = `hmi;     12'd227: toneR = `hmi;
                        
                        12'd228: toneR = `hmi;     12'd229: toneR = `hmi;
                        12'd230: toneR = `hmi;     12'd231: toneR = `sil;
                        
                        12'd232: toneR = `hmi;     12'd233: toneR = `hmi;
                        12'd234: toneR = `hmi;     12'd235: toneR = `hmi;
                        
                        12'd236: toneR = `hmi;     12'd237: toneR = `hmi;
                        12'd238: toneR = `hmi;     12'd239: toneR = `sil;
                        
                        12'd240: toneR = `hmi;     12'd241: toneR = `hmi;
                        12'd242: toneR = `hmi;     12'd243: toneR = `hmi;
                        
                        12'd244: toneR = `hmi;     12'd245: toneR = `hmi;
                        12'd246: toneR = `hmi;     12'd247: toneR = `hmi;
                        
                        12'd248: toneR = `hmi;     12'd249: toneR = `hmi;
                        12'd250: toneR = `hmi;     12'd251: toneR = `hmi;
                        
                        12'd252: toneR = `hmi;     12'd253: toneR = `hmi;
                        12'd254: toneR = `hmi;     12'd255: toneR = `hmi;
                        
                        //------------------------------------------------
                        
                        12'd256: toneR = `hre;     12'd257: toneR = `hre;
                        12'd258: toneR = `hre;     12'd259: toneR = `hre;
                        
                        12'd260: toneR = `hre;     12'd261: toneR = `hre;
                        12'd262: toneR = `hre;     12'd263: toneR = `sil;
                        
                        12'd264: toneR = `hre;     12'd265: toneR = `hre;
                        12'd266: toneR = `hre;     12'd267: toneR = `hre;
                        
                        12'd268: toneR = `hre;     12'd269: toneR = `hre;
                        12'd270: toneR = `hre;     12'd271: toneR = `sil;
                        
                        12'd272: toneR = `hre;     12'd273: toneR = `hre;
                        12'd274: toneR = `hre;     12'd275: toneR = `hre;
                        
                        12'd276: toneR = `hre;     12'd277: toneR = `hre;
                        12'd278: toneR = `hre;     12'd279: toneR = `sil;
                        
                        12'd280: toneR = `hre;     12'd281: toneR = `hre;
                        12'd282: toneR = `hre;     12'd283: toneR = `hre;
                        
                        12'd284: toneR = `hre;     12'd285: toneR = `hre;
                        12'd286: toneR = `hre;     12'd287: toneR = `sil;
                        
                        12'd288: toneR = `hre;     12'd289: toneR = `hre;
                        12'd290: toneR = `hre;     12'd291: toneR = `hre;
                        
                        12'd292: toneR = `hre;     12'd293: toneR = `hre;
                        12'd294: toneR = `hre;     12'd295: toneR = `hre;
                        
                        12'd296: toneR = `hmi;     12'd297: toneR = `hmi;
                        12'd298: toneR = `hmi;     12'd299: toneR = `hmi;
                        
                        12'd300: toneR = `hmi;     12'd301: toneR = `hmi;
                        12'd302: toneR = `hmi;     12'd303: toneR = `hmi;
                        
                        12'd304: toneR = `hfa;     12'd305: toneR = `hfa;
                        12'd306: toneR = `hfa;     12'd307: toneR = `hfa;
                        
                        12'd308: toneR = `hfa;     12'd309: toneR = `hfa;
                        12'd310: toneR = `hfa;     12'd311: toneR = `hfa;
                        
                        12'd312: toneR = `hfa;     12'd313: toneR = `hfa;
                        12'd314: toneR = `hfa;     12'd315: toneR = `hfa;
                        
                        12'd316: toneR = `hfa;     12'd317: toneR = `hfa;
                        12'd318: toneR = `hfa;     12'd319: toneR = `hfa;
                        
                        //-------------------------------------------------
                        
                        12'd320: toneR = `hmi;     12'd321: toneR = `hmi;
                        12'd322: toneR = `hmi;     12'd323: toneR = `hmi;
                        
                        12'd324: toneR = `hmi;     12'd325: toneR = `hmi;
                        12'd326: toneR = `hmi;     12'd327: toneR = `sil;
                        
                        12'd328: toneR = `hmi;     12'd329: toneR = `hmi;
                        12'd330: toneR = `hmi;     12'd331: toneR = `hmi;
                        
                        12'd332: toneR = `hmi;     12'd333: toneR = `hmi;
                        12'd334: toneR = `hmi;     12'd335: toneR = `sil;
                        
                        12'd336: toneR = `hmi;     12'd337: toneR = `hmi;
                        12'd338: toneR = `hmi;     12'd339: toneR = `hmi;
                        
                        12'd340: toneR = `hmi;     12'd341: toneR = `hmi;
                        12'd342: toneR = `hmi;     12'd343: toneR = `sil;
                        
                        12'd344: toneR = `hmi;     12'd345: toneR = `hmi;
                        12'd346: toneR = `hmi;     12'd347: toneR = `hmi;
                        
                        12'd348: toneR = `hmi;     12'd349: toneR = `hmi;
                        12'd350: toneR = `hmi;     12'd351: toneR = `sil;
                        
                        12'd352: toneR = `hmi;     12'd353: toneR = `hmi;
                        12'd354: toneR = `hmi;     12'd355: toneR = `hmi;
                        
                        12'd356: toneR = `hmi;     12'd357: toneR = `hmi;
                        12'd358: toneR = `hmi;     12'd359: toneR = `hmi;
                        
                        12'd360: toneR = `hfa;     12'd361: toneR = `hfa;
                        12'd362: toneR = `hfa;     12'd363: toneR = `hfa;
                        
                        12'd364: toneR = `hfa;     12'd365: toneR = `hfa;
                        12'd366: toneR = `hfa;     12'd367: toneR = `hfa;
                        
                        12'd368: toneR = `hso;     12'd369: toneR = `hso;
                        12'd370: toneR = `hso;     12'd371: toneR = `hso;
                        
                        12'd372: toneR = `hso;     12'd373: toneR = `hso;
                        12'd374: toneR = `hso;     12'd375: toneR = `hso;
                        
                        12'd376: toneR = `hso;     12'd377: toneR = `hso;
                        12'd378: toneR = `hso;     12'd379: toneR = `hso;
                        
                        12'd380: toneR = `hso;     12'd381: toneR = `hso;
                        12'd382: toneR = `hso;     12'd383: toneR = `sil;
                        
                        //------------------------------------------------
                        
                        12'd384: toneR = `hso;     12'd385: toneR = `hso;
                        12'd386: toneR = `hso;     12'd387: toneR = `hso;
                        
                        12'd388: toneR = `hso;     12'd389: toneR = `hso;
                        12'd390: toneR = `hso;     12'd391: toneR = `hso;
                        
                        12'd392: toneR = `hmi;     12'd393: toneR = `hmi;
                        12'd394: toneR = `hmi;     12'd395: toneR = `hmi;
                        
                        12'd396: toneR = `hmi;     12'd397: toneR = `hmi;
                        12'd398: toneR = `hmi;     12'd399: toneR = `sil;
                        
                        12'd400: toneR = `hmi;     12'd401: toneR = `hmi;
                        12'd402: toneR = `hmi;     12'd403: toneR = `hmi;
                        
                        12'd404: toneR = `hmi;     12'd405: toneR = `hmi;
                        12'd406: toneR = `hmi;     12'd407: toneR = `hmi;
                        
                        12'd408: toneR = `hmi;     12'd409: toneR = `hmi;
                        12'd410: toneR = `hmi;     12'd411: toneR = `hmi;
                        
                        12'd412: toneR = `hmi;     12'd413: toneR = `hmi;
                        12'd414: toneR = `hmi;     12'd415: toneR = `hmi;
                        
                        12'd416: toneR = `hfa;     12'd417: toneR = `hfa;
                        12'd418: toneR = `hfa;     12'd419: toneR = `hfa;
                        
                        12'd420: toneR = `hfa;     12'd421: toneR = `hfa;
                        12'd422: toneR = `hfa;     12'd423: toneR = `hfa;
                        
                        12'd424: toneR = `hre;     12'd425: toneR = `hre;
                        12'd426: toneR = `hre;     12'd427: toneR = `hre;
                        
                        12'd428: toneR = `hre;     12'd429: toneR = `hre;
                        12'd430: toneR = `hre;     12'd431: toneR = `sil;
                        
                        12'd432: toneR = `hre;     12'd433: toneR = `hre;
                        12'd434: toneR = `hre;     12'd435: toneR = `hre;
                        
                        12'd436: toneR = `hre;     12'd437: toneR = `hre;
                        12'd438: toneR = `hre;     12'd439: toneR = `hre;
                        
                        12'd440: toneR = `hre;     12'd441: toneR = `hre;
                        12'd442: toneR = `hre;     12'd443: toneR = `hre;
                        
                        12'd444: toneR = `hre;     12'd445: toneR = `hre;
                        12'd446: toneR = `hre;     12'd447: toneR = `hre;
                        
                        //-----------------------------------------------
                        
                        12'd448: toneR = `hdo;     12'd449: toneR = `hdo;
                        12'd450: toneR = `hdo;     12'd451: toneR = `hdo;
                        
                        12'd452: toneR = `hdo;     12'd453: toneR = `hdo;
                        12'd454: toneR = `hdo;     12'd455: toneR = `hdo;
                        
                        12'd456: toneR = `hmi;     12'd457: toneR = `hmi;
                        12'd458: toneR = `hmi;     12'd459: toneR = `hmi;
                        
                        12'd460: toneR = `hmi;     12'd461: toneR = `hmi;
                        12'd462: toneR = `hmi;     12'd463: toneR = `hmi;
                        
                        12'd464: toneR = `hso;     12'd465: toneR = `hso;
                        12'd466: toneR = `hso;     12'd467: toneR = `hso;
                        
                        12'd468: toneR = `hso;     12'd469: toneR = `hso;
                        12'd470: toneR = `hso;     12'd471: toneR = `sil;
                        
                        12'd472: toneR = `hso;     12'd473: toneR = `hso;
                        12'd474: toneR = `hso;     12'd475: toneR = `hso;
                        
                        12'd476: toneR = `hso;     12'd477: toneR = `hso;
                        12'd478: toneR = `hso;     12'd479: toneR = `hso;
                        
                        12'd480: toneR = `hdo;     12'd481: toneR = `hdo;
                        12'd482: toneR = `hdo;     12'd483: toneR = `hdo;
                        
                        12'd484: toneR = `hdo;     12'd485: toneR = `hdo;
                        12'd486: toneR = `hdo;     12'd487: toneR = `hdo;
                        
                        12'd488: toneR = `hdo;     12'd489: toneR = `hdo;
                        12'd490: toneR = `hdo;     12'd491: toneR = `hdo;
                        
                        12'd492: toneR = `hdo;     12'd493: toneR = `hdo;
                        12'd494: toneR = `hdo;     12'd495: toneR = `hdo;
                        
                        12'd496: toneR = `hdo;     12'd497: toneR = `hdo;
                        12'd498: toneR = `hdo;     12'd499: toneR = `hdo;
                        
                        12'd500: toneR = `hdo;     12'd501: toneR = `hdo;
                        12'd502: toneR = `hdo;     12'd503: toneR = `hdo;
                        
                        12'd504: toneR = `hdo;     12'd505: toneR = `hdo;
                        12'd506: toneR = `hdo;     12'd507: toneR = `hdo;
                        
                        12'd508: toneR = `hdo;     12'd509: toneR = `hdo;
                        12'd510: toneR = `hdo;     12'd511: toneR = `hdo;
                        
                        default: toneR = `sil;
                    endcase
                end else begin
                    toneR = `sil;
                end
            end else begin //材簈
                if(en == 1) begin
                    case(ibeatNum)
                        12'd0: toneR = `hmi;     12'd1: toneR = `hmi;
                        12'd2: toneR = `hmi;     12'd3: toneR = `hmi;
                        
                        12'd4: toneR = `hmi;     12'd5: toneR = `hmi;
                        12'd6: toneR = `hmi;     12'd7: toneR = `sil;
                        
                        12'd8: toneR = `hmi;     12'd9: toneR = `hmi;
                        12'd10: toneR = `hmi;     12'd11: toneR = `hmi;
                        
                        12'd12: toneR = `hmi;     12'd13: toneR = `hmi;
                        12'd14: toneR = `hmi;     12'd15: toneR = `sil;
                        
                        12'd16: toneR = `hmi;     12'd17: toneR = `hmi;
                        12'd18: toneR = `hmi;     12'd19: toneR = `hmi;
                        
                        12'd20: toneR = `hmi;     12'd21: toneR = `hmi;
                        12'd22: toneR = `hmi;     12'd23: toneR = `hmi;
                        
                        12'd24: toneR = `hmi;     12'd25: toneR = `hmi;
                        12'd26: toneR = `hmi;     12'd27: toneR = `hmi;
                        
                        12'd28: toneR = `hmi;     12'd29: toneR = `hmi;
                        12'd30: toneR = `hmi;     12'd31: toneR = `sil;
                        
                        12'd32: toneR = `hmi;     12'd33: toneR = `hmi;
                        12'd34: toneR = `hmi;     12'd35: toneR = `hmi;
                        
                        12'd36: toneR = `hmi;     12'd37: toneR = `hmi;
                        12'd38: toneR = `hmi;     12'd39: toneR = `sil;
                        
                        12'd40: toneR = `hmi;     12'd41: toneR = `hmi;
                        12'd42: toneR = `hmi;     12'd43: toneR = `hmi;
                        
                        12'd44: toneR = `hmi;     12'd45: toneR = `hmi;
                        12'd46: toneR = `hmi;     12'd47: toneR = `sil;
                        
                        12'd48: toneR = `hmi;     12'd49: toneR = `hmi;
                        12'd50: toneR = `hmi;     12'd51: toneR = `hmi;
                        
                        12'd52: toneR = `hmi;     12'd53: toneR = `hmi;
                        12'd54: toneR = `hmi;     12'd55: toneR = `hmi;
                        
                        12'd56: toneR = `hmi;     12'd57: toneR = `hmi;
                        12'd58: toneR = `hmi;     12'd59: toneR = `hmi;
                        
                        12'd60: toneR = `hmi;     12'd61: toneR = `hmi;
                        12'd62: toneR = `hmi;     12'd63: toneR = `sil;
                        
                        //----------------------------------------------
                        
                        12'd64: toneR = `hmi;     12'd65: toneR = `hmi;
                        12'd66: toneR = `hmi;     12'd67: toneR = `hmi;
                        
                        12'd68: toneR = `hmi;     12'd69: toneR = `hmi;
                        12'd70: toneR = `hmi;     12'd71: toneR = `hmi;
                        
                        12'd72: toneR = `hso;     12'd73: toneR = `hso;
                        12'd74: toneR = `hso;     12'd75: toneR = `hso;
                        
                        12'd76: toneR = `hso;     12'd77: toneR = `hso;
                        12'd78: toneR = `hso;     12'd79: toneR = `hso;
                        
                        12'd80: toneR = `hdo;     12'd81: toneR = `hdo;
                        12'd82: toneR = `hdo;     12'd83: toneR = `hdo;
                        
                        12'd84: toneR = `hdo;     12'd85: toneR = `hdo;
                        12'd86: toneR = `hdo;     12'd87: toneR = `hdo;
                        
                        12'd88: toneR = `hre;     12'd89: toneR = `hre;
                        12'd90: toneR = `hre;     12'd91: toneR = `hre;
                        
                        12'd92: toneR = `hre;     12'd93: toneR = `hre;
                        12'd94: toneR = `hre;     12'd95: toneR = `hre;
                        
                        12'd96: toneR = `hmi;     12'd97: toneR = `hmi;
                        12'd98: toneR = `hmi;     12'd99: toneR = `hmi;
                        
                        12'd100: toneR = `hmi;     12'd101: toneR = `hmi;
                        12'd102: toneR = `hmi;     12'd103: toneR = `hmi;
                        
                        12'd104: toneR = `hmi;     12'd105: toneR = `hmi;
                        12'd106: toneR = `hmi;     12'd107: toneR = `hmi;
                        
                        12'd108: toneR = `hmi;     12'd109: toneR = `hmi;
                        12'd110: toneR = `hmi;     12'd111: toneR = `hmi;
                        
                        12'd112: toneR = `hmi;     12'd113: toneR = `hmi;
                        12'd114: toneR = `hmi;     12'd115: toneR = `hmi;
                        
                        12'd116: toneR = `hmi;     12'd117: toneR = `hmi;
                        12'd118: toneR = `hmi;     12'd119: toneR = `hmi;
                        
                        12'd120: toneR = `hmi;     12'd121: toneR = `hmi;
                        12'd122: toneR = `hmi;     12'd123: toneR = `hmi;
                        
                        12'd124: toneR = `hmi;     12'd125: toneR = `hmi;
                        12'd126: toneR = `hmi;     12'd127: toneR = `hmi;
                        
                        //-----------------------------------------------
                        
                        12'd128: toneR = `hfa;     12'd129: toneR = `hfa;
                        12'd130: toneR = `hfa;     12'd131: toneR = `hfa;
                        
                        12'd132: toneR = `hfa;     12'd133: toneR = `hfa;
                        12'd134: toneR = `hfa;     12'd135: toneR = `sil;
                        
                        12'd136: toneR = `hfa;     12'd137: toneR = `hfa;
                        12'd138: toneR = `hfa;     12'd139: toneR = `hfa;
                        
                        12'd140: toneR = `hfa;     12'd141: toneR = `hfa;
                        12'd142: toneR = `hfa;     12'd143: toneR = `sil;
                        
                        12'd144: toneR = `hfa;     12'd145: toneR = `hfa;
                        12'd146: toneR = `hfa;     12'd147: toneR = `hfa;
                        
                        12'd148: toneR = `hfa;     12'd149: toneR = `hfa;
                        12'd150: toneR = `hfa;     12'd151: toneR = `hfa;
                        
                        12'd152: toneR = `hfa;     12'd153: toneR = `hfa;
                        12'd154: toneR = `hfa;     12'd155: toneR = `sil;
                        
                        12'd156: toneR = `hfa;     12'd157: toneR = `hfa;
                        12'd158: toneR = `hfa;     12'd159: toneR = `sil;
                        
                        12'd160: toneR = `hfa;     12'd161: toneR = `hfa;
                        12'd162: toneR = `hfa;     12'd163: toneR = `hfa;
                        
                        12'd164: toneR = `hfa;     12'd165: toneR = `hfa;
                        12'd166: toneR = `hfa;     12'd167: toneR = `sil;
                        
                        12'd168: toneR = `hmi;     12'd169: toneR = `hmi;
                        12'd170: toneR = `hmi;     12'd171: toneR = `hmi;
                        
                        12'd172: toneR = `hmi;     12'd173: toneR = `hmi;
                        12'd174: toneR = `hmi;     12'd175: toneR = `sil;
                        
                        12'd176: toneR = `hmi;     12'd177: toneR = `hmi;
                        12'd178: toneR = `hmi;     12'd179: toneR = `hmi;
                        
                        12'd180: toneR = `hmi;     12'd181: toneR = `hmi;
                        12'd182: toneR = `hmi;     12'd183: toneR = `hmi;
                        
                        12'd184: toneR = `hmi;     12'd185: toneR = `hmi;
                        12'd186: toneR = `hmi;     12'd187: toneR = `sil;
                        
                        12'd188: toneR = `hmi;     12'd189: toneR = `hmi;
                        12'd190: toneR = `hmi;     12'd191: toneR = `sil;
                        
                        //-----------------------------------------------
                        
                        12'd192: toneR = `hmi;     12'd193: toneR = `hmi;
                        12'd194: toneR = `hmi;     12'd195: toneR = `hmi;
                        
                        12'd196: toneR = `hmi;     12'd197: toneR = `hmi;
                        12'd198: toneR = `hmi;     12'd199: toneR = `hmi;
                        
                        12'd200: toneR = `hre;     12'd201: toneR = `hre;
                        12'd202: toneR = `hre;     12'd203: toneR = `hre;
                        
                        12'd204: toneR = `hre;     12'd205: toneR = `hre;
                        12'd206: toneR = `hre;     12'd207: toneR = `sil;
                        
                        12'd208: toneR = `hre;     12'd209: toneR = `hre;
                        12'd210: toneR = `hre;     12'd211: toneR = `hre;
                        
                        12'd212: toneR = `hre;     12'd213: toneR = `hre;
                        12'd214: toneR = `hre;     12'd215: toneR = `sil;
                        
                        12'd216: toneR = `hmi;     12'd217: toneR = `hmi;
                        12'd218: toneR = `hmi;     12'd219: toneR = `hmi;
                        
                        12'd220: toneR = `hmi;     12'd221: toneR = `hmi;
                        12'd222: toneR = `hmi;     12'd223: toneR = `hmi;
                        
                        12'd224: toneR = `hre;     12'd225: toneR = `hre;
                        12'd226: toneR = `hre;     12'd227: toneR = `hre;
                        
                        12'd228: toneR = `hre;     12'd229: toneR = `hre;
                        12'd230: toneR = `hre;     12'd231: toneR = `hre;
                        
                        12'd232: toneR = `hre;     12'd233: toneR = `hre;
                        12'd234: toneR = `hre;     12'd235: toneR = `hre;
                        
                        12'd236: toneR = `hre;     12'd237: toneR = `hre;
                        12'd238: toneR = `hre;     12'd239: toneR = `hre;
                        
                        12'd240: toneR = `hso;     12'd241: toneR = `hso;
                        12'd242: toneR = `hso;     12'd243: toneR = `hso;
                        
                        12'd244: toneR = `hso;     12'd245: toneR = `hso;
                        12'd246: toneR = `hso;     12'd247: toneR = `hso;
                        
                        12'd248: toneR = `hso;     12'd249: toneR = `hso;
                        12'd250: toneR = `hso;     12'd251: toneR = `hso;
                        
                        12'd252: toneR = `hso;     12'd253: toneR = `hso;
                        12'd254: toneR = `hso;     12'd255: toneR = `hso;
                        
                        //------------------------------------------------
                        
                        12'd256: toneR = `hmi;     12'd257: toneR = `hmi;
                        12'd258: toneR = `hmi;     12'd259: toneR = `hmi;
                        
                        12'd260: toneR = `hmi;     12'd261: toneR = `hmi;
                        12'd262: toneR = `hmi;     12'd263: toneR = `sil;
                        
                        12'd264: toneR = `hmi;     12'd265: toneR = `hmi;
                        12'd266: toneR = `hmi;     12'd267: toneR = `hmi;
                        
                        12'd268: toneR = `hmi;     12'd269: toneR = `hmi;
                        12'd270: toneR = `hmi;     12'd271: toneR = `sil;
                        
                        12'd272: toneR = `hmi;     12'd273: toneR = `hmi;
                        12'd274: toneR = `hmi;     12'd275: toneR = `hmi;
                        
                        12'd276: toneR = `hmi;     12'd277: toneR = `hmi;
                        12'd278: toneR = `hmi;     12'd279: toneR = `hmi;
                        
                        12'd280: toneR = `hmi;     12'd281: toneR = `hmi;
                        12'd282: toneR = `hmi;     12'd283: toneR = `hmi;
                        
                        12'd284: toneR = `hmi;     12'd285: toneR = `hmi;
                        12'd286: toneR = `hmi;     12'd287: toneR = `sil;
                        
                        12'd288: toneR = `hmi;     12'd289: toneR = `hmi;
                        12'd290: toneR = `hmi;     12'd291: toneR = `hmi;
                        
                        12'd292: toneR = `hmi;     12'd293: toneR = `hmi;
                        12'd294: toneR = `hmi;     12'd295: toneR = `sil;
                        
                        12'd296: toneR = `hmi;     12'd297: toneR = `hmi;
                        12'd298: toneR = `hmi;     12'd299: toneR = `hmi;
                        
                        12'd300: toneR = `hmi;     12'd301: toneR = `hmi;
                        12'd302: toneR = `hmi;     12'd303: toneR = `sil;
                        
                        12'd304: toneR = `hmi;     12'd305: toneR = `hmi;
                        12'd306: toneR = `hmi;     12'd307: toneR = `hmi;
                        
                        12'd308: toneR = `hmi;     12'd309: toneR = `hmi;
                        12'd310: toneR = `hmi;     12'd311: toneR = `hmi;
                        
                        12'd312: toneR = `hmi;     12'd313: toneR = `hmi;
                        12'd314: toneR = `hmi;     12'd315: toneR = `hmi;
                        
                        12'd316: toneR = `hmi;     12'd317: toneR = `hmi;
                        12'd318: toneR = `hmi;     12'd319: toneR = `sil;
                        
                        //-------------------------------------------------
                        
                        12'd320: toneR = `hmi;     12'd321: toneR = `hmi;
                        12'd322: toneR = `hmi;     12'd323: toneR = `hmi;
                        
                        12'd324: toneR = `hmi;     12'd325: toneR = `hmi;
                        12'd326: toneR = `hmi;     12'd327: toneR = `hmi;
                        
                        12'd328: toneR = `hso;     12'd329: toneR = `hso;
                        12'd330: toneR = `hso;     12'd331: toneR = `hso;
                        
                        12'd332: toneR = `hso;     12'd333: toneR = `hso;
                        12'd334: toneR = `hso;     12'd335: toneR = `hso;
                        
                        12'd336: toneR = `hdo;     12'd337: toneR = `hdo;
                        12'd338: toneR = `hdo;     12'd339: toneR = `hdo;
                        
                        12'd340: toneR = `hdo;     12'd341: toneR = `hdo;
                        12'd342: toneR = `hdo;     12'd343: toneR = `hdo;
                        
                        12'd344: toneR = `hre;     12'd345: toneR = `hre;
                        12'd346: toneR = `hre;     12'd347: toneR = `hre;
                        
                        12'd348: toneR = `hre;     12'd349: toneR = `hre;
                        12'd350: toneR = `hre;     12'd351: toneR = `hre;
                        
                        12'd352: toneR = `hmi;     12'd353: toneR = `hmi;
                        12'd354: toneR = `hmi;     12'd355: toneR = `hmi;
                        
                        12'd356: toneR = `hmi;     12'd357: toneR = `hmi;
                        12'd358: toneR = `hmi;     12'd359: toneR = `hmi;
                        
                        12'd360: toneR = `hmi;     12'd361: toneR = `hmi;
                        12'd362: toneR = `hmi;     12'd363: toneR = `hmi;
                        
                        12'd364: toneR = `hmi;     12'd365: toneR = `hmi;
                        12'd366: toneR = `hmi;     12'd367: toneR = `hmi;
                        
                        12'd368: toneR = `hmi;     12'd369: toneR = `hmi;
                        12'd370: toneR = `hmi;     12'd371: toneR = `hmi;
                        
                        12'd372: toneR = `hmi;     12'd373: toneR = `hmi;
                        12'd374: toneR = `hmi;     12'd375: toneR = `hmi;
                        
                        12'd376: toneR = `hmi;     12'd377: toneR = `hmi;
                        12'd378: toneR = `hmi;     12'd379: toneR = `hmi;
                        
                        12'd380: toneR = `hmi;     12'd381: toneR = `hmi;
                        12'd382: toneR = `hmi;     12'd383: toneR = `hmi;
                        
                        //------------------------------------------------
                        
                        12'd384: toneR = `hfa;     12'd385: toneR = `hfa;
                        12'd386: toneR = `hfa;     12'd387: toneR = `hfa;
                        
                        12'd388: toneR = `hfa;     12'd389: toneR = `hfa;
                        12'd390: toneR = `hfa;     12'd391: toneR = `sil;
                        
                        12'd392: toneR = `hfa;     12'd393: toneR = `hfa;
                        12'd394: toneR = `hfa;     12'd395: toneR = `hfa;
                        
                        12'd396: toneR = `hfa;     12'd397: toneR = `hfa;
                        12'd398: toneR = `hfa;     12'd399: toneR = `sil;
                        
                        12'd400: toneR = `hfa;     12'd401: toneR = `hfa;
                        12'd402: toneR = `hfa;     12'd403: toneR = `hfa;
                        
                        12'd404: toneR = `hfa;     12'd405: toneR = `hfa;
                        12'd406: toneR = `hfa;     12'd407: toneR = `hfa;
                        
                        12'd408: toneR = `hfa;     12'd409: toneR = `hfa;
                        12'd410: toneR = `hfa;     12'd411: toneR = `sil;
                        
                        12'd412: toneR = `hfa;     12'd413: toneR = `hfa;
                        12'd414: toneR = `hfa;     12'd415: toneR = `sil;
                        
                        12'd416: toneR = `hfa;     12'd417: toneR = `hfa;
                        12'd418: toneR = `hfa;     12'd419: toneR = `hfa;
                        
                        12'd420: toneR = `hfa;     12'd421: toneR = `hfa;
                        12'd422: toneR = `hfa;     12'd423: toneR = `sil;
                        
                        12'd424: toneR = `hmi;     12'd425: toneR = `hmi;
                        12'd426: toneR = `hmi;     12'd427: toneR = `hmi;
                        
                        12'd428: toneR = `hmi;     12'd429: toneR = `hmi;
                        12'd430: toneR = `hmi;     12'd431: toneR = `sil;
                        
                        12'd432: toneR = `hmi;     12'd433: toneR = `hmi;
                        12'd434: toneR = `hmi;     12'd435: toneR = `hmi;
                        
                        12'd436: toneR = `hmi;     12'd437: toneR = `hmi;
                        12'd438: toneR = `hmi;     12'd439: toneR = `hmi;
                        
                        12'd440: toneR = `hmi;     12'd441: toneR = `hmi;
                        12'd442: toneR = `hmi;     12'd443: toneR = `sil;
                        
                        12'd444: toneR = `hmi;     12'd445: toneR = `hmi;
                        12'd446: toneR = `hmi;     12'd447: toneR = `hmi;
                        
                        //-----------------------------------------------
                        
                        12'd448: toneR = `hso;     12'd449: toneR = `hso;
                        12'd450: toneR = `hso;     12'd451: toneR = `hso;
                        
                        12'd452: toneR = `hso;     12'd453: toneR = `hso;
                        12'd454: toneR = `hso;     12'd455: toneR = `sil;
                        
                        12'd456: toneR = `hso;     12'd457: toneR = `hso;
                        12'd458: toneR = `hso;     12'd459: toneR = `hso;
                        
                        12'd460: toneR = `hso;     12'd461: toneR = `hso;
                        12'd462: toneR = `hso;     12'd463: toneR = `hso;
                        
                        12'd464: toneR = `hfa;     12'd465: toneR = `hfa;
                        12'd466: toneR = `hfa;     12'd467: toneR = `hfa;
                        
                        12'd468: toneR = `hfa;     12'd469: toneR = `hfa;
                        12'd470: toneR = `hfa;     12'd471: toneR = `hfa;
                        
                        12'd472: toneR = `hre;     12'd473: toneR = `hre;
                        12'd474: toneR = `hre;     12'd475: toneR = `hre;
                        
                        12'd476: toneR = `hre;     12'd477: toneR = `hre;
                        12'd478: toneR = `hre;     12'd479: toneR = `hre;
                        
                        12'd480: toneR = `hdo;     12'd481: toneR = `hdo;
                        12'd482: toneR = `hdo;     12'd483: toneR = `hdo;
                        
                        12'd484: toneR = `hdo;     12'd485: toneR = `hdo;
                        12'd486: toneR = `hdo;     12'd487: toneR = `hdo;
                        
                        12'd488: toneR = `hdo;     12'd489: toneR = `hdo;
                        12'd490: toneR = `hdo;     12'd491: toneR = `hdo;
                        
                        12'd492: toneR = `hdo;     12'd493: toneR = `hdo;
                        12'd494: toneR = `hdo;     12'd495: toneR = `hdo;
                        
                        12'd496: toneR = `hdo;     12'd497: toneR = `hdo;
                        12'd498: toneR = `hdo;     12'd499: toneR = `hdo;
                        
                        12'd500: toneR = `hdo;     12'd501: toneR = `hdo;
                        12'd502: toneR = `hdo;     12'd503: toneR = `hdo;
                        
                        12'd504: toneR = `hdo;     12'd505: toneR = `hdo;
                        12'd506: toneR = `hdo;     12'd507: toneR = `hdo;
                        
                        12'd508: toneR = `hdo;     12'd509: toneR = `hdo;
                        12'd510: toneR = `hdo;     12'd511: toneR = `hdo;
                        
                        default: toneR = `sil;
                    endcase
                end else begin
                    toneR = `sil;
                end
            end
        end else begin // 龄絃
            case(ibeatNum)
                12'd0: toneR = `do;
                12'd1: toneR = `re;
                12'd2: toneR = `mi;
                12'd3: toneR = `fa;
                12'd4: toneR = `so;
                12'd5: toneR = `la;
                12'd6: toneR = `si;
                12'd7: toneR = `sil;
                default: toneR = `sil;
            endcase
        end
    end
    
    
    
    always @* begin
        if(mode == 1) begin
            if(music == 0) begin
                if(en == 1) begin
                    case(ibeatNum)
                        12'd0: toneL = `hdo;     12'd1: toneL = `hdo;
                        12'd2: toneL = `hdo;     12'd3: toneL = `hdo;
                        12'd4: toneL = `hdo;     12'd5: toneL = `hdo;
                        12'd6: toneL = `hdo;     12'd7: toneL = `hdo;
                        
                        12'd8: toneL = `hdo;     12'd9: toneL = `hdo;
                        12'd10: toneL = `hdo;     12'd11: toneL = `hdo;
                        12'd12: toneL = `hdo;     12'd13: toneL = `hdo;
                        12'd14: toneL = `hdo;     12'd15: toneL = `hdo;
                        
                        12'd16: toneL = `hdo;     12'd17: toneL = `hdo;
                        12'd18: toneL = `hdo;     12'd19: toneL = `hdo;
                        12'd20: toneL = `hdo;     12'd21: toneL = `hdo;
                        12'd22: toneL = `hdo;     12'd23: toneL = `hdo;
                        
                        12'd24: toneL = `hdo;     12'd25: toneL = `hdo;
                        12'd26: toneL = `hdo;     12'd27: toneL = `hdo;
                        12'd28: toneL = `hdo;     12'd29: toneL = `hdo;
                        12'd30: toneL = `hdo;     12'd31: toneL = `hdo;
                        
                        12'd32: toneL = `so;     12'd33: toneL = `so;
                        12'd34: toneL = `so;     12'd35: toneL = `so;
                        12'd36: toneL = `so;     12'd37: toneL = `so;
                        12'd38: toneL = `so;     12'd39: toneL = `so;
                        
                        12'd40: toneL = `so;     12'd41: toneL = `so;
                        12'd42: toneL = `so;     12'd43: toneL = `so;
                        12'd44: toneL = `so;     12'd45: toneL = `so;
                        12'd46: toneL = `so;     12'd47: toneL = `so;
                        
                        12'd48: toneL = `si;     12'd49: toneL = `si;
                        12'd50: toneL = `si;     12'd51: toneL = `si;
                        12'd52: toneL = `si;     12'd53: toneL = `si;
                        12'd54: toneL = `si;     12'd55: toneL = `si;
                        
                        12'd56: toneL = `si;     12'd57: toneL = `si;
                        12'd58: toneL = `si;     12'd59: toneL = `si;
                        12'd60: toneL = `si;     12'd61: toneL = `si;
                        12'd62: toneL = `si;     12'd63: toneL = `si;
                        
                        12'd64: toneL = `hdo;     12'd65: toneL = `hdo;
                        12'd66: toneL = `hdo;     12'd67: toneL = `hdo;
                        12'd68: toneL = `hdo;     12'd69: toneL = `hdo;
                        12'd70: toneL = `hdo;     12'd71: toneL = `hdo;
                        
                        12'd72: toneL = `hdo;     12'd73: toneL = `hdo;
                        12'd74: toneL = `hdo;     12'd75: toneL = `hdo;
                        12'd76: toneL = `hdo;     12'd77: toneL = `hdo;
                        12'd78: toneL = `hdo;     12'd79: toneL = `hdo;
                        
                        12'd80: toneL = `hdo;     12'd81: toneL = `hdo;
                        12'd82: toneL = `hdo;     12'd83: toneL = `hdo;
                        12'd84: toneL = `hdo;     12'd85: toneL = `hdo;
                        12'd86: toneL = `hdo;     12'd87: toneL = `hdo;
                        
                        12'd88: toneL = `hdo;     12'd89: toneL = `hdo;
                        12'd90: toneL = `hdo;     12'd91: toneL = `hdo;
                        12'd92: toneL = `hdo;     12'd93: toneL = `hdo;
                        12'd94: toneL = `hdo;     12'd95: toneL = `hdo;
                        
                        12'd96: toneL = `so;     12'd97: toneL = `so;
                        12'd98: toneL = `so;     12'd99: toneL = `so;
                        12'd100: toneL = `so;     12'd101: toneL = `so;
                        12'd102: toneL = `so;     12'd103: toneL = `so;
                        
                        12'd104: toneL = `so;     12'd105: toneL = `so;
                        12'd106: toneL = `so;     12'd107: toneL = `so;
                        12'd108: toneL = `so;     12'd109: toneL = `so;
                        12'd110: toneL = `so;     12'd111: toneL = `so;
                        
                        12'd112: toneL = `si;     12'd113: toneL = `si;
                        12'd114: toneL = `si;     12'd115: toneL = `si;
                        12'd116: toneL = `si;     12'd117: toneL = `si;
                        12'd118: toneL = `si;     12'd119: toneL = `si;
                        
                        12'd120: toneL = `si;     12'd121: toneL = `si;
                        12'd122: toneL = `si;     12'd123: toneL = `si;
                        12'd124: toneL = `si;     12'd125: toneL = `si;
                        12'd126: toneL = `si;     12'd127: toneL = `si;
                        
                        12'd128: toneL = `hdo;     12'd129: toneL = `hdo;
                        12'd130: toneL = `hdo;     12'd131: toneL = `hdo;
                        12'd132: toneL = `hdo;     12'd133: toneL = `hdo;
                        12'd134: toneL = `hdo;     12'd135: toneL = `hdo;
                        
                        12'd136: toneL = `hdo;     12'd137: toneL = `hdo;
                        12'd138: toneL = `hdo;     12'd139: toneL = `hdo;
                        12'd140: toneL = `hdo;     12'd141: toneL = `hdo;
                        12'd142: toneL = `hdo;     12'd143: toneL = `hdo;
                        
                        12'd144: toneL = `hdo;     12'd145: toneL = `hdo;
                        12'd146: toneL = `hdo;     12'd147: toneL = `hdo;
                        12'd148: toneL = `hdo;     12'd149: toneL = `hdo;
                        12'd150: toneL = `hdo;     12'd151: toneL = `hdo;
                        
                        12'd152: toneL = `hdo;     12'd153: toneL = `hdo;
                        12'd154: toneL = `hdo;     12'd155: toneL = `hdo;
                        12'd156: toneL = `hdo;     12'd157: toneL = `hdo;
                        12'd158: toneL = `hdo;     12'd159: toneL = `hdo;
                        
                        12'd160: toneL = `so;     12'd161: toneL = `so;
                        12'd162: toneL = `so;     12'd163: toneL = `so;
                        12'd164: toneL = `so;     12'd165: toneL = `so;
                        12'd166: toneL = `so;     12'd167: toneL = `so;
                        
                        12'd168: toneL = `so;     12'd169: toneL = `so;
                        12'd170: toneL = `so;     12'd171: toneL = `so;
                        12'd172: toneL = `so;     12'd173: toneL = `so;
                        12'd174: toneL = `so;     12'd175: toneL = `so;
                        
                        12'd176: toneL = `si;     12'd177: toneL = `si;
                        12'd178: toneL = `si;     12'd179: toneL = `si;
                        12'd180: toneL = `si;     12'd181: toneL = `si;
                        12'd182: toneL = `si;     12'd183: toneL = `si;
                        
                        12'd184: toneL = `si;     12'd185: toneL = `si;
                        12'd186: toneL = `si;     12'd187: toneL = `si;
                        12'd188: toneL = `si;     12'd189: toneL = `si;
                        12'd190: toneL = `si;     12'd191: toneL = `si;
                        
                        12'd192: toneL = `hdo;     12'd193: toneL = `hdo;
                        12'd194: toneL = `hdo;     12'd195: toneL = `hdo;
                        12'd196: toneL = `hdo;     12'd197: toneL = `hdo;
                        12'd198: toneL = `hdo;     12'd199: toneL = `hdo;
                        
                        12'd200: toneL = `hdo;     12'd201: toneL = `hdo;
                        12'd202: toneL = `hdo;     12'd203: toneL = `hdo;
                        12'd204: toneL = `hdo;     12'd205: toneL = `hdo;
                        12'd206: toneL = `hdo;     12'd207: toneL = `hdo;
                        
                        12'd208: toneL = `so;     12'd209: toneL = `so;
                        12'd210: toneL = `so;     12'd211: toneL = `so;
                        12'd212: toneL = `so;     12'd213: toneL = `so;
                        12'd214: toneL = `so;     12'd215: toneL = `so;
                        
                        12'd216: toneL = `so;     12'd217: toneL = `so;
                        12'd218: toneL = `so;     12'd219: toneL = `so;
                        12'd220: toneL = `so;     12'd221: toneL = `so;
                        12'd222: toneL = `so;     12'd223: toneL = `so;
                        
                        12'd224: toneL = `mi;     12'd225: toneL = `mi;
                        12'd226: toneL = `mi;     12'd227: toneL = `mi;
                        12'd228: toneL = `mi;     12'd229: toneL = `mi;
                        12'd230: toneL = `mi;     12'd231: toneL = `mi;
                        
                        12'd232: toneL = `mi;     12'd233: toneL = `mi;
                        12'd234: toneL = `mi;     12'd235: toneL = `mi;
                        12'd236: toneL = `mi;     12'd237: toneL = `mi;
                        12'd238: toneL = `mi;     12'd239: toneL = `mi;
                        
                        12'd240: toneL = `do;     12'd241: toneL = `do;
                        12'd242: toneL = `do;     12'd243: toneL = `do;
                        12'd244: toneL = `do;     12'd245: toneL = `do;
                        12'd246: toneL = `do;     12'd247: toneL = `do;
                        
                        12'd248: toneL = `do;     12'd249: toneL = `do;
                        12'd250: toneL = `do;     12'd251: toneL = `do;
                        12'd252: toneL = `do;     12'd253: toneL = `do;
                        12'd254: toneL = `do;     12'd255: toneL = `do;
                        
                        12'd256: toneL = `so;     12'd257: toneL = `so;
                        12'd258: toneL = `so;     12'd259: toneL = `so;
                        12'd260: toneL = `so;     12'd261: toneL = `so;
                        12'd262: toneL = `so;     12'd263: toneL = `so;
                        
                        12'd264: toneL = `so;     12'd265: toneL = `so;
                        12'd266: toneL = `so;     12'd267: toneL = `so;
                        12'd268: toneL = `so;     12'd269: toneL = `so;
                        12'd270: toneL = `so;     12'd271: toneL = `so;
                        
                        12'd272: toneL = `so;     12'd273: toneL = `so;
                        12'd274: toneL = `so;     12'd275: toneL = `so;
                        12'd276: toneL = `so;     12'd277: toneL = `so;
                        12'd278: toneL = `so;     12'd279: toneL = `so;
                        
                        12'd280: toneL = `so;     12'd281: toneL = `so;
                        12'd282: toneL = `so;     12'd283: toneL = `so;
                        12'd284: toneL = `so;     12'd285: toneL = `so;
                        12'd286: toneL = `so;     12'd287: toneL = `so;
                        
                        12'd288: toneL = `fa;     12'd289: toneL = `fa;
                        12'd290: toneL = `fa;     12'd291: toneL = `fa;
                        12'd292: toneL = `fa;     12'd293: toneL = `fa;
                        12'd294: toneL = `fa;     12'd295: toneL = `fa;
                        
                        12'd296: toneL = `fa;     12'd297: toneL = `fa;
                        12'd298: toneL = `fa;     12'd299: toneL = `fa;
                        12'd300: toneL = `fa;     12'd301: toneL = `fa;
                        12'd302: toneL = `fa;     12'd303: toneL = `fa;
                        
                        12'd304: toneL = `re;     12'd305: toneL = `re;
                        12'd306: toneL = `re;     12'd307: toneL = `re;
                        12'd308: toneL = `re;     12'd309: toneL = `re;
                        12'd310: toneL = `re;     12'd311: toneL = `re;
                        
                        12'd312: toneL = `re;     12'd313: toneL = `re;
                        12'd314: toneL = `re;     12'd315: toneL = `re;
                        12'd316: toneL = `re;     12'd317: toneL = `re;
                        12'd318: toneL = `re;     12'd319: toneL = `re;
                        
                        12'd320: toneL = `mi;     12'd321: toneL = `mi;
                        12'd322: toneL = `mi;     12'd323: toneL = `mi;
                        12'd324: toneL = `mi;     12'd325: toneL = `mi;
                        12'd326: toneL = `mi;     12'd327: toneL = `mi;
                        
                        12'd328: toneL = `mi;     12'd329: toneL = `mi;
                        12'd330: toneL = `mi;     12'd331: toneL = `mi;
                        12'd332: toneL = `mi;     12'd333: toneL = `mi;
                        12'd334: toneL = `mi;     12'd335: toneL = `mi;
                        
                        12'd336: toneL = `mi;     12'd337: toneL = `mi;
                        12'd338: toneL = `mi;     12'd339: toneL = `mi;
                        12'd340: toneL = `mi;     12'd341: toneL = `mi;
                        12'd342: toneL = `mi;     12'd343: toneL = `mi;
                        
                        12'd344: toneL = `mi;     12'd345: toneL = `mi;
                        12'd346: toneL = `mi;     12'd347: toneL = `mi;
                        12'd348: toneL = `mi;     12'd349: toneL = `mi;
                        12'd350: toneL = `mi;     12'd351: toneL = `mi;
                        
                        12'd352: toneL = `so;     12'd353: toneL = `so;
                        12'd354: toneL = `so;     12'd355: toneL = `so;
                        12'd356: toneL = `so;     12'd357: toneL = `so;
                        12'd358: toneL = `so;     12'd359: toneL = `so;
                        
                        12'd360: toneL = `so;     12'd361: toneL = `so;
                        12'd362: toneL = `so;     12'd363: toneL = `so;
                        12'd364: toneL = `so;     12'd365: toneL = `so;
                        12'd366: toneL = `so;     12'd367: toneL = `so;
                        
                        12'd368: toneL = `si;     12'd369: toneL = `si;
                        12'd370: toneL = `si;     12'd371: toneL = `si;
                        12'd372: toneL = `si;     12'd373: toneL = `si;
                        12'd374: toneL = `si;     12'd375: toneL = `si;
                        
                        12'd376: toneL = `si;     12'd377: toneL = `si;
                        12'd378: toneL = `si;     12'd379: toneL = `si;
                        12'd380: toneL = `si;     12'd381: toneL = `si;
                        12'd382: toneL = `si;     12'd383: toneL = `si;
                        
                        12'd384: toneL = `hdo;     12'd385: toneL = `hdo;
                        12'd386: toneL = `hdo;     12'd387: toneL = `hdo;
                        12'd388: toneL = `hdo;     12'd389: toneL = `hdo;
                        12'd390: toneL = `hdo;     12'd391: toneL = `hdo;
                        
                        12'd392: toneL = `hdo;     12'd393: toneL = `hdo;
                        12'd394: toneL = `hdo;     12'd395: toneL = `hdo;
                        12'd396: toneL = `hdo;     12'd397: toneL = `hdo;
                        12'd398: toneL = `hdo;     12'd399: toneL = `hdo;
                        
                        12'd400: toneL = `hdo;     12'd401: toneL = `hdo;
                        12'd402: toneL = `hdo;     12'd403: toneL = `hdo;
                        12'd404: toneL = `hdo;     12'd405: toneL = `hdo;
                        12'd406: toneL = `hdo;     12'd407: toneL = `hdo;
                        
                        12'd408: toneL = `hdo;     12'd409: toneL = `hdo;
                        12'd410: toneL = `hdo;     12'd411: toneL = `hdo;
                        12'd412: toneL = `hdo;     12'd413: toneL = `hdo;
                        12'd414: toneL = `hdo;     12'd415: toneL = `hdo;
                        
                        12'd416: toneL = `so;     12'd417: toneL = `so;
                        12'd418: toneL = `so;     12'd419: toneL = `so;
                        12'd420: toneL = `so;     12'd421: toneL = `so;
                        12'd422: toneL = `so;     12'd423: toneL = `so;
                        
                        12'd424: toneL = `so;     12'd425: toneL = `so;
                        12'd426: toneL = `so;     12'd427: toneL = `so;
                        12'd428: toneL = `so;     12'd429: toneL = `so;
                        12'd430: toneL = `so;     12'd431: toneL = `so;
                        
                        12'd432: toneL = `si;     12'd433: toneL = `si;
                        12'd434: toneL = `si;     12'd435: toneL = `si;
                        12'd436: toneL = `si;     12'd437: toneL = `si;
                        12'd438: toneL = `si;     12'd439: toneL = `si;
                        
                        12'd440: toneL = `si;     12'd441: toneL = `si;
                        12'd442: toneL = `si;     12'd443: toneL = `si;
                        12'd444: toneL = `si;     12'd445: toneL = `si;
                        12'd446: toneL = `si;     12'd447: toneL = `si;
                        
                        12'd448: toneL = `hdo;     12'd449: toneL = `hdo;
                        12'd450: toneL = `hdo;     12'd451: toneL = `hdo;
                        12'd452: toneL = `hdo;     12'd453: toneL = `hdo;
                        12'd454: toneL = `hdo;     12'd455: toneL = `hdo;
                        
                        12'd456: toneL = `hdo;     12'd457: toneL = `hdo;
                        12'd458: toneL = `hdo;     12'd459: toneL = `hdo;
                        12'd460: toneL = `hdo;     12'd461: toneL = `hdo;
                        12'd462: toneL = `hdo;     12'd463: toneL = `hdo;
                        
                        12'd464: toneL = `so;     12'd465: toneL = `so;
                        12'd466: toneL = `so;     12'd467: toneL = `so;
                        12'd468: toneL = `so;     12'd469: toneL = `so;
                        12'd470: toneL = `so;     12'd471: toneL = `so;
                        
                        12'd472: toneL = `so;     12'd473: toneL = `so;
                        12'd474: toneL = `so;     12'd475: toneL = `so;
                        12'd476: toneL = `so;     12'd477: toneL = `so;
                        12'd478: toneL = `so;     12'd479: toneL = `so;
                        
                        12'd480: toneL = `do;     12'd481: toneL = `do;
                        12'd482: toneL = `do;     12'd483: toneL = `do;
                        12'd484: toneL = `do;     12'd485: toneL = `do;
                        12'd486: toneL = `do;     12'd487: toneL = `do;
                        
                        12'd488: toneL = `do;     12'd489: toneL = `do;
                        12'd490: toneL = `do;     12'd491: toneL = `do;
                        12'd492: toneL = `do;     12'd493: toneL = `do;
                        12'd494: toneL = `do;     12'd495: toneL = `do;
                        
                        12'd496: toneL = `do;     12'd497: toneL = `do;
                        12'd498: toneL = `do;     12'd499: toneL = `do;
                        12'd500: toneL = `do;     12'd501: toneL = `do;
                        12'd502: toneL = `do;     12'd503: toneL = `do;
                        
                        12'd504: toneL = `do;     12'd505: toneL = `do;
                        12'd506: toneL = `do;     12'd507: toneL = `do;
                        12'd508: toneL = `do;     12'd509: toneL = `do;
                        12'd510: toneL = `do;     12'd511: toneL = `do;
                        
                        default: toneL = `sil;
                    endcase
                end else begin
                    toneL = `sil;
                end
            end else begin //材簈
                if(en == 1) begin
                    case(ibeatNum)
                        12'd0: toneL = `hdo;     12'd1: toneL = `hdo;
                        12'd2: toneL = `hdo;     12'd3: toneL = `hdo;
                        12'd4: toneL = `hdo;     12'd5: toneL = `hdo;
                        12'd6: toneL = `hdo;     12'd7: toneL = `hdo;
                        
                        12'd8: toneL = `hdo;     12'd9: toneL = `hdo;
                        12'd10: toneL = `hdo;     12'd11: toneL = `hdo;
                        12'd12: toneL = `hdo;     12'd13: toneL = `hdo;
                        12'd14: toneL = `hdo;     12'd15: toneL = `hdo;
                        
                        12'd16: toneL = `so;     12'd17: toneL = `so;
                        12'd18: toneL = `so;     12'd19: toneL = `so;
                        12'd20: toneL = `so;     12'd21: toneL = `so;
                        12'd22: toneL = `so;     12'd23: toneL = `so;
                        
                        12'd24: toneL = `so;     12'd25: toneL = `so;
                        12'd26: toneL = `so;     12'd27: toneL = `so;
                        12'd28: toneL = `so;     12'd29: toneL = `so;
                        12'd30: toneL = `so;     12'd31: toneL = `so;
                        
                        12'd32: toneL = `hdo;     12'd33: toneL = `hdo;
                        12'd34: toneL = `hdo;     12'd35: toneL = `hdo;
                        12'd36: toneL = `hdo;     12'd37: toneL = `hdo;
                        12'd38: toneL = `hdo;     12'd39: toneL = `hdo;
                        
                        12'd40: toneL = `hdo;     12'd41: toneL = `hdo;
                        12'd42: toneL = `hdo;     12'd43: toneL = `hdo;
                        12'd44: toneL = `hdo;     12'd45: toneL = `hdo;
                        12'd46: toneL = `hdo;     12'd47: toneL = `hdo;
                        
                        12'd48: toneL = `so;     12'd49: toneL = `so;
                        12'd50: toneL = `so;     12'd51: toneL = `so;
                        12'd52: toneL = `so;     12'd53: toneL = `so;
                        12'd54: toneL = `so;     12'd55: toneL = `so;
                        
                        12'd56: toneL = `so;     12'd57: toneL = `so;
                        12'd58: toneL = `so;     12'd59: toneL = `so;
                        12'd60: toneL = `so;     12'd61: toneL = `so;
                        12'd62: toneL = `so;     12'd63: toneL = `so;
                        
                        12'd64: toneL = `hdo;     12'd65: toneL = `hdo;
                        12'd66: toneL = `hdo;     12'd67: toneL = `hdo;
                        12'd68: toneL = `hdo;     12'd69: toneL = `hdo;
                        12'd70: toneL = `hdo;     12'd71: toneL = `hdo;
                        
                        12'd72: toneL = `hdo;     12'd73: toneL = `hdo;
                        12'd74: toneL = `hdo;     12'd75: toneL = `hdo;
                        12'd76: toneL = `hdo;     12'd77: toneL = `hdo;
                        12'd78: toneL = `hdo;     12'd79: toneL = `hdo;
                        
                        12'd80: toneL = `so;     12'd81: toneL = `so;
                        12'd82: toneL = `so;     12'd83: toneL = `so;
                        12'd84: toneL = `so;     12'd85: toneL = `so;
                        12'd86: toneL = `so;     12'd87: toneL = `so;
                        
                        12'd88: toneL = `so;     12'd89: toneL = `so;
                        12'd90: toneL = `so;     12'd91: toneL = `so;
                        12'd92: toneL = `so;     12'd93: toneL = `so;
                        12'd94: toneL = `so;     12'd95: toneL = `so;
                        
                        12'd96: toneL = `hdo;     12'd97: toneL = `hdo;
                        12'd98: toneL = `hdo;     12'd99: toneL = `hdo;
                        12'd100: toneL = `hdo;     12'd101: toneL = `hdo;
                        12'd102: toneL = `hdo;     12'd103: toneL = `hdo;
                        
                        12'd104: toneL = `so;     12'd105: toneL = `so;
                        12'd106: toneL = `so;     12'd107: toneL = `so;
                        12'd108: toneL = `so;     12'd109: toneL = `so;
                        12'd110: toneL = `so;     12'd111: toneL = `so;
                        
                        12'd112: toneL = `la;     12'd113: toneL = `la;
                        12'd114: toneL = `la;     12'd115: toneL = `la;
                        12'd116: toneL = `la;     12'd117: toneL = `la;
                        12'd118: toneL = `la;     12'd119: toneL = `la;
                        
                        12'd120: toneL = `si;     12'd121: toneL = `si;
                        12'd122: toneL = `si;     12'd123: toneL = `si;
                        12'd124: toneL = `si;     12'd125: toneL = `si;
                        12'd126: toneL = `si;     12'd127: toneL = `si;
                        
                        12'd128: toneL = `hre;     12'd129: toneL = `hre;
                        12'd130: toneL = `hre;     12'd131: toneL = `hre;
                        12'd132: toneL = `hre;     12'd133: toneL = `hre;
                        12'd134: toneL = `hre;     12'd135: toneL = `hre;
                        
                        12'd136: toneL = `hre;     12'd137: toneL = `hre;
                        12'd138: toneL = `hre;     12'd139: toneL = `hre;
                        12'd140: toneL = `hre;     12'd141: toneL = `hre;
                        12'd142: toneL = `hre;     12'd143: toneL = `hre;
                        
                        12'd144: toneL = `fa;     12'd145: toneL = `fa;
                        12'd146: toneL = `fa;     12'd147: toneL = `fa;
                        12'd148: toneL = `fa;     12'd149: toneL = `fa;
                        12'd150: toneL = `fa;     12'd151: toneL = `fa;
                        
                        12'd152: toneL = `fa;     12'd153: toneL = `fa;
                        12'd154: toneL = `fa;     12'd155: toneL = `fa;
                        12'd156: toneL = `fa;     12'd157: toneL = `fa;
                        12'd158: toneL = `fa;     12'd159: toneL = `fa;
                        
                        12'd160: toneL = `hdo;     12'd161: toneL = `hdo;
                        12'd162: toneL = `hdo;     12'd163: toneL = `hdo;
                        12'd164: toneL = `hdo;     12'd165: toneL = `hdo;
                        12'd166: toneL = `hdo;     12'd167: toneL = `hdo;
                        
                        12'd168: toneL = `hdo;     12'd169: toneL = `hdo;
                        12'd170: toneL = `hdo;     12'd171: toneL = `hdo;
                        12'd172: toneL = `hdo;     12'd173: toneL = `hdo;
                        12'd174: toneL = `hdo;     12'd175: toneL = `hdo;
                        
                        12'd176: toneL = `mi;     12'd177: toneL = `mi;
                        12'd178: toneL = `mi;     12'd179: toneL = `mi;
                        12'd180: toneL = `mi;     12'd181: toneL = `mi;
                        12'd182: toneL = `mi;     12'd183: toneL = `mi;
                        
                        12'd184: toneL = `mi;     12'd185: toneL = `mi;
                        12'd186: toneL = `mi;     12'd187: toneL = `mi;
                        12'd188: toneL = `mi;     12'd189: toneL = `mi;
                        12'd190: toneL = `mi;     12'd191: toneL = `mi;
                        
                        12'd192: toneL = `so;     12'd193: toneL = `so;
                        12'd194: toneL = `so;     12'd195: toneL = `so;
                        12'd196: toneL = `so;     12'd197: toneL = `so;
                        12'd198: toneL = `so;     12'd199: toneL = `so;
                        
                        12'd200: toneL = `so;     12'd201: toneL = `so;
                        12'd202: toneL = `so;     12'd203: toneL = `so;
                        12'd204: toneL = `so;     12'd205: toneL = `so;
                        12'd206: toneL = `so;     12'd207: toneL = `so;
                        
                        12'd208: toneL = `fa;     12'd209: toneL = `fa;
                        12'd210: toneL = `fa;     12'd211: toneL = `fa;
                        12'd212: toneL = `fa;     12'd213: toneL = `fa;
                        12'd214: toneL = `fa;     12'd215: toneL = `fa;
                        
                        12'd216: toneL = `fa;     12'd217: toneL = `fa;
                        12'd218: toneL = `fa;     12'd219: toneL = `fa;
                        12'd220: toneL = `fa;     12'd221: toneL = `fa;
                        12'd222: toneL = `fa;     12'd223: toneL = `fa;
                        
                        12'd224: toneL = `re;     12'd225: toneL = `re;
                        12'd226: toneL = `re;     12'd227: toneL = `re;
                        12'd228: toneL = `re;     12'd229: toneL = `re;
                        12'd230: toneL = `re;     12'd231: toneL = `re;
                        
                        12'd232: toneL = `re;     12'd233: toneL = `re;
                        12'd234: toneL = `re;     12'd235: toneL = `re;
                        12'd236: toneL = `re;     12'd237: toneL = `re;
                        12'd238: toneL = `re;     12'd239: toneL = `re;
                        
                        12'd240: toneL = `si;     12'd241: toneL = `si;
                        12'd242: toneL = `si;     12'd243: toneL = `si;
                        12'd244: toneL = `si;     12'd245: toneL = `si;
                        12'd246: toneL = `si;     12'd247: toneL = `si;
                        
                        12'd248: toneL = `si;     12'd249: toneL = `si;
                        12'd250: toneL = `si;     12'd251: toneL = `si;
                        12'd252: toneL = `si;     12'd253: toneL = `si;
                        12'd254: toneL = `si;     12'd255: toneL = `si;
                        
                        12'd256: toneL = `hdo;     12'd257: toneL = `hdo;
                        12'd258: toneL = `hdo;     12'd259: toneL = `hdo;
                        12'd260: toneL = `hdo;     12'd261: toneL = `hdo;
                        12'd262: toneL = `hdo;     12'd263: toneL = `hdo;
                        
                        12'd264: toneL = `hdo;     12'd265: toneL = `hdo;
                        12'd266: toneL = `hdo;     12'd267: toneL = `hdo;
                        12'd268: toneL = `hdo;     12'd269: toneL = `hdo;
                        12'd270: toneL = `hdo;     12'd271: toneL = `hdo;
                        
                        12'd272: toneL = `so;     12'd273: toneL = `so;
                        12'd274: toneL = `so;     12'd275: toneL = `so;
                        12'd276: toneL = `so;     12'd277: toneL = `so;
                        12'd278: toneL = `so;     12'd279: toneL = `so;
                        
                        12'd280: toneL = `so;     12'd281: toneL = `so;
                        12'd282: toneL = `so;     12'd283: toneL = `so;
                        12'd284: toneL = `so;     12'd285: toneL = `so;
                        12'd286: toneL = `so;     12'd287: toneL = `so;
                        
                        12'd288: toneL = `hdo;     12'd289: toneL = `hdo;
                        12'd290: toneL = `hdo;     12'd291: toneL = `hdo;
                        12'd292: toneL = `hdo;     12'd293: toneL = `hdo;
                        12'd294: toneL = `hdo;     12'd295: toneL = `hdo;
                        
                        12'd296: toneL = `hdo;     12'd297: toneL = `hdo;
                        12'd298: toneL = `hdo;     12'd299: toneL = `hdo;
                        12'd300: toneL = `hdo;     12'd301: toneL = `hdo;
                        12'd302: toneL = `hdo;     12'd303: toneL = `hdo;
                        
                        12'd304: toneL = `so;     12'd305: toneL = `so;
                        12'd306: toneL = `so;     12'd307: toneL = `so;
                        12'd308: toneL = `so;     12'd309: toneL = `so;
                        12'd310: toneL = `so;     12'd311: toneL = `so;
                        
                        12'd312: toneL = `so;     12'd313: toneL = `so;
                        12'd314: toneL = `so;     12'd315: toneL = `so;
                        12'd316: toneL = `so;     12'd317: toneL = `so;
                        12'd318: toneL = `so;     12'd319: toneL = `so;
                        
                        12'd320: toneL = `hdo;     12'd321: toneL = `hdo;
                        12'd322: toneL = `hdo;     12'd323: toneL = `hdo;
                        12'd324: toneL = `hdo;     12'd325: toneL = `hdo;
                        12'd326: toneL = `hdo;     12'd327: toneL = `hdo;
                        
                        12'd328: toneL = `hdo;     12'd329: toneL = `hdo;
                        12'd330: toneL = `hdo;     12'd331: toneL = `hdo;
                        12'd332: toneL = `hdo;     12'd333: toneL = `hdo;
                        12'd334: toneL = `hdo;     12'd335: toneL = `hdo;
                        
                        12'd336: toneL = `so;     12'd337: toneL = `so;
                        12'd338: toneL = `so;     12'd339: toneL = `so;
                        12'd340: toneL = `so;     12'd341: toneL = `so;
                        12'd342: toneL = `so;     12'd343: toneL = `so;
                        
                        12'd344: toneL = `so;     12'd345: toneL = `so;
                        12'd346: toneL = `so;     12'd347: toneL = `so;
                        12'd348: toneL = `so;     12'd349: toneL = `so;
                        12'd350: toneL = `so;     12'd351: toneL = `so;
                        
                        12'd352: toneL = `hdo;     12'd353: toneL = `hdo;
                        12'd354: toneL = `hdo;     12'd355: toneL = `hdo;
                        12'd356: toneL = `hdo;     12'd357: toneL = `hdo;
                        12'd358: toneL = `hdo;     12'd359: toneL = `hdo;
                        
                        12'd360: toneL = `so;     12'd361: toneL = `so;
                        12'd362: toneL = `so;     12'd363: toneL = `so;
                        12'd364: toneL = `so;     12'd365: toneL = `so;
                        12'd366: toneL = `so;     12'd367: toneL = `so;
                        
                        12'd368: toneL = `la;     12'd369: toneL = `la;
                        12'd370: toneL = `la;     12'd371: toneL = `la;
                        12'd372: toneL = `la;     12'd373: toneL = `la;
                        12'd374: toneL = `la;     12'd375: toneL = `la;
                        
                        12'd376: toneL = `si;     12'd377: toneL = `si;
                        12'd378: toneL = `si;     12'd379: toneL = `si;
                        12'd380: toneL = `si;     12'd381: toneL = `si;
                        12'd382: toneL = `si;     12'd383: toneL = `si;
                        
                        12'd384: toneL = `hre;     12'd385: toneL = `hre;
                        12'd386: toneL = `hre;     12'd387: toneL = `hre;
                        12'd388: toneL = `hre;     12'd389: toneL = `hre;
                        12'd390: toneL = `hre;     12'd391: toneL = `hre;
                        
                        12'd392: toneL = `hre;     12'd393: toneL = `hre;
                        12'd394: toneL = `hre;     12'd395: toneL = `hre;
                        12'd396: toneL = `hre;     12'd397: toneL = `hre;
                        12'd398: toneL = `hre;     12'd399: toneL = `hre;
                        
                        12'd400: toneL = `fa;     12'd401: toneL = `fa;
                        12'd402: toneL = `fa;     12'd403: toneL = `fa;
                        12'd404: toneL = `fa;     12'd405: toneL = `fa;
                        12'd406: toneL = `fa;     12'd407: toneL = `fa;
                        
                        12'd408: toneL = `fa;     12'd409: toneL = `fa;
                        12'd410: toneL = `fa;     12'd411: toneL = `fa;
                        12'd412: toneL = `fa;     12'd413: toneL = `fa;
                        12'd414: toneL = `fa;     12'd415: toneL = `fa;
                        
                        12'd416: toneL = `hdo;     12'd417: toneL = `hdo;
                        12'd418: toneL = `hdo;     12'd419: toneL = `hdo;
                        12'd420: toneL = `hdo;     12'd421: toneL = `hdo;
                        12'd422: toneL = `hdo;     12'd423: toneL = `hdo;
                        
                        12'd424: toneL = `hdo;     12'd425: toneL = `hdo;
                        12'd426: toneL = `hdo;     12'd427: toneL = `hdo;
                        12'd428: toneL = `hdo;     12'd429: toneL = `hdo;
                        12'd430: toneL = `hdo;     12'd431: toneL = `hdo;
                        
                        12'd432: toneL = `mi;     12'd433: toneL = `mi;
                        12'd434: toneL = `mi;     12'd435: toneL = `mi;
                        12'd436: toneL = `mi;     12'd437: toneL = `mi;
                        12'd438: toneL = `mi;     12'd439: toneL = `mi;
                        
                        12'd440: toneL = `mi;     12'd441: toneL = `mi;
                        12'd442: toneL = `mi;     12'd443: toneL = `mi;
                        12'd444: toneL = `mi;     12'd445: toneL = `mi;
                        12'd446: toneL = `mi;     12'd447: toneL = `mi;
                        
                        12'd448: toneL = `hdo;     12'd449: toneL = `hdo;
                        12'd450: toneL = `hdo;     12'd451: toneL = `hdo;
                        12'd452: toneL = `hdo;     12'd453: toneL = `hdo;
                        12'd454: toneL = `hdo;     12'd455: toneL = `hdo;
                        
                        12'd456: toneL = `hdo;     12'd457: toneL = `hdo;
                        12'd458: toneL = `hdo;     12'd459: toneL = `hdo;
                        12'd460: toneL = `hdo;     12'd461: toneL = `hdo;
                        12'd462: toneL = `hdo;     12'd463: toneL = `hdo;
                        
                        12'd464: toneL = `so;     12'd465: toneL = `so;
                        12'd466: toneL = `so;     12'd467: toneL = `so;
                        12'd468: toneL = `so;     12'd469: toneL = `so;
                        12'd470: toneL = `so;     12'd471: toneL = `so;
                        
                        12'd472: toneL = `so;     12'd473: toneL = `so;
                        12'd474: toneL = `so;     12'd475: toneL = `so;
                        12'd476: toneL = `so;     12'd477: toneL = `so;
                        12'd478: toneL = `so;     12'd479: toneL = `so;
                        
                        12'd480: toneL = `do;     12'd481: toneL = `do;
                        12'd482: toneL = `do;     12'd483: toneL = `do;
                        12'd484: toneL = `do;     12'd485: toneL = `do;
                        12'd486: toneL = `do;     12'd487: toneL = `do;
                        
                        12'd488: toneL = `do;     12'd489: toneL = `do;
                        12'd490: toneL = `do;     12'd491: toneL = `do;
                        12'd492: toneL = `do;     12'd493: toneL = `do;
                        12'd494: toneL = `do;     12'd495: toneL = `do;
                        
                        12'd496: toneL = `sil;     12'd497: toneL = `sil;
                        12'd498: toneL = `sil;     12'd499: toneL = `sil;
                        12'd500: toneL = `sil;     12'd501: toneL = `sil;
                        12'd502: toneL = `sil;     12'd503: toneL = `sil;
                        
                        12'd504: toneL = `sil;     12'd505: toneL = `sil;
                        12'd506: toneL = `sil;     12'd507: toneL = `sil;
                        12'd508: toneL = `sil;     12'd509: toneL = `sil;
                        12'd510: toneL = `sil;     12'd511: toneL = `sil;
                        default: toneL = `sil;
                    endcase
                end else begin
                    toneL = `sil;
                end
            end
        end else begin // 龄絃
            case(ibeatNum)
                12'd0: toneL = `do;
                12'd1: toneL = `re;
                12'd2: toneL = `mi;
                12'd3: toneL = `fa;
                12'd4: toneL = `so;
                12'd5: toneL = `la;
                12'd6: toneL = `si;
                12'd7: toneL = `sil;
                default: toneL = `sil;
            endcase
        end
    end

    
endmodule
