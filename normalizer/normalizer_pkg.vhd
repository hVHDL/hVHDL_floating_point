library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;

package normalizer_pkg is
------------------------------------------------------------------------
    type normalizer_record is record
        normalizer_is_done : boolean;
        normalizer_is_requested : boolean;
    end record;

    constant init_normalizer : normalizer_record := (false, false);
------------------------------------------------------------------------
    procedure create_normalizer (
        signal normalizer_object : inout normalizer_record);
------------------------------------------------------------------------
    procedure request_normalizer (
        signal normalizer_object : out normalizer_record);
------------------------------------------------------------------------
    function normalizer_is_ready (normalizer_object : normalizer_record)
        return boolean;
------------------------------------------------------------------------
end package normalizer_pkg;

package body normalizer_pkg is
------------------------------------------------------------------------
    procedure create_normalizer 
    (
        signal normalizer_object : inout normalizer_record
    ) 
    is
        alias normalizer_is_requested is normalizer_object.normalizer_is_requested;
        alias normalizer_is_done is normalizer_object.normalizer_is_done;
    begin
        normalizer_is_requested <= false;
        if normalizer_is_requested then
            normalizer_is_done <= true;
        else
            normalizer_is_done <= false;
        end if;
    end procedure;

------------------------------------------------------------------------
    procedure request_normalizer
    (
        signal normalizer_object : out normalizer_record
    ) is
    begin
        normalizer_object.normalizer_is_requested <= true;
        
    end request_normalizer;

------------------------------------------------------------------------
    function normalizer_is_ready
    (
        normalizer_object : normalizer_record
    )
    return boolean
    is
    begin
        return normalizer_object.normalizer_is_done;
    end normalizer_is_ready;

------------------------------------------------------------------------
end package body normalizer_pkg;
