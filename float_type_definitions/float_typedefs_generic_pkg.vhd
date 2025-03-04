library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package float_typedefs_generic_pkg is
    generic(
            g_mantissa_length   : natural := 24
            ; g_exponent_length : natural := 8);

    constant mantissa_length : natural := g_mantissa_length;
    constant exponent_length : natural := g_exponent_length;

    constant mantissa_high : integer := g_mantissa_length - 1;
    constant exponent_high : integer := g_exponent_length - 1;

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

    constant zero : float_record := ('0', (others => '0'), (others => '0'));
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
    function "+" ( left, right : float_record)
        return float_record;
------------------------------------------------------------------------
    function "/" (
        left : float_record;
        constant right : integer)
    return float_record;
------------------------------------------------------------------------
    function "=" ( left, right : float_record)
        return boolean;
------------------------------------------------------------------------
    function "-" ( right : float_record)
        return float_record;

    function ">" ( left, right : float_record)
        return boolean;
------------------------------------------------------------------------
    function number_of_leading_zeroes (
        data : unsigned;
        max_shift : integer)
    return integer;
------------------------------------------------------------------------
    function to_std_logic ( float_number : float_record)
        return std_logic_vector;
------------------------------------------------------------------------

end package float_typedefs_generic_pkg;

package body float_typedefs_generic_pkg is

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
------------------------------------------------------------------------
    function ">"
    (
        left, right : float_record
    )
    return boolean
    is
        variable retval : boolean := false;
    begin

        retval := false;
        if left.exponent > right.exponent then
            retval := true;
        end if;

        if left.exponent = right.exponent then
            if left.mantissa > right.mantissa then
                retval := true;
            end if;
        end if;

        if ((left.sign = '1') and (right.sign = '0')) then
            retval := false;
        end if;

        if ((left.sign = '0') and (right.sign = '1')) then
            retval := true;
        end if;

        if ((left.sign = '1') and (right.sign = '1')) then
            retval := not retval;
        end if;

        return retval;

    end ">";
------------------------------------------------------------------------
    function "+"
    (
        left, right : float_record
    )
    return float_record
    is
        variable signed_left_mantissa, signed_right_mantissa : signed(t_mantissa'high+2 downto 0);
        variable res             : signed(t_mantissa'high+2 downto 0);
        variable abs_res         : signed(t_mantissa'high+2 downto 0);
        variable result_exponent : signed(t_exponent'high+1 downto 0) := resize(left.exponent, t_exponent'length+1);
        variable returned_value : float_record;
    begin
        signed_left_mantissa  := get_signed_mantissa(left);
        signed_right_mantissa := get_signed_mantissa(right);

        res := signed_left_mantissa + signed_right_mantissa;

        abs_res := abs(res);
        if abs_res(t_mantissa'high+1) = '1' then
            result_exponent := result_exponent + 1;
            abs_res := shift_right(abs_res,1);
        end if;


        returned_value := ( res(res'high), 
                result_exponent(t_exponent'range),
                unsigned(abs_res(t_mantissa'range)));

        return returned_value;
    end "+";
------------------------------------------------------------------------
    function "/"
    (
        left : float_record;
        constant right : integer
    )
    return float_record
    is
    begin
        assert right - 2 = 0 report "only division by 2 allowed in floats" severity failure;
        return (left.sign,
                left.exponent-1,
                left.mantissa);
    end "/";
------------------------------------------------------------------------
    function "="
    (
        left, right : float_record
    )
    return boolean
    is
    begin
        return left.sign      = right.sign     and
                left.exponent = right.exponent and
                left.mantissa = right.mantissa;
    end "=";
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
    function to_std_logic
    (
        float_number : float_record
    )
    return std_logic_vector 
    is
    begin
        return float_number.sign & std_logic_vector(float_number.exponent) & std_logic_vector(float_number.mantissa);
    end to_std_logic;
------------------------------------------------------------------------

end package body float_typedefs_generic_pkg;
