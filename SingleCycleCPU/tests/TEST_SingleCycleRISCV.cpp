#include <cstdint>
#include <verilated.h> // runtime verilator
#include <verilated_vcd_c.h> // libreria per la generazione dei VCD (Value Change Dump)

// header file generati dai miei moduli contenenti le corrispondenticlassi c++
#include "VSingleCycleRISCV.h"
#include "VSingleCycleRISCV___024root.h"   // needed to see the members of rootp

#include <cstdio>
#include <stdint.h>

vluint64_t sim_time = 0;      
int n_checks = 0;
int n_fails  = 0;

// Un ciclo di clock completo: clk=0 -> eval -> clk=1 -> eval
void tick(VSingleCycleRISCV& riscv, VerilatedVcdC& tfp) {
    // fronte di discesa
    riscv.clk = 0;
    riscv.eval();
    tfp.dump(sim_time);
    sim_time += 5;
    // fronte di salita
    riscv.clk = 1;          
    riscv.eval();
    tfp.dump(sim_time);
    sim_time += 5;
}


struct DecodedInstruction {
    uint8_t opcode;
    union {
        struct {
            uint8_t funct3;
            uint8_t funct7;
            uint8_t rs1;
            uint8_t rs2;
            uint8_t rd;
        } RType;

        struct {
            int16_t imm; // 12 bit
            uint8_t funct3;
            uint8_t rs1;
            uint8_t rd;
        } IType;

        struct {
            int16_t imm; // 12 bit
            uint8_t funct3;
            uint8_t rs1;
            uint8_t rs2;
        } SType;

        struct {
            int16_t imm; // 13 bit (ricorda l'ultimo zero implicito)
            uint8_t funct3;
            uint8_t rs1;
            uint8_t rs2;
        } BType;
    } type;
};

uint32_t sliceBitsFromWord(uint32_t word, int highestBit, int lowestBit) {
    // shifto via i bit meno significativi
    uint32_t MSBSlice = (word >> lowestBit);
    // seleziono i bit fino ad highest bit con una maschera.
    // - highestBit - lowestBit + 1 => numero di bit dello slice
    // - 1U << (...) => ho un uno seguito da (highestBit - lowestBit + 1) zeri
    // - ... - 1 => ottengo (highestBit - lowestBit + 1 zeri) uni
    uint32_t MSBMask = ((1U << (highestBit - lowestBit + 1)) - 1);
    return MSBSlice & MSBMask; 
}

int32_t signExtend(uint32_t word, int numBits) {
    // per fare sign extension eseguo i seguenti passi
    // - recupero il msb del mio immediato da numBits
    // - ottengo una maschera in cui le posizioni associate ai bit del mio 
    //   immediato sono occupate da zeri, e il resto dal msb del mio immediato
    // - l'or finale, aggiungi gli uni necessari per la sign extension se l'msb
    //   dell'immediato era effetivamente pari a 1
    uint32_t signBitMask = 1U << (numBits - 1);
    uint32_t signBit = word & signBitMask;
    uint32_t signExtensionBits = ~((signBit << 1) - 1);

    return word | signExtensionBits;
}

DecodedInstruction decodeInstruction(uint32_t encodedInstruction) {
    DecodedInstruction res = {};
    res.opcode = (uint8_t)sliceBitsFromWord(encodedInstruction, 6, 0);

    switch (res.opcode) {
    // R-Type
    case 51: { 
        res.type.RType.funct3 = (uint8_t)sliceBitsFromWord(encodedInstruction, 14, 12);
        res.type.RType.funct7 = (uint8_t)sliceBitsFromWord(encodedInstruction, 31, 25);
        res.type.RType.rs1 = (uint8_t)sliceBitsFromWord(encodedInstruction, 19, 15);
        res.type.RType.rs2 = (uint8_t)sliceBitsFromWord(encodedInstruction, 24, 20);
        res.type.RType.rd = (uint8_t)sliceBitsFromWord(encodedInstruction, 11, 7);

        break;
    }
    // I-Type 
    // case ?: // alu-ops con immediato
    case 3: { // loads
        uint32_t rawImmBits = sliceBitsFromWord(encodedInstruction, 31, 20);
        res.type.IType.imm = (int16_t)signExtend(rawImmBits, 12);
        res.type.IType.funct3 = (uint8_t)sliceBitsFromWord(encodedInstruction, 14, 12);
        res.type.IType.rs1 = (uint8_t)sliceBitsFromWord(encodedInstruction, 19, 15);
        res.type.IType.rd = (uint8_t)sliceBitsFromWord(encodedInstruction, 11, 7);

        break;
    }
    // S-Type
    case 35: { 
        uint16_t immBottom5Bits = (int16_t)sliceBitsFromWord(encodedInstruction, 11, 7);
        uint16_t immTop7Bits = (uint16_t)sliceBitsFromWord(encodedInstruction, 31, 25);
        uint32_t rawImmBits = (immTop7Bits << 5) | immBottom5Bits;
        res.type.SType.imm = (int16_t)signExtend(rawImmBits, 12);

        res.type.SType.funct3 = (uint8_t)sliceBitsFromWord(encodedInstruction, 14, 12);
        res.type.SType.rs1 = (uint8_t)sliceBitsFromWord(encodedInstruction, 19, 15);
        res.type.SType.rs2 = (uint8_t)sliceBitsFromWord(encodedInstruction, 24, 20);

        break;
    }
    // B-Type
    case 99: { 
        uint16_t immBit13 = (uint16_t)sliceBitsFromWord(encodedInstruction, 31, 31);
        uint16_t immBit12 = (uint16_t)sliceBitsFromWord(encodedInstruction, 7, 7);
        uint16_t immBit11_6 = (uint16_t)sliceBitsFromWord(encodedInstruction, 30, 25);
        uint16_t immBit5_2 = (uint16_t)sliceBitsFromWord(encodedInstruction, 11, 8);
        // bit1 = zero implicito
        uint32_t rawImmBits =
            (int16_t)(((immBit13 << 11) | (immBit12 << 10) | (immBit11_6 << 4) | (immBit5_2)) << 1);
        res.type.BType.imm = (int16_t)signExtend(rawImmBits, 13);

        res.type.BType.funct3 = (uint8_t)sliceBitsFromWord(encodedInstruction, 14, 12);
        res.type.BType.rs1 = (uint8_t)sliceBitsFromWord(encodedInstruction, 19, 15);
        res.type.BType.rs2 = (uint8_t)sliceBitsFromWord(encodedInstruction, 24, 20);

        break;
    }
    // unrecognized
    default: {
        printf("errore decodifica istruzione\n");
    }
    }

    return res;
}

void printDecodedInstruction(DecodedInstruction decoded) {
    // FIXME: per adesso faccio un pretty print di solamente le istruzioni del
    // mio programma di test in maniera hardcoded.
    //
    // L7:  lw   x6, -4(x9)
    //      sw   x6, 8(x9)
    //      or   x4, x5, x6
    //      beq  x4, x4, L7
    //
    // Per supportare le altre istruzioni dovrei aggiungere una tabella che 
    // indicizzo con opcode, funct7 e funct3

    switch (decoded.opcode) {
    // R-Type
    case 51: { 
        if (decoded.type.RType.funct7 == 0 && decoded.type.RType.funct3 == 6) {
            printf("or\tx%d, x%d, x%d\n", decoded.type.RType.rd, decoded.type.RType.rs1, decoded.type.RType.rs2);
        }
        break;
    }
    // I-Type (loads)
    case 3: { 
        if (decoded.type.IType.funct3 == 2) {
            printf("lw\tx%d, %d(x%d)\n", decoded.type.IType.rd, decoded.type.IType.imm, decoded.type.IType.rs1);
        }
        break;
    }
    // S-Type
    case 35: { 
        if (decoded.type.SType.funct3 == 2) {
            printf("sw\tx%d, %d(x%d)\n", decoded.type.SType.rs2, decoded.type.SType.imm, decoded.type.SType.rs1);
        }
        break;
    }
    // B-Type
    case 99: { 
        if (decoded.type.BType.funct3 == 0) {
            printf("beq\tx%d, x%d, %d\n", decoded.type.BType.rs1, decoded.type.BType.rs2, decoded.type.BType.imm);
        }
        break;
    }
    // unrecognized
    default: {
        printf("errore stampa istruzione decodificata\n");
    }
    }
}

#define NUM_REGS 32
#define NUM_DMEM_WORDS 64

struct CpuState {
    uint32_t pc;
    uint32_t regs[NUM_REGS];
    uint32_t mem[NUM_DMEM_WORDS];
};

CpuState snapshot(VSingleCycleRISCV& riscv) {
    CpuState s;
    s.pc = riscv.rootp->SingleCycleRISCV__DOT__PC;
    for (int i = 0; i < NUM_REGS; i++)
        s.regs[i] = riscv.rootp->SingleCycleRISCV__DOT__rf__DOT__registers[i];

    for (int i = 0; i < NUM_DMEM_WORDS; i++)
        s.mem[i] = riscv.rootp->SingleCycleRISCV__DOT__dmem__DOT__memory[i];

    return s;
}

void printDiff(const CpuState& before, const CpuState& after) {
    for (int i = 0; i < 32; i++)
        if (before.regs[i] != after.regs[i])
            printf("\tx%d: 0x%x -> 0x%x\n", i, before.regs[i], after.regs[i]);

    for (int i = 0; i < 64; i++)
        if (before.mem[i] != after.mem[i])
            printf("\tmem[%d] (addr 0x%x): 0x%x -> 0x%x\n",
                   i, i * 4, before.mem[i], after.mem[i]);

    printf("\tpc : %x -> %x\n", before.pc, after.pc);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    VSingleCycleRISCV riscv;

    VerilatedVcdC tfp; 
    riscv.trace(&tfp, 99);         
    tfp.open("build/waveform.vcd");    

    // resettiamo allo stato iniziale
    riscv.reset = 0;
    tick(riscv, tfp);
    riscv.reset = 1;
    tick(riscv, tfp);
    riscv.reset = 0;

    for (int i = 0; i < 40; i++) {
        // printf("\t%x\n", riscv.rootp->SingleCycleRISCV__DOT__instruction);
        DecodedInstruction decoded = 
            decodeInstruction(riscv.rootp->SingleCycleRISCV__DOT__instruction);
        printDecodedInstruction(decoded);

        CpuState before = snapshot(riscv);
        tick(riscv, tfp);
        CpuState after = snapshot(riscv);
        printDiff(before, after);
    }
    tfp.dump(sim_time); 

    // If successful, it should write the value 25 to address 100 (word 25)

    // cleanup
    tfp.close();
    riscv.final();

    return 0;
}