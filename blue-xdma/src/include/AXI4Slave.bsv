package AXI4Slave;

import BlueAXI :: *;
import BlueLib :: *;
import GetPut  :: *;
import FIFOF   :: *;
`include "Config.defines"

interface IfcAxi4SlaveFab;
    (* prefix = "" *)
    interface AXI4_SLAVE_WR_FAB wr;
    (* prefix = "" *)
    interface AXI4_SLAVE_RD_FAB rd;
endinterface

interface IfcAxi4Slave;
    (* prefix = "" *)
    interface IfcAxi4SlaveFab fab;
    interface Get#(AXI4_SLAVE_READ_RQ) readRequest;
    interface Put#(AXI4_SLAVE_READ_RS) readResponse;
    interface Get#(AXI4_SLAVE_WRITE_RQ_ADDR) writeAddr;
    interface Get#(AXI4_SLAVE_WRITE_RQ_DATA) writeData;
    interface Put#(AXI4_SLAVE_WRITE_RS) writeResponse;
endinterface

module mkAXI4Slave(IfcAxi4Slave);
    AXI4_SLAVE_WR s_wr <- mkAXI4_Slave_Wr(valueOf(AXI4_SLAVE_FIFOSz), valueOf(AXI4_SLAVE_FIFOSz), valueOf(AXI4_SLAVE_FIFOSz));
    AXI4_SLAVE_RD s_rd <- mkAXI4_Slave_Rd(valueOf(AXI4_SLAVE_FIFOSz), valueOf(AXI4_SLAVE_FIFOSz));

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
