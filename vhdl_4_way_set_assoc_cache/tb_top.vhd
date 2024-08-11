library IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
  
ENTITY tb_top IS
END tb_top;
 
ARCHITECTURE behavior OF tb_top IS 

	 -- Component Declaration for the Design Under Test (DUT)
 
    COMPONENT top
    PORT(
         clock : IN  std_logic;
         reset : IN  std_logic;
         addr : IN  std_logic_vector(31 downto 0);
         rdata : OUT  std_logic_vector(31 downto 0);
         wdata : IN  std_logic_vector(31 downto 0);
         flush : IN  std_logic;
         rd : IN  std_logic;
         wr : IN  std_logic;
         stall : OUT  std_logic
        );
    END COMPONENT;
    
   --signal d : integer := 4;
   --Inputs
   signal clock : std_logic := '0';
   signal reset : std_logic := '0';
   signal addr : std_logic_vector(31 downto 0) := (others => '0');
   signal wdata : std_logic_vector(31 downto 0) := (others => '0');
   signal flush : std_logic := '0';
   signal rd : std_logic := '0';
   signal wr : std_logic := '0';
 
 	--Outputs
   signal rdata : std_logic_vector(31 downto 0);
   signal stall : std_logic;

   -- Clock period definitions
   constant clock_period : time := 1 us; 
	
	-- ARRAY TO STORE TEST VECTORS
	type my_array is array (0 to 15) of STD_LOGIC_VECTOR (31 downto 0);
   signal test_data : my_array := (OTHERS => (OTHERS =>'0'));
   signal test_addr : my_array := (OTHERS => (OTHERS =>'0'));	
 
   ------------------- USER PROCEDURES ------------------------
	
	-- TO RESET SYSTEM 
	procedure RESET_SYS (signal reset : out std_logic) is
	begin
	   reset <= '0';
		wait for 4*clock_period;
		reset <= '1';
	end procedure;
	
	-- MODELS A LATENCY OF 4 CYCLES UNTIL THE NEXT INSTRUCTION IS DECODED
	procedure HALT (signal wr : out std_logic;
                   signal rd : out std_logic) is
	begin
	   wait for clock_period;
	   wait until clock = '1' and stall = '0';
	   wait for 1.5*clock_period; -- WAIT THEN ACKNOWLEDGE
	   wr <= '0';
		rd <= '0';		
	   wait for 4*clock_period;   -- MODELS THE LATENCY
	end procedure;
	
	-- FINISH
	procedure FINISH is
	begin
	   wait;
	end procedure;
	
	-- FLUSH INSTRUCTION
	procedure FLUSH_CACHE (signal flush : out std_logic) is
	begin
	   flush <= '1';
		wait for clock_period;
		flush <= '0';
	end procedure;
	
	-- WRITE INSTRUCTION
	procedure MEM_WR (signal tb_data : in std_logic_vector(31 downto 0);
							signal tb_addr : in std_logic_vector(31 downto 0);
							signal wdata   : out std_logic_vector(31 downto 0);
							signal addr    : out std_logic_vector(31 downto 0);
							signal wr      : out std_logic;
							signal rd      : out std_logic) is
	begin
      wdata <= tb_data;
		addr  <= tb_addr;
		wr    <= '1';
		rd	   <= '0';
   end procedure;	
	
	-- READ INSTRUCTION
	procedure MEM_RD (signal tb_addr : in std_logic_vector(31 downto 0);							
							signal addr    : out std_logic_vector(31 downto 0);
							signal wr      : out std_logic;
							signal rd      : out std_logic) is
	begin      
		addr  <= tb_addr;
		wr    <= '0';
		rd	   <= '1';
   end procedure;	
	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top PORT MAP (
          clock => clock,
          reset => reset,
          addr => addr,
          rdata => rdata,
          wdata => wdata,
          flush => flush,
          rd => rd,
          wr => wr,
          stall => stall
        );
		  
	-------------- TEST VECTORS -----------------
	test_addr(0) <= x"00000201"; -- READ MISS		
	
	test_addr(1) <= x"00000203"; -- READ HIT	
	
	test_data(2) <= x"a0a0a0a0"; -- WRITE HIT
	test_addr(2) <= x"00000201";
	
	test_addr(3) <= x"00000201"; -- READ HIT
	
	test_addr(4) <= x"00000301"; -- READ MISS
	
	test_addr(5) <= x"00000001"; -- READ MISS
	
	test_addr(6) <= x"00000101"; -- READ MISS

   test_addr(7) <= x"00000211"; -- READ MISS		
	
	test_addr(8) <= x"00000221"; -- READ MISS	
	
	test_addr(9) <= x"00000101"; -- READ HIT
	
	test_addr(10)<= x"00000271"; -- READ MISS
	
	test_addr(11)<= x"000002F1"; -- READ MISS	
	
	test_addr(12)<= x"000002E1"; -- READ MISS
	
	test_addr(13)<= x"000002EF"; -- READ MISS
	
	test_data(14)<= x"44444444"; -- WRITE HIT
	test_addr(14)<= x"000002EC";	
	
	test_addr(15)<= x"000002EF"; -- READ MISS
	
  ---------------------------------------------
  
   -- Clock process definitions
   clock_process :process
   begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
   end process;
 
   
   -- Stimulus process
   stim_proc: process
   begin	
	
      ---------- MODELLING INSTRUCTION EXECUTION BY A PROCESSOR --------
		
		-- INITIAL OPERATIONS
      RESET_SYS(reset);
      FLUSH_CACHE(flush);
		
		-- RANDOM READ WRITE REQUESTS TO MEMORY BY PROCESSOR 		
		MEM_RD(test_addr(0),addr,wr,rd);
		HALT(wr,rd);
		
		MEM_RD(test_addr(1),addr,wr,rd);	
		HALT(wr,rd);		
				
		MEM_WR(test_data(2),test_addr(2),wdata,addr,wr,rd);	
		HALT(wr,rd);
		
		MEM_RD(test_addr(3),addr,wr,rd);	
		HALT(wr,rd);
		
		MEM_RD(test_addr(4),addr,wr,rd);	
		HALT(wr,rd);
		
		MEM_RD(test_addr(5),addr,wr,rd);	
		HALT(wr,rd);
		
		MEM_RD(test_addr(6),addr,wr,rd);	
		HALT(wr,rd);	 

      MEM_RD(test_addr(7),addr,wr,rd);	
		HALT(wr,rd);		
		
		MEM_RD(test_addr(8),addr,wr,rd);	
		HALT(wr,rd);
		
		MEM_RD(test_addr(9),addr,wr,rd);	
		HALT(wr,rd);
		
		MEM_RD(test_addr(10),addr,wr,rd);	
		HALT(wr,rd);
		
		MEM_RD(test_addr(11),addr,wr,rd);	
		HALT(wr,rd);
		
		MEM_RD(test_addr(12),addr,wr,rd);	
		HALT(wr,rd);		
		
		MEM_RD(test_addr(13),addr,wr,rd);	
		HALT(wr,rd);	
		
		MEM_WR(test_data(14),test_addr(14),wdata,addr,wr,rd);	
		HALT(wr,rd);			
		
		-- FLUSH AND CHECK DATA VALIDITY
      FLUSH_CACHE(flush);
		MEM_RD(test_addr(15),addr,wr,rd);	
		HALT(wr,rd);
		
		-- FINISH OPERATIONS
      FINISH;
		-----------------------------------------------------------------------
		
   end process;

END;
