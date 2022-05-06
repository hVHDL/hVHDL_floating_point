LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_alu_pkg.all;
    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity float_alu_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of float_alu_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal float_alu : float_alu_record := init_float_alu;
    signal test_multiplier : real := 0.0;
    signal add_result : float_record := to_float(0.0);
    signal add_result_real : real := 0.0;

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

            create_float_alu(float_alu);
            CASE simulation_counter is
                WHEN 3 => multiply(float_alu, to_float(5.0), to_float(5.0));
                WHEN 4 => multiply(float_alu, to_float(6.0), to_float(5.0));
                WHEN 5 => multiply(float_alu, to_float(7.0), to_float(5.0));
                WHEN 6 => multiply(float_alu, to_float(8.0), to_float(-8.0));
                WHEN 7 => multiply(float_alu, to_float(9.0), to_float(-9.0));
                WHEN others => -- do nothing
            end CASE;

            CASE simulation_counter is
                WHEN 3 => add(float_alu, to_float(5.0), to_float(5.0));
                WHEN 4 => add(float_alu, to_float(6.0), to_float(5.0));
                WHEN 5 => add(float_alu, to_float(7.0), to_float(5.0));
                WHEN 6 => add(float_alu, to_float(8.1), to_float(-8.0));
                WHEN 7 => add(float_alu, to_float(9.0), to_float(-9.1));
                WHEN others => -- do nothing
            end CASE;

            if multiplier_is_ready(float_alu) then
                test_multiplier <= to_real(get_multiplier_result(float_alu));
            end if;

            if add_is_ready(float_alu) then
                add_result      <= get_add_result(float_alu);
                add_result_real <= to_real(get_add_result(float_alu));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
