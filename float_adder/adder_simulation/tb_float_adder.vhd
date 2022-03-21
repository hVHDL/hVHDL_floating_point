LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_to_real_conversions_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_float_adder is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_float_adder is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 5000;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal number1       : float_record := normalize(("0", to_signed(-6,8), (9 => '1', others => '0')));
    signal result        : float_record := zero;

------------------------------------------------------------------------
    signal adder : float_adder_record := init_adder;

------------------------------------------------------------------------
    signal res : unsigned(number1.mantissa'high+1 downto 0) :=
    (resize(number1.mantissa, 24) + resize(number1.mantissa, 24));

    signal leading_zeroes_in_res : integer := number_of_leading_zeroes(std_logic_vector(res));

    signal real_result : real := 0.0;

    signal random_value : real := 1.0;
    signal random_value1 : real := 1.0;
    signal test_random_sum : real := 1.0;
    signal difference : real := 0.0;

    signal max_value : real := -10.0;

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

        variable seed1 : integer := 1359;
        variable seed2 : integer := 1;
        variable rand_out : real := 0.0;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            uniform(seed1, seed2, rand_out);
            random_value <= rand_out*10.0e6;
            random_value1 <= random_value;

            create_adder(adder);

            if simulation_counter = 0 or adder_is_ready(adder) then
                request_add(adder, to_float(random_value1), to_float(random_value));
                test_random_sum <= random_value1 + random_value;
            end if;

            if adder_is_ready(adder) then
                result      <= normalize(get_result(adder));
                real_result <= to_real(normalize(get_result(adder)));

                difference <= (test_random_sum - to_real(normalize(get_result(adder))))/test_random_sum;
                if (test_random_sum - to_real(normalize(get_result(adder))))/test_random_sum > max_value then
                    max_value <= (test_random_sum - to_real(normalize(get_result(adder))))/test_random_sum;
                end if;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
