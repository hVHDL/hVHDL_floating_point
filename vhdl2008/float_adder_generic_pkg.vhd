library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_typedefs_generic_pkg.all;
    -- use work.float_arithmetic_operations_pkg.all;
    use work.denormalizer_generic_pkg.all;

package float_adder_pkg is
------------------------------------------------------------------------
    type float_adder_record is record
        denormalizer : denormalizer_record;
        adder_result : float_record;
        adder_is_done : boolean;
    end record;

    -- constant init_adder : float_adder_record := (init_denormalizer, zero, false);
    -- constant init_float_adder : float_adder_record := init_adder;
------------------------------------------------------------------------
    procedure create_adder (
        signal self : inout float_adder_record);
------------------------------------------------------------------------
    procedure request_add (
        signal self : out float_adder_record;
        left, right : float_record);
------------------------------------------------------------------------
    procedure request_subtraction (
        signal self : out float_adder_record;
        left, right : float_record);
------------------------------------------------------------------------
    function adder_is_ready (float_self : float_adder_record)
        return boolean;
------------------------------------------------------------------------
    function get_result ( self : float_adder_record)
        return float_record;
------------------------------------------------------------------------
end package float_adder_pkg;

package body float_adder_pkg is
------------------------------------------------------------------------
    procedure create_adder
    (
        signal self : inout float_adder_record
    ) is
        constant number_of_denormalizer_pipeline_stages : natural := self.denormalizer.feedthrough_pipeline'high;
    begin
        create_denormalizer(self.denormalizer);
        self.adder_result <= (self.denormalizer.feedthrough_pipeline(number_of_denormalizer_pipeline_stages) + self.denormalizer.denormalizer_pipeline(number_of_denormalizer_pipeline_stages));
        self.adder_is_done <= denormalizer_is_ready(self.denormalizer);

    end create_adder;

------------------------------------------------------------------------
    procedure request_add
    (
        signal self : out float_adder_record;
        left, right : float_record
    ) is
    begin
        request_scaling(self.denormalizer, left, right);
    end request_add;

------------------------------------------------------------------------
    procedure request_subtraction
    (
        signal self : out float_adder_record;
        left, right : float_record
    ) is
    begin
        request_scaling(self.denormalizer, left, -right);
    end request_subtraction;
------------------------------------------------------------------------
    function adder_is_ready
    (
        float_self : float_adder_record
    )
    return boolean
    is
    begin
        return float_self.adder_is_done;
    end adder_is_ready;

------------------------------------------------------------------------
    function get_result
    (
        self : float_adder_record
    )
    return float_record
    is
    begin
        return self.adder_result;
    end get_result;
------------------------------------------------------------------------
end package body float_adder_pkg;
