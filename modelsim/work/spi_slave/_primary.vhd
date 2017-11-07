library verilog;
use verilog.vl_types.all;
entity spi_slave is
    port(
        rstb            : in     vl_logic;
        ten             : in     vl_logic;
        tdata           : in     vl_logic_vector(7 downto 0);
        mlb             : in     vl_logic;
        ss              : in     vl_logic;
        sck             : in     vl_logic;
        sdin            : in     vl_logic;
        sdout           : out    vl_logic;
        done            : out    vl_logic;
        rdata           : out    vl_logic_vector(7 downto 0)
    );
end spi_slave;
