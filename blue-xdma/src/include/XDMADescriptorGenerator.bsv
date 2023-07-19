import FIFOF::*;
import Clocks :: *;
import GetPut :: *;
import BlueAXI :: *;
import BlueLib :: *;
import AXI4LiteMaster :: *;
import StmtFSM :: *;
import Config :: *;

typedef struct {
    XDMADescriptorLength length;
    XDMADescriptorAddressSz srcAddr;
    XDMADescriptorAddressSz dstAddr;
} XDMADescriptor deriving (Bits, Eq, FShow);

typedef struct {
    Bool isC2H;
    Bool isEnable;
} ControlDMAIfc deriving (Bits, Eq, FShow);

(* always_ready, always_enabled *)
interface IfcXDMADescriptorFab;
    method Bool load;
    method XDMADescriptorAddressSz src_addr;
    method XDMADescriptorAddressSz dst_addr;
    method XDMADescriptorLength len;
    method XDMADescriptorCtl ctl;
    (* prefix = "" *) method Action ready((* port = "ready" *) Bool rdy);
endinterface

(* always_ready, always_enabled *)
interface IfcXDMADescriptorGeneratorFab;
    (* prefix = "m_axil" *) interface IfcAxi4LiteMasterFab liteFab;
    (* prefix = "c2h_dsc_byp" *) interface IfcXDMADescriptorFab c2hFab;
    (* prefix = "h2c_dsc_byp" *) interface IfcXDMADescriptorFab h2cFab;
endinterface

interface IfcXDMADescriptor;
    interface Put#(XDMADescriptor) c2h;
    interface Put#(XDMADescriptor) h2c;
    method Action startC2HTransfer;
    method Action stopC2HTransfer;
    method Action startH2CTransfer;
    method Action stopH2CTransfer;
endinterface

interface IfcXDMADescriptorGenerator;
    interface IfcXDMADescriptorGeneratorFab fab;
    interface IfcXDMADescriptor dsc;
endinterface

module mkXDMADescriptorGenerator(IfcXDMADescriptorGenerator);

    let axi4LiteMaster <- mkAXI4LiteMaster();

    FIFOF#(XDMADescriptor) c2hDescriptorFifo <- mkFIFOF;
    FIFOF#(XDMADescriptor) h2cDescriptorFifo <- mkFIFOF;

    ////////////////////////////////////////////////////////////////////////////
    ///////////////////////   Controller   /////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    Reg#(AXI4_Lite_Write_Rs_Pkg) writeResponse <- mkReg(unpack(0));

    Wire#(XDMADescriptorAddressSz) c2h_dsc_byp_src_addr <- mkDWire(0);
    Wire#(XDMADescriptorAddressSz) c2h_dsc_byp_dst_addr <- mkDWire(0);
    Wire#(XDMADescriptorLength) c2h_dsc_byp_len <- mkDWire(0);
    Wire#(XDMADescriptorCtl) c2h_dsc_byp_en <- mkDWire(0);
    Wire#(Bool) c2h_dsc_byp_ready <- mkBypassWire();

    Wire#(XDMADescriptorAddressSz) h2c_dsc_byp_src_addr <- mkDWire(0);
    Wire#(XDMADescriptorAddressSz) h2c_dsc_byp_dst_addr <- mkDWire(0);
    Wire#(XDMADescriptorLength) h2c_dsc_byp_len <- mkDWire(0);
    Wire#(XDMADescriptorCtl) h2c_dsc_byp_ctl <- mkDWire(0);
    Wire#(Bool) h2c_dsc_byp_ready <- mkBypassWire();

    rule clearWriteResponse;
        let pkg <- axi4LiteMaster.writeResponse.get();
    endrule

    rule c2hForward;
        let pkg = c2hDescriptorFifo.first;
        c2h_dsc_byp_src_addr <= pkg.srcAddr;
        c2h_dsc_byp_dst_addr <= pkg.dstAddr;
        c2h_dsc_byp_len <= pkg.length;
        c2h_dsc_byp_en <= fromInteger(valueOf(XDMA_DESC_ENABLE));
    endrule

    rule c2hTransfer if (c2h_dsc_byp_ready);
        let pkg = c2hDescriptorFifo.first;
        c2hDescriptorFifo.deq();
        printColorTimed(GREEN, $format("Start C2HTransfer %h -> %h (%h)", pkg.srcAddr, pkg.dstAddr, pkg.length));
    endrule

    rule h2cForward;
        let pkg = h2cDescriptorFifo.first;
        h2c_dsc_byp_src_addr <= pkg.srcAddr;
        h2c_dsc_byp_dst_addr <= pkg.dstAddr;
        h2c_dsc_byp_len <= pkg.length;
        h2c_dsc_byp_ctl <= fromInteger(valueOf(XDMA_DESC_ENABLE));
    endrule

    rule h2cTransfer if (h2c_dsc_byp_ready);
        let pkg = h2cDescriptorFifo.first;
        h2cDescriptorFifo.deq();
        printColorTimed(GREEN, $format("Start H2CTransfer %h -> %h (%h)", pkg.srcAddr, pkg.dstAddr, pkg.length));
    endrule

    function Action controlDMA(ControlDMAIfc control);
        return action axi4LiteMaster.writeRequest.put(AXI4_Lite_Write_Rq_Pkg {
            addr: control.isC2H ? fromInteger(valueOf(XDMA_C2H_ADDR)) : fromInteger(valueOf(XDMA_H2C_ADDR)),
            data: control.isEnable ? 'h1 : 'h0,
            strb: maxBound,
            prot: UNPRIV_SECURE_DATA
        });
        endaction;
    endfunction

    interface fab = IfcXDMADescriptorGeneratorFab {
        liteFab: axi4LiteMaster.fab,
        c2hFab: IfcXDMADescriptorFab {
            load: c2hDescriptorFifo.notEmpty,
            src_addr: c2h_dsc_byp_src_addr,
            dst_addr: c2h_dsc_byp_dst_addr,
            len: c2h_dsc_byp_len,
            ctl: c2h_dsc_byp_en,
            ready: c2h_dsc_byp_ready._write
        },
        h2cFab: IfcXDMADescriptorFab {
            load: h2cDescriptorFifo.notEmpty,
            src_addr: h2c_dsc_byp_src_addr,
            dst_addr: h2c_dsc_byp_dst_addr,
            len: h2c_dsc_byp_len,
            ctl: h2c_dsc_byp_ctl,
            ready: h2c_dsc_byp_ready._write
        }
    };
    interface dsc = IfcXDMADescriptor {
        c2h: toPut(c2hDescriptorFifo),
        h2c: toPut(h2cDescriptorFifo),
        startC2HTransfer: controlDMA(ControlDMAIfc {
            isC2H: True,
            isEnable: True
        }),
        stopC2HTransfer: action
            controlDMA(ControlDMAIfc {
                isC2H: True,
                isEnable: False
            });
            c2hDescriptorFifo.clear();
        endaction,
        startH2CTransfer: controlDMA(ControlDMAIfc {
            isC2H: False,
            isEnable: True
        }),
        stopH2CTransfer: action
            controlDMA(ControlDMAIfc {
                isC2H: False,
                isEnable: False
            });
            h2cDescriptorFifo.clear();
        endaction
    };
endmodule
