module Lab9(
    input clk,
    input rst,
    input echo,
    input left_track,
    input right_track,
    input mid_track,
    output trig,
    output IN1,
    output IN2,
    output IN3, 
    output IN4,
    output left_pwm,
    output right_pwm,
    // You may modify or add more input/ouput yourself.
    output [3:0] led
);
    // We have connected the motor, tracker_sensor and sonic_top modules in the template file for you.
    // TODO: control the motors with the information you get from ultrasonic sensor and 3-way track sensor.

    reg [1:0] mode;
    wire [19:0] distance;
    wire [1:0] tracker_state;
    
    always @* begin
        if(rst == 1) begin
            mode = 2'b10;
        end else if(distance <= 30) begin
            mode = 2'b11;
        end else if(tracker_state == 2'b00) begin
            mode = tracker_state;
        end else if(tracker_state == 2'b01) begin
            mode = tracker_state;
        end else if(tracker_state == 2'b10) begin
            mode = tracker_state;
        end else begin
            mode = 2'b10;
        end
    end
    
    motor A(
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .pwm({left_pwm, right_pwm}),
        .l_IN({IN1, IN2}),
        .r_IN({IN3, IN4})
    );

    sonic_top B(
        .clk(clk), 
        .rst(rst), 
        .Echo(echo), 
        .Trig(trig),
        .distance(distance)
    );

    tracker_sensor C(
        .clk(clk), 
        .reset(rst), 
        .left_track(~left_track), 
        .right_track(~right_track),
        .mid_track(~mid_track), 
        .state(tracker_state),
        .led(led)
    );

endmodule

// This module take "mode" input and control two motors accordingly.
// clk should be 100MHz for PWM_gen module to work correctly.
// You can modify / add more inputs and outputs by yourself.
module motor(
    input clk,
    input rst,
    input [1:0]mode,
    output  [1:0]pwm,
    output reg [1:0]r_IN,
    output reg [1:0]l_IN
);

    reg [9:0]next_left_motor, next_right_motor;
    reg [9:0]left_motor, right_motor;
    wire left_pwm, right_pwm;

    motor_pwm m0(clk, rst, left_motor, left_pwm);
    motor_pwm m1(clk, rst, right_motor, right_pwm);

    assign pwm = {left_pwm,right_pwm};

    // TODO: trace the rest of motor.v and control the speed and direction of the two motors
    always @(posedge clk) begin
        if(rst == 1) begin
            left_motor <= 0;
            right_motor <= 0;
        end else begin
            left_motor <= next_left_motor;
            right_motor <= next_right_motor;
        end
    end

    always @* begin
        case(mode)
            2'b00: begin
                next_left_motor = 100;
                next_right_motor = 700;
                r_IN = 2'b10;
                l_IN = 2'b11;
            end
            2'b01: begin
                next_left_motor = 700;
                next_right_motor = 100;
                r_IN = 2'b11;
                l_IN = 2'b01;
            end
            2'b10: begin
                next_left_motor = 700;
                next_right_motor = 700;
                r_IN = 2'b10;
                l_IN = 2'b01;
            end
            2'b11: begin
                next_left_motor = 0;
                next_right_motor = 0;
                r_IN = 2'b11;
                l_IN = 2'b11;
            end
        endcase
    end
    
endmodule

module motor_pwm (
    input clk,
    input reset,
    input [9:0]duty,
	output pmod_1 //PWM
);
        
    PWM_gen pwm_0 ( 
        .clk(clk), 
        .reset(reset), 
        .freq(32'd25000),
        .duty(duty), 
        .PWM(pmod_1)
    );

endmodule

//generte PWM by input frequency & duty cycle
module PWM_gen (
    input wire clk,
    input wire reset,
	input [31:0] freq,
    input [9:0] duty,
    output reg PWM
);
    wire [31:0] count_max = 100_000_000 / freq;
    wire [31:0] count_duty = count_max * duty / 1024;
    reg [31:0] count;
        
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            PWM <= 0;
        end else if (count < count_max) begin
            count <= count + 1;
            if(count < count_duty)
                PWM <= 1;
            else
                PWM <= 0;
        end else begin
            count <= 0;
            PWM <= 0;
        end
    end
endmodule

// sonic_top is the module to interface with sonic sensors
// clk = 100MHz
// <Trig> and <Echo> should connect to the sensor
// <distance> is the output distance in cm
module sonic_top(clk, rst, Echo, Trig, distance);
	input clk, rst, Echo;
	output Trig;
    output [19:0] distance;

	wire[19:0] dis;
    wire clk1M;
	wire clk_2_17;

    assign distance = dis;

    div clk1(clk ,clk1M);
	TrigSignal u1(.clk(clk), .rst(rst), .trig(Trig));
	PosCounter u2(.clk(clk1M), .rst(rst), .echo(Echo), .distance_count(dis));
 
endmodule

module PosCounter(clk, rst, echo, distance_count); 
    input clk, rst, echo;
    output[19:0] distance_count;

    parameter S0 = 2'b00;
    parameter S1 = 2'b01; 
    parameter S2 = 2'b10;
    
    wire start, finish;
    reg[1:0] curr_state, next_state;
    reg echo_reg1, echo_reg2;
    reg[19:0] count, distance_register;
    wire[19:0] distance_count; 

    always@(posedge clk) begin
        if(rst) begin
            echo_reg1 <= 0;
            echo_reg2 <= 0;
            count <= 0;
            distance_register  <= 0;
            curr_state <= S0;
        end
        else begin
            echo_reg1 <= echo;   
            echo_reg2 <= echo_reg1; 
            case(curr_state)
                S0:begin
                    if (start) curr_state <= next_state; //S1
                    else count <= 0;
                end
                S1:begin
                    if (finish) curr_state <= next_state; //S2
                    else count <= count + 1;
                end
                S2:begin
                    distance_register <= count;
                    count <= 0;
                    curr_state <= next_state; //S0
                end
            endcase
        end
    end

    always @(*) begin
        case(curr_state)
            S0:next_state = S1;
            S1:next_state = S2;
            S2:next_state = S0;
            default:next_state = S0;
        endcase
    end

    assign start = echo_reg1 & ~echo_reg2;
    assign finish = ~echo_reg1 & echo_reg2;

    // TODO: trace the code and calculate the distance, output it to <distance_count>
    assign distance_count = (distance_register / 2) * 34/1000;
    
endmodule

// send trigger signal to sensor
module TrigSignal(clk, rst, trig);
    input clk, rst;
    output trig;

    reg trig, next_trig;
    reg[23:0] count, next_count;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            trig <= 0;
        end
        else begin
            count <= next_count;
            trig <= next_trig;
        end
    end
    // count 10us to set trig high and wait for 100ms
    always @(*) begin
        next_trig = trig;
        next_count = count + 1;
        if(count == 999)
            next_trig = 0;
        else if(count == 24'd9999999) begin
            next_trig = 1;
            next_count = 0;
        end
    end
endmodule
/*
// clock divider for T = 1us clock
module div(clk ,out_clk);
    input clk;
    output out_clk;
    reg out_clk;
    reg [6:0]cnt;
    
    always @(posedge clk) begin   
        if(cnt < 7'd50) begin
            cnt <= cnt + 1'b1;
            out_clk <= 1'b1;
        end 
        else if(cnt < 7'd100) begin
	        cnt <= cnt + 1'b1;
	        out_clk <= 1'b0;
        end
        else if(cnt == 7'd100) begin
            cnt <= 0;
            out_clk <= 1'b1;
        end
    end
endmodule
*/
module tracker_sensor(clk, reset, left_track, right_track, mid_track, state, led);
    input clk;
    input reset;
    input left_track, right_track, mid_track;
    output reg [1:0] state;
    
    output [3:0] led;
    assign led = (state == 0) ? (4'b0001):((state == 1) ? (4'b0010):((state == 2) ? (4'b0100):(4'b1000)));
    
    // TODO: Receive three tracks and make your own policy.
    // Hint: You can use output state to change your action.

    always @(posedge clk or posedge reset) begin
        if(reset == 1) begin
            state <= 3;
        end else if(mid_track == 1) begin
            state <= 2;
        end else if(left_track == 1) begin
            state <= 0;
        end else if(right_track == 1) begin
            state <= 1;
        end else begin
            state <= 2;
        end
    end
endmodule
