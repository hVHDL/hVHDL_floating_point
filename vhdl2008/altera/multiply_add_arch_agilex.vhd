-- this is only used in Altera Agilex series FPGAs since it uses the hard float ip
architecture agilex of multiply_add is

    use ieee.float_pkg.all;
    signal fp32_mult_a  : std_logic_vector(31 downto 0) :=to_slv(to_float(0.0, float32'high)); -- fp32_mult_a
    signal fp32_mult_b  : std_logic_vector(31 downto 0) :=to_slv(to_float(0.0, float32'high)); -- fp32_mult_b
    signal fp32_adder_a : std_logic_vector(31 downto 0) :=to_slv(to_float(0.0, float32'high)); -- fp32_chainin
    signal ena          : std_logic_vector(2 downto 0)  := (others => '1'); -- ena
    signal fp32_result  : std_logic_vector(31 downto 0)                   ; -- fp32_result

    -- agilex 3 only, left as blackbox in efinix titanium
    -----------------------------------------------------
	component native_fp32 is
		port (
			fp32_mult_a  : in  std_logic_vector(31 downto 0) := (others => 'X'); -- fp32_mult_a
			fp32_mult_b  : in  std_logic_vector(31 downto 0) := (others => 'X'); -- fp32_mult_b
			fp32_adder_a : in  std_logic_vector(31 downto 0) := (others => 'X'); -- fp32_adder_a
			clk          : in  std_logic                     := 'X';             -- clk
			ena          : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- ena
			fp32_result  : out std_logic_vector(31 downto 0)                     -- fp32_result
		);
	end component native_fp32;
    -----------------------------------------------------


    signal ready_pipeline : std_logic_vector(2 downto 0) := (others => '0');
    -----------------------------------------------------
    -----------------------------------------------------
begin


    mpya_out.is_ready <= ready_pipeline(ready_pipeline'left);
    mpya_out.result   <= fp32_result;

    -----------------------------------------------------
	u0 : component native_fp32
		port map (
            fp32_mult_a   => mpya_in.mpy_a -- fp32_mult_a.fp32_mult_a
            ,fp32_mult_b  => mpya_in.mpy_b -- fp32_mult_b.fp32_mult_b
            ,fp32_adder_a => mpya_in.add_a -- fp32_mult_b.fp32_mult_b
            ,clk          => clock         -- clk.clk
            ,ena          => ena           -- ena.ena
            ,fp32_result  => fp32_result   -- fp32_result.fp32_result
		);

    -----------------------------------------------------
    create_ready_pipeline : process(clock) is
    begin
        if rising_edge(clock) 
        then
            ready_pipeline <= ready_pipeline(ready_pipeline'left-1 downto 0) & mpya_in.is_requested;
        end if; -- rising edge
    end process;
    -----------------------------------------------------
end hfloat;
