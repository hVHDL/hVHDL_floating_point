library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;

package float_arithmetic_operations_pkg is

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
    function get_signed_mantissa ( float_object : float_record)
        return signed;
----------------------------------------------------------------------
end package float_arithmetic_operations_pkg;


package body float_arithmetic_operations_pkg is

------------------------------------------------------------------------
    function ">"
    (
        left, right : float_record
    )
    return float_record
    is
        variable returned_float : float_record;
    begin
        if left.sign > right.sign then
            returned_float := left;
        else
            -- add additional functions here
            returned_float := right;
        end if;

        return returned_float;

    end ">";
------------------------------------------------------------------------
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
end package body float_arithmetic_operations_pkg;
