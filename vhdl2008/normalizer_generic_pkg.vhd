library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_typedefs_generic_pkg.all;

package normalizer_generic_pkg is
------------------------------------------------------------------------
    type normalizer_record is record
        normalizer_is_requested : std_logic_vector;
        normalized_data         : float_array;
    end record;

------------------------------------------------------------------------
    procedure create_normalizer (
        signal self : inout normalizer_record);
------------------------------------------------------------------------
    procedure request_normalizer (
        signal self : out normalizer_record;
        float_input : in float_record);
------------------------------------------------------------------------
    function normalizer_is_ready (self : normalizer_record)
        return boolean;
------------------------------------------------------------------------
    function get_normalizer_result ( self : normalizer_record)
        return float_record;
------------------------------------------------------------------------
    procedure to_float (
        signal self : out normalizer_record;
        int_input   : in integer;
        radix       : in integer
        ;ref        : in float_record);
------------------------------------------------------------------------
    function normalize
    (
        float_number : float_record;
        max_shift    : integer
    )
    return float_record;

    function normalize ( float_number : float_record)
        return float_record;
------------------------------------------------------------------------
    procedure convert_integer_to_float (
        signal self : out normalizer_record
        ;number_to_be_converted : in integer
        ;radix_of_converted_number : in integer
        ;ref : in float_record);
------------------------------------------------------------------------
end package normalizer_generic_pkg;

package body normalizer_generic_pkg is
------------------------------------------------------------------------
    procedure create_normalizer 
    (
        signal self : inout normalizer_record
    ) 
    is
        constant number_of_normalizer_pipeline_stages : natural := self.normalized_data'high;
        constant mantissa_high : natural := self.normalized_data(0).mantissa'high;
    begin

        self.normalizer_is_requested(0) <= '0';
        for i in 1 to number_of_normalizer_pipeline_stages loop
            self.normalizer_is_requested(i) <= self.normalizer_is_requested(i-1);
            self.normalized_data(i)         <= normalize(self.normalized_data(i-1), mantissa_high/number_of_normalizer_pipeline_stages);
        end loop;
    end procedure;

------------------------------------------------------------------------
    procedure request_normalizer
    (
        signal self : out normalizer_record;
        float_input              : in float_record
    ) is
    begin
        self.normalizer_is_requested(self.normalizer_is_requested'low) <= '1';
        self.normalized_data(self.normalized_data'low) <= float_input;
        
    end request_normalizer;

    procedure to_float
    (
        signal self : out normalizer_record
        ;int_input  : in integer
        ;radix      : in integer
        ;ref        : in float_record
    ) is
        variable float_to_be_scaled : ref'subtype;
        variable float_sign : std_logic;
        constant mantissa_length : natural := self.normalized_data(0).mantissa'length;
        constant exponent_length : natural := self.normalized_data(0).exponent'length;
    begin
        if int_input < 0 then
            float_sign := '1';
        else
            float_sign := '0';
        end if;
        float_to_be_scaled := (sign => float_sign,
            exponent => to_signed(mantissa_length - radix, exponent_length), 
            mantissa => to_unsigned(abs(int_input), mantissa_length));

        self.normalizer_is_requested(self.normalizer_is_requested'low) <= '1';
        self.normalized_data(self.normalized_data'low) <= float_to_be_scaled;
        
    end to_float;

------------------------------------------------------------------------
    function normalizer_is_ready
    (
        self : normalizer_record
    )
    return boolean
    is
    begin
        return self.normalizer_is_requested(self.normalizer_is_requested'high) = '1';
    end normalizer_is_ready;

------------------------------------------------------------------------
    function get_normalizer_result
    (
        self : normalizer_record
    )
    return float_record
    is
    begin
        return self.normalized_data(self.normalized_data'high);
    end get_normalizer_result;
------------------------------------------------------------------------
    function normalize
    (
        float_number : float_record;
        max_shift : integer
    )
    return float_record
    is
        variable number_of_zeroes : natural := 0;

    begin
        number_of_zeroes := number_of_leading_zeroes(float_number.mantissa, max_shift);

        return (sign     => float_number.sign,
                exponent => float_number.exponent - number_of_zeroes,
                mantissa => shift_left(float_number.mantissa, number_of_zeroes));
    end normalize;

----------

    function normalize
    (
        float_number : float_record
    )
    return float_record
    is
        variable number_of_zeroes : natural := 0;
        constant mantissa_high : natural := float_number.mantissa'high;
    begin

        return normalize(float_number => float_number, max_shift => mantissa_high);
    end normalize;
------------------------------------------------------------------------
    procedure convert_integer_to_float
    (
        signal self : out normalizer_record
        ;number_to_be_converted : in integer
        ;radix_of_converted_number : in integer
        ;ref : in float_record
    ) is
    begin
        to_float(self, number_to_be_converted, radix_of_converted_number, ref);
        
    end convert_integer_to_float;

--------------------------------------------------
end package body normalizer_generic_pkg;
