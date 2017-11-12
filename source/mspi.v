// 8bit SPI master
// author: jiajia.pi
// version: v1.1
// last modify date: 2014/08/19 change ready assert timing
// clk_div range: 4~255 divsion of clk
// only mode 0 and mode 3 support
// MSB send first and LSB send last
module mspi(
					clk,		// global clock
					rst,		// global async low reset
					clk_div,	// spi clock divider
					wr,			// spi write/read
					wr_len,		// spi write or read byte number
					wr_done,	// write done /read done
					wrdata,		// spi write data, ��Чλ��wr_len�йأ���8λ����16λ��ȫ��32λ 
					rddata,		// spi recieve data, valid when wr_done assert��Чλ��wr_len�йأ���8λ����16λ��ȫ��32λ 
					sck,		// spi master clock out 
					sdi,		// spi master data in (MISO) 
					sdo,		// spi master data out (MOSI) 
					ss,			// spi cs
					ready		// spi master ready (idle) 
					);
// ========================================================
//					
input				clk;
input				rst;
input	[7:0]		clk_div;
input				wr;
input	[1:0]		wr_len;
input	[31:0]		wrdata;
output	[31:0]		rddata;
output				wr_done;
output				sck;
output				sdo;
output				ready;
output				ss;
input				sdi;
// =========================================================
//
parameter clock_polarity = 1;  // '0': mode 0, sck=0 when idle; '1': mode 3, sck=1 when idle
parameter 	BYTE_NUM_1	= 0;
parameter	BYTE_NUM_2	= 1;
parameter	BYTE_NUM_4	= 2;

// =========================================================
//
reg		[31:0]		dat;
reg					rsck;
reg		[7:0]		cnt;
reg					busy;
reg		[4:0]		state;
reg		[4:0]		bit_number;
reg		[31:0]		rddata;
reg		[1:0]		wr_reg;
reg		[4:0]		busy_reg;
reg					wr_done_reg;
reg					rd_clr;
// =========================================================
//
wire	sdo = dat[31];
wire	sck = busy? rsck:clock_polarity;
wire	sdi_tick = (cnt==clk_div>>1)/*synthesis keep*/;  
wire	sdo_tick = (cnt==clk_div)/*synthesis keep*/;
wire	wr_pos = (wr_reg[1:0] == 2'b01)/*synthesis keep*/;
wire	ready = !(wr_pos||busy);
wire	ss = !busy;
wire	wr_done = wr_done_reg;
// =========================================================
//
always @(posedge clk or posedge rst)
if(rst)
	cnt <= 0;
else if(cnt<clk_div && busy)
	cnt <= cnt + 1;
else
	cnt <= 1;
// ---------------------------------------------------------
//
always @(posedge clk or posedge rst)
if(rst)
  rsck  <= 0;
else if(sdi_tick)
  rsck  <= 1;
else if(sdo_tick)
  rsck  <= 0;
// ---------------------------------------------------------
//
always @(posedge clk or posedge rst)
if(rst)
  bit_number  <= 8;
else case(wr_len)
	  BYTE_NUM_1:	bit_number <= 8;			// 1�ֽ�
	  BYTE_NUM_2:	bit_number <= 16;			// 2�ֽ�
	  BYTE_NUM_4:	bit_number <= 32;			// 4�ֽ�
  default:
		bit_number <= 8;
endcase

// ---------------------------------------------------------
//
always @(posedge clk or posedge rst)
if(rst)
  wr_reg  <= 0;
else
  wr_reg  <= {wr_reg[0],wr};

// ---------------------------------------------------------
//
always @(posedge clk or posedge rst)
if(rst)
	busy <= 0;
else if(wr_pos && !busy)
	busy <= 1;
else if(state==bit_number && sdo_tick)
	busy <= 0;
// ---------------------------------------------------------
//
always@(posedge clk or posedge rst)
if(rst)
	state  <= 0;
else if(wr_pos && !busy)
	state  <= 1;
else if(state==bit_number && sdo_tick)
	state  <= 0;
else if(sdo_tick)
	state  <= state + 1;  
// ---------------------------------------------------------
//
always @(posedge clk or posedge rst)
if(rst)
	dat  <= 0;
else if(wr_pos && !busy)
	dat  <= wrdata;
else if(sdo_tick && busy && state!=bit_number)
	dat  <= dat<<1;
// ---------------------------------------------------------
//
always @(posedge clk or posedge rst)
if(rst)
	rddata  <= 0;
else if(rd_clr)
	rddata  <= 0;
else if(sdi_tick && busy)
	rddata  <= {rddata[30:0],sdi};

// ---------------------------------------------------------
//
always @(posedge clk or posedge rst)
if(rst)
	busy_reg[4:0]  <= 0;
else
	busy_reg[4:0]  <= {busy_reg[3:0],busy};
 
// ---------------------------------------------------------
//
always @(posedge clk or posedge rst)
if(rst)
	begin
		wr_done_reg <= 0;
		rd_clr		<= 0;
	end
else
	begin
		wr_done_reg  <= (busy_reg[4:0]==5'b11100);
		rd_clr		<=	(busy_reg[4:0]==5'b11000);
	end


endmodule
