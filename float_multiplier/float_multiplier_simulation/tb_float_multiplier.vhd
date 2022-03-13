LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_multiplier_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_float_multiplier is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_float_multiplier is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal test_1 : float_record := float(0.57);
    signal test_2 : float_record := float(3.0);
    signal test_3 : float_record := float(-3.0);

    signal test_mantissa : unsigned(22 downto 0) := get_mantissa(1.3);
    signal test_real : real := 1.5-floor(1.5);

    signal test_exponent : t_exponent := get_exponent(-2.5);
    signal real_exponent : real := log2(2.0**(-15)*1.999999999999999);

    signal real_result : real := to_real(test_1);


------------------------------------------------------------------------
    function "+"
    (
        left, right : float_record
    )
    return float_record
    is
        variable result : float_record := float(1.0);
        variable result_mantissa : unsigned(t_mantissa'length+1 downto 0);
    begin
        if left.exponent = right.exponent then
            result.mantissa := left.mantissa + right.mantissa;
            result.exponent := left.exponent + to_integer(result_mantissa(result_mantissa'left downto result_mantissa'left-2));
        end if;

        return result;

    end "+";
------------------------------------------------------------------------


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

            test_3 <= test_1 + test_1;
            real_result <= to_real(test_3);

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
