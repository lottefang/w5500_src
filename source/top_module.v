module top_module
(
   input clk,
	input rstn,
	output [1:0]led,
	input MISO,
	output MOSI,
	output cs,
	output sck,
	output clk_div
);
assign led[0]=1'b1;

wire [7:0]rxdata;
wire clk2;
assign led[1]=rxdata[0];

assign clk2 = clk;
clk_divider  #(.CLK_DIVIDE_PARAM(1)) clk_generate
				(
					.clk(clk),
					.clk_div(clk_div)
				);
				


spi_control  spi_ctrl_inst
		(
		.rstn(rstn),
		.clk(clk_div),
		.txdata(),
		.din(MISO),
		.dout(MOSI),
		.cs(cs),
		.sck(sck),
		.rxdata(rxdata)
		);


endmodule