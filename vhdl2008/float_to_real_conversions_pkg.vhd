library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.float_typedefs_generic_pkg.all;
    use work.normalizer_generic_pkg.all;

package float_to_real_conversions_pkg is
    constant hfloat_zero : hfloat_record :=(sign => '0', exponent => (7 downto 0 => x"00"), mantissa => (23 downto 0 => x"000000"));
------------------------------------------------------------------------
    function to_hfloat (
        real_number : real
        ;exponent_length : natural
        ;mantissa_length : natural) return hfloat_record;
------------------------------------------------------------------------
    function to_hfloat_slv_generic
    generic( 
        exponent_length : natural
        ;word_length : natural
    )(
        real_number : real
    ) return std_logic_vector ;
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
    function to_hfloat_generic
    generic( 
        exponent_length : natural
        ;word_length : natural)
    (
        real_number : real
    )
    return hfloat_record;
------------------------------------------------------------------------
end package float_to_real_conversions_pkg;

package body float_to_real_conversions_pkg is


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
        ;exponent : natural := 8
    )
    return real
    is
    begin
        return (abs(number)/2.0**get_exponent(number, exponent));
    end get_mantissa;
------------------------------------------------------------------------
    function get_mantissa
    (
        number : real
        ;mantissa_length : natural
    )
    return unsigned
    is
        variable real_exp : real := 0.0;
        variable real_mantissa : real := 0.0;
        variable retval : unsigned(mantissa_length-1 downto 0);
    begin
        real_exp := get_exponent(number);
        if real_exp = 0.0
        then
            real_mantissa := abs(number)*2.0**mantissa_length;
        else
            real_mantissa := (abs(number) / 2.0**real_exp)*2.0**(mantissa_length-1);
        end if;

        for i in retval'range loop
            if real_mantissa >= 2.0**i then
                real_mantissa := real_mantissa - 2.0**i;
                retval(i) := '1';
            else
                retval(i) := '0';
            end if;
        end loop;

        return retval;
    end get_mantissa;
------------------------------------------------------------------------
    function to_hfloat
    (
        real_number : real
        ;exponent_length : natural
        ;mantissa_length : natural
    )
    return hfloat_record
    is

        constant hfloat_ref : hfloat_record := (
            sign => '0'
            ,exponent => (exponent_length-1 downto 0 => '0')
            ,mantissa => (mantissa_length-1 downto 0 => '0')
        );

        variable retval : hfloat_ref'subtype := hfloat_ref;

    begin

        retval := normalize((sign   => get_sign(real_number),
                        exponent => get_exponent(real_number),
                        mantissa => get_mantissa(real_number , mantissa_length)));

        if retval.mantissa = hfloat_ref.mantissa
        then
            retval := hfloat_ref;
        end if;

        return retval;
        
    end to_hfloat;

------------------------------------------------------------------------
    function to_hfloat_generic
    generic( 
        exponent_length : natural
        ;word_length : natural)
    (
        real_number : real
    )
    return hfloat_record 
    is
        constant mantissa_length : natural := word_length - exponent_length - 1;

    begin

        return normalize((sign   => get_sign(real_number),
                        exponent => get_exponent(real_number),
                        mantissa => get_mantissa(real_number , mantissa_length)));
        
    end to_hfloat_generic;

------------------------------------------------------------------------
    function to_hfloat_slv_generic
    generic( 
        exponent_length : natural
        ;word_length : natural)
    (
        real_number : real
    )
    return std_logic_vector 
    is
        constant mantissa_length : natural := word_length - exponent_length - 1;

        constant hfloat : hfloat_record := normalize(
                            (sign    => get_sign(real_number),
                            exponent => get_exponent(real_number),
                            mantissa => get_mantissa(real_number , mantissa_length)));

    begin

        return to_std_logic_vector(hfloat);

    end to_hfloat_slv_generic;
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
        function "*"(left : real; right : std_logic) return real is
            variable retval : real := 0.0;
        begin
            if right = '0'
            then
                retval := 0.0;
            else
                retval := left;
            end if;
            return retval;
        end function;

    begin

        if float_number.sign = '1' then
            sign := -1.0;
        else
            sign := 1.0;
        end if;

        for i in float_number.mantissa'range loop
            mantissa := mantissa + 2.0**(i)*float_number.mantissa(i)/ 2.0**(float_number.mantissa'length);
        end loop;

        -- mantissa := real(to_integer(float_number.mantissa))/2.0**(float_number.mantissa'length);
        exponent := (2.0**real(to_integer(float_number.exponent)));

        return sign * exponent * mantissa ;
        
    end to_real;
------------------------------------------------------------------------
    function to_hfloat
    (
        float : std_logic_vector
        ;ref : hfloat_record := hfloat_zero
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
    end to_hfloat;
------------------------------------------------------------------------

end package body float_to_real_conversions_pkg;
