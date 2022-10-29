LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_to_real_functions_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity fp2real_functions_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of fp2real_functions_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    constant tested_number : real := 8.0;
    signal test_4      : float_record := to_float(tested_number);
    signal test_4_real : real         := to_real(test_4);

    signal test_5      : float_record := to_float(0.0002);
    signal test_5_real : real         := to_real(test_4);

    signal test_exponent : t_exponent := get_exponent(tested_number);
    signal test_mantissa : t_mantissa := get_mantissa(tested_number);
    signal test_get_mantissa : real := get_mantissa(tested_number);

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


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
