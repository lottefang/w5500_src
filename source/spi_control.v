/*
 * @Author: cuidajun 
 * @Date: 2017-11-03 17:17:21 
 * @Last Modified by: cuidajun
 * @Last Modified time: 2017-11-03 22:25:28
 * @Description:  
 */



module spi_control(rstn,clk,txdata,din,dout,cs,sck,rxdata)/*synthesis noprune*/;
    input rstn,clk;
    input [7:0] txdata;  //transmit data
 
	input din;
	output  reg cs; 
	output  sck; 
	output  dout; 
	output  [7:0] rxdata; //received data


parameter fsm_idle = 8'd0,fsm_set_cnt = 8'd1, fsm_set_index = 8'd2 , fsm_send_start = 8'd3, 
fsm_send_wait = 8'd4, fsm_send_end = 8'd5 , fsm_finish = 8'd6,fsm_send_wait_2 =8'd7;
reg [8:0] cur=fsm_idle,nxt=fsm_idle;

wire [7:0] treg;
reg [7:0] cnt=0,index=0;

reg [7:0] mem[255:0];
initial begin
mem[0]<=8'd5;  mem[1]<=8'h00;  mem[2]<=8'h2e;  mem[3]<=8'h01;  mem[4]<=8'h00;
mem[5]<=8'd8;  mem[6]<=8'h00;  mem[7]<=8'h01;  mem[8]<=8'h04;  mem[9]<=8'hc0;  mem[10]<=8'ha8;  mem[11]<=8'h01;  mem[12]<=8'h01;
mem[13]<=8'd8;  mem[14]<=8'h00;  mem[15]<=8'h05;  mem[16]<=8'h04;  mem[17]<=8'hff;  mem[18]<=8'hff;  mem[19]<=8'hff;  mem[20]<=8'h00;
mem[21]<=8'd10;  mem[22]<=8'h00;  mem[23]<=8'h09;  mem[24]<=8'h04;  mem[25]<=8'h0c;  mem[26]<=8'h29;  mem[27]<=8'hab;  mem[28]<=8'h7c;  mem[29]<=8'h00;  mem[30]<=8'h01;
mem[31]<=8'd8;  mem[32]<=8'h00;  mem[33]<=8'h0f;  mem[34]<=8'h04;  mem[35]<=8'hc0;  mem[36]<=8'ha8;  mem[37]<=8'h01;  mem[38]<=8'hc7;
mem[39]<=8'd5;  mem[40]<=8'h00;  mem[41]<=8'h1e;  mem[42]<=8'h0d;  mem[43]<=8'h02;
mem[44]<=8'd5;  mem[45]<=8'h00;  mem[46]<=8'h1f;  mem[47]<=8'h0d;  mem[48]<=8'h02;
mem[49]<=8'd6;  mem[50]<=8'h00;  mem[51]<=8'h12;  mem[52]<=8'h0e;  mem[53]<=8'h05;  mem[54]<=8'hb4;
mem[55]<=8'd6;  mem[56]<=8'h00;  mem[57]<=8'h04;  mem[58]<=8'h0e;  mem[59]<=8'h13;  mem[60]<=8'h88;
mem[61]<=8'd5;  mem[62]<=8'h00;  mem[63]<=8'h00;  mem[64]<=8'h0d;  mem[65]<=8'h02;
mem[66]<=8'd5;  mem[67]<=8'h00;  mem[68]<=8'h01;  mem[69]<=8'h0d;  mem[70]<=8'h01;
mem[71]<=8'd5;  mem[72]<=8'h00;  mem[73]<=8'h17;  mem[74]<=8'h01;  mem[75]<=8'h00;
    index <=0;

end

//FSM i/o
assign treg = mem[index];
wire done;
reg start=0;
reg index_add_flag;
always @(cur or done ) begin
    //$display("FSM judge");
		 nxt=cur;
         start = 1'b0;
         cs  = 1'b0;
		 case(cur)
			fsm_idle:begin //idle
				nxt = fsm_set_cnt ;
                
            end
			fsm_set_cnt:begin //ready to  send spi data block
                //cnt = index + mem[index];//num of this data block
                cs=1'b1;
               
                nxt = fsm_set_index;              
			end//send
            fsm_set_index:begin
                nxt = fsm_send_start;
            end
            fsm_send_start:begin //start send
                $display("send data:%h",treg);
                start = 1'b1;
                nxt = fsm_send_wait;
                end
            fsm_send_wait:begin
                if (done) nxt =fsm_send_wait_2;
            end
            fsm_send_wait_2:begin
              nxt = fsm_send_end;
            end
            fsm_send_end:begin //wait for data send done
                
                if (index < cnt) begin
                    nxt = fsm_set_index; //block not end ,send next data
                end else begin
                    if (index<75)//send next blcok
                    begin
                        nxt = fsm_set_cnt;
                        cs = 1'b1;
                    end else begin //all data block send done
                        nxt = fsm_finish;
                        cs = 1'b1;
                    end
                end                    
            end
            
			fsm_finish:begin
                nxt = fsm_finish;

            end
			default: nxt=fsm_idle;
      endcase
    end//always

//state transistion
always@(posedge clk or negedge rstn) begin
 if(rstn==0) begin
   cur<=0;
   index<=0;
   cnt<=0;
 end 
 else begin
    
    case (cur)
      fsm_set_cnt: begin cnt <= index + mem[index]; index <= index+1'b1; end 
      fsm_send_wait_2:index <= index + 1'b1;
      fsm_finish: index<= 0; 
      
    endcase
    cur<=nxt;
   end
 end
wire[7:0] rreg;
wire [31:0]mspi_rdata;
wire mspi_ready;
assign rxdata = mspi_rdata[7:0];
mspi mspi_inst(
					.clk(clk),		// global clock
					.rst(~rstn),		// global async low reset
					.clk_div(4),	// spi clock divider
					.wr(start),			// spi write/read
					.wr_len(2'd0),		// spi write or read byte number
					.wr_done(done),	// write done /read done
					.wrdata({treg,24'd0}),		// spi write data, ��Чλ��wr_len�йأ���8λ����16λ��ȫ��32λ 
					.rddata(mspi_rdata),		// spi recieve data, valid when wr_done assert��Чλ��wr_len�йأ���8λ����16λ��ȫ��32λ 
					.sck(sck),		// spi master clock out 
					.sdi(din),		// spi master data in (MISO) 
					.sdo(dout),		// spi master data out (MOSI) 
					.ss(),			// spi cs
					.ready(mspi_ready)		// spi master ready (idle) 
					);


endmodule
