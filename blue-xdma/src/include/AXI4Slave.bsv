package AXI4Slave;

import BlueAXI :: *;
import BlueLib :: *;
import GetPut  :: *;
import FIFOF   :: *;
import Config  :: *;

interface IfcAxi4SlaveFab;
    (* prefix = "" *)
    interface Axi4SlaveWriteFab wr;
    (* prefix = "" *)
    interface Axi4SlaveReadFab rd;
endinterface

interface IfcAxi4Slave;
    (* prefix = "" *)
    interface IfcAxi4SlaveFab fab;
    interface Get#(Axi4SlaveReadReq) readRequest;
    interface Put#(Axi4SlaveReadRsp) readResponse;
    interface Get#(Axi4SlaveWriteReqAddr) writeAddr;
    interface Get#(Axi4SlaveWriteReqData) writeData;
    interface Put#(Axi4SlaveWriteRsp) writeResponse;
endinterface

module mkAXI4Slave(IfcAxi4Slave);
    Axi4SlaveWrite s_wr <- mkAXI4_Slave_Wr(valueOf(AXI4_SLAVE_FIFOSz), valueOf(AXI4_SLAVE_FIFOSz), valueOf(AXI4_SLAVE_FIFOSz));
    Axi4SlaveRead s_rd <- mkAXI4_Slave_Rd(valueOf(AXI4_SLAVE_FIFOSz), valueOf(AXI4_SLAVE_FIFOSz));

    interface fab = IfcAxi4SlaveFab {
        wr: s_wr.fab,
        rd: s_rd.fab
    };
    interface readRequest = s_rd.request;
    interface readResponse = s_rd.response;
    interface writeAddr = s_wr.request_addr;
    interface writeData = s_wr.request_data;
    interface writeResponse = s_wr.response;
endmodule

endpackage
