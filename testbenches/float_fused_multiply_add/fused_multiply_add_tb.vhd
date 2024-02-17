LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.float_alu_pkg.all;
    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_multiplier_pkg.all;
    use work.normalizer_pkg.all;
    use work.denormalizer_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity fused_multiply_add_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of fused_multiply_add_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal float_alu : float_alu_record := init_float_alu;
    signal test_multiplier : real := 0.0;
    signal add_result : float_record := to_float(0.0);
    signal add_result_real : real := 0.0;

    type float_array is array (natural range 0 to 4) of real;
    constant left : float_array := (
        5.2948629,
        37.2853628,
        21.7988346,
        15.3825920,
        1.9349673);
------------------------------------------------------------------------
    constant right : float_array := (
        1.296720,
        3.238572,
        5.746730,
        -7.92395,
        -9.10365);
------------------------------------------------------------------------

    function multiplier_result_values return float_array
    is
        variable retval : float_array;
    begin
        for i in left'range loop
            retval(i) := left(i) * right(i);
        end loop;
        
        return retval;
        
    end multiplier_result_values;
------------------------------------------------------------------------

    constant multiply_results : float_array := multiplier_result_values;
------------------------------------------------------------------------

    function adder_result_values return float_array
    is
        variable retval : float_array;
    begin
        for i in left'range loop
            retval(i) := left(i) + right(i);
        end loop;
        
        return retval;
        
    end adder_result_values;
------------------------------------------------------------------------

    constant add_results : float_array := adder_result_values;
------------------------------------------------------------------------

    signal mult_index : natural := 0;
    signal add_index : natural := 0;

    alias self is float_alu;

    signal mac_result : real := 0.0;

    signal request_pipeline : std_logic_vector(alu_timing.madd_pipeline_depth-1 downto 0);
    type real_array is array (natural range <>) of real;
    signal a : real_array(request_pipeline'range) := (others => 0.0);
    signal b : real_array(request_pipeline'range) := (others => 0.0);
    signal c : real_array(request_pipeline'range) := (others => 0.0);


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

        variable test_result : real := 0.0;

        procedure test_fmadd
        (
            left, right, add : real
        ) is
        begin
            fmac(float_alu, to_float(left), to_float(right), to_float(add));
            request_pipeline(0) <= '1';
            a(0) <= left;
            b(0) <= right;
            c(0) <= add;
            
        end test_fmadd;
        procedure test_fmadd
        (
            left, right, add : integer
        ) is
        begin
            test_fmadd(real(left), real(right), real(add));
        end test_fmadd;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_float_alu(self);
            request_pipeline <= request_pipeline(request_pipeline'left-1 downto 0) & '0';
            a <= a(a'left-1 downto 0) & 0.0;
            b <= b(a'left-1 downto 0) & 0.0;
            c <= c(a'left-1 downto 0) & 0.0;

            CASE simulation_counter is
                WHEN 2 => test_fmadd(1.9273592, 3.2835729, -5.2935);
                WHEN 3 => test_fmadd(1,2,3);
                WHEN 4 => test_fmadd(2.0,3.0,-4.0);
                WHEN 5 => test_fmadd(10.0,-10.0,100.1);
                WHEN 9 => test_fmadd(-10.0,10.0,-100.1);
                WHEN others => -- do nothing
            end CASE;

            check(add_is_ready(float_alu) = (request_pipeline(request_pipeline'left) = '1'));

            if add_is_ready(float_alu) then
                mac_result <= to_real(get_add_result(float_alu));
                check(abs(to_real(get_add_result(float_alu)) - (a(a'left)*b(b'left) + c(c'left))) < 1.0e-5, "error was " & real'image(to_real(get_add_result(float_alu)) - (a(a'left)*b(b'left) + c(c'left))));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
