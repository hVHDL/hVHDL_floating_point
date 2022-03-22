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

entity tb_subtract is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_subtract is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal test1 : float_record := to_float(0.0);
    signal test2 : float_record := to_float(2.0);

    signal signed_mantissa : signed(mantissa_length+1 downto 0) := get_signed_mantissa(test2);

    signal testjee : signed(t_mantissa'length+1 downto 0) := get_signed_mantissa(to_float(-2.5));

    signal test3 : float_record := to_float(2.5) + to_float(-3.0);
    signal test3_real : real := to_real(test3);


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
