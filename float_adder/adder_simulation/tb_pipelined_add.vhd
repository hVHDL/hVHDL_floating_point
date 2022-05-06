LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.denormalizer_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;
    use work.float_adder_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity pipelined_add_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of pipelined_add_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal adder : float_adder_record := init_adder;
    signal result : real := 0.0;

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
            CASE simulation_counter is
                WHEN 0 => pipelined_add(adder, to_float(1.5), to_float(0.5));
                WHEN 1 => pipelined_add(adder, to_float(2.5), to_float(0.5));
                WHEN 2 => pipelined_add(adder, to_float(-1.5), to_float(0.5));
                WHEN 3 => pipelined_subtract(adder, to_float(-1.5), to_float(0.5));
                WHEN others => -- do nothing
            end CASE;

            if adder_is_ready(adder) then
                result <= to_real(get_result(adder));
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
