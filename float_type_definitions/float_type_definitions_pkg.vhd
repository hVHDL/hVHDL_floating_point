library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package float_type_definitions_pkg is

    constant mantissa_high : integer := 22;
    constant exponent_high : integer := 7;

    constant mantissa_length : integer := mantissa_high + 1;
    constant exponent_length : integer := exponent_high + 1;

    subtype t_mantissa is unsigned(mantissa_high downto 0);
    subtype t_exponent is signed(exponent_high downto 0);

    type float_record is record
        sign : signed(0 downto 0);
        exponent : t_exponent;
        mantissa : t_mantissa;
    end record;

    type float_array is array (integer range <>) of float_record;

    constant zero : float_record := ((others => '0'), (others => '0'), (others => '0'));

------------------------------------------------------------------------
    function normalize ( float_number : float_record)
        return float_record;
------------------------------------------------------------------------
    function denormalize_float (
        right           : float_record;
        set_exponent_to : integer)
    return float_record;
------------------------------------------------------------------------
    function number_of_leading_zeroes ( data : std_logic_vector )
        return integer ;
------------------------------------------------------------------------

end package float_type_definitions_pkg;

package body float_type_definitions_pkg is

------------------------------------------------------------------------
    function number_of_leading_zeroes
    (
        data : std_logic_vector 
    )
    return integer 
    is
        variable number_of_zeroes : integer := 0;
    begin
        for i in data'range loop
            if data(data'high-i) = '0' then
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
        data : unsigned 
    )
    return integer 
    is
    begin

        return number_of_leading_zeroes(std_logic_vector(data));
        
    end number_of_leading_zeroes;
------------------------------------------------------------------------
    function normalize
    (
        float_number : float_record
    )
    return float_record
    is
        variable number_of_zeroes : natural := 0;
    begin
        number_of_zeroes := number_of_leading_zeroes(float_number.mantissa);

        return (sign     => float_number.sign,
                exponent => float_number.exponent - number_of_zeroes,
                mantissa => shift_left(float_number.mantissa, number_of_zeroes));
    end normalize;
------------------------------------------------------------------------
    function denormalize_float
    (
        right           : float_record;
        set_exponent_to : integer
    )
    return float_record
    is
        variable float : float_record := zero;
    begin
        if set_exponent_to < right.exponent then
            float := ("0",
                      exponent => to_signed(set_exponent_to, exponent_length),
                      mantissa => shift_right(right.mantissa,to_integer(set_exponent_to - right.exponent) ));
        else
            float := ("0",
                      exponent => to_signed(set_exponent_to, exponent_length),
                      mantissa => right.mantissa);
        end if;

        return float;
        
    end denormalize_float;
end package body float_type_definitions_pkg;
