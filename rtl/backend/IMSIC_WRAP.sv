// IMSIC_WRAP.sv — the CSR unit's handle on its per-hart IMSIC (AIA incoming-MSI controller).
// Scala: ChiselAIA/src/main/scala/IMSIC.scala (class IMSIC_WRAP), instantiated by
// xiangshan/backend/fu/wrapper/CSR.scala:218 as `imsic`.  The wrapper exists
// for the optional TEE/CVM extension (HasTEEIMSIC adds sec/teemsiio ports and
// pending-notice logic).  KunminghuV2 does not enable it, so the wrapper adds
// no logic at all: every port is passed straight through to a single IMSIC
// instance named `imsic` (rewritten in rtl/uncore/IMSIC.sv).
//   toCSR_*    read data / illegal / pending bits / topei for M, S and VS files
//   fromCSR_*  the miselect/mireg/mtopei-style CSR access from NewCSR
//   msiio_*    an incoming MSI (12-bit interrupt identity) and its ack
// There is no core here on purpose: a pass-through has nothing to explain
// beyond this header, and wrapping it in a core would only add a level.
module IMSIC_WRAP (
  input         clock,
  input         reset,
  output        toCSR_rdata_valid,
  output [63:0] toCSR_rdata_bits,
  output        toCSR_illegal,
  output [8:0]  toCSR_pendings,
  output [31:0] toCSR_topeis_0,
  output [31:0] toCSR_topeis_1,
  output [31:0] toCSR_topeis_2,
  input         fromCSR_addr_valid,
  input  [11:0] fromCSR_addr_bits_addr,
  input         fromCSR_addr_bits_virt,
  input  [1:0]  fromCSR_addr_bits_priv,
  input  [5:0]  fromCSR_vgein,
  input         fromCSR_wdata_valid,
  input  [1:0]  fromCSR_wdata_bits_op,
  input  [63:0] fromCSR_wdata_bits_data,
  input         fromCSR_claims_0,
  input         fromCSR_claims_1,
  input         fromCSR_claims_2,
  input         msiio_vld_req,
  input  [11:0] msiio_data,
  output        msiio_vld_ack
);
  IMSIC imsic (
    .clock                   (clock),
    .reset                   (reset),
    .toCSR_rdata_valid       (toCSR_rdata_valid),
    .toCSR_rdata_bits        (toCSR_rdata_bits),
    .toCSR_illegal           (toCSR_illegal),
    .toCSR_pendings          (toCSR_pendings),
    .toCSR_topeis_0          (toCSR_topeis_0),
    .toCSR_topeis_1          (toCSR_topeis_1),
    .toCSR_topeis_2          (toCSR_topeis_2),
    .fromCSR_addr_valid      (fromCSR_addr_valid),
    .fromCSR_addr_bits_addr  (fromCSR_addr_bits_addr),
    .fromCSR_addr_bits_virt  (fromCSR_addr_bits_virt),
    .fromCSR_addr_bits_priv  (fromCSR_addr_bits_priv),
    .fromCSR_vgein           (fromCSR_vgein),
    .fromCSR_wdata_valid     (fromCSR_wdata_valid),
    .fromCSR_wdata_bits_op   (fromCSR_wdata_bits_op),
    .fromCSR_wdata_bits_data (fromCSR_wdata_bits_data),
    .fromCSR_claims_0        (fromCSR_claims_0),
    .fromCSR_claims_1        (fromCSR_claims_1),
    .fromCSR_claims_2        (fromCSR_claims_2),
    .msiio_vld_req           (msiio_vld_req),
    .msiio_data              (msiio_data),
    .msiio_vld_ack           (msiio_vld_ack)
  );
endmodule
