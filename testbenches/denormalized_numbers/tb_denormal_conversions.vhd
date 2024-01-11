LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.float_to_real_conversions_pkg.all;
    use work.float_type_definitions_pkg.all;

entity denormal_conversions_tb is
  generic (runner_cfg : string);
end;
architecture vunit_simulation of denormal_conversions_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 80;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant test_result  : real := 0.00055435133453;
    constant test         : real := to_real(to_float(to_std_logic_vector(to_float(test_result))));
    signal should_be_zero : real := test_result - test;
    signal testi          : real := test;


    signal counter : real := 1.0;
    signal test_counter : real := 1.0;
    signal float_counter : float_record := to_float(1.0);
    signal counter2 : real := 0.0;
    signal test_counter2 : real := 0.0;
    signal float_counter2 : float_record := to_float(0.0);

    signal test_add_saturation : t_exponent := (others => '0');
------------------------------------------------------------------------
    function saturated_add 
    (
        left, right : signed
    ) 
    return signed 
    is
        variable retval : signed(right'length - 1 downto 0);
    begin

        retval := left + right;

        if left(left'high) = '1' and right(right'high) = '1' and retval(retval'high) = '0' then
            retval(retval'high) := '1';
            retval(retval'high-1 downto 0) := (others=>'0');

        elsif left(left'high) = '0' and right(right'high) = '0' and retval(retval'high) = '1' then 
            retval(retval'high) := '0';
            retval(retval'high-1 downto 0) := (others=>'1');
        end if;

        return retval;

    end saturated_add; 
------------------------------------------------------------------------

    function "+"
    (
        left, right : signed 
    )
    return signed
    is
    begin
        return saturated_add(left,right);
    end "+";

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(abs(should_be_zero) < 0.01, "got " & real'image(should_be_zero));
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            counter       <= counter * 0.90;
            test_counter  <= to_real(to_float(counter * 0.90));
            float_counter <= to_float(counter * 0.90);

            counter2      <= counter2 - 2.0;
            test_counter2 <= to_real(to_float(counter2 - 2.0));
            float_counter2 <= to_float(counter2 - 2.0);

            if simulation_counter < 10 then
                test_add_saturation <= test_add_saturation + to_signed(7, test_add_saturation'length);
            else
                test_add_saturation <= test_add_saturation + to_signed(-8, test_add_saturation'length);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
