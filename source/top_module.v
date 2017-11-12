module top_module
(
   input clk,
	input rstn,
	output [1:0]led,
	input MISO,
	output MOSI,
	output cs,
	output sck,
	output clk_div,
	output mspi_sck
);
reg myrstn = 1'b1;
assign led[0]=~myrstn;

wire [7:0]rxdata;
wire clk2;
assign led[1]=rxdata[0];

assign clk2 = clk;

parameter rstn_cnt = 100;
reg [31:0] cnt=0;
always @(posedge clk ) begin
  
  if (cnt== (rstn_cnt>>1)) begin myrstn<=1'b0; cnt<=cnt+1'b1;end 
  else if (cnt==rstn_cnt) myrstn<=1'b1; 
  else cnt<=cnt+1'b1;
end
clk_divider  #(.CLK_DIVIDE_PARAM(1)) clk_generate
				(
					.clk(clk),
					.clk_div(clk_div)
				);
				


spi_control  spi_ctrl_inst
		(
		.rstn(myrstn),
		.clk(clk_div),
		.txdata(),
		.din(MISO),
		.dout(MOSI),
		.cs(cs),
		.sck(sck),
		.rxdata(rxdata)
		);
wire spi_done;
wire [31:0] mspi_rdata;
wire mspi_mosi,mspi_ready;
mspi mspi_inst(
					.clk(clk),		// global clock
					.rst(~myrstn),		// global async low reset
					.clk_div(4),	// spi clock divider
					.wr(clk_div),			// spi write/read
					.wr_len(2'd0),		// spi write or read byte number
					.wr_done(mspi_done),	// write done /read done
					.wrdata({8'h77,24'd0}),		// spi write data, ��Чλ��wr_len�йأ���8λ����16λ��ȫ��32λ 
					.rddata(mspi_rdata),		// spi recieve data, valid when wr_done assert��Чλ��wr_len�йأ���8λ����16λ��ȫ��32λ 
					.sck(mspi_sck),		// spi master clock out 
					.sdi(1'b1),		// spi master data in (MISO) 
					.sdo(mspi_mosi),		// spi master data out (MOSI) 
					.ss(),			// spi cs
					.ready(mspi_ready)		// spi master ready (idle) 
					);

endmodule
