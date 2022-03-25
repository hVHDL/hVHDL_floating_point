LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_multiplier_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_first_order_filter_pkg.all;

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
    constant simtime_in_clocks : integer := 6500;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----


    signal first_order_filter : first_order_filter_record := init_first_order_filter;
    signal adder : float_adder_record := init_adder;
    signal float_multiplier : float_multiplier_record := init_float_multiplier;
    signal filter_out : real := 0.0;
    signal u : float_record := to_float(1.0);


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
            create_float_multiplier(float_multiplier);
            create_first_order_filter(first_order_filter, float_multiplier, adder);

            if simulation_counter mod 100 = 0 then
                u <= -u;
            end if;


            if simulation_counter = 0 then
                request_float_filter(first_order_filter, to_float(1.0));
            end if;

            if float_filter_is_ready(first_order_filter) then
                request_float_filter(first_order_filter, to_float(1.0));
            end if;


            filter_out <= to_real(get_filter_output(first_order_filter));

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
