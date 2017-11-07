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

parameter idle=0,finish=5;	

wire [7:0] treg;

parameter bitl = 7;  
reg [bitl:0] cur=finish,nxt=idle;

reg [bitl:0] cnt=0,index=0;

reg [7:0] mem[255:0];
initial begin
    mem[0]<=8'd4;
    mem[1]<=8'h00;
    mem[2]<=8'h2e ;
    mem[3]<=8'h01 ;
    mem[4]<=8'h00 ;
    mem[5]<=8'd4 ;
    mem[6]<=8'h00;
    mem[7]<=8'h2e ;
    mem[8]<=8'h01 ;
    mem[9]<=8'h00 ;

end

//FSM i/o
assign treg = mem[index];
wire done;
reg start=0;

always @(cur or done ) begin
    $display("FSM judge");
		 nxt=cur;
		 case(cur)
			0:begin //idle
				nxt = 1 ;
                start =1'b0;
            end
			1:begin //ready to  send spi data block
                cnt = index + mem[index];//num of this data block
                cs = 1'b0; //change cs to enable spi slave
                !!index = index+1; //load 1st data
                nxt = 2;              
			end//send
            2:begin //start send
                $display("send data:%h",treg);
                start = 1'b1;
                nxt = 3;
                end
            3:begin
                if (done) nxt =4;else nxt = 3;
            end
            4:begin //wait for data send done
                if (!done) begin
                    if (index < cnt) begin
                        nxt = 2; //block not end ,send next data
                    end else begin
                        if (index<9)//send next blcok
                        begin
                            nxt = 1;
                            cs = 1'b1;
                        end else begin //all data block send done
                            nxt = finish;
                            cs = 1'b1;
                        end
                    end
                    index = index +1;
                    start = 1'b0;
                end
            end
            
			finish:begin
                nxt = idle;
                index = 0;
            end
			default: nxt=0;
      endcase
    end//always

//state transistion
always@(negedge clk or negedge rstn) begin
 if(rstn==0) 
   cur<=0;
 else 
   cur<=nxt;
 end
wire[7:0] rreg;
spi_master spi_inst(
    .rstb(rstn),
    .clk(clk),
    .mlb(1'b1),
    .start(start),
    .tdat(treg),
    .cdiv(2'b0),
    .din(din), 
    .ss(),
    .sck(sck),
    .dout(dout),
    .done(done),
    .rdata(rxdata)
);


endmodule
