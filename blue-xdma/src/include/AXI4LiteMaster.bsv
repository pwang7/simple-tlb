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

    Axi4LiteMasterWrite wr <- mkAXI4_Lite_Master_Wr(valueOf(AXI4_LITE_MASTER_FIFOSz));
    Axi4LiteMasterRead rd <- mkAXI4_Lite_Master_Rd(valueOf(AXI4_LITE_MASTER_FIFOSz));

    interface fab = IfcAxi4LiteMasterFab {
        wr: wr.fab,
        rd: rd.fab
    };

    interface writeResponse = wr.response;
    interface readResponse = rd.response;
    interface writeRequest = wr.request;
    interface readRequest = rd.request;

endmodule

endpackage
