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
    function "-" ( right : float_record)
        return float_record;

------------------------------------------------------------------------
    function number_of_leading_zeroes (
        data : unsigned;
        max_shift : integer)
    return integer;
------------------------------------------------------------------------
    function to_std_logic ( float_number : float_record)
        return std_logic_vector;
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
end package body float_arithmetic_operations_pkg;
