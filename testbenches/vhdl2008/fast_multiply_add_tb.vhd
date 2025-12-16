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
    constant simtime_in_clocks : integer   := 5000;

    signal simulation_counter : natural := 0;
    -------------------------------------------------------

    -----------------------
    -----------------------
    use ieee.float_pkg.all;
    -----------------------
    -----------------------
    function to_float32 (a : real) return float32 is
    begin
        return to_float(a, float32'high);
    end to_float32;
    -----------------------
    -----------------------
    use work.float_typedefs_generic_pkg.all;
    use work.float_to_real_conversions_pkg.all;
    -----------------------
    -----------------------
    function to_hfloat(a : real) return hfloat_record is
    begin
        return to_hfloat(a,8,24);
    end to_hfloat;
    -----------------------
    -----------------------
    -- simulation specific signals ----

    constant hfloat_zero : hfloat_record := to_hfloat(0.0);

    signal float32_conv_result : float32 := to_float32(0.0);

    use work.multiply_add_pkg.all;
    constant mpya_ref : mpya_subtype_record := create_mpya_typeref(hfloat_zero);

    signal mpya_in  : mpya_ref.mpya_in'subtype  := mpya_ref.mpya_in;
    signal mpya_out : mpya_ref.mpya_out'subtype := mpya_ref.mpya_out;

    signal mpya_result : hfloat_zero'subtype := hfloat_zero;
    signal real_mpya_result : real := 0.0;

    signal ref_a   : real := 0.0;
    signal ref_b   : real := 0.0;
    signal ref_add : real := 0.0;

    signal ref_pipeline     : real_vector(5 downto 0) := (others => 0.0);
    signal ref_a_pipeline   : real_vector(5 downto 0) := (others => 0.0);
    signal ref_b_pipeline   : real_vector(5 downto 0) := (others => 0.0);
    signal ref_add_pipeline : real_vector(5 downto 0) := (others => 0.0);

    use work.float_typedefs_generic_pkg.to_ieee_float32;

    signal testnum : integer := -1;

    signal rel_error : real := 0.0;
    signal max_rel_error : real := 0.0;

    signal rel_error_count : real := 0.0;
    signal total_count : real := 0.0;

    signal error_density : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        check(rel_error_count = 0.0, "error count " & real'image(rel_error_count));
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
        -----------------
        variable seed1 : positive :=1;
        variable seed2 : positive :=1;
        variable rand1 : real := 0.0;
        variable rand2 : real := 0.0;
        variable rand3 : real := 0.0;
        -----------------
        procedure multiply_add(signal self_in : out mpya_ref.mpya_in'subtype; a , b , c : real) is
        begin
            multiply_add(self_in 
            ,to_std_logic(to_hfloat(to_float32(a),hfloat_zero))
            ,to_std_logic(to_hfloat(to_float32(b),hfloat_zero))
            ,to_std_logic(to_hfloat(to_float32(c),hfloat_zero)));

            ref_a   <= a;
            ref_b   <= b;
            ref_add <= c;

            ref_a_pipeline(0)   <= a;
            ref_b_pipeline(0)   <= b;
            ref_add_pipeline(0) <= c;
        end multiply_add;
        -----------------
        -----------------
        variable v_rel_error : real := 0.0;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            uniform(seed1, seed2, rand1);
            uniform(seed1, seed2, rand2);
            uniform(seed1, seed2, rand3);

            init_multiply_add(mpya_in);

            ref_pipeline <= ref_pipeline(ref_pipeline'left-1 downto 0) & (ref_a*ref_b + ref_add);

            ref_a_pipeline   <= ref_a_pipeline(ref_a_pipeline'left-1 downto 0) & ref_a_pipeline(0);
            ref_b_pipeline   <= ref_b_pipeline(ref_b_pipeline'left-1 downto 0) & ref_b_pipeline(0);
            ref_add_pipeline <= ref_add_pipeline(ref_add_pipeline'left-1 downto 0) & ref_add_pipeline(0);

            if simulation_counter >= 300
            then
                multiply_add(mpya_in 
                    ,(rand1-0.5)*100.0
                    ,(rand2-0.5)*100.0
                    ,(rand3-0.5)*100.0
                );
            end if;

            --------------------------
            -- shift one off
            -- multiply_add(mpya_in 
            --     ,4.22786
            --     ,0.67742
            --     ,0.24717
            -- );
            -- multiply_add(mpya_in 
            --     ,4.0
            --     ,0.5
            --     ,0.25
            -- );
            -- multiply_add(mpya_in 
            --     ,4.0
            --     ,0.5
            --     ,1.0e3
            -- );
            -------------------------

            --
            CASE simulation_counter is
                WHEN 0  *10 => multiply_add(mpya_in , +1.0 , +1.0 , +2.1); --000
                WHEN 1  *10 => multiply_add(mpya_in , -1.0 , -1.0 , +2.1); --110
                WHEN 2  *10 => multiply_add(mpya_in , -1.0 , +1.0 , -2.1); --101
                WHEN 3  *10 => multiply_add(mpya_in , +1.0 , -1.0 , -2.1); --011

                WHEN 4  *10 => multiply_add(mpya_in , -1.0 , +1.0 , +2.1); --100
                WHEN 5  *10 => multiply_add(mpya_in , -1.0 , -1.0 , -2.1); --111
                WHEN 6  *10 => multiply_add(mpya_in , +1.0 , -1.0 , +2.1); --010
                WHEN 7  *10 => multiply_add(mpya_in , +1.0 , +1.0 , -2.1); --001

                WHEN 8  *10  => multiply_add(mpya_in , +1.0 , +1.0 , +0.1); --000
                WHEN 9  *10  => multiply_add(mpya_in , -1.0 , -1.0 , +0.1); --110
                WHEN 10  *10 => multiply_add(mpya_in , -1.0 , +1.0 , -0.1); --101
                WHEN 11  *10 => multiply_add(mpya_in , +1.0 , -1.0 , -0.1); --011

                WHEN 12  *10 => multiply_add(mpya_in , -1.0 , +1.0 , +0.1); --100
                WHEN 13  *10 => multiply_add(mpya_in , -1.0 , -1.0 , -0.1); --111
                WHEN 14  *10 => multiply_add(mpya_in , +1.0 , -1.0 , +0.1); --010
                WHEN 15  *10 => multiply_add(mpya_in , +1.0 , +1.0 , -0.1); --001

                WHEN 16  *10 => multiply_add(mpya_in , +1.0 , +1.0 , +1.1); --000
                WHEN 17  *10 => multiply_add(mpya_in , -1.0 , -1.0 , +1.1); --110
                WHEN 18  *10 => multiply_add(mpya_in , -1.0 , +1.0 , -1.1); --101
                WHEN 19  *10 => multiply_add(mpya_in , +1.0 , -1.0 , -1.1); --011

                WHEN 20  *10 => multiply_add(mpya_in , -1.0 , +1.0 , +1.1); --100
                WHEN 21  *10 => multiply_add(mpya_in , -1.0 , -1.0 , -1.1); --111
                WHEN 22  *10 => multiply_add(mpya_in , +1.0 , -1.0 , +1.1); --010
                WHEN 23  *10 => multiply_add(mpya_in , +1.0 , +1.0 , -1.1); --001

                WHEN 24  *10 => multiply_add(mpya_in , -1.0/128.0 , 8.0 , 4.0); --100
                WHEN 25  *10 => multiply_add(mpya_in , 1.0/8.0 , -1.0 , 4.0); --010
                WHEN 26  *10 => multiply_add(mpya_in , 1.0/8.0 , -8.0 , 0.0); --010

                WHEN 27  *10 => multiply_add(mpya_in , 1.0/8.0 , -8.0 , 0.0); --010
                WHEN 28  *10 => multiply_add(mpya_in , 18.970327 , 1.16203521 , -22.041984); --010
                --TODO, check with negative zero

            --         multiply_add(mpya_in 
            --         ,0.49498465168
            --         ,1.498465468
            --         ,2.0**(-2)
            --     );
            --     WHEN 2  *5 =>
            --         multiply_add(mpya_in 
            --         ,3.49498465168
            --         ,1.498465468
            --         ,2.0**(1)
            --     );
            --     WHEN 3  *5 =>
            --         multiply_add(mpya_in 
            --         ,0.48498465168
            --         ,1.498465468
            --         ,0.0
            --     );
            --     WHEN 4  *5 =>
            --         multiply_add(mpya_in 
            --         ,1.46498465168
            --         ,1.498465468
            --         ,0.500001
            --     );
            --     WHEN 5  *5 =>
            --         multiply_add(mpya_in 
            --         ,0.001
            --         ,0.001
            --         ,0.999999
            --     );
            --
            --     WHEN 6  *5 =>
            --         multiply_add(mpya_in 
            --         ,1000.0
            --         ,1000.0
            --         ,6.5e6
            --     );
            --
            --
                WHEN others => -- do nothing
            end CASE;


            --
            if mpya_is_ready(mpya_out)
            then
                testnum <= testnum + 1;

                mpya_result         <= to_hfloat(get_mpya_result(mpya_out), hfloat_zero);
                real_mpya_result    <= to_real(to_hfloat(get_mpya_result(mpya_out), hfloat_zero));
                float32_conv_result <= to_ieee_float32(to_hfloat(get_mpya_result(mpya_out), hfloat_zero));

                v_rel_error := (to_real(to_hfloat(get_mpya_result(mpya_out), hfloat_zero)) - ref_pipeline(4))/ref_pipeline(4);
                rel_error   <= v_rel_error;
                total_count <= total_count + 1.0;
                if abs(v_rel_error) > 1.0e-5 then
                    rel_error_count <= rel_error_count + 1.0;
                    error_density <= ((rel_error_count+1.0) / (total_count+1.0));
                end if;

            end if;

            if abs(rel_error) > 1.0e-5
            then
                max_rel_error <= abs(rel_error);
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
