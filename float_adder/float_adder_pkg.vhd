library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package float_adder_pkg is
------------------------------------------------------------------------
    type float_adder_record is record
        float_adder_is_done : boolean;
        float_adder_is_requested : boolean;
    end record;

    constant init_float_adder : float_adder_record := (false, false);
------------------------------------------------------------------------
    procedure create_float_adder (
        signal float_adder_object : inout float_adder_record);
------------------------------------------------------------------------
    procedure request_float_adder (
        signal float_adder_object : out float_adder_record);
------------------------------------------------------------------------
    function float_adder_is_ready (float_adder_object : float_adder_record)
        return boolean;
------------------------------------------------------------------------
end package float_adder_pkg;

package body float_adder_pkg is
------------------------------------------------------------------------
    procedure create_float_adder 
    (
        signal float_adder_object : inout float_adder_record
    ) 
    is
        alias float_adder_is_requested is float_adder_object.float_adder_is_requested;
        alias float_adder_is_done is float_adder_object.float_adder_is_done;
    begin
        float_adder_is_requested <= false;
        if float_adder_is_requested then
            float_adder_is_done <= true;
        else
            float_adder_is_done <= false;
        end if;
    end procedure;

------------------------------------------------------------------------
    procedure request_float_adder
    (
        signal float_adder_object : out float_adder_record
    ) is
    begin
        float_adder_object.float_adder_is_requested <= true;
        
    end request_float_adder;

------------------------------------------------------------------------
    function float_adder_is_ready
    (
        float_adder_object : float_adder_record
    )
    return boolean
    is
    begin
        return float_adder_object.float_adder_is_done;
    end float_adder_is_ready;

------------------------------------------------------------------------
end package body float_adder_pkg;
