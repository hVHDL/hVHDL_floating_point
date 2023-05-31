library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.denormalizer_pipeline_pkg.pipeline_configuration;

package denormalizer_pkg is

    alias number_of_denormalizer_pipeline_stages is pipeline_configuration;
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
end package body denormalizer_pkg;
