library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_multiplier_pkg.all;
    use work.normalizer_pkg.all;
    use work.denormalizer_pkg.all;
    use work.float_to_real_conversions_pkg.all;

package float_alu_pkg is
------------------------------------------------------------------------
    type float_alu_record is record
        float_left         : float_record;
        float_adder        : float_adder_record  ;
        adder_normalizer   : normalizer_record   ;

        float_multiplier : float_multiplier_record ;
        multiplier_normalizer : normalizer_record  ;

    end record;

    constant init_float_alu : float_alu_record := (
            to_float(0.0)         ,
            init_float_adder      ,
            init_normalizer       ,
            init_float_multiplier ,
            init_normalizer);

------------------------------------------------------------------------
    procedure create_float_alu (
        signal float_alu_object : inout float_alu_record);
------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure multiply (
        signal alu_object : inout float_alu_record;
        left, right : float_record);
------------------------------------------------------------------------
    function multiplier_is_ready ( alu_object : float_alu_record)
        return boolean;
------------------------------------------------------------------------
    function get_multiplier_result ( alu_object : float_alu_record)
        return float_record;
------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure add (
        signal alu_object : inout float_alu_record;
        left, right : float_record);

    procedure subtract (
        signal alu_object : inout float_alu_record;
        left, right : float_record);
------------------------------------------------------------------------
    function add_is_ready ( alu_object : float_alu_record)
        return boolean;
------------------------------------------------------------------------
    function get_add_result ( alu_object : float_alu_record)
        return float_record;
------------------------------------------------------------------------
------------------------------------------------------------------------
end package float_alu_pkg;

package body float_alu_pkg is
------------------------------------------------------------------------
    procedure create_float_alu 
    (
        signal float_alu_object : inout float_alu_record
    ) 
    is
    begin

        create_adder(float_alu_object.float_adder);
        create_normalizer(float_alu_object.adder_normalizer);

        create_float_multiplier(float_alu_object.float_multiplier);
        create_normalizer(float_alu_object.multiplier_normalizer);

        if adder_is_ready(float_alu_object.float_adder) then
            request_normalizer(float_alu_object.adder_normalizer, get_result(float_alu_object.float_adder));
        end if;

        if float_multiplier_is_ready(float_alu_object.float_multiplier) then
            request_normalizer(float_alu_object.multiplier_normalizer, get_multiplier_result(float_alu_object.float_multiplier));
        end if;

    end procedure;
------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure multiply
    (
        signal alu_object : inout float_alu_record;
        left, right : float_record
    ) is
    begin

        request_float_multiplier(
            alu_object.float_multiplier,
            left, right);
    end multiply;
------------------------------------------------------------------------
    function multiplier_is_ready
    (
        alu_object : float_alu_record
    )
    return boolean
    is
    begin
        return normalizer_is_ready(alu_object.multiplier_normalizer);
    end multiplier_is_ready;
------------------------------------------------------------------------
    function get_multiplier_result
    (
        alu_object : float_alu_record
    )
    return float_record
    is
    begin
        return get_normalizer_result(alu_object.multiplier_normalizer);
    end get_multiplier_result;
------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure add
    (
        signal alu_object : inout float_alu_record;
        left, right : float_record
    ) is
    begin
        request_add(alu_object.float_adder, left, right);
    end add;
------------------------------------------------------------------------
    procedure subtract
    (
        signal alu_object : inout float_alu_record;
        left, right : float_record
    ) is
    begin
        request_subtraction(alu_object.float_adder, left, right);
    end subtract;
------------------------------------------------------------------------
    function add_is_ready
    (
        alu_object : float_alu_record
    )
    return boolean
    is
    begin
        return normalizer_is_ready(alu_object.adder_normalizer);
    end add_is_ready;
------------------------------------------------------------------------
    function get_add_result
    (
        alu_object : float_alu_record
    )
    return float_record
    is
    begin
        return get_normalizer_result(alu_object.adder_normalizer);
    end get_add_result;
------------------------------------------------------------------------
end package body float_alu_pkg;
