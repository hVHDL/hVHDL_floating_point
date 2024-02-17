library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;

package float_multiplier_pkg is
------------------------------------------------------------------------
    constant float_multiplier_pipeline_depth : natural := 3;
------------------------------------------------------------------------
    type float_multiplier_record is record

        left   : float_record;
        right  : float_record;
        result : float_record;

        sign                           : std_logic;
        exponent                       : t_exponent;
        mantissa_multiplication_result : unsigned(mantissa_high*2+1 downto 0);
        shift_register                 : std_logic_vector(float_multiplier_pipeline_depth-1 downto 0);
    end record;

    constant init_float_multiplier : float_multiplier_record := (zero, zero, zero, '0', (others => '0'),(others => '0'), (others => '0'));
------------------------------------------------------------------------
    procedure create_float_multiplier (
        signal self : inout float_multiplier_record);
------------------------------------------------------------------------
    procedure request_float_multiplier (
        signal self : out float_multiplier_record;
        left, right : float_record);
------------------------------------------------------------------------
    function float_multiplier_is_ready (self : float_multiplier_record)
        return boolean;
------------------------------------------------------------------------
    function get_multiplier_result ( self : float_multiplier_record)
        return float_record;
------------------------------------------------------------------------
    function "*" ( left, right : float_record)
        return float_record;
------------------------------------------------------------------------
    function float_multiplier_is_busy ( self : float_multiplier_record)
        return boolean;
------------------------------------------------------------------------
end package float_multiplier_pkg;

package body float_multiplier_pkg is
------------------------------------------------------------------------
    function "*"
    (
        left, right : float_record
    ) return float_record
    is
        variable result : float_record := zero;
        variable raw_result : unsigned(mantissa_high*2+1 downto 0) := (others => '0');
    begin

        result.sign     := left.sign xor right.sign;
        result.exponent := left.exponent + right.exponent;
        raw_result      := left.mantissa * right.mantissa;
        if raw_result(mantissa_high*2+1) = '1' then
            result.mantissa := raw_result(mantissa_high*2+1 downto mantissa_high+1);
        else
            result.mantissa := raw_result(mantissa_high*2 downto mantissa_high);
        end if;
        return result;
        
    end function;

------------------------------------------------------------------------
    procedure create_float_multiplier 
    (
        signal self : inout float_multiplier_record
    ) 
    is
    begin

        self.shift_register                 <= self.shift_register(self.shift_register'left-1 downto 0) & '0';
        self.sign                           <= self.left.sign xor self.right.sign;
        self.exponent                       <= self.left.exponent + self.right.exponent;
        self.mantissa_multiplication_result <= self.left.mantissa * self.right.mantissa;

        if self.mantissa_multiplication_result(mantissa_high*2+1) = '1' then
            self.result <= (
                               sign     => self.sign,
                               exponent => self.exponent,
                               mantissa => self.mantissa_multiplication_result(mantissa_high*2+1 downto mantissa_high+1)
                           );
        else
            self.result <= (
                               sign     => self.sign,
                               exponent => self.exponent - 1,
                               mantissa => self.mantissa_multiplication_result(mantissa_high*2 downto mantissa_high)
                           );
        end if;

    end procedure;

------------------------------------------------------------------------
    procedure request_float_multiplier
    (
        signal self : out float_multiplier_record;
        left, right : float_record
    ) is
    begin
        self.shift_register(0) <= '1';
        self.left <= left;
        self.right <= right;
        
    end request_float_multiplier;

------------------------------------------------------------------------
    function float_multiplier_is_ready
    (
        self : float_multiplier_record
    )
    return boolean
    is
    begin
        return self.shift_register(self.shift_register'left) = '1';
    end float_multiplier_is_ready;

------------------------------------------------------------------------
    function get_multiplier_result
    (
        self : float_multiplier_record
    )
    return float_record
    is
    begin
        return self.result;
    end get_multiplier_result;
------------------------------------------------------------------------
    function float_multiplier_is_busy
    (
        self : float_multiplier_record
    )
    return boolean
    is
    begin
        return to_integer(signed(self.shift_register)) = 0;
    end float_multiplier_is_busy;
------------------------------------------------------------------------
end package body float_multiplier_pkg;
