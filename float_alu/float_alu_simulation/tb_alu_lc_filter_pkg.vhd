LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

    use work.float_alu_pkg.all;
    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;

entity alu_lc_filter_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of alu_lc_filter_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 18e3;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal alu : float_alu_record := init_float_alu;

    signal current           : float_record := to_float(0.0);
    signal capacitor_voltage : float_record := to_float(0.0);
    signal input_voltage     : float_record := to_float(0.0);
    signal integrator_gain   : float_record := to_float(0.1);
    signal current_delta     : float_record := to_float(0.0);
    signal voltage_delta     : float_record := to_float(0.0);

    signal process_counter : integer := 0;
    signal process_counter1 : integer := 0;

    signal uin : float_record := to_float(13543.0245024702e12);
    signal voltage : real := 0.0;
    signal inductor_current : real := 0.0;

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
            create_float_alu(alu);

            CASE process_counter is
                WHEN 0 => 
                    subtract(alu, uin, capacitor_voltage);
                    process_counter <= process_counter + 1;
                WHEN 1 => 
                    if add_is_ready(alu) then
                        multiply(alu, get_add_result(alu), to_float(0.5));
                        process_counter <= process_counter + 1;
                    end if;
                WHEN 2 => 
                    if multiplier_is_ready(alu) then
                        add(alu, get_multiplier_result(alu), current);
                        process_counter <= process_counter + 1;
                    end if;
                WHEN 3 => 
                    if add_is_ready(alu) then
                        current <= get_add_result(alu);
                        -- calculate capacitor voltage equation
                        multiply(alu, capacitor_voltage, to_float(0.1));
                        process_counter <= process_counter + 1;
                    end if;
                WHEN 4 =>
                    if multiplier_is_ready(alu) then
                        subtract(alu, current, get_multiplier_result(alu));
                        process_counter <= process_counter + 1;
                    end if;
                WHEN 5 =>
                    if add_is_ready(alu) then
                        multiply(alu, get_add_result(alu), to_float(0.5));
                        process_counter <= process_counter + 1;
                    end if;
                WHEN 6 =>
                    if multiplier_is_ready(alu) then
                        add(alu, get_multiplier_result(alu), capacitor_voltage);
                        process_counter <= process_counter + 1;
                    end if;
                WHEN 7 =>
                    if add_is_ready(alu) then
                        capacitor_voltage <= get_add_result(alu);
                        process_counter <= 0;
                    end if;

                WHEN others => -- do nothing
            end CASE; --process_counter

            voltage <= to_real(capacitor_voltage);
            inductor_current <= to_real(current);

            if simulation_counter mod 6000 = 0 then
                uin <= -uin;
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
