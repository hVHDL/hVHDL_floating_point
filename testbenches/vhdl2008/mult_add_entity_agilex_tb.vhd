LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    
library vunit_lib;
    context vunit_lib.vunit_context;

entity mult_add_entity_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of mult_add_entity_tb is

    signal simulation_running  : boolean;
    signal simulator_clock     : std_logic := '0';
    constant clock_per         : time      := 1 ns;
    constant clock_half_per    : time      := 0.5 ns;
    constant simtime_in_clocks : integer   := 150;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    use ieee.float_pkg.all;

    function to_float32 (a : real) return float32 is
    begin
        return to_float(a, float32'high);
    end to_float32;

    constant check_value : real := -84.5;

    signal float32_conv_result : float32 := to_float32(0.0);
    signal convref             : float32 := to_float32(check_value);

    constant float1 : float32 := to_float32(-84.5);
    constant float2 : float32 := to_float32(1.5);
    constant float3 : float32 := to_float32(84.5/2.0);

    use work.multiply_add_pkg.all;
    constant mpya_ref : mpya_subtype_record := create_mpya_typeref;

    signal mpya_in  : mpya_ref.mpya_in'subtype  := mpya_ref.mpya_in;
    signal mpya_out : mpya_ref.mpya_out'subtype := mpya_ref.mpya_out;

    signal mpya_result : float32 := (others => '0');
    signal real_mpya_result : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        check(convref = float32_conv_result);
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            init_multiply_add(mpya_in);

            --
            CASE simulation_counter is
                WHEN 0 =>
                    multiply_add(mpya_in 
                    ,to_slv(float1)
                    ,to_slv(float2)
                    ,to_slv(float3));

                WHEN others => -- do nothing
            end CASE;
            --
            if mpya_is_ready(mpya_out)
            then
                mpya_result         <= to_float(get_mpya_result(mpya_out));
                real_mpya_result    <= to_real(to_float(get_mpya_result(mpya_out)));
                -- float32_conv_result <= to_ieee_float32(to_hfloat(get_mpya_result(mpya_out), hfloat_zero));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
    dut : entity work.multiply_add(agilex)
    port map(
        simulator_clock
        ,mpya_in
        ,mpya_out);
------------------------------------------------------------------------
end vunit_simulation;
