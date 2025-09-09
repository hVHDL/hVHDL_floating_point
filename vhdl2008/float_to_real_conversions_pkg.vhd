library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.float_typedefs_generic_pkg.all;
    use work.normalizer_generic_pkg.all;

package float_to_real_conversions_pkg is
    constant float_zero : hfloat_record :=(sign => '0', exponent => (7 downto 0 => x"00"), mantissa => (23 downto 0 => x"000000"));
------------------------------------------------------------------------
    function to_float (
        real_number : real
        ;exponent_length : natural
        ;mantissa_length : natural) return hfloat_record;
------------------------------------------------------------------------
    function to_real ( float_number : hfloat_record)
        return real;
------------------------------------------------------------------------
    function get_sign ( number : real)
        return std_logic;
------------------------------------------------------------------------
    function get_exponent ( number : real
        ;exponent_length : natural := 8)
        return real;
------------------------------------------------------------------------
    function get_exponent (
        number : real
        ;exponent_length : natural := 8) return signed;
------------------------------------------------------------------------
    function get_mantissa
    (
        number : real
        ;mantissa_length : natural
    )
    return unsigned;
------------------------------------------------------------------------
end package float_to_real_conversions_pkg;

package body float_to_real_conversions_pkg is


------------------------------------------------------------------------
    function get_exponent
    (
        number : real
        ;exponent_length : natural := 8
    )
    return real
    is
        variable retval : real;
    begin
        if number = 0.0 then
            retval := 0.0;
        else
            retval := floor(log2(abs(number)))+1.0;
        end if;
        if retval >= 2.0**(exponent_length-1)-1.0 then
            retval := 2.0**(exponent_length-1)-1.0;
        end if;

        return retval;
        
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
    function get_exponent
    (
        number : real
        ;exponent_length : natural := 8
    )
    return signed
    is
        variable result : real := 0.0;
    begin
        result := get_exponent(number, exponent_length);
        return to_signed(integer(result),exponent_length) + 1;
    end get_exponent;
------------------------------------------------------------------------
    function get_mantissa
    (
        number : real
    )
    return real
    is
    begin
        return (abs(number)/2.0**get_exponent(number, 8));
    end get_mantissa;
------------------------------------------------------------------------
    function get_mantissa
    (
        number : real
        ;mantissa_length : natural
    )
    return unsigned
    is
    begin
        return to_unsigned(integer(get_mantissa(number) * 2.0**(mantissa_length-1)), mantissa_length);
    end get_mantissa;
------------------------------------------------------------------------
    function to_float
    (
        real_number : real
        ;exponent_length : natural
        ;mantissa_length : natural
    )
    return hfloat_record
    is

    begin

        return normalize((sign   => get_sign(real_number),
                        exponent => get_exponent(real_number),
                        mantissa => get_mantissa(real_number , mantissa_length)));
        
    end to_float;
------------------------------------------------------------------------
    function to_real
    (
        float_number : hfloat_record
    )
    return real
    is
        variable mantissa : real := 0.0;
        variable sign     : real := 0.0;
        variable exponent : real := 0.0;
    begin

        if float_number.sign = '1' then
            sign := -1.0;
        else
            sign := 1.0;
        end if;
        mantissa := real(to_integer(float_number.mantissa))/2.0**(float_number.mantissa'length);
        exponent := (2.0**real(to_integer(float_number.exponent)));

        return sign * exponent * mantissa;
        
    end to_real;
------------------------------------------------------------------------
    function to_float
    (
        float : std_logic_vector
        ;ref : hfloat_record := float_zero
    )
    return hfloat_record 
    is
        variable retval : ref'subtype;
        constant exponent_high : natural := ref.exponent'high;
    begin
        retval.sign     := float(float'left);
        retval.exponent := signed(float(float'left-1 downto float'left-1-exponent_high));
        retval.mantissa := unsigned(float(float'left-exponent_high-2 downto 0));

        return retval;
    end to_float;
------------------------------------------------------------------------
    function to_std_logic_vector
    (
        float : hfloat_record
    )
    return std_logic_vector 
    is
        constant exponent_high : natural := float.exponent'high;
        constant mantissa_high : natural := float.mantissa'high;
        variable retval : std_logic_vector(mantissa_high+exponent_high+2 downto 0);
    begin
        retval  := float.sign & std_logic_vector(float.exponent) & std_logic_vector(float.mantissa);

        return retval;

    end to_std_logic_vector;
------------------------------------------------------------------------

end package body float_to_real_conversions_pkg;
