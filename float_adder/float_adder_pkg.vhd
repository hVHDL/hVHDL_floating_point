library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;
    use work.denormalizer_pkg.all;

package float_adder_pkg is
------------------------------------------------------------------------
    type float_adder_record is record
        larger        : float_record;
        smaller       : float_record;
        result        : float_record;
        adder_counter : integer range 0 to 7;
        adder_is_done : boolean;

        denormalizer : denormalizer_record;
        test_add : float_record;
        denormalized_add_is_ready : boolean;
    end record;

    constant init_adder : float_adder_record := (zero,zero,zero, 7, false, init_denormalizer, zero, false);
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
        alias larger        is adder_object.larger        ;
        alias smaller       is adder_object.smaller       ;
        alias result        is adder_object.result        ;
        alias adder_counter is adder_object.adder_counter ;
        alias adder_is_done is adder_object.adder_is_done;
        alias test_add is adder_object.test_add;
        alias denormalizer is adder_object.denormalizer;
        alias denormalized_add_is_ready is adder_object.denormalized_add_is_ready;
    begin
        create_denormalizer(adder_object.denormalizer);
        test_add <= (denormalizer.feedthrough_pipeline(2) + denormalizer.denormalizer_pipeline(2));
        denormalized_add_is_ready <= denormalizer_is_ready(denormalizer);

        adder_is_done <= false;
        CASE adder_counter is
            WHEN 0 => 
                if larger.exponent < smaller.exponent then
                    larger  <= smaller;
                    smaller <= larger;
                end if;
                adder_counter <= adder_counter + 1;
            WHEN 1 => 
                smaller <= denormalize_float(smaller, to_integer(larger.exponent));
                adder_counter <= adder_counter + 1;
            WHEN 2 =>
                result <= larger + smaller;
                adder_is_done <= true;
                adder_counter <= adder_counter + 1;
            WHEN others => -- do nothing
        end CASE;

    end create_adder;

------------------------------------------------------------------------
    procedure request_add
    (
        signal adder_object : out float_adder_record;
        left, right : float_record
    ) is
    begin
        adder_object.adder_counter <= 0;
        adder_object.smaller <= left;
        adder_object.larger <= right;
    end request_add;

------------------------------------------------------------------------
    procedure request_subtraction
    (
        signal adder_object : out float_adder_record;
        left, right : float_record
    ) is
    begin
        adder_object.adder_counter <= 0;
        adder_object.smaller <= left;
        adder_object.larger <= -right;
    end request_subtraction;
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
        return adder_object.result;
    end get_result;
------------------------------------------------------------------------
end package body float_adder_pkg;
