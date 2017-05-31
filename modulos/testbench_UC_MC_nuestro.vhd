-- TestBench Template

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

  ENTITY testbench IS
  END testbench;

  ARCHITECTURE behavior OF testbench IS

  -- Component Declaration
  COMPONENT UC_MC is
  Port (
              clk : in  STD_LOGIC;
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
    END COMPONENT;

      SIGNAL CLK, reset, RE, WE, hit, bus_wait, MC_RE, MC_WE,mux_MC_DOUT, mux_ADDR,save_ADDR,mux_DIN ,save_DIN, bus_WE, bus_RE, MC_tags_WE, mux_origen, ready, send_addr, send_data, burst :  std_logic;
      signal palabra,palabra_solicitada: STD_LOGIC_VECTOR (1 downto 0);

  -- Clock period definitions
   constant CLK_period : time := 10 ns;
  BEGIN

  -- Component Instantiation

   uut: UC_MC port map (clk => clk, reset=> reset, RE => RE, WE => WE,
   hit => hit, bus_wait => bus_wait, MC_RE => MC_RE, palabra_solicitada => palabra_solicitada ,
   MC_WE => MC_WE, bus_RE => bus_RE, bus_WE => bus_WE, MC_tags_WE=> MC_tags_WE,
   palabra => palabra, mux_origen => mux_origen, ready => ready, MC_send_addr => send_addr,
   MC_send_data => send_data, burst => burst, mux_MC_DOUT => mux_MC_DOUT,
   mux_ADDR => mux_ADDR, save_ADDR => save_ADDR, mux_DIN => mux_DIN, save_DIN => save_DIN);

-- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;

   stim_proc: process
    begin
    palabra_solicitada <= "01";
    reset <= '1';
    RE <= '0';
    we <= '0';
    hit <= '0';
    bus_wait <= '0';
    wait for CLK_period*2;
    reset <= '0'; --simulamos lecturas en acierto
    RE <= '1';
    hit <= '1';
    wait for CLK_period*3;
    RE <= '1';
    hit <= '0';
    bus_wait <= '1';
    wait for CLK_period*4; --MD tarda cuatro ciclos en dar el primer dato
    bus_wait <= '0';
    wait until ready = '1'; --se gestiona el fallo
    RE <= '0';
    wait for CLK_period*3;
    WE <= '1'; --simulamos escritura en acierto
    hit <= '1';
    bus_wait <= '1'; --MD tarda un ciclo en responder
    wait for CLK_period;
    bus_wait <= '0';
    wait until ready = '1'; --se gestiona la escritura
    RE <= '0';
    WE <= '1'; --simulamos escritura en fallo
    hit <= '0';
    wait for CLK_period;
    wait until ready = '1'; --se gestiona el fallo
    wait;
    end process;

  END;
