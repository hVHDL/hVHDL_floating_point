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

    signal simulation_running  : boolean;
    signal simulator_clock     : std_logic := '0';
    constant clock_per         : time      := 1 ns;
    constant clock_half_per    : time      := 0.5 ns;
    constant simtime_in_clocks : integer   := 150;

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
    use work.float_to_real_conversions_pkg.all;

    function to_float(a : real) return float_record is
    begin
        return to_float(a,8,23);
    end to_float;

    constant float_zero : float_record := to_float(0.0);

    signal float32_conv_result : float32 := to_float32(0.0);
    signal convref             : float32 := to_float32(check_value);
    signal conv_result         : float_zero'subtype := float_zero;

    constant float1 : float_zero'subtype := to_float(-84.5);
    constant float2 : float_zero'subtype := to_float(1.5);
    constant float3 : float_zero'subtype := to_float(84.5/2.0);

    use work.multiply_add_pkg.all;
    constant mpya_ref : mpya_subtype_record := create_mpya_typeref(8,23);

    signal mpya_in  : mpya_ref.mpya_in'subtype  := mpya_ref.mpya_in;
    signal mpya_out : mpya_ref.mpya_out'subtype := mpya_ref.mpya_out;

    signal mpya_result : float_zero'subtype := float_zero;
    signal real_mpya_result : real := 0.0;

    use work.normalizer_generic_pkg.to_ieee_float32;


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

            -- create_normalizer(normalizer);
            -- create_adder(adder);
            -- create_float_multiplier(multiplier);
            --
            CASE simulation_counter is
                WHEN 0 =>
                    multiply_add(mpya_in 
                    ,to_std_logic(float1)
                    ,to_std_logic(float2)
                    ,to_std_logic(float3));

                -- WHEN 1 =>
                --     multiply_add(mpya_in 
                --     ,to_std_logic(float1)
                --     ,to_std_logic(float1)
                --     ,to_std_logic(float3));
                -- WHEN 2 =>
                --     multiply_add(mpya_in 
                --     ,to_std_logic(float2)
                --     ,to_std_logic(float2)
                --     ,to_std_logic(float2));

                WHEN others => -- do nothing
            end CASE;
            --
            -- if float_multiplier_is_ready(multiplier) then
            --     request_add(adder,get_multiplier_result(multiplier), float3);
            -- end if;
            --
            -- if adder_is_ready(adder) 
            -- then
            --     request_normalizer(normalizer, get_result(adder));
            -- end if;
            --
            -- if normalizer_is_ready(normalizer) then
            --     request_denormalizer(denormalizer, get_normalizer_result(normalizer), 20);
            --     conv_result         <= get_normalizer_result(normalizer);
            --     float32_conv_result <= to_ieee_float32(get_normalizer_result(normalizer));
            -- end if;
            --
            if mpya_is_ready(mpya_out)
            then
                mpya_result         <= to_float(get_mpya_result(mpya_out), float_zero);
                real_mpya_result    <= to_real(to_float(get_mpya_result(mpya_out), float_zero));
                float32_conv_result <= to_ieee_float32(to_float(get_mpya_result(mpya_out), float_zero));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
    dut : entity work.multiply_add
    generic map(float_zero.exponent'length,float_zero.mantissa'length)
    port map(
        simulator_clock
        ,mpya_in
        ,mpya_out
    );

------------------------------------------------------------------------
end vunit_simulation;
