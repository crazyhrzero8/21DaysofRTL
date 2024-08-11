library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Main_Memory_System is
    Generic ( bulk_read_size : integer := 128; -- DEFAULT SPECS, DATA WIDTH OF THE MEMORY SYSTEM
	           no_of_banks    : integer := 4;   -- DEFAULT SPECS, NO OF MEMORY BANKS
				  bank_sel_bits  : integer := 2;   -- DEFAULT SPECS, NO. OF BITS TO SELECT BANK
	           bank_word_size : integer := 32;  -- DEFAULT SPECS FROM MEMORY BANK
				  bank_addr_width: integer := 8;   -- DEFAULT SPECS FROM MEMORY BANK
			     addr_width     : integer := 10   -- DEFAULT SPECS, LAST TWO BITS SELECT THE BANK
				);
    Port ( clock      : in  STD_LOGIC;   -- MEMORY CLOCK 
			  reset 	    : in STD_LOGIC;    -- ASYNC RESET SIGNAL
           rd         : in  STD_LOGIC;   -- READ SIGNAL 
           wr         : in STD_LOGIC;	  -- WRITE SIGNAL		  
           addr       : in  STD_LOGIC_VECTOR (addr_width-1 downto 0); -- ADDRESS INPUT
           data_in    : in  STD_LOGIC_VECTOR (bank_word_size-1  downto 0); -- DATA INPUT FOR WRITE
           data_out   : out  STD_LOGIC_VECTOR (bulk_read_size-1  downto 0); -- DATA OUT FOR READ
           data_ready : out  STD_LOGIC); -- TO ACKNOWLEDGE THE END OF DATA PROCESSING
end Main_Memory_System;

architecture Behavioral of Main_Memory_System is

signal data_out_0   : STD_LOGIC_VECTOR (bank_word_size-1 downto 0);
signal data_out_1   : STD_LOGIC_VECTOR (bank_word_size-1 downto 0);
signal data_out_2   : STD_LOGIC_VECTOR (bank_word_size-1 downto 0);
signal data_out_3   : STD_LOGIC_VECTOR (bank_word_size-1 downto 0);
signal data_ready_0 : STD_LOGIC;
signal data_ready_1 : STD_LOGIC;
signal data_ready_2 : STD_LOGIC;
signal data_ready_3 : STD_LOGIC;
signal wr_demux     : STD_LOGIC_VECTOR (no_of_banks-1 downto 0) ; -- DE-MUX TO SELECT BANK TO WHICH WRITE HAPPENS
																		            
COMPONENT Memory_Bank
	PORT(
		clock 		: IN STD_LOGIC;
      reset		   : IN STD_LOGIC;
		rd 			: IN STD_LOGIC;
		wr 			: IN STD_LOGIC;
		addr 			: IN STD_LOGIC_VECTOR (bank_addr_width-1 downto 0);
		data_in 		: IN STD_LOGIC_VECTOR (bank_word_size-1 downto 0);          
		data_out 	: OUT STD_LOGIC_VECTOR (bank_word_size-1 downto 0);
		data_ready  : OUT STD_LOGIC
		);
END COMPONENT;

begin

-- FOUR MEMORY BANKS
Memory_Bank_0 : Memory_Bank PORT MAP(
		clock => clock,
		reset => reset,
		rd => rd,
		wr => wr_demux(3),
		addr => addr(addr_width-1 downto bank_sel_bits), -- LAST TWO BITS SELECT BANK
		data_in => data_in,
		data_out => data_out_0,
		data_ready => data_ready_0
	);
Memory_Bank_1 : Memory_Bank PORT MAP(
		clock => clock,
		reset => reset,
		rd => rd,
		wr => wr_demux(2),
		addr => addr(addr_width-1 downto bank_sel_bits),
		data_in => data_in,
		data_out => data_out_1,
		data_ready => data_ready_1
	);
Memory_Bank_2 : Memory_Bank PORT MAP(
		clock => clock,
		reset => reset,
		rd => rd,
		wr => wr_demux(1),
		addr => addr(addr_width-1 downto bank_sel_bits),
		data_in => data_in,
		data_out => data_out_2,
		data_ready => data_ready_2
	);
Memory_Bank_3 : Memory_Bank PORT MAP(
		clock => clock,
		reset => reset,
		rd => rd,
		wr => wr_demux(0),
		addr => addr(addr_width-1 downto bank_sel_bits),
		data_in => data_in,
		data_out => data_out_3,
		data_ready => data_ready_3
	);

-- PROCESS TO DE-MUX THE WRITE SIGNAL TO THE CORRESPONDING BANK
process(wr,addr(bank_sel_bits-1 downto 0))
begin
if addr(bank_sel_bits-1 downto 0) = "00" then
	wr_demux(3) <= wr;
	wr_demux(2) <= '0';
	wr_demux(1) <= '0';
	wr_demux(0) <= '0';
elsif addr(bank_sel_bits-1 downto 0) = "01" then
	wr_demux(3) <= '0';
	wr_demux(2) <= wr;
	wr_demux(1) <= '0';
	wr_demux(0) <= '0';
elsif addr(bank_sel_bits-1 downto 0) = "10" then
	wr_demux(3) <= '0';
	wr_demux(2) <= '0';
	wr_demux(1) <= wr;
	wr_demux(0) <= '0';
else
	wr_demux(3) <= '0';
	wr_demux(2) <= '0';
	wr_demux(1) <= '0';
	wr_demux(0) <= wr;
end if;
end process;

data_out <= data_out_0 & data_out_1 & data_out_2 & data_out_3; -- COMBINING WORDS FROM MEMORY BANKS
data_ready <= data_ready_0 OR data_ready_1 OR data_ready_2 OR data_ready_3; -- DATA READY SIGNAL

end Behavioral;

