LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    
library vunit_lib;
    context vunit_lib.vunit_context;

entity fast_mult_add_pkg_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of fast_mult_add_pkg_tb is

    signal simulation_running  : boolean;
    signal simulator_clock     : std_logic := '0';
    constant clock_per         : time      := 1 ns;
    constant clock_half_per    : time      := 0.5 ns;
    constant simtime_in_clocks : integer   := 1500;

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

    constant check_value : real := -84.5;
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
    signal ref_a_pipeline : real_vector(4 downto 0) := (others => 0.0);
    signal ref_b_pipeline : real_vector(4 downto 0) := (others => 0.0);
    signal ref_add_pipeline : real_vector(4 downto 0) := (others => 0.0);

    use work.float_typedefs_generic_pkg.to_ieee_float32;
    use work.fast_hfloat_pkg.all;

    signal in1 : hfloat_zero'subtype := hfloat_zero;
    signal in2 : hfloat_zero'subtype := hfloat_zero;
    signal in3 : hfloat_zero'subtype := hfloat_zero;

    signal in1_0: hfloat_zero'subtype := hfloat_zero;
    signal in2_0: hfloat_zero'subtype := hfloat_zero;
    signal in3_0: hfloat_zero'subtype := hfloat_zero;

    signal mult : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal add : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal mult_add : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal test1 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');

    signal hfloat_result : hfloat_zero'subtype := hfloat_zero;

    function max(a,b : signed) return signed is
        variable retval : a'subtype;
    begin
        if a > b then
            retval := a;
        else
            retval := b;
        end if;
        return retval;
    end max;

    function shift(a : unsigned; b : integer) return unsigned is
        variable retval : a'subtype;
    begin
        if b >= 0 then
            retval := shift_left(a,b);
        else
            retval := shift_right(a,-b);
        end if;

        return retval;
    end shift;

    use work.normalizer_generic_pkg.normalize;

    signal result_shift : integer := 0;
    signal result_shift1 : integer := 0;
    constant guard_bits : natural := 1;

    signal result_error : real := 0.0;

    signal testi2 : hfloat_zero'subtype := 
    (sign => '0', exponent => (7 downto 0 => x"00"), mantissa => (23 downto 0 => x"000000"));

    function to_hfloat(sign : std_logic := '0' ; exponent : integer ; mantissa : std_logic_vector(23 downto 0))
    return hfloat_record is
        variable retval : hfloat_zero'subtype;
    begin
        retval := (sign => '0', exponent => (7 downto 0 => to_signed(exponent,8)), mantissa => unsigned(mantissa));
        return retval;

    end to_hfloat;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        -- check(convref = float32_conv_result);
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
        variable seed2 : positive :=2;
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
        procedure multiply_add(signal self_in : out mpya_ref.mpya_in'subtype; a , b , c : hfloat_record) is
        begin
            multiply_add(self_in 
            ,to_std_logic(a)
            ,to_std_logic(b)
            ,to_std_logic(c));

            ref_a   <= to_real(a);
            ref_b   <= to_real(b);
            ref_add <= to_real(c);

            ref_a_pipeline(0)   <= to_real(a);
            ref_b_pipeline(0)   <= to_real(b);
            ref_add_pipeline(0) <= to_real(c);
        end multiply_add;
        -----------------


    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            uniform(seed1, seed2, rand1);
            uniform(seed1, seed2, rand2);
            uniform(seed1, seed2, rand3);

            init_multiply_add(mpya_in);

            ref_pipeline <= ref_pipeline(ref_pipeline'left-1 downto 0) & (ref_a*ref_b + ref_add);

            ref_a_pipeline   <= ref_a_pipeline(ref_a_pipeline'left-1 downto 0) & ref_a;
            ref_b_pipeline   <= ref_b_pipeline(ref_b_pipeline'left-1 downto 0) & ref_b;
            ref_add_pipeline <= ref_add_pipeline(ref_add_pipeline'left-1 downto 0) & ref_add;

            --------------------------
            CASE simulation_counter is
                WHEN 5 => 
                    multiply_add(mpya_in 
                        ,0.2782
                        ,0.0866
                        ,0.1332
                    );
                WHEN 15 => 
                    multiply_add(mpya_in 
                        ,0.9998
                        ,0.0235
                        ,0.6680
                    );
                WHEN 25 => 
                    multiply_add(mpya_in 
                        ,0.02725
                        ,0.71655
                        ,0.03674
                    );
                    -- multiply_add(mpya_in 
                    --     ,to_hfloat(exponent => -5 , mantissa => x"df3b64")
                    --     ,to_hfloat(exponent => 1, mantissa   => x"b76fd2")
                    --     ,to_hfloat(exponent => -4 , mantissa => x"967cae")
                    -- );

                WHEN 35 => 
                    multiply_add(mpya_in 
                        ,to_hfloat(exponent => 1 , mantissa => x"fff2e4")
                        ,to_hfloat(exponent => -5, mantissa => x"c08312")
                        ,to_hfloat(exponent => 0 , mantissa => x"ab020c")
                    );
                WHEN others => --do nothing
            end CASE;
            -- multiply_add(mpya_in 
            --     ,0.01
            --     ,100.5
            --     ,15.5
            -- );

            -- multiply_add(mpya_in 
            --     ,4.0
            --     ,0.5
            --     ,1.0e3
            -- );
            if simulation_counter mod 5 = 0 then
                multiply_add(mpya_in 
                    ,(rand1*2.0)**2
                    ,(rand2*2.0)**2
                    ,(rand3*2.0)**2
                );
            end if;



        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
    process(simulator_clock) is
        -----------------
        variable v_hfloat_result : hfloat_zero'subtype;
        -----------------
    begin
        if rising_edge(simulator_clock)
        then
            -------------------------
            --- p1
            in1_0         <= to_hfloat(mpya_in.mpy_a, hfloat_zero);
            in2_0         <= to_hfloat(mpya_in.mpy_b, hfloat_zero);
            in3_0         <= to_hfloat(mpya_in.add_a, hfloat_zero);

            result_shift1 <= max(
                             to_integer(
                               to_hfloat(mpya_in.add_a, hfloat_zero).exponent 
                             - to_hfloat(mpya_in.mpy_a, hfloat_zero).exponent 
                             - to_hfloat(mpya_in.mpy_b, hfloat_zero).exponent)
                             ,0);

            mult  <= resize(
                       to_hfloat(mpya_in.mpy_a, hfloat_zero).mantissa 
                     * to_hfloat(mpya_in.mpy_b, hfloat_zero).mantissa
                     , mult);

            test1  <= shift(resize(to_hfloat(mpya_in.add_a, hfloat_zero).mantissa, mult)
                      ,hfloat_zero.mantissa'length
                     + to_integer(to_hfloat(mpya_in.add_a, hfloat_zero).exponent 
                     - to_hfloat(mpya_in.mpy_a, hfloat_zero).exponent 
                     - to_hfloat(mpya_in.mpy_b, hfloat_zero).exponent));
            -- end if;

            --- p2
            in1 <= in1_0;
            in2 <= in2_0;
            in3 <= in3_0;
            result_shift <= result_shift1;

            mult_add <= mult + test1;
            --- p3
            v_hfloat_result := ((sign => '0'
                             ,exponent => max(in1.exponent + in2.exponent+result_shift, in3.exponent) +guard_bits
                             ,mantissa => mult_add(hfloat_zero.mantissa'length*2-1+(result_shift)     +guard_bits
                             downto hfloat_zero.mantissa'length+(result_shift)                        +guard_bits )
                             ));

            hfloat_result    <= (v_hfloat_result);
            real_mpya_result <= to_real(normalize(v_hfloat_result));
            result_error     <= abs(to_real(normalize(v_hfloat_result)) - ref_pipeline(2));
            ---
        end if;
    end process;
------------------------------------------------------------------------
end vunit_simulation;
