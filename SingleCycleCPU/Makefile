TOP = SingleCycleRISCV

SRCS = src/InstructionMem.v \
	   src/DataMem.v \
	   src/RegisterFile.v \
	   src/ALU.v \
	   src/ControlUnit.v \
	   src/ImmExtensionUnit.v \
	   src/SingleCycleRISCV.v \

# TESTBENCH = tests/TEST_RegisterFile.cpp
TESTBENCH = tests/TEST_SingleCycleRISCV.cpp


# --cc 			-> Generate C++ code
# --exe 		-> Generate a runnable executable linked with the testbench
# --build 		-> Automatically builds the verilated files
# -Wall 		-> Enable all warning messages
# -Wno-fatal 	-> Non blocca la compilazione in caso di warning
# --trace 		-> Enable waveform tracing (.vcd generation)
# --Mdir build  -> Specify the target build output directory
VERILATOR_FLAGS = --cc \
                  --exe \
                  --build \
				  -Wall \
				  -Wno-fatal \
                  --trace \
                  --Mdir build \
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