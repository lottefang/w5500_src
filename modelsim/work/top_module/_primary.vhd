library verilog;
use verilog.vl_types.all;
entity top_module is
    generic(
        rstn_cnt        : integer := 100
    );
    port(
        clk             : in     vl_logic;
        rstn            : in     vl_logic;
        led             : out    vl_logic_vector(1 downto 0);
        MISO            : in     vl_logic;
        MOSI            : out    vl_logic;
        cs              : out    vl_logic;
        sck             : out    vl_logic;
        clk_div         : out    vl_logic;
        mspi_sck        : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of rstn_cnt : constant is 1;
end top_module;
