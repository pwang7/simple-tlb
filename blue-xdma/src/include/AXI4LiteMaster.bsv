package AXI4LiteMaster;

import BlueAXI :: *;
import BlueLib :: *;
import GetPut  :: *;
import FIFOF   :: *;
`include "Config.defines"

interface IfcAxi4LiteMasterFab;
    (* prefix = "" *)
    interface AXI4_LITE_MASTER_WR_FAB wr;
    (* prefix = "" *)
    interface AXI4_LITE_MASTER_RD_FAB rd;
endinterface

interface IfcAxi4LiteMaster;
    interface IfcAxi4LiteMasterFab fab;
    interface Put#(AXI4_LITE_MASTER_WRITE_RQ) writeRequest;
    interface Get#(AXI4_LITE_MASTER_WRITE_RS) writeResponse;
    interface Put#(AXI4_LITE_MASTER_READ_RQ) readRequest;
    interface Get#(AXI4_LITE_MASTER_READ_RS) readResponse;
endinterface

module mkAXI4LiteMaster(IfcAxi4LiteMaster);

    AXI4_LITE_MASTER_WR m_wr <- mkAXI4_Lite_Master_Wr(valueOf(AXI4_LITE_MASTER_FIFOSz));
    AXI4_LITE_MASTER_RD m_rd <- mkAXI4_Lite_Master_Rd(valueOf(AXI4_LITE_MASTER_FIFOSz));


    interface fab = IfcAxi4LiteMasterFab {
        wr: m_wr.fab,
        rd: m_rd.fab
    };

    interface writeResponse = m_wr.response;
    interface readResponse = m_rd.response;
    interface writeRequest = m_wr.request;
    interface readRequest = m_rd.request;

endmodule

endpackage
