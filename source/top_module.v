/*
 * @Author: cuidajun 
 * @Date: 2017-11-16 16:34:52 
 * @Last Modified by: cuidajun
 * @Last Modified time: 2017-11-16 16:37:39
 * @Description:  这是一个调用w5500模块的例程，将收到的数据发回去
 */

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


wire [7:0]rxdata;
wire clk2;

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
				

reg[7:0] txdata;
wire busy, busy_tx , busy_rx,clk_rx,init_done;
reg clk_sink,tx_start;
spi_control  spi_ctrl_inst
		(
		.rstn(myrstn),
		.clk(clk_div),
		.txdata(rxdata),
		.tx_start(tx_start),
		.clk_sink(clk_rx),
		.busy(busy),       //这个没用
		.busy_tx(busy_tx),    //！！注意，busy_tx高时正在发送数据忙，忙时不可继续增加发送数据缓存区，全部发送完后不忙	
		.busy_rx(busy_rx),
		.din(MISO),
		.dout(MOSI),
		.cs(cs),
		.sck(sck),
		.rxdata(rxdata),
		.clk_source(clk_rx),
		.init_done(init_done)
		);
//产生开始发送数据的start信号
wire clk_1S;
clk_divider  #(.CLK_DIVIDE_PARAM(15)) clk_generate2
				(
					.clk(clk_div),
					.clk_div(clk_1S)
				);
reg clk_1S_delay;
always @(posedge clk_div ) begin
  clk_1S_delay<=clk_1S;
end
always @(posedge clk_div or negedge myrstn) begin
	if (!myrstn) begin
		tx_start <= 1'b0;
	end else 
				if ({clk_1S_delay, clk_1S}==2'b01) begin
					tx_start <= 1;
				end  else tx_start<=1'b0;
end
assign led[1] = busy_tx;

endmodule
