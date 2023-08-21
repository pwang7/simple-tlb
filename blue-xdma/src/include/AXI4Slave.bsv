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

interface IfcAxi4SlaveData;
    interface Get#(Axi4SlaveReadReq) readRequest;
    interface Put#(Axi4SlaveReadRsp) readResponse;
    interface Get#(Axi4SlaveWriteReqAddr) writeAddr;
    interface Get#(Axi4SlaveWriteReqData) writeData;
    interface Put#(Axi4SlaveWriteRsp) writeResponse;
endinterface

interface IfcAxi4Slave;
    (* prefix = "" *)
    interface IfcAxi4SlaveFab fab;
    interface IfcAxi4SlaveData data;
endinterface

module mkAxi4Slave(IfcAxi4Slave);
    Axi4SlaveWrite wr <- mkAXI4_Slave_Wr(valueOf(AXI4_SLAVE_FIFOSz), valueOf(AXI4_SLAVE_FIFOSz), valueOf(AXI4_SLAVE_FIFOSz));
    Axi4SlaveRead rd <- mkAXI4_Slave_Rd(valueOf(AXI4_SLAVE_FIFOSz), valueOf(AXI4_SLAVE_FIFOSz));

    interface fab = IfcAxi4SlaveFab {
        wr: wr.fab,
        rd: rd.fab
    };
    interface data = IfcAxi4SlaveData {
        readRequest: rd.request,
        readResponse: rd.response,
        writeAddr: wr.request_addr,
        writeData: wr.request_data,
        writeResponse: wr.response
    };
endmodule

endpackage
