// =============================================================================
//  sinkc_pkg —— coupledL2 (tl2chi) TileLink C 通道接收器 SinkC 的常量 / 类型
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/SinkC.scala
//  单态化参数 (firtool SinkC.sv, KunmingHu V2R2 配置):
//    bufBlocks=4   (Release/ProbeAckData 数据缓冲块数, dataBuf/beatValids/taskBuf 各 4)
//    beatSize =2   (每块 2 拍, beatBytes=32 => 256 bit/拍)
//    bufIdxBits=2  mshrsAll=16 (io_msInfo 16 路)  ways=8 (wayMask=8'hFF)
//
//  说明: SinkC 把上层 (DCache) 来的 C 通道事务归一成内部 TaskBundle:
//    - Release / ReleaseData : 经 4 表项缓冲, 由 RRArbiterInit 轮询后送 RequestArb
//    - ProbeAck / ProbeAckData: 经 io.resp 唤醒 MSHR 的 w_probeack;
//      ProbeAckData 数据写 ReleaseBuffer
//  TaskBundle 共 95 个字段, toTaskBundle 只填其中 12 个 (其余恒 0); 但 golden 把整条
//  bundle 都建成寄存器, 故可读核同样逐字段保留 (见 SinkC.sv 的 `SC_TB_* 宏)。
// =============================================================================
package sinkc_pkg;

  localparam int BUF_BLOCKS = 4;   // 数据/任务缓冲块数
  localparam int BEAT_SIZE  = 2;   // 每块拍数
  localparam int MSHRS      = 16;  // io_msInfo 路数

  // ---------------- TileLink C 通道 opcode (rocket-chip TLMessages) ----------------
  //  bit1 = isRelease (Release/ReleaseData), bit0 = hasData (ProbeAckData/ReleaseData)
  typedef enum logic [2:0] {
    PROBE_ACK      = 3'd4,  // 100
    PROBE_ACK_DATA = 3'd5,  // 101
    RELEASE        = 3'd6,  // 110
    RELEASE_DATA   = 3'd7   // 111
  } tlc_opcode_e;

  // toTaskBundle 中 task.opcode 为 4-bit ReleaseData 编码 (refillBufWrite 判定用)
  localparam logic [3:0] TASK_RELEASE_DATA = 4'd7;

  // OHToUInt: 16 位 one-hot -> 4 位下标 (与 golden 门级归约等价; 非 one-hot 时与 golden 同值)
  function automatic logic [3:0] ohToUInt16(input logic [15:0] m);
    ohToUInt16 = {|(m & 16'hFF00), |(m & 16'hF0F0), |(m & 16'hCCCC), |(m & 16'hAAAA)};
  endfunction

endpackage
