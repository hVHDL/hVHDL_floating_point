LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

    use work.float_alu_pkg.all;
    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;

entity alu_lc_filter_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of alu_lc_filter_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 18e3;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal float_alu : float_alu_record := init_float_alu;
    signal voltage          : real := 0.0;
    signal inductor_current : real := 0.0;
    signal input_voltage : float_record := to_float(10.0);

    type lc_filter_record is record
        current           : float_record;
        capacitor_voltage : float_record;
        integrator_gain   : float_record;
        current_delta     : float_record;
        voltage_delta     : float_record;
        process_counter   : integer;
    end record;

    constant init_lc_filter : lc_filter_record := (to_float(0.0) ,
                               to_float(0.0)                     ,
                               to_float(0.0)                     ,
                               to_float(0.1)                     ,
                               to_float(0.0)                     ,
                               0                                 );

    signal lc_filter_model : lc_filter_record := init_lc_filter;



    procedure create_lc_filter_model
    (
        signal lc_filter_object : inout lc_filter_record;
        signal lc_filter_alu : inout float_alu_record;
        uin : in float_record
    ) is
        alias current           is  lc_filter_object.current;
        alias capacitor_voltage is  lc_filter_object.capacitor_voltage;
        alias integrator_gain   is  lc_filter_object.integrator_gain;
        alias current_delta     is  lc_filter_object.current_delta;
        alias voltage_delta     is  lc_filter_object.voltage_delta;
        alias process_counter   is  lc_filter_object.process_counter;
        alias alu               is  lc_filter_alu;
    begin
        CASE process_counter is
            WHEN 0 => 
                subtract(alu, uin, capacitor_voltage);
                process_counter <= process_counter + 1;
            WHEN 1 => 
                if add_is_ready(alu) then
                    multiply(alu, get_add_result(alu), to_float(0.5));
                    process_counter <= process_counter + 1;
                end if;
            WHEN 2 => 
                if multiplier_is_ready(alu) then
                    add(alu, get_multiplier_result(alu), current);
                    process_counter <= process_counter + 1;
                end if;
            WHEN 3 => 
                if add_is_ready(alu) then
                    current <= get_add_result(alu);
                    -- calculate capacitor voltage equation
                    multiply(alu, capacitor_voltage, to_float(0.01));
                    process_counter <= process_counter + 1;
                end if;
            WHEN 4 =>
                if multiplier_is_ready(alu) then
                    subtract(alu, current, get_multiplier_result(alu));
                    process_counter <= process_counter + 1;
                end if;
            WHEN 5 =>
                if add_is_ready(alu) then
                    multiply(alu, get_add_result(alu), to_float(0.5));
                    process_counter <= process_counter + 1;
                end if;
            WHEN 6 =>
                if multiplier_is_ready(alu) then
                    add(alu, get_multiplier_result(alu), capacitor_voltage);
                    process_counter <= process_counter + 1;
                end if;
            WHEN 7 =>
                if add_is_ready(alu) then
                    capacitor_voltage <= get_add_result(alu);
                    process_counter <= 0;
                end if;

            WHEN others => -- do nothing
        end CASE; --process_counter
        
    end create_lc_filter_model;

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
            create_float_alu(float_alu);
            create_lc_filter_model(lc_filter_model, float_alu, input_voltage);

            voltage <= to_real(lc_filter_model.capacitor_voltage);
            inductor_current <= to_real(lc_filter_model.current);

            if simulation_counter mod 12e3 = 0 then
                input_voltage <= -input_voltage;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
