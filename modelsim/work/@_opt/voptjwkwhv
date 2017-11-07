library verilog;
use verilog.vl_types.all;
entity clk_divider is
    generic(
        CLK_DIVIDE_PARAM: vl_notype
    );
    port(
        clk             : in     vl_logic;
        clk_div         : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of CLK_DIVIDE_PARAM : constant is 5;
end clk_divider;
