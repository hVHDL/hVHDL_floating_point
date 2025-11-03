architecture fast_hfloat of multiply_add is

    use work.normalizer_generic_pkg.all;
    use work.denormalizer_generic_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_multiplier_pkg.all;

    constant g_exponent_length : natural := g_floatref.exponent'length;
    constant g_mantissa_length : natural := g_floatref.mantissa'length;

    constant hfloat_zero : hfloat_record := (
            sign       => '0'
            , exponent => (g_exponent_length-1 downto 0 => (g_exponent_length-1 downto 0 => '0'))
            , mantissa => (g_mantissa_length-1 downto 0 => (g_mantissa_length-1 downto 0 => '0')));

    constant init_normalizer : normalizer_record := normalizer_typeref(2, floatref => hfloat_zero);
    signal normalizer : init_normalizer'subtype := init_normalizer;

    -- constant init_multiplier : float_multiplier_record := multiplier_typeref(hfloat_zero);
    -- signal multiplier : init_multiplier'subtype := init_multiplier;

    function "*"(left : integer; right : real) return integer is
    begin
        return integer(real(left)*right);
    end function;

    signal mpy_result  : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal mpy_result2 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');
    signal mpy_result3 : unsigned(hfloat_zero.mantissa'length*3-1 downto 0) := (others => '0');

    ----------------------
    ----------------------
    function to_hfloat( s : std_logic_vector) return hfloat_record is
    begin
        return to_hfloat(s, hfloat_zero);
    end to_hfloat;
    ----------------------
    ----------------------
    ----------------------
    ----------------------
    signal ready_pipeline : std_logic_vector(1 downto 0) := (others => '0');
    signal add_shift_pipeline : std_logic_vector(1 downto 0) := (others => '0');
    ----------------------
    type exp_array is array (natural range <>) of hfloat_zero.exponent'subtype;
    signal exponent_pipeline : exp_array(1 downto 0) := (others => (others => '0'));
    signal shift_pipeline : exp_array(1 downto 0) := (others => (others => '0'));
    ----------------------
    signal mpy_a : unsigned(hfloat_zero.mantissa'length*2-1 downto 0) := (others => '0');
    signal mpy_b : hfloat_zero.mantissa'subtype := (others => '0');
    signal res   : hfloat_zero'subtype          := hfloat_zero;
    ----------------------
    signal shift_res : integer := 0;
    ----------------------
    constant const_shift : integer := 1;
    ----------------------
    signal refa   :  hfloat_zero'subtype := hfloat_zero;
    signal refb   :  hfloat_zero'subtype := hfloat_zero;
    signal refadd :  hfloat_zero'subtype := hfloat_zero;

    ----------------------
    ----------------------
    function get_shift_width(a, b, c : signed) return integer is

        constant retval : unsigned(hfloat_zero.mantissa'length * 3-1 downto 0) := (0 => '1', others => '0');
        variable shiftwidth : integer;

    begin
        shiftwidth := to_integer(c - a - b + hfloat_zero.mantissa'length);
        if shiftwidth >= hfloat_zero.mantissa'length
        then
            shiftwidth := shiftwidth-1;
        end if;

        return shiftwidth;

    end get_shift_width;
    ----------------------
    impure function get_shift return unsigned is

        constant retval : unsigned(hfloat_zero.mantissa'length * 3-1 downto 0) := (0 => '1', others => '0');

    begin

        return shift_left(retval
                   ,get_shift_width(
                       to_hfloat(mpya_in.mpy_a).exponent 
                       , to_hfloat(mpya_in.mpy_b).exponent
                       , to_hfloat(mpya_in.add_a).exponent
                      )
                 );

    end get_shift;
    ----------------------
    function get_result_slice (a : unsigned; offset : integer) return unsigned is
    begin
        return (a(hfloat_zero.mantissa'length*2-1+(offset) downto hfloat_zero.mantissa'length+(offset)));
    end function;
    ----------------------

begin

    res <= (
                 sign      => '0'
                 ,exponent => exponent_pipeline(exponent_pipeline'left)+const_shift
                 ,mantissa => get_result_slice(mpy_result2, const_shift)
           )
            when add_shift_pipeline(add_shift_pipeline'left) = '0'
            else
           (
                 sign      => '0'
                 ,exponent => exponent_pipeline(exponent_pipeline'left)
                 ,mantissa => get_result_slice(mpy_result2, to_integer(shift_pipeline(1)))
           );

    mpya_out.is_ready <= ready_pipeline(ready_pipeline'left);
    -- normalize from 3m length |3m|2m|1m|0mxxxx|
    mpya_out.result   <= to_std_logic(normalize(res));

    process(clock) is
    begin
        if rising_edge(clock) 
        then
            create_normalizer(normalizer);

            ready_pipeline     <= ready_pipeline     ( ready_pipeline'left-1     downto 0) & mpya_in.is_requested;
            exponent_pipeline  <= exponent_pipeline  ( exponent_pipeline'left-1  downto 0) & hfloat_zero.exponent;
            shift_pipeline     <= shift_pipeline     ( shift_pipeline'left-1     downto 0) & hfloat_zero.exponent;
            add_shift_pipeline <= add_shift_pipeline ( add_shift_pipeline'left-1 downto 0) & '0';

            refa   <= to_hfloat(mpya_in.mpy_a);
            refb   <= to_hfloat(mpya_in.mpy_b);
            refadd <= to_hfloat(mpya_in.add_a);
            ---
            shift_res  <= get_shift_width(
                           to_hfloat(mpya_in.mpy_a).exponent
                          ,to_hfloat(mpya_in.mpy_b).exponent
                          ,to_hfloat(mpya_in.add_a).exponent
                      );
            ---
            if (to_hfloat(mpya_in.mpy_a).exponent + to_hfloat(mpya_in.mpy_b).exponent)
                >= to_hfloat(mpya_in.add_a).exponent
            then
                exponent_pipeline(0) <= 
                               to_hfloat(mpya_in.mpy_a).exponent 
                             + to_hfloat(mpya_in.mpy_b).exponent;
            else
                exponent_pipeline(0) <= to_hfloat(mpya_in.add_a).exponent;
                shift_pipeline(0)    <=
                               to_hfloat(mpya_in.add_a).exponent
                             - (to_hfloat(mpya_in.mpy_a).exponent 
                             + to_hfloat(mpya_in.mpy_b).exponent);
                add_shift_pipeline(0) <= '1';
            end if;
            ---
            -- p1
            mpy_a      <= shift_right(resize(get_shift, mpy_a'length), 0);
            mpy_b      <= to_hfloat(mpya_in.add_a).mantissa;
            mpy_result <= resize(to_hfloat(mpya_in.mpy_a).mantissa * to_hfloat(mpya_in.mpy_b).mantissa , mpy_result2'length);
            ---
            -- p2
            mpy_result2 <= resize(mpy_a * mpy_b , mpy_result2'length) + mpy_result;
            ---
        end if; -- rising edge
    end process;

end fast_hfloat;
