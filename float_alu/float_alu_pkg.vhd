library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_multiplier_pkg.all;
    use work.normalizer_pkg.all;

package float_alu_pkg is
------------------------------------------------------------------------
    type float_alu_record is record

        float_adder                 : float_adder_record      ;
        float_multiplier            : float_multiplier_record ;
        float_adder_normalizer      : float_normalizer_record ;
        float_multiplier_normalizer : float_normalizer_record ;

        float_alu_is_done : boolean;
        float_alu_is_requested : boolean;
    end record;

    constant init_float_alu : float_alu_record := (
            init_float_adder      ,
            init_float_multiplier ,
            init_float_normalizer ,
            init_float_normalizer ,
            false, false);

------------------------------------------------------------------------
    procedure create_float_alu (
        signal float_alu_object : inout float_alu_record);
------------------------------------------------------------------------
    procedure request_float_alu (
        signal float_alu_object : out float_alu_record);
------------------------------------------------------------------------
    function float_alu_is_ready (float_alu_object : float_alu_record)
        return boolean;
------------------------------------------------------------------------
end package float_alu_pkg;

package body float_alu_pkg is
------------------------------------------------------------------------
    procedure create_float_alu 
    (
        signal float_alu_object : inout float_alu_record
    ) 
    is
        alias float_alu_is_requested is  float_alu_object.float_alu_is_requested;
        alias float_alu_is_done      is  float_alu_object.float_alu_is_done;

        alias float_adder                 is float_alu_object.float_adder                ;
        alias float_multiplier            is float_alu_object.float_multiplier           ;
        alias float_adder_normalizer      is float_alu_object.float_adder_normalizer     ;
        alias float_multiplier_normalizer is float_alu_object.float_multiplier_normalizer;
    begin

        create_adder(float_adder);
        create_normalizer(float_adder_normalizer);

        create_float_multiplier(float_multiplier);
        create_normalizer(float_multiplier_normalizer);

        float_alu_is_requested <= false;
        if float_alu_is_requested then
            float_alu_is_done <= true;
        else
            float_alu_is_done <= false;
        end if;
    end procedure;

------------------------------------------------------------------------
    procedure request_float_alu
    (
        signal float_alu_object : out float_alu_record
    ) is
    begin
        float_alu_object.float_alu_is_requested <= true;
        
    end request_float_alu;

------------------------------------------------------------------------
    function float_alu_is_ready
    (
        float_alu_object : float_alu_record
    )
    return boolean
    is
    begin
        return float_alu_object.float_alu_is_done;
    end float_alu_is_ready;

------------------------------------------------------------------------
end package body float_alu_pkg;
