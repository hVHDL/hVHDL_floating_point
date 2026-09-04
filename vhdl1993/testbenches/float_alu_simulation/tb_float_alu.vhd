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
    constant simtime_in_clocks : integer := 100;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal float_alu : float_alu_record := init_float_alu;
    signal test_multiplier : real := 0.0;
    signal add_result : float_record := to_float(0.0);
    signal add_result_real : real := 0.0;

    subtype float_array is real_vector(natural range 0 to 4);
    constant left : float_array := (
        5.2948629,
        37.2853628,
        21.7988346,
        15.3825920,
        1.9349673);

    constant right : float_array := (
        1.296720,
        3.238572,
        5.746730,
        -7.92395,
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

    signal int_to_float_sequencer : natural := 0;

    signal float_to_int_ready : boolean := false;
    signal int_to_float_ready : boolean := false;

    signal add_request_pipeline : std_logic_vector(alu_timing.add_pipeline_depth-1 downto 0);
    signal a : real_vector(add_request_pipeline'range) := (others => 0.0);
    signal b : real_vector(add_request_pipeline'range) := (others => 0.0);
    signal c : real_vector(add_request_pipeline'range) := (others => 0.0);

    signal mult_request_pipeline : std_logic_vector(alu_timing.mult_pipeline_depth-1 downto 0);

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
            add_request_pipeline <= add_request_pipeline(add_request_pipeline'left-1 downto 0) & '0';
            mult_request_pipeline <= mult_request_pipeline(mult_request_pipeline'left-1 downto 0) & '0';
            a <= a(a'left-1 downto 0) & 0.0;
            b <= b(a'left-1 downto 0) & 0.0;
            c <= c(a'left-1 downto 0) & 0.0;

            CASE simulation_counter is
                WHEN 3 => multiply(float_alu, to_float(left(0)), to_float(right(0)));
                          mult_request_pipeline(0) <= '1';
                WHEN 4 => multiply(float_alu, to_float(left(1)), to_float(right(1)));
                          mult_request_pipeline(0) <= '1';
                WHEN 5 => multiply(float_alu, to_float(left(2)), to_float(right(2)));
                          mult_request_pipeline(0) <= '1';
                WHEN 6 => multiply(float_alu, to_float(left(3)), to_float(right(3)));
                          mult_request_pipeline(0) <= '1';
                WHEN 7 => multiply(float_alu, to_float(left(4)), to_float(right(4)));
                          mult_request_pipeline(0) <= '1';
                WHEN others => -- do nothing
            end CASE;

            CASE simulation_counter is
                WHEN 3 => add(float_alu, to_float(left(0)), to_float(right(0)));
                          add_request_pipeline(0) <= '1';
                WHEN 4 => add(float_alu, to_float(left(1)), to_float(right(1)));
                          add_request_pipeline(0) <= '1';
                WHEN 5 => add(float_alu, to_float(left(2)), to_float(right(2)));
                          add_request_pipeline(0) <= '1';
                WHEN 6 => add(float_alu, to_float(left(3)), to_float(right(3)));
                          add_request_pipeline(0) <= '1';
                WHEN 7 => add(float_alu, to_float(left(4)), to_float(right(4)));
                          add_request_pipeline(0) <= '1';
                WHEN others => -- do nothing
            end CASE;

            check(add_is_ready(float_alu) = (add_request_pipeline(add_request_pipeline'left)='1'));
            check(multiplier_is_ready(float_alu) = (mult_request_pipeline(mult_request_pipeline'left)='1'));

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
                test_result := to_real(get_add_result(float_alu)) - add_results(add_index);
                check(abs(test_result) < 1.0e-3, "adder error is " & real'image(test_result));
            end if;

            if add_index >= right'length then
                if int_to_float_sequencer < right'length then
                    int_to_float_sequencer <= int_to_float_sequencer + 1;
                    convert_float_to_integer(float_alu, to_float(left(int_to_float_sequencer)), 24);
                    convert_integer_to_float(float_alu, int_to_float_sequencer, 0);
                end if;
            end if;
            float_to_int_ready <= float_to_int_is_ready(float_alu);
            int_to_float_ready <= int_to_float_is_ready(float_alu);

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
