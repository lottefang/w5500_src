library verilog;
use verilog.vl_types.all;
entity spi_control is
    generic(
        idle            : integer := 0;
        finish          : integer := 5;
        bitl            : integer := 7
    );
    port(
        rstn            : in     vl_logic;
        clk             : in     vl_logic;
        txdata          : in     vl_logic_vector(7 downto 0);
        din             : in     vl_logic;
        dout            : out    vl_logic;
        cs              : out    vl_logic;
        sck             : out    vl_logic;
        rxdata          : out    vl_logic_vector(7 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of idle : constant is 1;
    attribute mti_svvh_generic_type of finish : constant is 1;
    attribute mti_svvh_generic_type of bitl : constant is 1;
end spi_control;
