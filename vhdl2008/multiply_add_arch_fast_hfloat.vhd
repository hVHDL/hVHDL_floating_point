---------------------
LIBRARY ieee  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.NUMERIC_STD.all  ; 

entity hw_mult_axb is
    generic(is_clocked : boolean := false);
    port(
        clock : in std_logic := '0'
        ;a    : in signed
        ;b   : in signed
        ;res : out signed
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

-- Signed multiply-add: res = a*b + c.  The add/sub choice is handled by the
-- caller pre-negating the 24-bit multiplicand, so this is a plain MAC and
-- maps straight onto the DSP accumulate path.
entity hw_mult_axb_addsub_c is
    generic(is_clocked : boolean := false);
    port(
        clock : in std_logic := '0'
        ;a   : in signed
        ;b   : in signed
        ;c   : in signed
        ;res : out signed
    );
end hw_mult_axb_addsub_c;

architecture rtl of hw_mult_axb_addsub_c is
    signal a_buf : a'subtype;
    signal b_buf : b'subtype;
    signal c_buf : c'subtype;

begin

    unclocked :
    if not is_clocked generate
        res <= resize(a * b, res'length) + c;
    end generate;

    clocked :
    if is_clocked generate
        process(clock) is
        begin
            if rising_edge(clock)
            then
                a_buf <= a;
                b_buf <= b;
                c_buf <= c;
                res <= resize(a_buf * b_buf, res'length) + c_buf;
            end if;
        end process;
    end generate;

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
    use work.fast_hfloat_pkg.get_sticky;
    ----------------------
    use work.fast_hfloat_pkg.c_align_guard;
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
    signal extended_result_buf2 : res_subtype'subtype := res_subtype;

    -- signed: the mantissa product is pre-negated for subtraction, so
    -- mpy_result2 can be negative near cancellation.  One extra bit for sign.
    signal mpy_result2 : signed(hfloat_zero.mantissa'length*2 + c_align_guard downto 0) := (others => '0');
    signal test_mpy2   : signed(hfloat_zero.mantissa'length*2 + c_align_guard - 1 downto 0) := (others => '0');
    ----------------------
    ----------------------
    -- pipelines
    ----------------------
    ----------------------
    constant pipe_depth : natural := 2;

    signal ready_pipe     : std_logic_vector(pipe_depth+2 downto 0) := (others => '0');
    signal add_shift_pipe : std_logic_vector(pipe_depth downto 0) := (others => '0');
    ----------------------
    type exp_array is array (natural range <>) of hfloat_zero.exponent'subtype;
    signal result_exponent_pipe : exp_array(pipe_depth downto 0) := (others => (others => '0'));
    signal shift_pipe           : exp_array(pipe_depth downto 0) := (others => (others => '0'));
    ----------------------
    signal op_pipe_sub_when_1 : std_logic_vector(pipe_depth downto 0) := (others => '0');
    ----------------------
    use work.fast_hfloat_pkg.sign_array;
    signal sign_pipe : sign_array(2 downto 0) := (others => (others => '0'));
    ----------------------
    -- end pipelines
    ----------------------
    -- mpy_b_buf is pre-negated (two's complement) when the effective operation
    -- is a subtract, so the mantissa multiply carries the sign
    signal mpy_a_buf    : signed(hfloat_zero.mantissa'length downto 0) := (others => '0');
    signal mpy_b_buf    : signed(hfloat_zero.mantissa'length downto 0) := (others => '0');
    signal add_a_buf    : signed(hfloat_zero.mantissa'length downto 0) := (others => '0');
    signal mpy_shifter  : unsigned(hfloat_zero.mantissa'length + c_align_guard - 1 downto 0) := (others => '0');
    signal op_p0        : std_logic := '0';
    ----------------------
    signal shift_res : integer := 0;
    ----------------------
    constant const_shift : integer := 1; -- TODO, check this
    ----------------------
    constant pipe : natural := 2;
    ------------------
    ------------------
    function "xor" (left : std_logic ; right : unsigned) return unsigned is
        constant expanded_left : unsigned(right'range) := (others => left);
    begin
        return expanded_left xor right;
    end function;

    ------------------
    use work.fast_hfloat_pkg.get_result_sign;

    -------------
    signal mpy_a : hfloat_zero'subtype := hfloat_zero;
    signal mpy_b : hfloat_zero'subtype := hfloat_zero;
    signal add_a : hfloat_zero'subtype := hfloat_zero;

    ------------------
    impure function get_fma_result return hfloat_record is
        variable retval : extended_result'subtype;
        variable v_mag  : unsigned(mpy_result2'range);
        variable v_off  : integer;
        variable v_mant : extended_result.mantissa'subtype;
    begin
        -- approximate magnitude (bitwise negate, off by one LSB) of the
        -- possibly-negative signed multiply-add result
        v_mag := mpy_result2(mpy_result2'left) xor unsigned(mpy_result2);

        if add_shift_pipe(pipe) = '0'
        then
            v_off := const_shift - extra_shift_bits*2;
        else
            v_off := to_integer(shift_pipe(pipe)) + const_shift - extra_shift_bits*2;
        end if;

        v_mant := get_result_slice(v_mag, v_off, res_subtype);
        v_mant(v_mant'right) := v_mant(v_mant'right) or get_sticky(v_mag, v_off, res_subtype);

        retval := (
              sign      => get_result_sign(pipe, sign_pipe, mpy_result2(mpy_result2'left), op_pipe_sub_when_1)
              ,exponent => result_exponent_pipe(pipe) + const_shift
              ,mantissa => v_mant
        );
        return retval;
    end function;
    ------------------

    use work.fast_hfloat_pkg.get_operation;

    -- signed one-hot shift vector (intermediate signal: nvc rejects a type
    -- conversion as the actual for an unconstrained port)
    signal shifter_a : signed(mpy_shifter'length downto 0) := (others => '0');

begin

    shifter_a <= signed('0' & mpy_shifter);

    ------------
    -- p0
    mpy_a <= to_hfloat(mpya_in.mpy_a, hfloat_zero);
    mpy_b <= to_hfloat(mpya_in.mpy_b, hfloat_zero);
    add_a <= to_hfloat(mpya_in.add_a, hfloat_zero);

    op_p0     <= get_operation(mpy_a, mpy_b, add_a);
    mpy_a_buf <= signed(resize(mpy_a.mantissa, mpy_a_buf'length));
    mpy_b_buf <= -signed(resize(mpy_b.mantissa, mpy_b_buf'length)) when op_p0 = '1'
                 else signed(resize(mpy_b.mantissa, mpy_b_buf'length));

    ------------
    -- p1
    mantissa_mult : entity work.hw_mult_axb
    generic map(is_clocked => true)
    port map( clock => clock
    , a   => mpy_a_buf
    , b   => mpy_b_buf
    , res => test_mpy2);

    process(clock) is
    begin
        if rising_edge(clock) then
            mpy_shifter <= resize(get_shift(mpya_in.mpy_a, mpya_in.mpy_b, mpya_in.add_a, hfloat_zero), mpy_shifter'length);
            add_a_buf   <= signed(resize(add_a.mantissa, add_a_buf'length));
        end if;
    end process;

    ------------
    -- p2  -- res = (shifted addend) + (signed mantissa product)
    shifter : entity work.hw_mult_axb_addsub_c
    generic map(is_clocked => true)
    port map(
            clock => clock
             , a   => shifter_a   -- one-hot shift vector, always positive
             , b   => add_a_buf   -- addend mantissa, always positive
             , c   => test_mpy2   -- mantissa product, negative when subtracting
             , res => mpy_result2);

    ------------
    -- p3  -- fused: magnitude/slice/sticky and leading-zero normalise in one stage
    output_buffer : process(clock) is
    begin
       if rising_edge(clock) then
            extended_result_buf <= normalize(get_fma_result);
        end if;
    end process;

    mpya_out.result   <= to_std_logic((extended_result_buf))(mpya_out.result'high+extra_shift_bits downto 0+extra_shift_bits);
    mpya_out.is_ready <= ready_pipe(ready_pipe'left);

    -------------------------------------------
    -------------------------------------------
    pipelines : process(clock) is
    begin
        if rising_edge(clock) 
        then

            ready_pipe              <= ready_pipe(ready_pipe'left-1 downto 0) & mpya_in.is_requested;
            sign_pipe(0)            <= mpy_a.sign & mpy_b.sign & add_a.sign;
            result_exponent_pipe(0) <= hfloat_zero.exponent;
            shift_pipe(0)           <= hfloat_zero.exponent;
            add_shift_pipe(0)       <= '0';
            op_pipe_sub_when_1(0)   <= get_operation( mpy_a ,mpy_b ,add_a) ;
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
                -- clamp to match get_shift_width: past the guard the product is
                -- dropped, so the slice offset must saturate with the shifter
                if (add_a.exponent - mpy_a.exponent - mpy_b.exponent) > c_align_guard - 1 then
                    shift_pipe(0) <= to_signed(c_align_guard - 1, shift_pipe(0)'length);
                else
                    shift_pipe(0) <= add_a.exponent - mpy_a.exponent - mpy_b.exponent;
                end if;

                add_shift_pipe(0) <= '1';
            end if;

            for i in op_pipe_sub_when_1'range loop
                if i > 0 then
                    op_pipe_sub_when_1(i)   <= op_pipe_sub_when_1(i-1);
                    add_shift_pipe(i)       <= add_shift_pipe(i-1);
                    shift_pipe(i)           <= shift_pipe(i-1);
                    result_exponent_pipe(i) <= result_exponent_pipe(i-1);
                    sign_pipe(i)            <= sign_pipe(i-1);
                end if;
            end loop;

        end if; -- rising edge
    end process;
    -------------------------------------------

end fast_hfloat;
