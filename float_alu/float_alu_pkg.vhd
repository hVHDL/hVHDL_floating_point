library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.float_type_definitions_pkg.all;
    use work.float_arithmetic_operations_pkg.all;
    use work.float_adder_pkg.all;
    use work.float_multiplier_pkg.all;
    use work.normalizer_pkg.all;
    use work.denormalizer_pkg.all;

package float_alu_pkg is
------------------------------------------------------------------------
    constant fmac_pipeline_depth         : natural := float_multiplier_pipeline_depth + number_of_normalizer_pipeline_stages + number_of_denormalizer_pipeline_stages;
    constant int_to_float_pipeline_depth : natural := number_of_normalizer_pipeline_stages + 1;
    constant float_to_int_pipeline_depth : natural := number_of_denormalizer_pipeline_stages + 1;
------------------------------------------------------------------------
    type float_alu_record is record
        float_adder        : float_adder_record  ;
        adder_normalizer   : normalizer_record   ;

        float_multiplier : float_multiplier_record ;

        int_to_float_pipeline : std_logic_vector(int_to_float_pipeline_depth-1 downto 0);
        float_to_int_pipeline : std_logic_vector(float_to_int_pipeline_depth-1 downto 0);
        fmac_pipeline         : std_logic_vector(fmac_pipeline_depth downto 0);

    end record;

    constant init_float_alu : float_alu_record := (
            init_float_adder      ,
            init_normalizer       ,
            init_float_multiplier ,
            (others => '0')       ,
            (others => '0')       ,
            (others => '0')  );
        

------------------------------------------------------------------------
    procedure create_float_alu (
        signal self : inout float_alu_record);
------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure multiply (
        signal self : inout float_alu_record;
        left, right : float_record);

    procedure multiply_and_increment_counter (
        signal self : inout float_alu_record;
        signal counter_to_be_incremented : inout integer;
        left, right : float_record);
------------------------------------------------------------------------
    function multiplier_is_ready ( self : float_alu_record)
        return boolean;
------------------------------------------------------------------------
    function get_multiplier_result ( self : float_alu_record)
        return float_record;
------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure add (
        signal self : inout float_alu_record;
        left, right : float_record);

    procedure add_and_increment_counter (
        signal self : inout float_alu_record;
        signal counter_to_be_incremented : inout integer;
        left, right : float_record);

    procedure subtract (
        signal self : inout float_alu_record;
        left, right : float_record);

    procedure subtract_and_increment_counter (
        signal self : inout float_alu_record;
        signal counter_to_be_incremented : inout integer;
        left, right : float_record);
------------------------------------------------------------------------
    function add_is_ready ( self : float_alu_record)
        return boolean;
------------------------------------------------------------------------
    function get_add_result ( self : float_alu_record)
        return float_record;
------------------------------------------------------------------------
    procedure convert_float_to_integer (
        signal self : out float_alu_record;
        number_to_be_converted : float_record;
        desired_radix : in integer);
------------------------------------------------------------------------
    procedure convert_integer_to_float (
        signal self : out float_alu_record;
        number_to_be_converted : in integer;
        radix_of_converted_number : in integer);
------------------------------------------------------------------------
    function int_to_float_is_ready ( self : float_alu_record)
        return boolean;
------------------------------------------------------------------------
    function get_converted_float ( self : float_alu_record)
        return float_record;
------------------------------------------------------------------------
    function float_to_int_is_ready ( self : float_alu_record)
        return boolean;
------------------------------------------------------------------------
    function get_converted_integer ( self : float_alu_record)
        return integer;
------------------------------------------------------------------------
end package float_alu_pkg;

package body float_alu_pkg is
------------------------------------------------------------------------
    procedure create_float_alu 
    (
        signal self : inout float_alu_record
    ) 
    is
    begin

        create_denormalizer(self.float_adder.denormalizer);
        self.float_adder.adder_result  <= (self.float_adder.denormalizer.feedthrough_pipeline(number_of_denormalizer_pipeline_stages) + self.float_adder.denormalizer.denormalizer_pipeline(number_of_denormalizer_pipeline_stages));
        self.float_adder.adder_is_done <= denormalizer_is_ready(self.float_adder.denormalizer) and self.float_to_int_pipeline(self.float_to_int_pipeline'left) = '0';
        create_normalizer(self.adder_normalizer);

        create_float_multiplier(self.float_multiplier);

        if self.float_adder.adder_is_done then
            request_normalizer(self.adder_normalizer, self.float_adder.adder_result);
        end if;

        self.int_to_float_pipeline <= self.int_to_float_pipeline(self.int_to_float_pipeline'left-1 downto 0) & '0';
        self.float_to_int_pipeline <= self.float_to_int_pipeline(self.float_to_int_pipeline'left-1 downto 0) & '0';

    end procedure;
------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure multiply
    (
        signal self : inout float_alu_record;
        left, right : float_record
    ) is
    begin

        request_float_multiplier(
            self.float_multiplier,
            left, right);
    end multiply;

    procedure multiply_and_increment_counter
    (
        signal self : inout float_alu_record;
        signal counter_to_be_incremented : inout integer;
        left, right : float_record
    ) is
    begin

        counter_to_be_incremented <= counter_to_be_incremented + 1;

        request_float_multiplier(
            self.float_multiplier,
            left, right);

    end multiply_and_increment_counter;
------------------------------------------------------------------------
------------------------------------------------------------------------
    function multiplier_is_ready
    (
        self : float_alu_record
    )
    return boolean
    is
    begin
        return float_multiplier_is_ready(self.float_multiplier);
    end multiplier_is_ready;
------------------------------------------------------------------------
    function get_multiplier_result
    (
        self : float_alu_record
    )
    return float_record
    is
    begin
        return get_multiplier_result(self.float_multiplier);
    end get_multiplier_result;
------------------------------------------------------------------------
------------------------------------------------------------------------
    procedure add
    (
        signal self : inout float_alu_record;
        left, right : float_record
    ) is
    begin
        request_add(self.float_adder, left, right);
    end add;

    procedure add_and_increment_counter
    (
        signal self : inout float_alu_record;
        signal counter_to_be_incremented : inout integer;
        left, right : float_record
    ) is
    begin
        counter_to_be_incremented <= counter_to_be_incremented + 1;
        request_add(self.float_adder, left, right);
    end add_and_increment_counter;
------------------------------------------------------------------------
    procedure subtract
    (
        signal self : inout float_alu_record;
        left, right : float_record
    ) is
    begin
        request_add(self.float_adder, left, -right);
    end subtract;

    procedure subtract_and_increment_counter
    (
        signal self : inout float_alu_record;
        signal counter_to_be_incremented : inout integer;
        left, right : float_record
    ) is
    begin
        counter_to_be_incremented <= counter_to_be_incremented + 1;
        request_add(self.float_adder, left, -right);
    end subtract_and_increment_counter;
------------------------------------------------------------------------
    function add_is_ready
    (
        self : float_alu_record
    )
    return boolean
    is
    begin
        return normalizer_is_ready(self.adder_normalizer) and self.int_to_float_pipeline(number_of_normalizer_pipeline_stages) = '0';
    end add_is_ready;
------------------------------------------------------------------------
    function get_add_result
    (
        self : float_alu_record
    )
    return float_record
    is
    begin
        return get_normalizer_result(self.adder_normalizer);
    end get_add_result;
------------------------------------------------------------------------
    procedure convert_float_to_integer
    (
        signal self : out float_alu_record;
        number_to_be_converted : float_record;
        desired_radix : in integer
    ) is
    begin
        request_scaling(self.float_adder.denormalizer, number_to_be_converted, desired_radix);
        self.float_to_int_pipeline(0) <= '1';
    end convert_float_to_integer;
--------------------------------------------------
    procedure convert_integer_to_float
    (
        signal self : out float_alu_record;
        number_to_be_converted : in integer;
        radix_of_converted_number : in integer
    ) is
    begin
        to_float(self.adder_normalizer, number_to_be_converted, radix_of_converted_number);
        self.int_to_float_pipeline(0) <= '1';
        
    end convert_integer_to_float;

------------------------------------------------------------------------
    function int_to_float_is_ready
    (
        self : float_alu_record
    )
    return boolean
    is
    begin
        return self.int_to_float_pipeline(number_of_normalizer_pipeline_stages) = '1';
    end int_to_float_is_ready;

------------------------------------------------------------------------
    function get_converted_float
    (
        self : float_alu_record
    )
    return float_record
    is
    begin
        return get_normalizer_result(self.adder_normalizer);
    end get_converted_float;

--------------------------------------------------
    function float_to_int_is_ready
    (
        self : float_alu_record
    )
    return boolean
    is
    begin
        return self.float_to_int_pipeline(number_of_denormalizer_pipeline_stages) = '1';
    end float_to_int_is_ready;
--------------------------------------------------
    function get_converted_integer
    (
        self : float_alu_record
    )
    return integer
    is
    begin
        return get_integer(self.float_adder.denormalizer);
    end get_converted_integer;
--------------------------------------------------
end package body float_alu_pkg;
