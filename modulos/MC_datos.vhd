----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    10:38:16 04/08/2014
-- Design Name:
-- Module Name:
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: La memoria cache est� compuesta de 4 bloques de 4 datos con: emplazamiento directo, escritura directa, y la politica convencional en fallo de escritura (fetch on write miss).
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;


entity MC_datos is port (
		  CLK : in std_logic;
		  reset : in  STD_LOGIC;
		  --Interfaz con el MIPS
		  ADDR : in std_logic_vector (31 downto 0); --Dir
		  Din : in std_logic_vector (31 downto 0);
        RE : in std_logic;		-- read enable
        WE : in  STD_LOGIC;
        ready : out  std_logic;  -- indica si podemos hacer la operaci�n solicitada en el ciclo actual
		  Dout : out std_logic_vector (31 downto 0);
		  --Interfaz con el bus
		  MC_Bus_Din : in std_logic_vector (31 downto 0);--para leer datos del bus
		  bus_wait : in  STD_LOGIC; --indica que el esclavo (la memoriade datos)  no puede realizar la operaci�n solicitada en este ciclo
		  MC_send_addr : out  STD_LOGIC; --ordena que se env�en la direcci�n y las se�ales de control al bus
        MC_send_data : out  STD_LOGIC; --ordena que se env�en los datos
        MC_burst : out  STD_LOGIC; --indica que la operaci�n no ha terminado
        MC_Bus_ADDR : out std_logic_vector (31 downto 0); --Dir
        MC_Bus_data_out : out std_logic_vector (31 downto 0);--para enviar datos por el bus
        MC_bus_RE : out  STD_LOGIC; --RE y WE del bus
        MC_bus_WE : out  STD_LOGIC
		  );
end MC_datos;

architecture Behavioral of MC_datos is

component UC_MC is
    Port ( 	clk : in  STD_LOGIC;
				reset : in  STD_LOGIC;
				RE : in  STD_LOGIC; --RE y WE son las ordenes del MIPs
				WE : in  STD_LOGIC;
				hit : in  STD_LOGIC; --se activa si hay acierto
				bus_wait : in  STD_LOGIC; --indica que la memoria no puede realizar la operaci�n solicitada en este ciclo
				MC_RE : out  STD_LOGIC; --RE y WE de la MC
        palabra_solicitada : in  STD_LOGIC_VECTOR (1 downto 0); -- palabra que se solicita dentro del bloque de datos
        MC_WE : out  STD_LOGIC;
            bus_RE : out  STD_LOGIC; --RE y WE de la MC
            bus_WE : out  STD_LOGIC;
            MC_tags_WE : out  STD_LOGIC; -- para escribir la etiqueta en la memoria de etiquetas
            palabra : out  STD_LOGIC_VECTOR (1 downto 0);--indica la palabra actual dentro de una transferencia de bloque (1�, 2�...)
            mux_origen: out STD_LOGIC; -- Se utiliza para elegir si el origen de la direcci�n y el dato es el Mips (cuando vale 0) o la UC y el bus (cuando vale 1)
            ready : out  STD_LOGIC; -- indica si podemos procesar la orden actual del MIPS en este ciclo. En caso contrario habr� que detener el MIPs
            MC_send_addr : out  STD_LOGIC; --ordena que se env�en la direcci�n y las se�ales de control al bus
            MC_send_data : out  STD_LOGIC; --ordena que se env�en los datos
            burst : out  STD_LOGIC; --indica que la operaci�n no ha terminado

            mux_MC_DOUT : out  STD_LOGIC;
            mux_ADDR : out  STD_LOGIC;
            save_ADDR : out  STD_LOGIC;
            mux_DIN : out  STD_LOGIC;
            save_DIN : out  STD_LOGIC
           );
end component;

component reg4 is
    Port (  Din : in  STD_LOGIC_VECTOR (3 downto 0);
            clk : in  STD_LOGIC;
				reset : in  STD_LOGIC;
            load : in  STD_LOGIC;
            Dout :out  STD_LOGIC_VECTOR (3 downto 0));
end component;

-- definimos la memoria de contenidos de la cache de instrucciones como un array de 16 palabras de 32 bits
type Ram_MC_data is array(0 to 15) of std_logic_vector(31 downto 0);
signal MC_data : Ram_MC_data := (  		X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- posiciones 0,1,2,3,4,5,6,7
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000");
-- definimos la memoria de etiquetas de la cache de instrucciones como un array de 4 palabras de 26 bits
type Ram_MC_Tags is array(0 to 3) of std_logic_vector(25 downto 0);
signal MC_Tags : Ram_MC_Tags := (  		"00000000000000000000000000", "00000000000000000000000000", "00000000000000000000000000", "00000000000000000000000000");
signal valid_bits_in, valid_bits_out, mask: std_logic_vector(3 downto 0); -- se usa para saber si un bloque tiene info v�lida. Cada bit representa un bloque.
signal dir_cjto: std_logic_vector(1 downto 0); -- se usa para elegir el cjto al que se accede en la cache de instrucciones.
signal dir_palabra: std_logic_vector(1 downto 0); -- se usa para elegir la instrucci�n solicitada de un determinado bloque.
signal int_bus_WE, mux_origen, MC_WE, MC_RE, MC_Tags_WE, hit, valid_bit: std_logic;
signal palabra_UC: std_logic_vector(1 downto 0); --se usa al traer un bloque nuevo a la MC (va cambiando de valos para traer todas las palabras)
signal dir_MC: std_logic_vector(3 downto 0); -- se usa para leer/escribir las instrucciones almacenas en al MC.
signal MC_Din: std_logic_vector (31 downto 0);
signal MC_Tags_Dout: std_logic_vector(25 downto 0);
signal ADDR_correcto: std_logic_vector (31 downto 0);-- Addr correspondiente al trabajo actual
signal ADDR_guardado: std_logic_vector (31 downto 0);-- Addr correspondiente al trabajo actual (registro)
signal DIN_correcto: std_logic_vector (31 downto 0);-- Addr correspondiente al trabajo actual
signal DIN_guardado: std_logic_vector (31 downto 0);-- Addr correspondiente al trabajo actual (registro)
signal mux_MC_DOUT : std_logic;
signal mux_ADDR : std_logic;
signal save_ADDR : std_logic;
signal mux_DIN : std_logic;
signal save_DIN : std_logic;
signal Dout_parcial: std_logic_vector (31 downto 0); -- representa la salida de MC_data
begin

  --- nuevo
  -- Mux inicial que mantiene duranate la escritura la addr guardada
  registro_save_ADDR: process (CLK)
     begin
         if (CLK'event and CLK = '1') then
           if ( save_ADDR = '1') then
             ADDR_guardado <= ADDR;
           end if;
         end if;
     end process;
       ADDR_correcto <= ADDR_guardado when (mux_ADDR='0') else ADDR;

    registro_save_DIN: process (CLK)
       begin
           if (CLK'event and CLK = '1') then
             if ( save_DIN = '1') then
               DIN_guardado <= Din;
             end if;
           end if;
       end process;

  DIN_correcto <= DIN_guardado when (mux_DIN='0') else Din;

  ----------

 --------------------------------------------------------------------------------------------------
 -----MC_data: memoria RAM que almacena los 4 bloques de 4 datos que puede guardar la Cache
 -- dir palabra puede venir de la entrada (cuando se busca un dato solicitado por el Mips) o de la Unidad de control, UC, (cuando se est� escribiendo un bloque nuevo
 --------------------------------------------------------------------------------------------------
 dir_palabra <= ADDR_correcto(3 downto 2) when (mux_origen='0') else palabra_UC;
 dir_cjto <= ADDR_correcto(5 downto 4); -- es emplazamiento directo
 dir_MC <= dir_cjto&dir_palabra; --para direccionar una instrucci�n hay que especificar el cjto y la palabra.
 -- la entrada de datos de la MC puede venir del Mips (acceso normal) o del bus (gesti�n de fallos)
 MC_Din <= DIN_correcto when (mux_origen='0') else MC_bus_Din;


 memoria_cache_I: process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (MC_WE = '1') then -- s�lo se escribe si WE_MC_I vale 1
                MC_data(conv_integer(dir_MC)) <= MC_Din;
            end if;
        end if;
    end process;
    Dout_parcial <= MC_data(conv_integer(dir_MC)) when (MC_RE='1') else "00000000000000000000000000000000"; --s�lo se lee si RE_MC vale 1
    Dout <= Dout_parcial when (mux_MC_DOUT='0') else MC_bus_Din;
--------------------------------------------------------------------------------------------------
-----MC_Tags: memoria RAM que almacena las 4 etiquetas
--------------------------------------------------------------------------------------------------
memoria_cache_tags: process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (MC_Tags_WE = '1') then -- s�lo se escribe si MC_Tags_WE vale 1
                MC_Tags(conv_integer(dir_cjto)) <= ADDR_correcto(31 downto 6);
            end if;
        end if;
    end process;
    MC_Tags_Dout <= MC_Tags(conv_integer(dir_cjto)) when (RE='1' or WE='1') else "00000000000000000000000000"; --s�lo se lee si RE_MC vale 1
--------------------------------------------------------------------------------------------------
-- registro de validez. Al resetear los bits de validez se ponen a 0 as� evitamos falsos positivos por basura en las memorias
-- en el bit de validez se escribe a la vez que en la memoria de etiquetas. Hay que poner a 1 el bit que toque y mantener los dem�s, para eso usamos una mascara generada por un decodificador
--------------------------------------------------------------------------------------------------
mask			<= 	"0001" when dir_cjto="00" else
						"0010" when dir_cjto="01" else
						"0100" when dir_cjto="10" else
						"1000" when dir_cjto="11" else
						"0000";
valid_bits_in <= valid_bits_out OR mask;
bits_validez: reg4 port map(	DIN_correcto => valid_bits_in, clk => clk, reset => reset, load => MC_tags_WE, Dout => valid_bits_out);
--------------------------------------------------------------------------------------------------
valid_bit <= 	valid_bits_out(0) when dir_cjto="00" else
						valid_bits_out(1) when dir_cjto="01" else
						valid_bits_out(2) when dir_cjto="10" else
						valid_bits_out(3) when dir_cjto="11" else
						'0';
hit <= '1' when ((MC_Tags_Dout= ADDR_correcto(31 downto 6)) AND (valid_bit='1'))else '0'; --comparador que compara el tag almacenado en MC con el de la direcci�n y si es el mismo y el bloque tiene el bit de v�lido activo devuelve un 1
--------------------------------------------------------------------------------------------------
-----MC_UC: unidad de control
--------------------------------------------------------------------------------------------------

-- nuevo modificado
Unidad_Control: UC_MC port map (clk => clk, reset=> reset, RE => RE, WE => WE,
hit => hit, bus_wait => bus_wait, MC_RE => MC_RE, palabra_solicitada => ADDR_correcto(3 downto 2) ,
MC_WE => MC_WE, bus_RE => MC_bus_RE, bus_WE => int_bus_WE, MC_tags_WE=> MC_tags_WE,
palabra => palabra_UC, mux_origen => mux_origen, ready => ready, MC_send_addr => MC_send_addr,
MC_send_data => MC_send_data, burst => MC_burst, mux_MC_DOUT => mux_MC_DOUT,
mux_ADDR => mux_ADDR, save_ADDR => save_ADDR, mux_DIN => mux_DIN, save_DIN => save_DIN);

--------------------------------------------------------------------------------------------------
----------- Conexiones con el bus
--------------------------------------------------------------------------------------------------
MC_bus_WE <= int_bus_WE;

MC_Bus_ADDR <= ADDR_correcto when int_bus_WE ='1' else
					ADDR_correcto(31 downto 4)&"0000";   --Si es escritura mandamos la direcci�n original, sino es un fallo y hay que mandar la direcci�n del primer elemento del bloque

MC_Bus_data_out <= DIN_correcto; -- se usa para mandar el dato a escribir

end Behavioral;
