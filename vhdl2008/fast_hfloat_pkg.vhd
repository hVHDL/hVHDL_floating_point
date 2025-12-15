
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

    use work.float_typedefs_generic_pkg.hfloat_record;
    use work.float_typedefs_generic_pkg.to_hfloat;

package fast_hfloat_pkg is

    function get_result_slice (a : unsigned; offset : integer ; hfloatref : hfloat_record) return unsigned;
    function get_shift_width(a, b, c : signed ; mantissa : unsigned) return integer;
    function get_shift(a : std_logic_vector; b : std_logic_vector ; c : std_logic_vector ; floatref : hfloat_record) return unsigned;
    function max (a, b : integer) return integer;
    function max(a,b : signed) return signed;
    function shift(a : unsigned; b : integer) return unsigned;

    type sign_array is array (natural range <>) of std_logic_vector(2 downto 0);
    function get_result_sign(pipe : natural ; sign_pipe : sign_array ; high_bit : STD_LOGIC ; op_pipe_sub_when_1 : STD_LOGIC_VECTOR) return std_logic;

end package;

package body fast_hfloat_pkg is 

    function get_shift_width(a, b, c : signed ; mantissa : unsigned) return integer is

        variable shiftwidth : integer;

    begin
        shiftwidth := to_integer(c - a - b);
        if shiftwidth > (mantissa'length)*2
        then
            shiftwidth := (mantissa'length)*2;
        end if;
        if shiftwidth < -(mantissa'length)
        then
            shiftwidth := -(mantissa'length);
        end if;
        -- if shiftwidth < 0 then
        --     shiftwidth := shiftwidth + 1;
        -- end if;
        return shiftwidth + mantissa'length;

    end get_shift_width;

    ----------------------------
    function get_result_slice (a : unsigned; offset : integer ; hfloatref : hfloat_record) return unsigned is
        variable safe_offset : integer := 0;
    begin
        safe_offset := offset;
        if safe_offset > hfloatref.mantissa'length
        then
            safe_offset := hfloatref.mantissa'length;
        end if;

        if safe_offset < -hfloatref.mantissa'length
        then
            safe_offset := -hfloatref.mantissa'length;
        end if;

        return (a(hfloatref.mantissa'length*2-1+(safe_offset) downto hfloatref.mantissa'length+(safe_offset)));
    end get_result_slice;

    function get_shift(a : std_logic_vector; b : std_logic_vector ; c : std_logic_vector ; floatref : hfloat_record) return unsigned is

        variable retval : unsigned(floatref.mantissa'length * 2-1 downto 0) := (others => '0');

    begin
        retval(get_shift_width(
                       to_hfloat(a,floatref).exponent 
                       , to_hfloat(b,floatref).exponent
                       , to_hfloat(c,floatref).exponent
                       , floatref.mantissa
                      )) := '1';
        return retval;

    end get_shift;
    ---------------------
    function max (a, b : integer) return integer is
        variable retval : integer := 0;
    begin
        if a > b
        then
            retval := a;
        else
            retval := b;
        end if;

        return retval;
    end max;

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
    ----------------------------
    function get_result_sign(pipe : natural ; sign_pipe : sign_array ; high_bit : STD_LOGIC ; op_pipe_sub_when_1 : STD_LOGIC_VECTOR) return std_logic is
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

    ----------------------------
end package body;
