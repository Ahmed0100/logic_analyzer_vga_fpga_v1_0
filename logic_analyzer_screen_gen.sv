module logic_analyzer_screen_gen
(
	input clk,reset_n,
	input key,
	input [3:0] in,
	input [9:0] pixel_x,pixel_y,
	input video_on,
	output logic [2:0] rgb
);

localparam IDLE=0, FIRST_PAIR=1, SECOND_PAIR=2;

logic [1:0] current_state,next_state;
logic we;
logic on_1,on_2,on_3,on_4;
logic [6:0] x_cursor_reg, x_cursor_next;
logic on;
logic [1:0] dout,dout_1,dout_2,dout_3,dout_4;
logic [1:0] din_1_reg,din_2_reg,din_3_reg,din_4_reg;
logic [1:0] din_1_next,din_2_next,din_3_next,din_4_next;
logic [7:0] mod250_reg=0;
logic mod_tick;
logic [7:0] font_data;
logic font_bit;
logic key_tick;
logic [9:0] pixel_x_reg_1,pixel_x_reg_2;

always_ff @(posedge clk or negedge reset_n) begin : proc_curret_state
	if(~reset_n) 
	begin
		current_state <= 0;
		{din_1_reg,din_2_reg,din_3_reg,din_4_reg} <= '0;
		pixel_x_reg_1 <= 0;
		pixel_x_reg_2 <= 0;
		mod250_reg <= 0;
		x_cursor_reg <= 0;
	end
	else 
	begin
		current_state <= next_state;
		{din_1_reg,din_2_reg,din_3_reg,din_4_reg} <= 
		{din_1_next,din_2_next,din_3_next,din_4_next};
		pixel_x_reg_1 <= pixel_x;
		pixel_x_reg_2 <= pixel_x_reg_1;
		mod250_reg <= (mod250_reg == 249)? 0 : mod250_reg+1;
		x_cursor_reg <= x_cursor_next;
	end
end
assign mod_tick = mod250_reg==0;

always_comb begin : proc_comb
		next_state = current_state;
		{din_1_next,din_2_next,din_3_next,din_4_next} = {din_1_reg,din_2_reg,din_3_reg,din_4_reg};
		x_cursor_next = x_cursor_reg;
		we=0;
		dout=0;
		on=0;
		case(current_state)
			IDLE:
			begin
				if(key_tick)
				begin
					next_state = FIRST_PAIR;
					x_cursor_next = 0;
				end
			end
			FIRST_PAIR: 
			begin
				if(mod_tick)
				begin
					din_1_next = {1'b0,in[0]};
					din_2_next = {1'b0,in[1]};
					din_3_next = {1'b0,in[2]};
					din_4_next = {1'b0,in[3]};
					next_state = SECOND_PAIR;
				end
			end
			SECOND_PAIR:
			begin
				if(mod_tick)
				begin
					we=1;
					din_1_next = {din_1_reg[0],in[0]};
					din_2_next = {din_2_reg[0],in[1]};
					din_3_next = {din_3_reg[0],in[2]};
					din_4_next = {din_4_reg[0],in[3]};
					if(x_cursor_reg==79) 
						next_state = IDLE;
					else
						x_cursor_next = x_cursor_reg + 1; 
				end
			end
			default: next_state = IDLE;
		endcase // curret_state
		case(pixel_y[8:6])
			0:
			begin
				dout = dout_1;
				on = on_1;
			end
			2:begin
				dout = dout_2;
				on = on_2;
			end
			4:begin
				dout = dout_3;
				on = on_3;
			end
			6:begin
				dout = dout_4;
				on = on_4;
			end
		endcase
end
assign font_bit = on && font_data[~pixel_x_reg_2[2:0]];

always_comb begin : proc_rgb
	rgb=0;
	if(!video_on)
		rgb=0;
	else
		rgb=font_bit? 3'b010:3'b000;
end

square_wave_rom square_wave_rom_inst
(.clk(clk), .addr({dout,pixel_y[5:0]}), .data(font_data));

dual_port_sync_ram #(.ADDR_WIDTH(10), .DATA_WIDTH(3)) dual_port_sync_ram_inst_1
( 
	.clk(clk),.we(we), 
	.din({1'b1,din_1_reg}),
	.addr_a({3'h0,x_cursor_reg}),
	.addr_b({pixel_y[8:6],pixel_x[9:3]}),
	.dout_a(),
	.dout_b({on_1,dout_1})
);

dual_port_sync_ram #(.ADDR_WIDTH(10), .DATA_WIDTH(3)) dual_port_sync_ram_inst_2
( 
	.clk(clk),.we(we), 
	.din({1'b1,din_2_reg}),
	.addr_a({3'h2,x_cursor_reg}),
	.addr_b({pixel_y[8:6],pixel_x[9:3]}),
	.dout_a(),
	.dout_b({on_2,dout_2})
);

dual_port_sync_ram #(.ADDR_WIDTH(10), .DATA_WIDTH(3)) dual_port_sync_ram_inst_3
( 
	.clk(clk),.we(we), 
	.din({1'b1,din_3_reg}),
	.addr_a({3'h4,x_cursor_reg}),
	.addr_b({pixel_y[8:6],pixel_x[9:3]}),
	.dout_a(),
	.dout_b({on_3,dout_3})
);

dual_port_sync_ram #(.ADDR_WIDTH(10), .DATA_WIDTH(3)) dual_port_sync_ram_inst_4
( 
	.clk(clk),.we(we), 
	.din({1'b1,din_4_reg}),
	.addr_a({3'h6,x_cursor_reg}),
	.addr_b({pixel_y[8:6],pixel_x[9:3]}),
	.dout_a(),
	.dout_b({on_4,dout_4})
);

db_fsm db_fsm_inst
(.clk(clk), .reset_n(reset_n), .sw(!key), 
	 .db_tick(key_tick));

endmodule : logic_analyzer_screen_gen