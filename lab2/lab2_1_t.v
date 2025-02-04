`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/29 22:46:28
// Design Name: 
// Module Name: lab2_1_t
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


module lab2_1_t;
    reg clk,rst;
    wire [5:0] out;
    reg pass;
    reg [5:0] res; //should be
    reg [5:0] index;
    
    lab2_1 counter(clk,rst,out);
    
    always #5 clk = ~clk;
    always @(posedge clk) begin
        cal();
    end
    always @(negedge clk) begin
        test();
    end
    
    
    initial begin
        clk = 1'b1;
        pass = 1'b1;
        rst = 1'b0;
        res = 6'b000000;
        index = 6'b000000;
        
        $display("Starting the simulation");
        
        
        #25 if(!pass) $display(">>>> Error1 occurs.");
        #5 rst = 1'b1;
        #5 rst = 1'b0;
        #100 if(!pass) $display(">>>> Error2 occurs.");
        #5 rst = 1'b1;
        #5 rst = 1'b0;
        #200 if(!pass) $display(">>>> Error3 occurs.");
        #5 rst = 1'b1;
        #5 rst = 1'b0;
        #1200 if(!pass) $display(">>>> Error4 occurs.");
     
        if(pass) $display(">>>> [PASS]  Congratulations!");
        else $display(">>>> [ERROR] Try it again!");
        $finish;
    end
    
    task test;
        begin
            if(out != res) error();
        end
    endtask
    
    task error;
        begin
            pass = 0;
        end
    endtask
    
    task cal;
        if(rst ==1'b1) begin
            index = 6'b000001;
            res = 6'b000000;
        end else if(index == 6'b111111) begin
            index = 6'b000001;
            res = 6'b000000;
        end
        else begin
            case(index)
                    6'b000000: res = 6'b000000;
                    6'b000001: res = 6'b000001;
                    6'b000010: res = 6'b000011;
                    6'b000011: res = 6'b000110;
                    6'b000100: res = 6'b000010;
                    6'b000101: res = 6'b000111;
                    6'b000110: res = 6'b000001;
                    6'b000111: res = 6'b001000;
                    6'b001000: res = 6'b010000;
                    6'b001001: res = 6'b000111;
                    6'b001010: res = 6'b010001;
                    6'b001011: res = 6'b000110;
                    6'b001100: res = 6'b010010;
                    6'b001101: res = 6'b000101;
                    6'b001110: res = 6'b010011;
                    6'b001111: res = 6'b000100;
                    6'b010000: res = 6'b010100;
                    6'b010001: res = 6'b000011;
                    6'b010010: res = 6'b010101;
                    6'b010011: res = 6'b000010;
                    6'b010100: res = 6'b010110;
                    6'b010101: res = 6'b000001;
                    6'b010110: res = 6'b010111;
                    6'b010111: res = 6'b101110;
                    6'b011000: res = 6'b010110;
                    6'b011001: res = 6'b101111;
                    6'b011010: res = 6'b010101;
                    6'b011011: res = 6'b110000;
                    6'b011100: res = 6'b010100;
                    6'b011101: res = 6'b110001;
                    6'b011110: res = 6'b010011;
                    6'b011111: res = 6'b110010;
                    6'b100000: res = 6'b010010;
                    6'b100001: res = 6'b110011;
                    6'b100010: res = 6'b010001;
                    6'b100011: res = 6'b110100;
                    6'b100100: res = 6'b010000;
                    6'b100101: res = 6'b110101;
                    6'b100110: res = 6'b001111;
                    6'b100111: res = 6'b110110;
                    6'b101000: res = 6'b001110;
                    6'b101001: res = 6'b110111;
                    6'b101010: res = 6'b001101;
                    6'b101011: res = 6'b111000;
                    6'b101100: res = 6'b001100;
                    6'b101101: res = 6'b111001;
                    6'b101110: res = 6'b001011;
                    6'b101111: res = 6'b111010;
                    6'b110000: res = 6'b001010;
                    6'b110001: res = 6'b111011;
                    6'b110010: res = 6'b001001;
                    6'b110011: res = 6'b111100;
                    6'b110100: res = 6'b001000;
                    6'b110101: res = 6'b111101;
                    6'b110110: res = 6'b000111;
                    6'b110111: res = 6'b111110;
                    6'b111000: res = 6'b000110;
                    6'b111001: res = 6'b111111;
                    6'b111010: res = 6'b111110;
                    6'b111011: res = 6'b111100;
                    6'b111100: res = 6'b111000;
                    6'b111101: res = 6'b110000;
                    6'b111110: res = 6'b100000;
            endcase
            index <= index + 1;
        end
    endtask
    
    
    
    
endmodule
