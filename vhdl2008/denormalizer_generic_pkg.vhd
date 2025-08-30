library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package denormalizer_generic_pkg is
    generic(
                package float_types_pkg is new work.float_typedefs_generic_pkg generic map (<>)
                ; g_denormalizer_pipeline_depth : natural := 1
            );

    use float_types_pkg.all;

    constant number_of_denormalizer_pipeline_stages : natural := g_denormalizer_pipeline_depth;
------------------------------------------------------------------------
    type intarray is array (integer range number_of_denormalizer_pipeline_stages downto 0) of integer range -2**exponent_high to 2**exponent_high-1;
------------------------------------------------------------------------
    type denormalizer_record is record
        denormalizer_pipeline : float_array(number_of_denormalizer_pipeline_stages downto 0);
        feedthrough_pipeline  : float_array(number_of_denormalizer_pipeline_stages downto 0);
        shift_register        : std_logic_vector(number_of_denormalizer_pipeline_stages downto 0);
        target_scale_pipeline : intarray;
    end record;

    constant init_denormalizer : denormalizer_record := (
            denormalizer_pipeline => (others => zero),
            feedthrough_pipeline  => (others => zero),
            shift_register        => (others => '0'),
            target_scale_pipeline => (others => 0));

------------------------------------------------------------------------
    procedure create_denormalizer (
        signal self : inout denormalizer_record);
------------------------------------------------------------------------
    procedure request_denormalizer (
        signal self : out denormalizer_record;
        denormalized_number : in float_record;
        target_scale : in integer);
------------------------------------------------------------------------
    procedure request_scaling (
        signal self : out denormalizer_record;
        left,right : in float_record);

    procedure request_scaling (
        signal self : out denormalizer_record;
        left : in float_record;
        right : in integer);
------------------------------------------------------------------------
    function denormalizer_is_ready (self : denormalizer_record)
        return boolean;
------------------------------------------------------------------------
    function get_denormalized_result ( self : denormalizer_record)
        return float_record;
------------------------------------------------------------------------
    function get_integer ( self : denormalizer_record)
        return integer;
------------------------------------------------------------------------
    function denormalize_float (
        right           : float_record;
        set_exponent_to : integer)
    return float_record;

    function denormalize_float (
        right           : float_record;
        set_exponent_to : integer;
        max_shift       : integer)
    return float_record;
------------------------------------------------------------------------
    procedure convert_float_to_integer (
        signal self : out denormalizer_record;
        number_to_be_converted : float_record;
        desired_radix : in integer);
------------------------------------------------------------------------
end package denormalizer_generic_pkg;

package body denormalizer_generic_pkg is
------------------------------------------------------------------------
    procedure create_denormalizer 
    (
        signal self : inout denormalizer_record
    ) 
    is
    begin

        self.shift_register(0) <= '0';
        for i in 1 to number_of_denormalizer_pipeline_stages loop
            self.denormalizer_pipeline(i) <= denormalize_float(self.denormalizer_pipeline(i-1), self.target_scale_pipeline(i-1), mantissa_length/number_of_denormalizer_pipeline_stages);
            self.feedthrough_pipeline(i)  <= self.feedthrough_pipeline(i-1);
            self.target_scale_pipeline(i) <= self.target_scale_pipeline(i-1);
            self.shift_register(i)        <= self.shift_register(i-1);
        end loop;

    end procedure;

------------------------------------------------------------------------
    procedure request_denormalizer
    (
        signal self : out denormalizer_record;
        denormalized_number : in float_record;
        target_scale : in integer
    ) is
    begin
        self.denormalizer_pipeline(0) <= denormalized_number;
        self.target_scale_pipeline(0) <= target_scale;
        self.shift_register(0) <= '1';
        
    end request_denormalizer;
------------------------------------------------------------------------
    procedure request_scaling
    (
        signal self : out denormalizer_record;
        left,right : in float_record
    ) is
    begin
        self.shift_register(0) <= '1';
        if get_exponent(left) < get_exponent(right) then
            self.denormalizer_pipeline(0) <= left;
            self.feedthrough_pipeline(0)  <= right;
            self.target_scale_pipeline(0) <= get_exponent(right);
        else
            self.denormalizer_pipeline(0) <= right;
            self.feedthrough_pipeline(0)  <= left;
            self.target_scale_pipeline(0) <= get_exponent(left);
        end if;
        
    end request_scaling;
------------------------------------------------------------------------
    procedure request_scaling
    (
        signal self : out denormalizer_record;
        left : in float_record;
        right : in integer
    ) is
    begin
        self.shift_register(0) <= '1';
        self.denormalizer_pipeline(0) <= left;
        self.feedthrough_pipeline(0)  <= left;
        self.target_scale_pipeline(0) <= mantissa_length - right;
        
    end request_scaling;

    function get_integer
    (
        self : denormalizer_record
        
    )
    return integer
    is
        variable returned_value : integer;
    begin
        if get_sign(self.feedthrough_pipeline(number_of_denormalizer_pipeline_stages)) = '0' then
            returned_value := (get_mantissa(get_denormalized_result(self)));
        else
            returned_value := -(get_mantissa(get_denormalized_result(self)));
        end if;
        return returned_value;
        
    end get_integer;

------------------------------------------------------------------------
    function denormalizer_is_ready
    (
        self : denormalizer_record
    )
    return boolean
    is
        constant left : integer := (self.shift_register'left);
    begin
        return self.shift_register(left) = '1';
    end denormalizer_is_ready;
------------------------------------------------------------------------
    function get_denormalized_result
    (
        self : denormalizer_record
    )
    return float_record
    is
    begin
        return self.denormalizer_pipeline(self.denormalizer_pipeline'left);
    end get_denormalized_result;
------------------------------------------------------------------------
    function denormalize_float
    (
        right           : float_record;
        set_exponent_to : integer;
        max_shift       : integer
    )
    return float_record
    is
        variable float : float_record := zero;
        variable shift_width : integer;
    begin
        shift_width := to_integer(set_exponent_to - right.exponent);
        if shift_width >= max_shift then
            shift_width := max_shift;
        end if;
        if shift_width < 0 then
            shift_width := 0;
        end if;
        float := (sign     => right.sign,
                  exponent => right.exponent + shift_width,
                  mantissa => shift_right(right.mantissa , shift_width));

        return float;
        
    end denormalize_float;
------------------------------------------------------------------------
    function denormalize_float
    (
        right           : float_record;
        set_exponent_to : integer
    )
    return float_record
    is
    begin

        return denormalize_float(right, set_exponent_to, mantissa_length);
        
    end denormalize_float;
------------------------------------------------------------------------
    procedure convert_float_to_integer
    (
        signal self : out denormalizer_record;
        number_to_be_converted : float_record;
        desired_radix : in integer
    ) is
    begin
        request_scaling(self, number_to_be_converted, desired_radix);
        
    end convert_float_to_integer;
--------------------------------------------------
end package body denormalizer_generic_pkg;
