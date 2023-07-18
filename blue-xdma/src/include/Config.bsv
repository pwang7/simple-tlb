package Config;

import BlueAXI :: *;

typedef 3000 WAITRESET;
typedef 10000 TIMEOUT;

typedef 'h80 TESTLENGTH;
typedef 'h0 TESTSRCADDR;
typedef 'h800 TESTDSTADDR;

///////////////////////////////////////////////
/////           AXI4 Slave                /////
///////////////////////////////////////////////

typedef 64 AXI4_SLAVE_ADDRSz;
typedef 64 AXI4_SLAVE_DATASz;
typedef 4 AXI4_SLAVE_IDSz;
typedef 0 AXI4_SLAVE_USRSz;
typedef 0 AXI4_SLAVE_FIFOSz;
typedef AXI4_Read_Rq#(AXI4_SLAVE_ADDRSz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz) Axi4SlaveReadReq;
typedef AXI4_Read_Rs#(AXI4_SLAVE_DATASz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz) Axi4SlaveReadRsp;
typedef AXI4_Write_Rq_Addr#(AXI4_SLAVE_ADDRSz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz) Axi4SlaveWriteReqAddr;
typedef AXI4_Write_Rq_Data#(AXI4_SLAVE_DATASz, AXI4_SLAVE_USRSz) Axi4SlaveWriteReqData;
typedef AXI4_Write_Rs#(AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz) Axi4SlaveWriteRsp;
typedef AXI4_Slave_Wr#(AXI4_SLAVE_ADDRSz, AXI4_SLAVE_DATASz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz) Axi4SlaveWrite;
typedef AXI4_Slave_Rd#(AXI4_SLAVE_ADDRSz, AXI4_SLAVE_DATASz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz) Axi4SlaveRead;
typedef AXI4_Slave_Wr_Fab#(AXI4_SLAVE_ADDRSz, AXI4_SLAVE_DATASz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz) Axi4SlaveWriteFab;
typedef AXI4_Slave_Rd_Fab#(AXI4_SLAVE_ADDRSz, AXI4_SLAVE_DATASz, AXI4_SLAVE_IDSz, AXI4_SLAVE_USRSz) Axi4SlaveReadFab;

///////////////////////////////////////////////
/////           AXI4 Lite Master          /////
///////////////////////////////////////////////

typedef 32 AXI4_LITE_MASTER_ADDRSz;
typedef 32 AXI4_LITE_MASTER_DATASz;
typedef 1 AXI4_LITE_MASTER_FIFOSz;
typedef AXI4_Lite_Master_Wr_Fab#(AXI4_LITE_MASTER_ADDRSz, AXI4_LITE_MASTER_DATASz) Axi4LiteMasterWriteFab;
typedef AXI4_Lite_Master_Rd_Fab#(AXI4_LITE_MASTER_ADDRSz, AXI4_LITE_MASTER_DATASz) Axi4LiteMasterReadFab;
typedef AXI4_Lite_Write_Rq_Pkg#(AXI4_LITE_MASTER_ADDRSz, AXI4_LITE_MASTER_DATASz) Axi4LiteMasterWriteReq;
typedef AXI4_Lite_Write_Rs_Pkg Axi4LiteMasterWriteRsp;
typedef AXI4_Lite_Read_Rq_Pkg#(AXI4_LITE_MASTER_ADDRSz) Axi4LiteMasterReadReq;
typedef AXI4_Lite_Read_Rs_Pkg#(AXI4_LITE_MASTER_DATASz) Axi4LiteMasterReadRsp;
typedef AXI4_Lite_Master_Wr#(AXI4_LITE_MASTER_ADDRSz, AXI4_LITE_MASTER_DATASz) Axi4LiteMasterWrite;
typedef AXI4_Lite_Master_Rd#(AXI4_LITE_MASTER_ADDRSz, AXI4_LITE_MASTER_DATASz) Axi4LiteMasterRead;

endpackage
