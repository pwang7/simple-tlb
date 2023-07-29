import FIFOF::*;
import Clocks :: *;
import GetPut :: *;
import BlueAXI :: *;
import BlueLib :: *;
import AXI4LiteMaster :: *;
import StmtFSM :: *;
import Config :: *;
import AXI4Slave :: *;

typedef struct {
    XDMADescriptorLength length;
    XDMADescriptorAddressSz srcAddr;
    XDMADescriptorAddressSz dstAddr;
} XDMADescriptor deriving (Bits, Eq, FShow);

typedef enum {C2H, H2C} Direction deriving(Eq, Bits, FShow);

typedef struct {
    Direction dir;
    Bool enable;
} DMA_Configure deriving (Bits, Eq, FShow);

(* always_ready, always_enabled *)
interface IfcXDMAChannelFab;
    method Bool load;
    (* result = "src_addr" *) method XDMADescriptorAddressSz srcAddr;
    (* result = "dst_addr" *) method XDMADescriptorAddressSz dstAddr;
    (* result = "len" *) method XDMADescriptorLength len;
    (* result = "ctl" *) method XDMADescriptorCtl ctl;
    (* prefix = "" *) method Action ready((* port = "ready" *) Bool rdy);
endinterface

(* always_ready, always_enabled *)
interface IfcXDMADescriptorFab;
    (* prefix = "m_axil" *) interface IfcAxi4LiteMasterFab liteFab;
    (* prefix = "c2h_dsc_byp" *) interface IfcXDMAChannelFab c2hFab;
    (* prefix = "h2c_dsc_byp" *) interface IfcXDMAChannelFab h2cFab;
    (* prefix = "s_axi" *) interface IfcAxi4SlaveFab axi4SlaveFab;
endinterface

interface IfcXDMADescriptor;
    interface Put#(XDMADescriptor) c2h;
    interface Put#(XDMADescriptor) h2c;
    method Action controlDMA(DMA_Configure control);
endinterface

interface IfcXDMADescriptorGeneratorTop;
    interface IfcXDMADescriptorFab fab;
    interface IfcXDMADescriptor dsc;
    interface IfcAxi4SlaveData data;
endinterface

module mkXDMADescriptorGenerator(IfcXDMADescriptorGeneratorTop);

    let axi4LiteMaster <- mkAXI4LiteMaster;
    let axi4Slave <- mkAxi4Slave;

    Reg#(Bool) c2hReadyAfterLoadReg <- mkReg(False);
    Reg#(Bool) h2cReadyAfterLoadReg <- mkReg(False);
    Reg#(Bool) controlError <- mkReg(False);

    FIFOF#(XDMADescriptor) c2hDescriptorFifo <- mkFIFOF;
    FIFOF#(XDMADescriptor) h2cDescriptorFifo <- mkFIFOF;

    Reg#(Axi4LiteMasterWriteRsp) writeResponse <- mkReg(unpack(0));

    Wire#(XDMADescriptorAddressSz) c2hDscBypSrcAddr <- mkDWire(0);
    Wire#(XDMADescriptorAddressSz) c2hDscBypDstAddr <- mkDWire(0);
    Wire#(XDMADescriptorLength) c2hDscBypLen <- mkDWire(0);
    Wire#(XDMADescriptorCtl) c2hDscBypEn <- mkDWire(0);
    Wire#(Bool) c2hDscBypReady <- mkBypassWire;

    Wire#(XDMADescriptorAddressSz) h2cDscBypSrcAddr <- mkDWire(0);
    Wire#(XDMADescriptorAddressSz) h2cDscBypDstAddr <- mkDWire(0);
    Wire#(XDMADescriptorLength) h2cDscBypLen <- mkDWire(0);
    Wire#(XDMADescriptorCtl) h2cDscBypCtl <- mkDWire(0);
    Wire#(Bool) h2cDscBypReady <- mkBypassWire;

    rule clearWriteResponse;
        let pkg <- axi4LiteMaster.writeResponse.get;
        if (pkg.resp != OKAY && pkg.resp != EXOKAY) begin
            printColorTimed(RED, $format("AXI4LiteMaster write response error"));
            controlError <= True;
            $finish(fromInteger(valueOf(AXI4_LITE_CONTROL_ERROR)));
        end
    endrule

    rule c2hForward;
        let pkg = c2hDescriptorFifo.first;
        c2hDscBypSrcAddr <= pkg.srcAddr;
        c2hDscBypDstAddr <= pkg.dstAddr;
        c2hDscBypLen <= pkg.length;
        c2hDscBypEn <= fromInteger(valueOf(XDMA_DESC_ENABLE));
    endrule

    rule c2hTransfer if (c2hDscBypReady || c2hReadyAfterLoadReg);
        let pkg = c2hDescriptorFifo.first;
        c2hDescriptorFifo.deq;
        printColorTimed(GREEN, $format("Start C2HTransfer %h -> %h (%h)", pkg.srcAddr, pkg.dstAddr, pkg.length));
        c2hReadyAfterLoadReg <= c2hDscBypReady;
    endrule

    rule h2cForward;
        let pkg = h2cDescriptorFifo.first;
        h2cDscBypSrcAddr <= pkg.srcAddr;
        h2cDscBypDstAddr <= pkg.dstAddr;
        h2cDscBypLen <= pkg.length;
        h2cDscBypCtl <= fromInteger(valueOf(XDMA_DESC_ENABLE));
    endrule

    rule h2cTransfer if (h2cDscBypReady || h2cReadyAfterLoadReg);
        let pkg = h2cDescriptorFifo.first;
        h2cDescriptorFifo.deq;
        printColorTimed(GREEN, $format("Start H2CTransfer %h -> %h (%h)", pkg.srcAddr, pkg.dstAddr, pkg.length));
        h2cReadyAfterLoadReg <= h2cDscBypReady;
    endrule

    function Action controlDMA(DMA_Configure control);
        return action
            if (!controlError) begin
                axi4LiteMaster.writeRequest.put(AXI4_Lite_Write_Rq_Pkg {
                    addr: (control.dir == C2H) ? fromInteger(valueOf(XDMA_C2H_ADDR)) : fromInteger(valueOf(XDMA_H2C_ADDR)),
                    data: zeroExtend(pack(control.enable)),
                    strb: maxBound,
                    prot: UNPRIV_SECURE_DATA
                });
            end
        endaction;
    endfunction

    interface fab = IfcXDMADescriptorFab {
        liteFab: axi4LiteMaster.fab,
        c2hFab: IfcXDMAChannelFab {
            load: c2hDescriptorFifo.notEmpty,
            srcAddr: c2hDscBypSrcAddr,
            dstAddr: c2hDscBypDstAddr,
            len: c2hDscBypLen,
            ctl: c2hDscBypEn,
            ready: c2hDscBypReady._write
        },
        h2cFab: IfcXDMAChannelFab {
            load: h2cDescriptorFifo.notEmpty,
            srcAddr: h2cDscBypSrcAddr,
            dstAddr: h2cDscBypDstAddr,
            len: h2cDscBypLen,
            ctl: h2cDscBypCtl,
            ready: h2cDscBypReady._write
        },
        axi4SlaveFab: axi4Slave.fab
    };
    interface dsc = IfcXDMADescriptor {
        c2h: toPut(c2hDescriptorFifo),
        h2c: toPut(h2cDescriptorFifo),
        controlDMA: controlDMA
    };
    interface data = axi4Slave.data;
endmodule
