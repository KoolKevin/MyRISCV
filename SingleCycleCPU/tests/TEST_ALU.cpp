#include <verilated.h> 
#include <verilated_vcd_c.h> 

#include "VALU.h"

#include <cstdio>

vluint64_t sim_time = 0;      
int n_checks = 0;
int n_fails  = 0;

struct TestVector {
    int opcode;
    int op1;
    int op2;
    int result;
    int isZero;
};

TestVector testVectors[] = {
    // add
    {.opcode = 0b000, .op1 = 10, .op2 = 10, .result = 20, .isZero = 0},
    // sub
    {.opcode = 0b001, .op1 = 10, .op2 = 10, .result = 0, .isZero = 1},
    // and
    {.opcode = 0b010, .op1 = 0b1000, .op2 = 0b1001, .result = 0b1000, .isZero = 0},
    // or
    {.opcode = 0b011, .op1 = 0b1000, .op2 = 0b1001, .result = 0b1001, .isZero = 0},
    // xor
    {.opcode = 0b100, .op1 = 0b1010, .op2 = 0b0110, .result = 0b1100, .isZero = 0},
    // slt
    {.opcode = 0b101, .op1 = 10, .op2 = 11, .result = 1, .isZero = 0},
    {.opcode = 0b101, .op1 = 10, .op2 = 9, .result = 0, .isZero = 1},
    {.opcode = 0b101, .op1 = -10, .op2 = 11, .result = 1, .isZero = 0},
    // sll
    {.opcode = 0b110, .op1 = 0b0010, .op2 = 1, .result = 0b0100, .isZero = 0},
    // srl
    {.opcode = 0b111, .op1 = 0b0010, .op2 = 1, .result = 0b0001, .isZero = 0},
};

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    VALU alu;

    VerilatedVcdC tfp; 
    alu.trace(&tfp, 99);         
    tfp.open("build/waveform.vcd");    

    // scorro i miei testvectors
    for (TestVector tv : testVectors) {
        alu.opcode = tv.opcode;
        alu.op1 = tv.op1;
        alu.op2 = tv.op2;

        alu.eval();
        tfp.dump(sim_time);
        sim_time += 10;

        n_checks++;
        if (alu.result == tv.result && alu.resultIsZero == tv.isZero) {
            printf("[PASS] opcode 0b%b op1=%d, op2=%d -> result=%d, isZero=%d (expected result=%d isZero=%d)\n",
                    alu.opcode, alu.op1, alu.op2, alu.result, alu.resultIsZero, tv.result, tv.isZero);
        } else {
            n_fails++;
            printf("[FAIL] opcode 0b%b op1=%d, op2=%d -> result=%d, isZero=%d (expected result=%d isZero=%d)\n",
                    alu.opcode, alu.op1, alu.op2, alu.result, alu.resultIsZero, tv.result, tv.isZero);
        }
    }
    tfp.dump(sim_time); 

    printf("\n=========================================\n");
    if (n_fails == 0)
        printf("ALL TESTS PASSED (%d/%d checks)\n", n_checks, n_checks);
    else
        printf("TESTS FAILED: %d of %d checks failed\n", n_fails, n_checks);
    printf("=========================================\n");

    // cleanup
    tfp.close();
    alu.final();

    return 0;
}