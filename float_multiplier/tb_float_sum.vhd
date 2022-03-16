LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_multiplier_pkg.all;
    use work.float_arithmetic_operations_pkg.all;
    use work.float_adder_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_float_sum is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_float_sum is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal number1       : float_record :=("0", to_signed(-6,8), (22 => '1', others => '0'));
    signal result        : float_record := zero;

------------------------------------------------------------------------
    signal adder : float_adder_record := init_adder;

------------------------------------------------------------------------
    signal res : unsigned(number1.mantissa'high+1 downto 0) :=
    (resize(number1.mantissa, 24) + resize(number1.mantissa, 24));

    signal leading_zeroes_in_res : integer := number_of_leading_zeroes(std_logic_vector(res));

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

            if simulation_counter = 0 then
                request_add(adder, number1, number1);
            end if;

            if adder_is_ready(adder) then
                request_add(adder, get_result(adder), get_result(adder));
                result <= get_result(adder);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
