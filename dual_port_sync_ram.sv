module dual_port_sync_ram #(parameter ADDR_WIDTH=11, DATA_WIDTH=8)
(
	input clk,
	input we,
	input [DATA_WIDTH-1:0] din,
	input [ADDR_WIDTH-1:0] addr_a,addr_b,
	output [DATA_WIDTH-1:0] dout_a,dout_b
);

logic[DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
logic[ADDR_WIDTH-1:0] addr_a_reg,addr_b_reg;

always_ff @(posedge clk) begin : proc_addr
	if(we) ram[addr_a] <= din;
	addr_a_reg<= addr_a;
	addr_b_reg <= addr_b;
end

assign dout_a = ram[addr_a_reg];
assign dout_b = ram[addr_b_reg];

endmodule