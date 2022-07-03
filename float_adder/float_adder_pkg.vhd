library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;
    use work.denormalizer_pkg.all;

package float_adder_pkg is
------------------------------------------------------------------------
    type float_adder_record is record
        denormalizer : denormalizer_record;
        adder_result : float_record;
        adder_is_done : boolean;
    end record;

    constant init_adder : float_adder_record := (init_denormalizer, zero, false);
    constant init_float_adder : float_adder_record := init_adder;
------------------------------------------------------------------------
    procedure create_adder (
        signal adder_object : inout float_adder_record);
------------------------------------------------------------------------
    procedure request_add (
        signal adder_object : out float_adder_record;
        left, right : float_record);
------------------------------------------------------------------------
    procedure request_subtraction (
        signal adder_object : out float_adder_record;
        left, right : float_record);
------------------------------------------------------------------------
    procedure pipelined_add (
        signal adder_object : out float_adder_record;
        left, right : float_record );
------------------------------------------------------------------------
    procedure pipelined_subtract (
        signal adder_object : out float_adder_record;
        left, right : float_record );
------------------------------------------------------------------------
    function adder_is_ready (float_adder_object : float_adder_record)
        return boolean;
------------------------------------------------------------------------
    function get_result ( adder_object : float_adder_record)
        return float_record;
------------------------------------------------------------------------
end package float_adder_pkg;

package body float_adder_pkg is
------------------------------------------------------------------------
    procedure create_adder
    (
        signal adder_object : inout float_adder_record
    ) is
        alias adder_result is adder_object.adder_result;
        alias denormalizer is adder_object.denormalizer;
        alias adder_is_done is adder_object.adder_is_done;
    begin
        create_denormalizer(adder_object.denormalizer);
        adder_result <= (denormalizer.feedthrough_pipeline(number_of_denormalizer_pipeline_stages) + denormalizer.denormalizer_pipeline(number_of_denormalizer_pipeline_stages));
        adder_is_done <= denormalizer_is_ready(denormalizer);

    end create_adder;

------------------------------------------------------------------------
    procedure request_add
    (
        signal adder_object : out float_adder_record;
        left, right : float_record
    ) is
    begin
        pipelined_add(adder_object, left, right);
    end request_add;

------------------------------------------------------------------------
    procedure request_subtraction
    (
        signal adder_object : out float_adder_record;
        left, right : float_record
    ) is
    begin
        pipelined_subtract(adder_object, left, right);
    end request_subtraction;
------------------------------------------------------------------------
    procedure pipelined_add
    (
        signal adder_object : out float_adder_record;
        left, right : float_record 
    ) is
    begin
        request_scaling(adder_object.denormalizer, left, right);
    end pipelined_add;
------------------------------------------------------------------------
    procedure pipelined_subtract
    (
        signal adder_object : out float_adder_record;
        left, right : float_record 
    ) is
    begin
        request_scaling(adder_object.denormalizer, left, -right);
    end pipelined_subtract;
------------------------------------------------------------------------
    function adder_is_ready
    (
        float_adder_object : float_adder_record
    )
    return boolean
    is
    begin
        return float_adder_object.adder_is_done;
    end adder_is_ready;

------------------------------------------------------------------------
    function get_result
    (
        adder_object : float_adder_record
    )
    return float_record
    is
    begin
        return adder_object.adder_result;
    end get_result;
------------------------------------------------------------------------
end package body float_adder_pkg;
