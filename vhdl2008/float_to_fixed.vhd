------------------------------------------------------------------------
-- float_to_fixed - fixed = trunc(value * 2**radix), signed.
--
-- Same denormalise-then-take-the-mantissa algorithm as
-- hVHDL_floating_point's denormalizer, exposed as an abstract interface
-- in the multiply_add style:
--
--   constant f2f_ref : float_to_fixed_typeref := create_float_to_fixed_typeref(hfloat32);
--   signal   f2f_in  : f2f_ref.f2f_in'subtype  := f2f_ref.f2f_in;
--   signal   f2f_out : f2f_ref.f2f_out'subtype := f2f_ref.f2f_out;
--   ...
--   u_f2f : entity work.float_to_fixed        -- floatref defaults to hfloat32
--       port map (clock => clk, float_to_fixed_in => f2f_in, float_to_fixed_out => f2f_out);
--   ...
--   request_float_to_fixed(f2f_in, fp32_to_hfloat(slv), radix);   -- glue is a separate call
--   result <= get_fixed_result(f2f_out);                          -- valid g_stages edges later
--
-- The hfloat reference type (floatref) and the pipeline depth (g_stages)
-- are entity generics; radix is carried in the input record, so one
-- instance converts at any radix.  Nothing is read off an unconstrained
-- record subprogram formal - the construct Quartus Prime Pro 25.3
-- mis-evaluates - so it synthesises.
------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_typedefs_generic_pkg.hfloat_record;

package float_to_fixed_pkg is

    -- hVHDL hfloat matching IEEE-754 binary32: 8-bit exponent, 23-bit
    -- mantissa (implicit leading 1).  fp32_to_hfloat returns the
    -- CONSTRAINED subtype so its result carries definite bounds through
    -- request_float_to_fixed's formal parameter.  `hfloat32` is the
    -- reference value - the default for the entity's floatref generic.
    subtype  t_hfloat32 is hfloat_record(exponent(7 downto 0), mantissa(22 downto 0));
    constant hfloat32   : t_hfloat32 :=
        (sign => '0', exponent => (others => '0'), mantissa => (others => '0'));

    type float_to_fixed_input_record is record
        number       : hfloat_record;   -- hfloat, implicit leading 1 set
        radix        : natural;         -- fixed = trunc(value * 2**radix)
        is_requested : std_logic;
    end record;

    type float_to_fixed_output_record is record
        result   : signed;
        is_ready : std_logic;
    end record;

    type float_to_fixed_typeref is record
        f2f_in  : float_to_fixed_input_record;
        f2f_out : float_to_fixed_output_record;
    end record;

    function create_float_to_fixed_typeref (
        floatref    : hfloat_record;
        result_bits : natural := 32)
    return float_to_fixed_typeref;

    procedure init_float_to_fixed (signal self_in : out float_to_fixed_input_record);

    -- start a conversion of `number` at `radix`
    procedure request_float_to_fixed (
        signal self_in : out float_to_fixed_input_record;
        number         : in  hfloat_record;
        radix          : in  natural);

    function float_to_fixed_is_ready (self_out : float_to_fixed_output_record) return boolean;
    function get_fixed_result        (self_out : float_to_fixed_output_record) return signed;

    -- glue, called separately: IEEE-754 binary32 -> hfloat (8-bit exponent,
    -- 23-bit mantissa with the implicit leading 1; fraction LSB dropped as
    -- float_typedefs_generic_pkg.to_hfloat does).  be = 0 / out of range
    -- -> exact 0 so the shift never overflows the exponent field.
    function fp32_to_hfloat (fp32 : std_logic_vector(31 downto 0)) return t_hfloat32;

end package float_to_fixed_pkg;

package body float_to_fixed_pkg is

    function create_float_to_fixed_typeref (
        floatref    : hfloat_record;
        result_bits : natural := 32)
    return float_to_fixed_typeref is
        constant el : natural := floatref.exponent'length;
        constant ml : natural := floatref.mantissa'length;
    begin
        return (
            f2f_in => (
                number       => (sign     => '0',
                                 exponent => (el - 1 downto 0 => '0'),
                                 mantissa => (ml - 1 downto 0 => '0')),
                radix        => 0,
                is_requested => '0'),
            f2f_out => (
                result   => (result_bits - 1 downto 0 => '0'),
                is_ready => '0'));
    end function;

    procedure init_float_to_fixed (signal self_in : out float_to_fixed_input_record) is
    begin
        self_in.is_requested <= '0';
    end procedure;

    procedure request_float_to_fixed (
        signal self_in : out float_to_fixed_input_record;
        number         : in  hfloat_record;
        radix          : in  natural) is
    begin
        self_in.number       <= number;
        self_in.radix        <= radix;
        self_in.is_requested <= '1';
    end procedure;

    function float_to_fixed_is_ready (self_out : float_to_fixed_output_record) return boolean is
    begin
        return self_out.is_ready = '1';
    end function;

    function get_fixed_result (self_out : float_to_fixed_output_record) return signed is
    begin
        return self_out.result;
    end function;

    function fp32_to_hfloat (fp32 : std_logic_vector(31 downto 0)) return t_hfloat32 is
        variable be : natural;
        variable r  : t_hfloat32;
    begin
        r.sign     := fp32(31);
        r.exponent := (others => '0');
        r.mantissa := (others => '0');
        be := to_integer(unsigned(fp32(30 downto 23)));
        if be /= 0 and be <= 200 then
            r.exponent   := to_signed(be - 126, 8);
            r.mantissa(22) := '1';
            for i in 1 to 22 loop
                r.mantissa(22 - i) := fp32(23 - i);
            end loop;
        end if;
        return r;
    end function;

end package body float_to_fixed_pkg;

------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_typedefs_generic_pkg.hfloat_record;
    use work.float_to_fixed_pkg.all;

entity float_to_fixed is
    generic (
        floatref : hfloat_record := hfloat32;   -- constrained actual fixes exp/mant widths
        g_stages : natural       := 2
    );
    port (
        clock              : in  std_logic;
        float_to_fixed_in  : in  float_to_fixed_input_record;
        float_to_fixed_out : out float_to_fixed_output_record
    );
end entity float_to_fixed;

architecture rtl of float_to_fixed is

    subtype t_hfloat is floatref'subtype;
    type    t_pipe   is array (natural range <>) of t_hfloat;

    constant c_mant_len  : natural := floatref.mantissa'length;    -- read off a GENERIC
    constant c_max_shift : natural := c_mant_len / g_stages;

    function denorm_step (h : t_hfloat; target_scale : integer) return t_hfloat is
        variable sw : integer;
    begin
        sw := target_scale - to_integer(h.exponent);
        if sw >= c_max_shift then sw := c_max_shift; end if;
        if sw < 0            then sw := 0;            end if;
        return (sign     => h.sign,
                exponent => h.exponent + sw,
                mantissa => shift_right(h.mantissa, sw));
    end function;

    signal pipe   : t_pipe(0 to g_stages)          := (others => floatref);
    signal fthru  : t_pipe(0 to g_stages)          := (others => floatref);
    signal scale  : integer_vector(0 to g_stages)  := (others => 0);
    signal strobe : std_logic_vector(0 to g_stages) := (others => '0');

    signal result_i : signed(31 downto 0) := (others => '0');

begin

    denormalise : process (clock) is
    begin
        if rising_edge(clock) then
            strobe(0) <= float_to_fixed_in.is_requested;
            pipe(0)   <= float_to_fixed_in.number;
            fthru(0)  <= float_to_fixed_in.number;
            scale(0)  <= c_mant_len - float_to_fixed_in.radix;
            for i in 1 to g_stages loop
                pipe(i)   <= denorm_step(pipe(i - 1), scale(i - 1));
                fthru(i)  <= fthru(i - 1);
                scale(i)  <= scale(i - 1);
                strobe(i) <= strobe(i - 1);
            end loop;
        end if;
    end process denormalise;

    result_i <= to_signed(to_integer(pipe(g_stages).mantissa), 32) when fthru(g_stages).sign = '0'
                else -to_signed(to_integer(pipe(g_stages).mantissa), 32);

    float_to_fixed_out.result   <= result_i;
    float_to_fixed_out.is_ready <= strobe(g_stages);

end architecture rtl;
