LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_multiplier_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_first_order_filter_pkg.all;
    use work.float_alu_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity float_filter_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of float_filter_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 6500;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal u : float_record := to_float(1.0);

    signal float_alu : float_alu_record := init_float_alu;
    signal alu_filter : first_order_filter_record := init_first_order_filter;
    signal alu_filter_out : real := 0.0;


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

    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_float_alu(float_alu);
            create_first_order_filter(alu_filter, float_alu, to_float(0.04));

            if simulation_counter mod 100 = 0 then
                u <= -u;
            end if;


            if simulation_counter = 0 then
                request_float_filter(alu_filter, to_float(8.0));
            end if;

            if float_filter_is_ready(alu_filter) then
                request_float_filter(alu_filter, to_float(8.0));
            end if;


            alu_filter_out <= to_real(get_filter_output(alu_filter));

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
