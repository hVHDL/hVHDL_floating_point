library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package float_typedefs_generic_pkg is

    subtype t_mantissa is unsigned;
    subtype t_exponent is signed;

    type float_record is record
        sign     : std_logic;
        exponent : signed;
        mantissa : unsigned;
    end record;

    type float_array is array (natural range <>) of float_record;

    -- common instantiations
    constant hfloat32_ref : float_record :=(
        sign => '0'
        ,exponent => (7 downto 0 => x"00")
        ,mantissa => (22 downto 0 => x"000000"));

    constant hfloat40_ref : float_record :=(
        sign => '0'
        ,exponent => (7 downto 0 => x"00")
        ,mantissa => (30 downto 0 => x"000000"));

------------------------------------------------------------------------
    function get_signed_mantissa ( hfloat : float_record)
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
    function to_float (
        slv       : std_logic_vector
        ;floatref : float_record)
    return float_record;
------------------------------------------------------------------------

end package float_typedefs_generic_pkg;

package body float_typedefs_generic_pkg is

    function get_signed_mantissa
    (
        hfloat : float_record
    )
    return signed 
    is
        constant mantissa_length : natural := hfloat.mantissa'length;
        variable signed_mantissa : signed(mantissa_length+1 downto 0) := (others => '0');

    begin
        signed_mantissa(hfloat.mantissa'range) := signed(hfloat.mantissa);
        if hfloat.sign = '1' then
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
        subtype t_mantissa is left.mantissa'subtype;
        variable signed_left_mantissa, signed_right_mantissa : signed(t_mantissa'high+2 downto 0);
        variable res             : signed(left.mantissa'high+2 downto 0);
        variable abs_res         : signed(left.mantissa'high+2 downto 0);
        variable result_exponent : signed(left.exponent'high+1 downto 0)  := resize(left.exponent, left.exponent'length+1);
        variable returned_value  : left'subtype;
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
                result_exponent(left.exponent'range),
                unsigned(abs_res(left.mantissa'range)));

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
        variable returned_float : right'subtype;
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
        constant slvref : std_logic_vector := float_number.sign & std_logic_vector(float_number.exponent) & std_logic_vector(float_number.mantissa);
        constant slvref1 : std_logic_vector(slvref'high downto 0) := float_number.sign & std_logic_vector(float_number.exponent) & std_logic_vector(float_number.mantissa);
    begin
        return slvref1;
    end to_std_logic;
------------------------------------------------------------------------
    function to_float
    (
        slv : std_logic_vector
        ;floatref : float_record
    )
    return float_record 
    is
        variable retval : floatref'subtype := (sign => '0', exponent => (floatref.exponent'range => '0'), mantissa => (floatref.mantissa'range => '0'));
    begin
        retval.sign     := slv(slv'left);
        retval.exponent := signed(slv(slv'left-1 downto slv'left-1-retval.exponent'high));
        retval.mantissa := unsigned(slv(slv'left-1-retval.exponent'high-1 downto 0));

        return retval;
    end to_float;
------------------------------------------------------------------------

end package body float_typedefs_generic_pkg;
