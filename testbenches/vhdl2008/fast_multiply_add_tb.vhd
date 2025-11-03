LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    
library vunit_lib;
    context vunit_lib.vunit_context;

entity fast_mult_add_entity_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of fast_mult_add_entity_tb is

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

    use work.float_typedefs_generic_pkg.all;
    use work.float_to_real_conversions_pkg.all;

    function to_hfloat(a : real) return hfloat_record is
    begin
        return to_hfloat(a,8,24);
    end to_hfloat;

    constant hfloat_zero : hfloat_record := to_hfloat(0.0);

    signal float32_conv_result : float32 := to_float32(0.0);
    signal convref             : float32 := to_float32(check_value);
    signal conv_result         : hfloat_zero'subtype := hfloat_zero;

    constant float1 : hfloat_zero'subtype := to_hfloat(-84.5);
    constant float2 : hfloat_zero'subtype := to_hfloat(1.5);
    constant float3 : hfloat_zero'subtype := to_hfloat(84.5/2.0);

    use work.multiply_add_pkg.all;
    constant mpya_ref : mpya_subtype_record := create_mpya_typeref(hfloat_zero);

    signal mpya_in  : mpya_ref.mpya_in'subtype  := mpya_ref.mpya_in;
    signal mpya_out : mpya_ref.mpya_out'subtype := mpya_ref.mpya_out;

    signal mpya_result : hfloat_zero'subtype := hfloat_zero;
    signal real_mpya_result : real := 0.0;

    signal ref_a   : real := 0.0;
    signal ref_b   : real := 0.0;
    signal ref_add : real := 0.0;

    signal ref_pipeline : real_vector(2 downto 0) := (others => 0.0);

    use work.float_typedefs_generic_pkg.to_ieee_float32;

    signal testnum : integer := -1;

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
        procedure multiply_add(signal self_in : out mpya_ref.mpya_in'subtype; a,b,c : real) is
        begin
            multiply_add(self_in 
            ,to_std_logic(to_hfloat(a))
            ,to_std_logic(to_hfloat(b))
            ,to_std_logic(to_hfloat(c)));

            ref_a   <= a;
            ref_b   <= b;
            ref_add <= c;
            testnum <= testnum + 1;

        end multiply_add;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            init_multiply_add(mpya_in);

            ref_pipeline <= ref_pipeline(ref_pipeline'left-1 downto 0) & (ref_a*ref_b + ref_add);

            --
            CASE simulation_counter is
                WHEN 0  *5 =>
                    multiply_add(mpya_in 
                    ,0.49498465168
                    ,1.498465468
                    ,2.0**(-5)
                );
                WHEN 1  *5 =>
                    multiply_add(mpya_in 
                    ,0.49498465168
                    ,1.498465468
                    ,2.0**(-2)
                );
                WHEN 2  *5 =>
                    multiply_add(mpya_in 
                    ,3.49498465168
                    ,1.498465468
                    ,2.0**(1)
                );
                WHEN 3  *5 =>
                    multiply_add(mpya_in 
                    ,0.48498465168
                    ,1.498465468
                    ,0.0
                );
                WHEN 4  *5 =>
                    multiply_add(mpya_in 
                    ,0.46498465168
                    ,1.498465468
                    ,0.500001
                );
                WHEN 5  *5 =>
                    multiply_add(mpya_in 
                    ,0.0001
                    ,0.001
                    ,3.999999
                );

                WHEN 6  *5 =>
                    multiply_add(mpya_in 
                    ,1000.0
                    ,1000.0
                    ,6.5e9
                );


                WHEN others => -- do nothing
            end CASE;
            --
            if mpya_is_ready(mpya_out)
            then
                mpya_result         <= to_hfloat(get_mpya_result(mpya_out), hfloat_zero);
                real_mpya_result    <= to_real(to_hfloat(get_mpya_result(mpya_out), hfloat_zero));
                float32_conv_result <= to_ieee_float32(to_hfloat(get_mpya_result(mpya_out), hfloat_zero));
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
    dut : entity work.multiply_add(fast_hfloat)
    generic map(hfloat_zero)
    port map(
        simulator_clock
        ,mpya_in
        ,mpya_out);
------------------------------------------------------------------------
end vunit_simulation;
