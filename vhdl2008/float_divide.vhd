------------------------------------------------------------------------
-- float_divide - a/b for hfloat_record, mantissa division via
-- hVHDL_fixed_point's lut_reciprocal_pkg (piecewise-linear 1/x lookup).
--
-- hfloat_record's mantissa is an m-bit unsigned with the leading 1
-- explicit at bit m-1, representing mantissa_real = mantissa_int/2**m in
-- [0.5,1) (value = mantissa_real * 2**exponent - see to_real/to_hfloat in
-- float_to_real_conversions_pkg), i.e. it already sits in exactly the
-- lut's [0.5,1) domain, so its fraction bits feed the lut directly as
-- x_frac.  mantissa_a * lut_result approximates mantissa_a/mantissa_b *
-- 2**m, landing in (0.5,2) of that same scale; one conditional 1-bit
-- renormalisation (the same trick as the "+" operator in
-- float_typedefs_generic_pkg) recovers a mantissa in [0.5,1).
--
-- Pulls in hVHDL_fixed_point (source/hVHDL_fixed_point) as a submodule
-- purely for that one lut_reciprocal_pkg.vhd file.
--
-- Accuracy is bounded by the lut: only the top recip_word_length (16)
-- bits of b's mantissa are used, so this is not full precision for wider
-- mantissas - see testbenches/vhdl2008/float_divide_tb.vhd for the
-- measured error.  b = 0 is not handled (matches multiply_add/
-- float_to_fixed: no subnormals/inf/NaN in this format).
--
--   constant div_ref : float_divide_typeref := create_float_divide_typeref(hfloat32_ref);
--   signal   div_in  : div_ref.divide_in'subtype  := div_ref.divide_in;
--   signal   div_out : div_ref.divide_out'subtype := div_ref.divide_out;
--   ...
--   u_div : entity work.float_divide        -- floatref defaults to hfloat32_ref
--       port map (clock => clk, divide_in => div_in, divide_out => div_out);
--   ...
--   request_divide(div_in, a, b);            -- a, b : hfloat native serialisation
--   result <= get_divide_result(div_out);    -- valid 4 clock edges later
------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_typedefs_generic_pkg.hfloat_record;

package float_divide_pkg is

    type float_divide_in_record is record
        a            : std_logic_vector;
        b            : std_logic_vector;
        is_requested : std_logic;
    end record;

    type float_divide_out_record is record
        result   : std_logic_vector;
        is_ready : std_logic;
    end record;

    type float_divide_typeref is record
        divide_in  : float_divide_in_record;
        divide_out : float_divide_out_record;
    end record;

    function create_float_divide_typeref (floatref : hfloat_record) return float_divide_typeref;

    procedure init_float_divide (signal self_in : out float_divide_in_record);

    procedure request_divide (
        signal self_in : out float_divide_in_record;
        a              : in  std_logic_vector;
        b              : in  std_logic_vector);

    function float_divide_is_ready (self_out : float_divide_out_record) return boolean;
    function get_divide_result     (self_out : float_divide_out_record) return std_logic_vector;

end package float_divide_pkg;

package body float_divide_pkg is

    function create_float_divide_typeref (floatref : hfloat_record) return float_divide_typeref is
        constant w : natural := 1 + floatref.exponent'length + floatref.mantissa'length;
    begin
        return (
            divide_in => (
                a            => (w-1 downto 0 => '0'),
                b            => (w-1 downto 0 => '0'),
                is_requested => '0'),
            divide_out => (
                result   => (w-1 downto 0 => '0'),
                is_ready => '0'));
    end function;

    procedure init_float_divide (signal self_in : out float_divide_in_record) is
    begin
        self_in.is_requested <= '0';
    end procedure;

    procedure request_divide (
        signal self_in : out float_divide_in_record;
        a              : in  std_logic_vector;
        b              : in  std_logic_vector) is
    begin
        self_in.a            <= a;
        self_in.b            <= b;
        self_in.is_requested <= '1';
    end procedure;

    function float_divide_is_ready (self_out : float_divide_out_record) return boolean is
    begin
        return self_out.is_ready = '1';
    end function;

    function get_divide_result (self_out : float_divide_out_record) return std_logic_vector is
    begin
        return self_out.result;
    end function;

end package body float_divide_pkg;

------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_typedefs_generic_pkg.all;
    use work.float_divide_pkg.all;

entity float_divide is
    generic (
        floatref : hfloat_record := hfloat32_ref   -- constrained actual fixes exp/mant widths
    );
    port (
        clock      : in  std_logic;
        divide_in  : in  float_divide_in_record;
        divide_out : out float_divide_out_record
    );
end entity float_divide;

architecture lut of float_divide is

    use work.lut_reciprocal_pkg.all;

    constant m : natural := floatref.mantissa'length;   -- must be >= recip_word_length+1

    subtype t_hfloat is floatref'subtype;

    -- p0: unpacked operands
    signal op_a, op_b : t_hfloat := floatref;

    -- p1: lut index registered, a's mantissa / sign / exponent piped alongside
    signal x_frac_r    : unsigned(recip_word_length-1 downto 0) := (others => '0');
    signal mant_a_p1   : unsigned(m-1 downto 0)          := (others => '0');
    signal sign_p1     : std_logic                       := '0';
    signal exponent_p1 : signed(floatref.exponent'range) := (others => '0');

    -- p2: lut result (2/mantissa_b) registered, a/sign/exponent piped alongside
    signal y_scaled    : unsigned(recip_word_length-1 downto 0) := (others => '0');
    signal mant_a_p2   : unsigned(m-1 downto 0)          := (others => '0');
    signal sign_p2     : std_logic                       := '0';
    signal exponent_p2 : signed(floatref.exponent'range) := (others => '0');

    -- p3: mantissa_a * (2/mantissa_b) registered, sign/exponent piped alongside
    signal product     : unsigned(m + recip_word_length - 1 downto 0) := (others => '0');
    signal sign_p3      : std_logic                       := '0';
    signal exponent_p3  : signed(floatref.exponent'range)  := (others => '0');

    signal ready_pipe : std_logic_vector(3 downto 0) := (others => '0');

begin

    op_a <= to_hfloat(divide_in.a, floatref);
    op_b <= to_hfloat(divide_in.b, floatref);

    ------------------------------------------------------------------------
    -- p0 -> p1
    process (clock) is
    begin
        if rising_edge(clock) then
            x_frac_r    <= op_b.mantissa(m-2 downto m-1-recip_word_length);
            mant_a_p1   <= op_a.mantissa;
            sign_p1     <= op_a.sign xor op_b.sign;
            exponent_p1 <= op_a.exponent - op_b.exponent;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- p1 -> p2 : the lut is a pure function (point+slope lookup + one MAC
    -- folded into it) - registering its output is the only stage it needs
    process (clock) is
    begin
        if rising_edge(clock) then
            y_scaled    <= get_reciprocal_from_lut(x_frac_r);
            mant_a_p2   <= mant_a_p1;
            sign_p2     <= sign_p1;
            exponent_p2 <= exponent_p1;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- p2 -> p3
    process (clock) is
    begin
        if rising_edge(clock) then
            product     <= mant_a_p2 * y_scaled;
            sign_p3     <= sign_p2;
            exponent_p3 <= exponent_p2;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- p3 -> p4 : product = mantissa_a_int * lut(1/mantissa_b), i.e.
    -- (mantissa_a/mantissa_b) * 2**m * 2**(recip_word_length-2),
    -- covering (0.5,2) of that scale.  window is that value taken down to
    -- an (m+1)-bit slice - so its top bit alone decides whether the ratio
    -- was >= 1 (needs one more halving and the exponent bumped) or
    -- already in [0.5,1).
    process (clock) is
        variable window : unsigned(m downto 0);
    begin
        if rising_edge(clock) then
            window := product(m + recip_word_length - 2 downto recip_word_length - 2);
            if window(m) = '1' then
                divide_out.result <= to_std_logic(t_hfloat'(
                    sign     => sign_p3,
                    exponent => exponent_p3 + 1,
                    mantissa => window(m downto 1)));
            else
                divide_out.result <= to_std_logic(t_hfloat'(
                    sign     => sign_p3,
                    exponent => exponent_p3,
                    mantissa => window(m-1 downto 0)));
            end if;
        end if;
    end process;

    ------------------------------------------------------------------------
    ready_valid : process (clock) is
    begin
        if rising_edge(clock) then
            ready_pipe <= ready_pipe(ready_pipe'left-1 downto 0) & divide_in.is_requested;
        end if;
    end process ready_valid;

    divide_out.is_ready <= ready_pipe(ready_pipe'left);

end architecture lut;
