library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.float_to_real_functions_pkg.all;

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
    function to_float
    (
        real_number : real
    )
    return float_record
    is

    begin

        return normalize((sign   => get_sign(real_number),
                        exponent => get_exponent(real_number),
                        mantissa => get_mantissa(real_number)));
        
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
end package body float_to_real_conversions_pkg;
