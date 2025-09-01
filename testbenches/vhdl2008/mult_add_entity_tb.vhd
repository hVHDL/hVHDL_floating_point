LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    
library vunit_lib;
    context vunit_lib.vunit_context;

entity mult_add_entity_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of mult_add_entity_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic := '0';
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    use ieee.float_pkg.all;

    function to_float32 (a : real) return float32 is
    begin
        return to_float(a, float32'high);
    end to_float32;

    constant check_value : real := -84.5;

    use work.float_typedefs_generic_pkg.all;
    use work.normalizer_generic_pkg.all;
    use work.denormalizer_generic_pkg.all;

    constant float_zero : float_record :=(sign => '0', exponent => (7 downto 0 => x"00"), mantissa => (23 downto 0 => x"000000"));

    signal float32_conv_result : float32 := to_float32(0.0);
    signal convref : float32 := to_float32(check_value);
    signal conv_result : float_zero'subtype := float_zero;

    constant init_normalizer : normalizer_record := normalizer_typeref(2, floatref => float_zero);
    signal normalizer : init_normalizer'subtype := init_normalizer;

    constant init_denormalizer : denormalizer_record := denormalizer_typeref(2, floatref => float_zero);
    signal denormalizer : init_denormalizer'subtype := init_denormalizer;

    use work.float_adder_pkg.all;
    constant init_adder : float_adder_record := adder_typeref(2, float_zero);
    signal adder : init_adder'subtype := init_adder;

    use work.float_to_real_conversions_pkg.all;

    constant float1 : float_zero'subtype := to_float(-84.5);
    constant float2 : float_zero'subtype := to_float(1.5);
    constant float3 : float_zero'subtype := to_float(84.5/2.0);

    use work.float_multiplier_pkg.all;
    constant init_multiplier : float_multiplier_record := multiplier_typeref(float_zero);
    signal multiplier : init_multiplier'subtype := init_multiplier;

    use work.multiply_add_pkg.all;
    constant mpya_ref : mpya_subtype_record := create_mpya_typeref(8,24);

    signal mpya_in  : mpya_ref.mpya_in'subtype  := mpya_ref.mpya_in;
    signal mpya_out : mpya_ref.mpya_out'subtype := mpya_ref.mpya_out;

    signal mpya_result : float_zero'subtype := float_zero;
    signal real_mpya_result : real := 0.0;


begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        check(convref = float32_conv_result);
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            init_multiply_add(mpya_in);

            create_normalizer(normalizer);
            create_adder(adder);
            create_float_multiplier(multiplier);

            CASE simulation_counter is
                WHEN 0 =>
                    request_float_multiplier(multiplier, float1, float2);
                    multiply_add(mpya_in 
                    ,to_std_logic(float1)
                    ,to_std_logic(float2)
                    ,to_std_logic(float3));

                WHEN 1 =>
                    multiply_add(mpya_in 
                    ,to_std_logic(float1)
                    ,to_std_logic(float1)
                    ,to_std_logic(float3));
                WHEN 2 =>
                    multiply_add(mpya_in 
                    ,to_std_logic(float2)
                    ,to_std_logic(float2)
                    ,to_std_logic(float2));

                WHEN others => -- do nothing
            end CASE;
            
            if float_multiplier_is_ready(multiplier) then
                request_add(adder,get_multiplier_result(multiplier), float3);
            end if;

            if adder_is_ready(adder) 
            then
                request_normalizer(normalizer, get_result(adder));
            end if;

            if normalizer_is_ready(normalizer) then
                request_denormalizer(denormalizer, get_normalizer_result(normalizer), 20);
                conv_result         <= get_normalizer_result(normalizer);
                float32_conv_result <= to_ieee_float32(get_normalizer_result(normalizer));
            end if;

            if mpya_is_ready(mpya_out)
            then
                mpya_result <= to_float(get_mpya_result(mpya_out), float_zero);
                real_mpya_result <= to_real(to_float(get_mpya_result(mpya_out), float_zero));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
    dut : entity work.multiply_add
    port map(
        simulator_clock
        ,mpya_in
        ,mpya_out
    );

------------------------------------------------------------------------
end vunit_simulation;
