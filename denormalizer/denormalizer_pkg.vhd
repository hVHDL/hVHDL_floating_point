library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;

package denormalizer_pkg is
------------------------------------------------------------------------
    type intarray is array (integer range 2 downto 0) of integer range -2**exponent_high to 2**exponent_high-1;
    constant init_intarray : intarray := (0,0,0);
------------------------------------------------------------------------
    type denormalizer_record is record
        denormalizer_pipeline : float_array(2 downto 0);
        feedthrough_pipeline : float_array(2 downto 0);
        target_scale_pipeline : intarray;
        shift_register : std_logic_vector(2 downto 0);
    end record;

    constant init_denormalizer : denormalizer_record := ((zero,zero,zero), (zero, zero, zero),init_intarray, (others => '0'));
------------------------------------------------------------------------
    procedure create_denormalizer (
        signal denormalizer_object : inout denormalizer_record);
------------------------------------------------------------------------
    procedure request_denormalizer (
        signal denormalizer_object : out denormalizer_record;
        denormalized_number : in float_record;
        target_scale : in integer);
------------------------------------------------------------------------
    procedure request_scaling (
        signal denormalizer_object : out denormalizer_record;
        left,right : in float_record);
------------------------------------------------------------------------
    function denormalizer_is_ready (denormalizer_object : denormalizer_record)
        return boolean;
------------------------------------------------------------------------
    function get_denormalized_result ( denormalizer_object : denormalizer_record)
        return float_record;
------------------------------------------------------------------------
end package denormalizer_pkg;

package body denormalizer_pkg is
------------------------------------------------------------------------
    procedure create_denormalizer 
    (
        signal denormalizer_object : inout denormalizer_record
    ) 
    is
        alias denormalizer_pipeline is denormalizer_object.denormalizer_pipeline;
        alias feedthrough_pipeline is denormalizer_object.feedthrough_pipeline;
        alias shift_register is denormalizer_object.shift_register;
        alias target_scale_pipeline is denormalizer_object.target_scale_pipeline;
    begin

        denormalizer_pipeline(1) <= denormalize_float(denormalizer_pipeline(0), target_scale_pipeline(0), mantissa_length/2);
        denormalizer_pipeline(2) <= denormalize_float(denormalizer_pipeline(1), target_scale_pipeline(1), mantissa_length/2);
        
        feedthrough_pipeline(1) <= feedthrough_pipeline(0);
        feedthrough_pipeline(2) <= feedthrough_pipeline(1);

        target_scale_pipeline(1) <= target_scale_pipeline(0);
        target_scale_pipeline(2) <= target_scale_pipeline(1);

        shift_register(0) <= '0';
        shift_register(1) <= shift_register(0);
        shift_register(2) <= shift_register(1);

    end procedure;

------------------------------------------------------------------------
    procedure request_denormalizer
    (
        signal denormalizer_object : out denormalizer_record;
        denormalized_number : in float_record;
        target_scale : in integer
    ) is
    begin
        denormalizer_object.denormalizer_pipeline(0) <= denormalized_number;
        denormalizer_object.target_scale_pipeline(0) <= target_scale;
        denormalizer_object.shift_register(0) <= '1';
        
    end request_denormalizer;
------------------------------------------------------------------------
    procedure request_scaling
    (
        signal denormalizer_object : out denormalizer_record;
        left,right : in float_record
    ) is
    begin
        denormalizer_object.shift_register(0) <= '1';
        if get_exponent(left) < get_exponent(right) then
            denormalizer_object.denormalizer_pipeline(0) <= left;
            denormalizer_object.feedthrough_pipeline(0)  <= right;
            denormalizer_object.target_scale_pipeline(0) <= get_exponent(right);
        else
            denormalizer_object.denormalizer_pipeline(0) <= right;
            denormalizer_object.feedthrough_pipeline(0)  <= left;
            denormalizer_object.target_scale_pipeline(0) <= get_exponent(left);
        end if;
        
    end request_scaling;
------------------------------------------------------------------------
    function denormalizer_is_ready
    (
        denormalizer_object : denormalizer_record
    )
    return boolean
    is
        constant left : integer := (denormalizer_object.shift_register'left);
    begin
        return denormalizer_object.shift_register(left) = '1';
    end denormalizer_is_ready;
------------------------------------------------------------------------
    function get_denormalized_result
    (
        denormalizer_object : denormalizer_record
    )
    return float_record
    is
        alias denormalizer_pipeline is denormalizer_object.denormalizer_pipeline;
    begin
        return denormalizer_pipeline(denormalizer_pipeline'left);
    end get_denormalized_result;
------------------------------------------------------------------------
end package body denormalizer_pkg;
