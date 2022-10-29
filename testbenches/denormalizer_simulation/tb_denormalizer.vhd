LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.denormalizer_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity denormalizer_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of denormalizer_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal larger  : float_record := to_float(8563.0);
    signal smaller : float_record := to_float(37.0);

    signal test_float : float_record := to_float(1.65);
    signal test_denormalizer : float_record := denormalize_float(test_float,3);

    signal denormalizer : denormalizer_record := init_denormalizer;
    signal denormalization_result : float_record := to_float(0.0);

    signal test_add : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    sim_clock_gen : process
    begin
        simulator_clock <= '0';
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                simulator_clock <= not simulator_clock;
            end loop;
        wait;
    end process;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_denormalizer(denormalizer);

            CASE simulation_counter is
                -- WHEN 0 => request_denormalizer(denormalizer, (to_float(1.5)), 5);
                -- WHEN 1 => request_denormalizer(denormalizer, (to_float(1.5)), 6);
                -- WHEN 2 => request_denormalizer(denormalizer, (to_float(1.5)), 7); 
                
                WHEN 0 => request_scaling(denormalizer , to_float(1.5)    , to_float(7.5));
                WHEN 1 => request_scaling(denormalizer , to_float(1.5)    , to_float(8.5));
                WHEN 2 => request_scaling(denormalizer , to_float(-100.5) , to_float(-9.5));
                WHEN 3 => request_scaling(denormalizer , to_float(0.0)    , to_float(-9.5));
                WHEN others => -- do nothing
            end CASE;

            if denormalizer_is_ready(denormalizer) then
                denormalization_result <= get_denormalized_result(denormalizer);
            end if;
            
            test_add <= to_real(denormalizer.feedthrough_pipeline(2) + denormalizer.denormalizer_pipeline(2));

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
