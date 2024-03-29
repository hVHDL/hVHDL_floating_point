library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.normalizer_pkg.all;
    use work.denormalizer_pkg.all;

package float_to_integer_converter_pkg is

    type float_to_integer_converter_record is record
        normalizer : normalizer_record;
        denormalizer : denormalizer_record;
    end record;

    constant init_float_to_integer_converter : float_to_integer_converter_record := (init_normalizer, init_denormalizer);
------------------------------------------------------------------------
    procedure create_float_to_integer_converter (
        signal self : inout float_to_integer_converter_record);
------------------------------------------------------------------------
    procedure convert_float_to_integer (
        signal self : out float_to_integer_converter_record;
        number_to_be_converted : float_record;
        desired_radix : in integer);
------------------------------------------------------------------------
    function float_to_int_conversion_is_ready ( self : float_to_integer_converter_record)
        return boolean;
--------------------------------------------------
    function get_converted_integer ( self : float_to_integer_converter_record)
        return integer;
------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure convert_integer_to_float (
        signal self : out float_to_integer_converter_record;
        number_to_be_converted : in integer;
        radix_of_converted_number : in integer);
--------------------------------------------------
    function int_to_float_conversion_is_ready ( self : float_to_integer_converter_record)
        return boolean;
--------------------------------------------------
    function get_converted_float ( self : float_to_integer_converter_record)
        return float_record;
------------------------------------------------------------------------
end package float_to_integer_converter_pkg;

package body float_to_integer_converter_pkg is

------------------------------------------------------------------------
    procedure create_float_to_integer_converter
    (
        signal self : inout float_to_integer_converter_record
    ) is
    begin
        create_normalizer(self.normalizer);
        create_denormalizer(self.denormalizer);
    end create_float_to_integer_converter;

------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure convert_float_to_integer
    (
        signal self : out float_to_integer_converter_record;
        number_to_be_converted : float_record;
        desired_radix : in integer
    ) is
    begin
        request_scaling(self.denormalizer, number_to_be_converted, desired_radix);
        
    end convert_float_to_integer;

--------------------------------------------------
    function float_to_int_conversion_is_ready
    (
        self : float_to_integer_converter_record
    )
    return boolean
    is
    begin
        return denormalizer_is_ready(self.denormalizer);
    end float_to_int_conversion_is_ready;

--------------------------------------------------
    function get_converted_integer
    (
        self : float_to_integer_converter_record
    )
    return integer
    is
    begin
        return get_integer(self.denormalizer);
    end get_converted_integer;

------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure convert_integer_to_float
    (
        signal self : out float_to_integer_converter_record;
        number_to_be_converted : in integer;
        radix_of_converted_number : in integer
    ) is
    begin
        to_float(self.normalizer, number_to_be_converted, radix_of_converted_number);
        
    end convert_integer_to_float;

--------------------------------------------------
    function int_to_float_conversion_is_ready
    (
        self : float_to_integer_converter_record
    )
    return boolean
    is
    begin
        return normalizer_is_ready(self.normalizer);
    end int_to_float_conversion_is_ready;

--------------------------------------------------
    function get_converted_float
    (
        self : float_to_integer_converter_record
    )
    return float_record
    is
    begin
        return get_normalizer_result(self.normalizer);
    end get_converted_float;
------------------------------------------------------------------------
end package body float_to_integer_converter_pkg;
