/*
 * @Author: cuidajun 
 * @Date: 2017-11-03 17:17:21 
 * @Last Modified by: cuidajun
 * @Last Modified time: 2017-11-16 17:15:44
 * @Description: 例程网络参数
    //网关：192.168.1.1
    //掩码:	255.255.255.0
    //物理地址：0C 29 AB 7C 00 01
    //本机IP地址:192.168.1.199
    //端口0的端口号：5000
    //端口0的目的IP地址：192.168.1.190
    //端口0的目的端口号：6000 
 */



module spi_control(
    rstn,       //reset_n
    clk,        //main clk
    txdata,     //数据通过txdata传进该模块的缓存区，一次最多传送2K个字节，在clk_sink的上升沿，将txdata存入缓存区
    clk_sink,   //在clk_sink的上升沿，将txdata存入缓存区
    tx_start,   //数据传输开始信号，上升沿代表开始发送缓存区内的数据到远端ip
    busy,       //模块忙，正在接受数据或者发送数据，本模块为半双工
    busy_tx,    //正在发送数据，忙时不可继续增加发送数据缓存区，全部发送完后不忙
    busy_rx,    //正在接受数据，接收数据未完成时，若在发送数据时，远端ip同时也发送数据2次，则会出现多出来的IP信息字节
    din,        //W5500模块MISO
    dout,       //W5500模块MOSI
    cs,         //W5500模块csn
    sck,        //W5500模块sck
    rxdata,     //接受到的数据通过rxdata传出该模块，请在clk_source上升沿读数
    clk_source,  //rxdata的时钟
    init_done   //是否初始化完成
    )/*synthesis noprune*/;
input       rstn,clk;
input[7:0]  txdata;  //transmit data
input       tx_start;
input       din;
output  reg cs; 
output      sck; 
output      dout; 
output[7:0] rxdata; //received data
output      busy;
output  reg busy_tx,busy_rx;
output  reg clk_source;
input       clk_sink;
output      init_done;
reg [7:0] rxdata;
parameter  SPI_CLK_DIV_NUM = 8'd4;//4~255 divsion of clk,spi的时钟分频，必须大于4
parameter  RX_START_CLK_DIV = 6; //clk的2^n分频，用于启动查询是否接受到数据
                                //这里可能会有个问题，就是如果在一次查询间隔内，发送了两次数据，则rxdata的输出数据里可能会混杂第二次的ip信息没有剔除。不过考虑到网络的延迟时ms级别，这个查询时间间隔也是ms级别，所以5500应该会自动合并两次数据，不会出这个问题
parameter  GATEWAY_IP = 32'hc0a80101;
//设置网关(Gateway)的IP地址,Gateway_IP为4字节,自己定义 
//使用网关可以使通信突破子网的局限，通过网关可以访问到其它子网或进入Internet
parameter  MASK = 32'hffffff00;
//设置子网掩码(MASK)值,SUB_MASK为4字节数组,自己定义
//子网掩码用于子网运算
parameter  PHY_ADDR = 48'h0c29ab7c0001;
//设置物理地址,PHY_ADDR为6字节数组,自己定义,用于唯一标识网络设备的物理地址值
//该地址值需要到IEEE申请，按照OUI的规定，前3个字节为厂商代码，后三个字节为产品序号
//如果自己定义物理地址，注意第一个字节必须为偶数
parameter  LOCAL_IP = 32'hc0a801c7;
//设置本机的IP地址,IP_ADDR为4字节unsigned char数组,自己定义
//注意，网关IP必须与本机IP属于同一个子网，否则本机将无法找到网关
parameter  UDP_PORT = 16'h1388;
//设置本机udp Port
parameter TARGET_IP = 32'hc0a801be;
//设置目的主机ip
parameter TARGET_PORT = 16'h1770;
//设置目的主机port


parameter   spi_fsm_idle        =   8'd0,
            spi_fsm_set_cnt     =   8'd1,
            spi_fsm_set_ptr     =   8'd2,
            spi_fsm_set_tx_data =   8'd3,
            spi_fsm_spi_start   =   8'd4,
            spi_fsm_spi_wait    =   8'd5,
            spi_fsm_cnt_minus   =   8'd6,
            spi_fsm_1_byte_fini =   8'd7,
            spi_fsm_1_block_fini=   8'd8,
            spi_fsm_finish      =   8'd9;
reg [7:0] cur=spi_fsm_idle,nxt=spi_fsm_idle;

parameter   tx_fsm_idle             =   8'd0,
            tx_fsm_start            =   8'd1,
            tx_fsm_write_ip         =   8'd2,
            tx_fsm_write_ip_wait    =   8'd3,
            tx_fsm_read_offset      =   8'd4,
            tx_fsm_read_offset_wait =   8'd5,
            tx_fsm_write_data       =   8'd6,
            tx_fsm_write_data_wait  =   8'd7,
            tx_fsm_judge            =   8'd8,
            tx_fsm_write_send       =   8'd9,
            tx_fsm_write_send_wait  =   8'd10,
            tx_fsm_finish           =   8'd11;
reg [7:0]   tx_cur = tx_fsm_idle,   tx_nxt  = tx_fsm_idle;
parameter   rx_fsm_idle                     =   8'd0,
            rx_fsm_start                    =   8'd1,    
            rx_fsm_read_int_reg             =   8'd2,
            rx_fsm_read_int_reg_wait        =   8'd3,
            rx_fsm_judge_int                =   8'd4,
            rx_fsm_write_snir               =   8'd5,
            rx_fsm_write_snir_wait          =   8'd6,
            rx_fsm_judge_snir               =   8'd7,
            rx_fsm_read_size_offset         =   8'd8,
            rx_fsm_read_size_offset_wait    =   8'd9,  
            rx_fsm_read_data                =   8'd10,
            rx_fsm_read_data_wait           =   8'd11 ,
            rx_fsm_judge_read_data          =   8'd12 ,
            rx_fsm_write_rev                =   8'd13 ,
            rx_fsm_write_rev_wait           =   8'd14 ,
            rx_fsm_finish                   =   8'd15 ,
            rx_fsm_finish2                  =   8'd16;
reg [7:0]   rx_cur = rx_fsm_idle, rx_nxt = rx_fsm_idle;

parameter init_reg_num = 84;

reg [7:0] treg;
reg [7:0] index=0;
reg [15:0] cnt=0;
reg [7:0] mem[255:0];
reg [7:0] ram[127:0]; //tx 缓存区
reg [15:0] tx_offset;
reg [10:0] tx_ram_start = 0, tx_ram_end = 0;
wire[10:0] tx_count;
reg[15:0] rx_size=0,rx_count =0;reg [15:0] rx_offset;

assign tx_count = tx_ram_end > tx_ram_start ? (tx_ram_end - tx_ram_start): (12'd2048-tx_ram_start+tx_ram_end);//tx缓存区字节数量
//tx缓存区fifo 入
always @(posedge clk_sink or negedge rstn) begin
    if(!rstn) begin
        tx_ram_end<=0;
    end else begin 
        if (!busy_tx) begin
            ram[tx_ram_end]<=txdata;
            tx_ram_end<=tx_ram_end+1'b1;
        end 
    end 
end
//tx缓存区FIFO 出
always @(posedge clk or negedge rstn ) begin
    if (!rstn) tx_ram_start <=0;
    else if (index == 8'd109 && cur == spi_fsm_1_byte_fini)
        tx_ram_start <= tx_ram_start +1'b1;
end



//----init_done 是否初始化完成
reg init_done = 1'b0;
always @(posedge clk or negedge rstn) begin
  if(!rstn) 
    init_done<=1'b0;
  else if ((index == init_reg_num) &&( cur == spi_fsm_1_byte_fini )) 
    init_done <= 1'b1;
end
//spi 状态机状态转换
wire spi_done;
reg index_add_flag;
always @(cur or init_done or spi_done or cnt or busy_tx or tx_cur or rx_cur ) 
    begin
        nxt=cur;
        case(cur)
            spi_fsm_idle:   //idle
                begin
                if ((!init_done)
                ||(tx_cur == tx_fsm_write_ip)
                ||(tx_cur == tx_fsm_write_data)
                ||(tx_cur == tx_fsm_write_send)
                ||(tx_cur == tx_fsm_write_ip_wait)
                ||(tx_cur == tx_fsm_write_data_wait)
                ||(tx_cur == tx_fsm_write_send_wait)
                ||(rx_cur == rx_fsm_read_int_reg)
                ||(rx_cur == rx_fsm_read_int_reg_wait)
                ||(rx_cur == rx_fsm_read_data)
                ||(rx_cur == rx_fsm_read_data_wait)
                ||(rx_cur == rx_fsm_write_snir)
                ||(rx_cur == rx_fsm_write_snir_wait)
                ||(rx_cur == rx_fsm_read_size_offset)
                ||(rx_cur == rx_fsm_read_size_offset_wait)
                ||(rx_cur == rx_fsm_write_rev)
                ||(rx_cur == rx_fsm_write_rev_wait)
                
                ) nxt = spi_fsm_set_cnt ;
                end
            spi_fsm_set_cnt:    //设置本次spi传输字节个数，置低cs
                begin
                  nxt   =  spi_fsm_set_ptr ;
                end
            spi_fsm_set_ptr :   //设置传输数据的指针
                begin
                  nxt   =   spi_fsm_set_tx_data;
                end     
            spi_fsm_set_tx_data ://设置spi传输数
                begin
                  nxt = spi_fsm_spi_start; 
                end
            spi_fsm_spi_start  ://启动spi传输，传输一个字节
                begin
                  nxt = spi_fsm_spi_wait;
                end 
            spi_fsm_spi_wait   ://等待spi传输完成
                begin
                  if (spi_done) nxt = spi_fsm_cnt_minus;
                end
            spi_fsm_cnt_minus   ://更新cnt和ptr
                begin
                    nxt = spi_fsm_1_byte_fini;
                end
            spi_fsm_1_byte_fini://判断是否一帧数据传输完成
                begin
                    if  (cnt == 0) 
                        nxt = spi_fsm_1_block_fini; 
                    else 
                        nxt = spi_fsm_set_ptr;
                end
            spi_fsm_1_block_fini://判断时候需要传下一帧数据
                begin
                    if  (!init_done) 
                        nxt = spi_fsm_set_cnt;
                    else 
                        nxt = spi_fsm_finish;
                end
            spi_fsm_finish ://回到idle
                begin
                    nxt = spi_fsm_idle;
                end    
            default: nxt=spi_fsm_idle;
        endcase
    end//always

//-------spi状态机
always@(posedge clk or negedge rstn) begin
    if(!rstn) 
        cur<=spi_fsm_idle; 
    else begin
        cur<=nxt;
    end
end

//----spi 一个数据帧的个数 cnt
always@(posedge clk or negedge rstn) begin
    if(!rstn) 
        cnt<=0;
    else 
    case (cur)
        spi_fsm_set_cnt:    
            begin
                if ((!init_done) || busy_tx||busy_rx) cnt <= mem[index]-1'b1;
                if (busy_tx && tx_cur == tx_fsm_write_data_wait) 
                begin
                    if (12'd2048-tx_offset[10:0]>=tx_count) 
                        cnt <= tx_count+3; 
                    else 
                        cnt <= 12'd2048-tx_offset[10:0] +3;
                end
                if (busy_rx && rx_cur == rx_fsm_read_data_wait && index == 8'd148 ) begin
                    if (12'd2048 - rx_offset[10:0]>= rx_size )
                        cnt<= rx_size-rx_count +3;
                    else 
                        cnt<= 12'd2048-rx_offset[10:0] +3;
                end 
            end 
        spi_fsm_cnt_minus:
            if ((!init_done) || busy_tx||busy_rx) cnt <= cnt -1'b1;
    endcase
end

//-----spi index 
always@(posedge clk or negedge rstn) begin
    if(!rstn) 
        index<=0;
    else   
        case(cur)
            spi_fsm_idle:
                begin 
                    if (busy_tx && tx_cur == tx_fsm_write_ip) index <= 8'd85;
                    if (busy_tx && tx_cur == tx_fsm_write_data) index <= 8'd105;
                    if (busy_tx && tx_cur == tx_fsm_write_send) index <= 8'd110;
                    if (busy_rx && rx_cur == rx_fsm_read_int_reg) index <=8'd121;
                    if (busy_rx && rx_cur == rx_fsm_write_snir) index <=8'd126;
                    if (busy_rx && rx_cur == rx_fsm_read_size_offset ) index <=8'd136;
                    if (busy_rx && rx_cur == rx_fsm_read_data ) index <=8'd148;
                    if (busy_rx && rx_cur == rx_fsm_write_rev ) index <=8'd153;
                end
            spi_fsm_set_ptr:
                begin
                     if ((!init_done) || busy_tx||busy_rx) index <= index +1'b1;
                     if (index == 8'd109) index<=8'd109;
                     if (index == 8'd152) index<=8'd152;
                end
            spi_fsm_1_block_fini:
                begin
                     if ((!init_done) || busy_tx||busy_rx) index <= index +1'b1;
                     
                end
        endcase   
end

//------w5500 cs
always@(posedge clk or negedge rstn) begin
    if(!rstn) 
        cs<=1'b1;
    else 
    case (cur)
        spi_fsm_set_cnt:    cs<=1'b0;
        spi_fsm_1_block_fini: cs<=1'b1;
    endcase
end

//-----spi start signal
reg  spi_start;
always@(posedge clk or negedge rstn) begin
    if(!rstn) 
        spi_start = 1'b0;
    else 
  case (cur)
        spi_fsm_spi_start: 
             spi_start <= 1'b1; 
        spi_fsm_spi_wait: spi_start <=1'b0;
  endcase
end

wire[7:0] rreg;
wire [31:0]mspi_rdata;
wire mspi_ready;

mspi mspi_inst(
					.clk(clk),		// global clock
					.rst(~rstn),		// global async low reset
					.clk_div(SPI_CLK_DIV_NUM),	// spi clock divider
					.wr(spi_start),			// spi write/read
					.wr_len(2'd0),		// spi write or read byte number
					.wr_done(spi_done),	// write done /read done
					.wrdata({treg,24'd0}),		// spi write data, ??Чλ??wr_len?й????8λ????16λ?????32λ 
					.rddata(mspi_rdata),		// spi recieve data, valid when wr_done assert??Чλ??wr_len?й????8λ????16λ?????32λ 
					.sck(sck),		// spi master clock out 
					.sdi(din),		// spi master data in (MISO) 
					.sdo(dout),		// spi master data out (MOSI) 
					.ss(),			// spi cs
					.ready(mspi_ready)		// spi master ready (idle) 
					);
//------rx_reg 暂存spi接收到的byte
reg[7:0]  rx_reg;
always @(posedge spi_done) begin
  rx_reg<=mspi_rdata[7:0];
end
reg[15:0] rx_reg_db;
always @(posedge spi_done) begin
    rx_reg_db <= {rx_reg_db[7:0],mspi_rdata[7:0]};
    //rx_reg_db<=16'h07ff;
end 

//-------tx_start_signal
reg tx_start_delay;
always @(posedge clk ) begin
  tx_start_delay<=tx_start;
end
reg if_start_tx;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        if_start_tx<=1'b0;
    end else begin
        if ({tx_start_delay,tx_start}==2'b01) if_start_tx<=1'b1;
        if (busy_tx) if_start_tx <=1'b0;
    end
end
//--------busy_tx
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
        busy_tx <= 1'b0;
    else begin

        if (if_start_tx&&(!busy_rx)&&(tx_ram_start!=tx_ram_end)) busy_tx <= 1'b1;
        if (tx_cur ==  tx_fsm_finish) busy_tx<=1'b0;
    end
end

//-------tx_write_send_done
reg tx_write_send_done=1'b0;
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
        tx_write_send_done <= 1'b0;
    else begin
        if (index == 8'd120 && cur == spi_fsm_1_byte_fini) tx_write_send_done <= 1'b1;
        if (tx_cur == tx_fsm_idle) tx_write_send_done <= 1'b0;
    end
end
//--------tx_write_ip_done
reg tx_write_ip_done = 1'b0;
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
        tx_write_ip_done <= 1'b0;
    else begin
        if (index == 8'd104 && cur == spi_fsm_1_byte_fini) tx_write_ip_done <= 1'b1;
        if (tx_cur == tx_fsm_idle) tx_write_ip_done <= 1'b0;
    end
end
//-------tx_offset

always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
       tx_offset <= 0;
    else begin
        if (tx_cur== tx_fsm_write_ip_wait && cur == spi_fsm_1_byte_fini && index == 8'd104)  tx_offset <= rx_reg_db; 
        if (tx_cur == tx_fsm_write_data_wait && cur == spi_fsm_1_byte_fini && index == 8'd109) begin
            tx_offset<=tx_offset+1'b1;
        end 
    end
end
//------tx_write_data_done
reg tx_write_data_done=1'b0;
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
       tx_write_data_done <= 1'b0;
    else begin
        if (tx_cur == tx_fsm_judge || tx_cur == tx_fsm_write_ip) tx_write_data_done<=1'b0;
        if (tx_cur == tx_fsm_write_data_wait && cnt == 0 && cur == spi_fsm_1_byte_fini) tx_write_data_done<=1'b1;
    end
end

//--------tx 状态机
always @(posedge clk or negedge rstn) begin
    if(!rstn) tx_cur <= tx_fsm_idle;
    else tx_cur <= tx_nxt;
end
//------tx 状态机
always @(tx_cur or busy_tx or tx_write_ip_done or tx_write_data_done or cur ) begin
    tx_nxt = tx_cur;
    case (tx_cur)
        tx_fsm_idle: if (busy_tx) tx_nxt = tx_fsm_start;
        tx_fsm_start:   tx_nxt = tx_fsm_write_ip; 
        tx_fsm_write_ip : if (cur == spi_fsm_idle) tx_nxt = tx_fsm_write_ip_wait;
        tx_fsm_write_ip_wait: if (tx_write_ip_done) tx_nxt = tx_fsm_write_data;
        tx_fsm_write_data: if (cur == spi_fsm_idle)tx_nxt = tx_fsm_write_data_wait;
        tx_fsm_write_data_wait:    if   (tx_write_data_done) tx_nxt =tx_fsm_judge;
        tx_fsm_judge:if (tx_count==0) tx_nxt = tx_fsm_write_send ; else tx_nxt = tx_fsm_write_data;
        tx_fsm_write_send:if (cur == spi_fsm_idle) tx_nxt = tx_fsm_write_send_wait;
        tx_fsm_write_send_wait: if (tx_write_send_done) tx_nxt = tx_fsm_finish;
        tx_fsm_finish: tx_nxt = tx_fsm_idle;
        

    endcase
end
//-------busy_rx
always @(posedge clk or negedge rstn) begin
    if (!rstn) 
        busy_rx <=1'b0;
    else begin  
        if (rx_cur == rx_fsm_start) busy_rx <=1'b1;
        if (rx_cur == rx_fsm_finish) busy_rx <=1'b0;
    end 
end
assign busy = busy_tx|busy_rx|(!init_done);
//------rx_snir_reg
reg [7:0] rx_snir_reg;
always @(posedge clk or negedge rstn ) begin
    if (!rstn  ) rx_snir_reg <=0;
    else begin
        if (rx_cur== rx_fsm_write_snir_wait && cur == spi_fsm_1_byte_fini && index == 8'd130)  rx_snir_reg <= rx_reg; 
    end 
end
//------rx_read_int_reg_done
reg rx_read_int_reg_done=1'b0;
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
       rx_read_int_reg_done <= 1'b0;
    else begin
        if (rx_cur == rx_fsm_judge_int || rx_cur == rx_fsm_read_int_reg) rx_read_int_reg_done<=1'b0;
        if (index == 8'd125 && cur == spi_fsm_1_block_fini) rx_read_int_reg_done<=1'b1;
    end
end
//------rx_write_snir_done
reg rx_write_snir_done=1'b0;
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
       rx_write_snir_done <= 1'b0;
    else begin
        if (rx_cur == rx_fsm_write_snir || rx_cur == rx_fsm_idle) rx_write_snir_done<=1'b0;
        if (index == 8'd135 && cur == spi_fsm_1_block_fini) rx_write_snir_done<=1'b1;
    end
end
//------rx_read_data_done
reg rx_read_data_done=1'b0;
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
       rx_read_data_done <= 1'b0;
    else begin
        if (rx_cur == rx_fsm_read_data || rx_cur == rx_fsm_idle) rx_read_data_done<=1'b0;
        if (index == 8'd152 && cur == spi_fsm_1_block_fini) rx_read_data_done<=1'b1;
    end
end
//------rx_read_size_offset_done
reg rx_read_size_offset_done=1'b0;
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
       rx_read_size_offset_done <= 1'b0;
    else begin
        if (rx_cur == rx_fsm_read_size_offset || rx_cur == rx_fsm_idle) rx_read_size_offset_done<=1'b0;
        if (index == 8'd147 && cur == spi_fsm_1_byte_fini) rx_read_size_offset_done<=1'b1;
    end
end
//------rx_write_rev_done
reg rx_write_rev_done=1'b0;
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
       rx_write_rev_done <= 1'b0;
    else begin
        if (rx_cur == rx_fsm_write_rev || rx_cur == rx_fsm_idle) rx_write_rev_done<=1'b0;
        if (index == 8'd163 && cur == spi_fsm_1_byte_fini) rx_write_rev_done<=1'b1;
    end
end
//-------rx_size,rx_count

always @(posedge clk or negedge rstn ) begin
    if (!rstn ) rx_size<=16'd0; 
    else begin
        if (rx_cur== rx_fsm_read_size_offset_wait && cur == spi_fsm_1_byte_fini && index == 8'd141)  rx_size <= rx_reg_db; 
    end
end
always @(posedge clk or negedge rstn ) begin
    if (!rstn ) rx_count<=16'd0; 
    else begin
        if (rx_cur== rx_fsm_read_size_offset_wait && cur == spi_fsm_1_byte_fini && index == 8'd141)  rx_count <= 0; 
        if ( cur == spi_fsm_1_byte_fini && index == 8'd152) 
            rx_count<=rx_count+1'b1;
    end
end
//-----rx_offset

always @(posedge clk or negedge rstn ) begin
    if (!rstn ) rx_offset<=16'd0; 
    else begin
        if (rx_cur== rx_fsm_read_size_offset_wait && cur == spi_fsm_1_byte_fini && index == 8'd147)  rx_offset <= rx_reg_db; 
        if ( cur == spi_fsm_1_byte_fini && index == 8'd152) 
            rx_offset<=rx_offset+1'b1;
    end
end

//------clk_source
always @(posedge clk or negedge rstn) begin
  if (!rstn) clk_source = 1'b0;
  else begin
    if (index == 8'd152&&rx_count>7) begin
        if (cur == spi_fsm_spi_start) clk_source <=1'b0;
        if (cur == spi_fsm_1_byte_fini) clk_source <=1'b1;
    end else clk_source = 1'b0;
  end
end
//-------rxdata
always @(posedge clk or negedge rstn ) begin
  if (!rstn) rxdata <=0;
  else begin
    if (index == 8'd152) begin
        
        if (cur == spi_fsm_cnt_minus) rxdata <=rx_reg;
    end 
  end
end
//--------rx 状态机
always @(posedge clk or negedge rstn) begin
    if(!rstn) rx_cur <= rx_fsm_idle;
    else rx_cur <= rx_nxt;
end
//-------delay
wire clk_1S;
clk_divider  #(.CLK_DIVIDE_PARAM(RX_START_CLK_DIV)) clk_generate2
				(
					.clk(clk),
					.clk_div(clk_1S)
				);
reg clk_1S_delay;
always @(posedge clk ) begin
  clk_1S_delay<=clk_1S;
end
//----------rx_fsm
always @(rx_cur or busy_tx or init_done or cur or rx_read_int_reg_done or rx_reg or  rx_write_snir_done or rx_read_data_done
            or rx_count or rx_size or clk_1S_delay or clk_1S) begin
    rx_nxt = rx_cur;
    case(rx_cur)
        rx_fsm_idle: 
            begin
                if ((!busy_tx)&&(init_done)) rx_nxt = rx_fsm_start;
            end
        rx_fsm_start:
            begin
                if (cur == spi_fsm_idle ) rx_nxt = rx_fsm_read_int_reg;
            end
        rx_fsm_read_int_reg:
            begin
                if (cur == spi_fsm_idle)  rx_nxt = rx_fsm_read_int_reg_wait;
            end 
        rx_fsm_read_int_reg_wait:
            begin
                if (rx_read_int_reg_done) rx_nxt = rx_fsm_judge_int;
            end 
        rx_fsm_judge_int:
            if (rx_reg[0]==1'b1) rx_nxt = rx_fsm_write_snir; else rx_nxt = rx_fsm_finish;
        rx_fsm_write_snir:
            if (cur == spi_fsm_idle) rx_nxt = rx_fsm_write_snir_wait;
        rx_fsm_write_snir_wait:
            if (rx_write_snir_done) rx_nxt = rx_fsm_judge_snir;
        rx_fsm_judge_snir:
            if (rx_snir_reg[2]==1'b1) rx_nxt = rx_fsm_read_size_offset; else rx_nxt = rx_fsm_finish;
        rx_fsm_read_size_offset:
            if (cur== spi_fsm_idle) rx_nxt = rx_fsm_read_size_offset_wait;
        rx_fsm_read_size_offset_wait:
            if (rx_read_size_offset_done) rx_nxt = rx_fsm_read_data;
        rx_fsm_read_data:
            if (cur == spi_fsm_idle) rx_nxt = rx_fsm_read_data_wait;
        rx_fsm_read_data_wait:
            if (rx_read_data_done) rx_nxt = rx_fsm_judge_read_data;
        rx_fsm_judge_read_data:
            if (rx_count == rx_size) rx_nxt = rx_fsm_write_rev; else rx_nxt = rx_fsm_read_data;
        rx_fsm_write_rev:
            if (cur == spi_fsm_idle) rx_nxt = rx_fsm_write_rev_wait;
        rx_fsm_write_rev_wait:
            if (rx_write_rev_done) rx_nxt =rx_fsm_finish;
        rx_fsm_finish:
            if ({clk_1S_delay, clk_1S}==2'b01) rx_nxt = rx_fsm_finish2;
        rx_fsm_finish2:
            rx_nxt = rx_fsm_idle;
    endcase
end
//-----spi要发送de数据
reg [7:0] treg_test;
always @(posedge clk ) begin
  treg_test <= treg;
end
always @(index or tx_ram_start) begin
    case(index)
        8'd109: treg = ram[tx_ram_start];
        8'd106: treg = {5'b0000,tx_offset[10:8]};
        8'd107: treg = tx_offset[7:0];
        8'd114: treg = tx_offset[15:8];
        8'd115: treg = tx_offset[7:0];
        8'd135: treg = rx_snir_reg;
        8'd149: treg = {5'b0000,rx_offset[10:8]};
        8'd150: treg = rx_offset[7:0];
        8'd157: treg = rx_offset[15:8];
        8'd158: treg = rx_offset[7:0];
        default:treg  = mem[index];

    endcase

        
end
initial begin
//每行配置的前4位是一字节总数，两字节地址，一字节控制，后面的字节是具体配置参数

mem[0]<=8'd5;  mem[1]<=8'h00;  mem[2]<=8'h2e;  mem[3]<=8'h01;  mem[4]<=8'h00;
//查询是否接入互联网（插网线了没，如果没有，我也没处理。。。）
mem[5]<=8'd8;  mem[6]<=8'h00;  mem[7]<=8'h01;  mem[8]<=8'h04; {mem[9],mem[10],mem[11],mem[12]}<=LOCAL_IP;

//mem[5]<=8'd8;  mem[6]<=8'h00;  mem[7]<=8'h01;  mem[8]<=8'h04;  mem[9]<=8'hc0;  mem[10]<=8'ha8;  mem[11]<=8'h01;  mem[12]<=8'h01;
//设置网关(Gateway)的IP地址,Gateway_IP为4字节,自己定义 
//使用网关可以使通信突破子网的局限，通过网关可以访问到其它子网或进入Internet

mem[13]<=8'd8;  mem[14]<=8'h00;  mem[15]<=8'h05;  mem[16]<=8'h04; {mem[17],mem[18],mem[19],mem[20]}<=MASK;
//mem[13]<=8'd8;  mem[14]<=8'h00;  mem[15]<=8'h05;  mem[16]<=8'h04;  mem[17]<=8'hff;  mem[18]<=8'hff;  mem[19]<=8'hff;  mem[20]<=8'h00;
//设置子网掩码(MASK)值,SUB_MASK为4字节数组,自己定义
//子网掩码用于子网运算

mem[21]<=8'd10;  mem[22]<=8'h00;  mem[23]<=8'h09;  mem[24]<=8'h04;  {mem[25],mem[26],mem[27],mem[28],mem[29],mem[30]}<=PHY_ADDR;
//设置物理地址,PHY_ADDR为6字节数组,自己定义,用于唯一标识网络设备的物理地址值
//该地址值需要到IEEE申请，按照OUI的规定，前3个字节为厂商代码，后三个字节为产品序号
//如果自己定义物理地址，注意第一个字节必须为偶数

mem[31]<=8'd8;  mem[32]<=8'h00;  mem[33]<=8'h0f;  mem[34]<=8'h04;  {mem[35],mem[36],  mem[37],mem[38]}<=LOCAL_IP;
//设置本机的IP地址,IP_ADDR为4字节unsigned char数组,自己定义
//注意，网关IP必须与本机IP属于同一个子网，否则本机将无法找到网关

mem[39]<=8'd5;  mem[40]<=8'h00;  mem[41]<=8'h1e;  mem[42]<=8'h0d;  mem[43]<=8'h02;
mem[44]<=8'd5;  mem[45]<=8'h00;  mem[46]<=8'h1f;  mem[47]<=8'h0d;  mem[48]<=8'h02;
//设置发送缓冲区和接收缓冲区的大小，参考W5500数据手册,无需更改
mem[49]<=8'd6;  mem[50]<=8'h00;  mem[51]<=8'h12;  mem[52]<=8'h0e;  mem[53]<=8'h05;  mem[54]<=8'hb4;
//设置本机
mem[55]<=8'd6;  mem[56]<=8'h00;  mem[57]<=8'h04;  mem[58]<=8'h0e;  mem[59]<=8'h13;  mem[60]<=8'h88;
//设置本机udp Port

mem[61]<=8'd5;  mem[62]<=8'h00;  mem[63]<=8'h00;  mem[64]<=8'h0d;  mem[65]<=8'h02;
mem[66]<=8'd5;  mem[67]<=8'h00;  mem[68]<=8'h01;  mem[69]<=8'h0d;  mem[70]<=8'h01;
//开启udp

// mem[71]<=8'd8;  mem[72]<=8'h00;  mem[73]<=8'h0c;  mem[74]<=8'h0f;  mem[75]<=8'hc0;  mem[76]<=8'ha8;  mem[77]<=8'h01;  mem[78]<=8'hbe;
// //设置目的主机ip
// mem[79]<=8'd6;  mem[80]<=8'h00;  mem[81]<=8'h10;  mem[82]<=8'h0e;  mem[83]<=8'h17;  mem[84]<=8'h70;
// //设置目的主机port


mem[71]<=8'd8;  mem[72]<=8'h00;  mem[73]<=8'h0c;  mem[74]<=8'h0f; { mem[75], mem[76],mem[77],mem[78]}<=TARGET_IP;
//设置目的主机ip
mem[79]<=8'd6;  mem[80]<=8'h00;  mem[81]<=8'h10;  mem[82]<=8'h0e; { mem[83],  mem[84]}<=TARGET_PORT;
//设置目的主机port


mem[85]<=8'd8;  mem[86]<=8'h00;  mem[87]<=8'h0c;  mem[88]<=8'h0f; { mem[89], mem[90],mem[91],mem[92]}<=TARGET_IP;
mem[93]<=8'd6;  mem[94]<=8'h00;  mem[95]<=8'h10;  mem[96]<=8'h0e;  {mem[97], mem[98]}<=TARGET_PORT;
// mem[85]<=8'd8;  mem[86]<=8'h00;  mem[87]<=8'h0c;  mem[88]<=8'h0f;  mem[89]<=8'hc0;  mem[90]<=8'ha8;  mem[91]<=8'h01;  mem[92]<=8'hbe;
// mem[93]<=8'd6;  mem[94]<=8'h00;  mem[95]<=8'h10;  mem[96]<=8'h0e;  mem[97]<=8'h17;  mem[98]<=8'h70;
//send udp destination ip and port
mem[99]<=8'd6;  mem[100]<=8'h00;  mem[101]<=8'h24;  mem[102]<=8'h0a;  mem[103]<=8'h00;  mem[104]<=8'h00;
//read offset 

mem[105]<=8'd4;  mem[106]<=8'h00;  mem[107]<=8'h00;  mem[108]<=8'h14; mem[109]<=8'h00;
//send tx data,106,107 代表地址,108控制位
mem[110]<=8'd6;  mem[111]<=8'h00;  mem[112]<=8'h24;  mem[113]<=8'h0e;  mem[114]<=8'h09;  mem[115]<=8'hcc;
//写offset
mem[116]<=8'd5;  mem[117]<=8'h00;  mem[118]<=8'h01;  mem[119]<=8'h0d;  mem[120]<=8'h20;
//写启动tx

mem[121]<=8'd5;  mem[122]<=8'h00;  mem[123]<=8'h17;  mem[124]<=8'h01;  mem[125]<=8'h00;
//read int register:1
//enter interupt

//Read_W5500_SOCK_1Byte
mem[126]<=8'd5;  mem[127]<=8'h00;  mem[128]<=8'h02;  mem[129]<=8'h09;  mem[130]<=8'h00;
//read Sn_IR
//write Sn_IR = 0x04
mem[131]<=8'd5;  mem[132]<=8'h00;  mem[133]<=8'h02;  mem[134]<=8'h0d;  mem[135]<=8'h04;
//Write_W5500_SOCK_1Byte

//Read_W5500_SOCK_2Byte
mem[136]<=8'd6;  mem[137]<=8'h00;  mem[138]<=8'h26;  mem[139]<=8'h0a;  mem[140]<=8'h00;  mem[141]<=8'h00;
//read rx_size
//rx_size = 11 

//Read_W5500_SOCK_2Byte
mem[142]<=8'd6;  mem[143]<=8'h00;  mem[144]<=8'h28;  mem[145]<=8'h0a;  mem[146]<=8'h00;  mem[147]<=8'h00;
//read offset offset = 0x0000

//set cs ,send offset , control byte,and then data
mem[148]<=8'd5;  mem[149]<=8'h00;  mem[150]<=8'h00;  mem[151]<=8'h18;  mem[152]<=8'h00;

//write offset
//Write_W5500_SOCK_2Byte
mem[153]<=8'd6;  mem[154]<=8'h00;  mem[155]<=8'h28;  mem[156]<=8'h0e;  mem[157]<=8'h00;  mem[158]<=8'h0b;

//Write_W5500_SOCK_1Byte
mem[159]<=8'd5;  mem[160]<=8'h00;  mem[161]<=8'h01;  mem[162]<=8'h0d;  mem[163]<=8'h40;
//spi set recv
mem[164]<=8'd2;

end
endmodule
