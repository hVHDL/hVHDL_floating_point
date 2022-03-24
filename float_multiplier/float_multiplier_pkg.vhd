library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;

package float_multiplier_pkg is
------------------------------------------------------------------------
    type float_multiplier_record is record

        left   : float_record;
        right  : float_record;
        result : float_record;

        sign                           : std_logic;
        exponent                       : t_exponent;
        mantissa_multiplication_result : unsigned(mantissa_high*2+1 downto 0);
        shift_register                 : std_logic_vector(2 downto 0);
    end record;

    constant init_float_multiplier : float_multiplier_record := (zero, zero, zero, '0', (others => '0'),(others => '0'), (others => '0'));
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
    function float_multiplier_is_busy ( float_multiplier_object : float_multiplier_record)
        return boolean;
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

        alias shift_register                 is  float_multiplier_object.shift_register;
        alias mantissa_multiplication_result is  float_multiplier_object.mantissa_multiplication_result;
        alias left                           is  float_multiplier_object.left;
        alias right                          is  float_multiplier_object.right;
        alias result                         is  float_multiplier_object.result;
        alias sign                           is  float_multiplier_object.sign;
        alias exponent                       is  float_multiplier_object.exponent;

    begin

        shift_register                 <= shift_register(shift_register'left-1 downto 0) & '0';
        sign                           <= left.sign xor right.sign;
        exponent                       <= left.exponent + right.exponent;
        mantissa_multiplication_result <= left.mantissa * right.mantissa;

        result <= normalize((sign       => sign,
                               exponent => exponent,
                               mantissa => (mantissa_multiplication_result(mantissa_high*2+1 downto mantissa_high+1))
                              ));

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
        return float_multiplier_object.result;
    end get_multiplier_result;
------------------------------------------------------------------------
    function float_multiplier_is_busy
    (
        float_multiplier_object : float_multiplier_record
    )
    return boolean
    is
    begin
        return to_integer(signed(float_multiplier_object.shift_register)) = 0;
    end float_multiplier_is_busy;
------------------------------------------------------------------------
end package body float_multiplier_pkg;
