#include <verilated.h> // runtime verilator
#include <verilated_vcd_c.h> // libreria per la generazione dei VCD (Value Change Dump)

// header file generati dai miei moduli contenenti le corrispondenticlassi c++
#include "VInstructionMem.h"

#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Istanziamo il modulo. Ogni segnale di input (address) e output
    // (instruction) del modulo diventa una proprietà di questo oggetto
    VInstructionMem imem;

    // Abilitiamo e configuriamo la generazione del file VCD
    // - abilitiamo il tracing (strano che non sia abilitato di default)
    // - creiamo l'oggetto che si occuperà di scrivere i dati nel formato vcd
    //   (Trace File Pointer)
    // - creiamo un'associazione tra DUT (imem) e tfp. 
    //   - Il numero 99 indica la profondità gerarchica massima dei sottomoduli
    //     da tracciare
    //   - Se mettessi 1, traccieresti solo i pin esterni del modulo principale
    //     ignorando tutti i segnali interni
    Verilated::traceEverOn(true);
    VerilatedVcdC tfp; 
    imem.trace(&tfp, 99);         
    tfp.open("build/waveform.vcd");    

    // Contatore del tempo di simulazione
    vluint64_t sim_time = 0;      
    // Testiamo alcuni indirizzi
    for (int i = 0; i < 64; i++) {
        // generazioni degli input
        imem.address = i;
        // Aggiorna la logica combinatoria
        imem.eval(); 

        // Cattura lo stato corrente di tutti i segnali monitorati e li scrive
        // nel file VCD associandoli al tempo sim_time.
        tfp.dump(sim_time);

        // Qua dovrei controllare se l'output ottenuto è quello che mi aspetto.
        // Per adesso mi limito a fare una stampa
        std::cout << "Indirizzo: " << i << " | Istruzione: 0x" 
                  << std::hex << imem.instruction << std::endl;

        sim_time += 10;
    }
    // aggiungiamo un dump ulteriore per poter visualizzare 
    // anche l'ultima transizione
    tfp.dump(sim_time); 

    // cleanup
    tfp.close();
    imem.final();

    return 0;
}