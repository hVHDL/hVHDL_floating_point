library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_multiplier_pkg.all;

package float_arithmetic_operations_pkg is

------------------------------------------------------------------------
    function denormalize_float (
        right           : float_record;
        set_exponent_to : integer)
    return float_record;
------------------------------------------------------------------------
    function "+" ( left, right : float_record)
        return float_record;
------------------------------------------------------------------------

end package float_arithmetic_operations_pkg;


package body float_arithmetic_operations_pkg is

------------------------------------------------------------------------
    function denormalize_float
    (
        right           : float_record;
        set_exponent_to : integer
    )
    return float_record
    is
        variable float : float_record := zero;
    begin
        if set_exponent_to - right.exponent > 0 then
            float := ("0",
                      exponent => to_signed(set_exponent_to, right.exponent'length),
                      mantissa => shift_right(right.mantissa,to_integer(set_exponent_to - right.exponent) ));
        else
            float := ("0",
                      exponent => to_signed(set_exponent_to, right.exponent'length),
                      mantissa => (others => '0'));
        end if;

        return float;
        
    end denormalize_float;
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
end package body float_arithmetic_operations_pkg;

