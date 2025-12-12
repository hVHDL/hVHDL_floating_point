---------------------
LIBRARY ieee  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.NUMERIC_STD.all  ; 

entity hw_mult_axb is
    generic(is_clocked : boolean := false);
    port(
        clock : in std_logic := '0'
        ;a    : in unsigned
        ;b   : in unsigned
        ;res : out unsigned
    );
end hw_mult_axb;

architecture rtl of hw_mult_axb is

begin

    clock_gen :
    if is_clocked generate
        process(clock) is
        begin
            if rising_edge(clock) then
                res <= resize(a * b, res'length);
            end if;
        end process;
    end generate;
    unclocked : 

    if not is_clocked generate
        res <= resize(a * b, res'length);
    end generate;


end rtl;
        
---------------------
LIBRARY ieee  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.NUMERIC_STD.all  ; 

entity hw_mult_axb_addsub_c is
    port(
        a           : in unsigned
        ;b          : in unsigned
        ;c          : in unsigned
        ;sub_when_1 : in std_logic

        ;res        : out unsigned
    );
end hw_mult_axb_addsub_c;

architecture rtl of hw_mult_axb_addsub_c is

begin

    res <= resize(a * b, res'length) + c when sub_when_1 = '0' else
           resize(a * b, res'length) - c ;

end rtl;
        
---------------------
architecture fast_hfloat of multiply_add is

    ----------------------
    use work.fast_hfloat_pkg.get_result_slice;
    ----------------------
    use work.fast_hfloat_pkg.get_shift_width;
    ----------------------
    use work.fast_hfloat_pkg.get_shift;
    ----------------------
    use work.fast_hfloat_pkg.max;
    ----------------------
    use work.normalizer_generic_pkg.normalize;
    ----------------------
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

    constant norm_subtype : normalizer_record := normalizer_typeref(floatref => res_subtype);

    signal normalizer : norm_subtype'subtype := norm_subtype;

    signal extended_result     : res_subtype'subtype := res_subtype;
    signal extended_result_buf : res_subtype'subtype := res_subtype;

    signal mpy_result  : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal mpy_result2 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal mpy_result3 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');

    signal test_mpy1 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal test_mpy2 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    ----------------------
    ----------------------
    -- pipelines
    ----------------------
    ----------------------
    constant pipe_depth : natural := 1;

    signal ready_pipeline     : std_logic_vector(pipe_depth downto 0) := (others => '0');
    signal add_shift_pipeline : std_logic_vector(pipe_depth downto 0) := (others => '0');
    ----------------------
    type exp_array is array (natural range <>) of hfloat_zero.exponent'subtype;
    signal result_exponent_pipe : exp_array(pipe_depth downto 0) := (others => (others => '0'));
    signal shift_pipeline       : exp_array(pipe_depth downto 0) := (others => (others => '0'));
    ----------------------
    signal op_pipe_sub_when_1 : std_logic_vector(pipe_depth downto 0) := (others => '0');
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

    begin
        CASE sign_pipe(pipe) is
            WHEN "111" => retval := op_pipe_sub_when_1(pipe);
            WHEN "001" => retval := op_pipe_sub_when_1(pipe);
            WHEN "010" => retval := not op_pipe_sub_when_1(pipe);
            WHEN "100" => retval := not op_pipe_sub_when_1(pipe);
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
    signal sign_pipe : sign_array(1 downto 0) := (others => (others => '0'));

    signal mpy_a : hfloat_zero'subtype := hfloat_zero;
    signal mpy_b : hfloat_zero'subtype := hfloat_zero;
    signal add_a : hfloat_zero'subtype := hfloat_zero;

    ------------------
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
    ------------------

begin

    mpy_a <= to_hfloat(mpya_in.mpy_a, hfloat_zero);
    mpy_b <= to_hfloat(mpya_in.mpy_b, hfloat_zero);
    add_a <= to_hfloat(mpya_in.add_a, hfloat_zero);

    shifter : entity work.hw_mult_axb
    port map(a => mpy_shifter, b => add_a_buf, res => test_mpy1);

    mantissa_mult : entity work.hw_mult_axb
    port map(clock => clock, a => mpy_a_buf, b => mpy_b_buf, res => test_mpy2);

    mpy_shifter <= resize(get_shift(mpya_in.mpy_a, mpya_in.mpy_b, mpya_in.add_a, hfloat_zero), mpy_shifter'length);
    mpy_a_buf   <= resize(mpy_a.mantissa, mpy_a_buf);
    mpy_b_buf   <= resize(mpy_b.mantissa, mpy_b_buf);
    add_a_buf   <= resize(add_a.mantissa, add_a_buf);

    ------------
    output_buffer : process(clock) is
    begin
       if rising_edge(clock) then
            -- mpy_result  <= test_mpy1 + test_mpy2;
            -- mpy_result3 <= test_mpy1 - test_mpy2;
           if get_operation( mpy_a ,mpy_b ,add_a) = '0'
           then
               mpy_result2 <= test_mpy1 + test_mpy2;
           else
               mpy_result2 <= test_mpy1 - test_mpy2;
           end if;

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
                        mpy_a.sign
                        & mpy_b.sign
                        & add_a.sign) ;

            ready_pipeline(0)       <= mpya_in.is_requested;
            result_exponent_pipe(0) <= hfloat_zero.exponent;
            shift_pipeline(0)       <= hfloat_zero.exponent;
            add_shift_pipeline(0)   <= '0';
            op_pipe_sub_when_1(0)   <= get_operation( mpy_a ,mpy_b ,add_a) ;

            for i in op_pipe_sub_when_1'range loop
                if i > 0 then
                    op_pipe_sub_when_1(i)   <= op_pipe_sub_when_1(i-1);
                    add_shift_pipeline(i)   <= add_shift_pipeline(i-1);
                    shift_pipeline(i)       <= shift_pipeline(i-1);
                    result_exponent_pipe(i) <= result_exponent_pipe(i-1);
                    ready_pipeline(i)       <= ready_pipeline(i-1);
                end if;
            end loop;

            ---
            shift_res  <= get_shift_width(
                           mpy_a.exponent
                          ,mpy_b.exponent
                          ,add_a.exponent
                          ,add_a.mantissa
                      ) - hfloat_zero.mantissa'length;
            ---
            if get_shift_width(
                mpy_a.exponent 
                ,mpy_b.exponent
                ,add_a.exponent
                ,add_a.mantissa)
                <  hfloat_zero.mantissa'length
            then
                result_exponent_pipe(0) <= 
                               mpy_a.exponent 
                             + mpy_b.exponent;
            else
                result_exponent_pipe(0) <= add_a.exponent;
                shift_pipeline(0)    <=
                               add_a.exponent
                             - mpy_a.exponent 
                             - mpy_b.exponent;

                add_shift_pipeline(0) <= '1';
            end if;
        end if; -- rising edge
    end process;
    -------------------------------------------

end fast_hfloat;
