LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_multiplier_pkg.all;
    use work.float_adder_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_float_filter is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_float_filter is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 1500;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal filter_counter : integer := 0; 
    signal y : float_record := zero;
    signal filter_gain : float_record := to_float(0.05);

    signal adder : float_adder_record := init_adder;
    signal filter_out : real := 0.0;

    signal u : float_record := to_float(-1.0);

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

            create_adder(adder);

            if simulation_counter mod 100 = 0 then
                u <= -u;
            end if;

            CASE filter_counter is
                WHEN 0 => 
                    request_subtraction(adder, to_float(to_real(u) + 1.0), y);
                    filter_counter <= filter_counter + 1;
                WHEN 1 =>
                    if adder_is_ready(adder) then
                        request_add(adder, get_result(adder)*filter_gain, y);
                        filter_counter <= filter_counter + 1;
                    end if;
                WHEN 2 => 
                    if adder_is_ready(adder) then
                        y <= get_result(adder);
                        filter_out <= to_real(get_result(adder));
                        filter_counter <= filter_counter + 1;
                    end if;
                WHEN others =>  -- filter is ready
                    filter_counter <= 0;
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
