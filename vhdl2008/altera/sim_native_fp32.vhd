LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

--- simulation model
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

begin

end sim;
