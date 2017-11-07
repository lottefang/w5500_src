library verilog;
use verilog.vl_types.all;
entity top_module is
    port(
        clk             : in     vl_logic;
        rstn            : in     vl_logic;
        led             : out    vl_logic_vector(1 downto 0);
        MISO            : in     vl_logic;
        MOSI            : out    vl_logic;
        cs              : out    vl_logic;
        sck             : out    vl_logic
    );
end top_module;
