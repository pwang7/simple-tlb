package Config;

import BlueAXI :: *;

typedef 3000 WAITRESET;
typedef 10000 STOPAFTER;

// Compatible with the example design
typedef 128 TESTLENGTH;
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

///////////////////////////////////////////////
/////             XDMA DESC               /////
///////////////////////////////////////////////

typedef 28 XDMA_DESC_LEN;
typedef 64 XDMA_DESC_ADDRSz;
typedef 16 XDMA_CTL_LEN;
typedef Bit#(XDMA_DESC_LEN) XDMADescriptorLength;
typedef Bit#(XDMA_DESC_ADDRSz) XDMADescriptorAddressSz;
typedef Bit#(XDMA_CTL_LEN) XDMADescriptorCtl;
typedef 'b11 XDMA_DESC_ENABLE;
typedef 'h1004 XDMA_C2H_ADDR;
typedef 'h0004 XDMA_H2C_ADDR;

///////////////////////////////////////////////
/////            ERROR CODE               /////
///////////////////////////////////////////////

typedef 0 NO_ERROR;
typedef 1 TIMEOUT_ERROR;
typedef 2 COMPARE_ERROR;
typedef 3 AXI4_LITE_CONTROL_ERROR;

endpackage
