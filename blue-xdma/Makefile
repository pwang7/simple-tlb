.PHONY: check_build_folder compile create sim synth clean

.DEFAULT_GOAL := sim

PCIE_LOC ?= X0Y1
BUILD_DIR ?= build
SCRIPT_DIR ?= script
CREATE_SCRIPT ?= $(SCRIPT_DIR)/create.tcl
SIM_SCRIPT ?= $(SCRIPT_DIR)/sim.tcl
SYNTH_SCRIPT ?= $(SCRIPT_DIR)/synth_impl.tcl
PROJECT_DIR ?= $(BUILD_DIR)/xdma_ex/xdma_ex.xpr

check_build_folder:
	@if [ ! -d "$(BUILD_DIR)" ]; then \
		mkdir $(BUILD_DIR); \
	fi

compile: check_build_folder
	$(MAKE) -C ./src BUILD_DIR=../$(BUILD_DIR)

create: compile
	@if [ ! -f "$(BUILD_DIR)/xdma_ex/xdma_ex.xpr" ]; then \
		vivado -mode batch -notrace -nolog -nojournal -source $(CREATE_SCRIPT) -tclargs $(BUILD_DIR) $(PCIE_LOC); \
	fi

sim: create
	vivado -mode batch -notrace -nolog -nojournal -source $(SIM_SCRIPT) -tclargs $(PROJECT_DIR)

synth: create
	vivado -mode batch -notrace -nolog -nojournal -source $(SYNTH_SCRIPT) -tclargs $(PROJECT_DIR)

clean:
	@rm *.log *.jou *.str || true
	@rm -rf $(BUILD_DIR) || true
