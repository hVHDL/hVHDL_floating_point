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
    function to_float ( float : std_logic_vector)
        return float_record ;
------------------------------------------------------------------------
    function to_std_logic_vector ( float : float_record)
        return std_logic_vector;
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

        return work.normalizer_pkg.normalize((sign   => get_sign(real_number),
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
        variable mantissa : real := 0.0;
        variable sign     : real := 0.0;
        variable exponent : real := 0.0;
    begin

        sign     := get_sign(float_number);
        mantissa := real(to_integer(float_number.mantissa))/2.0**(mantissa_length);
        exponent := (2.0**real(to_integer(float_number.exponent)));

        return sign * exponent * mantissa;
        
    end to_real;
------------------------------------------------------------------------
    function to_float
    (
        float : std_logic_vector
    )
    return float_record 
    is
        variable retval : float_record;
    begin
        retval.sign     := float(float'left);
        retval.exponent := signed(float(float'left-1 downto float'left-1-exponent_high));
        retval.mantissa := unsigned(float(float'left-exponent_high-2 downto 0));

        return retval;
    end to_float;
------------------------------------------------------------------------
    function to_std_logic_vector
    (
        float : float_record
    )
    return std_logic_vector 
    is
        variable retval : std_logic_vector(mantissa_high+exponent_high+2 downto 0);
    begin
        retval  := float.sign & std_logic_vector(float.exponent) & std_logic_vector(float.mantissa);

        return retval;

    end to_std_logic_vector;
------------------------------------------------------------------------

end package body float_to_real_conversions_pkg;
