LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.normalizer_pkg.all;

entity tb_integer_to_float_simulation_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_integer_to_float_simulation_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal normalizer : normalizer_record := init_normalizer;

    signal float_result : float_record := zero;
    signal real_result : real := 0.0;
    signal result_index : integer := 0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_normalizer(normalizer);

            CASE simulation_counter is
                WHEN 0 => to_float(normalizer, 65536, 16);
                WHEN 1 => to_float(normalizer, -65536, 16);
                WHEN 2 => to_float(normalizer, integer(2.0**16*3.2), 16);
                WHEN 3 => to_float(normalizer, integer(2.0**15*3.2), 15);
                WHEN others => -- do nothing
            end CASE;

            if normalizer_is_ready(normalizer) then
                float_result <= get_normalizer_result(normalizer);
                real_result  <= to_real(get_normalizer_result(normalizer));
                result_index <= result_index + 1;
                CASE result_index is
                    WHEN 0 => check(abs(to_real(get_normalizer_result(normalizer)) - 1.0) < 0.001, "fail");
                    WHEN 1 => check(abs(to_real(get_normalizer_result(normalizer)) + 1.0) < 0.001, "fail");
                    WHEN 2 => check(abs(to_real(get_normalizer_result(normalizer)) - 3.2) < 0.001, "fail");
                    WHEN 3 => check(abs(to_real(get_normalizer_result(normalizer)) - 3.2) < 0.001, "fail");
                    WHEN others => -- do nothing
                end CASE;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
