LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    
    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.normalizer_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_normalizer is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_normalizer is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal smaller : float_record := to_float(0.5);
    signal larger : float_record := to_float(6.0);

    signal normalizer : normalizer_record := init_normalizer;

    signal test_float_normalization : float_record := ('0', to_signed(0, exponent_length), (0 => '1', others => '0'));

    signal number_zeroes : integer := number_of_leading_zeroes(test_float_normalization.mantissa, 5);

    signal normalizer_array : float_array(0 to 3) := (zero,zero,zero,zero);
    signal normalizer_result : float_record := zero;

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

            create_normalizer(normalizer);

            CASE simulation_counter is 
                WHEN 0 => 
                    request_normalizer(normalizer, test_float_normalization);
                WHEN others => -- do nothing
            end CASE;

            normalizer_array(0) <= normalize(test_float_normalization , mantissa_high/4);
            normalizer_array(1) <= normalize(normalizer_array(0)      , mantissa_high/4);
            normalizer_array(2) <= normalize(normalizer_array(1)      , mantissa_high/4);
            normalizer_array(3) <= normalize(normalizer_array(2)      , mantissa_high/4);


            if normalizer_is_ready(normalizer) then
                normalizer_result <= get_normalizer_result(normalizer);
            end if;

            smaller <= normalize(smaller);

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
