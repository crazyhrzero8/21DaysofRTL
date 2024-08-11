library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
	 Generic ( -- DEFAULT SPECS FROM PROCESSOR
				  data_bus_width : integer := 32;
				  addr_bus_width : integer := 32;
				  -- DEFAULT SPECS FROM CACHE CONTROLLER
				  index_bits  	  : integer  := 2;   
			     tag_bits       : integer  := 6;
				  set_offset_bits : integer := 2;
				  -- DEFAULT SPECS FROM CACHE MEMORY DATA ARRAY
				  loctn_bits     : integer := 4;
				  offset_bits 	  : integer := 2;   
				  block_size     : integer := 128; 
				  -- DEFAULT SPECS FROM MAIN MEMORY
				  bulk_read_size : integer := 128; 
	           bank_word_size : integer := 32;  
				  addr_width     : integer := 10;
              -- OTHERS	DERIVED FROM ABOVE SPECS				  
				  tag_offset     : integer := 9; -- LOCAL ADDRESS --> | TAG  | INDEX | OFFSET |
				  index_offset   : integer := 3;
				  block_offset   : integer := 1
				);
	 Port ( clock : in STD_LOGIC; -- GLOBAL CLOCK
			  reset : in STD_LOGIC; -- GLOBAL ASYNC RESET
			  addr  : in STD_LOGIC_VECTOR (addr_bus_width-1 downto 0);  -- ADDRESS BUS
			  rdata : out STD_LOGIC_VECTOR (data_bus_width-1 downto 0); -- DATA BUS FOR READ
			  wdata : in STD_LOGIC_VECTOR (data_bus_width-1 downto 0);  -- DATA BUS FOR WRITE
			  flush : in STD_LOGIC; -- FLUSH CACHE LINES
			  rd    : in STD_LOGIC; -- READ SIGNAL FROM PROCESSOR
			  wr    : in STD_LOGIC; -- WRITE SIGNAL FROM PROCESSOR
			  stall : out STD_LOGIC -- STALL SIGNAL TO PROCESSOR			  
			);
end top;

architecture Behavioral of top is

-- INTERCONNECT SIGNALS
signal addr_local : STD_LOGIC_VECTOR (addr_width-1 downto 0); -- LOCALLY ADDRESSABLE MEMORY SPACE

-- FOR MAIN MEMORY CONNECTIONS
signal ready_inter  : STD_LOGIC;
signal data_from_mem_inter : STD_LOGIC_VECTOR (block_size-1 downto 0);  
signal rd_inter_mem : STD_LOGIC;
signal wr_inter_mem : STD_LOGIC;

-- FOR CACHE DATA ARRAY CONNECTIONS
signal refill_inter : STD_LOGIC;
signal update_inter : STD_LOGIC;
signal index_inter  : STD_LOGIC_VECTOR (index_bits+set_offset_bits-1 downto 0);

-- SUB MODULES
COMPONENT Cache_Controller
    Port ( clock			 : in STD_LOGIC; 
			  reset			 : in STD_LOGIC; 
			  flush			 : in STD_LOGIC; 
			  rd   			 : in STD_LOGIC; 
			  wr   			 : in STD_LOGIC; 
			  ix			 : in STD_LOGIC_VECTOR (index_bits-1 downto 0); 
			  tag  			 : in STD_LOGIC_VECTOR (tag_bits-1 downto 0);   
			  ready			 : in STD_LOGIC;  
           loctn         : out STD_LOGIC_VECTOR(index_bits+set_offset_bits-1 downto 0); 			  
			  refill			 : out STD_LOGIC;    
			  update			 : out STD_LOGIC;    
			  read_from_mem : out STD_LOGIC;    
			  write_to_mem  : out STD_LOGIC;    
			  stall 			 : out STD_LOGIC);		
END COMPONENT;

COMPONENT Cache_Memory_Data_Array
    Port ( clock  		 : in STD_LOGIC;      
			  refill 		 : in STD_LOGIC; 
			  update 		 : in STD_LOGIC; 
			  ix         : in STD_LOGIC_VECTOR (loctn_bits-1 downto 0);      
			  offset 		 : in STD_LOGIC_VECTOR (offset_bits-1 downto 0);     
			  data_from_mem : in STD_LOGIC_VECTOR (block_size-1 downto 0);      
			  write_data    : in STD_LOGIC_VECTOR (data_bus_width-1 downto 0);  
			  read_data     : out STD_LOGIC_VECTOR(data_bus_width-1 downto 0)); 	
END COMPONENT;

COMPONENT Main_Memory_System
    Port ( clock      : in  STD_LOGIC;   
			  reset 	    : in STD_LOGIC;    
           rd         : in  STD_LOGIC;   
           wr         : in STD_LOGIC;	    
           addr       : in  STD_LOGIC_VECTOR (addr_width-1 downto 0); 
           data_in    : in  STD_LOGIC_VECTOR (bank_word_size-1  downto 0); 
           data_out   : out  STD_LOGIC_VECTOR (bulk_read_size-1  downto 0); 
           data_ready : out  STD_LOGIC); 
END COMPONENT;

begin

addr_local <= addr(addr_width-1 downto 0);

--INSTANTIATING SUB MODULES
Inst_Cache_Controller: Cache_Controller PORT MAP(
		clock => clock,
		reset => reset,
		flush => flush,
		rd => rd,
		wr => wr,
		ix => addr_local(index_offset downto block_offset+1),
		tag   => addr_local(tag_offset downto index_offset+1),
		ready => ready_inter,
		loctn => index_inter,
		refill => refill_inter,
		update => update_inter,
		read_from_mem => rd_inter_mem,
		write_to_mem  => wr_inter_mem,
		stall => stall
	);

Inst_Cache_Memory_Data_Array: Cache_Memory_Data_Array PORT MAP(
		clock  => clock,
		refill => refill_inter,
		update => update_inter,
		ix  => index_inter,
		offset => addr_local(block_offset downto 0),
		data_from_mem => data_from_mem_inter ,
		write_data => wdata,
		read_data  => rdata
	);

Inst_Main_Memory_System: Main_Memory_System PORT MAP(
		clock => clock,
		reset => reset,
		rd    => rd_inter_mem,
		wr    => wr_inter_mem,
		addr  => addr_local,
		data_in  => wdata,
		data_out => data_from_mem_inter ,
		data_ready => ready_inter
	);

end Behavioral;

