library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use ieee.float_pkg.all;

package normalizer_pkg is
------------------------------------------------------------------------

    type float_array is array (natural range <>) of float32;

    type normalizer_record is record
        normalizer_is_requested : std_logic_vector
        normalized_data         : float_array;
    end record;

    -- constant init_normalizer : normalizer_record := ((others => '0'), (others => zero));
------------------------------------------------------------------------
    procedure create_normalizer (
        signal self : inout normalizer_record);
------------------------------------------------------------------------
    procedure request_normalizer (
        signal self : out normalizer_record;
        float_input : in float32);
------------------------------------------------------------------------
    function normalizer_is_ready (self : normalizer_record)
        return boolean;
------------------------------------------------------------------------
    function get_normalizer_result ( self : normalizer_record)
        return float32;
------------------------------------------------------------------------
    procedure to_float (
        signal self : out normalizer_record;
        int_input   : in integer;
        radix       : in integer);
------------------------------------------------------------------------
    function normalize
    (
        float_number : float32;
        max_shift    : integer
    )
    return float32;

    function normalize ( float_number : float32)
        return float32;
------------------------------------------------------------------------
    procedure convert_integer_to_float
    (
        signal self : out normalizer_record;
        number_to_be_converted : in integer;
        radix_of_converted_number : in integer);
------------------------------------------------------------------------
end package normalizer_pkg;

package body normalizer_pkg is
------------------------------------------------------------------------
    procedure create_normalizer 
    (
        signal self : inout normalizer_record
    ) 
    is
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
        float_input              : in float32
    ) is
    begin
        self.normalizer_is_requested(self.normalizer_is_requested'low) <= '1';
        self.normalized_data(self.normalized_data'low) <= float_input;
        
    end request_normalizer;

    procedure to_float
    (
        signal self : out normalizer_record;
        int_input                : in integer;
        radix                    : in integer
    ) is
        variable float_to_be_scaled : float32;
        variable float_sign : std_logic;
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
    return float32
    is
    begin
        return self.normalized_data(self.normalized_data'high);
    end get_normalizer_result;
------------------------------------------------------------------------
    function normalize
    (
        float_number : float32;
        max_shift : integer
    )
    return float32
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
        float_number : float32
    )
    return float32
    is
        variable number_of_zeroes : natural := 0;
    begin

        return normalize(float_number => float_number, max_shift => mantissa_high);
    end normalize;
------------------------------------------------------------------------
    procedure convert_integer_to_float
    (
        signal self : out normalizer_record;
        number_to_be_converted : in integer;
        radix_of_converted_number : in integer
    ) is
    begin
        to_float(self, number_to_be_converted, radix_of_converted_number);
        
    end convert_integer_to_float;

--------------------------------------------------
end package body normalizer_pkg;
