`define MR		'h0000
	`define RST		'h80
	`define WOL		'h20
	`define PB		'h10
	`define PPP		'h08
	`define FARP	'h02

`define GAR		'h0001
`define SUBR	'h0005
`define SHAR	'h0009
`define SIPR	'h000f

`define INTLEVEL	'h0013
`define IR		'h0015
	`define CONFLICT	'h80
	`define UNREACH		'h40
	`define PPPOE		'h20
	`define MP			'h10

`define IMR		'h0016
	`define IM_IR7		'h80
	`define IM_IR6		'h40
	`define IM_IR5		'h20
	`define IM_IR4		'h10

`define SIR		'h0017
	`define S7_INT		'h80
	`define S6_INT		'h40
	`define S5_INT		'h20
	`define S4_INT		'h10
	`define S3_INT		'h08
	`define S2_INT		'h04
	`define S1_INT		'h02
	`define S0_INT		'h01

`define SIMR	'h0018
	`define S7_IMR		'h80
	`define S6_IMR		'h40
	`define S5_IMR		'h20
	`define S4_IMR		'h10
	`define S3_IMR		'h08
	`define S2_IMR		'h04
	`define S1_IMR		'h02
	`define S0_IMR		'h01

`define RTR		'h0019
`define RCR		'h001b

`define PTIMER	'h001c
`define PMAGIC	'h001d
`define PHA		'h001e
`define PSID	'h0024
`define PMRU	'h0026

`define UIPR	'h0028
`define UPORT	'h002c

`define PHYCFGR	'h002e
	`define RST_PHY		'h80
	`define OPMODE		'h40
	`define DPX			'h04
	`define SPD			'h02
	`define LINK		'h01

`define VERR	'h0039

/********************* Socket Register *******************/
`define Sn_MR		'h0000
	`define MULTI_MFEN		'h80
	`define BCASTB			'h40
	`define	ND_MC_MMB		'h20
	`define UCASTB_MIP6B	'h10
	`define MR_CLOSE		'h00
	`define MR_TCP		'h01
	`define MR_UDP		'h02
	`define MR_MACRAW		'h04

`define Sn_CR		'h0001
	`define OPEN		'h01
	`define LISTEN		'h02
	`define CONNECT		'h04
	`define DISCON		'h08
	`define CLOSE		'h10
	`define SEND		'h20
	`define SEND_MAC	'h21
	`define SEND_KEEP	'h22
	`define RECV		'h40

`define Sn_IR		'h0002
	`define IR_SEND_OK		'h10
	`define IR_TIMEOUT		'h08
	`define IR_RECV			'h04
	`define IR_DISCON		'h02
	`define IR_CON			'h01

`define Sn_SR		'h0003
	`define SOCK_CLOSED		'h00
	`define SOCK_INIT		'h13
	`define SOCK_LISTEN		'h14
	`define SOCK_ESTABLISHED	'h17
	`define SOCK_CLOSE_WAIT		'h1c
	`define SOCK_UDP		'h22
	`define SOCK_MACRAW		'h02

	`define SOCK_SYNSEND	'h15
	`define SOCK_SYNRECV	'h16
	`define SOCK_FIN_WAI	'h18
	`define SOCK_CLOSING	'h1a
	`define SOCK_TIME_WAIT	'h1b
	`define SOCK_LAST_ACK	'h1d

`define Sn_PORT		'h0004
`define Sn_DHAR	   	'h0006
`define Sn_DIPR		'h000c
`define Sn_DPORTR	'h0010

`define Sn_MSSR		'h0012
`define Sn_TOS		'h0015
`define Sn_TTL		'h0016

`define Sn_RXBUF_SIZE	'h001e
`define Sn_TXBUF_SIZE	'h001f
`define Sn_TX_FSR	'h0020
`define Sn_TX_RD	'h0022
`define Sn_TX_WR	'h0024
`define Sn_RX_RSR	'h0026
`define Sn_RX_RD	'h0028
`define Sn_RX_WR	'h002a

`define Sn_IMR		'h002c
	`define IMR_SENDOK	'h10
	`define IMR_TIMEOUT	'h08
	`define IMR_RECV	'h04
	`define IMR_DISCON	'h02
	`define IMR_CON		'h01

`define Sn_FRAG		'h002d
`define Sn_KPALVTR	'h002f

/*******************************************************************/
/************************ SPI Control Byte *************************/
/*******************************************************************/
/* Operation mode bits */
`define VDM		'h00
`define FDM1	'h01
`define	FDM2	'h02
`define FDM4	'h03

/* Read_Write control bit */
`define RWB_READ	'h00
`define RWB_WRITE	'h04

/* Block select bits */
`define COMMON_R	'h00

/* Socket 0 */
`define S0_REG		'h08
`define S0_TX_BUF	'h10
`define S0_RX_BUF	'h18

/* Socket 1 */
`define S1_REG		'h28
`define S1_TX_BUF	'h30
`define S1_RX_BUF	'h38

/* Socket 2 */
`define S2_REG		'h48
`define S2_TX_BUF	'h50
`define S2_RX_BUF	'h58

/* Socket 3 */
`define S3_REG		'h68
`define S3_TX_BUF	'h70
`define S3_RX_BUF	'h78

/* Socket 4 */
`define S4_REG		'h88
`define S4_TX_BUF	'h90
`define S4_RX_BUF	'h98

/* Socket 5 */
`define S5_REG		'ha8
`define S5_TX_BUF	'hb0
`define S5_RX_BUF	'hb8

/* Socket 6 */
`define S6_REG		'hc8
`define S6_TX_BUF	'hd0
`define S6_RX_BUF	'hd8

/* Socket 7 */
`define S7_REG		'he8
`define S7_TX_BUF	'hf0
`define S7_RX_BUF	'hf8

`define TRUE	'hff
`define FALSE	'h00

`define S_RX_SIZE	2048	/*定义Socket接收缓冲区的大小，可以根据W5500_RMSR的设置修改 */
`define S_TX_SIZE	2048  	/*定义Socket发送缓冲区的大小，可以根据W5500_TMSR的设置修改 */
