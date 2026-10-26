# MyRISCV

Implementazione di una CPU RISC-V in Verilog, seguendo quanto studiato nel libro: "Digital Design and Computer Architecture, RISC-V Edition (Sarah Harris, David Harris)"

La CPU implementa un subset minimale delle istruzioni RV32I sufficienti a eseguire una gran quantità di programmi. Le istruzioni implementate sono: lw, sw, add, sub, and, or, slt, addi, andi, ori, slti, beq, jal

La microarchitettura consiste in una classica pipeline a cinque stadi:

- in the Fetch stage, the processor reads the instruction from instruction memory.
- In the Decode stage, the processor reads the source operands from the register file and decodes the instruction to produce the control signals.
- In the Execute stage, the processor performs a computation with the ALU.
- In the Memory stage, the processor reads or writes data memory, if applicable.
- Finally, in the Writeback stage, the processor writes the result to the register file, if applicable.
