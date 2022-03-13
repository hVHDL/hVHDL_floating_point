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

    signal test_1_real : real := 1.57;
    signal test_1 : float_record := to_float(1.57);
    signal test_2 : float_record := to_float(3.0);
    signal test_3 : float_record := to_float(-3.0);

    signal test_mantissa : unsigned(22 downto 0) := get_mantissa(1.3);
    signal test_real : real := 1.5-floor(1.5);

    signal test_exponent : t_exponent := get_exponent(-2.5);
    signal real_exponent : real := log2(2.0**(-15)*1.999999999999999);

    signal real_result : real := to_real(test_1);

    signal sum_result_float : float_record := to_float(0.0);
    signal sum_result_real : real := 0.0;
    signal sum_result_reference : real := 0.57+ 0.57;
    signal float_reference : float_record := (to_float(0.57+ 0.57));

------------------------------------------------------------------------
    signal test_normalization : float_record := 
        normalize((sign     => "0"             ,
                   exponent => (others => '0') ,
                   mantissa => (
                                22 => '0',
                                8 => '0',
                                12 => '0',
                                others => '1'
                                )));
------------------------------------------------------------------------
    function "+"
    (
        left, right : float_record
    )
    return float_record
    is
        constant mantissa_left : integer := t_mantissa'length;
        variable result : float_record := to_float(0.0);
        variable result_mantissa : unsigned(t_mantissa'length downto 0);
    begin
        if left.exponent = right.exponent then
            result_mantissa := resize(left.mantissa,t_mantissa'length+1) + resize(right.mantissa,t_mantissa'length+1);
            result.exponent := left.exponent;
            result.mantissa := result_mantissa(result.mantissa'left+1 downto 1);
        end if;

        return normalize(result);

    end "+";
------------------------------------------------------------------------
    signal test_sum_mantissa : unsigned(t_mantissa'length downto 0) := resize(test_1.mantissa,t_mantissa'length+1) + resize(test_1.mantissa,t_mantissa'length+1);


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

            sum_result_reference <= test_1_real+test_1_real;
            sum_result_float <= (test_1 + test_1);
            sum_result_real <= to_real(sum_result_float);
            real_result <= to_real(float_reference);

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
