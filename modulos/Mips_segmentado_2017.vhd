----------------------------------------------------------------------------------
-- Description: Mips segmentado tal y como lo hemos estudiado en clase. Sus caracter�sticas son:
-- Saltos 1-retardados
-- instrucciones aritm�ticas, LW, SW y BEQ
-- MI y MD de 128 palabras de 32 bits
-- Registro de salida de 32 bits mapeado en la direcci�n FFFFFFFF. Si haces un SW en esa direcci�n se escribe en este registro y no en la memoria
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MIPs_segmentado is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  output : out  STD_LOGIC_VECTOR (31 downto 0));
end MIPs_segmentado;

architecture Behavioral of MIPs_segmentado is
component reg32 is
    Port ( Din : in  STD_LOGIC_VECTOR (31 downto 0);
           clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (31 downto 0));
end component;
---------------------------------------------------------------
-- Interfaz del componente que deb�is dise�ar
component branch_predictor is
 Port ( 	clk : in  STD_LOGIC;
			reset : in  STD_LOGIC;
 			-- Puerto de lectura se accede con los 8 bits menos significativos de PC+4 sumado en IF
			PC4 : in  STD_LOGIC_VECTOR (7 downto 0);
			branch_address_out : out  STD_LOGIC_VECTOR (31 downto 0); -- direcci�n de salto
			prediction_out : out  STD_LOGIC; -- indica si hay que saltar a la direcci�n de salto (1) o no (0)
         	-- Puerto de escritura se env�a PC+4, la direcci�n de salto y la predicci�n, y se activa la se�al update_prediction
			PC4_ID:  in  STD_LOGIC_VECTOR (7 downto 0); -- Etiqueta: 8 bits menos significativos del PC+4 de la etapa ID
			prediction_in : in  STD_LOGIC; -- predicci�n
			branch_address_in : in  STD_LOGIC_VECTOR (31 downto 0); -- direcci�n de salto
       		update:  in  STD_LOGIC); -- da la orden de actualizar la informaci�n del predictor
end component;
--------------------------------------------------------------
component adder32 is
    Port ( Din0 : in  STD_LOGIC_VECTOR (31 downto 0);
           Din1 : in  STD_LOGIC_VECTOR (31 downto 0);
           Dout : out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component mux2_1 is
  Port (   DIn0 : in  STD_LOGIC_VECTOR (31 downto 0);
           DIn1 : in  STD_LOGIC_VECTOR (31 downto 0);
		   ctrl : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component memoriaRAM_D is port (
		  CLK : in std_logic;
		  ADDR : in std_logic_vector (31 downto 0); --Dir
          Din : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
          WE : in std_logic;		-- write enable
		  RE : in std_logic;		-- read enable
		  Dout : out std_logic_vector (31 downto 0));
end component;

component memoriaRAM_I is port (
		  CLK : in std_logic;
		  ADDR : in std_logic_vector (31 downto 0); --Dir
          Din : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
          WE : in std_logic;		-- write enable
		  RE : in std_logic;		-- read enable
		  Dout : out std_logic_vector (31 downto 0));
end component;

component Banco_ID is
 Port (  IR_in : in  STD_LOGIC_VECTOR (31 downto 0); -- instrucci�n leida en IF
         PC4_in:  in  STD_LOGIC_VECTOR (31 downto 0); -- PC+4 sumado en IF
		 clk : in  STD_LOGIC;
		 reset : in  STD_LOGIC;
         load : in  STD_LOGIC;
         IR_ID : out  STD_LOGIC_VECTOR (31 downto 0); -- instrucci�n en la etapa ID
         PC4_ID:  out  STD_LOGIC_VECTOR (31 downto 0)); -- PC+4 en la etapa ID
end component;

COMPONENT BReg
    PORT(
         clk : IN  std_logic;
		     reset : in  STD_LOGIC;
         RA : IN  std_logic_vector(4 downto 0);
         RB : IN  std_logic_vector(4 downto 0);
         RW : IN  std_logic_vector(4 downto 0);
         RW_pos : in std_logic_vector (4 downto 0); --Dir para el registro postincremento
         BusW : IN  std_logic_vector(31 downto 0);
         BusW_pos : in std_logic_vector (31 downto 0);--entrada del registro con postincremento
         RegWrite : IN  std_logic;
         BusA : OUT  std_logic_vector(31 downto 0);
         BusB : OUT  std_logic_vector(31 downto 0)
        );
END COMPONENT;

component Ext_signo is
    Port ( inm : in  STD_LOGIC_VECTOR (15 downto 0);
           inm_ext : out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component two_bits_shifter is
    Port ( Din : in  STD_LOGIC_VECTOR (31 downto 0);
           Dout : out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component UC is
    Port ( IR_op_code : in  STD_LOGIC_VECTOR (5 downto 0);
           Branch : out  STD_LOGIC;
           RegDst : out  STD_LOGIC;
           ALUSrc : out  STD_LOGIC;
           MemWrite : out  STD_LOGIC;
           MemRead : out  STD_LOGIC;
           MemtoReg : out  STD_LOGIC;
           RegWrite : out  STD_LOGIC;
           MuxMD : out  STD_LOGIC; -- Mutex añadido antes de la memoria de datos
           RegWrite_rs : out  STD_LOGIC -- Controla si se hace un postincremento

           );
end component;

component HDM is
  Port (
	op_code_ID : in  STD_LOGIC_VECTOR (5 downto 0);
	op_code_EX : in  STD_LOGIC_VECTOR (5 downto 0);
	op_code_MEM : in  STD_LOGIC_VECTOR (5 downto 0);

  Reg_Rs_ID : in  STD_LOGIC_VECTOR (4 downto 0);
	Reg_Rt_ID : in  STD_LOGIC_VECTOR (4 downto 0);

	Reg_Rs_EX : in  STD_LOGIC_VECTOR (4 downto 0);
	Reg_Rt_EX : in  STD_LOGIC_VECTOR (4 downto 0);
	Reg_Rd_EX : in  STD_LOGIC_VECTOR (4 downto 0);

  Reg_Rs_MEM : in  STD_LOGIC_VECTOR (4 downto 0);
	Reg_Rt_MEM : in  STD_LOGIC_VECTOR (4 downto 0);
	Reg_Rd_MEM : in  STD_LOGIC_VECTOR (4 downto 0);

	mtx_busA : out  STD_LOGIC_VECTOR (1 downto 0);
	mtx_busB : out  STD_LOGIC_VECTOR (1 downto 0);
	signal_STOP : out  STD_LOGIC
  );
  END COMPONENT;

COMPONENT Banco_EX
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         load : IN  std_logic;
         busA : IN  std_logic_vector(31 downto 0);
         busB : IN  std_logic_vector(31 downto 0);
         busA_EX : OUT  std_logic_vector(31 downto 0);
         busB_EX : OUT  std_logic_vector(31 downto 0);
		     inm_ext: IN  std_logic_vector(31 downto 0);
		     inm_ext_EX: OUT  std_logic_vector(31 downto 0);
         RegDst_ID : IN  std_logic;
         ALUSrc_ID : IN  std_logic;
         MemWrite_ID : IN  std_logic;
         MemRead_ID : IN  std_logic;
         MemtoReg_ID : IN  std_logic;
         RegWrite_ID : IN  std_logic;
         RegDst_EX : OUT  std_logic;
         ALUSrc_EX : OUT  std_logic;
         MemWrite_EX : OUT  std_logic;
         MemRead_EX : OUT  std_logic;
         MemtoReg_EX : OUT  std_logic;
         RegWrite_EX : OUT  std_logic;

		     ALUctrl_ID: in STD_LOGIC_VECTOR (2 downto 0);
		     ALUctrl_EX: out STD_LOGIC_VECTOR (2 downto 0);

         IR_op_code_ID : in  STD_LOGIC_VECTOR (5 downto 0); -- Propagacion cod instruccion
         IR_op_code_EX : out  STD_LOGIC_VECTOR (5 downto 0);

         Reg_Rs_ID : in  STD_LOGIC_VECTOR (4 downto 0); -- Propagacion registros
         Reg_Rt_ID : in  STD_LOGIC_VECTOR (4 downto 0);
         Reg_Rd_ID : in  STD_LOGIC_VECTOR (4 downto 0);
         Reg_Rs_EX : out  STD_LOGIC_VECTOR (4 downto 0);
         Reg_Rt_EX : out  STD_LOGIC_VECTOR (4 downto 0);
         Reg_Rd_EX : out  STD_LOGIC_VECTOR (4 downto 0);

         --Nuevo UC
         MuxMD_ID : in STD_LOGIC;
         MuxMD_EX : out STD_LOGIC;

         RegWrite_rs_ID : in STD_LOGIC;
         RegWrite_rs_EX : out STD_LOGIC

        );
    END COMPONENT;

    COMPONENT ALU
    PORT(
         DA : IN  std_logic_vector(31 downto 0);
         DB : IN  std_logic_vector(31 downto 0);
         ALUctrl : IN  std_logic_vector(2 downto 0);
         Dout : OUT  std_logic_vector(31 downto 0)
               );
    END COMPONENT;

	 component mux2_5bits is
		  Port (   DIn0 : in  STD_LOGIC_VECTOR (4 downto 0);
				   DIn1 : in  STD_LOGIC_VECTOR (4 downto 0);
				   ctrl : in  STD_LOGIC;
				   Dout : out  STD_LOGIC_VECTOR (4 downto 0));
		end component;

-- Nuestro mutex de 4 entradas
    COMPONENT mux4_5bits
    Port (   DIn0 : in  STD_LOGIC_VECTOR (4 downto 0);
             DIn1 : in  STD_LOGIC_VECTOR (4 downto 0);
             DIn2 : in  STD_LOGIC_VECTOR (4 downto 0);
             DIn3 : in  STD_LOGIC_VECTOR (4 downto 0);
    			   ctrl : in  STD_LOGIC_VECTOR (1 downto 0);
             Dout : out  STD_LOGIC_VECTOR (4 downto 0));
    END COMPONENT;

COMPONENT Banco_MEM
    PORT(
         ALU_out_EX : IN  std_logic_vector(31 downto 0);
         ALU_out_MEM : OUT  std_logic_vector(31 downto 0);
         clk : IN  std_logic;
         reset : IN  std_logic;
         load : IN  std_logic;
         MemWrite_EX : IN  std_logic;
         MemRead_EX : IN  std_logic;
         MemtoReg_EX : IN  std_logic;
         RegWrite_EX : IN  std_logic;
         MemWrite_MEM : OUT  std_logic;
         MemRead_MEM : OUT  std_logic;
         MemtoReg_MEM : OUT  std_logic;
         RegWrite_MEM : OUT  std_logic;
         BusB_EX : IN  std_logic_vector(31 downto 0);
         BusB_MEM : OUT  std_logic_vector(31 downto 0);
         RW_EX : IN  std_logic_vector(4 downto 0);
         RW_MEM : OUT  std_logic_vector(4 downto 0);

         IR_op_code_EX : in  STD_LOGIC_VECTOR (5 downto 0); -- Propagacion cod instruccion
         IR_op_code_MEM : out  STD_LOGIC_VECTOR (5 downto 0);

         Reg_Rs_EX : in  STD_LOGIC_VECTOR (4 downto 0); -- Propagacion registros
         Reg_Rt_EX : in  STD_LOGIC_VECTOR (4 downto 0);
         Reg_Rd_EX : in  STD_LOGIC_VECTOR (4 downto 0);
         Reg_Rs_MEM : out  STD_LOGIC_VECTOR (4 downto 0);
         Reg_Rt_MEM : out  STD_LOGIC_VECTOR (4 downto 0);
         Reg_Rd_MEM : out  STD_LOGIC_VECTOR (4 downto 0);

         --Para nuevas instrucciones
         BusA_EX: in  STD_LOGIC_VECTOR (31 downto 0);
         BusA_MEM: out  STD_LOGIC_VECTOR (31 downto 0);

         --Nuevo UC
         MuxMD_EX : in STD_LOGIC;
         MuxMD_MEM : out STD_LOGIC;

         RegWrite_rs_EX : in STD_LOGIC;
         RegWrite_rs_MEM : out STD_LOGIC

        );
    END COMPONENT;

    COMPONENT Banco_WB
    PORT(
         MuxMD_out_MEM : in  STD_LOGIC_VECTOR (31 downto 0);
         MuxMD_out_WB : out  STD_LOGIC_VECTOR (31 downto 0);
         MEM_out : IN  std_logic_vector(31 downto 0);
         MDR : OUT  std_logic_vector(31 downto 0);
         clk : IN  std_logic;
         reset : IN  std_logic;
         load : IN  std_logic;
         MemtoReg_MEM : IN  std_logic;
         RegWrite_MEM : IN  std_logic;
         MemtoReg_WB : OUT  std_logic;
         RegWrite_WB : OUT  std_logic;
         RW_MEM : IN  std_logic_vector(4 downto 0);
         RW_WB : OUT  std_logic_vector(4 downto 0);

         -- postincremento
         RW_MEM_rs : in  STD_LOGIC_VECTOR (4 downto 0);
         RW_WB_rs : out  STD_LOGIC_VECTOR (4 downto 0);

         ALU_out_MEM : in  STD_LOGIC_VECTOR (31 downto 0);
         ALU_out_WB : out  STD_LOGIC_VECTOR (31 downto 0);

         --Nuevo UC
         RegWrite_rs_MEM : in STD_LOGIC;
         RegWrite_rs_WB : out STD_LOGIC

        );
    END COMPONENT;

signal load_PC, PCSrc, RegWrite_ID, RegWrite_EX, RegWrite_MEM, RegWrite_WB, Z, Branch, RegDst_ID, RegDst_EX, ALUSrc_ID, ALUSrc_EX: std_logic;
signal MemtoReg_ID, MemtoReg_EX, MemtoReg_MEM, MemtoReg_WB, MemWrite_ID, MemWrite_EX, MemWrite_MEM, MemRead_ID, MemRead_EX, MemRead_MEM: std_logic;
signal PC_in, PC_out, four, PC4, Dirsalto_ID, IR_in, IR_ID, PC4_ID, inm_ext_EX, Mux_out, MuxMD_out_MEM, MuxMD_out_WB : std_logic_vector(31 downto 0);
signal BusW, BusA, BusB, BusA_EX, BusA_MEM, BusB_EX, BusB_MEM, inm_ext, inm_ext_x4, ALU_out_EX, ALU_out_MEM, ALU_out_WB, Mem_out, MDR : std_logic_vector(31 downto 0);
signal RW_EX, RW_MEM, RW_WB, Reg_Rd_EX, Reg_Rt_EX, Reg_Rs_EX, Reg_Rs_MEM, Reg_Rt_MEM, Reg_Rd_MEM, RW_MEM_rs, RW_WB_rs : std_logic_vector(4 downto 0);
signal ALUctrl_ID, ALUctrl_EX : std_logic_vector(2 downto 0);
signal IR_op_code_EX, IR_op_code_ID, IR_op_code_MEM : out  STD_LOGIC_VECTOR (5 downto 0);
signal mtx_busA, mtx_busB: std_logic_vector(1 downto 0); -- Señales para controlar los mutex nuevos
signal mutex_busA_salida, mutex_busB_salida : std_logic_vector(31 downto 0);
signal MuxMD_ID, RegWrite_rs_ID, MuxMD_EX, MuxMD_MEM, RegWrite_rs_EX, RegWrite_rs_MEM, RegWrite_rs_WB  : STD_LOGIC; -- Mutex añadido antes de la memoria de datos

begin
pc: reg32 port map (	Din => PC_in, clk => clk, reset => reset, load => load_PC, Dout => PC_out);
------------------------------------------------------------------------------------
-- vale '1' porque en la versi�n actual el procesador no para nunca
-- Si queremos detener una instrucci�n en la etapa fetch habr� que ponerlo a '0'
load_PC <= '1';
------------------------------------------------------------------------------------
four <= "00000000000000000000000000000100";

adder_4: adder32 port map (Din0 => PC_out, Din1 => four, Dout => PC4);
------------------------------------------------------------------------------------
-- Este mux elige entre PC+4 o la Direcci�n de salto generada en ID
muxPC: mux2_1 port map (Din0 => PC4, DIn1 => Dirsalto_ID, ctrl => PCSrc, Dout => PC_in);
------------------------------------------------------------------------------------
-- si leemos una instrucci�n equivocada tenemos que modificar el c�digo de operaci�n antes de almacenarlo en memoria
Mem_I: memoriaRAM_I PORT MAP (CLK => CLK, ADDR => PC_out, Din => "00000000000000000000000000000000", WE => '0', RE => '1', Dout => IR_in);
------------------------------------------------------------------------------------
-- el load vale uno porque este procesador no para nunca. Si queremos que una instrucci�n no avance habr� que poner el load a '0'
Banco_IF_ID: Banco_ID port map (	IR_in => IR_in, PC4_in => PC4, clk => clk, reset => reset, load => '1', IR_ID => IR_ID, PC4_ID => PC4_ID);
--
------------------------------------------Etapa ID-------------------------------------------------------------------
-- Hay que a�adir un nuevo puerto de escritura al banco de registros para la instrucci�n de post-incremento
Register_bank: BReg PORT MAP (clk => clk, reset => reset, RA => IR_ID(25 downto 21), RB => IR_ID(20 downto 16), RW => RW_WB, BusW => BusW,
									RegWrite => RegWrite_WB, BusA => BusA, BusB => BusB);
-------------------------------------------------------------------------------------
sign_ext: Ext_signo port map (inm => IR_ID(15 downto 0), inm_ext => inm_ext);

two_bits_shift: two_bits_shifter	port map (Din => inm_ext, Dout => inm_ext_x4);

adder_dir: adder32 port map (Din0 => inm_ext_x4, Din1 => PC4_ID, Dout => Dirsalto_ID);

Z <= '1' when (busA=busB) else '0';

------------------------gesti�n de la parada en ID-----------------------------------
-- incluir aqu� el c�digo que detecta los riesgos de datos

-- operación actual = IR_ID(31 downto 26)
-- operación un ciclo por delante =
-- operación dos ciclos por delante =

-- registro rs usado en este ciclo =
-- registro rs usado un ciclo antes =
-- registro rs usado dos ciclos antes =

-- registro rt usado en este ciclo =
-- registro rt usado un ciclo antes =
-- registro rt usado dos ciclos antes =

-- registro rd usado en este ciclo =
-- registro rd usado un ciclo antes =
-- registro rd usado dos ciclos antes =


mtx_busA <= '00' when () else
            '01' when () else
            '10' when () else
            '11' when others;
mtx_busB <= '00' when () else
            '01' when () else
            '10' when () else
            '11' when others;

-------------------------------------------------------------------------------------
------------------------Unidad de anticipaci�n de operandos--------------------------
-- incluir aqu� el c�digo gestiona la anticipaci�n de operandos
-- BusA bus a
-- BusB bus b
-- ALU_out_EX Salida ALU
-- ALU_out_MEM salida banco mem ALU
-- Mem_out salida ram

--- salidas mutex_busA_salida, mutex_busB_salida

mutex_busA : mux4_5bits port map (DIn0 => BusA, DIn1 => ALU_out_EX, DIn2 => ALU_out_MEM , DIn3 => Mem_out , ctrl => mtx_busA , Dout => mutex_busA_salida);

mutex_busB : mux4_5bits port map (DIn0 => BusB, DIn1 => ALU_out_EX, DIn2 => ALU_out_MEM , DIn3 => Mem_out , ctrl => mtx_busB , Dout => mutex_busB_salida);

-- Falta hacer la parte de modificar la uc y meter en todos los bancos la propagación de la uc
-- Y a partir de la siguiente fase

-------------------------------------------------------------------------------------
-- Deber�is incluir la nueva se�al Update_Rs en la unidad de control
---
--MuxMD_ID, RegWrite_rs_ID : out  STD_LOGIC; -- Mutex añadido antes de la memoria de datos


UC_seg: UC port map (IR_op_code => IR_ID(31 downto 26), Branch => Branch, RegDst => RegDst_ID,  ALUSrc => ALUSrc_ID, MemWrite => MemWrite_ID,
							MemRead => MemRead_ID, MemtoReg => MemtoReg_ID, RegWrite => RegWrite_ID , MuxMD => MuxMD_ID , RegWrite_rs => RegWrite_rs_ID);
-------------------------------------------------------------------------------------
-- Ahora mismo s�lo esta implementada la instrucci�n de salto BEQ. Si es una instrucci�n de salto y se activa la se�al Z se carga la direcci�n de salto, sino PC+4
PCSrc <= Branch AND Z;
-- si la operaci�n es aritm�tica (es decir: IR_ID(31 downto 26)= "000001") miro el campo funct
-- como s�lo hay 4 operaciones en la alu, basta con los bits menos significativos del campo func de la instrucci�n
-- si no es aritm�tica le damos el valor de la suma (000)
ALUctrl_ID <= IR_ID(2 downto 0) when IR_ID(31 downto 26)= "000001" else "000";
-- hay que a�adir los campos necesarios a los registros intermedios

-- instruccion_ex
-- IR_ID(31 downto 26) Instruccion actual
-- IR_ID(25 downto 21) Rs
Banco_ID_EX: Banco_EX PORT MAP ( clk => clk, reset => reset, load => '1', busA => mutex_busA_salida, busB => mutex_busB_salida, busA_EX => busA_EX, busB_EX => busB_EX,
											RegDst_ID => RegDst_ID, ALUSrc_ID => ALUSrc_ID, MemWrite_ID => MemWrite_ID, MemRead_ID => MemRead_ID,
											MemtoReg_ID => MemtoReg_ID, RegWrite_ID => RegWrite_ID, RegDst_EX => RegDst_EX, ALUSrc_EX => ALUSrc_EX,
											MemWrite_EX => MemWrite_EX, MemRead_EX => MemRead_EX, MemtoReg_EX => MemtoReg_EX, RegWrite_EX => RegWrite_EX,
											ALUctrl_ID => ALUctrl_ID, ALUctrl_EX => ALUctrl_EX, inm_ext => inm_ext, inm_ext_EX=> inm_ext_EX,
                      IR_op_code_ID=>IR_ID(31 downto 26) , IR_op_code_EX => IR_op_code_EX,
											Reg_Rt_ID => IR_ID(20 downto 16), Reg_Rd_ID => IR_ID(15 downto 11), Reg_Rs_ID => IR_ID(25 downto 21),
                      Reg_Rt_EX => Reg_Rt_EX, Reg_Rd_EX => Reg_Rd_EX , Reg_Rs_EX => Reg_Rs_EX, MuxMD_EX => MuxMD_EX , MuxMD_ID => MuxMD_ID,
                      RegWrite_rs_ID => RegWrite_rs_ID , RegWrite_rs_EX => RegWrite_rs_EX
                      );
--
------------------------------------------Etapa EX-------------------------------------------------------------------
--
muxALU_src: mux2_1 port map (Din0 => busB_EX, DIn1 => inm_ext_EX, ctrl => ALUSrc_EX, Dout => Mux_out);

ALU_MIPs: ALU PORT MAP ( DA => BusA_EX, DB => Mux_out, ALUctrl => ALUctrl_EX, Dout => ALU_out_EX);

mux_dst: mux2_5bits port map (Din0 => Reg_Rt_EX, DIn1 => Reg_Rd_EX, ctrl => RegDst_EX, Dout => RW_EX);
-- hay que a�adir los campos necesarios a los registros intermedios
Banco_EX_MEM: Banco_MEM PORT MAP ( ALU_out_EX => ALU_out_EX, ALU_out_MEM => ALU_out_MEM, clk => clk, reset => reset, load => '1', MemWrite_EX => MemWrite_EX,
												MemRead_EX => MemRead_EX, MemtoReg_EX => MemtoReg_EX, RegWrite_EX => RegWrite_EX, MemWrite_MEM => MemWrite_MEM, MemRead_MEM => MemRead_MEM,
												MemtoReg_MEM => MemtoReg_MEM, RegWrite_MEM => RegWrite_MEM, BusB_EX => BusB_EX, BusB_MEM => BusB_MEM, RW_EX => RW_EX, RW_MEM => RW_MEM,
                        IR_op_code_EX => IR_op_code_EX, IR_op_code_MEM => IR_op_code_MEM,Reg_Rs_EX => Reg_Rs_EX,Reg_Rt_EX => Reg_Rt_EX
                        Reg_Rd_EX => Reg_Rd_EX, Reg_Rs_MEM => Reg_Rs_MEM, Reg_Rt_MEM => Reg_Rt_MEM, Reg_Rd_MEM => Reg_Rd_MEM,
                        BusA_EX => BusA_EX, BusA_MEM => BusA_MEM, MuxMD_EX => MuxMD_EX, MuxMD_MEM => MuxMD_MEM,
                        RegWrite_rs_EX => RegWrite_rs_EX, RegWrite_rs_MEM => RegWrite_rs_MEM
                        );
--
------------------------------------------Etapa MEM-------------------------------------------------------------------
--

---------------------------------------
--Usado para añadir las dos nuevas instrucciones
mutex_MD : mux2_1 port map (DIn0 => BusA_MEM, DIn1 => ALU_out_MEM, ctrl => MuxMD_MEM, Dout => MuxMD_out_MEM );

Mem_D: memoriaRAM_D PORT MAP (CLK => CLK, ADDR => MuxMD_out_MEM, Din => BusB_MEM, WE => MemWrite_MEM, RE => MemRead_MEM, Dout => Mem_out);
-- hay que a�adir los campos necesarios a los registros intermedios
Banco_MEM_WB: Banco_WB PORT MAP ( ALU_out_MEM => ALU_out_MEM, ALU_out_WB => ALU_out_WB, Mem_out => Mem_out, MDR => MDR, clk => clk, reset => reset, load => '1', MemtoReg_MEM => MemtoReg_MEM, RegWrite_MEM => RegWrite_MEM,
											MemtoReg_WB => MemtoReg_WB, RegWrite_WB => RegWrite_WB, RW_MEM => RW_MEM, RW_WB => RW_WB,
                      RW_MEM_rs => RW_MEM_rs, RW_WB_rs => RW_WB_rs, MuxMD_out_MEM => MuxMD_out_MEM, MuxMD_out_WB => MuxMD_out_WB,
                      RegWrite_rs_MEM => RegWrite_rs_MEM, RegWrite_rs_WB => RegWrite_rs_WB);

--
------------------------------------------Etapa WB-------------------------------------------------------------------
--
mux_busW: mux2_1 port map (Din0 => MuxMD_out_WB, DIn1 => MDR, ctrl => MemtoReg_WB, Dout => busW);
-----------
-- output no se usa para nada. Est� puesto para que el sistema tenga alguna salida al exterior.
output <= IR_ID;
end Behavioral;
