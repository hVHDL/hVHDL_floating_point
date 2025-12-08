architecture fast_hfloat of multiply_add is

    use work.normalizer_generic_pkg.all;

    constant extra_shift_bits : natural := 3;

    constant g_exponent_length : natural := g_floatref.exponent'length;
    constant g_mantissa_length : natural := g_floatref.mantissa'length;

    constant hfloat_zero : hfloat_record := (
            sign       => '0'
            , exponent => (g_exponent_length-1 downto 0 => (g_exponent_length-1 downto 0 => '0'))
            , mantissa => (g_mantissa_length-1 downto 0 => (g_mantissa_length-1 downto 0 => '0')));

    constant res_subtype : hfloat_record := (
            sign       => '0'
            , exponent => (g_exponent_length-1 downto 0 => (g_exponent_length-1 downto 0 => '0'))
            , mantissa => (g_mantissa_length-1+extra_shift_bits downto 0 => (g_mantissa_length-1+extra_shift_bits downto 0 => '0')));

    signal extended_result : res_subtype'subtype := res_subtype;
    signal extended_result_buf : res_subtype'subtype := res_subtype;

    constant init_normalizer : normalizer_record := normalizer_typeref(2, floatref => hfloat_zero);

    signal mpy_result  : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal mpy_result2 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal mpy_result3 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');

    signal test_mpy1 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal test_mpy2 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal test_mpy3 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    ----------------------
    ----------------------
    function to_hfloat( s : std_logic_vector) return hfloat_record is
    begin
        return to_hfloat(s, hfloat_zero);
    end to_hfloat;
    ----------------------
    ----------------------
    signal ready_pipeline     : std_logic_vector(1 downto 0) := (others => '0');
    signal add_shift_pipeline : std_logic_vector(1 downto 0) := (others => '0');
    ----------------------
    type exp_array is array (natural range <>) of hfloat_zero.exponent'subtype;
    signal result_exponent_pipe : exp_array(1 downto 0) := (others => (others => '0'));
    signal shift_pipeline       : exp_array(1 downto 0) := (others => (others => '0'));

    signal exp_a_pipe : exp_array(2 downto 0) := (others => (others => '0'));
    signal exp_b_pipe : exp_array(2 downto 0) := (others => (others => '0'));
    signal exp_c_pipe : exp_array(2 downto 0) := (others => (others => '0'));
    ----------------------
    signal mpy_a_buf    : unsigned(hfloat_zero.mantissa'length*2-1 downto 0) := (others => '0');
    signal add_a_buf    : unsigned(hfloat_zero.mantissa'length*2-1 downto 0) := (others => '0');
    signal mpy_b_buf    : unsigned(hfloat_zero.mantissa'length*2-1 downto 0) := (others => '0');
    signal mpy_shifter  : unsigned(hfloat_zero.mantissa'length*2-1 downto 0) := (others => '0');
    ----------------------
    signal shift_res : integer := 0;
    ----------------------
    constant const_shift : integer := 1; -- TODO, check this
    ----------------------
    signal op_pipe_sub_when_1 : std_logic_vector(2 downto 0) := (others => '0');
    ----------------------
    use work.fast_hfloat_pkg.get_result_slice;
    ----------------------
    use work.fast_hfloat_pkg.get_shift_width;
    ----------------------
    use work.fast_hfloat_pkg.get_shift;
    ----------------------
    use work.fast_hfloat_pkg.max;
    ----------------------

    ------------------
    function get_operation (mpy_a,mpy_b, add_a : hfloat_zero'subtype) return std_logic is
        variable add_when_0_neg_when_1 : std_logic;
        variable sign_vector : std_logic_vector(2 downto 0);
        /*
        sign propagation to operation
        ++|+ => +
        --|+ => +
        -+|- => +
        +-|- => +

        --|- => -
        -+|+ => -
        +-|+ => -
        ++|- => -
        */
    begin
        sign_vector := (mpy_a.sign & mpy_b.sign & add_a.sign);
        CASE sign_vector is
            -- add
            WHEN "000" 
                |"110" 
                |"101" 
                |"011" => add_when_0_neg_when_1 := '0';

            -- sub
            WHEN "111" 
                |"100" 
                |"010" 
                |"001" => add_when_0_neg_when_1 := '1';

            WHEN others => --do nothing
        end CASE;

        return add_when_0_neg_when_1;

    end get_operation;

    ------------------
    type sign_array is array (natural range <>) of std_logic_vector(2 downto 0);

    ------------------
    constant pipe : natural := 0;
    ------------------
    impure function get_result_sign(sign_pipe : sign_array ; high_bit : STD_LOGIC ; op_pipe_sub_when_1 : STD_LOGIC_VECTOR) return std_logic is

        ---------
        variable retval : std_logic;

        ---------
        function "xor"(left : std_logic ; right : boolean) return std_logic 
        is
            variable retval : std_logic;
        begin
            if right then
                retval := '1';
            else
                retval := '0';
            end if;

            return retval xor left;
        end function;

        ---------
        ---------
        constant exp_a : hfloat_zero.exponent'subtype := exp_a_pipe(pipe);
        constant exp_b : hfloat_zero.exponent'subtype := exp_b_pipe(pipe);
        constant exp_c : hfloat_zero.exponent'subtype := exp_c_pipe(pipe);
        ---------

    begin
        CASE sign_pipe(pipe) is
            WHEN "111" => retval := '0' xor (exp_a + exp_b) >= exp_c;
                if op_pipe_sub_when_1(pipe) = '1' then
                    retval := '1';
                end if;
            WHEN "001" => retval := '0' xor (exp_a + exp_b) >= exp_c;
                if op_pipe_sub_when_1(pipe) = '1' then
                    retval := '1';
                end if;
            WHEN "010" => retval := '1' xor (exp_a + exp_b) >= exp_c;
                if op_pipe_sub_when_1(pipe) = '1' then
                    retval := '0';
                end if;
            WHEN "100" => retval := '1' xor (exp_a + exp_b) >= exp_c;
                if op_pipe_sub_when_1(pipe) = '1' then
                    retval := '0';
                end if;
            --
            WHEN "000" => retval := '0';
            WHEN "011" => retval := '1';
            WHEN "101" => retval := '1';
            WHEN "110" => retval := '0';
            WHEN others => --do nothing
        end CASE;

        return retval xor high_bit;
    end function;

    ------------------
    function "xor" (left : std_logic ; right : unsigned) return unsigned is
        constant expanded_left : unsigned(right'range) := (others => left);
    begin
        return expanded_left xor right;
    end function;

    ------------------
    signal sign_pipe : sign_array(2 downto 0) := (others => (others => '0'));
    --debug signals, remove when no longer needed
    signal refa   :  hfloat_zero'subtype := hfloat_zero;
    signal refb   :  hfloat_zero'subtype := hfloat_zero;
    signal refadd :  hfloat_zero'subtype := hfloat_zero;

    impure function get_fma_result return hfloat_record is
        variable retval : extended_result'subtype;
    begin
        if add_shift_pipeline(pipe) = '0'
        then
            retval := 
                   (
                         sign      => get_result_sign(sign_pipe, mpy_result2(mpy_result2'left), op_pipe_sub_when_1)
                         ,exponent => result_exponent_pipe(pipe)+const_shift
                         ,mantissa => get_result_slice(mpy_result2(mpy_result2'left) xor mpy_result2, const_shift-extra_shift_bits*2, res_subtype)
                   );
        else
            retval := 
                   (
                         sign      => get_result_sign(sign_pipe, mpy_result2(mpy_result2'left), op_pipe_sub_when_1)
                         ,exponent => result_exponent_pipe(pipe) + const_shift
                         ,mantissa => get_result_slice(mpy_result2(mpy_result2'left) xor mpy_result2, to_integer(shift_pipeline(pipe) + const_shift-extra_shift_bits*2), res_subtype)
                   );
        end if;
        return retval;
    end function;

    attribute multstyle : string;
    attribute multstyle of mpy_result  : signal is "dsp";
    attribute multstyle of mpy_result3 : signal is "dsp";
    -- result <= a * b; -- implement this multiply in logic

begin

    mpy_shifter <= resize(get_shift(mpya_in.mpy_a, mpya_in.mpy_b, mpya_in.add_a, hfloat_zero), mpy_shifter'length);
    mpy_a_buf   <= resize(to_hfloat(mpya_in.mpy_a).mantissa, mpy_a_buf);
    mpy_b_buf   <= resize(to_hfloat(mpya_in.mpy_b).mantissa, mpy_b_buf);
    add_a_buf   <= resize(to_hfloat(mpya_in.add_a).mantissa, add_a_buf);



    -- use res with mantissa + 3 length
    process(all) is
    begin

        if op_pipe_sub_when_1(0) = '0' then
            mpy_result2 <= mpy_result;
        else
            mpy_result2 <= mpy_result3;
        end if;

    end process;

    test_mpy1 <= resize(mpy_shifter * add_a_buf, test_mpy1);
    test_mpy2 <= resize(mpy_a_buf   * mpy_b_buf, test_mpy2);

    output_buffer : process(clock) is
    begin
       if rising_edge(clock) then
            mpy_result  <= test_mpy1 + test_mpy2;
            mpy_result3 <= test_mpy1 - test_mpy2;

            extended_result     <= get_fma_result;
            extended_result_buf <= extended_result;
        end if;
    end process;

    mpya_out.is_ready <= ready_pipeline(ready_pipeline'left);
    mpya_out.result   <= to_std_logic(normalize(extended_result))(mpya_out.result'high+extra_shift_bits downto 0+extra_shift_bits);


    -------------------------------------------
    pipelines : process(clock) is
    begin
        if rising_edge(clock) 
        then
            sign_pipe <= sign_pipe(sign_pipe'left-1 downto 0) &
                    STD_LOGIC_VECTOR'(
                        to_hfloat(mpya_in.mpy_a).sign
                        & to_hfloat(mpya_in.mpy_b).sign
                        & to_hfloat(mpya_in.add_a).sign) ;

            exp_a_pipe <= exp_a_pipe(exp_a_pipe'left-1 downto 0) 
                          & to_hfloat(mpya_in.mpy_a).exponent;

            exp_b_pipe <= exp_b_pipe(exp_b_pipe'left-1 downto 0) 
                          & to_hfloat(mpya_in.mpy_b).exponent;

            exp_c_pipe <= exp_c_pipe(exp_c_pipe'left-1 downto 0) 
                          & to_hfloat(mpya_in.add_a).exponent;

            ready_pipeline       <= ready_pipeline       ( ready_pipeline'left-1       downto 0) & mpya_in.is_requested;
            result_exponent_pipe <= result_exponent_pipe ( result_exponent_pipe'left-1 downto 0) & hfloat_zero.exponent;
            shift_pipeline       <= shift_pipeline       ( shift_pipeline'left-1       downto 0) & hfloat_zero.exponent;
            add_shift_pipeline   <= add_shift_pipeline   ( add_shift_pipeline'left-1   downto 0) & '0';
            op_pipe_sub_when_1 <= 
                op_pipe_sub_when_1 ( op_pipe_sub_when_1'left-1 downto 0) 
                &
                get_operation(
                    to_hfloat(mpya_in.mpy_a)
                    ,to_hfloat(mpya_in.mpy_b)
                    ,to_hfloat(mpya_in.add_a))
            ;


            refa   <= to_hfloat(mpya_in.mpy_a);
            refb   <= to_hfloat(mpya_in.mpy_b);
            refadd <= to_hfloat(mpya_in.add_a);
            ---
            shift_res  <= get_shift_width(
                           to_hfloat(mpya_in.mpy_a).exponent
                          ,to_hfloat(mpya_in.mpy_b).exponent
                          ,to_hfloat(mpya_in.add_a).exponent
                          ,to_hfloat(mpya_in.add_a).mantissa
                      ) - hfloat_zero.mantissa'length;
            ---
            if get_shift_width(
                to_hfloat(mpya_in.mpy_a).exponent 
                ,to_hfloat(mpya_in.mpy_b).exponent
                ,to_hfloat(mpya_in.add_a).exponent
                ,to_hfloat(mpya_in.add_a).mantissa)
                <  hfloat_zero.mantissa'length
            then
                result_exponent_pipe(0) <= 
                               to_hfloat(mpya_in.mpy_a).exponent 
                             + to_hfloat(mpya_in.mpy_b).exponent;
            else
                result_exponent_pipe(0) <= to_hfloat(mpya_in.add_a).exponent;
                shift_pipeline(0)    <=
                               to_hfloat(mpya_in.add_a).exponent
                             - to_hfloat(mpya_in.mpy_a).exponent 
                             - to_hfloat(mpya_in.mpy_b).exponent;

                add_shift_pipeline(0) <= '1';
            end if;
        end if; -- rising edge
    end process;
    -------------------------------------------

end fast_hfloat;
