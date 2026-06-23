// UopInfoGen_xs —— UT 用可读核包装(golden 同端口,改名避免与 golden 冲突)。
import uopinfogen_pkg::*;

module UopInfoGen_it (
  input        io_in_preInfo_isVecArith,
  input        io_in_preInfo_isVecMem,
  input        io_in_preInfo_isAmoCAS,
  input  [5:0] io_in_preInfo_typeOfSplit,
  input  [1:0] io_in_preInfo_vsew,
  input  [2:0] io_in_preInfo_vlmul,
  input  [2:0] io_in_preInfo_vwidth,
  input  [2:0] io_in_preInfo_nf,
  input  [2:0] io_in_preInfo_vmvn,
  input        io_in_preInfo_isVlsr,
  input        io_in_preInfo_isVlsm,
  output       io_out_isComplex,
  output [6:0] io_out_uopInfo_numOfUop,
  output [6:0] io_out_uopInfo_numOfWB,
  output [3:0] io_out_uopInfo_lmul
);
  preinfo_t pre;
  uopinfo_t info;
  logic     cplx;
  assign pre = '{
    isVecArith:  io_in_preInfo_isVecArith,
    isVecMem:    io_in_preInfo_isVecMem,
    isAmoCAS:    io_in_preInfo_isAmoCAS,
    typeOfSplit: io_in_preInfo_typeOfSplit,
    vsew:        io_in_preInfo_vsew,
    vlmul:       io_in_preInfo_vlmul,
    vwidth:      io_in_preInfo_vwidth,
    nf:          io_in_preInfo_nf,
    vmvn:        io_in_preInfo_vmvn,
    isVlsr:      io_in_preInfo_isVlsr,
    isVlsm:      io_in_preInfo_isVlsm
  };
  xs_UopInfoGen_core u_core (.pre(pre), .is_complex(cplx), .uop_info(info));
  assign io_out_isComplex        = cplx;
  assign io_out_uopInfo_numOfUop = info.numOfUop;
  assign io_out_uopInfo_numOfWB  = info.numOfWB;
  assign io_out_uopInfo_lmul     = info.lmul;
endmodule
