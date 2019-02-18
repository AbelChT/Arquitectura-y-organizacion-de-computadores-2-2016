----------------------------------------------------------------------------------
--
-- Description: Este módulo sustituye a la memoria de datos del mips. Incluye un memoria cache que se conecta a través de un bus a memoria principal
-- el interfaz añade una señal nueva (Mem_ready) que indica si la MC podrá ralizar la operación en el ciclo actual
----------------------------------------------------------------------------------
library IEEE;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
-- Memoria RAM de 128 palabras de 32 bits
entity MD_mas_MC is port (
		  CLK : in std_logic;
		  reset: in std_logic; -- sólo resetea el controlador de DMA
		  ADDR : in std_logic_vector (31 downto 0); --Dir 
        Din : in std_logic_vector (31 downto 0);--entrada de datos desde el Mips
        WE : in std_logic;		-- write enable	del MIPS
		  RE : in std_logic;		-- read enable del MIPS	
		  Mem_ready: out std_logic; -- indica si podemos hacer la operación solicitada en el ciclo actual
		  Dout : out std_logic_vector (31 downto 0)
		  ); --salida que puede leer el MIPS
end MD_mas_MC;

architecture Behavioral of MD_mas_MC is
-- Memoria de datos con su controlador de bus
component  MD_cont is port (
				CLK : in std_logic;
				reset: in std_logic;
				Bus_BURST: in std_logic;
				Bus_WE: in std_logic;
				Bus_RE: in std_logic;
				Bus_addr : in std_logic_vector (31 downto 0); --Dir 
				Bus_data : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
				MD_Bus_WAIT: out std_logic; -- para avisar de que no va a realizar la operación en el ciclo actual
				MD_send_data: out std_logic; -- para enviar los datos al bus
				MD_Dout : out std_logic_vector (31 downto 0)		  -- salida de datos
		  );
end component;
-- MemoriaCache de datos
COMPONENT MC_datos is port (
				CLK : in std_logic;
				reset : in  STD_LOGIC;
				--Interfaz con el MIPS
				ADDR : in std_logic_vector (31 downto 0); --Dir 
				Din : in std_logic_vector (31 downto 0);
				RE : in std_logic;		-- read enable		
				WE : in  STD_LOGIC;
				ready : out  std_logic;  -- indica si podemos hacer la operación solicitada en el ciclo actual
				Dout : out std_logic_vector (31 downto 0);
				--Interfaz con el bus
				MC_Bus_Din : in std_logic_vector (31 downto 0);--para leer datos del bus
				bus_wait : in  STD_LOGIC; --indica que el esclavo (la memoriade datos)  no puede realizar la operación solicitada en este ciclo
				MC_send_addr : out  STD_LOGIC; --ordena que se envíen la dirección y las señales de control al bus
				MC_send_data : out  STD_LOGIC; --ordena que se envíen los datos
				MC_burst : out  STD_LOGIC; --indica que la operación no ha terminado
				MC_Bus_ADDR : out std_logic_vector (31 downto 0); --Dir 
				MC_Bus_data_out : out std_logic_vector (31 downto 0);--para enviar datos por el bus
				MC_bus_RE : out  STD_LOGIC; --RE y WE del bus
				MC_bus_WE : out  STD_LOGIC
		  );
  END COMPONENT;

--señales del bus
signal Bus_addr:  std_logic_vector(31 downto 0); 
signal Bus_data:  std_logic_vector(31 downto 0); 
signal Bus_RE, Bus_WE, Bus_Wait, Bus_BURST: std_logic;
--señales de MC
signal MC_Bus_Din, MC_Bus_ADDR, MC_Bus_data_out: std_logic_vector (31 downto 0);
signal MC_send_addr, MC_send_data, MC_burst, MC_bus_RE, MC_bus_WE: std_logic;
--señales de MD
signal MD_Dout:  std_logic_vector(31 downto 0); 
signal MD_Bus_WAIT, MD_send_data: std_logic;


begin
------------------------------------------------------------------------------------------------
--   MC de datos
------------------------------------------------------------------------------------------------

	MC: MC_datos PORT MAP(clk=> clk, reset => reset, ADDR => ADDR, Din => Din, RE => RE, WE => WE, ready => Mem_ready, Dout => Dout, MC_Bus_Din => MC_Bus_Din, bus_wait => bus_wait, MC_send_addr => MC_send_addr, MC_send_data => MC_send_data, MC_burst => MC_burst, MC_Bus_ADDR => MC_Bus_ADDR, MC_Bus_data_out => MC_Bus_data_out, MC_bus_RE => MC_bus_RE, MC_bus_WE => MC_bus_WE);

------------------------------------------------------------------------------------------------	
-- Controlador de MD
------------------------------------------------------------------------------------------------
	controlador_MD: MD_cont port map (clk, reset, Bus_BURST, Bus_WE, Bus_RE, Bus_addr, Bus_data, MD_Bus_WAIT, MD_send_data, MD_Dout);

	MC_Bus_Din <= Bus_data;
------------------------------------------------------------------------------------------------	 

------------------------------------------------------------------------------------------------
--   	BUS: líneas compartidas y buffers triestado
------------------------------------------------------------------------------------------------
-- Bus datos: Dos fuentes de datos: MC y MD 
	Bus_data <= MC_Bus_data_out when MC_send_data='1' else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"; 
	Bus_data <= MD_Dout when MD_send_data ='1' else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	
-- Bus addr 
	Bus_addr <= MC_Bus_ADDR when MC_send_addr='1' else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"; 
	

-- control
	Bus_RE <= MC_bus_RE when MC_send_addr='1' else 'Z'; 
	
	
	Bus_WE <=  MC_bus_WE when MC_send_addr='1' else 'Z';
	 
	
	Bus_BURST <= MC_burst when MC_send_addr='1' else 'Z'; 
	
	
	Bus_Wait <= MD_Bus_wait; --sólo la memoria activa la señal de wait
		
------------------------------------------------------------------------------------------------	
end Behavioral;

