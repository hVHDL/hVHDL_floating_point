library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_typedefs_generic_pkg.all;

package denormalizer_generic_pkg is

------------------------------------------------------------------------
    type intarray is array (integer range <>) of integer;
------------------------------------------------------------------------
    type denormalizer_record is record
        denormalizer_pipeline : float_array;
        feedthrough_pipeline  : float_array;
        shift_register        : std_logic_vector;
        target_scale_pipeline : intarray;
    end record;

    function denormalizer_typeref (number_of_pipeline_stages : natural := 2; floatref : hfloat_record) 
        return denormalizer_record;

------------------------------------------------------------------------
    procedure create_denormalizer (
        signal self : inout denormalizer_record);
------------------------------------------------------------------------
    procedure request_denormalizer (
        signal self : out denormalizer_record;
        denormalized_number : in hfloat_record;
        target_scale : in integer);
------------------------------------------------------------------------
    procedure request_scaling (
        signal self : out denormalizer_record;
        left,right : in hfloat_record);

    procedure request_scaling (
        signal self : out denormalizer_record;
        left : in hfloat_record;
        right : in integer);
------------------------------------------------------------------------
    function denormalizer_is_ready (self : denormalizer_record)
        return boolean;
------------------------------------------------------------------------
    function get_denormalized_result ( self : denormalizer_record)
        return hfloat_record;
------------------------------------------------------------------------
    function get_integer ( self : denormalizer_record)
        return integer;
------------------------------------------------------------------------
    function denormalize_float (
        right           : hfloat_record;
        set_exponent_to : integer)
    return hfloat_record;

    function denormalize_float (
        right           : hfloat_record;
        set_exponent_to : integer;
        max_shift       : integer)
    return hfloat_record;
------------------------------------------------------------------------
    procedure convert_float_to_integer (
        signal self : out denormalizer_record;
        number_to_be_converted : hfloat_record;
        desired_radix : in integer);
------------------------------------------------------------------------
end package denormalizer_generic_pkg;

package body denormalizer_generic_pkg is
------------------------------------------------------------------------
    function denormalizer_typeref (number_of_pipeline_stages : natural := 2; floatref : hfloat_record) 
    return denormalizer_record is
        constant init_denormalizer : denormalizer_record := (
            denormalizer_pipeline  => (number_of_pipeline_stages-1 downto 0 => floatref)
            ,feedthrough_pipeline  => (number_of_pipeline_stages-1 downto 0 => floatref)
            ,shift_register        => (number_of_pipeline_stages-1 downto 0 => '0')
            ,target_scale_pipeline => (number_of_pipeline_stages-1 downto 0 => 0));
    begin
        return init_denormalizer;
    end denormalizer_typeref;
------------------------------------------------------------------------
    procedure create_denormalizer 
    (
        signal self : inout denormalizer_record
    ) 
    is
        constant number_of_denormalizer_pipeline_stages : natural := self.denormalizer_pipeline'high;
        constant mantissa_length : natural := self.denormalizer_pipeline(0).mantissa'length;
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
        denormalized_number : in hfloat_record;
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
        left,right : in hfloat_record
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
        left : in hfloat_record;
        right : in integer
    ) is
        constant mantissa_length : natural := self.denormalizer_pipeline(0).mantissa'length;
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
        if get_sign(self.feedthrough_pipeline(self.feedthrough_pipeline'high)) = '0' then
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
    return hfloat_record
    is
    begin
        return self.denormalizer_pipeline(self.denormalizer_pipeline'left);
    end get_denormalized_result;
------------------------------------------------------------------------
    function denormalize_float
    (
        right           : hfloat_record;
        set_exponent_to : integer;
        max_shift       : integer
    )
    return hfloat_record
    is
        variable retval : right'subtype;
        variable shift_width : integer;
    begin
        shift_width := to_integer(set_exponent_to - right.exponent);
        if shift_width >= max_shift then
            shift_width := max_shift;
        end if;
        if shift_width < 0 then
            shift_width := 0;
        end if;
        retval := (sign     => right.sign,
                  exponent => right.exponent + shift_width,
                  mantissa => shift_right(right.mantissa , shift_width));

        return retval;
        
    end denormalize_float;
------------------------------------------------------------------------
    function denormalize_float
    (
        right           : hfloat_record;
        set_exponent_to : integer
    )
    return hfloat_record
    is
        constant mantissa_length : natural := right.mantissa'length;
    begin

        return denormalize_float(right, set_exponent_to, mantissa_length);
        
    end denormalize_float;
------------------------------------------------------------------------
    procedure convert_float_to_integer
    (
        signal self : out denormalizer_record;
        number_to_be_converted : hfloat_record;
        desired_radix : in integer
    ) is
    begin
        request_scaling(self, number_to_be_converted, desired_radix);
        
    end convert_float_to_integer;
--------------------------------------------------
end package body denormalizer_generic_pkg;
