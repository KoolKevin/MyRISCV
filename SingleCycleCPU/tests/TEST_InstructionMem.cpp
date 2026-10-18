#include "VInstructionMem.h"
#include <verilated.h>
#include <verilated_vcd_c.h> // Necessario per il tracciamento VCD
#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // 1. Istanziamo il modulo
    VInstructionMem imem;

    // 2. Abilitiamo e configuriamo la generazione del file VCD
    Verilated::traceEverOn(true);
    VerilatedVcdC tfp; 
    imem.trace(&tfp, 99);         // 99 livelli di profondità gerarchica (??)
    tfp.open("build/waveform.vcd");    // Nome del file di output

    vluint64_t sim_time = 0;      // Contatore del tempo di simulazione

    // Testiamo alcuni indirizzi
    for (int i = 0; i < 3; i++) {
        imem.address = i;
        imem.eval(); // Aggiorna la logica combinatoria

        // Registriamo lo stato attuale nel file VCD al tempo corrente
        tfp.dump(sim_time);
        sim_time += 10; // Facciamo avanzare il "tempo" di 10 unità

        std::cout << "Indirizzo: " << i 
                  << " | Istruzione: 0x" << std::hex << imem.instruction << std::endl;
    }
    // aggiungiamo un dump ulteriore per poter visualizzare 
    // anche l'ultima transizione
    tfp.dump(sim_time); 

    // 3. Chiusura e pulizia
    tfp.close();
    imem.final();

    return 0;
}