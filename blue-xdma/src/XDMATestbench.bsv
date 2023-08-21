import FIFOF::*;
import Clocks :: *;
import GetPut :: *;
import BlueAXI :: *;
import BlueLib :: *;
import AXI4LiteMaster :: *;
import AXI4Slave :: *;
import XdmaDescriptorGenerator :: *;
import StmtFSM :: *;
import Counter :: *;
import BRAMFIFO::*;
import Config :: *;

interface IfcTop;
    (* prefix = "" *) interface IfcXdmaDescriptorFab fab;
endinterface

(* synthesize, clock_prefix = "axi_aclk", reset_prefix = "axi_aresetn" *)
module mkXdmaTestbench(IfcTop);
    let c2hTestDescriptor = XdmaDescriptor {
        length: fromInteger(valueOf(TESTLENGTH)),
        srcAddr: fromInteger(valueOf(TESTSRCADDR)),
        dstAddr: fromInteger(valueOf(TESTDSTADDR) + valueOf(RANDOM_SEED))
    };
    let h2cTestDescriptor = XdmaDescriptor {
        length: fromInteger(valueOf(TESTLENGTH)),
        srcAddr: fromInteger(valueOf(TESTDSTADDR) + valueOf(RANDOM_SEED)),
        dstAddr: fromInteger(valueOf(TESTSRCADDR))
    };
    let xdmaDescriptorGenerator <- mkXdmaDescriptorGenerator;

    Reg#(Maybe#(AXI4_Read_Rq#(AXI4_SLAVE_ADDRSz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz))) readReq <- mkReg(tagged Invalid);
    Reg#(Maybe#(AXI4_Write_Rq_Addr#(AXI4_SLAVE_ADDRSz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz))) writeReq <- mkReg(tagged Invalid);

    Reg#(Bool) c2hInitiated <- mkReg(False);
    Reg#(Bool) h2cInitiated <- mkReg(False);
    Reg#(Bool) c2hFinished <- mkReg(False);
    Reg#(Bool) h2cFinished <- mkReg(False);
    Reg#(Bool) h2cCheckedFailed <- mkReg(False);

    // The function generates the bit vector by concatenating 8 bytes,
    // each of which is obtained by adding the input address to an offset and masking the result with 'hFF.
    // This code is designed to be compatible with existing example tests.
    // ex: 0x0706050403020100 (addr = 0)
    function Bit#(AXI4_SLAVE_DATASz) generateTestData(Bit#(AXI4_SLAVE_ADDRSz) addr);
        addr = addr + fromInteger(valueOf(RANDOM_SEED)); // add random seed
        return ((((((((addr + 7) & 'hFF) << 8
           | ((addr + 6) & 'hFF)) << 8
           | ((addr + 5) & 'hFF)) << 8
           | ((addr + 4) & 'hFF)) << 8
           | ((addr + 3) & 'hFF)) << 8
           | ((addr + 2) & 'hFF)) << 8
           | ((addr + 1) & 'hFF)) << 8
           | (addr & 'hFF);
    endfunction

    Counter#(64) tickTockCounter <- mkCounter(0);

    rule tickTock;
        tickTockCounter.inc(1);
    endrule

    rule forceStop if (tickTockCounter.value == fromInteger(valueOf(STOP_AFTER)));
        printColorTimed(RED, $format("If you see this, the test has timed out."));
        $finish(fromInteger(valueOf(TIMEOUT_ERROR)));
    endrule

    rule initC2HTransfer if (tickTockCounter.value == fromInteger(valueOf(WAIT_RESET)) && !c2hInitiated);
        printColorTimed(BLUE, $format("Initiating C2H Transfer..."));
        xdmaDescriptorGenerator.dsc.controlDMA(DMA_Configure {
            dir: C2H,
            enable: True
        });
        xdmaDescriptorGenerator.dsc.c2h.put(c2hTestDescriptor);
        c2hInitiated <= True;
    endrule

    rule initH2CTransfer if (c2hInitiated && c2hFinished && !h2cInitiated);
        printColorTimed(BLUE, $format("Initiating H2C Transfer..."));
        xdmaDescriptorGenerator.dsc.controlDMA(DMA_Configure {
            dir: H2C,
            enable: True
        });
        xdmaDescriptorGenerator.dsc.h2c.put(h2cTestDescriptor);
        h2cInitiated <= True;
    endrule

    rule axi4ReceiveReadRequest if (!(isValid(readReq)) && !c2hFinished && c2hInitiated);
        let pkg <- xdmaDescriptorGenerator.data.readRequest.get;
        readReq <= tagged Valid pkg;
    endrule

    FIFOF#(Bit#(AXI4_SLAVE_DATASz)) compareDataFifo <- mkSizedBRAMFIFOF(valueOf(TESTLENGTH));

    rule axi4SendReadResponse if (isValid(readReq));
        let pkg = fromMaybe(?, readReq);
        let actual = generateTestData(pkg.addr);
        compareDataFifo.enq(actual);
        xdmaDescriptorGenerator.data.readResponse.put(AXI4_Read_Rs {
            data: actual,
            last: (pkg.burst_length == 0),
            id: pkg.id,
            user: pkg.user,
            resp: OKAY
        });
        if (pkg.burst_length == 0) begin
            readReq <= tagged Invalid;
            c2hFinished <= True;
        end
        else begin
            pkg.burst_length = pkg.burst_length - 1;
            pkg.addr = pkg.addr + (1 << pack(pkg.burst_size));
            readReq <= tagged Valid pkg;
        end
    endrule

    rule axi4ReceiveWriteAddr if (!(isValid(writeReq)) && !h2cFinished && h2cInitiated);
        let addrPkg <- xdmaDescriptorGenerator.data.writeAddr.get;
        writeReq <= tagged Valid addrPkg;
    endrule

    rule axi4ReceiveWriteData if (isValid(writeReq));
        let addrPkg = fromMaybe(?, writeReq);
        let dataPkg <- xdmaDescriptorGenerator.data.writeData.get;
        let actual = dataPkg.data;
        let refer = compareDataFifo.first;
        compareDataFifo.deq;

        if (refer != actual) begin
            printColorTimed(RED, $format("Error: addr = %h, actual = %h, refer = %h", addrPkg.addr, actual, refer));
            h2cCheckedFailed <= True;
            $finish(fromInteger(valueOf(COMPARE_ERROR)));
        end
        if (addrPkg.burst_length == 'h0) begin
            writeReq <= tagged Invalid;
            h2cFinished <= True;
        end
        else begin
            addrPkg.burst_length = addrPkg.burst_length - 1;
            addrPkg.addr = addrPkg.addr + (1 << pack(addrPkg.burst_size));
            writeReq <= tagged Valid addrPkg;
        end
    endrule

    rule compareDataFifoNotEmpty if (h2cFinished && !h2cCheckedFailed && compareDataFifo.notEmpty);
        printColorTimed(RED, $format("Compare Data FIFO is not empty!"));
        $finish(fromInteger(valueOf(COMPARE_ERROR)));
    endrule

    rule finished if (h2cFinished && !h2cCheckedFailed && !compareDataFifo.notEmpty);
        printColorTimed(GREEN, $format("Test finished successfully."));
        printColorTimed(GREEN, $format("                  "));
        printColorTimed(GREEN, $format(" ____   _    ____ ____  "));
        printColorTimed(GREEN, $format("|  _ \\ / \\  / ___/ ___| "));
        printColorTimed(GREEN, $format("| |_) / _ \\ \\___ \\___ \\ "));
        printColorTimed(GREEN, $format("|  __/ ___ \\ ___) |__) |"));
        printColorTimed(GREEN, $format("|_| /_/   \\_\\____/____/ "));
        printColorTimed(GREEN, $format("                  "));
        $finish(fromInteger(valueOf(NO_ERROR)));
    endrule

    interface fab = xdmaDescriptorGenerator.fab;
endmodule
