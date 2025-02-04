`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/03 16:22:29
// Design Name: 
// Module Name: lab7_1
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


module lab7_1(
    input clk,
    input rst,
    input en,
    input dir,
    input nf,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
    );
    
    wire clk_22;
    wire clk_25M;
    
    wire [11:0] data;
    wire [16:0] pixel_addr;
    wire [11:0] pixel;
    
    wire valid;
    wire [9:0] h_cnt;
    wire [9:0] v_cnt;
    
    clock_divider #(22) m1(clk,clk_22);
    clock_divider #(2) m2(clk,clk_25M);
    
    vga_controller vga_inst(
      .pclk(clk_25M),
      .reset(rst),
      .hsync(hsync),
      .vsync(vsync),
      .valid(valid),
      .h_cnt(h_cnt),
      .v_cnt(v_cnt)
    );
    
    mem_addr_gen mem_addr_gen_inst(
    .clk(clk_22),
    .rst(rst),
    .en(en),
    .dir(dir),
    .h_cnt(h_cnt),
    .v_cnt(v_cnt),
    .pixel_addr(pixel_addr)
    );
    
    assign {vgaRed, vgaGreen, vgaBlue} = (valid == 1'b1) ? ((nf == 1'b0) ? (pixel):(~pixel)) : 12'd0;
    assign data = {vgaRed, vgaGreen, vgaBlue};
    blk_mem_gen_0 mem_gen(.addra(pixel_addr), .clka(clk_25M), .dina(data), .douta(pixel), .wea(0));
    
endmodule


module mem_addr_gen(
   input clk,
   input rst,
   input en,
   input dir,
   input [9:0] h_cnt,
   input [9:0] v_cnt,
   output [16:0] pixel_addr
   );
    
   reg [7:0] position;
  
   assign pixel_addr = ((h_cnt>>1)+320*(v_cnt>>1)+position*320) % 76800;  //640*480 --> 320*240 

   always @ (posedge clk or posedge rst) begin
       if(rst) begin
           position <= 0;
       end else begin
            if(en == 1'b0) begin
                position <= position;
            end else begin
                if(dir == 1'b0) begin
                    if(position < 239) position <= position + 1;
                    else position <= 0;
                end else begin
                    if(position > 0) position <= position - 1;
                    else position <= 239;
                end
            end
       end
   end
endmodule







