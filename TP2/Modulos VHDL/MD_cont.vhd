----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:12:11 04/04/2014 
-- Design Name: 
-- Module Name:    DMA - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;


entity MD_cont is port (
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
end MD_cont;

architecture Behavioral of MD_cont is

component counter is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           count_enable : in  STD_LOGIC;
           load : in  STD_LOGIC;
           D_in  : in  STD_LOGIC_VECTOR (7 downto 0);
		   count : out  STD_LOGIC_VECTOR (7 downto 0));
end component;

-- misma memoria que en el proyecto anterior
component RAM_128_32 is port (
		  CLK : in std_logic;
		  enable: in std_logic; --solo se lee o escribe si enable está activado
		  ADDR : in std_logic_vector (31 downto 0); --Dir 
        Din : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
        WE : in std_logic;		-- write enable	
		  RE : in std_logic;		-- read enable		  
		  Dout : out std_logic_vector (31 downto 0));
end component;

component reg7 is
    Port ( Din : in  STD_LOGIC_VECTOR (6 downto 0);
           clk : in  STD_LOGIC;
			  reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (6 downto 0));
end component;

signal MEM_WE, contar_palabras, resetear_cuenta,MD_enable, memoria_preparada, contar_retardos, direccion_distinta, fin_cuenta, reset_retardo, load_addr: std_logic;
signal addr_burst, addr_bus, last_addr:  STD_LOGIC_VECTOR (6 downto 0);
signal cuenta_palabras, cuenta_retardos:  STD_LOGIC_VECTOR (7 downto 0);
signal MD_addr: STD_LOGIC_VECTOR (31 downto 0);
type state_type is (Inicio, Preparado, Retardo); 
signal state, next_state : state_type; 
begin
---------------------------------------------------------------------------
-- Decodificador: identifica cuando la dirección pertenece a la MD: (X"00000000"-X"000001FF")
---------------------------------------------------------------------------

MD_enable <= '1' when Bus_addr(31 downto 9) = "00000000000000000000000" else '0'; 

---------------------------------------------------------------------------
-- HW para introducir retardos:
-- Con un contador y una sencilla máquina de estados introducimos un retardo en la memoria de forma articial. 
-- Cuando se pide una dirección nueva manda la primera palabra en 5 ciclos y el resto en uno
-- Si se accede dos veces a la misma dirección la segunda vez no hay retardo inicial
---------------------------------------------------------------------------

cont_retardos: counter port map (clk => clk, reset => reset, count_enable => contar_retardos , load=> reset_retardo, D_in => "00000000", count => cuenta_retardos);

-- este registro almacena la ultima dirección accedida. Cada vez que cambia la dirección se resetea el contador de retaros
-- La idea es simular que cuando accedes a una dirección nueva tarda más. Si siempre accedes a la misma no introducirá retardos adicionales
reg_last_addr: reg7 PORT MAP(Din => Bus_addr(8 downto 2), CLK => CLK, reset => reset, load => load_addr, Dout => last_addr);
direccion_distinta <= '0' when (last_addr= Bus_addr(8 downto 2)) else '1';
--introducimos un retardo en la memoria de forma articial. Manda la primera palabra en 5 ciclos y el resto en uno
-- Pero si los accesos son a direcciones repetidas los retardos iniciales desaparecen

fin_cuenta <= '1' when (cuenta_retardos = "00000011") else '0';
---------------------------------------------------------------------------
-- Máquina de estados para introducir retardos
---------------------------------------------------------------------------

SYNC_PROC: process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            state <= Inicio;
         else
            state <= next_state;
         end if;        
      end if;
   end process;
   
 --MEALY State-Machine - Outputs based on state and inputs
   OUTPUT_DECODE: process (state, direccion_distinta, MD_enable, fin_cuenta)
   begin
		-- valores por defecto, si no se asigna otro valor en un estado valdrán lo que se asigna aquí
		memoria_preparada <= '0';
		contar_retardos <= '0';
		reset_retardo <= '0';
		load_addr <= '0';
		next_state <= Inicio;
		-- Estado Inicio: se llega sólo con el reset. Sirve para que al acceder a la dirección 0 tras un reset introduzca los retardos         
        if (state = Inicio and MD_enable= '0') then -- si no piden nada no hacemos nada
			next_state <= Inicio;
		elsif 	(state = Inicio and MD_enable= '1') then -- Si piden algo tras un reset hay que meter los retardos
			next_state <= Retardo;
         	reset_retardo <= '1';
		-- Estado Preparado   
		elsif (state = Preparado and MD_enable= '0') then -- si no piden nada no hacemos nada
			next_state <= Preparado;
        elsif (state = Preparado and MD_enable= '1' and  direccion_distinta='0') then -- si es la misma dirección no se introducen retardos
         	next_state <= Preparado;
         	memoria_preparada <= '1';
		elsif (state = Preparado and MD_enable= '1' and  direccion_distinta='1') then -- si es una dirección vamos al estado en el que se simulan los retardos iniciales
         	next_state <= Retardo;
         	reset_retardo <= '1';
   	        -- Estado retardo
        elsif (state = Retardo and fin_cuenta = '0') then
        	next_state <= Retardo;
         	contar_retardos <= '1'; 
        elsif (state = Retardo and fin_cuenta = '1') then 	--Cuando llegue a tres se activará fin de cuenta
        	next_state <= Preparado;
        	load_addr <= '1'; --cargamos  la dirección para que al ciclo siguiente direccion_distinta sea 0
        end if;	
	end process;

---------------------------------------------------------------------------
-- calculo direcciones 
-- el contador cuenta mientras burst esté activo, la dirección pertenezca a la memoria y la memoria esté preparada para realizar la operación actual. 
---------------------------------------------------------------------------

contar_palabras <= '1' when (Bus_BURST='1' and MD_enable='1' and memoria_preparada='1') else '0';
--Si se desactiva la señal de burst la cuenta vuelve a 0 al ciclo siguiente. Para que este esquema funcione Burst debe estar un ciclo a 0 entre dos ráfagas. En este sistema esto siempre se cumple.
resetear_cuenta <= '1' when ((MD_enable = '0') OR (Bus_BURST='0')) else '0';
cont_palabras: counter port map (clk => clk, reset => reset, count_enable => contar_palabras , load=> resetear_cuenta, D_in => "00000000", count => cuenta_palabras);
addr_bus <= Bus_addr(8 downto 2);
addr_burst <= 	"0000000" when (MD_enable = '0') else
					addr_bus + cuenta_palabras(6 downto 0);
-- sólo asignamos los bits que se usan. El resto se quedan a 0.
MD_addr(8 downto 2) <= 	"0000000" when (MD_enable = '0') else
								addr_burst when (Bus_BURST='1')  else 
								addr_bus; --si es una operación de ráfaga sumamos las palabras que llevemos. Sino usamos la dirección del bus
MD_addr(1 downto 0) <= "00";
MD_addr(31 downto 9) <= "00000000000000000000000";

---------------------------------------------------------------------------
-- Memoria de datos original 
---------------------------------------------------------------------------

MEM_WE <= '1' when (Bus_WE='1' and memoria_preparada='1') else '0'; --evitamos escribir varias veces
MD: RAM_128_32 PORT MAP (CLK => CLK, enable => MD_enable, ADDR => MD_addr, Din => Bus_data, WE =>  MEM_WE, RE => Bus_RE, Dout => MD_Dout);

---------------------------------------------------------------------------
-- Envio de datos y señal WAIT al bus
---------------------------------------------------------------------------

MD_Bus_WAIT <= not(memoria_preparada);
MD_send_data <='1' when ((MD_enable='1') AND (Bus_RE='1') AND (memoria_preparada='1')) else '0'; -- si la dirección está en rango y es una lectura se carga el dato de MD en el bus

end Behavioral;

