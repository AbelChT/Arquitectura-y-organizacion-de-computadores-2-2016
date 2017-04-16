package com.company;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.math.BigInteger;

public class Main {

    public static void main(String[] args) {
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        String leido = "";
        while (!leido.equals("exit")) {
            try{
                leido = br.readLine();
                // Obtengo instruccion

                leido = new BigInteger(leido, 16).toString(2);


                String instruccion ;
                int numzeros= 32 - leido.length();
                String aux ="";

                for (int i = 0 ; i< numzeros ; ++ i) aux = aux + "0";

                aux = aux + leido;
                leido= aux;

                switch (leido.substring(0,6)){
                    case "001010":
                        instruccion="lw_pos";
                        break;
                    case "001011":
                        instruccion="sw_pos";
                        break;
                    case "000010":
                        instruccion="lw";
                        break;
                    case "000011":
                        instruccion="sw";
                        break;
                    case "000100":
                        instruccion="beq";
                        break;
                    case "000001":
                        instruccion="add";
                        break;
                    case "000000":
                        instruccion="nop";
                        break;
                    default:
                        instruccion="desconocida";
                }


                // Obtengo rt
                String rt = new BigInteger(leido.substring(11,16), 2).toString(10);
                // Obtengo rs
                String rs = new BigInteger(leido.substring(6,11), 2).toString(10);
                // Obtengo rd
                String rd = new BigInteger(leido.substring(16,21), 2).toString(10);
                // Obtengo inmediato
                String inmediato = new BigInteger(leido.substring(16), 2).toString(10);


                if(instruccion.equals("desconocida") || instruccion.equals("nop")){
                    System.out.println(instruccion);
                }else if (instruccion.equals("beq")){
                    System.out.println(instruccion + " r" + rs + " , r" + rt + " , " + inmediato);
                }else if(instruccion.equals("lw_pos")||instruccion.equals("sw_pos") ||instruccion.equals("sw") ||instruccion.equals("lw") ){
                    System.out.println(instruccion + " r" + rt + " , " + " "+ inmediato + "( r"+ rs +" )");
                }else {
                    System.out.println(instruccion + " r" + rd + " , r" + rs + " , r" + rt);
                }

            }catch (Exception e){

            }

        }
    }
}
