/*
 * @Author: cuidajun 
 * @Date: 2017-11-03 17:16:09 
 * @Last Modified by: cuidajun
 * @Last Modified time: 2017-11-03 17:16:29
 * @Description:  clk 2^n divider 
 */

module clk_divider
#(parameter CLK_DIVIDE_PARAM)(
    input clk,
    output  clk_div
);
reg [CLK_DIVIDE_PARAM-1:0] cnt=0;
always @(posedge clk) begin
  cnt<=cnt+1'b1;
end
assign clk_div = (cnt[CLK_DIVIDE_PARAM-1]==1)?1:0;


endmodule // clk_divider    input clk,
