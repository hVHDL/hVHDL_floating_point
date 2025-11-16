
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

end package;

package body fast_hfloat_pkg is 

    function get_shift_width(a, b, c : signed ; mantissa : unsigned) return integer is

        variable shiftwidth : integer;

    begin
        shiftwidth := to_integer(c - a - b);
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

        constant retval : unsigned(floatref.mantissa'length * 3-1 downto 0) := (0 => '1', others => '0');

    begin

        return shift_left(retval
                   ,get_shift_width(
                       to_hfloat(a,floatref).exponent 
                       , to_hfloat(b,floatref).exponent
                       , to_hfloat(c,floatref).exponent
                       , floatref.mantissa
                      )
                 );

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
    ----------------------------
    ----------------------------
end package body;
