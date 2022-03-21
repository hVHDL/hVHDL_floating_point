library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.float_record;
    use work.float_type_definitions_pkg.normalize;
    use work.float_type_definitions_pkg.zero;
    use work.float_type_definitions_pkg.float_array;

package normalizer_pkg is
------------------------------------------------------------------------
    type normalizer_record is record
        normalizer_is_requested : std_logic_vector(2 downto 0);
        normalized_data         : float_array(0 to 2);
    end record;

    constant init_normalizer : normalizer_record := ((others => '0'), (zero, zero, zero));
------------------------------------------------------------------------
    procedure create_normalizer (
        signal normalizer_object : inout normalizer_record);
------------------------------------------------------------------------
    procedure request_normalizer (
        signal normalizer_object : out normalizer_record;
        float_input : in float_record);
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
        alias normalized_data         is normalizer_object.normalized_data;
    begin
        normalizer_is_requested <= normalizer_is_requested(normalizer_is_requested'left-1 downto 0) & '0';
        normalized_data(1)      <= normalize(normalized_data(0));
        normalized_data(2)      <= normalize(normalized_data(1));
    end procedure;

------------------------------------------------------------------------
    procedure request_normalizer
    (
        signal normalizer_object : out normalizer_record;
        float_input              : in float_record
    ) is
    begin
        normalizer_object.normalizer_is_requested(normalizer_object.normalizer_is_requested'low) <= '1';
        normalizer_object.normalized_data(normalizer_object.normalized_data'low) <= normalize(float_input);
        
    end request_normalizer;

------------------------------------------------------------------------
    function normalizer_is_ready
    (
        normalizer_object : normalizer_record
    )
    return boolean
    is
    begin
        return normalizer_object.normalizer_is_requested(normalizer_object.normalizer_is_requested'high) = '1';
    end normalizer_is_ready;

------------------------------------------------------------------------
end package body normalizer_pkg;
