LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.float_multiplier_pkg.all;
    use work.float_to_real_conversions_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;

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

------------------------------------------------------------------------
    constant left_multiplier : real := 3.0;
    constant right_multiplier : real := 2.5/1000.0;
    signal float1 : float_record := to_float(left_multiplier);
    signal float2 : float_record := to_float(right_multiplier);
    signal float_resutl : float_record := normalize(float1 * (float2));

    signal real_result      : real := to_real(float_resutl);
    signal float_reference  : real := left_multiplier*right_multiplier;
    signal multiplier_error : real := 1.0-abs(real_result/float_reference);
------------------------------------------------------------------------

------------------------------------------------------------------------
begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        check(1.0-abs(real_result/float_reference) < 1.0e-3, "float multiplier error higher than 1.0e-3");
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
