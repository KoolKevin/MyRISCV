#include <verilated.h> // runtime verilator
#include <verilated_vcd_c.h> // libreria per la generazione dei VCD (Value Change Dump)

// header file generati dai miei moduli contenenti le corrispondenticlassi c++
#include "VRegisterFile.h"

#include <cstdio>

vluint64_t sim_time = 0;      
int n_checks = 0;
int n_fails  = 0;

void check(int reg, uint32_t got1, uint32_t got2, uint32_t expected) {
    n_checks++;
    if (got1 == expected && got2 == expected) {
        printf("[PASS] reg %d: rd1=%d rd2=%d (expected %d)\n",
               reg, got1, got2, expected);
    } else {
        n_fails++;
        printf("[FAIL] reg %d: rd1=%d rd2=%d (expected %d)\n",
               reg, got1, got2, expected);
    }
}

// Un ciclo di clock completo: clk=0 -> eval -> clk=1 -> eval
void tick(VRegisterFile& rf, VerilatedVcdC& tfp) {
    // fronte di discesa
    rf.clk = 0;
    rf.eval();
    tfp.dump(sim_time);
    sim_time += 5;
    // fronte di salita
    rf.clk = 1;          
    rf.eval();
    tfp.dump(sim_time);
    sim_time += 5;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    VRegisterFile rf;

    VerilatedVcdC tfp; 
    rf.trace(&tfp, 99);         
    tfp.open("build/waveform.vcd");    

    // testo tutti i registri in ordine
    for (int i = 1; i < 32; i++) {
        // prima scrivo il registro ...
        rf.writeEnable = 1;
        rf.addressDestReg = i;
        rf.destRegData = i*10;
        tick(rf, tfp);
        // e poi lo leggo 
        rf.writeEnable = 0;         
        rf.addressSourceReg1 = i;
        rf.addressSourceReg2 = i;
        tick(rf, tfp);

        check(i, rf.sourceReg1Data, rf.sourceReg2Data, i * 10);
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
    rf.final();

    return 0;
}