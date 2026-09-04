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

    function init_float (
        sign : std_logic;
        exponent : integer range -2**t_exponent'high to 2**t_exponent'high-1;
        mantissa : t_mantissa)
    return float_record;

    type float_array is array (natural range <>) of float_record;

    constant zero    : float_record := ('0', (others => '0'), (others => '0'));
    constant pos_max : float_record := ('0', (exponent_high => '0', others => '1'), (others => '1'));

------------------------------------------------------------------------
    function get_signed_mantissa ( float_object : float_record)
        return signed;
------------------------------------------------------------------------
    function get_exponent ( float_number : float_record)
        return integer;
------------------------------------------------------------------------
    function get_mantissa ( float_number : float_record)
        return integer;
------------------------------------------------------------------------
    function get_sign ( float_number : float_record)
        return std_logic ;
------------------------------------------------------------------------

end package float_type_definitions_pkg;

package body float_type_definitions_pkg is

    function init_float
    (
        sign : std_logic;
        exponent : integer range -2**t_exponent'high to 2**t_exponent'high-1;
        mantissa : t_mantissa
    )
    return float_record
    is
    begin
        return (sign => sign,
                exponent => to_signed(exponent,t_exponent'length),
                mantissa => mantissa);
    end init_float;

    function get_signed_mantissa
    (
        float_object : float_record
    )
    return signed 
    is
        variable signed_mantissa : signed(mantissa_length+1 downto 0) := (others => '0');

    begin
        signed_mantissa(t_mantissa'range) := signed(float_object.mantissa);
        if float_object.sign = '1' then
            signed_mantissa := -signed_mantissa;
        end if;

        return signed_mantissa;

    end get_signed_mantissa;
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
        return to_integer(float_number.mantissa);
        
    end get_mantissa;

------------------------------------------------------------------------
    function get_sign
    (
        float_number : float_record
    )
    return std_logic 
    is
    begin
        return float_number.sign;
    end get_sign;
------------------------------------------------------------------------

end package body float_type_definitions_pkg;
