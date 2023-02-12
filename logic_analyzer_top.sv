module logic_analyzer_vga_v1_0 (
	input clk,    // Clock
	input key,
	input reset_n,  // Asynchronous reset active low
	output logic vga_hsync,vga_vsync,
	output logic [2:0] vga_rgb
);

logic [9:0] pixel_x,pixel_y;
logic video_on;
logic [2:0] rgb;
logic [3:0] in_reg;
vga_sync vga_sync_inst
(
	.clk(clk), .rst_n(reset_n), .hsync(vga_hsync),.vsync(vga_vsync),
	.pixel_x(pixel_x),.pixel_y(pixel_y),.video_on(video_on)
);

logic_analyzer_screen_gen logic_analyzer_screen_gen_inst
(
	.clk(clk),
	.reset_n(reset_n),
	.key(key),
	.in(in_reg),
	.pixel_x(pixel_x),
	.pixel_y(pixel_y),
	.video_on(video_on),
	.rgb(vga_rgb)
);

reg [9:0] counter_100khz = 0;
reg [9:0] counter_40khz = 0;
reg [9:0] counter_20khz = 0;
reg [9:0] counter_10khz = 0;
initial 
begin
	in_reg = 0;
end
always @(posedge clk)
begin
	counter_100khz = (counter_100khz==249)? 0 : counter_100khz + 1;
	counter_40khz = (counter_40khz==624)? 0 : counter_40khz + 1;
	counter_20khz = (counter_20khz==1249)? 0 : counter_20khz + 1;
	counter_10khz = (counter_10khz==2499)? 0 : counter_10khz + 1;

	in_reg[0] <= (counter_100khz==0)? !in_reg[0]:in_reg[0]; //reverse the signal every restart of the free running counter to form a square
	in_reg[1] <= (counter_40khz==0)? !in_reg[1]:in_reg[1];
	in_reg[2] <= (counter_20khz==0)? !in_reg[2]:in_reg[2];
	in_reg[3] <= (counter_10khz==0)? !in_reg[3]:in_reg[3];
end
endmodule