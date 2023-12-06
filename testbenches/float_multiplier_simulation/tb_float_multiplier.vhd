LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_type_definitions_pkg.all;
    use work.normalizer_pkg.normalize;
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
    constant simtime_in_clocks : integer := 500;

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
    signal float_multiplier : float_multiplier_record := init_float_multiplier;
    signal multiplier_result : real := 0.0;
    signal multiplier_reference_result : real := 0.0;

    signal float_multiplier2 : float_multiplier_record := init_float_multiplier;
    signal float_test : float_record := to_float(1.0);
    signal real_test : real := 0.0;

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

            create_float_multiplier(float_multiplier);
            create_float_multiplier(float_multiplier2);

            CASE simulation_counter is
                WHEN 3 => request_float_multiplier(float_multiplier, to_float(1.5), to_float(1.0));
                WHEN 4 => request_float_multiplier(float_multiplier, to_float(2.5), to_float(-1.0));
                WHEN 5 => request_float_multiplier(float_multiplier, to_float(3.5), to_float(1.0));
                WHEN 7 => request_float_multiplier(float_multiplier, to_float(4.5), to_float(-1.0));
                WHEN 8 => request_float_multiplier(float_multiplier, to_float(5.5), to_float(-1.0));
                WHEN others => -- do nothing
            end CASE;

            if simulation_counter = 0 then
                request_float_multiplier(float_multiplier2 , float_test , to_float(1.1));
            end if;

            if float_multiplier_is_ready(float_multiplier2) then
                request_float_multiplier(float_multiplier2 , float_test , to_float(1.1));
                float_test <= get_multiplier_result(float_multiplier2);
                real_test <= to_real(get_multiplier_result(float_multiplier2));
            end if;

            if float_multiplier_is_ready(float_multiplier) then
                multiplier_result <= to_real(get_multiplier_result(float_multiplier));
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
