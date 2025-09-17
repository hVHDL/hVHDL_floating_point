library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use ieee.float_pkg.float32;

package float_typedefs_generic_pkg is

    type hfloat_record is record
        sign     : std_logic;
        exponent : signed;
        mantissa : unsigned;
    end record;

    type float_array is array (natural range <>) of hfloat_record;
------------------------------------------------------------------------
    function to_hfloat (
        slv       : std_logic_vector
        ;floatref : hfloat_record)
    return hfloat_record;
------------------------------------------------------------------------
    function to_std_logic ( float_number : hfloat_record)
        return std_logic_vector;
------------------------------------------------------------------------
    function to_ieee_float32(a : hfloat_record) return float32;
--------
    function float32_to_hfloat (a : float32; hfloatref : hfloat_record) return hfloat_record;
------------------------------------------------------------------------

    -- common instantiations
    constant hfloat32_ref : hfloat_record :=(
        sign => '0'
        ,exponent => (7 downto 0 => x"00")
        ,mantissa => (22 downto 0 => (22 downto 0 => '0')));

    constant hfloat40_ref : hfloat_record :=(
        sign => '0'
        ,exponent => (7 downto 0 => x"00")
        ,mantissa => (30 downto 0 => (30 downto 0 => '0')));

    function "+" ( left, right : hfloat_record)
        return hfloat_record;
------------------------------------------------------------------------
    function "/" (
        left : hfloat_record;
        constant right : integer)
    return hfloat_record;
------------------------------------------------------------------------
    function "=" ( left, right : hfloat_record)
        return boolean;
------------------------------------------------------------------------
    function "-" ( right : hfloat_record)
        return hfloat_record;

    function ">" ( left, right : hfloat_record)
        return boolean;
------------------------------------------------------------------------
    function number_of_leading_zeroes (
        data : unsigned;
        max_shift : integer)
    return integer;
------------------------------------------------------------------------
------------------------------------------------------------------------
    function get_signed_mantissa ( hfloat : hfloat_record)
        return signed;
------------------------------------------------------------------------
    function get_exponent ( float_number : hfloat_record)
        return integer;
------------------------------------------------------------------------
    function get_mantissa ( float_number : hfloat_record)
        return integer;
------------------------------------------------------------------------
    function get_sign ( float_number : hfloat_record)
        return std_logic ;
------------------------------------------------------------------------

end package float_typedefs_generic_pkg;

package body float_typedefs_generic_pkg is

    function get_signed_mantissa
    (
        hfloat : hfloat_record
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
        float_number : hfloat_record
    )
    return integer
    is
    begin
        return to_integer(float_number.exponent);
        
    end get_exponent;

------------------------------------------------------------------------
    function get_mantissa
    (
        float_number : hfloat_record
    )
    return integer
    is
    begin
        return to_integer(float_number.mantissa);
        
    end get_mantissa;

------------------------------------------------------------------------
    function get_sign
    (
        float_number : hfloat_record
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
        left, right : hfloat_record
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
        left, right : hfloat_record
    )
    return hfloat_record
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
        left : hfloat_record;
        constant right : integer
    )
    return hfloat_record
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
        left, right : hfloat_record
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
        right : hfloat_record
    )
    return hfloat_record
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
        float_number : hfloat_record
    )
    return std_logic_vector 
    is
        constant slvref : std_logic_vector := float_number.sign & std_logic_vector(float_number.exponent) & std_logic_vector(float_number.mantissa);
        constant slvref1 : std_logic_vector(slvref'high downto 0) := float_number.sign & std_logic_vector(float_number.exponent) & std_logic_vector(float_number.mantissa);
    begin
        return slvref1;
    end to_std_logic;
------------------------------------------------------------------------
    function to_hfloat
    (
        slv : std_logic_vector
        ;floatref : hfloat_record
    )
    return hfloat_record 
    is
        variable retval : floatref'subtype := (sign => '0', exponent => (floatref.exponent'range => '0'), mantissa => (floatref.mantissa'range => '0'));
        constant c_slv : std_logic_vector(slv'high downto slv'low) := slv;
        constant slv_mantissa : std_logic_vector(c_slv'left-1-retval.exponent'high-1 downto 0) := c_slv(c_slv'left-1-retval.exponent'high-1 downto 0);
    begin
        retval.sign     := c_slv(c_slv'left);
        retval.exponent := signed(c_slv(c_slv'left-1 downto c_slv'left-1-retval.exponent'high));

        if retval.mantissa'length > slv_mantissa'length
        then
            for i in slv_mantissa'range loop
                retval.mantissa(retval.mantissa'high-slv_mantissa'high+ i) := slv_mantissa(i);
            end loop;
        else
            for i in retval.mantissa'range loop
                retval.mantissa(i) := slv_mantissa(slv_mantissa'high-retval.mantissa'high+i);
            end loop;
        end if;

        return retval;
    end to_hfloat;
------------------------------------------------------------------------
    function to_ieee_float32(a : hfloat_record) return float32 is
        variable retval : float32 := (others => '0');
        variable dingdong : a'subtype;
        variable exponent : signed(7 downto 0);
    begin
        dingdong :=(
        a.sign
        ,a.exponent+126
        ,shift_left(a.mantissa,1));

        retval(retval'left) := a.sign;
        exponent := resize(dingdong.exponent,8);

        for i in exponent'range loop
            retval(i) := exponent(i);
        end loop;

        for i in a.mantissa'range loop
            if i-a.mantissa'high - 1 >= retval'low then
                retval(i-dingdong.mantissa'high - 1) := dingdong.mantissa(i);
            end if;
        end loop;

        return retval;
    end to_ieee_float32;
--------------------------------------------------
    function float32_to_hfloat (a : float32; hfloatref : hfloat_record) return hfloat_record is
        variable retval : hfloatref'subtype := (
        sign => a(a'high)
        , exponent => signed(a(7 downto 0))-126
        ,mantissa => (others => '0'));
    begin
        for i in a(-1 downto -23)'range loop
            if retval.mantissa'high + i >= 0
            then
                retval.mantissa(retval.mantissa'high + i) := a(i);
            end if;
        end loop;

        retval.mantissa(retval.mantissa'high) := '1';

        return retval;

    end float32_to_hfloat;

end package body float_typedefs_generic_pkg;
