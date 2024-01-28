LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_alu_pkg.all;
    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;

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

    type float_array is array (natural range 0 to 4) of real;
    constant left : float_array := (
        5.2948629,
        6.2853628,
        7.7988346,
        8.3825920,
        9.9349673);

    constant right : float_array := (
        5.296720,
        5.238572,
        5.746730,
        -8.92395,
        -9.10365);

    function multiplier_result_values return float_array
    is
        variable retval : float_array;
    begin
        for i in left'range loop
            retval(i) := left(i) * right(i);
        end loop;
        
        return retval;
        
    end multiplier_result_values;

    constant multiply_results : float_array := multiplier_result_values;

    function adder_result_values return float_array
    is
        variable retval : float_array;
    begin
        for i in left'range loop
            retval(i) := left(i) + right(i);
        end loop;
        
        return retval;
        
    end adder_result_values;

    constant add_results : float_array := adder_result_values;

    signal mult_index : natural := 0;
    signal add_index : natural := 0;


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

        variable test_result : real := 0.0;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_float_alu(float_alu);
            CASE simulation_counter is
                WHEN 3 => multiply(float_alu, to_float(left(0)), to_float(right(0)));
                WHEN 4 => multiply(float_alu, to_float(left(1)), to_float(right(1)));
                WHEN 5 => multiply(float_alu, to_float(left(2)), to_float(right(2)));
                WHEN 6 => multiply(float_alu, to_float(left(3)), to_float(right(3)));
                WHEN 7 => multiply(float_alu, to_float(left(4)), to_float(right(4)));
                WHEN others => -- do nothing
            end CASE;

            CASE simulation_counter is
                WHEN 3 => add(float_alu, to_float(left(0)), to_float(right(0)));
                WHEN 4 => add(float_alu, to_float(left(1)), to_float(right(1)));
                WHEN 5 => add(float_alu, to_float(left(2)), to_float(right(2)));
                WHEN 6 => add(float_alu, to_float(left(3)), to_float(right(3)));
                WHEN 7 => add(float_alu, to_float(left(4)), to_float(right(4)));
                WHEN others => -- do nothing
            end CASE;

            if multiplier_is_ready(float_alu) then
                mult_index      <= mult_index + 1;
                test_multiplier <= to_real(get_multiplier_result(float_alu));
                test_result := to_real(get_multiplier_result(float_alu)) - multiply_results(mult_index);
                check(abs(test_result) < 1.0e-3, "multiply error is " & real'image(test_result));
            end if;

            if add_is_ready(float_alu) then
                add_result      <= get_add_result(float_alu);
                add_result_real <= to_real(get_add_result(float_alu));

                add_index <= add_index + 1;
                test_result := to_real(get_add_result(float_alu)) - add_results(mult_index);
                check(abs(test_result) < 1.0e-3, "adder error is " & real'image(test_result));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
