library verilog;
use verilog.vl_types.all;
entity spi_master is
    generic(
        idle            : vl_logic_vector(0 to 1) := (Hi0, Hi0);
        send            : vl_logic_vector(0 to 1) := (Hi1, Hi0);
        finish          : vl_logic_vector(0 to 1) := (Hi1, Hi1)
    );
    port(
        rstb            : in     vl_logic;
        clk             : in     vl_logic;
        mlb             : in     vl_logic;
        start           : in     vl_logic;
        tdat            : in     vl_logic_vector(7 downto 0);
        cdiv            : in     vl_logic_vector(1 downto 0);
        din             : in     vl_logic;
        ss              : out    vl_logic;
        sck             : out    vl_logic;
        dout            : out    vl_logic;
        done            : out    vl_logic;
        rdata           : out    vl_logic_vector(7 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of idle : constant is 1;
    attribute mti_svvh_generic_type of send : constant is 1;
    attribute mti_svvh_generic_type of finish : constant is 1;
end spi_master;
