library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;

package float_multiplier_pkg is
------------------------------------------------------------------------
    type exponent_array is array (integer range <>) of t_exponent;
------------------------------------------------------------------------
    type float_multiplier_record is record

        left   : float_record;
        right  : float_record;

        shift_register    : std_logic_vector(1 downto 0);
        sign_pipeline     : signed(1 downto 0);
        exponent_pipeline : exponent_array(1 downto 0);

        mantissa_multiplicaion_result : unsigned(mantissa_length*2-1 downto 0);
    end record;

    constant init_float_multiplier : float_multiplier_record := (zero, zero, (others => '0'), (("0"),("0")), ((others => '0'), (others => '0')), (others => '0'));
------------------------------------------------------------------------
    procedure create_float_multiplier (
        signal float_multiplier_object : inout float_multiplier_record);
------------------------------------------------------------------------
    procedure request_float_multiplier (
        signal float_multiplier_object : out float_multiplier_record;
        left, right : float_record);
------------------------------------------------------------------------
    function float_multiplier_is_ready (float_multiplier_object : float_multiplier_record)
        return boolean;
------------------------------------------------------------------------
    function get_multiplier_result ( float_multiplier_object : float_multiplier_record)
        return float_record;
------------------------------------------------------------------------
    function mult ( left,right : natural)
        return unsigned;
------------------------------------------------------------------------
    function "*" ( left, right : float_record)
        return float_record;
------------------------------------------------------------------------
end package float_multiplier_pkg;

package body float_multiplier_pkg is
------------------------------------------------------------------------
    function mult
    (
        left,right : natural
    )
    return unsigned 
    is
        variable result : unsigned(mantissa_length*2+1 downto 0) := (others => '0');

    begin
        result := to_unsigned(left, mantissa_length+1) * to_unsigned(right,mantissa_length+1);
        
        return result(mantissa_high*2+1 downto mantissa_high+1);
    end mult;

------------------------------------------------------------------------
    function "*"
    (
        left, right : float_record
    ) return float_record
    is
        variable result : float_record := zero;
    begin

        result.sign     := left.sign xor right.sign;
        result.exponent := left.exponent + right.exponent;
        result.mantissa := mult(to_integer(left.mantissa) , to_integer(right.mantissa));
        return result;
        
    end function;
------------------------------------------------------------------------

    procedure create_float_multiplier 
    (
        signal float_multiplier_object : inout float_multiplier_record
    ) 
    is

        alias shift_register                is float_multiplier_object.shift_register;
        alias mantissa_multiplicaion_result is float_multiplier_object.mantissa_multiplicaion_result;
        alias left                          is float_multiplier_object.left;
        alias right                         is float_multiplier_object.right;
    begin

        shift_register <= shift_register(shift_register'left-1 downto 0) & '0';

        -- result.sign                   <= left.sign xor right.sign;
        -- result.exponent               <= left.exponent + right.exponent;
        -- mantissa_multiplicaion_result <= left.mantissa * right.mantissa;

        -- result.mantissa <= mantissa_multiplicaion_result(mantissa_high*2+1 downto mantissa_high+1);


    end procedure;

------------------------------------------------------------------------
    procedure request_float_multiplier
    (
        signal float_multiplier_object : out float_multiplier_record;
        left, right : float_record
    ) is
    begin
        float_multiplier_object.shift_register(0) <= '1';
        float_multiplier_object.left <= left;
        float_multiplier_object.right <= right;
        
    end request_float_multiplier;

------------------------------------------------------------------------
    function float_multiplier_is_ready
    (
        float_multiplier_object : float_multiplier_record
    )
    return boolean
    is
    begin
        return float_multiplier_object.shift_register(float_multiplier_object.shift_register'left) = '1';
    end float_multiplier_is_ready;

------------------------------------------------------------------------
    function get_multiplier_result
    (
        float_multiplier_object : float_multiplier_record
    )
    return float_record
    is
    begin
        return zero;
    end get_multiplier_result;
------------------------------------------------------------------------
end package body float_multiplier_pkg;
