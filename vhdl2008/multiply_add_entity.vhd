LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

    use work.float_typedefs_generic_pkg.float_record;

package multiply_add_pkg is

-----------------------------------------------------
    type multiply_add_in_record is record
        mpy_a : std_logic_vector;
        mpy_b : std_logic_vector;
        add_a : std_logic_vector;
        is_requested : std_logic;
    end record;

-----------------------------------------------------
    type multiply_add_out_record is record
        result   : std_logic_vector;
        is_ready : std_logic;
    end record;

-----------------------------------------------------
    type mpya_subtype_record is record
        mpya_in  : multiply_add_in_record;
        mpya_out : multiply_add_out_record;
    end record;

-----------------------------------------------------
    function create_mpya_typeref(
        exponent_length  : natural := 8
        ;mantissa_length : natural := 23)
    return mpya_subtype_record;

-----------------------------------------------------
    function create_mpya_typeref(floatref : float_record)
        return mpya_subtype_record;
-----------------------------------------------------
    procedure init_multiply_add(signal self_in : out multiply_add_in_record);

-----------------------------------------------------
    procedure multiply_add(signal self_in : out multiply_add_in_record
        ;a : std_logic_vector
        ;b : std_logic_vector
        ;c : std_logic_vector);
-----------------------------------------------------
    function mpya_is_ready(mpya_out : multiply_add_out_record) 
        return boolean;
-----------------------------------------------------
    function get_mpya_result(mpya_out : multiply_add_out_record) return std_logic_vector;
-----------------------------------------------------

end package multiply_add_pkg;

package body multiply_add_pkg is

-----------------------------------------------------
    function create_mpya_typeref(exponent_length : natural := 8 ; mantissa_length : natural := 23)
    return mpya_subtype_record is

        constant retval : mpya_subtype_record :=(
            mpya_in => (
                mpy_a  => (exponent_length + mantissa_length downto 0 => '0')
                ,mpy_b => (exponent_length + mantissa_length downto 0 => '0')
                ,add_a => (exponent_length + mantissa_length downto 0 => '0')
                ,is_requested => '0')
            ,mpya_out => (
                result    => (exponent_length + mantissa_length downto 0 => '0')
                ,is_ready => '0')
            );

    begin

        return retval;

    end create_mpya_typeref;

-----------------------------------------------------
    function create_mpya_typeref(floatref : float_record)
    return mpya_subtype_record is

        constant exponent_length : natural := floatref.exponent'length;
        constant mantissa_length : natural := floatref.mantissa'length;

        constant retval : mpya_subtype_record :=(
            mpya_in => (
                mpy_a  => (exponent_length + mantissa_length downto 0 => '0')
                ,mpy_b => (exponent_length + mantissa_length downto 0 => '0')
                ,add_a => (exponent_length + mantissa_length downto 0 => '0')
                ,is_requested => '0')
            ,mpya_out => (
                result    => (exponent_length + mantissa_length downto 0 => '0')
                ,is_ready => '0')
            );

    begin
        return retval;
    end create_mpya_typeref;

-----------------------------------------------------
    function mpya_is_ready(mpya_out : multiply_add_out_record) return boolean
    is
    begin
        return mpya_out.is_ready = '1';
    end mpya_is_ready;
-----------------------------------------------------
    function get_mpya_result(mpya_out : multiply_add_out_record) return std_logic_vector
    is
    begin
        return mpya_out.result;
    end get_mpya_result;
-----------------------------------------------------
    procedure init_multiply_add(signal self_in : out multiply_add_in_record) 
    is
    begin
        self_in.mpy_a <= (self_in.mpy_a'range => '0');
        self_in.mpy_b <= (self_in.mpy_b'range => '0');
        self_in.add_a <= (self_in.add_a'range => '0');
        self_in.is_requested <= '0';
    end procedure;

-----------------------------------------------------
    procedure multiply_add(signal self_in : out multiply_add_in_record
        ;a : std_logic_vector
        ;b : std_logic_vector
        ;c : std_logic_vector
    ) 
    is
    begin
        self_in.mpy_a <= a;
        self_in.mpy_b <= b;
        self_in.add_a <= c;
        self_in.is_requested <= '1';
    end procedure;

-----------------------------------------------------
    procedure multiply(signal self_in : out multiply_add_in_record
        ;a : std_logic_vector
        ;b : std_logic_vector
    ) 
    is
    begin
        self_in.mpy_a <= a;
        self_in.mpy_b <= b;
        self_in.add_a <= (self_in.add_a'range => '0');
        self_in.is_requested <= '1';
    end procedure;

-----------------------------------------------------
    procedure add(signal self_in : out multiply_add_in_record
        ;a : std_logic_vector
        ;b : std_logic_vector
    ) 
    is
    begin
        self_in.mpy_a <= a;
        self_in.mpy_b <= a;  -- should be 1.0
        self_in.add_a <= b;
        self_in.is_requested <= '0';
    end procedure;

-----------------------------------------------------
    procedure sub(signal self_in : out multiply_add_in_record
        ;a : std_logic_vector
        ;b : std_logic_vector
    ) 
    is
    begin
        self_in.mpy_a <= a;
        self_in.mpy_b <= a;  -- should be 1.0
        self_in.add_a <= b; -- should be inverted
        self_in.is_requested <= '0';
    end procedure;
-----------------------------------------------------

end package body multiply_add_pkg;

LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

    use work.multiply_add_pkg.all;
    use work.float_typedefs_generic_pkg.all;

entity multiply_add is
    generic(
        g_exponent_length  : natural := 8
        ;g_mantissa_length : natural := 23
    );
    port(clock : in std_logic
        ;mpya_in   : in  multiply_add_in_record
        ;mpya_out  : out multiply_add_out_record
    );
end multiply_add;
