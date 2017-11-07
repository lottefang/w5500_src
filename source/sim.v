
`timescale 1ns/10ps
module sim;
  reg clk;
  reg rst_n;
  wire  [1:0] led;
  reg [31:0] index;
  initial begin
    clk=0;
    rst_n=1;
    // #10
    // rst_n=0;
    // #1 
    // rst_n=1;
  end
  always #1 clk=~clk;
  reg MISO;
  wire cs,sck,MOSI;
  top_module u(  clk,rst_n, led, MISO,
	 MOSI,
	 cs,
	 sck
	);
endmodule // sim