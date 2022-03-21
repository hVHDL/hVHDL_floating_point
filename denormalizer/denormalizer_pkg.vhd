library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package denormalizer_pkg is
------------------------------------------------------------------------
    type denormalizer_record is record
        denormalizer_is_done : boolean;
        denormalizer_is_requested : boolean;
    end record;

    constant init_denormalizer : denormalizer_record := (false, false);
------------------------------------------------------------------------
    procedure create_denormalizer (
        signal denormalizer_object : inout denormalizer_record);
------------------------------------------------------------------------
    procedure request_denormalizer (
        signal denormalizer_object : out denormalizer_record);
------------------------------------------------------------------------
    function denormalizer_is_ready (denormalizer_object : denormalizer_record)
        return boolean;
------------------------------------------------------------------------
end package denormalizer_pkg;

package body denormalizer_pkg is
------------------------------------------------------------------------
    procedure create_denormalizer 
    (
        signal denormalizer_object : inout denormalizer_record
    ) 
    is
        alias denormalizer_is_requested is denormalizer_object.denormalizer_is_requested;
        alias denormalizer_is_done is denormalizer_object.denormalizer_is_done;
    begin
        denormalizer_is_requested <= false;
        if denormalizer_is_requested then
            denormalizer_is_done <= true;
        else
            denormalizer_is_done <= false;
        end if;
    end procedure;

------------------------------------------------------------------------
    procedure request_denormalizer
    (
        signal denormalizer_object : out denormalizer_record
    ) is
    begin
        denormalizer_object.denormalizer_is_requested <= true;
        
    end request_denormalizer;

------------------------------------------------------------------------
    function denormalizer_is_ready
    (
        denormalizer_object : denormalizer_record
    )
    return boolean
    is
    begin
        return denormalizer_object.denormalizer_is_done;
    end denormalizer_is_ready;

------------------------------------------------------------------------
end package body denormalizer_pkg;
