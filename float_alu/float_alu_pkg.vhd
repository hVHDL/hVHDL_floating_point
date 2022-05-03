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
        adder_denormalizer : denormalizer_record ;
        float_left         : float_record;
        float_adder        : float_adder_record  ;
        adder_normalizer   : normalizer_record   ;

        float_multiplier : float_multiplier_record ;
        multiplier_normalizer : normalizer_record  ;

    end record;

    constant init_float_alu : float_alu_record := (
            init_denormalizer     ,
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
        alias float_multiplier is float_alu_object.float_multiplier;
        alias float_adder is float_alu_object.float_adder;
        alias multiplier_normalizer is float_alu_object.multiplier_normalizer;
        alias adder_normalizer is float_alu_object.adder_normalizer;
        alias adder_denormalizer is float_alu_object.adder_denormalizer;
        alias left is float_alu_object.float_left;
    begin

        create_denormalizer(float_alu_object.adder_denormalizer);
        create_adder(float_alu_object.float_adder);
        create_normalizer(float_alu_object.adder_normalizer);

        create_float_multiplier(float_alu_object.float_multiplier);
        create_normalizer(float_alu_object.multiplier_normalizer);

        if denormalizer_is_ready(adder_denormalizer) then
            request_add(float_adder, left, get_denormalized_result(adder_denormalizer));
        end if; 

        if adder_is_ready(float_adder) then
            request_normalizer(adder_normalizer, get_result(float_adder));
        end if;

        if float_multiplier_is_ready(float_multiplier) then
            request_normalizer(multiplier_normalizer, get_multiplier_result(float_multiplier));
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
        variable left_mantissa, right_mantissa : integer;
    begin
        left_mantissa := get_mantissa(left);
        right_mantissa := get_mantissa(right);
        if left_mantissa > right_mantissa then
            request_denormalizer(alu_object.adder_denormalizer, left, right_mantissa);
            alu_object.float_left <= right;
        else
            request_denormalizer(alu_object.adder_denormalizer, right, left_mantissa);
            alu_object.float_left <= left;
        end if;
    end add;
------------------------------------------------------------------------
    function add_is_ready
    (
        alu_object : float_alu_record
    )
    return boolean
    is
    begin
        return adder_is_ready(alu_object.float_adder);
    end add_is_ready;
------------------------------------------------------------------------
    function get_add_result
    (
        alu_object : float_alu_record
    )
    return float_record
    is
    begin
        return get_result(alu_object.float_adder);
    end get_add_result;
------------------------------------------------------------------------
end package body float_alu_pkg;
