TOP = PipelinedRISCV

SRCS = src/InstructionMem.v \
	   src/DataMem.v \
	   src/RegisterFile.v \
	   src/ALU.v \
	   src/ControlUnit.v \
	   src/ImmExtensionUnit.v \
	   src/HazardDetectionUnit.v \
	   src/PipelinedRISCV.v \

# TESTBENCH = tests/TEST_RegisterFile.cpp
TESTBENCH = tests/TEST_PipelinedRISCV.cpp


# --cc 				-> Generate C++ code
# --exe 			-> Generate a runnable executable linked with the testbench
# --build 			-> Automatically builds the verilated files
# --public-flat-rw 	-> Rende visibili i segnali interni tramite rootp
# -Wall 			-> Enable all warning messages
# -Wno-fatal 		-> Non blocca la compilazione in caso di warning
# --trace 			-> Enable waveform tracing (.vcd generation)
# --Mdir build  	-> Specify the target build output directory
# ... vari flag per produrre un binario debuggabile (impossibile trovare docs)
VERILATOR_FLAGS = --cc \
                  --exe \
                  --build \
				  --public-flat-rw \
				  -Wall \
				  -Wno-fatal \
                  --trace \
                  --Mdir build \
                  -CFLAGS "-g -O0" \
                  -LDFLAGS "-g" \
				  -MAKEFLAGS "OPT_FAST=-O0 OPT_SLOW=-O0 OPT_GLOBAL=-O0" \
				  -o sim

.PHONY: build run clean

build: $(SRCS) $(TESTBENCH)
	verilator $(VERILATOR_FLAGS) $(SRCS) $(TESTBENCH) --top-module $(TOP)

run: build
	./build/sim	

clean:
	rm -rf ./build/*

wave: run
	gtkwave ./build/waveform.vcd

lint:
	verilator --lint-only -Wall $(SRCS) --top-module $(TOP)

debug:
	raddbg build/sim