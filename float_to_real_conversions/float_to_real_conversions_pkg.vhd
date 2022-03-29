library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;

package float_to_real_conversions_pkg is
------------------------------------------------------------------------
    function to_float ( real_number : real)
        return float_record;
------------------------------------------------------------------------
    function to_real ( float_number : float_record)
        return real;
------------------------------------------------------------------------
end package float_to_real_conversions_pkg;

package body float_to_real_conversions_pkg is

------------------------------------------------------------------------
    function get_exponent
    (
        number : real
    )
    return real
    is
    begin
        if number = 0.0 then
            return 0.0;
        else
            return floor(log2(abs(number)))+1.0;
        end if;
    end get_exponent;
------------------------------------------------------------------------
    function get_mantissa
    (
        number : real
    )
    return real
    is
    begin
        return (abs(number)/2**get_exponent(number));
    end get_mantissa;
------------------------------------------------------------------------
    function get_sign
    (
        number : float_record
    )
    return real
    is
        variable returned_real : real;
    begin
        if number.sign = '1' then
            returned_real := -1.0;
        else
            returned_real := 1.0;
        end if;

        return returned_real;
    end get_sign;

------------------------------------------------------------------------
    function get_mantissa
    (
        number : real
    )
    return unsigned
    is
    begin
        return to_unsigned(integer(get_mantissa(number) * 2.0**mantissa_length), mantissa_length);
    end get_mantissa;
------------------------------------------------------------------------
    function get_exponent
    (
        number : real
    )
    return t_exponent
    is
        variable result : real := 0.0;
    begin
        result := get_exponent(number);
        return to_signed(integer(result),exponent_length);
    end get_exponent;
------------------------------------------------------------------------
    function get_sign
    (
        number : real
    )
    return std_logic
    is
        variable result : std_logic;
    begin

        if number >= 0.0 then
            result := '0';
        else
            result := '1';
        end if;

        return result;
        
    end get_sign;
------------------------------------------------------------------------
    function get_data
    (
        int_number : integer;
        real_number : real
    )
    return signed 
    is
        variable returned_signed : t_exponent;
    begin
        if real_number >= 0.0 then 
            returned_signed := to_signed(int_number, exponent_length);
        else
            returned_signed := -to_signed(int_number, exponent_length);
        end if;

        return returned_signed;

    end get_data;
------------------------------------------------------------------------
    function to_float
    (
        real_number : real
    )
    return float_record
    is

    begin

        return (sign     => get_sign(real_number),
                exponent => get_exponent(real_number),
                mantissa => get_mantissa(real_number));
        
    end to_float;
------------------------------------------------------------------------
    function to_real
    (
        float_number : float_record
    )
    return real
    is
        variable mantissa : real;
        variable sign     : real;
        variable exponent : real;
    begin

        sign     := get_sign(float_number);
        mantissa := real(to_integer(float_number.mantissa))/2.0**(mantissa_length);
        exponent := (2.0**real(to_integer(float_number.exponent)));

        return sign * exponent * mantissa;
        
    end to_real;
------------------------------------------------------------------------
    function to_integer
    (
        float_number : float_record
    )
    return integer
    is
        variable result : integer;
    begin

        if float_number.sign = '1' then
            result := -to_integer(float_number.mantissa);
        else
            result := to_integer(float_number.mantissa);
        end if;

        return result;
    end to_integer;
------------------------------------------------------------------------
end package body float_to_real_conversions_pkg;
