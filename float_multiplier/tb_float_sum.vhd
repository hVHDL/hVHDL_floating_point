LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_multiplier_pkg.all;
    use work.float_arithmetic_operations_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_float_sum is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_float_sum is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant test_float : float_record := ("0", to_signed(-5,8), (22 => '0', others => '1'));
    signal number1      : float_record := test_float;
    signal number2      : float_record := test_float;
    signal result       : float_record := zero;

------------------------------------------------------------------------
------------------------------------------------------------------------
    signal test_denormalization : float_record := denormalize_float(test_float, 4);

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

            CASE simulation_counter is
                WHEN 0 => 
                    result <= number1 + number2;
                WHEN 1 => 

                WHEN others => -- do nothing
            end case;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
