LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_to_real_functions_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity fp2real_functions_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of fp2real_functions_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    constant tested_number : real := 8.0;
    signal test_4      : float_record := to_float(tested_number);
    signal test_4_real : real         := to_real(test_4);

    signal test_5      : float_record := to_float(0.0002);
    signal test_5_real : real         := to_real(test_4);

    signal test_exponent : t_exponent := get_exponent(tested_number);
    signal test_mantissa : t_mantissa := get_mantissa(tested_number);
    signal test_get_mantissa : real := get_mantissa(tested_number);

    function real_2_float
    (
        number : real
    )
    return float_record
    is
        variable retval : float_record := zero;
        variable temp : real;
        variable temp2 : real;
    begin

        if number < 0.0 then
            retval.sign := '1';
        else
            retval.sign := '0';
        end if;

        temp := abs(number);
        for i in t_exponent'range loop
            if temp >= 2.0**(i) then
                retval.exponent(i) := '1';
                temp := temp - 2.0**(i);
            else
                retval.exponent(i) := '0';
            end if;
        end loop;

        temp2 := number / (2.0**real(to_integer(retval.exponent)));

        for i in t_mantissa'range loop
            if temp2 >= 2.0**(t_mantissa'high - i) then
                retval.mantissa(i) := '1';
                temp2 := temp2 - 2.0**(t_mantissa'high - i);
            else
                retval.mantissa(i) := '0';
            end if;
        end loop;

        return retval;
    end real_2_float;

    signal testi1 : float_record := real_2_float(4.5);
    signal testi2 : float_record := real_2_float(85.846);

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


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
