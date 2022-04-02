library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.float_word_length_pkg;

package float_type_definitions_pkg is

    constant mantissa_length : integer := float_word_length_pkg.mantissa_bits;
    constant exponent_length : integer := float_word_length_pkg.exponent_bits;

    constant mantissa_high : integer := mantissa_length - 1;
    constant exponent_high : integer := exponent_length - 1;

    subtype t_mantissa is unsigned(mantissa_high downto 0);
    subtype t_exponent is signed(exponent_high downto 0);

    type float_record is record
        sign     : std_logic;
        exponent : t_exponent;
        mantissa : t_mantissa;
    end record;

    type float_array is array (integer range <>) of float_record;

    constant zero : float_record := ('0', (others => '0'), (others => '0'));

------------------------------------------------------------------------
    function normalize ( float_number : float_record)
        return float_record;
------------------------------------------------------------------------
    function denormalize_float (
        right           : float_record;
        set_exponent_to : integer)
    return float_record;
------------------------------------------------------------------------
    function "-" ( right : float_record)
        return float_record;

------------------------------------------------------------------------
    function number_of_leading_zeroes (
        data : unsigned;
        max_shift : integer)
    return integer;
------------------------------------------------------------------------
    function normalize
    (
        float_number : float_record;
        max_shift : integer
    )
    return float_record;
------------------------------------------------------------------------
    function denormalize_float (
        right           : float_record;
        set_exponent_to : integer;
        max_shift       : integer)
    return float_record;
------------------------------------------------------------------------
    function get_exponent ( float_number : float_record)
        return integer;
------------------------------------------------------------------------
    function get_mantissa ( float_number : float_record)
        return integer;
------------------------------------------------------------------------
end package float_type_definitions_pkg;

package body float_type_definitions_pkg is

------------------------------------------------------------------------
    function number_of_leading_zeroes
    (
        data : std_logic_vector;
        max_shift : integer
    )
    return integer 
    is
        variable number_of_zeroes : integer := 0;
    begin
        for i in data'high - max_shift to data'high loop
            if data(i) = '0' then
                number_of_zeroes := number_of_zeroes + 1;
            else
                number_of_zeroes := 0;
            end if;
        end loop;

        return number_of_zeroes;
        
    end number_of_leading_zeroes;

------------------------------------------------------------------------
    function number_of_leading_zeroes
    (
        data : unsigned;
        max_shift : integer
    )
    return integer 
    is
    begin

        return number_of_leading_zeroes(std_logic_vector(data), max_shift);
        
    end number_of_leading_zeroes;

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

------------------------------------------------------------------------
    function normalize
    (
        float_number : float_record
    )
    return float_record
    is
        variable number_of_zeroes : natural := 0;
    begin

        return normalize(float_number, mantissa_high);
    end normalize;
------------------------------------------------------------------------
    function denormalize_float
    (
        right           : float_record;
        set_exponent_to : integer;
        max_shift       : integer
    )
    return float_record
    is
        variable float : float_record := zero;
    begin
        float := (right.sign,
                  exponent => to_signed(set_exponent_to, exponent_length),
                  mantissa => shift_right(right.mantissa,to_integer(set_exponent_to - right.exponent)));

        return float;
        
    end denormalize_float;
------------------------------------------------------------------------
    function denormalize_float
    (
        right           : float_record;
        set_exponent_to : integer
    )
    return float_record
    is
    begin

        return denormalize_float(right, set_exponent_to, mantissa_length);
        
    end denormalize_float;
------------------------------------------------------------------------
    function "-"
    (
        right : float_record
    )
    return float_record
    is
        variable returned_float : float_record;
    begin
         returned_float := (sign     => not right.sign,
                            exponent => right.exponent,
                            mantissa => right.mantissa);
        return returned_float;
    end "-";
------------------------------------------------------------------------
    function get_exponent
    (
        float_number : float_record
    )
    return integer
    is
    begin
        return to_integer(float_number.exponent);
        
    end get_exponent;

------------------------------------------------------------------------
    function get_mantissa
    (
        float_number : float_record
    )
    return integer
    is
    begin
        return to_integer(float_number.exponent);
        
    end get_mantissa;

------------------------------------------------------------------------
end package body float_type_definitions_pkg;
