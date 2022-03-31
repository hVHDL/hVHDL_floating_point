library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_multiplier_pkg.all;
    use work.float_adder_pkg.all;

package float_first_order_filter_pkg is

------------------------------------------------------------------------
    type first_order_filter_record is record
        filter_counter   : integer range 0 to 7 ;
        u                : float_record;
        y                : float_record;
        filter_is_ready : boolean;
    end record;

    constant init_first_order_filter : first_order_filter_record := (
        0, zero, to_float(-1.0), false);

------------------------------------------------------------------------
    procedure create_first_order_filter (
        signal first_order_filter_object : inout first_order_filter_record;
        signal float_multiplier          : inout float_multiplier_record;
        signal float_adder               : inout float_adder_record;
        filter_gain : in float_record);
------------------------------------------------------------------------
    procedure request_float_filter (
        signal first_order_filter_object : inout first_order_filter_record;
        filter_data : float_record);

------------------------------------------------------------------------
    function float_filter_is_ready ( first_order_filter_object : first_order_filter_record)
        return boolean;
------------------------------------------------------------------------
    function get_filter_output ( first_order_filter_object : first_order_filter_record)
        return float_record;
------------------------------------------------------------------------
end package float_first_order_filter_pkg;

package body float_first_order_filter_pkg is

------------------------------------------------------------------------
    procedure create_first_order_filter
    (
        signal first_order_filter_object : inout first_order_filter_record;
        signal float_multiplier          : inout float_multiplier_record;
        signal float_adder               : inout float_adder_record;
        filter_gain                      : in float_record
        
    ) is
        alias filter_counter   is first_order_filter_object.filter_counter  ;
        alias y                is first_order_filter_object.y               ;
        alias u                is first_order_filter_object.u               ;
        alias filter_is_ready is first_order_filter_object.filter_is_ready;
    begin

        filter_is_ready <= false;
        CASE filter_counter is
            WHEN 0 => 
                request_subtraction(float_adder, u, y);
                filter_counter <= filter_counter + 1;
            WHEN 1 =>
                if adder_is_ready(float_adder) then
                    request_float_multiplier(float_multiplier  , get_result(float_adder) , filter_gain);
                    filter_counter <= filter_counter + 1;
                end if;

            WHEN 2 =>
                if float_multiplier_is_ready(float_multiplier) then
                    request_add(float_adder, get_multiplier_result(float_multiplier), y);
                    filter_counter <= filter_counter + 1;
                end if;
            WHEN 3 => 
                if adder_is_ready(float_adder) then
                    filter_is_ready <= true;
                    y <= normalize(get_result(float_adder));
                    filter_counter <= filter_counter + 1;
                end if;
            WHEN others =>  -- filter is ready
        end CASE;
    end create_first_order_filter;
------------------------------------------------------------------------
    procedure request_float_filter
    (
        signal first_order_filter_object : inout first_order_filter_record;
        filter_data : float_record
    ) is
    begin

        first_order_filter_object.u <= filter_data;
        first_order_filter_object.filter_counter <= 0;
        
    end request_float_filter;
------------------------------------------------------------------------
    function float_filter_is_ready
    (
        first_order_filter_object : first_order_filter_record
    )
    return boolean
    is
    begin
        return first_order_filter_object.filter_is_ready;
    end float_filter_is_ready;
------------------------------------------------------------------------
    function get_filter_output
    (
        first_order_filter_object : first_order_filter_record
    )
    return float_record
    is
    begin
        return first_order_filter_object.y;
    end get_filter_output;

end package body float_first_order_filter_pkg;
