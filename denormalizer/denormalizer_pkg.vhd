library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;

package denormalizer_pkg is

    constant number_of_denormalizer_pipeline_stages : natural := 2;
------------------------------------------------------------------------
    type intarray is array (integer range number_of_denormalizer_pipeline_stages downto 0) of integer range -2**exponent_high to 2**exponent_high-1;
------------------------------------------------------------------------
    type denormalizer_record is record
        denormalizer_pipeline : float_array(number_of_denormalizer_pipeline_stages downto 0);
        feedthrough_pipeline  : float_array(number_of_denormalizer_pipeline_stages downto 0);
        shift_register        : std_logic_vector(number_of_denormalizer_pipeline_stages downto 0);
        target_scale_pipeline : intarray;
    end record;

    function init_denormalizer return denormalizer_record;

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
    function init_denormalizer
    return denormalizer_record
    is
        variable initialized_record : denormalizer_record;
        variable init_denormalizer_pipeline : float_array(number_of_denormalizer_pipeline_stages downto 0);
        variable init_feedthrough_pipeline  : float_array(number_of_denormalizer_pipeline_stages downto 0);
        variable init_shift_register        : std_logic_vector(number_of_denormalizer_pipeline_stages downto 0);
        variable init_target_scale_pipeline : intarray;
    begin
        for i in 0 to number_of_denormalizer_pipeline_stages loop
            init_denormalizer_pipeline(i) := zero;
            init_feedthrough_pipeline(i)  := zero;
            init_target_scale_pipeline(i) := 0;
            init_shift_register(i)        := '0';
        end loop;
        initialized_record := (
            denormalizer_pipeline => init_denormalizer_pipeline ,
            feedthrough_pipeline  => init_feedthrough_pipeline  ,
            shift_register        => init_shift_register        ,
            target_scale_pipeline => init_target_scale_pipeline);
        return initialized_record;
    end init_denormalizer;
------------------------------------------------------------------------
    procedure create_denormalizer 
    (
        signal denormalizer_object : inout denormalizer_record
    ) 
    is
        alias m is denormalizer_object;
    begin

        m.shift_register(0) <= '0';
        for i in 1 to number_of_denormalizer_pipeline_stages loop
            m.denormalizer_pipeline(i) <= denormalize_float(m.denormalizer_pipeline(i-1), m.target_scale_pipeline(i-1), mantissa_length/number_of_denormalizer_pipeline_stages);
            m.feedthrough_pipeline(i)  <= m.feedthrough_pipeline(i-1);
            m.target_scale_pipeline(i) <= m.target_scale_pipeline(i-1);
            m.shift_register(i)        <= m.shift_register(i-1);
        end loop;

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
