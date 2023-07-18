import FIFOF::*;
import Clocks :: *;
import GetPut :: *;
import BlueAXI :: *;
import BlueLib :: *;
import AXI4LiteMaster :: *;
import AXI4Slave :: *;
import XDMADescriptorGenerator :: *;
import StmtFSM :: *;
import Config :: *;

interface IfcTop;
    (* prefix = "m_axil" *) interface IfcAxi4LiteMasterFab ifcAxi4LiteMaster;
    (* prefix = "s_axi" *) interface IfcAxi4SlaveFab ifcAxi4Slave;
    (* prefix = "c2h_dsc_byp" *) interface IfcXDMADescriptorGeneratorFab c2hFab;
    (* prefix = "h2c_dsc_byp" *) interface IfcXDMADescriptorGeneratorFab h2cFab;
endinterface

(* synthesize, clock_prefix = "axi_aclk", reset_prefix = "axi_aresetn" *)
module mkXDMATestbench(IfcTop);

    let xdmaDescriptorGenerator <- mkXDMADescriptorGenerator();
    let axi4Slave <- mkAXI4Slave();

    Reg#(Maybe#(AXI4_Read_Rq#(AXI4_SLAVE_ADDRSz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz))) readReq <- mkReg(tagged Invalid);
    Reg#(Maybe#(AXI4_Write_Rq_Addr#(AXI4_SLAVE_ADDRSz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz))) writeReq <- mkReg(tagged Invalid);

    Reg#(Bool) c2hInitiated <- mkReg(False);
    Reg#(Bool) h2cInitiated <- mkReg(False);
    Reg#(Bool) c2hFinished <- mkReg(False);
    Reg#(Bool) h2cFinished <- mkReg(False);
    Reg#(Bool) h2cCheckedFailed <- mkReg(False);

    function Bit#(AXI4_SLAVE_DATASz) generatePattern(Bit#(AXI4_SLAVE_ADDRSz) addr);
        Bit#(AXI4_SLAVE_DATASz) out = 0;
        for (Integer i = valueOf(AXI4_SLAVE_DATASz) / 8 - 1; i >= 0; i = i - 1) begin
            out = out << 8;
            out = out | ((addr + fromInteger(i)) & 'hFF);
        end
        return out;
    endfunction

    Reg#(UInt#(64)) count <- mkReg(0);

    rule forceStop;
        count <= count + 1;
        if (count >= fromInteger(valueOf(TIMEOUT))) begin
            printColorTimed(RED, $format("If you see this, the test has timed out."));
            $finish(1);
        end
    endrule

    rule initC2HTransfer if (count == fromInteger(valueOf(WAITRESET)) && !c2hInitiated);
        printColorTimed(BLUE, $format("Initiating C2H Transfer..."));
        xdmaDescriptorGenerator.startC2HTransfer();
        xdmaDescriptorGenerator.c2h.put(XDMADescriptor {
            length: fromInteger(valueOf(TESTLENGTH)),
            srcAddr: fromInteger(valueOf(TESTSRCADDR)),
            dstAddr: fromInteger(valueOf(TESTDSTADDR))
        });
        c2hInitiated <= True;
    endrule

    rule initH2CTransfer if (c2hInitiated && c2hFinished && !h2cInitiated);
        printColorTimed(BLUE, $format("Initiating H2C Transfer..."));
        xdmaDescriptorGenerator.startH2CTransfer();
        xdmaDescriptorGenerator.h2c.put(XDMADescriptor {
            length: fromInteger(valueOf(TESTLENGTH)),
            srcAddr: fromInteger(valueOf(TESTDSTADDR)),
            dstAddr: fromInteger(valueOf(TESTSRCADDR))
        });
        h2cInitiated <= True;
    endrule

    rule axi4ReceiveReadRequest if (!(isValid(readReq)) && !c2hFinished && c2hInitiated);
        let pkg <- axi4Slave.readRequest.get();
        readReq <= tagged Valid(pkg);
    endrule

    rule axi4ReceiveReadResponse if (isValid(readReq));
        let pkg = fromMaybe(?, readReq);
        let pattern = generatePattern(pkg.addr);

        axi4Slave.readResponse.put(AXI4_Read_Rs {
            data: pattern,
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
            readReq <= tagged Valid(pkg);
        end
    endrule

    rule axi4ReceiveWriteRequest if (!(isValid(writeReq)) && !h2cFinished && h2cInitiated);
        let addrPkg <- axi4Slave.writeAddr.get();
        writeReq <= tagged Valid(addrPkg);
    endrule

    rule axi4ReceiveWriteResponse if (isValid(writeReq));
        let addrPkg = fromMaybe(?, writeReq);
        let dataPkg <- axi4Slave.writeData.get();
        let data = dataPkg.data;
        let pattern = generatePattern(addrPkg.addr);

        if (pattern != data) begin
            printColorTimed(RED, $format("Error: addr = %h, data = %h", addrPkg.addr, data));
            h2cCheckedFailed <= True;
            $finish(2);
        end
        if (addrPkg.burst_length == 'h0) begin
            writeReq <= tagged Invalid;
            h2cFinished <= True;
        end
        else begin
            addrPkg.burst_length = addrPkg.burst_length - 1;
            addrPkg.addr = addrPkg.addr + (1 << pack(addrPkg.burst_size));
            writeReq <= tagged Valid(addrPkg);
        end
    endrule

    rule finished if (h2cFinished && !h2cCheckedFailed);
        printColorTimed(GREEN, $format("Test finished successfully."));
        printColorTimed(GREEN, $format("                  "));
        printColorTimed(GREEN, $format(" ____   _    ____ ____  "));
        printColorTimed(GREEN, $format("|  _ \\ / \\  / ___/ ___| "));
        printColorTimed(GREEN, $format("| |_) / _ \\ \\___ \\___ \\ "));
        printColorTimed(GREEN, $format("|  __/ ___ \\ ___) |__) |"));
        printColorTimed(GREEN, $format("|_| /_/   \\_\\____/____/ "));
        printColorTimed(GREEN, $format("                  "));
        $finish(0);
    endrule

    interface ifcAxi4LiteMaster = xdmaDescriptorGenerator.liteFab;
    interface ifcAxi4Slave = axi4Slave.fab;
    interface c2hFab = xdmaDescriptorGenerator.c2hFab;
    interface h2cFab = xdmaDescriptorGenerator.h2cFab;

endmodule
