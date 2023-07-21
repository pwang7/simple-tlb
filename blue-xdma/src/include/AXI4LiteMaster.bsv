package AXI4LiteMaster;

import BlueAXI :: *;
import BlueLib :: *;
import GetPut  :: *;
import FIFOF   :: *;
import Config  :: *;

interface IfcAxi4LiteMasterFab;
    (* prefix = "" *)
    interface Axi4LiteMasterWriteFab wr;
    (* prefix = "" *)
    interface Axi4LiteMasterReadFab rd;
endinterface

interface IfcAxi4LiteMaster;
    interface IfcAxi4LiteMasterFab fab;
    interface Put#(Axi4LiteMasterWriteReq) writeRequest;
    interface Get#(Axi4LiteMasterWriteRsp) writeResponse;
    interface Put#(Axi4LiteMasterReadReq) readRequest;
    interface Get#(Axi4LiteMasterReadRsp) readResponse;
endinterface

module mkAxi4LiteMaster(IfcAxi4LiteMaster);

    Axi4LiteMasterWrite m_wr <- mkAXI4_Lite_Master_Wr(valueOf(AXI4_LITE_MASTER_FIFOSz));
    Axi4LiteMasterRead m_rd <- mkAXI4_Lite_Master_Rd(valueOf(AXI4_LITE_MASTER_FIFOSz));


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
