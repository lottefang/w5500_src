library verilog;
use verilog.vl_types.all;
entity mspi is
    generic(
        clock_polarity  : integer := 1;
        BYTE_NUM_1      : integer := 0;
        BYTE_NUM_2      : integer := 1;
        BYTE_NUM_4      : integer := 2
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        clk_div         : in     vl_logic_vector(7 downto 0);
        wr              : in     vl_logic;
        wr_len          : in     vl_logic_vector(1 downto 0);
        wr_done         : out    vl_logic;
        wrdata          : in     vl_logic_vector(31 downto 0);
        rddata          : out    vl_logic_vector(31 downto 0);
        sck             : out    vl_logic;
        sdi             : in     vl_logic;
        sdo             : out    vl_logic;
        ss              : out    vl_logic;
        ready           : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of clock_polarity : constant is 1;
    attribute mti_svvh_generic_type of BYTE_NUM_1 : constant is 1;
    attribute mti_svvh_generic_type of BYTE_NUM_2 : constant is 1;
    attribute mti_svvh_generic_type of BYTE_NUM_4 : constant is 1;
end mspi;
