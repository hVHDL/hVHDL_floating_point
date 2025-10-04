LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

--- simulation 
--- ,use ip instantiation in synth code instead
    
entity native_fp32 is
    port (
        fp32_mult_a   : in  std_logic_vector(31 downto 0) := (others => 'X') -- fp32_mult_a
        ;fp32_mult_b  : in  std_logic_vector(31 downto 0) := (others => 'X') -- fp32_mult_b
        ;fp32_adder_a : in  std_logic_vector(31 downto 0) := (others => 'X') -- fp32_adder_a
        ;clk          : in  std_logic                     := 'X'             -- clk
        ;ena          : in  std_logic_vector(2 downto 0)  := (others => 'X') -- ena
        ;fp32_result  : out std_logic_vector(31 downto 0) -- fp32_result
    );
end entity native_fp32;

architecture sim of native_fp32 is

    use ieee.float_pkg.all;

    signal mpy_result   : float32 := (others => '0');
    signal mpy_result_buf   : float32 := (others => '0');
    signal add_pipeline : float32 := (others => '0');

begin

    pipelined_multiply_add : process(clk)
    begin
        if rising_edge(clk) then
            mpy_result     <= to_float(fp32_mult_a) * to_float(fp32_mult_b);
            add_pipeline   <= to_float(fp32_adder_a);
            mpy_result_buf <= mpy_result + add_pipeline;
            fp32_result    <= to_slv(mpy_result_buf);
        end if;
    end process;

end sim;
