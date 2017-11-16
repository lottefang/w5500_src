library verilog;
use verilog.vl_types.all;
entity spi_control is
    generic(
        spi_fsm_idle    : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0);
        spi_fsm_set_cnt : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1);
        spi_fsm_set_ptr : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0);
        spi_fsm_set_tx_data: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1);
        spi_fsm_spi_start: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0);
        spi_fsm_spi_wait: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1);
        spi_fsm_cnt_minus: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0);
        spi_fsm_1_byte_fini: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi1);
        spi_fsm_1_block_fini: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0);
        spi_fsm_finish  : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi1);
        tx_fsm_idle     : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0);
        tx_fsm_start    : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1);
        tx_fsm_write_ip : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0);
        tx_fsm_write_ip_wait: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1);
        tx_fsm_read_offset: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0);
        tx_fsm_read_offset_wait: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1);
        tx_fsm_write_data: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0);
        tx_fsm_write_data_wait: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi1);
        tx_fsm_judge    : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0);
        tx_fsm_write_send: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi1);
        tx_fsm_write_send_wait: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi0);
        tx_fsm_finish   : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1);
        rx_fsm_idle     : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0);
        rx_fsm_start    : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1);
        rx_fsm_read_int_reg: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0);
        rx_fsm_read_int_reg_wait: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1);
        rx_fsm_judge_int: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0);
        rx_fsm_write_snir: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1);
        rx_fsm_write_snir_wait: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0);
        rx_fsm_judge_snir: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi1);
        rx_fsm_read_size_offset: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0);
        rx_fsm_read_size_offset_wait: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi1);
        rx_fsm_read_data: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi0);
        rx_fsm_read_data_wait: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1);
        rx_fsm_judge_read_data: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0);
        rx_fsm_write_rev: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi1);
        rx_fsm_write_rev_wait: vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi1, Hi0);
        rx_fsm_finish   : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi1, Hi1);
        rx_fsm_finish2  : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0);
        init_reg_num    : integer := 84
    );
    port(
        rstn            : in     vl_logic;
        clk             : in     vl_logic;
        txdata          : in     vl_logic_vector(7 downto 0);
        clk_sink        : in     vl_logic;
        tx_start        : in     vl_logic;
        busy            : out    vl_logic;
        busy_tx         : out    vl_logic;
        busy_rx         : out    vl_logic;
        din             : in     vl_logic;
        dout            : out    vl_logic;
        cs              : out    vl_logic;
        sck             : out    vl_logic;
        rxdata          : out    vl_logic_vector(7 downto 0);
        clk_source      : out    vl_logic;
        init_done       : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of spi_fsm_idle : constant is 1;
    attribute mti_svvh_generic_type of spi_fsm_set_cnt : constant is 1;
    attribute mti_svvh_generic_type of spi_fsm_set_ptr : constant is 1;
    attribute mti_svvh_generic_type of spi_fsm_set_tx_data : constant is 1;
    attribute mti_svvh_generic_type of spi_fsm_spi_start : constant is 1;
    attribute mti_svvh_generic_type of spi_fsm_spi_wait : constant is 1;
    attribute mti_svvh_generic_type of spi_fsm_cnt_minus : constant is 1;
    attribute mti_svvh_generic_type of spi_fsm_1_byte_fini : constant is 1;
    attribute mti_svvh_generic_type of spi_fsm_1_block_fini : constant is 1;
    attribute mti_svvh_generic_type of spi_fsm_finish : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_idle : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_start : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_write_ip : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_write_ip_wait : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_read_offset : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_read_offset_wait : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_write_data : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_write_data_wait : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_judge : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_write_send : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_write_send_wait : constant is 1;
    attribute mti_svvh_generic_type of tx_fsm_finish : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_idle : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_start : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_read_int_reg : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_read_int_reg_wait : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_judge_int : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_write_snir : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_write_snir_wait : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_judge_snir : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_read_size_offset : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_read_size_offset_wait : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_read_data : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_read_data_wait : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_judge_read_data : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_write_rev : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_write_rev_wait : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_finish : constant is 1;
    attribute mti_svvh_generic_type of rx_fsm_finish2 : constant is 1;
    attribute mti_svvh_generic_type of init_reg_num : constant is 1;
end spi_control;
