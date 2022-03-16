library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_multiplier_pkg.all;

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
    function "+"
    (
        left, right : float_record
    )
    return float_record
    is
        variable res : unsigned(left.mantissa'high+1 downto 0);
        variable result_exponent : signed(left.exponent'high+1 downto 0) := resize(left.exponent, left.exponent'length+1);
    begin
        res := resize(left.mantissa, res'length) + resize(right.mantissa, res'length);

        -- if exponent needs to be incremented
        if res(res'left) = '1' then
            result_exponent := result_exponent + 1;
            res := shift_right(res,1);
        end if;

        return ("0",
                result_exponent(left.exponent'range),
                res(left.mantissa'range));
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
        return left.sign = right.sign          and
                left.exponent = right.exponent and
                left.mantissa = right.mantissa;
    end "=";
------------------------------------------------------------------------
end package body float_arithmetic_operations_pkg;
