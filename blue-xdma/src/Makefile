.PHONY: all clean

BSC_FLAGS := -verilog
BSC_FLAGS += -p +:%/Libraries/AMBA_TLM3/Axi4
BSC_FLAGS += -p +:%/Libraries/Bus
BSC_FLAGS += -p +:%/Libraries/AMBA_TLM3/TLM3
BSC_FLAGS += -p +:%/Libraries/AMBA_TLM3/Axi
BSC_FLAGS += -p +:../BlueLib/src
BSC_FLAGS += -p +:../BlueAXI/src
BSC_FLAGS += -p +:./include
BSC_FLAGS += -bdir ../build
# BSC_FLAGS += -promote-warnings ALL

all: clean mkXDMATestbench

mkTb:
	@bsc $(BSC_FLAGS) -g mkTb -u Top.bsv

mkXDMATestbench:
	@bsc $(BSC_FLAGS) -g mkXDMATestbench -u XDMATestbench.bsv

clean:
	rm -f *.v
