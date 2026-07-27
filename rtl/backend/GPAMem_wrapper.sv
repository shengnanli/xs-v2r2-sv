// 自动生成: golden 同名 wrapper(FM impl), 例化 xs_GPAMem_core。
module GPAMem(
  input clock,
  input reset,
  input io_fromIFU_gpaddrMem_wen,
  input [5:0] io_fromIFU_gpaddrMem_waddr,
  input [55:0] io_fromIFU_gpaddrMem_wdata_gpaddr,
  input io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE,
  input io_exceptionReadAddr_valid,
  input [5:0] io_exceptionReadAddr_bits_ftqPtr_value,
  input [3:0] io_exceptionReadAddr_bits_ftqOffset,
  output [55:0] io_exceptionReadData_gpaddr,
  output io_exceptionReadData_isForVSnonLeafPTE
);
  xs_GPAMem_core u_core (
    .clock(clock),
    .reset(reset),
    .io_fromIFU_gpaddrMem_wen(io_fromIFU_gpaddrMem_wen),
    .io_fromIFU_gpaddrMem_waddr(io_fromIFU_gpaddrMem_waddr),
    .io_fromIFU_gpaddrMem_wdata_gpaddr(io_fromIFU_gpaddrMem_wdata_gpaddr),
    .io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE(io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE),
    .io_exceptionReadAddr_valid(io_exceptionReadAddr_valid),
    .io_exceptionReadAddr_bits_ftqPtr_value(io_exceptionReadAddr_bits_ftqPtr_value),
    .io_exceptionReadAddr_bits_ftqOffset(io_exceptionReadAddr_bits_ftqOffset),
    .io_exceptionReadData_gpaddr(io_exceptionReadData_gpaddr),
    .io_exceptionReadData_isForVSnonLeafPTE(io_exceptionReadData_isForVSnonLeafPTE)
  );
endmodule
