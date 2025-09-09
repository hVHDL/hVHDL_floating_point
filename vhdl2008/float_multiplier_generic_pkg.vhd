library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_typedefs_generic_pkg.all;

package float_multiplier_pkg is
------------------------------------------------------------------------
    constant float_multiplier_pipeline_depth : natural := 3;
------------------------------------------------------------------------
    type float_multiplier_record is record

        left                           : hfloat_record;
        right                          : hfloat_record;
        result                         : hfloat_record;
        sign                           : std_logic;
        exponent                       : signed;
        mantissa_multiplication_result : unsigned; -- (mantissa_high*2+1 downto 0);
        shift_register                 : std_logic_vector; --(float_multiplier_pipeline_depth-1 downto 0);
    end record;

    function multiplier_typeref(floatref : hfloat_record) 
        return float_multiplier_record;
------------------------------------------------------------------------
    procedure create_float_multiplier (
        signal self : inout float_multiplier_record);
------------------------------------------------------------------------
    procedure request_float_multiplier (
        signal self : out float_multiplier_record;
        left, right : hfloat_record);
------------------------------------------------------------------------
    function float_multiplier_is_ready (self : float_multiplier_record)
        return boolean;
------------------------------------------------------------------------
    function get_multiplier_result ( self : float_multiplier_record)
        return hfloat_record;
------------------------------------------------------------------------
    function "*" ( left, right : hfloat_record)
        return hfloat_record;
------------------------------------------------------------------------
    function float_multiplier_is_busy ( self : float_multiplier_record)
        return boolean;
------------------------------------------------------------------------
end package float_multiplier_pkg;

package body float_multiplier_pkg is
------------------------------------------------------------------------
    function multiplier_typeref(floatref : hfloat_record) return float_multiplier_record
    is
        constant zero : floatref'subtype := (sign => '0', mantissa => (others => '0'), exponent => (others => '0'));
        constant mpy  : unsigned(floatref.mantissa'high*2+1 downto 0) := (others => '0');
        constant shift_register : std_logic_vector(2 downto 0) := (others => '0');

        constant init_multiplier : float_multiplier_record := (
            left      => zero
            ,right    => zero
            ,result   => zero
            ,sign     => '0'
            ,exponent => zero.exponent
            ,mantissa_multiplication_result => mpy
            ,shift_register                 => shift_register
            );

    begin
        return init_multiplier;
    end multiplier_typeref;
------------------------------------------------------------------------
    function "*"
    (
        left, right : hfloat_record
    ) return hfloat_record
    is
        variable result : left'subtype;
        constant mantissa_high : natural := left.mantissa'high;
        variable raw_result : unsigned(mantissa_high*2+1 downto 0) := (others => '0');
    begin

        result.sign     := left.sign xor right.sign;
        result.exponent := left.exponent + right.exponent;
        raw_result      := left.mantissa * right.mantissa;
        if raw_result(mantissa_high*2+1) = '1' then
            result.mantissa := raw_result(mantissa_high*2+1 downto mantissa_high+1);
        else
            result.mantissa := raw_result(mantissa_high*2 downto mantissa_high);
            result.exponent := left.exponent + right.exponent - 1;
        end if;
        return result;
        
    end function;

------------------------------------------------------------------------
    procedure create_float_multiplier 
    (
        signal self : inout float_multiplier_record
    ) 
    is
        constant mantissa_high : natural := self.left.mantissa'high;
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
        left, right : hfloat_record
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
    return hfloat_record
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
