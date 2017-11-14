/*
 * @Author: cuidajun 
 * @Date: 2017-11-03 17:17:21 
 * @Last Modified by: cuidajun
 * @Last Modified time: 2017-11-03 22:25:28
 * @Description: �����������
    //���أ�192.168.1.1
    //����:	255.255.255.0
    //�����ַ��0C 29 AB 7C 00 01
    //����IP��ַ:192.168.1.199
    //�˿�0�Ķ˿ںţ�5000
    //�˿�0��Ŀ��IP��ַ��192.168.1.190
    //�˿�0��Ŀ�Ķ˿ںţ�6000 
 */



module spi_control(
    rstn,       //reset_n
    clk,        //main clk
    txdata,     //����ͨ��txdata������ģ��Ļ�������һ����ഫ��2K���ֽڣ���clk_sink�������أ���txdata���뻺����
    clk_sink,   //��clk_sink�������أ���txdata���뻺����
    tx_start,   //���ݴ��俪ʼ�źţ������ش���ʼ���ͻ������ڵ����ݵ�Զ��ip
    busy,       //ģ��æ�����ڽ������ݻ��߷������ݣ���ģ��Ϊ��˫��
    busy_tx,    //���ڷ������ݣ�æʱ�ɼ������ӷ������ݻ�������ȫ���������æ
    busy_rx,    //���ڽ������ݣ���������δ���ʱ�����ڷ�������ʱ��Զ��ipͬʱҲ��������2�Σ������ֶ������IP��Ϣ�ֽ�
    din,        //W5500ģ��MISO
    dout,       //W5500ģ��MOSI
    cs,         //W5500ģ��csn
    sck,        //W5500ģ��sck
    rxdata,     //���ܵ�������ͨ��rxdata������ģ�飬����clk_source�����ض���
    clk_source  //rxdata��ʱ��
    )/*synthesis noprune*/;
input       rstn,clk;
input[7:0]  txdata;  //transmit data
input       tx_start;
input       din;
output  reg cs; 
output      sck; 
output      dout; 
output[7:0] rxdata; //received data
output  reg busy,busy_tx,busy_rx;
output  reg clk_source;
input       clk_sink;

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

parameter   tx_fsm_idle             =   8'd0;
            tx_fsm_start            =   8'd1;
            tx_fsm_write_ip          =   8'd2;
            tx_fsm_write_port        =   8'd3;
            tx_fsm_read_offset      =   8'd4;
            tx_fsm_write_data       =   8'd5;
            tx_fsm_judge            =   8'd6;
            tx_fsm_write_data_again =   8'd7;
            tx_fsm_write_offset     =   8'd8;
            tx_fsm_write_send       =   8'd9;
            tx_fsm_finish           =   9'd10;
reg [7:0]   cur=spi_fsm_idle,nxt=spi_fsm_idle;
reg [7:0]   tx_cur = tx_fsm_idle,   tx_nxt  = tx_fsm_idle;

parameter init_reg_num = 84;

reg [7:0] treg;
reg [7:0] index=0;
reg [15:0] cnt=0;
reg [7:0] mem[255:0];
reg [7:0] ram[2047:0]; //tx ������
reg [10:0] tx_ram_start = 0, tx_ram_end = 0, tx_count = 0;
assign tx_count = tx_ram_end > tx_ram_start ? (tx_ram_end - tx_ram_start): (12'd2048-tx_ram_start+tx_ram_end);//tx�������ֽ�����
//tx������fifo ��
always @(posedge clk_sink or negedge rstn) begin
    if(!rstn) begin
        tx_ram_end<=0;
    end else begin 
        ram[tx_ram_end]<=txdata;
        tx_ram_end<=tx_ram_end+1'b1;
    end 
end
//tx������FIFO ��
always @(posedge clk or negedge rstn ) begin
    if (!rstn) tx_ram_start <=0;
    else if (index == 8'd109 && cur == spi_fsm_set_ptr)
        tx_ram_start <= tx_ram_start +1'b1;
end




//spi ״̬��״̬ת��
wire spi_done;
reg index_add_flag;
always @(cur or init_done or spi_done or cnt) 
    begin
        nxt=cur;
        case(cur)
            spi_fsm_idle:   //idle
                begin
                if ((!init_done)||(busy_tx)) nxt = spi_fsm_set_cnt ;
                end
            spi_fsm_set_cnt:    //���ñ���spi�����ֽڸ������õ�cs
                begin
                  nxt   =  spi_fsm_set_ptr ;
                end
            spi_fsm_set_ptr :   //���ô������ݵ�ָ��
                begin
                  nxt   =   spi_fsm_set_tx_data;
                end     
            spi_fsm_set_tx_data ://����spi������
                begin
                  nxt = spi_fsm_spi_start; 
                end
            spi_fsm_spi_start  ://����spi���䣬����һ���ֽ�
                begin
                  nxt = spi_fsm_spi_wait;
                end 
            spi_fsm_spi_wait   ://�ȴ�spi�������
                begin
                  if (spi_done) nxt = spi_fsm_cnt_minus;
                end
            spi_fsm_cnt_minus   ://����cnt��ptr
                begin
                    nxt = spi_fsm_1_byte_fini;
                end
            spi_fsm_1_byte_fini://�ж��Ƿ�һ֡���ݴ������
                begin
                    if  (cnt == 0) 
                        nxt = spi_fsm_1_block_fini; 
                    else 
                        nxt = spi_fsm_set_ptr;
                end
            spi_fsm_1_block_fini://�ж�ʱ����Ҫ����һ֡����
                begin
                    if  (!init_done) 
                        nxt = spi_fsm_set_cnt;
                    else 
                        nxt = spi_fsm_finish;
                end
            spi_fsm_finish ://�ص�idle
                begin
                    nxt = spi_fsm_idle;
                end    
            default: nxt=spi_fsm_idle;
        endcase
    end//always

//-------spi״̬��
always@(posedge clk or negedge rstn) begin
    if(!rstn) 
        cur<=spi_fsm_idle; 
    else begin
        cur<=nxt;
    end
end

//----spi һ������֡�ĸ��� cnt
always@(posedge clk or negedge rstn) begin
    if(!rstn) 
        cnt<=0;
    else 
    case (cur)
        spi_fsm_set_cnt:    
            begin
                if ((!init_done) || busy_tx) cnt <= mem[index]-1'b1;
                if (busy_tx && tx_cur == tx_fsm_write_data) 
                begin
                    if (12'd2048-offset[10:0]>=tx_count) 
                        cnt <= tx_count+3; 
                    else 
                        cnt <= 12'd2048-offset[10:0] +3;
                end
            end 
        spi_fsm_cnt_minus:
            if ((!init_done) || busy_tx) cnt <= cnt -1'b1;
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
                end
            spi_fsm_set_ptr:
                begin
                     if ((!init_done) || busy_tx) index <= index +1'b1;
                     if (index == 8'd109) index<=8'd109;
                end
            spi_fsm_1_block_fini:
                begin
                     if ((!init_done) || busy_tx) index <= index +1'b1;
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
            if (!init_done) spi_start <= 1'b1; 
        spi_fsm_spi_wait: spi_start <=1'b0;
  endcase
end

wire[7:0] rreg;
wire [31:0]mspi_rdata;
wire mspi_ready;

mspi mspi_inst(
					.clk(clk),		// global clock
					.rst(~rstn),		// global async low reset
					.clk_div(4),	// spi clock divider
					.wr(spi_start),			// spi write/read
					.wr_len(2'd0),		// spi write or read byte number
					.wr_done(spi_done),	// write done /read done
					.wrdata({treg,24'd0}),		// spi write data, ??����??wr_len?��????8��????16��?????32�� 
					.rddata(mspi_rdata),		// spi recieve data, valid when wr_done assert??����??wr_len?��????8��????16��?????32�� 
					.sck(sck),		// spi master clock out 
					.sdi(din),		// spi master data in (MISO) 
					.sdo(dout),		// spi master data out (MOSI) 
					.ss(),			// spi cs
					.ready(mspi_ready)		// spi master ready (idle) 
					);
//------rx_reg �ݴ�spi���յ���byte
reg[7:0]  rx_reg;
always @(posedge spi_done) begin
  rx_reg<=mspi_rdata[7:0];
end
reg[15:0] rx_reg_db;
always @(posedge spi_done) begin
    rx_reg_db <= {rx_reg_db[7:0],mspi_rdata[7:0]};
end 

//--------busy_tx
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
        busy_tx <= 1'b0;
    else begin

        if (tx_start && (!busy_rx)) busy_tx <= 1'b1;
        if (tx_cur ==  tx_fsm_finish) busy_tx<=1'b0;
    end
end
//----init_done �Ƿ��ʼ�����
reg init_done = 1'b0;
always @(posedge clk or negedge rstn) begin
  if(!rstn) 
    init_done<=1'b0;
  else if ((index == init_reg_num) &&( cur == spi_fsm_1_byte_fini )) 
    init_done <= 1'b1;
end
//-------tx_write_send_done
reg tx_write_send_done=1'b0;
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
        tx_write_send_done <= 1'b0;
    else begin
        if (index == 8'119 && cur == spi_fsm_1_byte_fini) tx_write_send_done <= 1'b1;
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
reg [15:0] tx_offset
always @(posedge clk or negedge rstn ) begin
  if(!rstn) 
       tx_offset <= 0;
    else begin
        if (tx_cur== tx_fsm_write_ip && cur == spi_fsm_1_byte_fini && index == 8'd104)  tx_offset <= rx_reg_db; 
        if (tx_cur == tx_fsm_write_data && cur == spi_fsm_set_ptr && index == 8'd109) begin
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
        if ((tx_cur == tx_fsm_judge || tx_cur == tx_fsm_write_ip) tx_write_data_done<=1'b0;
        if (tx_cur == tx_fsm_write_data && cnt == 0 && cur == spi_fsm_1_byte_fini) tx_write_data_done<=1'b1;
    end
end
//-----spiҪ����de����
always @(index or tx_ram_start) begin
    case(index)
        8'd109: treg = ram[tx_ram_start-1'b1];
        8'd106: treg = {5'b0000,offset[10:8]};
        8'd107: treg = offset[7:0];
        default:treg  = mem[index];

    endcase
    if (index == 8'd109)
        treg = ram[tx_ram_start-1'b1];
    else 
        
end
//--------tx ״̬��
always @(posedge clk or negedge rstn) begin
    if(!rstn) tx_cur <= tx_fsm_idle;
    else tx_cur <= tx_nxt;
end
//------tx ״̬��
always @(cur or busy_tx or tx_write_ip_done or tx_write_data_done) begin
    tx_nxt = tx_cur;
    case (tx_cur)
        tx_fsm_idle: if (busy_tx) tx_nxt = tx_fsm_start;
        tx_fsm_start:   tx_nxt = tx_fsm_write_ip; 
        tx_fsm_write_ip : if (tx_write_ip_done) tx_nxt = tx_fsm_write_data;
        tx_fsm_write_data: if   (tx_write_data_done) tx_nxt =tx_fsm_judge;
        tx_fsm_judge:if (tx_count==0) tx_nxt = tx_fsm_write_send ; else tx_nxt = tx_fsm_write_data;
        tx_fsm_write_send: if (tx_write_send_done) tx_nxt = tx_fsm_finish;
        tx_fsm_finish: tx_nxt = tx_fsm_idle;
        

    endcase
end


initial begin
//ÿ�����õ�ǰ4λ��һ�ֽ����������ֽڵ�ַ��һ�ֽڿ��ƣ�������ֽ��Ǿ������ò���

mem[0]<=8'd5;  mem[1]<=8'h00;  mem[2]<=8'h2e;  mem[3]<=8'h01;  mem[4]<=8'h00;
//��ѯ�Ƿ���뻥��������������û�����û�У���Ҳû����������

mem[5]<=8'd8;  mem[6]<=8'h00;  mem[7]<=8'h01;  mem[8]<=8'h04;  mem[9]<=8'hc0;  mem[10]<=8'ha8;  mem[11]<=8'h01;  mem[12]<=8'h01;
//��������(Gateway)��IP��ַ,Gateway_IPΪ4�ֽ�,�Լ����� 
//ʹ�����ؿ���ʹͨ��ͻ�������ľ��ޣ�ͨ�����ؿ��Է��ʵ��������������Internet

mem[13]<=8'd8;  mem[14]<=8'h00;  mem[15]<=8'h05;  mem[16]<=8'h04;  mem[17]<=8'hff;  mem[18]<=8'hff;  mem[19]<=8'hff;  mem[20]<=8'h00;
//������������(MASK)ֵ,SUB_MASKΪ4�ֽ�����,�Լ�����
//��������������������

mem[21]<=8'd10;  mem[22]<=8'h00;  mem[23]<=8'h09;  mem[24]<=8'h04;  mem[25]<=8'h0c;  mem[26]<=8'h29;  mem[27]<=8'hab;  mem[28]<=8'h7c;  mem[29]<=8'h00;  mem[30]<=8'h01;
//���������ַ,PHY_ADDRΪ6�ֽ�����,�Լ�����,����Ψһ��ʶ�����豸�������ֵַ
//�õ�ֵַ��Ҫ��IEEE���룬����OUI�Ĺ涨��ǰ3���ֽ�Ϊ���̴��룬�������ֽ�Ϊ��Ʒ���
//����Լ����������ַ��ע���һ���ֽڱ���Ϊż��

mem[31]<=8'd8;  mem[32]<=8'h00;  mem[33]<=8'h0f;  mem[34]<=8'h04;  mem[35]<=8'hc0;  mem[36]<=8'ha8;  mem[37]<=8'h01;  mem[38]<=8'hc7;
//���ñ�����IP��ַ,IP_ADDRΪ4�ֽ�unsigned char����,�Լ�����
//ע�⣬����IP�����뱾��IP����ͬһ�����������򱾻����޷��ҵ�����

mem[39]<=8'd5;  mem[40]<=8'h00;  mem[41]<=8'h1e;  mem[42]<=8'h0d;  mem[43]<=8'h02;
mem[44]<=8'd5;  mem[45]<=8'h00;  mem[46]<=8'h1f;  mem[47]<=8'h0d;  mem[48]<=8'h02;
//���÷��ͻ������ͽ��ջ������Ĵ�С���ο�W5500�����ֲ�,�������
mem[49]<=8'd6;  mem[50]<=8'h00;  mem[51]<=8'h12;  mem[52]<=8'h0e;  mem[53]<=8'h05;  mem[54]<=8'hb4;
//���ñ���
mem[55]<=8'd6;  mem[56]<=8'h00;  mem[57]<=8'h04;  mem[58]<=8'h0e;  mem[59]<=8'h13;  mem[60]<=8'h88;
//���ñ���udp Port

mem[61]<=8'd5;  mem[62]<=8'h00;  mem[63]<=8'h00;  mem[64]<=8'h0d;  mem[65]<=8'h02;
mem[66]<=8'd5;  mem[67]<=8'h00;  mem[68]<=8'h01;  mem[69]<=8'h0d;  mem[70]<=8'h01;
//����udp

mem[71]<=8'd8;  mem[72]<=8'h00;  mem[73]<=8'h0c;  mem[74]<=8'h0f;  mem[75]<=8'hc0;  mem[76]<=8'ha8;  mem[77]<=8'h01;  mem[78]<=8'hbe;
//����Ŀ������ip
mem[79]<=8'd6;  mem[80]<=8'h00;  mem[81]<=8'h10;  mem[82]<=8'h0e;  mem[83]<=8'h17;  mem[84]<=8'h70;
//����Ŀ������port


mem[85]<=8'd8;  mem[86]<=8'h00;  mem[87]<=8'h0c;  mem[88]<=8'h0f;  mem[89]<=8'hc0;  mem[90]<=8'ha8;  mem[91]<=8'h01;  mem[92]<=8'hbe;
mem[93]<=8'd6;  mem[94]<=8'h00;  mem[95]<=8'h10;  mem[96]<=8'h0e;  mem[97]<=8'h17;  mem[98]<=8'h70;
//send udp destination ip and port
mem[99]<=8'd6;  mem[100]<=8'h00;  mem[101]<=8'h24;  mem[102]<=8'h0a;  mem[103]<=8'h00;  mem[104]<=8'h00;
//read offset 

mem[105]<=8'd4;  mem[106]<=8'h00;  mem[107]<=8'h00;  mem[108]<=8'h14; mem[109]<=8'h00;
//send tx data,106,107 �����ַ,108����λ
mem[110]<=8'd6;  mem[111]<=8'h00;  mem[112]<=8'h24;  mem[113]<=8'h0e;  mem[114]<=8'h09;  mem[115]<=8'hcc;
//дoffset
mem[116]<=8'd5;  mem[117]<=8'h00;  mem[118]<=8'h01;  mem[119]<=8'h0d;  mem[120]<=8'h20;
//д����tx
end
endmodule
