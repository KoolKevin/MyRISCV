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
    rf.clk = 1;
    rf.eval();
    tfp.dump(sim_time);
    sim_time += 5;
    // fronte di salita
    rf.clk = 0;          
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

    // Note verilator:
    // - verilator seems to only support 2-level logic (0 and 1; no X or Z)
    // - il comportamento a inizio simulazione non è chiarissimo
    //   - ci sono dei CLI flag
    //     - --x-initial <mode>  Assign initial Xs to this value
    //     - --x-initial-edge    Enable initial X->0 and X->1 edge triggers
    //   - ma per evitare stranezze è meglio essere espliciti nell'inserimento
    //     dei fronti di salita/discesa: 
    //     - verilator detects an edge by comparing the current value of a
    //       signal with its value at the previous eval()
    //     - se il segnale parte alto, non viene quindi rilevato nessun fronte
    //       di salita

    // testo tutti i registri in ordine

    // prima verifico il reset
    rf.reset = 0;
    tick(rf, tfp);
    rf.reset = 1;
    tick(rf, tfp);
    rf.reset = 0;
    for (int i = 0; i < 32; i++) {
        // leggo i registri
        rf.writeEnable = 0;         
        rf.addressSourceReg1 = i;
        rf.addressSourceReg2 = i;
        tick(rf, tfp);

        check(i, rf.sourceReg1Data, rf.sourceReg2Data, i);
    }

    for (int i = 0; i < 32; i++) {
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

    for (int i = 0; i < 32; i++) {
        // Scrivo e leggo un registro contemporaneamente.
        // Siccome, scrivo nel primo semiperiodo, e leggo nel secondo, dovrei
        // riuscire a leggere il valore aggiornato
        rf.writeEnable = 1;
        rf.addressDestReg = i;
        rf.destRegData = i*100;
        rf.addressSourceReg1 = i;
        rf.addressSourceReg2 = i;
        tick(rf, tfp);

        check(i, rf.sourceReg1Data, rf.sourceReg2Data, i * 100);
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