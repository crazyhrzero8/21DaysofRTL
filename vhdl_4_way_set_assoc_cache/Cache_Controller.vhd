library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Cache_Controller is
	 Generic ( index_bits  	   : integer := 2; -- 4 SETS BY DEFAULT
	           set_offset_bits : integer := 2; -- 4 ELEMENTS/ CACHE LINES PER SET BY DEFAULT
			     tag_bits        : integer := 6  -- DERIVED FROM DEFAULT SPECS OF ADDRESS BUS WIDTH (10 - 2 - 2 = 6)
				);
	 Port ( clock			 : in STD_LOGIC;   -- MAIN CLOCK
			  reset			 : in STD_LOGIC;   -- ASYNC RESET
			  flush			 : in STD_LOGIC;   -- TO FLUSH THE CACHE DATA ARRAY, INVALIDATE ALL LINES
			  rd   			 : in STD_LOGIC;   -- READ REQUEST FROM PROCESSOR
			  wr   			 : in STD_LOGIC;   -- WRITE REQUEST FROM PROCESSOR
			  ix			 : in STD_LOGIC_VECTOR(index_bits-1 downto 0); -- INDEX OF THE ADDRESS REQUESTED
			  tag  			 : in STD_LOGIC_VECTOR(tag_bits-1 downto 0);   -- TAG OF THE ADDRESS REQUESTED
			  ready			 : in STD_LOGIC;   -- DATA READY SIGNAL FROM MEMORY
			  loctn         : out STD_LOGIC_VECTOR(index_bits+set_offset_bits-1 downto 0);  -- LOCATION OF DATA IN CACHE DATA ARRAY
			  refill			 : out STD_LOGIC;  -- REFILL SIGNAL TO DATA ARRAY
			  update			 : out STD_LOGIC;  -- UPDATE SIGNAL TO DATA ARRAY
			  read_from_mem : out STD_LOGIC;  -- READ SIGNAL TO DATA MEMORY
			  write_to_mem  : out STD_LOGIC;  -- WRITE SIGNAL TO DATA MEMORY
			  stall 			 : out STD_LOGIC); -- SIGNAL TO STALL THE PROCESSOR		  
end Cache_Controller;

architecture Behavioral of Cache_Controller is

-- ALL INTERNAL SIGNALS
signal STATE : STD_LOGIC_VECTOR (7 downto 0) := (OTHERS => '0'); -- STATE SIGNAL
signal HIT   : STD_LOGIC := '0'; -- SIGNAL TO INDICATE HIT
signal MISS  : STD_LOGIC := '0'; -- SIGNAL TO INDICATE MISS
signal loctn_loc : STD_LOGIC_VECTOR(index_bits+set_offset_bits-1 downto 0); -- LOCAL FOR loctn

-- USER DEFINED TYPES
type ram is array (0 to 2**(index_bits+set_offset_bits)-1) of STD_LOGIC_VECTOR (tag_bits downto 0);
type ptr_array is array (0 to 2**index_bits-1) of STD_LOGIC;

-- INSTANCE OF RAM AS TAG ARRAY
signal tag_array : ram := (OTHERS => (OTHERS =>'0'));

-- POINTERS FOR TREE-PLRU ALGORITHM
signal S_ptr     : ptr_array := (OTHERS => '0'); -- SET POINTER/BASE POINTER FOR EACH SET
signal L_ptr     : ptr_array := (OTHERS => '0'); -- LEFT POINTER FOR EACH SET
signal R_ptr     : ptr_array := (OTHERS => '0'); -- RIGHT POINTER FOR EACH SET

begin

process(clock, reset)

-- USER VARIABLES
variable temp_tag      : STD_LOGIC_VECTOR (tag_bits downto 0);
variable temp_index    : integer;
variable temp_index_00 : integer;
variable temp_index_01 : integer;
variable temp_index_10 : integer;
variable temp_index_11 : integer;
variable index_00 	  : STD_LOGIC_VECTOR (index_bits+set_offset_bits-1 downto 0);
variable index_01 	  : STD_LOGIC_VECTOR (index_bits+set_offset_bits-1 downto 0);
variable index_10 	  : STD_LOGIC_VECTOR (index_bits+set_offset_bits-1 downto 0);
variable index_11 	  : STD_LOGIC_VECTOR (index_bits+set_offset_bits-1 downto 0);

begin
if reset = '0' then
   -- RESETTING INTERNAL SIGNALS
	STATE <= (OTHERS => '0'); 
	HIT   <= '0';
	MISS  <= '0';
	tag_array <= (OTHERS => (OTHERS =>'0'));
	loctn_loc <= (OTHERS => '0');
	S_ptr <= (OTHERS => '0');
	L_ptr <= (OTHERS => '0');
	R_ptr <= (OTHERS => '0');
	-- RESETTING OUT PORT SIGNALS	
	stall <= '0';
	read_from_mem <= '0';
	write_to_mem  <= '0';
	refill <= '0';
	update <= '0';
elsif rising_edge(clock) then
   if flush = '1' then -- HIGH PRIORITY SIGNAL TO FLUSH ENTIRE CACHE
	   tag_array <= (OTHERS => (OTHERS => '0')); -- INVALIDATE ALL CACHE LINES
		S_ptr <= (OTHERS => '0');                 -- RESET ALL PLRU POINTERS
	   L_ptr <= (OTHERS => '0');
	   R_ptr <= (OTHERS => '0');
	else
		Case STATE is		
			when x"00"  => -- INIT STATE, WHERE ALL REQUESTS START PROCESSING
			             ---- CHECKS FOR HIT OR MISS HAPPEN IN THIS STATE
						    ---- BUT NO READ DATA AVAILABLE HERE (IF READ HIT)								
			             temp_tag := '1' & tag;
							 index_00 := ix & "00";
							 index_01 := ix & "01";
							 index_10 := ix & "10";
							 index_11 := ix & "11";
							 temp_index    := to_integer(unsigned(ix));
							 temp_index_00 := to_integer(unsigned(index_00));
							 temp_index_01 := to_integer(unsigned(index_01));
							 temp_index_10 := to_integer(unsigned(index_10));
							 temp_index_11 := to_integer(unsigned(index_11));
							 
							 if ((temp_tag XOR tag_array(temp_index_00)) = "0000000") then
							    -- HIT IN THE FIRST SET
							    loctn_loc <= index_00;								 
								 HIT  <= '1';
								 MISS <= '0';
							 elsif ((temp_tag XOR tag_array(temp_index_01)) = "0000000") then
							    -- HIT IN THE SECOND SET
							    loctn_loc <= index_01;
								 HIT  <= '1';
								 MISS <= '0';
							 elsif ((temp_tag XOR tag_array(temp_index_10)) = "0000000") then
								 -- HIT IN THE THIRD SET
							    loctn_loc <= index_10;
								 HIT  <= '1';
								 MISS <= '0';
                      elsif ((temp_tag XOR tag_array(temp_index_11)) = "0000000") then
								 -- HIT IN THE FOURTH SET
                         loctn_loc <= index_11;
								 HIT  <= '1';
								 MISS <= '0';
							 else
							    -- MISS OCCURED
							    MISS <= '1';
								 HIT  <= '0';
								 ----------------------- UPDATE PLRU POINTERS -------------------------
								 -- ASSIGNING LOCATION AS PER PLRU POINTERS
								 if S_ptr(temp_index) = '0' then
								    loctn_loc <= ix & S_ptr(temp_index) & L_ptr(temp_index);
									 S_ptr(temp_index) <= '1';
									 L_ptr(temp_index) <= not L_ptr(temp_index);
								 else
								    loctn_loc <= ix & S_ptr(temp_index) & R_ptr(temp_index);
									 S_ptr(temp_index) <= '0';
									 R_ptr(temp_index) <= not R_ptr(temp_index);									 
								 end if;	
								 ----------------------------------------------------------------------
                      end if;		
							 
							 -- STATE TRANSITION NEEDED ONLY IF A READ/WRITE REQUEST IS ACTIVE
							 if rd = '1' or wr = '1' then
                         STATE <= x"01"; -- TO HIT/MISS ANALYSE STATE
							 else
								 -- NO REQUEST ACTIVE, REVERT THE CHANGES
								 S_ptr(temp_index) <= S_ptr(temp_index);
								 R_ptr(temp_index) <= R_ptr(temp_index);
								 L_ptr(temp_index) <= L_ptr(temp_index);
								 STATE <= x"00"; -- STAY IN THE SAME STATE
								 HIT   <= '0';
								 MISS  <= '0';
							 end if;   			
							 
         when x"01"  => -- HIT/MISS ANALYSE STATE
                      ---- READ DATA FOR READ HIT IS AVAILABLE IN THIS STATE								
                      if HIT = '1' then          -- IF HIT
                         if wr = '1' then        -- IF WRITE HIT
								    stall <= '1';		    -- STALL CZ MAIN MEMORY ACCESS
									 update <= '1';       -- UPDATES CACHE
								    refill <= '0';   
							       write_to_mem <= '1'; -- INITIATE WRITE TO MEMORY
								    read_from_mem <= '0';
									 STATE <= x"02";      -- GO TO WRITE HIT STATE
                         else                    -- IF READ HIT, NOTHING TO DO
								    STATE <= x"07";      -- GO TO GLOBAL WAIT STATE
                         end if;		 									 
								 --------------------- UPDATE PLRU POINTERS--------------------------
								 -- K-MAP EQUATIONS USED INSTEAD OF COARSE NESTED IF-ELSE BLOCKS
								 S_ptr(temp_index) <= not loctn_loc(1); 
								 L_ptr(temp_index) <= ((not loctn_loc(1)) AND (not loctn_loc(0))) OR 
								                      (loctn_loc(1) AND L_ptr(temp_index));
								 R_ptr(temp_index) <= (loctn_loc(1) AND (not loctn_loc(0))) OR 
								                      ((not loctn_loc(1)) AND R_ptr(temp_index));	
								 --------------------------------------------------------------------								 
							 else                        -- IF MISS
							    if rd = '1' then         -- IF READ MISS
								    stall  <= '1';		  -- STALL CZ MAIN MEMORY ACCESS
									 update <= '0';   
									 refill <= '0';   
									 write_to_mem <= '0';
									 read_from_mem <= '1'; -- INITIATE READ FROM MEMORY
									 STATE <= x"03";       -- GO TO READ MISS STATE
								 else                     -- IF WRITE MISS
								    stall <= '1';			  -- STALL CZ MAIN MEMORY ACCESS
								    update <= '0';  		  -- NO UPDATE ON CACHE
								    refill <= '0';
							       write_to_mem <= '1';  -- INITIATE WRITE TO MEMORY
								    read_from_mem <= '0';
								    STATE <= x"02";       -- GO TO WRITE MISS STATE
								 end if;
							 end if;	
							 
			when x"02"  =>	-- WRITE HIT/MISS STATE, WAIT HERE UNTIL DATA IS WRITTEN TO MEMORY
							 update <= '0';          -- STOP UPDATING CACHE
							 refill <= '0';
							 if ready = '1' then     -- IF READY, ACKNOWLEDGE THE MEMORY
							    stall <= '0';        -- SIGNAL PROCESSOR THAT NEW REQUEST CAN BE INITIATED
								 write_to_mem  <= '0';-- ACKNOWLEDGING THE MEMORY
								 read_from_mem <= '0';
								 STATE <= x"07";      -- GO TO GLOBAL WAIT STATE
							 else
								 STATE <= x"02";      -- WAIT HERE
							 end if;
							 
         when x"03"  =>	-- READ MISS STATE, WAIT HERE UNTIL DATA FROM MEMORY IS READY
							 if ready = '1' then
								 read_from_mem <= '0';-- ACKNOWLEDGING MEMORY
								 write_to_mem  <= '0';
								 refill <= '1';       -- INITIATE REFILLING CACHE DATA ARRAY
								 update <= '0';
								 STATE <= x"04";      -- GO TO REFILL/STALL DE-ASSERT STATE
							 else
								 STATE <= x"03";      -- WAIT HERE
							 end if;	
							 
         when x"04"	=> -- REFILL/STALL DE-ASSERT STATE
			             refill <= '0';
							 update <= '0';
							 tag_array(to_integer(unsigned(loctn_loc))) <= '1' & tag;  -- UPDATE TAG ARRAY
							 stall <= '0';
							 STATE <= x"07";			 -- GO TO GLOBAL WAIT STATE	
							 
			when x"07"  =>	-- GLOBAL WAIT STATE AFTER FURNISHING EVERY REQUEST
			             ---- PROCESSOR MAY GENERATE NEW REQUEST IN THE MEAN TIME
							 ---- REVERTING SIGNALS BACK TO THEIR INIT DEFAULT VALUES 
							 ---- POINTERS AND LOCATION VECTOR NEED NOT BE REVERTED
							 HIT    <= '0';
							 MISS   <= '0';
							 stall  <= '0';
							 refill <= '0';
							 update <= '0';
							 read_from_mem <= '0';
							 write_to_mem  <= '0';
							 
							 -- CHECK IF PROCESSOR FINISHED CURRENT REQUEST
							 if wr = '0' and rd = '0' then  
							    STATE <= x"00";            -- GO TO INIT STATE
							 else
							    STATE <= x"07";
							 end if;		
							 
			when OTHERS =>
							 STATE <= x"00";							 
		end Case;
	end if;
end if; -- RISING EDGE
end process;

loctn <= loctn_loc; -- ASSIGNING LOCAL SIGNAL TO THE OUTPUT PORT

end Behavioral;

