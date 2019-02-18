package net.langelp;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class VHDL {

	public static final int NOP = 0x0;
	public static final int ALU = 0x1;
	public static final int LW = 0x2;
	public static final int SW = 0x3;
	public static final int BEQ = 0x4;
	public static final int LW2 = 0xA;
	public static final int SW2 = 0xB;
	public static final int DIS = -1;

	private static int getA(int op, int op1, int op2, int s, int t, int d, int s1, int t1, int d1, int s2, int t2,
			int d2) {
		int a = 0;

		if (op != NOP && s == t2 && (op2 == LW || op2 == LW2)) {
			a = 3;
		} else if (op != NOP && ((op2 == ALU && s == d2) || ((op2 == LW2 || op2 == SW2) && s == s2))) {
			a = 2;
		} else if ((op != NOP && ((op1 == ALU && s == d1) || ((op1 == LW2 || op2 == SW2) && s == s1)))
				|| ((op == ALU || op == BEQ || op == SW || op == SW2) && op1 == LW2 && s == s1)) {
			a = 1;
		}

		return a;
	}

	private static int getB(int op, int op1, int op2, int s, int t, int d, int s1, int t1, int d1, int s2, int t2,
			int d2) {
		int b = 0;

		if ((op == ALU || op == BEQ || op == SW || op == SW2) && (op2 == LW || op2 == LW2) && t == t2) {
			b = 3;
		} else if ((op == ALU || op == BEQ || op == SW || op == SW2)
				&& ((op2 == ALU && t == d2) || ((op2 == LW2 || op2 == SW) && t == s2))) {
			b = 2;
		} else if ((op == ALU || op == BEQ || op == SW || op == SW2)
				&& ((op1 == ALU && t == d1) || ((op1 == LW2 || op1 == SW2) && t == s1))) {
			b = 1;
		}

		return b;
	}

	private static int getSTOP(int op, int op1, int op2, int s, int t, int d, int s1, int t1, int d1, int s2, int t2,
			int d2) {
		int stop = 0;

		if ((op == ALU || op == BEQ || op == SW || op == SW2) && (op2 == LW || op2 == LW2) && t == t2) {
			stop = 1;
		}

		return stop;
	}

	private static void test2(int op, int op1, int op2, int s, int t, int d, int s1, int t1, int d1, int s2, int t2,
			int d2, int a, int b, int stop, int round) {
		int A = 0, B = 0, STOP = 0;

		if (op == LW || op == LW2) {
			if (op1 == ALU) {
				if (s == d1)
					A = 1;
			} else if (op1 == LW) {
				if (s == t1)
					STOP = 1;
			} else if (op1 == LW2) {
				if (s == t1)
					STOP = 1;
				if (s == s1)
					A = 1;
			} else if (op1 == SW2) {
				if (s == s1)
					A = 1;
			} else if (op2 == ALU) {
				if (s == d2)
					A = 2;
			} else if (op2 == LW) {
				if (s == t2)
					A = 3;
			} else if (op2 == LW2) {
				if (s == t2)
					A = 3;
				if (s == s2)
					A = 2;
			} else if (op2 == SW2) {
				if (s == s2)
					A = 2;
			}
		} else if (op == ALU || op == BEQ || op == SW || op == SW2) {
			if (op1 == ALU) {
				if (s == d1)
					A = 1;
				if (t == d1)
					B = 1;
			} else if (op1 == LW) {
				if (s == t1 || t == t1)
					STOP = 1;
			} else if (op1 == LW2) {
				if (s == t1 || t == t1)
					STOP = 1;
				if (s == s1)
					A = 1;
				if (t == s1)
					B = 1;
			} else if (op1 == SW2) {
				if (s == s1)
					A = 1;
				if (t == s1)
					B = 1;
			} else if (op2 == ALU) {
				if (s == d2)
					A = 2;
				if (t == d2)
					B = 2;
			} else if (op2 == LW) {
				if (s == t2)
					A = 3;
				if (t == t2)
					B = 3;
			} else if (op2 == LW2) {
				if (s == t2)
					A = 3;
				if (t == t2)
					B = 3;
				if (s == s2)
					A = 2;
				if (t == s2)
					B = 2;
			} else if (op2 == SW2) {
				if (s == s2)
					A = 2;
				if (t == s2)
					B = 2;
			}
		}

		if (a != A) {
			System.out.println("A no coincide en " + round);
		} else if (a != getA(op, op1, op2, s, t, d, s1, t1, d1, s2, t2, d2)) {
			// System.out.println("A2 no coincide en " + round);
		}

		if (b != B) {
			System.out.println("B no coincide en " + round);
		} else if (a != getB(op, op1, op2, s, t, d, s1, t1, d1, s2, t2, d2)) {
			// System.out.println("B2 no coincide en " + round);
		}

		if (stop != STOP) {
			System.out.println("STOP no coincide en " + round);
		} else if (a != getSTOP(op, op1, op2, s, t, d, s1, t1, d1, s2, t2, d2)) {
			// System.out.println("STOP2 no coincide en " + round);
		}

		test3(op, op1, op2, s, t, d, s1, t1, d1, s2, t2, d2, a, b, stop, round);
	}

	private static void test3(int op, int op1, int op2, int s, int t, int d, int s1, int t1, int d1, int s2, int t2,
			int d2, int a, int b, int stop, int round) {
		int A = 0, B = 0, STOP = 0;

		if (
				(op != NOP && ((op1 == ALU && s == d1) || ((op1 == LW2 || op1 == SW2) && s == s1)))
				) {
			A = 1;
		} else if(
				(op != NOP && ((op2 == ALU && s == d2) || ((op2 == LW2 || op2 == SW2) && s == s2)))
				){
			A = 2;
		} else if (
				(op != NOP && (op2 == LW || op2 == LW2) && s == t2)
				){
			A = 3;
		}

		if (
				((op == ALU || op == BEQ || op == SW || op == SW2) && ((op1 == ALU && t == d1) || ((op1 == LW2 || op1 == SW2) && t == s1)))
				){
			B = 1;
		} else if (
				((op == ALU || op == BEQ || op == SW || op == SW2) && ((op2 == ALU && t == d2) || (op2 == LW2 || op2 == SW2) && t == s2))
				){
			B = 2;
		} else if (
				((op == ALU || op == BEQ || op == SW || op == SW2) && (op2 == LW || op2 == LW2) && t == t2)
				){
			B = 3;
		}

		if (
				((op == ALU || op == BEQ || op == SW || op == SW2) && (op1 == LW2 || op1 == LW) && t == t1) ||
				(op != NOP && (op1 == LW || op1 == LW2) && s == t1)
			){
			STOP = 1;
		}

		if (a != A) {
			System.out.println("A no coincide en " + round);
		}

		if (b != B) {
			System.out.println("B no coincide en " + round);
		}

		if (stop != STOP) {
			System.out.println("STOP no coincide en " + round);
		}
	}

	public static void test() {
		int round = 0;
		test2(ALU, ALU, NOP, 0, 0, 1, 2, 2, 0, 3, 4, 5, 1, 1, 0, round++); // 0

		test2(ALU, NOP, ALU, 0, 0, 1, 2, 2, 3, 3, 4, 0, 2, 2, 0, round++); // 1

		test2(ALU, LW, NOP, 0, 1, 2, DIS, 0, DIS, DIS, DIS, DIS, 0, 0, 1, round++); // 2
		test2(ALU, LW, NOP, 1, 0, 2, DIS, 0, DIS, DIS, DIS, DIS, 0, 0, 1, round++); // 3

		test2(ALU, NOP, LW, 0, 1, 2, DIS, DIS, DIS, DIS, 0, DIS, 3, 0, 0, round++); // 4
		test2(ALU, NOP, LW, 1, 0, 2, DIS, DIS, DIS, DIS, 0, DIS, 0, 3, 0, round++); // 5

		test2(ALU, LW2, NOP, 0, 1, 2, DIS, 0, DIS, DIS, DIS, DIS, 0, 0, 1, round++); // 6
		test2(ALU, LW2, NOP, 1, 0, 2, DIS, 0, DIS, DIS, DIS, DIS, 0, 0, 1, round++); // 7
		test2(ALU, LW2, NOP, 0, 1, 2, 0, DIS, DIS, DIS, DIS, DIS, 1, 0, 0, round++); // 8
		test2(ALU, LW2, NOP, 1, 0, 2, 0, DIS, DIS, DIS, DIS, DIS, 0, 1, 0, round++); // 9

		test2(ALU, NOP, LW2, 0, 1, 2, DIS, DIS, DIS, DIS, 0, DIS, 3, 0, 0, round++); // 10
		test2(ALU, NOP, LW2, 1, 0, 2, DIS, DIS, DIS, DIS, 0, DIS, 0, 3, 0, round++); // 11
		test2(ALU, NOP, LW2, 0, 1, 2, DIS, DIS, DIS, 0, DIS, DIS, 2, 0, 0, round++); // 12
		test2(ALU, NOP, LW2, 1, 0, 2, DIS, DIS, DIS, 0, DIS, DIS, 0, 2, 0, round++); // 13

		test2(ALU, SW2, NOP, 0, 0, 2, 0, DIS, DIS, DIS, DIS, DIS, 1, 1, 0, round++); // 14

		test2(ALU, NOP, SW2, 0, 0, 2, DIS, DIS, DIS, 0, DIS, DIS, 2, 2, 0, round++); // 15

		// R2
		test2(LW, ALU, NOP, 0, 1, 2, DIS, DIS, 0, DIS, DIS, DIS, 1, 0, 0, round++); // 16

		test2(LW, NOP, ALU, 0, 1, 2, DIS, DIS, DIS, DIS, DIS, 0, 2, 0, 0, round++); // 17

		test2(LW, LW, NOP, 0, 1, 2, DIS, 0, DIS, DIS, DIS, DIS, 0, 0, 1, round++); // 18

		test2(LW, NOP, LW, 0, 1, 2, DIS, DIS, DIS, DIS, 0, DIS, 3, 0, 0, round++); // 19

		test2(LW, LW2, NOP, 0, 1, 2, 0, 0, DIS, DIS, DIS, DIS, 1, 0, 1, round++); // 20

		test2(LW, NOP, LW2, 0, 1, 2, DIS, DIS, DIS, DIS, 0, DIS, 3, 0, 0, round++); // 21
		test2(LW, NOP, LW2, 0, 1, 2, DIS, DIS, DIS, 0, DIS, DIS, 2, 0, 0, round++); // 22

		test2(LW, SW2, NOP, 0, 1, 2, 0, DIS, DIS, DIS, DIS, DIS, 1, 0, 0, round++); // 23
		test2(LW, NOP, SW2, 0, 1, 2, DIS, DIS, DIS, 0, DIS, DIS, 2, 0, 0, round++); // 24
		
		try {
			parse();
		} catch (IOException ignored) {}

	}
	
	public static void parse() throws IOException{
		final int OP_CODE = 26;
		final int[] aluShift = new int[]{11, 21, 16};
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
		String line;
		while((line = reader.readLine()) != null){
			if(line.isEmpty() || line.equals("end")) {break;}
			
			int code = 0;
			if(!line.equals("nop")){
				String[] instr = line.split(" ", 2);
				switch (instr[0]) {
				case "alu":
					String[] ops = instr[1].split(",");
					code = ALU << OP_CODE;
					for(int i = 0; i < ops.length; i++){
						String parsed = ops[i].replaceAll("[^0-9]*", "");
						code |= (Integer.parseInt(parsed) & 0x1F) << aluShift[i];
					}
					break;
				case "beq":
					code = parseNoALU(instr[1], BEQ << OP_CODE);
					break;
				case "lw":
					code = parseNoALU(instr[1], LW << OP_CODE);
					break;
				case "lw2":
					code = parseNoALU(instr[1], LW2 << OP_CODE);
					break;
				case "sw":
					code = parseNoALU(instr[1], SW << OP_CODE);
					break;
				case "sw2":
					code = parseNoALU(instr[1], SW2 << OP_CODE);
					break;
				default:
					System.out.println("Unknown instruction " + line + " (" + instr[0] + "/"+instr[1]+") ");
				}
			}
			
			System.out.println("Code: " + Integer.toHexString(code) + "/" + Integer.toBinaryString(code)+ "/" + Integer.toOctalString(code));
		}
		
	}
	
	private static int parseNoALU(String ops, int code){
		final int shift[] = new int[]{21, 16, 0};
		final int[] limit = new int[]{0x1F, 0x1F, 0xFFFF};
		String[] ops2 = ops.split(",");
		for(int i = 0; i < ops2.length; i++){
			String parsed = ops2[i].replaceAll("[^0-9]*", "");
			code |= (Integer.parseInt(parsed) & limit[i]) << shift[i];
		}
		return code;
	}

}
