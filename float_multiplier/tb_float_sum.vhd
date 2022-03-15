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

    signal number2       : float_record :=("0", to_signed(0,8), (22 => '1', others => '0'));
    signal number1       : float_record :=("0", to_signed(22,8), (22 => '1', others => '0'));
    signal result        : float_record := zero;

------------------------------------------------------------------------
------------------------------------------------------------------------
    signal test_denormalization : float_record := denormalize_float(number1, 4);

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
                    if number2.exponent > number1.exponent then
                        result <= number2 + denormalize_float(number1, to_integer(number2.exponent));
                    else
                        result <= number1 + denormalize_float(number2, to_integer(number1.exponent));
                    end if;
                WHEN 1 => 

                WHEN others => -- do nothing
            end case;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
