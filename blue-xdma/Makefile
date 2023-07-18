.PHONY: check_build_folder compile create sim synth clean

.DEFAULT_GOAL := synth

PCIE_LOC ?= "X0Y1"

check_build_folder:
	@if [ ! -d "build" ]; then \
		mkdir build; \
	fi

compile: check_build_folder
	$(MAKE) -C ./src

create: compile
	@if [ ! -f "./build/xdma_ex/xdma_ex.xpr" ]; then \
		vivado -mode batch -notrace -nolog -nojournal -source ./script/create.tcl -tclargs $(PCIE_LOC); \
    fi

sim: create
	vivado -mode batch -notrace -nolog -nojournal -source ./script/sim.tcl

synth: create
	vivado -mode batch -notrace -nolog -nojournal -source ./script/synth_impl.tcl

clean:
	@rm *.log *.jou *.str || true
	@rm -rf build || true
