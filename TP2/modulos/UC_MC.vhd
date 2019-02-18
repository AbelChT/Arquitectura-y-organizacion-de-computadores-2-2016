----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    13:38:18 05/15/2014
-- Design Name:
-- Module Name:    UC_slave - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: la UC incluye un contador de 2 bits para llevar la cuenta de las transferencias de bloque y una m�quina de estados
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UC_MC is
    Port ( 	clk : in  STD_LOGIC;
                reset : in  STD_LOGIC;
                RE : in  STD_LOGIC; --RE y WE son las ordenes del MIPs
                WE : in  STD_LOGIC;
                hit : in  STD_LOGIC; --se activa si hay acierto
                bus_wait : in  STD_LOGIC; --indica que el esclavo (la memoriade datos)  no puede realizar la operaci�n solicitada en este ciclo
                palabra_solicitada : in  STD_LOGIC_VECTOR (1 downto 0); -- indica la palabra deltro del bloque que nos han solicitado
                MC_RE : out  STD_LOGIC; --RE y WE de la MC
                MC_WE : out  STD_LOGIC;
                bus_RE : out  STD_LOGIC; --RE y WE del bus
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
end UC_MC;

architecture Behavioral of UC_MC is

component counter_2bits is
            Port ( clk : in  STD_LOGIC;
                   reset : in  STD_LOGIC;
                   count_enable : in  STD_LOGIC;
                   count : out  STD_LOGIC_VECTOR (1 downto 0)
                      );
end component;
-- Poned en aqu� el nombre de vuestros estados. Os recomendamos usar nombre que aporten informaci�n.
type state_type is (Inicio, fallo_lectura_1, fallo_lectura_2_palabra_no_servida, fallo_lectura_2_ready,
fallo_lectura_3_palabra_no_servida, fallo_lectura_3_ready, fallo_lectura_4_palabra_no_servida,
fallo_lectura_4_ready, escritura, lectura_antes_escritura, wait_before_write);

signal state, next_state : state_type;
--signal last_word: STD_LOGIC; --se activa cuando se est� pidiendo la �ltima palabra de un bloque
signal count_enable: STD_LOGIC; -- se activa si se ha recibido una palabra de un bloque para que se incremente el contador de palabras
signal palabra_UC : STD_LOGIC_VECTOR (1 downto 0);
signal type_op_actual: STD_LOGIC; -- 0 lectura 1 escritura
begin

-------------------------------------------------------------------------------------
-- Contador de palabras
-- El contador nos dice cuantas palabras hemos recibido. Se usa para saber cuando se termina la transferencia del bloque y para direccionar la palabra en la que se escribe el dato leido del bus en la MC
-- Indica la palabra actual dentro de una transferencia de bloque (1�, 2�...)
-------------------------------------------------------------------------------------
word_counter: counter_2bits port map (clk, reset, count_enable, palabra_UC);
-- Last_word se activa cuando estamos pidiendo la �ltima palabra
--last_word <= '1' when palabra_UC="11" else '0';
palabra <= palabra_UC;
-------------------------------------------------------------------------------------
-- Registro de estado
-------------------------------------------------------------------------------------
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

---------------------------------------------
  -- revisar si se hace en dos o en 1 process
 -------------------------------------------

-------------------------------------------------------------------------------------
-- State-Machine: Las salidas y el estado siguiente s epuden generar en el mismo proceso (t�pico en las Mealy) o en dos procesos (Moore)
-------------------------------------------------------------------------------------
   OUTPUT_DECODE: process (state, hit, bus_wait, RE, WE, palabra_solicitada) -- Recordad poner en la lista de sensibilidad todas las se�ales que se usen de entradas. Si falta alguna har� cosas raras
   begin
     -- valores por defecto, si no se asigna otro valor en un estado valdr�n lo que se asigna aqu�
     -- As� no hace falta poner el valor de todo en todos los casos
		MC_WE <= '0';
		bus_RE <= '0';
		bus_WE <= '0';
		MC_tags_WE <= '0';
		MC_RE <= '0';
		ready <= '1';
		mux_origen <= '0';
		MC_send_addr <= '0';
		MC_send_data <= '0';
		burst <= '0';
		next_state <= state;
		count_enable <= '0';
		mux_MC_DOUT <= '0';
		mux_ADDR <= '0';
		save_ADDR <= '0';
		mux_DIN <= '0';
		save_DIN <= '0';

     -- Estado VHDL (Estado en el autómata)
     -- Inicio (q0)
     -- fallo_lectura_1 (q1)
     -- fallo_lectura_2_palabra_no_servida  (q2)
     -- fallo_lectura_2_ready (q5)
     -- fallo_lectura_3_palabra_no_servida (q3)
     -- fallo_lectura_3_ready (q6)
     -- fallo_lectura_4_palabra_no_servida (q4)
     -- fallo_lectura_4_ready (q7)
	   -- fallo_escritura_1 (q8)
     -- fallo_escritura_1_2 (q10)
	   -- fallo_escritura_2 (q9)

       case state is
         when Inicio =>
          if (RE='0' AND WE='0') then
            ready <= '0';

          elsif (RE='1' AND WE='0' AND hit='1') then
            MC_RE <= '1';
            mux_ADDR <= '1';

          elsif (RE='1' AND WE='0') then
            ready <= '0';
            bus_RE <= '1';
            MC_send_addr <= '1';
            burst <= '1';
            mux_ADDR <= '1';
            save_ADDR <= '1';
            type_op_actual <= '0';
            next_state <= fallo_lectura_1;

          elsif(RE = '0' AND WE = '1' AND hit='1') then
            MC_WE <= '1';
            bus_WE <= '1';
            MC_send_addr <= '1';
            MC_send_data <= '1';
            mux_ADDR <= '1';
            save_ADDR <= '1';
            mux_DIN <= '1';
            save_DIN <= '1';
            next_state <= escritura;

          elsif(RE = '0' AND WE = '1') then
            bus_RE <= '1';
            MC_send_addr <= '1';
            burst <= '1';
            mux_ADDR <= '1';
            save_ADDR <= '1';
            mux_DIN <= '1';
            save_DIN <= '1';
            type_op_actual <= '1';
            next_state <= lectura_antes_escritura;

          end if;

         when fallo_lectura_1 =>
          if (bus_wait='1') then
            bus_RE <='1';
            MC_send_addr <= '1';
            burst <='1';
            ready <= '0';

          elsif (palabra_solicitada= "00") then
            MC_WE <='1';
            bus_RE <='1';
            MC_send_addr <= '1';
            mux_origen <='1';
            burst <='1';
            mux_MC_DOUT <='1';
            count_enable <= '1';
            next_state <= fallo_lectura_2_ready;

          else
            MC_WE <='1';
            bus_RE <='1';
            MC_send_addr <= '1';
            mux_origen <='1';
            burst <='1';
            ready <= '0';
            count_enable <= '1';
            next_state <= fallo_lectura_2_palabra_no_servida;
          end if;

         when fallo_lectura_2_palabra_no_servida =>
          if (bus_wait='1') then
            bus_RE <='1';
            MC_send_addr <= '1';
            burst <='1';
            ready <='0';

          elsif (palabra_solicitada= "01") then
            MC_WE <='1';
            bus_RE <='1';
            MC_send_addr <= '1';
            mux_origen <='1';
            burst <='1';
            mux_MC_DOUT <='1';
            count_enable <= '1';
            next_state <= fallo_lectura_3_ready;

          else
            MC_WE <='1';
            bus_RE <='1';
             MC_send_addr <= '1';
            mux_origen <='1';
            burst <='1';
            ready <= '0';
            count_enable <= '1';
            next_state <= fallo_lectura_3_palabra_no_servida;
          end if;

         when fallo_lectura_2_ready =>
          if (bus_wait='1') then
           bus_RE <='1';
            MC_send_addr <= '1';
           burst <='1';
           ready <='0';

          else
           MC_WE <='1';
           bus_RE <='1';
           MC_send_addr <= '1';
           mux_origen <='1';
           burst <='1';
           ready <= '0';
           count_enable <= '1';
           next_state <= fallo_lectura_3_ready;
          end if;


         when fallo_lectura_3_palabra_no_servida =>
          if (bus_wait='1') then
           bus_RE <='1';
           MC_send_addr <= '1';
           burst <='1';
           ready <='0';
          elsif (palabra_solicitada= "10") then
           MC_WE <='1';
           bus_RE <='1';
           MC_send_addr <= '1';
           mux_origen <='1';
           burst <='1';
           mux_MC_DOUT <='1';
           count_enable <= '1';
           next_state <= fallo_lectura_4_ready;

          else
           MC_WE <='1';
           bus_RE <='1';
            MC_send_addr <= '1';
           mux_origen <='1';
           burst <='1';
           ready <= '0';
           count_enable <= '1';
           next_state <= fallo_lectura_4_palabra_no_servida;
          end if;


         when fallo_lectura_3_ready =>
         if (bus_wait='1') then
           bus_RE <='1';
            MC_send_addr <= '1';
           burst <='1';
           ready <='0';

         else
           MC_WE <='1';
           bus_RE <='1';
            MC_send_addr <= '1';
           mux_origen <='1';
           burst <='1';
           ready <= '0';
           count_enable <= '1';
           next_state <= fallo_lectura_4_ready;
         end if;


         when fallo_lectura_4_palabra_no_servida =>
         if (bus_wait='1') then
           bus_RE <='1';
            MC_send_addr <= '1';
           burst <='1';
           ready <='0';

         else
           MC_WE <='1';
           bus_RE <= '1';
           MC_send_addr <= '1';
           MC_tags_WE <='1';
           mux_origen <='1';
           burst <='1';
           mux_MC_DOUT <= '1';
           count_enable <= '1';
           next_state <= Inicio;
         end if;


         when fallo_lectura_4_ready =>
         if (bus_wait='1') then
           bus_RE <='1';
           MC_send_addr <= '1';
           burst <='1';
           ready <='0';
         else
           if (type_op_actual='0') then
             ready <='0';
             MC_WE <='1';
             bus_RE <='1';
             MC_send_addr <= '1';
             burst <='1';
             MC_tags_WE <='1';
             mux_origen <='1';
             count_enable <= '1';
             next_state <= Inicio;
           else
             ready <='0';
             MC_WE <='1';
             bus_RE <='1';
             MC_send_addr <= '1';
             burst <='1';
             MC_tags_WE <='1';
             mux_origen <='1';
             count_enable <= '1';
             next_state <= wait_before_write;
           end if;
         end if;

          when wait_before_write =>
            ready <='0';
            MC_WE <= '1';
            bus_WE <= '1';
            MC_send_addr <= '1';
            MC_send_data <= '1';
            next_state <= escritura;
		 ---------------------------------------
         ---------------------------------------
         when escritura =>
         if(bus_wait='1') then
           bus_WE <= '1';
           MC_send_addr <= '1';
           MC_send_data <= '1';
           ready <= '0';
         else
           bus_WE <= '1';
           MC_send_addr <= '1';
           MC_send_data <= '1';
           ready <= '0';
           next_state <= Inicio;
         end if;

         when lectura_antes_escritura =>
         if (bus_wait='0') then
           MC_WE <= '1';
           bus_RE <= '1';
           MC_send_addr <= '1';
           ready <= '0';
           mux_origen <= '1';
           burst <= '1';
           count_enable <= '1';
           next_state <= fallo_lectura_2_ready;

         else
           bus_RE <= '1';
           MC_send_addr <= '1';
           ready <= '0';
           burst <= '1';
         end if;

       end case;

   end process;

end Behavioral;
