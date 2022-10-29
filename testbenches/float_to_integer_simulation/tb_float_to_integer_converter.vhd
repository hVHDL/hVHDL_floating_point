LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.denormalizer_pkg.all;

entity tb_float_to_integer_converter is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_float_to_integer_converter is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_period : time := 1 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal denormalizer : denormalizer_record := init_denormalizer;
    signal result_index : integer := 0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_period;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_denormalizer(denormalizer);

            CASE simulation_counter is 
                WHEN 0 => request_scaling(denormalizer , to_float(1.0)   , 12);
                WHEN 1 => request_scaling(denormalizer , to_float(5.0)   , 12);
                WHEN 2 => request_scaling(denormalizer , to_float(-11.0) , 12);
                WHEN 3 => request_scaling(denormalizer , to_float(-0.0)  , 12);
                WHEN 4 => request_scaling(denormalizer , to_float(0.0)   , 12);
                WHEN others => -- do nothing
            end CASE;

            if denormalizer_is_ready(denormalizer) then
                result_index <= result_index + 1;
                CASE result_index is 
                    WHEN 0 => check(get_integer(denormalizer) = 4096     , "fail");
                    WHEN 1 => check(get_integer(denormalizer) = 5*4096   , "fail");
                    WHEN 2 => check(get_integer(denormalizer) = -11*4096 , "fail");
                    WHEN 3 => check(get_integer(denormalizer) = 0        , "fail");
                    WHEN 4 => check(get_integer(denormalizer) = 0        , "fail");
                    WHEN others => -- do nothing
                end CASE;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
