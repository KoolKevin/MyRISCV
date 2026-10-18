# Appunti

- per controllare errori di sintassi
    - verilator --lint-only <nome>.v

- dalla documentazione
    - For simulation, a small user-written C++ wrapper file is required, the "wrapper". This wrapper defines the C++ standard function “main()”, which instantiates the Verilated model as a C++/SystemC object.

- verilator --cc --exe --build InstructionMemory.v test.cpp
    - per buildare un binario che esegue il tuo testbench .cpp (deve contere la funzione main())
