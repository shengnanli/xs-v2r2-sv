// =============================================================================
// L2Top —— 香山 Tile 里 L2 那一层的装配壳：L2 Cache + 总线缓冲 / 交叉开关 / 日志 + BEU + 核与 Tile 之间的打拍
//
// Scala：src/main/scala/xiangshan/L2Top.scala（class L2TopInlined.Imp）。
// 位置：XSTile 里（核 XSCore 与 Tile 外部总线之间）。
//
// 结构（golden 3779 行，绝大部分是 21 个 child 的逐端口连线；child 全部是已签核的重写件）：
//
//   核的 L1 TileLink ─▶ inner_buffer(s) / inner_logger* ─▶ inner_xbar ─▶ inner_l2cache（TL2CHICoupledL2）─▶ io_chi
//   核的 MMIO / PTW ─▶ inner_i_mmio_buffer / inner_ptw_to_l2_buffer ─▶ inner_mmio_xbar ─▶ L2 的 MMIO 桥 / 外部
//   中断（clint / plic / debug / nmi）直通；inner_beu（BusErrorUnit）收各级 ECC 错误、发中断
//   复位向量 ─▶ inner_resetDelayN（DelayN）；clintTime ─▶ inner_clintTime（DelayNWithValid）
//
// 本层手写的只有核 ↔ Tile 之间的打拍（xs_L2Top_core）：
//   §1 MSI 信息 / CPU halt / critical error / L3 miss：各打一拍（critical error 复位为 0，其余不复位）。
//   §2 trace 接口（核 → 编码器）：
//      valid 打一拍（复位 0）；iretire / itype / mstatus 打一拍；iaddr / ilastsize 只在该组 valid 时锁存；
//      priv 在第 0 组 valid 时锁存；trap（cause / tval）在第 0 组 valid 且 itype 是异常(1) / 中断(2) 时锁存。
//      编码器 → 核的 enable / stall 打一拍。
//   §3 hartIsInReset：复位为 1，之后跟随 resetInFrontend 打一拍。
//   §4 BEU 的 L2 ECC 错误地址：L2 给 46 位物理地址，BEU 收 48 位（高位补 0）。
//   其余核 ↔ Tile 信号（hartId、msiAck、中断）在 wrapper 里直通。
//
// 本文件导航：xs_L2Top_core（手写 §1–§4）→ L2Top（golden 同名端口表 + 21 个 child，实例名同 golden；
//   scripts/gen_l2top.py 从 golden 机械生成，规则见 scripts/parent_wrapper_lib.py）
// =============================================================================

module xs_L2Top_core #(
  parameter int unsigned TRACE_GROUPS = 3
) (
  input  logic        clock,
  input  logic        reset,

  // §1 核 ↔ Tile 打一拍
  input  logic        msiFromTile_valid,
  input  logic [11:0] msiFromTile_bits,
  output logic        msiToCore_valid,
  output logic [11:0] msiToCore_bits,
  input  logic        cpuHaltFromCore,
  output logic        cpuHaltToTile,
  input  logic        criticalErrorFromCore,
  output logic        criticalErrorToTile,
  input  logic        l3MissFromTile,
  output logic        l3MissToCore,

  // §2 trace：核 → 编码器
  input  logic [2:0]  traceIn_priv,
  input  logic [63:0] traceIn_mstatus,
  input  logic [63:0] traceIn_trapCause,
  input  logic [49:0] traceIn_trapTval,
  input  logic [TRACE_GROUPS-1:0] traceIn_valid,
  input  logic [49:0] traceIn_iaddr [TRACE_GROUPS],
  input  logic [3:0]  traceIn_itype [TRACE_GROUPS],
  input  logic [6:0]  traceIn_iretire [TRACE_GROUPS],
  input  logic [TRACE_GROUPS-1:0] traceIn_ilastsize,
  output logic [2:0]  traceOut_priv,
  output logic [63:0] traceOut_mstatus,
  output logic [63:0] traceOut_trapCause,
  output logic [49:0] traceOut_trapTval,
  output logic [TRACE_GROUPS-1:0] traceOut_valid,
  output logic [49:0] traceOut_iaddr [TRACE_GROUPS],
  output logic [3:0]  traceOut_itype [TRACE_GROUPS],
  output logic [6:0]  traceOut_iretire [TRACE_GROUPS],
  output logic [TRACE_GROUPS-1:0] traceOut_ilastsize,
  //    编码器 → 核
  input  logic        encoderIn_enable,
  input  logic        encoderIn_stall,
  output logic        encoderOut_enable,
  output logic        encoderOut_stall,

  // §3 hartIsInReset
  input  logic        resetInFrontend,
  output logic        hartIsInReset,

  // §4 BEU 的 L2 ECC 错误地址
  input  logic [45:0] l2ErrorAddr,
  output logic [47:0] beuL2ErrorAddr
);

  localparam logic [3:0] ITYPE_EXCEPTION = 4'd1;
  localparam logic [3:0] ITYPE_INTERRUPT = 4'd2;

  // ===========================================================================
  // §1 核 ↔ Tile 打一拍
  // ===========================================================================
  always_ff @(posedge clock) begin
    msiToCore_valid <= msiFromTile_valid;
    if (msiFromTile_valid) msiToCore_bits <= msiFromTile_bits;
    cpuHaltToTile   <= cpuHaltFromCore;
    l3MissToCore    <= l3MissFromTile;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) criticalErrorToTile <= 1'b0;
    else       criticalErrorToTile <= criticalErrorFromCore;
  end

  // ===========================================================================
  // §2 trace 接口
  // ===========================================================================
  logic trapCapture;   // 第 0 组是一条 trap（异常 / 中断）

  assign trapCapture = traceIn_valid[0]
                       & (traceIn_itype[0] == ITYPE_EXCEPTION | traceIn_itype[0] == ITYPE_INTERRUPT);

  always_ff @(posedge clock) begin
    encoderOut_enable <= encoderIn_enable;
    encoderOut_stall  <= encoderIn_stall;
    if (trapCapture) begin
      traceOut_trapCause <= traceIn_trapCause;
      traceOut_trapTval  <= traceIn_trapTval;
    end
    if (traceIn_valid[0]) traceOut_priv <= traceIn_priv;
    traceOut_mstatus <= traceIn_mstatus;
    for (int i = 0; i < TRACE_GROUPS; i++) begin
      traceOut_iretire[i] <= traceIn_iretire[i];
      traceOut_itype[i]   <= traceIn_itype[i];
      if (traceIn_valid[i]) begin
        traceOut_ilastsize[i] <= traceIn_ilastsize[i];
        traceOut_iaddr[i]     <= traceIn_iaddr[i];
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) traceOut_valid <= '0;
    else       traceOut_valid <= traceIn_valid;
  end

  // ===========================================================================
  // §3 hartIsInReset：复位为 1
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) hartIsInReset <= 1'b1;
    else       hartIsInReset <= resetInFrontend;
  end

  // ===========================================================================
  // §4 BEU 的 L2 ECC 错误地址
  // ===========================================================================
  assign beuL2ErrorAddr = {2'b00, l2ErrorAddr};

endmodule

// BEGIN GENERATED(l2top-wrapper)
module L2Top (
  input           clock,
  input           reset,
  input           auto_inner_buffers_out_a_ready,
  output          auto_inner_buffers_out_a_valid,
  output [3:0]    auto_inner_buffers_out_a_bits_opcode,
  output [2:0]    auto_inner_buffers_out_a_bits_param,
  output [1:0]    auto_inner_buffers_out_a_bits_size,
  output [4:0]    auto_inner_buffers_out_a_bits_source,
  output [29:0]   auto_inner_buffers_out_a_bits_address,
  output [7:0]    auto_inner_buffers_out_a_bits_mask,
  output [63:0]   auto_inner_buffers_out_a_bits_data,
  output          auto_inner_buffers_out_a_bits_corrupt,
  output          auto_inner_buffers_out_d_ready,
  input           auto_inner_buffers_out_d_valid,
  input  [3:0]    auto_inner_buffers_out_d_bits_opcode,
  input  [1:0]    auto_inner_buffers_out_d_bits_param,
  input  [1:0]    auto_inner_buffers_out_d_bits_size,
  input  [4:0]    auto_inner_buffers_out_d_bits_source,
  input           auto_inner_buffers_out_d_bits_sink,
  input           auto_inner_buffers_out_d_bits_denied,
  input  [63:0]   auto_inner_buffers_out_d_bits_data,
  input           auto_inner_buffers_out_d_bits_corrupt,
  output          auto_inner_buffers_in_a_ready,
  input           auto_inner_buffers_in_a_valid,
  input  [3:0]    auto_inner_buffers_in_a_bits_opcode,
  input  [2:0]    auto_inner_buffers_in_a_bits_param,
  input  [1:0]    auto_inner_buffers_in_a_bits_size,
  input  [3:0]    auto_inner_buffers_in_a_bits_source,
  input  [47:0]   auto_inner_buffers_in_a_bits_address,
  input           auto_inner_buffers_in_a_bits_user_memBackType_MM,
  input           auto_inner_buffers_in_a_bits_user_memPageType_NC,
  input  [7:0]    auto_inner_buffers_in_a_bits_mask,
  input  [63:0]   auto_inner_buffers_in_a_bits_data,
  input           auto_inner_buffers_in_a_bits_corrupt,
  input           auto_inner_buffers_in_d_ready,
  output          auto_inner_buffers_in_d_valid,
  output [3:0]    auto_inner_buffers_in_d_bits_opcode,
  output [1:0]    auto_inner_buffers_in_d_bits_param,
  output [1:0]    auto_inner_buffers_in_d_bits_size,
  output [3:0]    auto_inner_buffers_in_d_bits_source,
  output          auto_inner_buffers_in_d_bits_sink,
  output          auto_inner_buffers_in_d_bits_denied,
  output [63:0]   auto_inner_buffers_in_d_bits_data,
  output          auto_inner_buffers_in_d_bits_corrupt,
  input  [63:0]   auto_inner_l2cache_pf_recv_in_addr,
  input  [4:0]    auto_inner_l2cache_pf_recv_in_pf_source,
  input           auto_inner_l2cache_pf_recv_in_addr_valid,
  output          auto_inner_intBuffer_out_0,
  output          auto_inner_i_mmio_buffer_in_a_ready,
  input           auto_inner_i_mmio_buffer_in_a_valid,
  input  [2:0]    auto_inner_i_mmio_buffer_in_a_bits_param,
  input  [47:0]   auto_inner_i_mmio_buffer_in_a_bits_address,
  input           auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC,
  input           auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM,
  input           auto_inner_i_mmio_buffer_in_a_bits_corrupt,
  input           auto_inner_i_mmio_buffer_in_d_ready,
  output          auto_inner_i_mmio_buffer_in_d_valid,
  output [3:0]    auto_inner_i_mmio_buffer_in_d_bits_opcode,
  output [1:0]    auto_inner_i_mmio_buffer_in_d_bits_param,
  output [1:0]    auto_inner_i_mmio_buffer_in_d_bits_size,
  output          auto_inner_i_mmio_buffer_in_d_bits_source,
  output          auto_inner_i_mmio_buffer_in_d_bits_sink,
  output          auto_inner_i_mmio_buffer_in_d_bits_denied,
  output [63:0]   auto_inner_i_mmio_buffer_in_d_bits_data,
  output          auto_inner_i_mmio_buffer_in_d_bits_corrupt,
  output          auto_inner_ptw_to_l2_buffer_in_a_ready,
  input           auto_inner_ptw_to_l2_buffer_in_a_valid,
  input  [3:0]    auto_inner_ptw_to_l2_buffer_in_a_bits_opcode,
  input  [2:0]    auto_inner_ptw_to_l2_buffer_in_a_bits_param,
  input  [2:0]    auto_inner_ptw_to_l2_buffer_in_a_bits_size,
  input  [3:0]    auto_inner_ptw_to_l2_buffer_in_a_bits_source,
  input  [47:0]   auto_inner_ptw_to_l2_buffer_in_a_bits_address,
  input  [4:0]    auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource,
  input  [31:0]   auto_inner_ptw_to_l2_buffer_in_a_bits_mask,
  input  [255:0]  auto_inner_ptw_to_l2_buffer_in_a_bits_data,
  input           auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt,
  input           auto_inner_ptw_to_l2_buffer_in_d_ready,
  output          auto_inner_ptw_to_l2_buffer_in_d_valid,
  output [3:0]    auto_inner_ptw_to_l2_buffer_in_d_bits_opcode,
  output [1:0]    auto_inner_ptw_to_l2_buffer_in_d_bits_param,
  output [2:0]    auto_inner_ptw_to_l2_buffer_in_d_bits_size,
  output [3:0]    auto_inner_ptw_to_l2_buffer_in_d_bits_source,
  output [9:0]    auto_inner_ptw_to_l2_buffer_in_d_bits_sink,
  output          auto_inner_ptw_to_l2_buffer_in_d_bits_denied,
  output [255:0]  auto_inner_ptw_to_l2_buffer_in_d_bits_data,
  output          auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt,
  output          auto_inner_logger_in_1_a_ready,
  input           auto_inner_logger_in_1_a_valid,
  input  [3:0]    auto_inner_logger_in_1_a_bits_opcode,
  input  [2:0]    auto_inner_logger_in_1_a_bits_param,
  input  [2:0]    auto_inner_logger_in_1_a_bits_size,
  input  [3:0]    auto_inner_logger_in_1_a_bits_source,
  input  [47:0]   auto_inner_logger_in_1_a_bits_address,
  input  [1:0]    auto_inner_logger_in_1_a_bits_user_alias,
  input  [4:0]    auto_inner_logger_in_1_a_bits_user_reqSource,
  input           auto_inner_logger_in_1_a_bits_user_needHint,
  input  [31:0]   auto_inner_logger_in_1_a_bits_mask,
  input  [255:0]  auto_inner_logger_in_1_a_bits_data,
  input           auto_inner_logger_in_1_a_bits_corrupt,
  input           auto_inner_logger_in_1_d_ready,
  output          auto_inner_logger_in_1_d_valid,
  output [3:0]    auto_inner_logger_in_1_d_bits_opcode,
  output [1:0]    auto_inner_logger_in_1_d_bits_param,
  output [2:0]    auto_inner_logger_in_1_d_bits_size,
  output [3:0]    auto_inner_logger_in_1_d_bits_source,
  output [9:0]    auto_inner_logger_in_1_d_bits_sink,
  output          auto_inner_logger_in_1_d_bits_denied,
  output [255:0]  auto_inner_logger_in_1_d_bits_data,
  output          auto_inner_logger_in_1_d_bits_corrupt,
  output          auto_inner_logger_in_0_a_ready,
  input           auto_inner_logger_in_0_a_valid,
  input  [3:0]    auto_inner_logger_in_0_a_bits_opcode,
  input  [2:0]    auto_inner_logger_in_0_a_bits_param,
  input  [2:0]    auto_inner_logger_in_0_a_bits_size,
  input  [5:0]    auto_inner_logger_in_0_a_bits_source,
  input  [47:0]   auto_inner_logger_in_0_a_bits_address,
  input  [1:0]    auto_inner_logger_in_0_a_bits_user_alias,
  input  [43:0]   auto_inner_logger_in_0_a_bits_user_vaddr,
  input  [4:0]    auto_inner_logger_in_0_a_bits_user_reqSource,
  input           auto_inner_logger_in_0_a_bits_user_needHint,
  input           auto_inner_logger_in_0_a_bits_echo_isKeyword,
  input  [31:0]   auto_inner_logger_in_0_a_bits_mask,
  input  [255:0]  auto_inner_logger_in_0_a_bits_data,
  input           auto_inner_logger_in_0_a_bits_corrupt,
  input           auto_inner_logger_in_0_b_ready,
  output          auto_inner_logger_in_0_b_valid,
  output [2:0]    auto_inner_logger_in_0_b_bits_opcode,
  output [1:0]    auto_inner_logger_in_0_b_bits_param,
  output [2:0]    auto_inner_logger_in_0_b_bits_size,
  output [5:0]    auto_inner_logger_in_0_b_bits_source,
  output [47:0]   auto_inner_logger_in_0_b_bits_address,
  output [31:0]   auto_inner_logger_in_0_b_bits_mask,
  output [255:0]  auto_inner_logger_in_0_b_bits_data,
  output          auto_inner_logger_in_0_b_bits_corrupt,
  output          auto_inner_logger_in_0_c_ready,
  input           auto_inner_logger_in_0_c_valid,
  input  [2:0]    auto_inner_logger_in_0_c_bits_opcode,
  input  [2:0]    auto_inner_logger_in_0_c_bits_param,
  input  [2:0]    auto_inner_logger_in_0_c_bits_size,
  input  [5:0]    auto_inner_logger_in_0_c_bits_source,
  input  [47:0]   auto_inner_logger_in_0_c_bits_address,
  input  [1:0]    auto_inner_logger_in_0_c_bits_user_alias,
  input  [43:0]   auto_inner_logger_in_0_c_bits_user_vaddr,
  input  [4:0]    auto_inner_logger_in_0_c_bits_user_reqSource,
  input           auto_inner_logger_in_0_c_bits_user_needHint,
  input           auto_inner_logger_in_0_c_bits_echo_isKeyword,
  input  [255:0]  auto_inner_logger_in_0_c_bits_data,
  input           auto_inner_logger_in_0_c_bits_corrupt,
  input           auto_inner_logger_in_0_d_ready,
  output          auto_inner_logger_in_0_d_valid,
  output [3:0]    auto_inner_logger_in_0_d_bits_opcode,
  output [1:0]    auto_inner_logger_in_0_d_bits_param,
  output [2:0]    auto_inner_logger_in_0_d_bits_size,
  output [5:0]    auto_inner_logger_in_0_d_bits_source,
  output [9:0]    auto_inner_logger_in_0_d_bits_sink,
  output          auto_inner_logger_in_0_d_bits_denied,
  output          auto_inner_logger_in_0_d_bits_echo_isKeyword,
  output [255:0]  auto_inner_logger_in_0_d_bits_data,
  output          auto_inner_logger_in_0_d_bits_corrupt,
  output          auto_inner_logger_in_0_e_ready,
  input           auto_inner_logger_in_0_e_valid,
  input  [9:0]    auto_inner_logger_in_0_e_bits_sink,
  output          auto_inner_beu_int_out_0,
  input           auto_inner_nmi_int_in_0,
  input           auto_inner_nmi_int_in_1,
  output          auto_inner_nmi_int_out_0,
  output          auto_inner_nmi_int_out_1,
  input           auto_inner_plic_int_in_1_0,
  input           auto_inner_plic_int_in_0_0,
  output          auto_inner_plic_int_out_1_0,
  output          auto_inner_plic_int_out_0_0,
  input           auto_inner_debug_int_in_0,
  output          auto_inner_debug_int_out_0,
  input           auto_inner_clint_int_in_0,
  input           auto_inner_clint_int_in_1,
  output          auto_inner_clint_int_out_0,
  output          auto_inner_clint_int_out_1,
  input           io_beu_errors_icache_ecc_error_valid,
  input  [47:0]   io_beu_errors_icache_ecc_error_bits,
  input           io_beu_errors_dcache_ecc_error_valid,
  input  [47:0]   io_beu_errors_dcache_ecc_error_bits,
  input           io_beu_errors_uncache_ecc_error_valid,
  input  [47:0]   io_beu_errors_uncache_ecc_error_bits,
  input  [47:0]   io_reset_vector_fromTile,
  output [47:0]   io_reset_vector_toCore,
  input  [63:0]   io_hartId_fromTile,
  output [63:0]   io_hartId_toCore,
  input           io_msiInfo_fromTile_valid,
  input  [11:0]   io_msiInfo_fromTile_bits,
  output          io_msiInfo_toCore_valid,
  output [11:0]   io_msiInfo_toCore_bits,
  input           io_msiAck_fromCore,
  output          io_msiAck_toTile,
  input           io_cpu_halt_fromCore,
  output          io_cpu_halt_toTile,
  input           io_cpu_critical_error_fromCore,
  output          io_cpu_critical_error_toTile,
  input           io_hartIsInReset_resetInFrontend,
  output          io_hartIsInReset_toTile,
  output          io_traceCoreInterface_fromCore_fromEncoder_enable,
  output          io_traceCoreInterface_fromCore_fromEncoder_stall,
  input  [2:0]    io_traceCoreInterface_fromCore_toEncoder_priv,
  input  [63:0]   io_traceCoreInterface_fromCore_toEncoder_mstatus,
  input  [63:0]   io_traceCoreInterface_fromCore_toEncoder_trap_cause,
  input  [49:0]   io_traceCoreInterface_fromCore_toEncoder_trap_tval,
  input           io_traceCoreInterface_fromCore_toEncoder_groups_0_valid,
  input  [49:0]   io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr,
  input  [3:0]    io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype,
  input  [6:0]    io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire,
  input           io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize,
  input           io_traceCoreInterface_fromCore_toEncoder_groups_1_valid,
  input  [49:0]   io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr,
  input  [3:0]    io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype,
  input  [6:0]    io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire,
  input           io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize,
  input           io_traceCoreInterface_fromCore_toEncoder_groups_2_valid,
  input  [49:0]   io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr,
  input  [3:0]    io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype,
  input  [6:0]    io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire,
  input           io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize,
  input           io_traceCoreInterface_toTile_fromEncoder_enable,
  input           io_traceCoreInterface_toTile_fromEncoder_stall,
  output [2:0]    io_traceCoreInterface_toTile_toEncoder_priv,
  output [63:0]   io_traceCoreInterface_toTile_toEncoder_mstatus,
  output [63:0]   io_traceCoreInterface_toTile_toEncoder_trap_cause,
  output [49:0]   io_traceCoreInterface_toTile_toEncoder_trap_tval,
  output          io_traceCoreInterface_toTile_toEncoder_groups_0_valid,
  output [49:0]   io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr,
  output [3:0]    io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype,
  output [6:0]    io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire,
  output          io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize,
  output          io_traceCoreInterface_toTile_toEncoder_groups_1_valid,
  output [49:0]   io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr,
  output [3:0]    io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype,
  output [6:0]    io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire,
  output          io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize,
  output          io_traceCoreInterface_toTile_toEncoder_groups_2_valid,
  output [49:0]   io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr,
  output [3:0]    io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype,
  output [6:0]    io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire,
  output          io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize,
  input           io_debugTopDown_robHeadPaddr_valid,
  input  [35:0]   io_debugTopDown_robHeadPaddr_bits,
  output          io_debugTopDown_l2MissMatch,
  output          io_l2Miss,
  input           io_l3Miss_fromTile,
  output          io_l3Miss_toCore,
  input           io_clintTime_fromTile_valid,
  input  [63:0]   io_clintTime_fromTile_bits,
  output          io_clintTime_toCore_valid,
  output [63:0]   io_clintTime_toCore_bits,
  output          io_chi_txsactive,
  input           io_chi_rxsactive,
  output          io_chi_syscoreq,
  input           io_chi_syscoack,
  output          io_chi_tx_linkactivereq,
  input           io_chi_tx_linkactiveack,
  output          io_chi_tx_req_flitpend,
  output          io_chi_tx_req_flitv,
  output [161:0]  io_chi_tx_req_flit,
  input           io_chi_tx_req_lcrdv,
  output          io_chi_tx_rsp_flitpend,
  output          io_chi_tx_rsp_flitv,
  output [72:0]   io_chi_tx_rsp_flit,
  input           io_chi_tx_rsp_lcrdv,
  output          io_chi_tx_dat_flitpend,
  output          io_chi_tx_dat_flitv,
  output [421:0]  io_chi_tx_dat_flit,
  input           io_chi_tx_dat_lcrdv,
  input           io_chi_rx_linkactivereq,
  output          io_chi_rx_linkactiveack,
  input           io_chi_rx_rsp_flitpend,
  input           io_chi_rx_rsp_flitv,
  input  [72:0]   io_chi_rx_rsp_flit,
  output          io_chi_rx_rsp_lcrdv,
  input           io_chi_rx_dat_flitpend,
  input           io_chi_rx_dat_flitv,
  input  [421:0]  io_chi_rx_dat_flit,
  output          io_chi_rx_dat_lcrdv,
  input           io_chi_rx_snp_flitpend,
  input           io_chi_rx_snp_flitv,
  input  [114:0]  io_chi_rx_snp_flit,
  output          io_chi_rx_snp_lcrdv,
  input  [10:0]   io_nodeID,
  input           io_pfCtrlFromCore_l2_pf_master_en,
  input           io_pfCtrlFromCore_l2_pf_recv_en,
  input           io_pfCtrlFromCore_l2_pbop_en,
  input           io_pfCtrlFromCore_l2_vbop_en,
  input  [9:0]    io_pfCtrlFromCore_l2_pf_delay_latency,
  output          io_l2_tlb_req_req_valid,
  output [49:0]   io_l2_tlb_req_req_bits_vaddr,
  output [2:0]    io_l2_tlb_req_req_bits_cmd,
  output          io_l2_tlb_req_req_bits_kill,
  output          io_l2_tlb_req_req_bits_isPrefetch,
  output          io_l2_tlb_req_req_bits_no_translate,
  input           io_l2_tlb_req_resp_valid,
  input  [47:0]   io_l2_tlb_req_resp_bits_paddr_0,
  input  [1:0]    io_l2_tlb_req_resp_bits_pbmt_0,
  input           io_l2_tlb_req_resp_bits_miss,
  input           io_l2_tlb_req_resp_bits_excp_0_gpf_ld,
  input           io_l2_tlb_req_resp_bits_excp_0_pf_ld,
  input           io_l2_tlb_req_resp_bits_excp_0_af_ld,
  input           io_l2_pmp_resp_ld,
  input           io_l2_pmp_resp_mmio,
  output          io_l2_hint_valid,
  output [3:0]    io_l2_hint_bits_sourceId,
  output          io_l2_hint_bits_isKeyword,
  output [5:0]    io_perfEvents_1_value,
  output [5:0]    io_perfEvents_2_value,
  output [5:0]    io_perfEvents_3_value,
  output [5:0]    io_perfEvents_4_value,
  output [5:0]    io_perfEvents_5_value,
  output [5:0]    io_perfEvents_6_value,
  output [5:0]    io_perfEvents_7_value,
  output [5:0]    io_perfEvents_8_value,
  output [5:0]    io_perfEvents_9_value,
  output [5:0]    io_perfEvents_10_value,
  output [5:0]    io_perfEvents_11_value,
  output [5:0]    io_perfEvents_12_value,
  output [5:0]    io_perfEvents_13_value,
  output [5:0]    io_perfEvents_14_value,
  output [5:0]    io_perfEvents_15_value,
  output [5:0]    io_perfEvents_16_value,
  output [5:0]    io_perfEvents_17_value,
  output [5:0]    io_perfEvents_18_value,
  output [5:0]    io_perfEvents_19_value,
  output [5:0]    io_perfEvents_20_value,
  output [5:0]    io_perfEvents_21_value,
  output [5:0]    io_perfEvents_22_value,
  output [5:0]    io_perfEvents_23_value,
  output [5:0]    io_perfEvents_24_value,
  output [5:0]    io_perfEvents_25_value,
  output [5:0]    io_perfEvents_26_value,
  output [5:0]    io_perfEvents_27_value,
  output [5:0]    io_perfEvents_28_value,
  output [5:0]    io_perfEvents_29_value,
  output [5:0]    io_perfEvents_30_value,
  output [5:0]    io_perfEvents_31_value,
  output [5:0]    io_perfEvents_32_value,
  output [5:0]    io_perfEvents_33_value,
  output [5:0]    io_perfEvents_34_value,
  output [5:0]    io_perfEvents_35_value,
  output [5:0]    io_perfEvents_36_value,
  output [5:0]    io_perfEvents_37_value,
  output [5:0]    io_perfEvents_38_value,
  output [5:0]    io_perfEvents_39_value,
  output [5:0]    io_perfEvents_40_value,
  output [5:0]    io_perfEvents_41_value,
  output [5:0]    io_perfEvents_42_value,
  output [5:0]    io_perfEvents_43_value,
  output [5:0]    io_perfEvents_44_value,
  output [5:0]    io_perfEvents_45_value,
  output [5:0]    io_perfEvents_46_value,
  output [5:0]    io_perfEvents_47_value,
  output [5:0]    io_perfEvents_48_value,
  output [5:0]    io_perfEvents_49_value,
  output [5:0]    io_perfEvents_50_value,
  output [5:0]    io_perfEvents_51_value,
  output [5:0]    io_perfEvents_52_value,
  output [5:0]    io_perfEvents_53_value,
  output [5:0]    io_perfEvents_54_value,
  output [5:0]    io_perfEvents_55_value,
  output [5:0]    io_perfEvents_56_value,
  output [5:0]    io_perfEvents_57_value,
  output [5:0]    io_perfEvents_58_value,
  output [5:0]    io_perfEvents_59_value,
  output [5:0]    io_perfEvents_60_value,
  output [5:0]    io_perfEvents_61_value,
  output [5:0]    io_perfEvents_62_value,
  output [5:0]    io_perfEvents_63_value,
  output [5:0]    io_perfEvents_64_value,
  output [5:0]    io_perfEvents_65_value,
  output [5:0]    io_perfEvents_66_value,
  output [5:0]    io_perfEvents_67_value,
  output [5:0]    io_perfEvents_68_value,
  input           io_dft_ram_hold,
  input           io_dft_ram_bypass,
  input           io_dft_ram_bp_clken,
  input           io_dft_ram_aux_clk,
  input           io_dft_ram_aux_ckbp,
  input           io_dft_ram_mcp_hold,
  input           io_dft_cgen
);

  // ---- child 输出线（<实例名>_<端口名>）----
  logic inner_beu_auto_in_a_ready;
  logic [63:0] inner_beu_auto_in_d_bits_data;
  logic [3:0] inner_beu_auto_in_d_bits_opcode;
  logic [1:0] inner_beu_auto_in_d_bits_size;
  logic [4:0] inner_beu_auto_in_d_bits_source;
  logic inner_beu_auto_in_d_valid;
  logic inner_beu_io_interrupt;
  logic inner_buffer_1_auto_in_a_ready;
  logic inner_buffer_1_auto_in_d_bits_corrupt;
  logic [63:0] inner_buffer_1_auto_in_d_bits_data;
  logic inner_buffer_1_auto_in_d_bits_denied;
  logic [3:0] inner_buffer_1_auto_in_d_bits_opcode;
  logic [1:0] inner_buffer_1_auto_in_d_bits_param;
  logic inner_buffer_1_auto_in_d_bits_sink;
  logic [1:0] inner_buffer_1_auto_in_d_bits_size;
  logic [4:0] inner_buffer_1_auto_in_d_bits_source;
  logic inner_buffer_1_auto_in_d_valid;
  logic [47:0] inner_buffer_1_auto_out_a_bits_address;
  logic inner_buffer_1_auto_out_a_bits_corrupt;
  logic [63:0] inner_buffer_1_auto_out_a_bits_data;
  logic [7:0] inner_buffer_1_auto_out_a_bits_mask;
  logic [3:0] inner_buffer_1_auto_out_a_bits_opcode;
  logic [2:0] inner_buffer_1_auto_out_a_bits_param;
  logic [1:0] inner_buffer_1_auto_out_a_bits_size;
  logic [4:0] inner_buffer_1_auto_out_a_bits_source;
  logic inner_buffer_1_auto_out_a_bits_user_memBackType_MM;
  logic inner_buffer_1_auto_out_a_bits_user_memPageType_NC;
  logic inner_buffer_1_auto_out_a_valid;
  logic inner_buffer_1_auto_out_d_ready;
  logic inner_buffer_auto_in_0_a_ready;
  logic [47:0] inner_buffer_auto_in_0_b_bits_address;
  logic inner_buffer_auto_in_0_b_bits_corrupt;
  logic [255:0] inner_buffer_auto_in_0_b_bits_data;
  logic [31:0] inner_buffer_auto_in_0_b_bits_mask;
  logic [2:0] inner_buffer_auto_in_0_b_bits_opcode;
  logic [1:0] inner_buffer_auto_in_0_b_bits_param;
  logic [2:0] inner_buffer_auto_in_0_b_bits_size;
  logic [6:0] inner_buffer_auto_in_0_b_bits_source;
  logic inner_buffer_auto_in_0_b_valid;
  logic inner_buffer_auto_in_0_c_ready;
  logic inner_buffer_auto_in_0_d_bits_corrupt;
  logic [255:0] inner_buffer_auto_in_0_d_bits_data;
  logic inner_buffer_auto_in_0_d_bits_denied;
  logic inner_buffer_auto_in_0_d_bits_echo_isKeyword;
  logic [3:0] inner_buffer_auto_in_0_d_bits_opcode;
  logic [1:0] inner_buffer_auto_in_0_d_bits_param;
  logic [7:0] inner_buffer_auto_in_0_d_bits_sink;
  logic [2:0] inner_buffer_auto_in_0_d_bits_size;
  logic [6:0] inner_buffer_auto_in_0_d_bits_source;
  logic inner_buffer_auto_in_0_d_valid;
  logic inner_buffer_auto_in_0_e_ready;
  logic inner_buffer_auto_in_1_a_ready;
  logic [47:0] inner_buffer_auto_in_1_b_bits_address;
  logic inner_buffer_auto_in_1_b_bits_corrupt;
  logic [255:0] inner_buffer_auto_in_1_b_bits_data;
  logic [31:0] inner_buffer_auto_in_1_b_bits_mask;
  logic [2:0] inner_buffer_auto_in_1_b_bits_opcode;
  logic [1:0] inner_buffer_auto_in_1_b_bits_param;
  logic [2:0] inner_buffer_auto_in_1_b_bits_size;
  logic [6:0] inner_buffer_auto_in_1_b_bits_source;
  logic inner_buffer_auto_in_1_b_valid;
  logic inner_buffer_auto_in_1_c_ready;
  logic inner_buffer_auto_in_1_d_bits_corrupt;
  logic [255:0] inner_buffer_auto_in_1_d_bits_data;
  logic inner_buffer_auto_in_1_d_bits_denied;
  logic inner_buffer_auto_in_1_d_bits_echo_isKeyword;
  logic [3:0] inner_buffer_auto_in_1_d_bits_opcode;
  logic [1:0] inner_buffer_auto_in_1_d_bits_param;
  logic [7:0] inner_buffer_auto_in_1_d_bits_sink;
  logic [2:0] inner_buffer_auto_in_1_d_bits_size;
  logic [6:0] inner_buffer_auto_in_1_d_bits_source;
  logic inner_buffer_auto_in_1_d_valid;
  logic inner_buffer_auto_in_1_e_ready;
  logic inner_buffer_auto_in_2_a_ready;
  logic [47:0] inner_buffer_auto_in_2_b_bits_address;
  logic inner_buffer_auto_in_2_b_bits_corrupt;
  logic [255:0] inner_buffer_auto_in_2_b_bits_data;
  logic [31:0] inner_buffer_auto_in_2_b_bits_mask;
  logic [2:0] inner_buffer_auto_in_2_b_bits_opcode;
  logic [1:0] inner_buffer_auto_in_2_b_bits_param;
  logic [2:0] inner_buffer_auto_in_2_b_bits_size;
  logic [6:0] inner_buffer_auto_in_2_b_bits_source;
  logic inner_buffer_auto_in_2_b_valid;
  logic inner_buffer_auto_in_2_c_ready;
  logic inner_buffer_auto_in_2_d_bits_corrupt;
  logic [255:0] inner_buffer_auto_in_2_d_bits_data;
  logic inner_buffer_auto_in_2_d_bits_denied;
  logic inner_buffer_auto_in_2_d_bits_echo_isKeyword;
  logic [3:0] inner_buffer_auto_in_2_d_bits_opcode;
  logic [1:0] inner_buffer_auto_in_2_d_bits_param;
  logic [7:0] inner_buffer_auto_in_2_d_bits_sink;
  logic [2:0] inner_buffer_auto_in_2_d_bits_size;
  logic [6:0] inner_buffer_auto_in_2_d_bits_source;
  logic inner_buffer_auto_in_2_d_valid;
  logic inner_buffer_auto_in_2_e_ready;
  logic inner_buffer_auto_in_3_a_ready;
  logic [47:0] inner_buffer_auto_in_3_b_bits_address;
  logic inner_buffer_auto_in_3_b_bits_corrupt;
  logic [255:0] inner_buffer_auto_in_3_b_bits_data;
  logic [31:0] inner_buffer_auto_in_3_b_bits_mask;
  logic [2:0] inner_buffer_auto_in_3_b_bits_opcode;
  logic [1:0] inner_buffer_auto_in_3_b_bits_param;
  logic [2:0] inner_buffer_auto_in_3_b_bits_size;
  logic [6:0] inner_buffer_auto_in_3_b_bits_source;
  logic inner_buffer_auto_in_3_b_valid;
  logic inner_buffer_auto_in_3_c_ready;
  logic inner_buffer_auto_in_3_d_bits_corrupt;
  logic [255:0] inner_buffer_auto_in_3_d_bits_data;
  logic inner_buffer_auto_in_3_d_bits_denied;
  logic inner_buffer_auto_in_3_d_bits_echo_isKeyword;
  logic [3:0] inner_buffer_auto_in_3_d_bits_opcode;
  logic [1:0] inner_buffer_auto_in_3_d_bits_param;
  logic [7:0] inner_buffer_auto_in_3_d_bits_sink;
  logic [2:0] inner_buffer_auto_in_3_d_bits_size;
  logic [6:0] inner_buffer_auto_in_3_d_bits_source;
  logic inner_buffer_auto_in_3_d_valid;
  logic inner_buffer_auto_in_3_e_ready;
  logic [47:0] inner_buffer_auto_out_0_a_bits_address;
  logic inner_buffer_auto_out_0_a_bits_corrupt;
  logic inner_buffer_auto_out_0_a_bits_echo_isKeyword;
  logic [3:0] inner_buffer_auto_out_0_a_bits_opcode;
  logic [2:0] inner_buffer_auto_out_0_a_bits_param;
  logic [2:0] inner_buffer_auto_out_0_a_bits_size;
  logic [6:0] inner_buffer_auto_out_0_a_bits_source;
  logic [1:0] inner_buffer_auto_out_0_a_bits_user_alias;
  logic inner_buffer_auto_out_0_a_bits_user_needHint;
  logic [4:0] inner_buffer_auto_out_0_a_bits_user_reqSource;
  logic [43:0] inner_buffer_auto_out_0_a_bits_user_vaddr;
  logic inner_buffer_auto_out_0_a_valid;
  logic inner_buffer_auto_out_0_b_ready;
  logic [47:0] inner_buffer_auto_out_0_c_bits_address;
  logic inner_buffer_auto_out_0_c_bits_corrupt;
  logic [255:0] inner_buffer_auto_out_0_c_bits_data;
  logic [2:0] inner_buffer_auto_out_0_c_bits_opcode;
  logic [2:0] inner_buffer_auto_out_0_c_bits_param;
  logic [2:0] inner_buffer_auto_out_0_c_bits_size;
  logic [6:0] inner_buffer_auto_out_0_c_bits_source;
  logic inner_buffer_auto_out_0_c_valid;
  logic inner_buffer_auto_out_0_d_ready;
  logic [7:0] inner_buffer_auto_out_0_e_bits_sink;
  logic inner_buffer_auto_out_0_e_valid;
  logic [47:0] inner_buffer_auto_out_1_a_bits_address;
  logic inner_buffer_auto_out_1_a_bits_corrupt;
  logic inner_buffer_auto_out_1_a_bits_echo_isKeyword;
  logic [3:0] inner_buffer_auto_out_1_a_bits_opcode;
  logic [2:0] inner_buffer_auto_out_1_a_bits_param;
  logic [2:0] inner_buffer_auto_out_1_a_bits_size;
  logic [6:0] inner_buffer_auto_out_1_a_bits_source;
  logic [1:0] inner_buffer_auto_out_1_a_bits_user_alias;
  logic inner_buffer_auto_out_1_a_bits_user_needHint;
  logic [4:0] inner_buffer_auto_out_1_a_bits_user_reqSource;
  logic [43:0] inner_buffer_auto_out_1_a_bits_user_vaddr;
  logic inner_buffer_auto_out_1_a_valid;
  logic inner_buffer_auto_out_1_b_ready;
  logic [47:0] inner_buffer_auto_out_1_c_bits_address;
  logic inner_buffer_auto_out_1_c_bits_corrupt;
  logic [255:0] inner_buffer_auto_out_1_c_bits_data;
  logic [2:0] inner_buffer_auto_out_1_c_bits_opcode;
  logic [2:0] inner_buffer_auto_out_1_c_bits_param;
  logic [2:0] inner_buffer_auto_out_1_c_bits_size;
  logic [6:0] inner_buffer_auto_out_1_c_bits_source;
  logic inner_buffer_auto_out_1_c_valid;
  logic inner_buffer_auto_out_1_d_ready;
  logic [7:0] inner_buffer_auto_out_1_e_bits_sink;
  logic inner_buffer_auto_out_1_e_valid;
  logic [47:0] inner_buffer_auto_out_2_a_bits_address;
  logic inner_buffer_auto_out_2_a_bits_corrupt;
  logic inner_buffer_auto_out_2_a_bits_echo_isKeyword;
  logic [3:0] inner_buffer_auto_out_2_a_bits_opcode;
  logic [2:0] inner_buffer_auto_out_2_a_bits_param;
  logic [2:0] inner_buffer_auto_out_2_a_bits_size;
  logic [6:0] inner_buffer_auto_out_2_a_bits_source;
  logic [1:0] inner_buffer_auto_out_2_a_bits_user_alias;
  logic inner_buffer_auto_out_2_a_bits_user_needHint;
  logic [4:0] inner_buffer_auto_out_2_a_bits_user_reqSource;
  logic [43:0] inner_buffer_auto_out_2_a_bits_user_vaddr;
  logic inner_buffer_auto_out_2_a_valid;
  logic inner_buffer_auto_out_2_b_ready;
  logic [47:0] inner_buffer_auto_out_2_c_bits_address;
  logic inner_buffer_auto_out_2_c_bits_corrupt;
  logic [255:0] inner_buffer_auto_out_2_c_bits_data;
  logic [2:0] inner_buffer_auto_out_2_c_bits_opcode;
  logic [2:0] inner_buffer_auto_out_2_c_bits_param;
  logic [2:0] inner_buffer_auto_out_2_c_bits_size;
  logic [6:0] inner_buffer_auto_out_2_c_bits_source;
  logic inner_buffer_auto_out_2_c_valid;
  logic inner_buffer_auto_out_2_d_ready;
  logic [7:0] inner_buffer_auto_out_2_e_bits_sink;
  logic inner_buffer_auto_out_2_e_valid;
  logic [47:0] inner_buffer_auto_out_3_a_bits_address;
  logic inner_buffer_auto_out_3_a_bits_corrupt;
  logic inner_buffer_auto_out_3_a_bits_echo_isKeyword;
  logic [3:0] inner_buffer_auto_out_3_a_bits_opcode;
  logic [2:0] inner_buffer_auto_out_3_a_bits_param;
  logic [2:0] inner_buffer_auto_out_3_a_bits_size;
  logic [6:0] inner_buffer_auto_out_3_a_bits_source;
  logic [1:0] inner_buffer_auto_out_3_a_bits_user_alias;
  logic inner_buffer_auto_out_3_a_bits_user_needHint;
  logic [4:0] inner_buffer_auto_out_3_a_bits_user_reqSource;
  logic [43:0] inner_buffer_auto_out_3_a_bits_user_vaddr;
  logic inner_buffer_auto_out_3_a_valid;
  logic inner_buffer_auto_out_3_b_ready;
  logic [47:0] inner_buffer_auto_out_3_c_bits_address;
  logic inner_buffer_auto_out_3_c_bits_corrupt;
  logic [255:0] inner_buffer_auto_out_3_c_bits_data;
  logic [2:0] inner_buffer_auto_out_3_c_bits_opcode;
  logic [2:0] inner_buffer_auto_out_3_c_bits_param;
  logic [2:0] inner_buffer_auto_out_3_c_bits_size;
  logic [6:0] inner_buffer_auto_out_3_c_bits_source;
  logic inner_buffer_auto_out_3_c_valid;
  logic inner_buffer_auto_out_3_d_ready;
  logic [7:0] inner_buffer_auto_out_3_e_bits_sink;
  logic inner_buffer_auto_out_3_e_valid;
  logic inner_buffers_1_auto_in_a_ready;
  logic inner_buffers_1_auto_in_d_bits_corrupt;
  logic [63:0] inner_buffers_1_auto_in_d_bits_data;
  logic inner_buffers_1_auto_in_d_bits_denied;
  logic [3:0] inner_buffers_1_auto_in_d_bits_opcode;
  logic [1:0] inner_buffers_1_auto_in_d_bits_param;
  logic inner_buffers_1_auto_in_d_bits_sink;
  logic [1:0] inner_buffers_1_auto_in_d_bits_size;
  logic inner_buffers_1_auto_in_d_bits_source;
  logic inner_buffers_1_auto_in_d_valid;
  logic [47:0] inner_buffers_1_auto_out_a_bits_address;
  logic inner_buffers_1_auto_out_a_bits_corrupt;
  logic [63:0] inner_buffers_1_auto_out_a_bits_data;
  logic [7:0] inner_buffers_1_auto_out_a_bits_mask;
  logic [3:0] inner_buffers_1_auto_out_a_bits_opcode;
  logic [2:0] inner_buffers_1_auto_out_a_bits_param;
  logic [1:0] inner_buffers_1_auto_out_a_bits_size;
  logic inner_buffers_1_auto_out_a_bits_source;
  logic inner_buffers_1_auto_out_a_bits_user_memBackType_MM;
  logic inner_buffers_1_auto_out_a_bits_user_memPageType_NC;
  logic inner_buffers_1_auto_out_a_valid;
  logic inner_buffers_1_auto_out_d_ready;
  logic inner_buffers_2_auto_in_a_ready;
  logic inner_buffers_2_auto_in_d_bits_corrupt;
  logic [63:0] inner_buffers_2_auto_in_d_bits_data;
  logic inner_buffers_2_auto_in_d_bits_denied;
  logic [3:0] inner_buffers_2_auto_in_d_bits_opcode;
  logic [1:0] inner_buffers_2_auto_in_d_bits_param;
  logic inner_buffers_2_auto_in_d_bits_sink;
  logic [1:0] inner_buffers_2_auto_in_d_bits_size;
  logic [3:0] inner_buffers_2_auto_in_d_bits_source;
  logic inner_buffers_2_auto_in_d_valid;
  logic [47:0] inner_buffers_2_auto_out_a_bits_address;
  logic inner_buffers_2_auto_out_a_bits_corrupt;
  logic [63:0] inner_buffers_2_auto_out_a_bits_data;
  logic [7:0] inner_buffers_2_auto_out_a_bits_mask;
  logic [3:0] inner_buffers_2_auto_out_a_bits_opcode;
  logic [2:0] inner_buffers_2_auto_out_a_bits_param;
  logic [1:0] inner_buffers_2_auto_out_a_bits_size;
  logic [3:0] inner_buffers_2_auto_out_a_bits_source;
  logic inner_buffers_2_auto_out_a_bits_user_memBackType_MM;
  logic inner_buffers_2_auto_out_a_bits_user_memPageType_NC;
  logic inner_buffers_2_auto_out_a_valid;
  logic inner_buffers_2_auto_out_d_ready;
  logic [47:0] inner_buffers_3_auto_out_a_bits_address;
  logic inner_buffers_3_auto_out_a_bits_corrupt;
  logic [63:0] inner_buffers_3_auto_out_a_bits_data;
  logic [7:0] inner_buffers_3_auto_out_a_bits_mask;
  logic [3:0] inner_buffers_3_auto_out_a_bits_opcode;
  logic [2:0] inner_buffers_3_auto_out_a_bits_param;
  logic [1:0] inner_buffers_3_auto_out_a_bits_size;
  logic [3:0] inner_buffers_3_auto_out_a_bits_source;
  logic inner_buffers_3_auto_out_a_bits_user_memBackType_MM;
  logic inner_buffers_3_auto_out_a_bits_user_memPageType_NC;
  logic inner_buffers_3_auto_out_a_valid;
  logic inner_buffers_3_auto_out_d_ready;
  logic inner_buffers_4_auto_in_a_ready;
  logic inner_buffers_4_auto_in_d_bits_corrupt;
  logic [63:0] inner_buffers_4_auto_in_d_bits_data;
  logic inner_buffers_4_auto_in_d_bits_denied;
  logic [3:0] inner_buffers_4_auto_in_d_bits_opcode;
  logic [1:0] inner_buffers_4_auto_in_d_bits_param;
  logic inner_buffers_4_auto_in_d_bits_sink;
  logic [1:0] inner_buffers_4_auto_in_d_bits_size;
  logic [4:0] inner_buffers_4_auto_in_d_bits_source;
  logic inner_buffers_4_auto_in_d_valid;
  logic [29:0] inner_buffers_4_auto_out_a_bits_address;
  logic [63:0] inner_buffers_4_auto_out_a_bits_data;
  logic [7:0] inner_buffers_4_auto_out_a_bits_mask;
  logic [3:0] inner_buffers_4_auto_out_a_bits_opcode;
  logic [1:0] inner_buffers_4_auto_out_a_bits_size;
  logic [4:0] inner_buffers_4_auto_out_a_bits_source;
  logic inner_buffers_4_auto_out_a_valid;
  logic inner_buffers_4_auto_out_d_ready;
  logic inner_buffers_5_auto_in_a_ready;
  logic inner_buffers_5_auto_in_d_bits_corrupt;
  logic [63:0] inner_buffers_5_auto_in_d_bits_data;
  logic inner_buffers_5_auto_in_d_bits_denied;
  logic [3:0] inner_buffers_5_auto_in_d_bits_opcode;
  logic [1:0] inner_buffers_5_auto_in_d_bits_param;
  logic inner_buffers_5_auto_in_d_bits_sink;
  logic [1:0] inner_buffers_5_auto_in_d_bits_size;
  logic [4:0] inner_buffers_5_auto_in_d_bits_source;
  logic inner_buffers_5_auto_in_d_valid;
  logic inner_buffers_auto_in_a_ready;
  logic inner_buffers_auto_in_d_bits_corrupt;
  logic [63:0] inner_buffers_auto_in_d_bits_data;
  logic inner_buffers_auto_in_d_bits_denied;
  logic [3:0] inner_buffers_auto_in_d_bits_opcode;
  logic [1:0] inner_buffers_auto_in_d_bits_param;
  logic inner_buffers_auto_in_d_bits_sink;
  logic [1:0] inner_buffers_auto_in_d_bits_size;
  logic inner_buffers_auto_in_d_bits_source;
  logic inner_buffers_auto_in_d_valid;
  logic [47:0] inner_buffers_auto_out_a_bits_address;
  logic inner_buffers_auto_out_a_bits_corrupt;
  logic [63:0] inner_buffers_auto_out_a_bits_data;
  logic [7:0] inner_buffers_auto_out_a_bits_mask;
  logic [3:0] inner_buffers_auto_out_a_bits_opcode;
  logic [2:0] inner_buffers_auto_out_a_bits_param;
  logic [1:0] inner_buffers_auto_out_a_bits_size;
  logic inner_buffers_auto_out_a_bits_source;
  logic inner_buffers_auto_out_a_bits_user_memBackType_MM;
  logic inner_buffers_auto_out_a_bits_user_memPageType_NC;
  logic inner_buffers_auto_out_a_valid;
  logic inner_buffers_auto_out_d_ready;
  logic inner_busPMU_auto_in_0_a_ready;
  logic [47:0] inner_busPMU_auto_in_0_b_bits_address;
  logic inner_busPMU_auto_in_0_b_bits_corrupt;
  logic [255:0] inner_busPMU_auto_in_0_b_bits_data;
  logic [31:0] inner_busPMU_auto_in_0_b_bits_mask;
  logic [2:0] inner_busPMU_auto_in_0_b_bits_opcode;
  logic [1:0] inner_busPMU_auto_in_0_b_bits_param;
  logic [2:0] inner_busPMU_auto_in_0_b_bits_size;
  logic [5:0] inner_busPMU_auto_in_0_b_bits_source;
  logic inner_busPMU_auto_in_0_b_valid;
  logic inner_busPMU_auto_in_0_c_ready;
  logic inner_busPMU_auto_in_0_d_bits_corrupt;
  logic [255:0] inner_busPMU_auto_in_0_d_bits_data;
  logic inner_busPMU_auto_in_0_d_bits_denied;
  logic inner_busPMU_auto_in_0_d_bits_echo_isKeyword;
  logic [3:0] inner_busPMU_auto_in_0_d_bits_opcode;
  logic [1:0] inner_busPMU_auto_in_0_d_bits_param;
  logic [9:0] inner_busPMU_auto_in_0_d_bits_sink;
  logic [2:0] inner_busPMU_auto_in_0_d_bits_size;
  logic [5:0] inner_busPMU_auto_in_0_d_bits_source;
  logic inner_busPMU_auto_in_0_d_valid;
  logic inner_busPMU_auto_in_0_e_ready;
  logic inner_busPMU_auto_in_1_a_ready;
  logic inner_busPMU_auto_in_1_d_bits_corrupt;
  logic [255:0] inner_busPMU_auto_in_1_d_bits_data;
  logic inner_busPMU_auto_in_1_d_bits_denied;
  logic [3:0] inner_busPMU_auto_in_1_d_bits_opcode;
  logic [1:0] inner_busPMU_auto_in_1_d_bits_param;
  logic [9:0] inner_busPMU_auto_in_1_d_bits_sink;
  logic [2:0] inner_busPMU_auto_in_1_d_bits_size;
  logic [3:0] inner_busPMU_auto_in_1_d_bits_source;
  logic inner_busPMU_auto_in_1_d_valid;
  logic inner_busPMU_auto_in_2_a_ready;
  logic inner_busPMU_auto_in_2_d_bits_corrupt;
  logic [255:0] inner_busPMU_auto_in_2_d_bits_data;
  logic inner_busPMU_auto_in_2_d_bits_denied;
  logic [3:0] inner_busPMU_auto_in_2_d_bits_opcode;
  logic [1:0] inner_busPMU_auto_in_2_d_bits_param;
  logic [9:0] inner_busPMU_auto_in_2_d_bits_sink;
  logic [2:0] inner_busPMU_auto_in_2_d_bits_size;
  logic [3:0] inner_busPMU_auto_in_2_d_bits_source;
  logic inner_busPMU_auto_in_2_d_valid;
  logic [47:0] inner_busPMU_auto_out_0_a_bits_address;
  logic inner_busPMU_auto_out_0_a_bits_corrupt;
  logic [255:0] inner_busPMU_auto_out_0_a_bits_data;
  logic inner_busPMU_auto_out_0_a_bits_echo_isKeyword;
  logic [31:0] inner_busPMU_auto_out_0_a_bits_mask;
  logic [3:0] inner_busPMU_auto_out_0_a_bits_opcode;
  logic [2:0] inner_busPMU_auto_out_0_a_bits_param;
  logic [2:0] inner_busPMU_auto_out_0_a_bits_size;
  logic [5:0] inner_busPMU_auto_out_0_a_bits_source;
  logic [1:0] inner_busPMU_auto_out_0_a_bits_user_alias;
  logic inner_busPMU_auto_out_0_a_bits_user_needHint;
  logic [4:0] inner_busPMU_auto_out_0_a_bits_user_reqSource;
  logic [43:0] inner_busPMU_auto_out_0_a_bits_user_vaddr;
  logic inner_busPMU_auto_out_0_a_valid;
  logic inner_busPMU_auto_out_0_b_ready;
  logic [47:0] inner_busPMU_auto_out_0_c_bits_address;
  logic inner_busPMU_auto_out_0_c_bits_corrupt;
  logic [255:0] inner_busPMU_auto_out_0_c_bits_data;
  logic inner_busPMU_auto_out_0_c_bits_echo_isKeyword;
  logic [2:0] inner_busPMU_auto_out_0_c_bits_opcode;
  logic [2:0] inner_busPMU_auto_out_0_c_bits_param;
  logic [2:0] inner_busPMU_auto_out_0_c_bits_size;
  logic [5:0] inner_busPMU_auto_out_0_c_bits_source;
  logic [1:0] inner_busPMU_auto_out_0_c_bits_user_alias;
  logic inner_busPMU_auto_out_0_c_bits_user_needHint;
  logic [4:0] inner_busPMU_auto_out_0_c_bits_user_reqSource;
  logic [43:0] inner_busPMU_auto_out_0_c_bits_user_vaddr;
  logic inner_busPMU_auto_out_0_c_valid;
  logic inner_busPMU_auto_out_0_d_ready;
  logic [9:0] inner_busPMU_auto_out_0_e_bits_sink;
  logic inner_busPMU_auto_out_0_e_valid;
  logic [47:0] inner_busPMU_auto_out_1_a_bits_address;
  logic inner_busPMU_auto_out_1_a_bits_corrupt;
  logic [255:0] inner_busPMU_auto_out_1_a_bits_data;
  logic [31:0] inner_busPMU_auto_out_1_a_bits_mask;
  logic [3:0] inner_busPMU_auto_out_1_a_bits_opcode;
  logic [2:0] inner_busPMU_auto_out_1_a_bits_param;
  logic [2:0] inner_busPMU_auto_out_1_a_bits_size;
  logic [3:0] inner_busPMU_auto_out_1_a_bits_source;
  logic [1:0] inner_busPMU_auto_out_1_a_bits_user_alias;
  logic inner_busPMU_auto_out_1_a_bits_user_needHint;
  logic [4:0] inner_busPMU_auto_out_1_a_bits_user_reqSource;
  logic inner_busPMU_auto_out_1_a_valid;
  logic inner_busPMU_auto_out_1_d_ready;
  logic [47:0] inner_busPMU_auto_out_2_a_bits_address;
  logic inner_busPMU_auto_out_2_a_bits_corrupt;
  logic [255:0] inner_busPMU_auto_out_2_a_bits_data;
  logic [31:0] inner_busPMU_auto_out_2_a_bits_mask;
  logic [3:0] inner_busPMU_auto_out_2_a_bits_opcode;
  logic [2:0] inner_busPMU_auto_out_2_a_bits_param;
  logic [2:0] inner_busPMU_auto_out_2_a_bits_size;
  logic [3:0] inner_busPMU_auto_out_2_a_bits_source;
  logic [4:0] inner_busPMU_auto_out_2_a_bits_user_reqSource;
  logic inner_busPMU_auto_out_2_a_valid;
  logic inner_busPMU_auto_out_2_d_ready;
  logic [47:0] inner_i_mmio_buffer_auto_out_a_bits_address;
  logic inner_i_mmio_buffer_auto_out_a_bits_corrupt;
  logic [63:0] inner_i_mmio_buffer_auto_out_a_bits_data;
  logic [7:0] inner_i_mmio_buffer_auto_out_a_bits_mask;
  logic [3:0] inner_i_mmio_buffer_auto_out_a_bits_opcode;
  logic [2:0] inner_i_mmio_buffer_auto_out_a_bits_param;
  logic [1:0] inner_i_mmio_buffer_auto_out_a_bits_size;
  logic inner_i_mmio_buffer_auto_out_a_bits_source;
  logic inner_i_mmio_buffer_auto_out_a_bits_user_memBackType_MM;
  logic inner_i_mmio_buffer_auto_out_a_bits_user_memPageType_NC;
  logic inner_i_mmio_buffer_auto_out_a_valid;
  logic inner_i_mmio_buffer_auto_out_d_ready;
  logic inner_l2cache_auto_in_0_a_ready;
  logic [47:0] inner_l2cache_auto_in_0_b_bits_address;
  logic [255:0] inner_l2cache_auto_in_0_b_bits_data;
  logic [2:0] inner_l2cache_auto_in_0_b_bits_opcode;
  logic [1:0] inner_l2cache_auto_in_0_b_bits_param;
  logic inner_l2cache_auto_in_0_b_valid;
  logic inner_l2cache_auto_in_0_c_ready;
  logic inner_l2cache_auto_in_0_d_bits_corrupt;
  logic [255:0] inner_l2cache_auto_in_0_d_bits_data;
  logic inner_l2cache_auto_in_0_d_bits_denied;
  logic inner_l2cache_auto_in_0_d_bits_echo_isKeyword;
  logic [3:0] inner_l2cache_auto_in_0_d_bits_opcode;
  logic [1:0] inner_l2cache_auto_in_0_d_bits_param;
  logic [7:0] inner_l2cache_auto_in_0_d_bits_sink;
  logic [6:0] inner_l2cache_auto_in_0_d_bits_source;
  logic inner_l2cache_auto_in_0_d_valid;
  logic inner_l2cache_auto_in_1_a_ready;
  logic [47:0] inner_l2cache_auto_in_1_b_bits_address;
  logic [255:0] inner_l2cache_auto_in_1_b_bits_data;
  logic [2:0] inner_l2cache_auto_in_1_b_bits_opcode;
  logic [1:0] inner_l2cache_auto_in_1_b_bits_param;
  logic inner_l2cache_auto_in_1_b_valid;
  logic inner_l2cache_auto_in_1_c_ready;
  logic inner_l2cache_auto_in_1_d_bits_corrupt;
  logic [255:0] inner_l2cache_auto_in_1_d_bits_data;
  logic inner_l2cache_auto_in_1_d_bits_denied;
  logic inner_l2cache_auto_in_1_d_bits_echo_isKeyword;
  logic [3:0] inner_l2cache_auto_in_1_d_bits_opcode;
  logic [1:0] inner_l2cache_auto_in_1_d_bits_param;
  logic [7:0] inner_l2cache_auto_in_1_d_bits_sink;
  logic [6:0] inner_l2cache_auto_in_1_d_bits_source;
  logic inner_l2cache_auto_in_1_d_valid;
  logic inner_l2cache_auto_in_2_a_ready;
  logic [47:0] inner_l2cache_auto_in_2_b_bits_address;
  logic [255:0] inner_l2cache_auto_in_2_b_bits_data;
  logic [2:0] inner_l2cache_auto_in_2_b_bits_opcode;
  logic [1:0] inner_l2cache_auto_in_2_b_bits_param;
  logic inner_l2cache_auto_in_2_b_valid;
  logic inner_l2cache_auto_in_2_c_ready;
  logic inner_l2cache_auto_in_2_d_bits_corrupt;
  logic [255:0] inner_l2cache_auto_in_2_d_bits_data;
  logic inner_l2cache_auto_in_2_d_bits_denied;
  logic inner_l2cache_auto_in_2_d_bits_echo_isKeyword;
  logic [3:0] inner_l2cache_auto_in_2_d_bits_opcode;
  logic [1:0] inner_l2cache_auto_in_2_d_bits_param;
  logic [7:0] inner_l2cache_auto_in_2_d_bits_sink;
  logic [6:0] inner_l2cache_auto_in_2_d_bits_source;
  logic inner_l2cache_auto_in_2_d_valid;
  logic inner_l2cache_auto_in_3_a_ready;
  logic [47:0] inner_l2cache_auto_in_3_b_bits_address;
  logic [255:0] inner_l2cache_auto_in_3_b_bits_data;
  logic [2:0] inner_l2cache_auto_in_3_b_bits_opcode;
  logic [1:0] inner_l2cache_auto_in_3_b_bits_param;
  logic inner_l2cache_auto_in_3_b_valid;
  logic inner_l2cache_auto_in_3_c_ready;
  logic inner_l2cache_auto_in_3_d_bits_corrupt;
  logic [255:0] inner_l2cache_auto_in_3_d_bits_data;
  logic inner_l2cache_auto_in_3_d_bits_denied;
  logic inner_l2cache_auto_in_3_d_bits_echo_isKeyword;
  logic [3:0] inner_l2cache_auto_in_3_d_bits_opcode;
  logic [1:0] inner_l2cache_auto_in_3_d_bits_param;
  logic [7:0] inner_l2cache_auto_in_3_d_bits_sink;
  logic [6:0] inner_l2cache_auto_in_3_d_bits_source;
  logic inner_l2cache_auto_in_3_d_valid;
  logic inner_l2cache_auto_mmioBridge_mmio_in_a_ready;
  logic inner_l2cache_auto_mmioBridge_mmio_in_d_bits_corrupt;
  logic [63:0] inner_l2cache_auto_mmioBridge_mmio_in_d_bits_data;
  logic inner_l2cache_auto_mmioBridge_mmio_in_d_bits_denied;
  logic [3:0] inner_l2cache_auto_mmioBridge_mmio_in_d_bits_opcode;
  logic [1:0] inner_l2cache_auto_mmioBridge_mmio_in_d_bits_param;
  logic inner_l2cache_auto_mmioBridge_mmio_in_d_bits_sink;
  logic [1:0] inner_l2cache_auto_mmioBridge_mmio_in_d_bits_size;
  logic [4:0] inner_l2cache_auto_mmioBridge_mmio_in_d_bits_source;
  logic inner_l2cache_auto_mmioBridge_mmio_in_d_valid;
  logic inner_l2cache_io_chi_rx_dat_lcrdv;
  logic inner_l2cache_io_chi_rx_linkactiveack;
  logic inner_l2cache_io_chi_rx_rsp_lcrdv;
  logic inner_l2cache_io_chi_rx_snp_lcrdv;
  logic inner_l2cache_io_chi_syscoreq;
  logic [421:0] inner_l2cache_io_chi_tx_dat_flit;
  logic inner_l2cache_io_chi_tx_dat_flitpend;
  logic inner_l2cache_io_chi_tx_dat_flitv;
  logic inner_l2cache_io_chi_tx_linkactivereq;
  logic [161:0] inner_l2cache_io_chi_tx_req_flit;
  logic inner_l2cache_io_chi_tx_req_flitpend;
  logic inner_l2cache_io_chi_tx_req_flitv;
  logic [72:0] inner_l2cache_io_chi_tx_rsp_flit;
  logic inner_l2cache_io_chi_tx_rsp_flitpend;
  logic inner_l2cache_io_chi_tx_rsp_flitv;
  logic inner_l2cache_io_chi_txsactive;
  logic [45:0] inner_l2cache_io_error_address;
  logic inner_l2cache_io_error_valid;
  logic [31:0] inner_l2cache_io_l2_hint_bits_sourceId;
  logic [47:0] inner_logger_1_auto_out_a_bits_address;
  logic inner_logger_1_auto_out_a_bits_corrupt;
  logic [255:0] inner_logger_1_auto_out_a_bits_data;
  logic [31:0] inner_logger_1_auto_out_a_bits_mask;
  logic [3:0] inner_logger_1_auto_out_a_bits_opcode;
  logic [2:0] inner_logger_1_auto_out_a_bits_param;
  logic [2:0] inner_logger_1_auto_out_a_bits_size;
  logic [3:0] inner_logger_1_auto_out_a_bits_source;
  logic [1:0] inner_logger_1_auto_out_a_bits_user_alias;
  logic inner_logger_1_auto_out_a_bits_user_needHint;
  logic [4:0] inner_logger_1_auto_out_a_bits_user_reqSource;
  logic inner_logger_1_auto_out_a_valid;
  logic inner_logger_1_auto_out_d_ready;
  logic inner_logger_2_auto_in_a_ready;
  logic inner_logger_2_auto_in_d_bits_corrupt;
  logic [255:0] inner_logger_2_auto_in_d_bits_data;
  logic inner_logger_2_auto_in_d_bits_denied;
  logic [3:0] inner_logger_2_auto_in_d_bits_opcode;
  logic [1:0] inner_logger_2_auto_in_d_bits_param;
  logic [9:0] inner_logger_2_auto_in_d_bits_sink;
  logic [2:0] inner_logger_2_auto_in_d_bits_size;
  logic [3:0] inner_logger_2_auto_in_d_bits_source;
  logic inner_logger_2_auto_in_d_valid;
  logic [47:0] inner_logger_2_auto_out_a_bits_address;
  logic inner_logger_2_auto_out_a_bits_corrupt;
  logic [255:0] inner_logger_2_auto_out_a_bits_data;
  logic [31:0] inner_logger_2_auto_out_a_bits_mask;
  logic [3:0] inner_logger_2_auto_out_a_bits_opcode;
  logic [2:0] inner_logger_2_auto_out_a_bits_param;
  logic [2:0] inner_logger_2_auto_out_a_bits_size;
  logic [3:0] inner_logger_2_auto_out_a_bits_source;
  logic [4:0] inner_logger_2_auto_out_a_bits_user_reqSource;
  logic inner_logger_2_auto_out_a_valid;
  logic inner_logger_2_auto_out_d_ready;
  logic [47:0] inner_logger_auto_out_a_bits_address;
  logic inner_logger_auto_out_a_bits_corrupt;
  logic [255:0] inner_logger_auto_out_a_bits_data;
  logic inner_logger_auto_out_a_bits_echo_isKeyword;
  logic [31:0] inner_logger_auto_out_a_bits_mask;
  logic [3:0] inner_logger_auto_out_a_bits_opcode;
  logic [2:0] inner_logger_auto_out_a_bits_param;
  logic [2:0] inner_logger_auto_out_a_bits_size;
  logic [5:0] inner_logger_auto_out_a_bits_source;
  logic [1:0] inner_logger_auto_out_a_bits_user_alias;
  logic inner_logger_auto_out_a_bits_user_needHint;
  logic [4:0] inner_logger_auto_out_a_bits_user_reqSource;
  logic [43:0] inner_logger_auto_out_a_bits_user_vaddr;
  logic inner_logger_auto_out_a_valid;
  logic inner_logger_auto_out_b_ready;
  logic [47:0] inner_logger_auto_out_c_bits_address;
  logic inner_logger_auto_out_c_bits_corrupt;
  logic [255:0] inner_logger_auto_out_c_bits_data;
  logic inner_logger_auto_out_c_bits_echo_isKeyword;
  logic [2:0] inner_logger_auto_out_c_bits_opcode;
  logic [2:0] inner_logger_auto_out_c_bits_param;
  logic [2:0] inner_logger_auto_out_c_bits_size;
  logic [5:0] inner_logger_auto_out_c_bits_source;
  logic [1:0] inner_logger_auto_out_c_bits_user_alias;
  logic inner_logger_auto_out_c_bits_user_needHint;
  logic [4:0] inner_logger_auto_out_c_bits_user_reqSource;
  logic [43:0] inner_logger_auto_out_c_bits_user_vaddr;
  logic inner_logger_auto_out_c_valid;
  logic inner_logger_auto_out_d_ready;
  logic [9:0] inner_logger_auto_out_e_bits_sink;
  logic inner_logger_auto_out_e_valid;
  logic [47:0] inner_ptw_to_l2_buffer_auto_out_a_bits_address;
  logic inner_ptw_to_l2_buffer_auto_out_a_bits_corrupt;
  logic [255:0] inner_ptw_to_l2_buffer_auto_out_a_bits_data;
  logic [31:0] inner_ptw_to_l2_buffer_auto_out_a_bits_mask;
  logic [3:0] inner_ptw_to_l2_buffer_auto_out_a_bits_opcode;
  logic [2:0] inner_ptw_to_l2_buffer_auto_out_a_bits_param;
  logic [2:0] inner_ptw_to_l2_buffer_auto_out_a_bits_size;
  logic [3:0] inner_ptw_to_l2_buffer_auto_out_a_bits_source;
  logic [4:0] inner_ptw_to_l2_buffer_auto_out_a_bits_user_reqSource;
  logic inner_ptw_to_l2_buffer_auto_out_a_valid;
  logic inner_ptw_to_l2_buffer_auto_out_d_ready;
  logic inner_xbar_1_auto_in_0_a_ready;
  logic inner_xbar_1_auto_in_0_d_bits_corrupt;
  logic [63:0] inner_xbar_1_auto_in_0_d_bits_data;
  logic inner_xbar_1_auto_in_0_d_bits_denied;
  logic [3:0] inner_xbar_1_auto_in_0_d_bits_opcode;
  logic [1:0] inner_xbar_1_auto_in_0_d_bits_param;
  logic inner_xbar_1_auto_in_0_d_bits_sink;
  logic [1:0] inner_xbar_1_auto_in_0_d_bits_size;
  logic inner_xbar_1_auto_in_0_d_valid;
  logic inner_xbar_1_auto_in_1_a_ready;
  logic inner_xbar_1_auto_in_1_d_bits_corrupt;
  logic [63:0] inner_xbar_1_auto_in_1_d_bits_data;
  logic inner_xbar_1_auto_in_1_d_bits_denied;
  logic [3:0] inner_xbar_1_auto_in_1_d_bits_opcode;
  logic [1:0] inner_xbar_1_auto_in_1_d_bits_param;
  logic inner_xbar_1_auto_in_1_d_bits_sink;
  logic [1:0] inner_xbar_1_auto_in_1_d_bits_size;
  logic [3:0] inner_xbar_1_auto_in_1_d_bits_source;
  logic inner_xbar_1_auto_in_1_d_valid;
  logic [29:0] inner_xbar_1_auto_out_0_a_bits_address;
  logic inner_xbar_1_auto_out_0_a_bits_corrupt;
  logic [63:0] inner_xbar_1_auto_out_0_a_bits_data;
  logic [7:0] inner_xbar_1_auto_out_0_a_bits_mask;
  logic [3:0] inner_xbar_1_auto_out_0_a_bits_opcode;
  logic [2:0] inner_xbar_1_auto_out_0_a_bits_param;
  logic [1:0] inner_xbar_1_auto_out_0_a_bits_size;
  logic [4:0] inner_xbar_1_auto_out_0_a_bits_source;
  logic inner_xbar_1_auto_out_0_a_valid;
  logic inner_xbar_1_auto_out_0_d_ready;
  logic [29:0] inner_xbar_1_auto_out_1_a_bits_address;
  logic inner_xbar_1_auto_out_1_a_bits_corrupt;
  logic [63:0] inner_xbar_1_auto_out_1_a_bits_data;
  logic [7:0] inner_xbar_1_auto_out_1_a_bits_mask;
  logic [3:0] inner_xbar_1_auto_out_1_a_bits_opcode;
  logic [2:0] inner_xbar_1_auto_out_1_a_bits_param;
  logic [1:0] inner_xbar_1_auto_out_1_a_bits_size;
  logic [4:0] inner_xbar_1_auto_out_1_a_bits_source;
  logic inner_xbar_1_auto_out_1_a_valid;
  logic inner_xbar_1_auto_out_1_d_ready;
  logic [47:0] inner_xbar_1_auto_out_2_a_bits_address;
  logic inner_xbar_1_auto_out_2_a_bits_corrupt;
  logic [63:0] inner_xbar_1_auto_out_2_a_bits_data;
  logic [7:0] inner_xbar_1_auto_out_2_a_bits_mask;
  logic [3:0] inner_xbar_1_auto_out_2_a_bits_opcode;
  logic [2:0] inner_xbar_1_auto_out_2_a_bits_param;
  logic [1:0] inner_xbar_1_auto_out_2_a_bits_size;
  logic [4:0] inner_xbar_1_auto_out_2_a_bits_source;
  logic inner_xbar_1_auto_out_2_a_bits_user_memBackType_MM;
  logic inner_xbar_1_auto_out_2_a_bits_user_memPageType_NC;
  logic inner_xbar_1_auto_out_2_a_valid;
  logic inner_xbar_1_auto_out_2_d_ready;
  logic inner_xbar_auto_in_0_a_ready;
  logic [47:0] inner_xbar_auto_in_0_b_bits_address;
  logic inner_xbar_auto_in_0_b_bits_corrupt;
  logic [255:0] inner_xbar_auto_in_0_b_bits_data;
  logic [31:0] inner_xbar_auto_in_0_b_bits_mask;
  logic [2:0] inner_xbar_auto_in_0_b_bits_opcode;
  logic [1:0] inner_xbar_auto_in_0_b_bits_param;
  logic [2:0] inner_xbar_auto_in_0_b_bits_size;
  logic [5:0] inner_xbar_auto_in_0_b_bits_source;
  logic inner_xbar_auto_in_0_b_valid;
  logic inner_xbar_auto_in_0_c_ready;
  logic inner_xbar_auto_in_0_d_bits_corrupt;
  logic [255:0] inner_xbar_auto_in_0_d_bits_data;
  logic inner_xbar_auto_in_0_d_bits_denied;
  logic inner_xbar_auto_in_0_d_bits_echo_isKeyword;
  logic [3:0] inner_xbar_auto_in_0_d_bits_opcode;
  logic [1:0] inner_xbar_auto_in_0_d_bits_param;
  logic [9:0] inner_xbar_auto_in_0_d_bits_sink;
  logic [2:0] inner_xbar_auto_in_0_d_bits_size;
  logic [5:0] inner_xbar_auto_in_0_d_bits_source;
  logic inner_xbar_auto_in_0_d_valid;
  logic inner_xbar_auto_in_0_e_ready;
  logic inner_xbar_auto_in_1_a_ready;
  logic inner_xbar_auto_in_1_d_bits_corrupt;
  logic [255:0] inner_xbar_auto_in_1_d_bits_data;
  logic inner_xbar_auto_in_1_d_bits_denied;
  logic [3:0] inner_xbar_auto_in_1_d_bits_opcode;
  logic [1:0] inner_xbar_auto_in_1_d_bits_param;
  logic [9:0] inner_xbar_auto_in_1_d_bits_sink;
  logic [2:0] inner_xbar_auto_in_1_d_bits_size;
  logic [3:0] inner_xbar_auto_in_1_d_bits_source;
  logic inner_xbar_auto_in_1_d_valid;
  logic inner_xbar_auto_in_2_a_ready;
  logic inner_xbar_auto_in_2_d_bits_corrupt;
  logic [255:0] inner_xbar_auto_in_2_d_bits_data;
  logic inner_xbar_auto_in_2_d_bits_denied;
  logic [3:0] inner_xbar_auto_in_2_d_bits_opcode;
  logic [1:0] inner_xbar_auto_in_2_d_bits_param;
  logic [9:0] inner_xbar_auto_in_2_d_bits_sink;
  logic [2:0] inner_xbar_auto_in_2_d_bits_size;
  logic [3:0] inner_xbar_auto_in_2_d_bits_source;
  logic inner_xbar_auto_in_2_d_valid;
  logic [47:0] inner_xbar_auto_out_0_a_bits_address;
  logic inner_xbar_auto_out_0_a_bits_corrupt;
  logic [255:0] inner_xbar_auto_out_0_a_bits_data;
  logic inner_xbar_auto_out_0_a_bits_echo_isKeyword;
  logic [31:0] inner_xbar_auto_out_0_a_bits_mask;
  logic [3:0] inner_xbar_auto_out_0_a_bits_opcode;
  logic [2:0] inner_xbar_auto_out_0_a_bits_param;
  logic [2:0] inner_xbar_auto_out_0_a_bits_size;
  logic [6:0] inner_xbar_auto_out_0_a_bits_source;
  logic [1:0] inner_xbar_auto_out_0_a_bits_user_alias;
  logic inner_xbar_auto_out_0_a_bits_user_needHint;
  logic [4:0] inner_xbar_auto_out_0_a_bits_user_reqSource;
  logic [43:0] inner_xbar_auto_out_0_a_bits_user_vaddr;
  logic inner_xbar_auto_out_0_a_valid;
  logic inner_xbar_auto_out_0_b_ready;
  logic [47:0] inner_xbar_auto_out_0_c_bits_address;
  logic inner_xbar_auto_out_0_c_bits_corrupt;
  logic [255:0] inner_xbar_auto_out_0_c_bits_data;
  logic inner_xbar_auto_out_0_c_bits_echo_isKeyword;
  logic [2:0] inner_xbar_auto_out_0_c_bits_opcode;
  logic [2:0] inner_xbar_auto_out_0_c_bits_param;
  logic [2:0] inner_xbar_auto_out_0_c_bits_size;
  logic [6:0] inner_xbar_auto_out_0_c_bits_source;
  logic [1:0] inner_xbar_auto_out_0_c_bits_user_alias;
  logic inner_xbar_auto_out_0_c_bits_user_needHint;
  logic [4:0] inner_xbar_auto_out_0_c_bits_user_reqSource;
  logic [43:0] inner_xbar_auto_out_0_c_bits_user_vaddr;
  logic inner_xbar_auto_out_0_c_valid;
  logic inner_xbar_auto_out_0_d_ready;
  logic [7:0] inner_xbar_auto_out_0_e_bits_sink;
  logic inner_xbar_auto_out_0_e_valid;
  logic [47:0] inner_xbar_auto_out_1_a_bits_address;
  logic inner_xbar_auto_out_1_a_bits_corrupt;
  logic [255:0] inner_xbar_auto_out_1_a_bits_data;
  logic inner_xbar_auto_out_1_a_bits_echo_isKeyword;
  logic [31:0] inner_xbar_auto_out_1_a_bits_mask;
  logic [3:0] inner_xbar_auto_out_1_a_bits_opcode;
  logic [2:0] inner_xbar_auto_out_1_a_bits_param;
  logic [2:0] inner_xbar_auto_out_1_a_bits_size;
  logic [6:0] inner_xbar_auto_out_1_a_bits_source;
  logic [1:0] inner_xbar_auto_out_1_a_bits_user_alias;
  logic inner_xbar_auto_out_1_a_bits_user_needHint;
  logic [4:0] inner_xbar_auto_out_1_a_bits_user_reqSource;
  logic [43:0] inner_xbar_auto_out_1_a_bits_user_vaddr;
  logic inner_xbar_auto_out_1_a_valid;
  logic inner_xbar_auto_out_1_b_ready;
  logic [47:0] inner_xbar_auto_out_1_c_bits_address;
  logic inner_xbar_auto_out_1_c_bits_corrupt;
  logic [255:0] inner_xbar_auto_out_1_c_bits_data;
  logic inner_xbar_auto_out_1_c_bits_echo_isKeyword;
  logic [2:0] inner_xbar_auto_out_1_c_bits_opcode;
  logic [2:0] inner_xbar_auto_out_1_c_bits_param;
  logic [2:0] inner_xbar_auto_out_1_c_bits_size;
  logic [6:0] inner_xbar_auto_out_1_c_bits_source;
  logic [1:0] inner_xbar_auto_out_1_c_bits_user_alias;
  logic inner_xbar_auto_out_1_c_bits_user_needHint;
  logic [4:0] inner_xbar_auto_out_1_c_bits_user_reqSource;
  logic [43:0] inner_xbar_auto_out_1_c_bits_user_vaddr;
  logic inner_xbar_auto_out_1_c_valid;
  logic inner_xbar_auto_out_1_d_ready;
  logic [7:0] inner_xbar_auto_out_1_e_bits_sink;
  logic inner_xbar_auto_out_1_e_valid;
  logic [47:0] inner_xbar_auto_out_2_a_bits_address;
  logic inner_xbar_auto_out_2_a_bits_corrupt;
  logic [255:0] inner_xbar_auto_out_2_a_bits_data;
  logic inner_xbar_auto_out_2_a_bits_echo_isKeyword;
  logic [31:0] inner_xbar_auto_out_2_a_bits_mask;
  logic [3:0] inner_xbar_auto_out_2_a_bits_opcode;
  logic [2:0] inner_xbar_auto_out_2_a_bits_param;
  logic [2:0] inner_xbar_auto_out_2_a_bits_size;
  logic [6:0] inner_xbar_auto_out_2_a_bits_source;
  logic [1:0] inner_xbar_auto_out_2_a_bits_user_alias;
  logic inner_xbar_auto_out_2_a_bits_user_needHint;
  logic [4:0] inner_xbar_auto_out_2_a_bits_user_reqSource;
  logic [43:0] inner_xbar_auto_out_2_a_bits_user_vaddr;
  logic inner_xbar_auto_out_2_a_valid;
  logic inner_xbar_auto_out_2_b_ready;
  logic [47:0] inner_xbar_auto_out_2_c_bits_address;
  logic inner_xbar_auto_out_2_c_bits_corrupt;
  logic [255:0] inner_xbar_auto_out_2_c_bits_data;
  logic inner_xbar_auto_out_2_c_bits_echo_isKeyword;
  logic [2:0] inner_xbar_auto_out_2_c_bits_opcode;
  logic [2:0] inner_xbar_auto_out_2_c_bits_param;
  logic [2:0] inner_xbar_auto_out_2_c_bits_size;
  logic [6:0] inner_xbar_auto_out_2_c_bits_source;
  logic [1:0] inner_xbar_auto_out_2_c_bits_user_alias;
  logic inner_xbar_auto_out_2_c_bits_user_needHint;
  logic [4:0] inner_xbar_auto_out_2_c_bits_user_reqSource;
  logic [43:0] inner_xbar_auto_out_2_c_bits_user_vaddr;
  logic inner_xbar_auto_out_2_c_valid;
  logic inner_xbar_auto_out_2_d_ready;
  logic [7:0] inner_xbar_auto_out_2_e_bits_sink;
  logic inner_xbar_auto_out_2_e_valid;
  logic [47:0] inner_xbar_auto_out_3_a_bits_address;
  logic inner_xbar_auto_out_3_a_bits_corrupt;
  logic [255:0] inner_xbar_auto_out_3_a_bits_data;
  logic inner_xbar_auto_out_3_a_bits_echo_isKeyword;
  logic [31:0] inner_xbar_auto_out_3_a_bits_mask;
  logic [3:0] inner_xbar_auto_out_3_a_bits_opcode;
  logic [2:0] inner_xbar_auto_out_3_a_bits_param;
  logic [2:0] inner_xbar_auto_out_3_a_bits_size;
  logic [6:0] inner_xbar_auto_out_3_a_bits_source;
  logic [1:0] inner_xbar_auto_out_3_a_bits_user_alias;
  logic inner_xbar_auto_out_3_a_bits_user_needHint;
  logic [4:0] inner_xbar_auto_out_3_a_bits_user_reqSource;
  logic [43:0] inner_xbar_auto_out_3_a_bits_user_vaddr;
  logic inner_xbar_auto_out_3_a_valid;
  logic inner_xbar_auto_out_3_b_ready;
  logic [47:0] inner_xbar_auto_out_3_c_bits_address;
  logic inner_xbar_auto_out_3_c_bits_corrupt;
  logic [255:0] inner_xbar_auto_out_3_c_bits_data;
  logic inner_xbar_auto_out_3_c_bits_echo_isKeyword;
  logic [2:0] inner_xbar_auto_out_3_c_bits_opcode;
  logic [2:0] inner_xbar_auto_out_3_c_bits_param;
  logic [2:0] inner_xbar_auto_out_3_c_bits_size;
  logic [6:0] inner_xbar_auto_out_3_c_bits_source;
  logic [1:0] inner_xbar_auto_out_3_c_bits_user_alias;
  logic inner_xbar_auto_out_3_c_bits_user_needHint;
  logic [4:0] inner_xbar_auto_out_3_c_bits_user_reqSource;
  logic [43:0] inner_xbar_auto_out_3_c_bits_user_vaddr;
  logic inner_xbar_auto_out_3_c_valid;
  logic inner_xbar_auto_out_3_d_ready;
  logic [7:0] inner_xbar_auto_out_3_e_bits_sink;
  logic inner_xbar_auto_out_3_e_valid;

  // ---- 胶合核的端口 ----
  logic msiFromTile_valid;
  logic [11:0] msiFromTile_bits;
  logic msiToCore_valid;
  logic [11:0] msiToCore_bits;
  logic cpuHaltFromCore;
  logic cpuHaltToTile;
  logic criticalErrorFromCore;
  logic criticalErrorToTile;
  logic l3MissFromTile;
  logic l3MissToCore;
  logic [2:0] traceIn_priv;
  logic [63:0] traceIn_mstatus;
  logic [63:0] traceIn_trapCause;
  logic [49:0] traceIn_trapTval;
  logic [3-1:0] traceIn_valid;
  logic [49:0] traceIn_iaddr [3];
  logic [3:0] traceIn_itype [3];
  logic [6:0] traceIn_iretire [3];
  logic [3-1:0] traceIn_ilastsize;
  logic [2:0] traceOut_priv;
  logic [63:0] traceOut_mstatus;
  logic [63:0] traceOut_trapCause;
  logic [49:0] traceOut_trapTval;
  logic [3-1:0] traceOut_valid;
  logic [49:0] traceOut_iaddr [3];
  logic [3:0] traceOut_itype [3];
  logic [6:0] traceOut_iretire [3];
  logic [3-1:0] traceOut_ilastsize;
  logic encoderIn_enable;
  logic encoderIn_stall;
  logic encoderOut_enable;
  logic encoderOut_stall;
  logic resetInFrontend;
  logic hartIsInReset;
  logic [45:0] l2ErrorAddr;
  logic [47:0] beuL2ErrorAddr;

  // ---- 核的输入：从 child 输出 / 顶层输入收集 ----
  assign msiFromTile_valid = io_msiInfo_fromTile_valid;
  assign msiFromTile_bits = io_msiInfo_fromTile_bits;
  assign cpuHaltFromCore = io_cpu_halt_fromCore;
  assign criticalErrorFromCore = io_cpu_critical_error_fromCore;
  assign l3MissFromTile = io_l3Miss_fromTile;
  assign traceIn_priv = io_traceCoreInterface_fromCore_toEncoder_priv;
  assign traceIn_mstatus = io_traceCoreInterface_fromCore_toEncoder_mstatus;
  assign traceIn_trapCause = io_traceCoreInterface_fromCore_toEncoder_trap_cause;
  assign traceIn_trapTval = io_traceCoreInterface_fromCore_toEncoder_trap_tval;
  assign traceIn_valid[0] = io_traceCoreInterface_fromCore_toEncoder_groups_0_valid;
  assign traceIn_valid[1] = io_traceCoreInterface_fromCore_toEncoder_groups_1_valid;
  assign traceIn_valid[2] = io_traceCoreInterface_fromCore_toEncoder_groups_2_valid;
  assign traceIn_iaddr[0] = io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr;
  assign traceIn_iaddr[1] = io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr;
  assign traceIn_iaddr[2] = io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr;
  assign traceIn_itype[0] = io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype;
  assign traceIn_itype[1] = io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype;
  assign traceIn_itype[2] = io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype;
  assign traceIn_iretire[0] = io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire;
  assign traceIn_iretire[1] = io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire;
  assign traceIn_iretire[2] = io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire;
  assign traceIn_ilastsize[0] = io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize;
  assign traceIn_ilastsize[1] = io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize;
  assign traceIn_ilastsize[2] = io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize;
  assign encoderIn_enable = io_traceCoreInterface_toTile_fromEncoder_enable;
  assign encoderIn_stall = io_traceCoreInterface_toTile_fromEncoder_stall;
  assign resetInFrontend = io_hartIsInReset_resetInFrontend;
  assign l2ErrorAddr = inner_l2cache_io_error_address;

  xs_L2Top_core u_core (
    .clock                (clock),
    .reset                (reset),
    .msiFromTile_valid    (msiFromTile_valid),
    .msiFromTile_bits     (msiFromTile_bits),
    .msiToCore_valid      (msiToCore_valid),
    .msiToCore_bits       (msiToCore_bits),
    .cpuHaltFromCore      (cpuHaltFromCore),
    .cpuHaltToTile        (cpuHaltToTile),
    .criticalErrorFromCore (criticalErrorFromCore),
    .criticalErrorToTile  (criticalErrorToTile),
    .l3MissFromTile       (l3MissFromTile),
    .l3MissToCore         (l3MissToCore),
    .traceIn_priv         (traceIn_priv),
    .traceIn_mstatus      (traceIn_mstatus),
    .traceIn_trapCause    (traceIn_trapCause),
    .traceIn_trapTval     (traceIn_trapTval),
    .traceIn_valid        (traceIn_valid),
    .traceIn_iaddr        (traceIn_iaddr),
    .traceIn_itype        (traceIn_itype),
    .traceIn_iretire      (traceIn_iretire),
    .traceIn_ilastsize    (traceIn_ilastsize),
    .traceOut_priv        (traceOut_priv),
    .traceOut_mstatus     (traceOut_mstatus),
    .traceOut_trapCause   (traceOut_trapCause),
    .traceOut_trapTval    (traceOut_trapTval),
    .traceOut_valid       (traceOut_valid),
    .traceOut_iaddr       (traceOut_iaddr),
    .traceOut_itype       (traceOut_itype),
    .traceOut_iretire     (traceOut_iretire),
    .traceOut_ilastsize   (traceOut_ilastsize),
    .encoderIn_enable     (encoderIn_enable),
    .encoderIn_stall      (encoderIn_stall),
    .encoderOut_enable    (encoderOut_enable),
    .encoderOut_stall     (encoderOut_stall),
    .resetInFrontend      (resetInFrontend),
    .hartIsInReset        (hartIsInReset),
    .l2ErrorAddr          (l2ErrorAddr),
    .beuL2ErrorAddr       (beuL2ErrorAddr)
  );

  // ---- 21 个 child（实例名 / 顺序同 golden）----
  TLXbar_5 inner_xbar (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_2_a_ready                        (inner_xbar_auto_in_2_a_ready),
    .auto_in_2_a_valid                        (inner_busPMU_auto_out_2_a_valid),
    .auto_in_2_a_bits_opcode                  (inner_busPMU_auto_out_2_a_bits_opcode),
    .auto_in_2_a_bits_param                   (inner_busPMU_auto_out_2_a_bits_param),
    .auto_in_2_a_bits_size                    (inner_busPMU_auto_out_2_a_bits_size),
    .auto_in_2_a_bits_source                  (inner_busPMU_auto_out_2_a_bits_source),
    .auto_in_2_a_bits_address                 (inner_busPMU_auto_out_2_a_bits_address),
    .auto_in_2_a_bits_user_reqSource          (inner_busPMU_auto_out_2_a_bits_user_reqSource),
    .auto_in_2_a_bits_mask                    (inner_busPMU_auto_out_2_a_bits_mask),
    .auto_in_2_a_bits_data                    (inner_busPMU_auto_out_2_a_bits_data),
    .auto_in_2_a_bits_corrupt                 (inner_busPMU_auto_out_2_a_bits_corrupt),
    .auto_in_2_d_ready                        (inner_busPMU_auto_out_2_d_ready),
    .auto_in_2_d_valid                        (inner_xbar_auto_in_2_d_valid),
    .auto_in_2_d_bits_opcode                  (inner_xbar_auto_in_2_d_bits_opcode),
    .auto_in_2_d_bits_param                   (inner_xbar_auto_in_2_d_bits_param),
    .auto_in_2_d_bits_size                    (inner_xbar_auto_in_2_d_bits_size),
    .auto_in_2_d_bits_source                  (inner_xbar_auto_in_2_d_bits_source),
    .auto_in_2_d_bits_sink                    (inner_xbar_auto_in_2_d_bits_sink),
    .auto_in_2_d_bits_denied                  (inner_xbar_auto_in_2_d_bits_denied),
    .auto_in_2_d_bits_data                    (inner_xbar_auto_in_2_d_bits_data),
    .auto_in_2_d_bits_corrupt                 (inner_xbar_auto_in_2_d_bits_corrupt),
    .auto_in_1_a_ready                        (inner_xbar_auto_in_1_a_ready),
    .auto_in_1_a_valid                        (inner_busPMU_auto_out_1_a_valid),
    .auto_in_1_a_bits_opcode                  (inner_busPMU_auto_out_1_a_bits_opcode),
    .auto_in_1_a_bits_param                   (inner_busPMU_auto_out_1_a_bits_param),
    .auto_in_1_a_bits_size                    (inner_busPMU_auto_out_1_a_bits_size),
    .auto_in_1_a_bits_source                  (inner_busPMU_auto_out_1_a_bits_source),
    .auto_in_1_a_bits_address                 (inner_busPMU_auto_out_1_a_bits_address),
    .auto_in_1_a_bits_user_alias              (inner_busPMU_auto_out_1_a_bits_user_alias),
    .auto_in_1_a_bits_user_reqSource          (inner_busPMU_auto_out_1_a_bits_user_reqSource),
    .auto_in_1_a_bits_user_needHint           (inner_busPMU_auto_out_1_a_bits_user_needHint),
    .auto_in_1_a_bits_mask                    (inner_busPMU_auto_out_1_a_bits_mask),
    .auto_in_1_a_bits_data                    (inner_busPMU_auto_out_1_a_bits_data),
    .auto_in_1_a_bits_corrupt                 (inner_busPMU_auto_out_1_a_bits_corrupt),
    .auto_in_1_d_ready                        (inner_busPMU_auto_out_1_d_ready),
    .auto_in_1_d_valid                        (inner_xbar_auto_in_1_d_valid),
    .auto_in_1_d_bits_opcode                  (inner_xbar_auto_in_1_d_bits_opcode),
    .auto_in_1_d_bits_param                   (inner_xbar_auto_in_1_d_bits_param),
    .auto_in_1_d_bits_size                    (inner_xbar_auto_in_1_d_bits_size),
    .auto_in_1_d_bits_source                  (inner_xbar_auto_in_1_d_bits_source),
    .auto_in_1_d_bits_sink                    (inner_xbar_auto_in_1_d_bits_sink),
    .auto_in_1_d_bits_denied                  (inner_xbar_auto_in_1_d_bits_denied),
    .auto_in_1_d_bits_data                    (inner_xbar_auto_in_1_d_bits_data),
    .auto_in_1_d_bits_corrupt                 (inner_xbar_auto_in_1_d_bits_corrupt),
    .auto_in_0_a_ready                        (inner_xbar_auto_in_0_a_ready),
    .auto_in_0_a_valid                        (inner_busPMU_auto_out_0_a_valid),
    .auto_in_0_a_bits_opcode                  (inner_busPMU_auto_out_0_a_bits_opcode),
    .auto_in_0_a_bits_param                   (inner_busPMU_auto_out_0_a_bits_param),
    .auto_in_0_a_bits_size                    (inner_busPMU_auto_out_0_a_bits_size),
    .auto_in_0_a_bits_source                  (inner_busPMU_auto_out_0_a_bits_source),
    .auto_in_0_a_bits_address                 (inner_busPMU_auto_out_0_a_bits_address),
    .auto_in_0_a_bits_user_alias              (inner_busPMU_auto_out_0_a_bits_user_alias),
    .auto_in_0_a_bits_user_vaddr              (inner_busPMU_auto_out_0_a_bits_user_vaddr),
    .auto_in_0_a_bits_user_reqSource          (inner_busPMU_auto_out_0_a_bits_user_reqSource),
    .auto_in_0_a_bits_user_needHint           (inner_busPMU_auto_out_0_a_bits_user_needHint),
    .auto_in_0_a_bits_echo_isKeyword          (inner_busPMU_auto_out_0_a_bits_echo_isKeyword),
    .auto_in_0_a_bits_mask                    (inner_busPMU_auto_out_0_a_bits_mask),
    .auto_in_0_a_bits_data                    (inner_busPMU_auto_out_0_a_bits_data),
    .auto_in_0_a_bits_corrupt                 (inner_busPMU_auto_out_0_a_bits_corrupt),
    .auto_in_0_b_ready                        (inner_busPMU_auto_out_0_b_ready),
    .auto_in_0_b_valid                        (inner_xbar_auto_in_0_b_valid),
    .auto_in_0_b_bits_opcode                  (inner_xbar_auto_in_0_b_bits_opcode),
    .auto_in_0_b_bits_param                   (inner_xbar_auto_in_0_b_bits_param),
    .auto_in_0_b_bits_size                    (inner_xbar_auto_in_0_b_bits_size),
    .auto_in_0_b_bits_source                  (inner_xbar_auto_in_0_b_bits_source),
    .auto_in_0_b_bits_address                 (inner_xbar_auto_in_0_b_bits_address),
    .auto_in_0_b_bits_mask                    (inner_xbar_auto_in_0_b_bits_mask),
    .auto_in_0_b_bits_data                    (inner_xbar_auto_in_0_b_bits_data),
    .auto_in_0_b_bits_corrupt                 (inner_xbar_auto_in_0_b_bits_corrupt),
    .auto_in_0_c_ready                        (inner_xbar_auto_in_0_c_ready),
    .auto_in_0_c_valid                        (inner_busPMU_auto_out_0_c_valid),
    .auto_in_0_c_bits_opcode                  (inner_busPMU_auto_out_0_c_bits_opcode),
    .auto_in_0_c_bits_param                   (inner_busPMU_auto_out_0_c_bits_param),
    .auto_in_0_c_bits_size                    (inner_busPMU_auto_out_0_c_bits_size),
    .auto_in_0_c_bits_source                  (inner_busPMU_auto_out_0_c_bits_source),
    .auto_in_0_c_bits_address                 (inner_busPMU_auto_out_0_c_bits_address),
    .auto_in_0_c_bits_user_alias              (inner_busPMU_auto_out_0_c_bits_user_alias),
    .auto_in_0_c_bits_user_vaddr              (inner_busPMU_auto_out_0_c_bits_user_vaddr),
    .auto_in_0_c_bits_user_reqSource          (inner_busPMU_auto_out_0_c_bits_user_reqSource),
    .auto_in_0_c_bits_user_needHint           (inner_busPMU_auto_out_0_c_bits_user_needHint),
    .auto_in_0_c_bits_echo_isKeyword          (inner_busPMU_auto_out_0_c_bits_echo_isKeyword),
    .auto_in_0_c_bits_data                    (inner_busPMU_auto_out_0_c_bits_data),
    .auto_in_0_c_bits_corrupt                 (inner_busPMU_auto_out_0_c_bits_corrupt),
    .auto_in_0_d_ready                        (inner_busPMU_auto_out_0_d_ready),
    .auto_in_0_d_valid                        (inner_xbar_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode                  (inner_xbar_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param                   (inner_xbar_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size                    (inner_xbar_auto_in_0_d_bits_size),
    .auto_in_0_d_bits_source                  (inner_xbar_auto_in_0_d_bits_source),
    .auto_in_0_d_bits_sink                    (inner_xbar_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied                  (inner_xbar_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_echo_isKeyword          (inner_xbar_auto_in_0_d_bits_echo_isKeyword),
    .auto_in_0_d_bits_data                    (inner_xbar_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt                 (inner_xbar_auto_in_0_d_bits_corrupt),
    .auto_in_0_e_ready                        (inner_xbar_auto_in_0_e_ready),
    .auto_in_0_e_valid                        (inner_busPMU_auto_out_0_e_valid),
    .auto_in_0_e_bits_sink                    (inner_busPMU_auto_out_0_e_bits_sink),
    .auto_out_3_a_ready                       (inner_buffer_auto_in_3_a_ready),
    .auto_out_3_a_valid                       (inner_xbar_auto_out_3_a_valid),
    .auto_out_3_a_bits_opcode                 (inner_xbar_auto_out_3_a_bits_opcode),
    .auto_out_3_a_bits_param                  (inner_xbar_auto_out_3_a_bits_param),
    .auto_out_3_a_bits_size                   (inner_xbar_auto_out_3_a_bits_size),
    .auto_out_3_a_bits_source                 (inner_xbar_auto_out_3_a_bits_source),
    .auto_out_3_a_bits_address                (inner_xbar_auto_out_3_a_bits_address),
    .auto_out_3_a_bits_user_reqSource         (inner_xbar_auto_out_3_a_bits_user_reqSource),
    .auto_out_3_a_bits_user_alias             (inner_xbar_auto_out_3_a_bits_user_alias),
    .auto_out_3_a_bits_user_vaddr             (inner_xbar_auto_out_3_a_bits_user_vaddr),
    .auto_out_3_a_bits_user_needHint          (inner_xbar_auto_out_3_a_bits_user_needHint),
    .auto_out_3_a_bits_echo_isKeyword         (inner_xbar_auto_out_3_a_bits_echo_isKeyword),
    .auto_out_3_a_bits_mask                   (inner_xbar_auto_out_3_a_bits_mask),
    .auto_out_3_a_bits_data                   (inner_xbar_auto_out_3_a_bits_data),
    .auto_out_3_a_bits_corrupt                (inner_xbar_auto_out_3_a_bits_corrupt),
    .auto_out_3_b_ready                       (inner_xbar_auto_out_3_b_ready),
    .auto_out_3_b_valid                       (inner_buffer_auto_in_3_b_valid),
    .auto_out_3_b_bits_opcode                 (inner_buffer_auto_in_3_b_bits_opcode),
    .auto_out_3_b_bits_param                  (inner_buffer_auto_in_3_b_bits_param),
    .auto_out_3_b_bits_size                   (inner_buffer_auto_in_3_b_bits_size),
    .auto_out_3_b_bits_source                 (inner_buffer_auto_in_3_b_bits_source),
    .auto_out_3_b_bits_address                (inner_buffer_auto_in_3_b_bits_address),
    .auto_out_3_b_bits_mask                   (inner_buffer_auto_in_3_b_bits_mask),
    .auto_out_3_b_bits_data                   (inner_buffer_auto_in_3_b_bits_data),
    .auto_out_3_b_bits_corrupt                (inner_buffer_auto_in_3_b_bits_corrupt),
    .auto_out_3_c_ready                       (inner_buffer_auto_in_3_c_ready),
    .auto_out_3_c_valid                       (inner_xbar_auto_out_3_c_valid),
    .auto_out_3_c_bits_opcode                 (inner_xbar_auto_out_3_c_bits_opcode),
    .auto_out_3_c_bits_param                  (inner_xbar_auto_out_3_c_bits_param),
    .auto_out_3_c_bits_size                   (inner_xbar_auto_out_3_c_bits_size),
    .auto_out_3_c_bits_source                 (inner_xbar_auto_out_3_c_bits_source),
    .auto_out_3_c_bits_address                (inner_xbar_auto_out_3_c_bits_address),
    .auto_out_3_c_bits_user_reqSource         (inner_xbar_auto_out_3_c_bits_user_reqSource),
    .auto_out_3_c_bits_user_alias             (inner_xbar_auto_out_3_c_bits_user_alias),
    .auto_out_3_c_bits_user_vaddr             (inner_xbar_auto_out_3_c_bits_user_vaddr),
    .auto_out_3_c_bits_user_needHint          (inner_xbar_auto_out_3_c_bits_user_needHint),
    .auto_out_3_c_bits_echo_isKeyword         (inner_xbar_auto_out_3_c_bits_echo_isKeyword),
    .auto_out_3_c_bits_data                   (inner_xbar_auto_out_3_c_bits_data),
    .auto_out_3_c_bits_corrupt                (inner_xbar_auto_out_3_c_bits_corrupt),
    .auto_out_3_d_ready                       (inner_xbar_auto_out_3_d_ready),
    .auto_out_3_d_valid                       (inner_buffer_auto_in_3_d_valid),
    .auto_out_3_d_bits_opcode                 (inner_buffer_auto_in_3_d_bits_opcode),
    .auto_out_3_d_bits_param                  (inner_buffer_auto_in_3_d_bits_param),
    .auto_out_3_d_bits_size                   (inner_buffer_auto_in_3_d_bits_size),
    .auto_out_3_d_bits_source                 (inner_buffer_auto_in_3_d_bits_source),
    .auto_out_3_d_bits_sink                   (inner_buffer_auto_in_3_d_bits_sink),
    .auto_out_3_d_bits_denied                 (inner_buffer_auto_in_3_d_bits_denied),
    .auto_out_3_d_bits_echo_isKeyword         (inner_buffer_auto_in_3_d_bits_echo_isKeyword),
    .auto_out_3_d_bits_data                   (inner_buffer_auto_in_3_d_bits_data),
    .auto_out_3_d_bits_corrupt                (inner_buffer_auto_in_3_d_bits_corrupt),
    .auto_out_3_e_ready                       (inner_buffer_auto_in_3_e_ready),
    .auto_out_3_e_valid                       (inner_xbar_auto_out_3_e_valid),
    .auto_out_3_e_bits_sink                   (inner_xbar_auto_out_3_e_bits_sink),
    .auto_out_2_a_ready                       (inner_buffer_auto_in_2_a_ready),
    .auto_out_2_a_valid                       (inner_xbar_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode                 (inner_xbar_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param                  (inner_xbar_auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size                   (inner_xbar_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source                 (inner_xbar_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address                (inner_xbar_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_user_reqSource         (inner_xbar_auto_out_2_a_bits_user_reqSource),
    .auto_out_2_a_bits_user_alias             (inner_xbar_auto_out_2_a_bits_user_alias),
    .auto_out_2_a_bits_user_vaddr             (inner_xbar_auto_out_2_a_bits_user_vaddr),
    .auto_out_2_a_bits_user_needHint          (inner_xbar_auto_out_2_a_bits_user_needHint),
    .auto_out_2_a_bits_echo_isKeyword         (inner_xbar_auto_out_2_a_bits_echo_isKeyword),
    .auto_out_2_a_bits_mask                   (inner_xbar_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data                   (inner_xbar_auto_out_2_a_bits_data),
    .auto_out_2_a_bits_corrupt                (inner_xbar_auto_out_2_a_bits_corrupt),
    .auto_out_2_b_ready                       (inner_xbar_auto_out_2_b_ready),
    .auto_out_2_b_valid                       (inner_buffer_auto_in_2_b_valid),
    .auto_out_2_b_bits_opcode                 (inner_buffer_auto_in_2_b_bits_opcode),
    .auto_out_2_b_bits_param                  (inner_buffer_auto_in_2_b_bits_param),
    .auto_out_2_b_bits_size                   (inner_buffer_auto_in_2_b_bits_size),
    .auto_out_2_b_bits_source                 (inner_buffer_auto_in_2_b_bits_source),
    .auto_out_2_b_bits_address                (inner_buffer_auto_in_2_b_bits_address),
    .auto_out_2_b_bits_mask                   (inner_buffer_auto_in_2_b_bits_mask),
    .auto_out_2_b_bits_data                   (inner_buffer_auto_in_2_b_bits_data),
    .auto_out_2_b_bits_corrupt                (inner_buffer_auto_in_2_b_bits_corrupt),
    .auto_out_2_c_ready                       (inner_buffer_auto_in_2_c_ready),
    .auto_out_2_c_valid                       (inner_xbar_auto_out_2_c_valid),
    .auto_out_2_c_bits_opcode                 (inner_xbar_auto_out_2_c_bits_opcode),
    .auto_out_2_c_bits_param                  (inner_xbar_auto_out_2_c_bits_param),
    .auto_out_2_c_bits_size                   (inner_xbar_auto_out_2_c_bits_size),
    .auto_out_2_c_bits_source                 (inner_xbar_auto_out_2_c_bits_source),
    .auto_out_2_c_bits_address                (inner_xbar_auto_out_2_c_bits_address),
    .auto_out_2_c_bits_user_reqSource         (inner_xbar_auto_out_2_c_bits_user_reqSource),
    .auto_out_2_c_bits_user_alias             (inner_xbar_auto_out_2_c_bits_user_alias),
    .auto_out_2_c_bits_user_vaddr             (inner_xbar_auto_out_2_c_bits_user_vaddr),
    .auto_out_2_c_bits_user_needHint          (inner_xbar_auto_out_2_c_bits_user_needHint),
    .auto_out_2_c_bits_echo_isKeyword         (inner_xbar_auto_out_2_c_bits_echo_isKeyword),
    .auto_out_2_c_bits_data                   (inner_xbar_auto_out_2_c_bits_data),
    .auto_out_2_c_bits_corrupt                (inner_xbar_auto_out_2_c_bits_corrupt),
    .auto_out_2_d_ready                       (inner_xbar_auto_out_2_d_ready),
    .auto_out_2_d_valid                       (inner_buffer_auto_in_2_d_valid),
    .auto_out_2_d_bits_opcode                 (inner_buffer_auto_in_2_d_bits_opcode),
    .auto_out_2_d_bits_param                  (inner_buffer_auto_in_2_d_bits_param),
    .auto_out_2_d_bits_size                   (inner_buffer_auto_in_2_d_bits_size),
    .auto_out_2_d_bits_source                 (inner_buffer_auto_in_2_d_bits_source),
    .auto_out_2_d_bits_sink                   (inner_buffer_auto_in_2_d_bits_sink),
    .auto_out_2_d_bits_denied                 (inner_buffer_auto_in_2_d_bits_denied),
    .auto_out_2_d_bits_echo_isKeyword         (inner_buffer_auto_in_2_d_bits_echo_isKeyword),
    .auto_out_2_d_bits_data                   (inner_buffer_auto_in_2_d_bits_data),
    .auto_out_2_d_bits_corrupt                (inner_buffer_auto_in_2_d_bits_corrupt),
    .auto_out_2_e_ready                       (inner_buffer_auto_in_2_e_ready),
    .auto_out_2_e_valid                       (inner_xbar_auto_out_2_e_valid),
    .auto_out_2_e_bits_sink                   (inner_xbar_auto_out_2_e_bits_sink),
    .auto_out_1_a_ready                       (inner_buffer_auto_in_1_a_ready),
    .auto_out_1_a_valid                       (inner_xbar_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode                 (inner_xbar_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param                  (inner_xbar_auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size                   (inner_xbar_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source                 (inner_xbar_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address                (inner_xbar_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_user_reqSource         (inner_xbar_auto_out_1_a_bits_user_reqSource),
    .auto_out_1_a_bits_user_alias             (inner_xbar_auto_out_1_a_bits_user_alias),
    .auto_out_1_a_bits_user_vaddr             (inner_xbar_auto_out_1_a_bits_user_vaddr),
    .auto_out_1_a_bits_user_needHint          (inner_xbar_auto_out_1_a_bits_user_needHint),
    .auto_out_1_a_bits_echo_isKeyword         (inner_xbar_auto_out_1_a_bits_echo_isKeyword),
    .auto_out_1_a_bits_mask                   (inner_xbar_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data                   (inner_xbar_auto_out_1_a_bits_data),
    .auto_out_1_a_bits_corrupt                (inner_xbar_auto_out_1_a_bits_corrupt),
    .auto_out_1_b_ready                       (inner_xbar_auto_out_1_b_ready),
    .auto_out_1_b_valid                       (inner_buffer_auto_in_1_b_valid),
    .auto_out_1_b_bits_opcode                 (inner_buffer_auto_in_1_b_bits_opcode),
    .auto_out_1_b_bits_param                  (inner_buffer_auto_in_1_b_bits_param),
    .auto_out_1_b_bits_size                   (inner_buffer_auto_in_1_b_bits_size),
    .auto_out_1_b_bits_source                 (inner_buffer_auto_in_1_b_bits_source),
    .auto_out_1_b_bits_address                (inner_buffer_auto_in_1_b_bits_address),
    .auto_out_1_b_bits_mask                   (inner_buffer_auto_in_1_b_bits_mask),
    .auto_out_1_b_bits_data                   (inner_buffer_auto_in_1_b_bits_data),
    .auto_out_1_b_bits_corrupt                (inner_buffer_auto_in_1_b_bits_corrupt),
    .auto_out_1_c_ready                       (inner_buffer_auto_in_1_c_ready),
    .auto_out_1_c_valid                       (inner_xbar_auto_out_1_c_valid),
    .auto_out_1_c_bits_opcode                 (inner_xbar_auto_out_1_c_bits_opcode),
    .auto_out_1_c_bits_param                  (inner_xbar_auto_out_1_c_bits_param),
    .auto_out_1_c_bits_size                   (inner_xbar_auto_out_1_c_bits_size),
    .auto_out_1_c_bits_source                 (inner_xbar_auto_out_1_c_bits_source),
    .auto_out_1_c_bits_address                (inner_xbar_auto_out_1_c_bits_address),
    .auto_out_1_c_bits_user_reqSource         (inner_xbar_auto_out_1_c_bits_user_reqSource),
    .auto_out_1_c_bits_user_alias             (inner_xbar_auto_out_1_c_bits_user_alias),
    .auto_out_1_c_bits_user_vaddr             (inner_xbar_auto_out_1_c_bits_user_vaddr),
    .auto_out_1_c_bits_user_needHint          (inner_xbar_auto_out_1_c_bits_user_needHint),
    .auto_out_1_c_bits_echo_isKeyword         (inner_xbar_auto_out_1_c_bits_echo_isKeyword),
    .auto_out_1_c_bits_data                   (inner_xbar_auto_out_1_c_bits_data),
    .auto_out_1_c_bits_corrupt                (inner_xbar_auto_out_1_c_bits_corrupt),
    .auto_out_1_d_ready                       (inner_xbar_auto_out_1_d_ready),
    .auto_out_1_d_valid                       (inner_buffer_auto_in_1_d_valid),
    .auto_out_1_d_bits_opcode                 (inner_buffer_auto_in_1_d_bits_opcode),
    .auto_out_1_d_bits_param                  (inner_buffer_auto_in_1_d_bits_param),
    .auto_out_1_d_bits_size                   (inner_buffer_auto_in_1_d_bits_size),
    .auto_out_1_d_bits_source                 (inner_buffer_auto_in_1_d_bits_source),
    .auto_out_1_d_bits_sink                   (inner_buffer_auto_in_1_d_bits_sink),
    .auto_out_1_d_bits_denied                 (inner_buffer_auto_in_1_d_bits_denied),
    .auto_out_1_d_bits_echo_isKeyword         (inner_buffer_auto_in_1_d_bits_echo_isKeyword),
    .auto_out_1_d_bits_data                   (inner_buffer_auto_in_1_d_bits_data),
    .auto_out_1_d_bits_corrupt                (inner_buffer_auto_in_1_d_bits_corrupt),
    .auto_out_1_e_ready                       (inner_buffer_auto_in_1_e_ready),
    .auto_out_1_e_valid                       (inner_xbar_auto_out_1_e_valid),
    .auto_out_1_e_bits_sink                   (inner_xbar_auto_out_1_e_bits_sink),
    .auto_out_0_a_ready                       (inner_buffer_auto_in_0_a_ready),
    .auto_out_0_a_valid                       (inner_xbar_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode                 (inner_xbar_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param                  (inner_xbar_auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size                   (inner_xbar_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source                 (inner_xbar_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address                (inner_xbar_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_user_reqSource         (inner_xbar_auto_out_0_a_bits_user_reqSource),
    .auto_out_0_a_bits_user_alias             (inner_xbar_auto_out_0_a_bits_user_alias),
    .auto_out_0_a_bits_user_vaddr             (inner_xbar_auto_out_0_a_bits_user_vaddr),
    .auto_out_0_a_bits_user_needHint          (inner_xbar_auto_out_0_a_bits_user_needHint),
    .auto_out_0_a_bits_echo_isKeyword         (inner_xbar_auto_out_0_a_bits_echo_isKeyword),
    .auto_out_0_a_bits_mask                   (inner_xbar_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data                   (inner_xbar_auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt                (inner_xbar_auto_out_0_a_bits_corrupt),
    .auto_out_0_b_ready                       (inner_xbar_auto_out_0_b_ready),
    .auto_out_0_b_valid                       (inner_buffer_auto_in_0_b_valid),
    .auto_out_0_b_bits_opcode                 (inner_buffer_auto_in_0_b_bits_opcode),
    .auto_out_0_b_bits_param                  (inner_buffer_auto_in_0_b_bits_param),
    .auto_out_0_b_bits_size                   (inner_buffer_auto_in_0_b_bits_size),
    .auto_out_0_b_bits_source                 (inner_buffer_auto_in_0_b_bits_source),
    .auto_out_0_b_bits_address                (inner_buffer_auto_in_0_b_bits_address),
    .auto_out_0_b_bits_mask                   (inner_buffer_auto_in_0_b_bits_mask),
    .auto_out_0_b_bits_data                   (inner_buffer_auto_in_0_b_bits_data),
    .auto_out_0_b_bits_corrupt                (inner_buffer_auto_in_0_b_bits_corrupt),
    .auto_out_0_c_ready                       (inner_buffer_auto_in_0_c_ready),
    .auto_out_0_c_valid                       (inner_xbar_auto_out_0_c_valid),
    .auto_out_0_c_bits_opcode                 (inner_xbar_auto_out_0_c_bits_opcode),
    .auto_out_0_c_bits_param                  (inner_xbar_auto_out_0_c_bits_param),
    .auto_out_0_c_bits_size                   (inner_xbar_auto_out_0_c_bits_size),
    .auto_out_0_c_bits_source                 (inner_xbar_auto_out_0_c_bits_source),
    .auto_out_0_c_bits_address                (inner_xbar_auto_out_0_c_bits_address),
    .auto_out_0_c_bits_user_reqSource         (inner_xbar_auto_out_0_c_bits_user_reqSource),
    .auto_out_0_c_bits_user_alias             (inner_xbar_auto_out_0_c_bits_user_alias),
    .auto_out_0_c_bits_user_vaddr             (inner_xbar_auto_out_0_c_bits_user_vaddr),
    .auto_out_0_c_bits_user_needHint          (inner_xbar_auto_out_0_c_bits_user_needHint),
    .auto_out_0_c_bits_echo_isKeyword         (inner_xbar_auto_out_0_c_bits_echo_isKeyword),
    .auto_out_0_c_bits_data                   (inner_xbar_auto_out_0_c_bits_data),
    .auto_out_0_c_bits_corrupt                (inner_xbar_auto_out_0_c_bits_corrupt),
    .auto_out_0_d_ready                       (inner_xbar_auto_out_0_d_ready),
    .auto_out_0_d_valid                       (inner_buffer_auto_in_0_d_valid),
    .auto_out_0_d_bits_opcode                 (inner_buffer_auto_in_0_d_bits_opcode),
    .auto_out_0_d_bits_param                  (inner_buffer_auto_in_0_d_bits_param),
    .auto_out_0_d_bits_size                   (inner_buffer_auto_in_0_d_bits_size),
    .auto_out_0_d_bits_source                 (inner_buffer_auto_in_0_d_bits_source),
    .auto_out_0_d_bits_sink                   (inner_buffer_auto_in_0_d_bits_sink),
    .auto_out_0_d_bits_denied                 (inner_buffer_auto_in_0_d_bits_denied),
    .auto_out_0_d_bits_echo_isKeyword         (inner_buffer_auto_in_0_d_bits_echo_isKeyword),
    .auto_out_0_d_bits_data                   (inner_buffer_auto_in_0_d_bits_data),
    .auto_out_0_d_bits_corrupt                (inner_buffer_auto_in_0_d_bits_corrupt),
    .auto_out_0_e_ready                       (inner_buffer_auto_in_0_e_ready),
    .auto_out_0_e_valid                       (inner_xbar_auto_out_0_e_valid),
    .auto_out_0_e_bits_sink                   (inner_xbar_auto_out_0_e_bits_sink)
  );
  TLXbar_6 inner_xbar_1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_1_a_ready                        (inner_xbar_1_auto_in_1_a_ready),
    .auto_in_1_a_valid                        (inner_buffers_2_auto_out_a_valid),
    .auto_in_1_a_bits_opcode                  (inner_buffers_2_auto_out_a_bits_opcode),
    .auto_in_1_a_bits_param                   (inner_buffers_2_auto_out_a_bits_param),
    .auto_in_1_a_bits_size                    (inner_buffers_2_auto_out_a_bits_size),
    .auto_in_1_a_bits_source                  (inner_buffers_2_auto_out_a_bits_source),
    .auto_in_1_a_bits_address                 (inner_buffers_2_auto_out_a_bits_address),
    .auto_in_1_a_bits_user_memBackType_MM     (inner_buffers_2_auto_out_a_bits_user_memPageType_NC),
    .auto_in_1_a_bits_user_memPageType_NC     (inner_buffers_2_auto_out_a_bits_user_memBackType_MM),
    .auto_in_1_a_bits_mask                    (inner_buffers_2_auto_out_a_bits_mask),
    .auto_in_1_a_bits_data                    (inner_buffers_2_auto_out_a_bits_data),
    .auto_in_1_a_bits_corrupt                 (inner_buffers_2_auto_out_a_bits_corrupt),
    .auto_in_1_d_ready                        (inner_buffers_2_auto_out_d_ready),
    .auto_in_1_d_valid                        (inner_xbar_1_auto_in_1_d_valid),
    .auto_in_1_d_bits_opcode                  (inner_xbar_1_auto_in_1_d_bits_opcode),
    .auto_in_1_d_bits_param                   (inner_xbar_1_auto_in_1_d_bits_param),
    .auto_in_1_d_bits_size                    (inner_xbar_1_auto_in_1_d_bits_size),
    .auto_in_1_d_bits_source                  (inner_xbar_1_auto_in_1_d_bits_source),
    .auto_in_1_d_bits_sink                    (inner_xbar_1_auto_in_1_d_bits_sink),
    .auto_in_1_d_bits_denied                  (inner_xbar_1_auto_in_1_d_bits_denied),
    .auto_in_1_d_bits_data                    (inner_xbar_1_auto_in_1_d_bits_data),
    .auto_in_1_d_bits_corrupt                 (inner_xbar_1_auto_in_1_d_bits_corrupt),
    .auto_in_0_a_ready                        (inner_xbar_1_auto_in_0_a_ready),
    .auto_in_0_a_valid                        (inner_buffers_auto_out_a_valid),
    .auto_in_0_a_bits_opcode                  (inner_buffers_auto_out_a_bits_opcode),
    .auto_in_0_a_bits_param                   (inner_buffers_auto_out_a_bits_param),
    .auto_in_0_a_bits_size                    (inner_buffers_auto_out_a_bits_size),
    .auto_in_0_a_bits_source                  (inner_buffers_auto_out_a_bits_source),
    .auto_in_0_a_bits_address                 (inner_buffers_auto_out_a_bits_address),
    .auto_in_0_a_bits_user_memPageType_NC     (inner_buffers_auto_out_a_bits_user_memPageType_NC),
    .auto_in_0_a_bits_user_memBackType_MM     (inner_buffers_auto_out_a_bits_user_memBackType_MM),
    .auto_in_0_a_bits_mask                    (inner_buffers_auto_out_a_bits_mask),
    .auto_in_0_a_bits_data                    (inner_buffers_auto_out_a_bits_data),
    .auto_in_0_a_bits_corrupt                 (inner_buffers_auto_out_a_bits_corrupt),
    .auto_in_0_d_ready                        (inner_buffers_auto_out_d_ready),
    .auto_in_0_d_valid                        (inner_xbar_1_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode                  (inner_xbar_1_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param                   (inner_xbar_1_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size                    (inner_xbar_1_auto_in_0_d_bits_size),
    .auto_in_0_d_bits_sink                    (inner_xbar_1_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied                  (inner_xbar_1_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_data                    (inner_xbar_1_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt                 (inner_xbar_1_auto_in_0_d_bits_corrupt),
    .auto_out_2_a_ready                       (inner_buffer_1_auto_in_a_ready),
    .auto_out_2_a_valid                       (inner_xbar_1_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode                 (inner_xbar_1_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param                  (inner_xbar_1_auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size                   (inner_xbar_1_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source                 (inner_xbar_1_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address                (inner_xbar_1_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_user_memBackType_MM    (inner_xbar_1_auto_out_2_a_bits_user_memBackType_MM),
    .auto_out_2_a_bits_user_memPageType_NC    (inner_xbar_1_auto_out_2_a_bits_user_memPageType_NC),
    .auto_out_2_a_bits_mask                   (inner_xbar_1_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data                   (inner_xbar_1_auto_out_2_a_bits_data),
    .auto_out_2_a_bits_corrupt                (inner_xbar_1_auto_out_2_a_bits_corrupt),
    .auto_out_2_d_ready                       (inner_xbar_1_auto_out_2_d_ready),
    .auto_out_2_d_valid                       (inner_buffer_1_auto_in_d_valid),
    .auto_out_2_d_bits_opcode                 (inner_buffer_1_auto_in_d_bits_opcode),
    .auto_out_2_d_bits_param                  (inner_buffer_1_auto_in_d_bits_param),
    .auto_out_2_d_bits_size                   (inner_buffer_1_auto_in_d_bits_size),
    .auto_out_2_d_bits_source                 (inner_buffer_1_auto_in_d_bits_source),
    .auto_out_2_d_bits_sink                   (inner_buffer_1_auto_in_d_bits_sink),
    .auto_out_2_d_bits_denied                 (inner_buffer_1_auto_in_d_bits_denied),
    .auto_out_2_d_bits_data                   (inner_buffer_1_auto_in_d_bits_data),
    .auto_out_2_d_bits_corrupt                (inner_buffer_1_auto_in_d_bits_corrupt),
    .auto_out_1_a_ready                       (inner_buffers_5_auto_in_a_ready),
    .auto_out_1_a_valid                       (inner_xbar_1_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode                 (inner_xbar_1_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param                  (inner_xbar_1_auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size                   (inner_xbar_1_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source                 (inner_xbar_1_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address                (inner_xbar_1_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_mask                   (inner_xbar_1_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data                   (inner_xbar_1_auto_out_1_a_bits_data),
    .auto_out_1_a_bits_corrupt                (inner_xbar_1_auto_out_1_a_bits_corrupt),
    .auto_out_1_d_ready                       (inner_xbar_1_auto_out_1_d_ready),
    .auto_out_1_d_valid                       (inner_buffers_5_auto_in_d_valid),
    .auto_out_1_d_bits_opcode                 (inner_buffers_5_auto_in_d_bits_opcode),
    .auto_out_1_d_bits_param                  (inner_buffers_5_auto_in_d_bits_param),
    .auto_out_1_d_bits_size                   (inner_buffers_5_auto_in_d_bits_size),
    .auto_out_1_d_bits_source                 (inner_buffers_5_auto_in_d_bits_source),
    .auto_out_1_d_bits_sink                   (inner_buffers_5_auto_in_d_bits_sink),
    .auto_out_1_d_bits_denied                 (inner_buffers_5_auto_in_d_bits_denied),
    .auto_out_1_d_bits_data                   (inner_buffers_5_auto_in_d_bits_data),
    .auto_out_1_d_bits_corrupt                (inner_buffers_5_auto_in_d_bits_corrupt),
    .auto_out_0_a_ready                       (inner_buffers_4_auto_in_a_ready),
    .auto_out_0_a_valid                       (inner_xbar_1_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode                 (inner_xbar_1_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param                  (inner_xbar_1_auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size                   (inner_xbar_1_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source                 (inner_xbar_1_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address                (inner_xbar_1_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_mask                   (inner_xbar_1_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data                   (inner_xbar_1_auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt                (inner_xbar_1_auto_out_0_a_bits_corrupt),
    .auto_out_0_d_ready                       (inner_xbar_1_auto_out_0_d_ready),
    .auto_out_0_d_valid                       (inner_buffers_4_auto_in_d_valid),
    .auto_out_0_d_bits_opcode                 (inner_buffers_4_auto_in_d_bits_opcode),
    .auto_out_0_d_bits_param                  (inner_buffers_4_auto_in_d_bits_param),
    .auto_out_0_d_bits_size                   (inner_buffers_4_auto_in_d_bits_size),
    .auto_out_0_d_bits_source                 (inner_buffers_4_auto_in_d_bits_source),
    .auto_out_0_d_bits_sink                   (inner_buffers_4_auto_in_d_bits_sink),
    .auto_out_0_d_bits_denied                 (inner_buffers_4_auto_in_d_bits_denied),
    .auto_out_0_d_bits_data                   (inner_buffers_4_auto_in_d_bits_data),
    .auto_out_0_d_bits_corrupt                (inner_buffers_4_auto_in_d_bits_corrupt)
  );
  BusErrorUnit inner_beu (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_a_ready                          (inner_beu_auto_in_a_ready),
    .auto_in_a_valid                          (inner_buffers_4_auto_out_a_valid),
    .auto_in_a_bits_opcode                    (inner_buffers_4_auto_out_a_bits_opcode),
    .auto_in_a_bits_size                      (inner_buffers_4_auto_out_a_bits_size),
    .auto_in_a_bits_source                    (inner_buffers_4_auto_out_a_bits_source),
    .auto_in_a_bits_address                   (inner_buffers_4_auto_out_a_bits_address),
    .auto_in_a_bits_mask                      (inner_buffers_4_auto_out_a_bits_mask),
    .auto_in_a_bits_data                      (inner_buffers_4_auto_out_a_bits_data),
    .auto_in_d_ready                          (inner_buffers_4_auto_out_d_ready),
    .auto_in_d_valid                          (inner_beu_auto_in_d_valid),
    .auto_in_d_bits_opcode                    (inner_beu_auto_in_d_bits_opcode),
    .auto_in_d_bits_size                      (inner_beu_auto_in_d_bits_size),
    .auto_in_d_bits_source                    (inner_beu_auto_in_d_bits_source),
    .auto_in_d_bits_data                      (inner_beu_auto_in_d_bits_data),
    .auto_int_out_0                           (auto_inner_beu_int_out_0),
    .io_errors_icache_ecc_error_valid         (io_beu_errors_icache_ecc_error_valid),
    .io_errors_icache_ecc_error_bits          (io_beu_errors_icache_ecc_error_bits),
    .io_errors_dcache_ecc_error_valid         (io_beu_errors_dcache_ecc_error_valid),
    .io_errors_dcache_ecc_error_bits          (io_beu_errors_dcache_ecc_error_bits),
    .io_errors_uncache_ecc_error_valid        (io_beu_errors_uncache_ecc_error_valid),
    .io_errors_uncache_ecc_error_bits         (io_beu_errors_uncache_ecc_error_bits),
    .io_errors_l2_ecc_error_valid             (inner_l2cache_io_error_valid),
    .io_errors_l2_ecc_error_bits              (beuL2ErrorAddr),
    .io_interrupt                             (inner_beu_io_interrupt)
  );
  BusPerfMonitor inner_busPMU (
    .auto_in_2_a_ready                        (inner_busPMU_auto_in_2_a_ready),
    .auto_in_2_a_valid                        (inner_logger_2_auto_out_a_valid),
    .auto_in_2_a_bits_opcode                  (inner_logger_2_auto_out_a_bits_opcode),
    .auto_in_2_a_bits_param                   (inner_logger_2_auto_out_a_bits_param),
    .auto_in_2_a_bits_size                    (inner_logger_2_auto_out_a_bits_size),
    .auto_in_2_a_bits_source                  (inner_logger_2_auto_out_a_bits_source),
    .auto_in_2_a_bits_address                 (inner_logger_2_auto_out_a_bits_address),
    .auto_in_2_a_bits_user_reqSource          (inner_logger_2_auto_out_a_bits_user_reqSource),
    .auto_in_2_a_bits_mask                    (inner_logger_2_auto_out_a_bits_mask),
    .auto_in_2_a_bits_data                    (inner_logger_2_auto_out_a_bits_data),
    .auto_in_2_a_bits_corrupt                 (inner_logger_2_auto_out_a_bits_corrupt),
    .auto_in_2_d_ready                        (inner_logger_2_auto_out_d_ready),
    .auto_in_2_d_valid                        (inner_busPMU_auto_in_2_d_valid),
    .auto_in_2_d_bits_opcode                  (inner_busPMU_auto_in_2_d_bits_opcode),
    .auto_in_2_d_bits_param                   (inner_busPMU_auto_in_2_d_bits_param),
    .auto_in_2_d_bits_size                    (inner_busPMU_auto_in_2_d_bits_size),
    .auto_in_2_d_bits_source                  (inner_busPMU_auto_in_2_d_bits_source),
    .auto_in_2_d_bits_sink                    (inner_busPMU_auto_in_2_d_bits_sink),
    .auto_in_2_d_bits_denied                  (inner_busPMU_auto_in_2_d_bits_denied),
    .auto_in_2_d_bits_data                    (inner_busPMU_auto_in_2_d_bits_data),
    .auto_in_2_d_bits_corrupt                 (inner_busPMU_auto_in_2_d_bits_corrupt),
    .auto_in_1_a_ready                        (inner_busPMU_auto_in_1_a_ready),
    .auto_in_1_a_valid                        (inner_logger_1_auto_out_a_valid),
    .auto_in_1_a_bits_opcode                  (inner_logger_1_auto_out_a_bits_opcode),
    .auto_in_1_a_bits_param                   (inner_logger_1_auto_out_a_bits_param),
    .auto_in_1_a_bits_size                    (inner_logger_1_auto_out_a_bits_size),
    .auto_in_1_a_bits_source                  (inner_logger_1_auto_out_a_bits_source),
    .auto_in_1_a_bits_address                 (inner_logger_1_auto_out_a_bits_address),
    .auto_in_1_a_bits_user_alias              (inner_logger_1_auto_out_a_bits_user_alias),
    .auto_in_1_a_bits_user_reqSource          (inner_logger_1_auto_out_a_bits_user_reqSource),
    .auto_in_1_a_bits_user_needHint           (inner_logger_1_auto_out_a_bits_user_needHint),
    .auto_in_1_a_bits_mask                    (inner_logger_1_auto_out_a_bits_mask),
    .auto_in_1_a_bits_data                    (inner_logger_1_auto_out_a_bits_data),
    .auto_in_1_a_bits_corrupt                 (inner_logger_1_auto_out_a_bits_corrupt),
    .auto_in_1_d_ready                        (inner_logger_1_auto_out_d_ready),
    .auto_in_1_d_valid                        (inner_busPMU_auto_in_1_d_valid),
    .auto_in_1_d_bits_opcode                  (inner_busPMU_auto_in_1_d_bits_opcode),
    .auto_in_1_d_bits_param                   (inner_busPMU_auto_in_1_d_bits_param),
    .auto_in_1_d_bits_size                    (inner_busPMU_auto_in_1_d_bits_size),
    .auto_in_1_d_bits_source                  (inner_busPMU_auto_in_1_d_bits_source),
    .auto_in_1_d_bits_sink                    (inner_busPMU_auto_in_1_d_bits_sink),
    .auto_in_1_d_bits_denied                  (inner_busPMU_auto_in_1_d_bits_denied),
    .auto_in_1_d_bits_data                    (inner_busPMU_auto_in_1_d_bits_data),
    .auto_in_1_d_bits_corrupt                 (inner_busPMU_auto_in_1_d_bits_corrupt),
    .auto_in_0_a_ready                        (inner_busPMU_auto_in_0_a_ready),
    .auto_in_0_a_valid                        (inner_logger_auto_out_a_valid),
    .auto_in_0_a_bits_opcode                  (inner_logger_auto_out_a_bits_opcode),
    .auto_in_0_a_bits_param                   (inner_logger_auto_out_a_bits_param),
    .auto_in_0_a_bits_size                    (inner_logger_auto_out_a_bits_size),
    .auto_in_0_a_bits_source                  (inner_logger_auto_out_a_bits_source),
    .auto_in_0_a_bits_address                 (inner_logger_auto_out_a_bits_address),
    .auto_in_0_a_bits_user_alias              (inner_logger_auto_out_a_bits_user_alias),
    .auto_in_0_a_bits_user_vaddr              (inner_logger_auto_out_a_bits_user_vaddr),
    .auto_in_0_a_bits_user_reqSource          (inner_logger_auto_out_a_bits_user_reqSource),
    .auto_in_0_a_bits_user_needHint           (inner_logger_auto_out_a_bits_user_needHint),
    .auto_in_0_a_bits_echo_isKeyword          (inner_logger_auto_out_a_bits_echo_isKeyword),
    .auto_in_0_a_bits_mask                    (inner_logger_auto_out_a_bits_mask),
    .auto_in_0_a_bits_data                    (inner_logger_auto_out_a_bits_data),
    .auto_in_0_a_bits_corrupt                 (inner_logger_auto_out_a_bits_corrupt),
    .auto_in_0_b_ready                        (inner_logger_auto_out_b_ready),
    .auto_in_0_b_valid                        (inner_busPMU_auto_in_0_b_valid),
    .auto_in_0_b_bits_opcode                  (inner_busPMU_auto_in_0_b_bits_opcode),
    .auto_in_0_b_bits_param                   (inner_busPMU_auto_in_0_b_bits_param),
    .auto_in_0_b_bits_size                    (inner_busPMU_auto_in_0_b_bits_size),
    .auto_in_0_b_bits_source                  (inner_busPMU_auto_in_0_b_bits_source),
    .auto_in_0_b_bits_address                 (inner_busPMU_auto_in_0_b_bits_address),
    .auto_in_0_b_bits_mask                    (inner_busPMU_auto_in_0_b_bits_mask),
    .auto_in_0_b_bits_data                    (inner_busPMU_auto_in_0_b_bits_data),
    .auto_in_0_b_bits_corrupt                 (inner_busPMU_auto_in_0_b_bits_corrupt),
    .auto_in_0_c_ready                        (inner_busPMU_auto_in_0_c_ready),
    .auto_in_0_c_valid                        (inner_logger_auto_out_c_valid),
    .auto_in_0_c_bits_opcode                  (inner_logger_auto_out_c_bits_opcode),
    .auto_in_0_c_bits_param                   (inner_logger_auto_out_c_bits_param),
    .auto_in_0_c_bits_size                    (inner_logger_auto_out_c_bits_size),
    .auto_in_0_c_bits_source                  (inner_logger_auto_out_c_bits_source),
    .auto_in_0_c_bits_address                 (inner_logger_auto_out_c_bits_address),
    .auto_in_0_c_bits_user_alias              (inner_logger_auto_out_c_bits_user_alias),
    .auto_in_0_c_bits_user_vaddr              (inner_logger_auto_out_c_bits_user_vaddr),
    .auto_in_0_c_bits_user_reqSource          (inner_logger_auto_out_c_bits_user_reqSource),
    .auto_in_0_c_bits_user_needHint           (inner_logger_auto_out_c_bits_user_needHint),
    .auto_in_0_c_bits_echo_isKeyword          (inner_logger_auto_out_c_bits_echo_isKeyword),
    .auto_in_0_c_bits_data                    (inner_logger_auto_out_c_bits_data),
    .auto_in_0_c_bits_corrupt                 (inner_logger_auto_out_c_bits_corrupt),
    .auto_in_0_d_ready                        (inner_logger_auto_out_d_ready),
    .auto_in_0_d_valid                        (inner_busPMU_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode                  (inner_busPMU_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param                   (inner_busPMU_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size                    (inner_busPMU_auto_in_0_d_bits_size),
    .auto_in_0_d_bits_source                  (inner_busPMU_auto_in_0_d_bits_source),
    .auto_in_0_d_bits_sink                    (inner_busPMU_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied                  (inner_busPMU_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_echo_isKeyword          (inner_busPMU_auto_in_0_d_bits_echo_isKeyword),
    .auto_in_0_d_bits_data                    (inner_busPMU_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt                 (inner_busPMU_auto_in_0_d_bits_corrupt),
    .auto_in_0_e_ready                        (inner_busPMU_auto_in_0_e_ready),
    .auto_in_0_e_valid                        (inner_logger_auto_out_e_valid),
    .auto_in_0_e_bits_sink                    (inner_logger_auto_out_e_bits_sink),
    .auto_out_2_a_ready                       (inner_xbar_auto_in_2_a_ready),
    .auto_out_2_a_valid                       (inner_busPMU_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode                 (inner_busPMU_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param                  (inner_busPMU_auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size                   (inner_busPMU_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source                 (inner_busPMU_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address                (inner_busPMU_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_user_reqSource         (inner_busPMU_auto_out_2_a_bits_user_reqSource),
    .auto_out_2_a_bits_mask                   (inner_busPMU_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data                   (inner_busPMU_auto_out_2_a_bits_data),
    .auto_out_2_a_bits_corrupt                (inner_busPMU_auto_out_2_a_bits_corrupt),
    .auto_out_2_d_ready                       (inner_busPMU_auto_out_2_d_ready),
    .auto_out_2_d_valid                       (inner_xbar_auto_in_2_d_valid),
    .auto_out_2_d_bits_opcode                 (inner_xbar_auto_in_2_d_bits_opcode),
    .auto_out_2_d_bits_param                  (inner_xbar_auto_in_2_d_bits_param),
    .auto_out_2_d_bits_size                   (inner_xbar_auto_in_2_d_bits_size),
    .auto_out_2_d_bits_source                 (inner_xbar_auto_in_2_d_bits_source),
    .auto_out_2_d_bits_sink                   (inner_xbar_auto_in_2_d_bits_sink),
    .auto_out_2_d_bits_denied                 (inner_xbar_auto_in_2_d_bits_denied),
    .auto_out_2_d_bits_data                   (inner_xbar_auto_in_2_d_bits_data),
    .auto_out_2_d_bits_corrupt                (inner_xbar_auto_in_2_d_bits_corrupt),
    .auto_out_1_a_ready                       (inner_xbar_auto_in_1_a_ready),
    .auto_out_1_a_valid                       (inner_busPMU_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode                 (inner_busPMU_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param                  (inner_busPMU_auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size                   (inner_busPMU_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source                 (inner_busPMU_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address                (inner_busPMU_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_user_alias             (inner_busPMU_auto_out_1_a_bits_user_alias),
    .auto_out_1_a_bits_user_reqSource         (inner_busPMU_auto_out_1_a_bits_user_reqSource),
    .auto_out_1_a_bits_user_needHint          (inner_busPMU_auto_out_1_a_bits_user_needHint),
    .auto_out_1_a_bits_mask                   (inner_busPMU_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data                   (inner_busPMU_auto_out_1_a_bits_data),
    .auto_out_1_a_bits_corrupt                (inner_busPMU_auto_out_1_a_bits_corrupt),
    .auto_out_1_d_ready                       (inner_busPMU_auto_out_1_d_ready),
    .auto_out_1_d_valid                       (inner_xbar_auto_in_1_d_valid),
    .auto_out_1_d_bits_opcode                 (inner_xbar_auto_in_1_d_bits_opcode),
    .auto_out_1_d_bits_param                  (inner_xbar_auto_in_1_d_bits_param),
    .auto_out_1_d_bits_size                   (inner_xbar_auto_in_1_d_bits_size),
    .auto_out_1_d_bits_source                 (inner_xbar_auto_in_1_d_bits_source),
    .auto_out_1_d_bits_sink                   (inner_xbar_auto_in_1_d_bits_sink),
    .auto_out_1_d_bits_denied                 (inner_xbar_auto_in_1_d_bits_denied),
    .auto_out_1_d_bits_data                   (inner_xbar_auto_in_1_d_bits_data),
    .auto_out_1_d_bits_corrupt                (inner_xbar_auto_in_1_d_bits_corrupt),
    .auto_out_0_a_ready                       (inner_xbar_auto_in_0_a_ready),
    .auto_out_0_a_valid                       (inner_busPMU_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode                 (inner_busPMU_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param                  (inner_busPMU_auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size                   (inner_busPMU_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source                 (inner_busPMU_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address                (inner_busPMU_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_user_alias             (inner_busPMU_auto_out_0_a_bits_user_alias),
    .auto_out_0_a_bits_user_vaddr             (inner_busPMU_auto_out_0_a_bits_user_vaddr),
    .auto_out_0_a_bits_user_reqSource         (inner_busPMU_auto_out_0_a_bits_user_reqSource),
    .auto_out_0_a_bits_user_needHint          (inner_busPMU_auto_out_0_a_bits_user_needHint),
    .auto_out_0_a_bits_echo_isKeyword         (inner_busPMU_auto_out_0_a_bits_echo_isKeyword),
    .auto_out_0_a_bits_mask                   (inner_busPMU_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data                   (inner_busPMU_auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt                (inner_busPMU_auto_out_0_a_bits_corrupt),
    .auto_out_0_b_ready                       (inner_busPMU_auto_out_0_b_ready),
    .auto_out_0_b_valid                       (inner_xbar_auto_in_0_b_valid),
    .auto_out_0_b_bits_opcode                 (inner_xbar_auto_in_0_b_bits_opcode),
    .auto_out_0_b_bits_param                  (inner_xbar_auto_in_0_b_bits_param),
    .auto_out_0_b_bits_size                   (inner_xbar_auto_in_0_b_bits_size),
    .auto_out_0_b_bits_source                 (inner_xbar_auto_in_0_b_bits_source),
    .auto_out_0_b_bits_address                (inner_xbar_auto_in_0_b_bits_address),
    .auto_out_0_b_bits_mask                   (inner_xbar_auto_in_0_b_bits_mask),
    .auto_out_0_b_bits_data                   (inner_xbar_auto_in_0_b_bits_data),
    .auto_out_0_b_bits_corrupt                (inner_xbar_auto_in_0_b_bits_corrupt),
    .auto_out_0_c_ready                       (inner_xbar_auto_in_0_c_ready),
    .auto_out_0_c_valid                       (inner_busPMU_auto_out_0_c_valid),
    .auto_out_0_c_bits_opcode                 (inner_busPMU_auto_out_0_c_bits_opcode),
    .auto_out_0_c_bits_param                  (inner_busPMU_auto_out_0_c_bits_param),
    .auto_out_0_c_bits_size                   (inner_busPMU_auto_out_0_c_bits_size),
    .auto_out_0_c_bits_source                 (inner_busPMU_auto_out_0_c_bits_source),
    .auto_out_0_c_bits_address                (inner_busPMU_auto_out_0_c_bits_address),
    .auto_out_0_c_bits_user_alias             (inner_busPMU_auto_out_0_c_bits_user_alias),
    .auto_out_0_c_bits_user_vaddr             (inner_busPMU_auto_out_0_c_bits_user_vaddr),
    .auto_out_0_c_bits_user_reqSource         (inner_busPMU_auto_out_0_c_bits_user_reqSource),
    .auto_out_0_c_bits_user_needHint          (inner_busPMU_auto_out_0_c_bits_user_needHint),
    .auto_out_0_c_bits_echo_isKeyword         (inner_busPMU_auto_out_0_c_bits_echo_isKeyword),
    .auto_out_0_c_bits_data                   (inner_busPMU_auto_out_0_c_bits_data),
    .auto_out_0_c_bits_corrupt                (inner_busPMU_auto_out_0_c_bits_corrupt),
    .auto_out_0_d_ready                       (inner_busPMU_auto_out_0_d_ready),
    .auto_out_0_d_valid                       (inner_xbar_auto_in_0_d_valid),
    .auto_out_0_d_bits_opcode                 (inner_xbar_auto_in_0_d_bits_opcode),
    .auto_out_0_d_bits_param                  (inner_xbar_auto_in_0_d_bits_param),
    .auto_out_0_d_bits_size                   (inner_xbar_auto_in_0_d_bits_size),
    .auto_out_0_d_bits_source                 (inner_xbar_auto_in_0_d_bits_source),
    .auto_out_0_d_bits_sink                   (inner_xbar_auto_in_0_d_bits_sink),
    .auto_out_0_d_bits_denied                 (inner_xbar_auto_in_0_d_bits_denied),
    .auto_out_0_d_bits_echo_isKeyword         (inner_xbar_auto_in_0_d_bits_echo_isKeyword),
    .auto_out_0_d_bits_data                   (inner_xbar_auto_in_0_d_bits_data),
    .auto_out_0_d_bits_corrupt                (inner_xbar_auto_in_0_d_bits_corrupt),
    .auto_out_0_e_ready                       (inner_xbar_auto_in_0_e_ready),
    .auto_out_0_e_valid                       (inner_busPMU_auto_out_0_e_valid),
    .auto_out_0_e_bits_sink                   (inner_busPMU_auto_out_0_e_bits_sink)
  );
  TLBuffer_13 inner_buffer (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_3_a_ready                        (inner_buffer_auto_in_3_a_ready),
    .auto_in_3_a_valid                        (inner_xbar_auto_out_3_a_valid),
    .auto_in_3_a_bits_opcode                  (inner_xbar_auto_out_3_a_bits_opcode),
    .auto_in_3_a_bits_param                   (inner_xbar_auto_out_3_a_bits_param),
    .auto_in_3_a_bits_size                    (inner_xbar_auto_out_3_a_bits_size),
    .auto_in_3_a_bits_source                  (inner_xbar_auto_out_3_a_bits_source),
    .auto_in_3_a_bits_address                 (inner_xbar_auto_out_3_a_bits_address),
    .auto_in_3_a_bits_user_reqSource          (inner_xbar_auto_out_3_a_bits_user_reqSource),
    .auto_in_3_a_bits_user_alias              (inner_xbar_auto_out_3_a_bits_user_alias),
    .auto_in_3_a_bits_user_vaddr              (inner_xbar_auto_out_3_a_bits_user_vaddr),
    .auto_in_3_a_bits_user_needHint           (inner_xbar_auto_out_3_a_bits_user_needHint),
    .auto_in_3_a_bits_echo_isKeyword          (inner_xbar_auto_out_3_a_bits_echo_isKeyword),
    .auto_in_3_a_bits_mask                    (inner_xbar_auto_out_3_a_bits_mask),
    .auto_in_3_a_bits_data                    (inner_xbar_auto_out_3_a_bits_data),
    .auto_in_3_a_bits_corrupt                 (inner_xbar_auto_out_3_a_bits_corrupt),
    .auto_in_3_b_ready                        (inner_xbar_auto_out_3_b_ready),
    .auto_in_3_b_valid                        (inner_buffer_auto_in_3_b_valid),
    .auto_in_3_b_bits_opcode                  (inner_buffer_auto_in_3_b_bits_opcode),
    .auto_in_3_b_bits_param                   (inner_buffer_auto_in_3_b_bits_param),
    .auto_in_3_b_bits_size                    (inner_buffer_auto_in_3_b_bits_size),
    .auto_in_3_b_bits_source                  (inner_buffer_auto_in_3_b_bits_source),
    .auto_in_3_b_bits_address                 (inner_buffer_auto_in_3_b_bits_address),
    .auto_in_3_b_bits_mask                    (inner_buffer_auto_in_3_b_bits_mask),
    .auto_in_3_b_bits_data                    (inner_buffer_auto_in_3_b_bits_data),
    .auto_in_3_b_bits_corrupt                 (inner_buffer_auto_in_3_b_bits_corrupt),
    .auto_in_3_c_ready                        (inner_buffer_auto_in_3_c_ready),
    .auto_in_3_c_valid                        (inner_xbar_auto_out_3_c_valid),
    .auto_in_3_c_bits_opcode                  (inner_xbar_auto_out_3_c_bits_opcode),
    .auto_in_3_c_bits_param                   (inner_xbar_auto_out_3_c_bits_param),
    .auto_in_3_c_bits_size                    (inner_xbar_auto_out_3_c_bits_size),
    .auto_in_3_c_bits_source                  (inner_xbar_auto_out_3_c_bits_source),
    .auto_in_3_c_bits_address                 (inner_xbar_auto_out_3_c_bits_address),
    .auto_in_3_c_bits_user_reqSource          (inner_xbar_auto_out_3_c_bits_user_reqSource),
    .auto_in_3_c_bits_user_alias              (inner_xbar_auto_out_3_c_bits_user_alias),
    .auto_in_3_c_bits_user_vaddr              (inner_xbar_auto_out_3_c_bits_user_vaddr),
    .auto_in_3_c_bits_user_needHint           (inner_xbar_auto_out_3_c_bits_user_needHint),
    .auto_in_3_c_bits_echo_isKeyword          (inner_xbar_auto_out_3_c_bits_echo_isKeyword),
    .auto_in_3_c_bits_data                    (inner_xbar_auto_out_3_c_bits_data),
    .auto_in_3_c_bits_corrupt                 (inner_xbar_auto_out_3_c_bits_corrupt),
    .auto_in_3_d_ready                        (inner_xbar_auto_out_3_d_ready),
    .auto_in_3_d_valid                        (inner_buffer_auto_in_3_d_valid),
    .auto_in_3_d_bits_opcode                  (inner_buffer_auto_in_3_d_bits_opcode),
    .auto_in_3_d_bits_param                   (inner_buffer_auto_in_3_d_bits_param),
    .auto_in_3_d_bits_size                    (inner_buffer_auto_in_3_d_bits_size),
    .auto_in_3_d_bits_source                  (inner_buffer_auto_in_3_d_bits_source),
    .auto_in_3_d_bits_sink                    (inner_buffer_auto_in_3_d_bits_sink),
    .auto_in_3_d_bits_denied                  (inner_buffer_auto_in_3_d_bits_denied),
    .auto_in_3_d_bits_echo_isKeyword          (inner_buffer_auto_in_3_d_bits_echo_isKeyword),
    .auto_in_3_d_bits_data                    (inner_buffer_auto_in_3_d_bits_data),
    .auto_in_3_d_bits_corrupt                 (inner_buffer_auto_in_3_d_bits_corrupt),
    .auto_in_3_e_ready                        (inner_buffer_auto_in_3_e_ready),
    .auto_in_3_e_valid                        (inner_xbar_auto_out_3_e_valid),
    .auto_in_3_e_bits_sink                    (inner_xbar_auto_out_3_e_bits_sink),
    .auto_in_2_a_ready                        (inner_buffer_auto_in_2_a_ready),
    .auto_in_2_a_valid                        (inner_xbar_auto_out_2_a_valid),
    .auto_in_2_a_bits_opcode                  (inner_xbar_auto_out_2_a_bits_opcode),
    .auto_in_2_a_bits_param                   (inner_xbar_auto_out_2_a_bits_param),
    .auto_in_2_a_bits_size                    (inner_xbar_auto_out_2_a_bits_size),
    .auto_in_2_a_bits_source                  (inner_xbar_auto_out_2_a_bits_source),
    .auto_in_2_a_bits_address                 (inner_xbar_auto_out_2_a_bits_address),
    .auto_in_2_a_bits_user_reqSource          (inner_xbar_auto_out_2_a_bits_user_reqSource),
    .auto_in_2_a_bits_user_alias              (inner_xbar_auto_out_2_a_bits_user_alias),
    .auto_in_2_a_bits_user_vaddr              (inner_xbar_auto_out_2_a_bits_user_vaddr),
    .auto_in_2_a_bits_user_needHint           (inner_xbar_auto_out_2_a_bits_user_needHint),
    .auto_in_2_a_bits_echo_isKeyword          (inner_xbar_auto_out_2_a_bits_echo_isKeyword),
    .auto_in_2_a_bits_mask                    (inner_xbar_auto_out_2_a_bits_mask),
    .auto_in_2_a_bits_data                    (inner_xbar_auto_out_2_a_bits_data),
    .auto_in_2_a_bits_corrupt                 (inner_xbar_auto_out_2_a_bits_corrupt),
    .auto_in_2_b_ready                        (inner_xbar_auto_out_2_b_ready),
    .auto_in_2_b_valid                        (inner_buffer_auto_in_2_b_valid),
    .auto_in_2_b_bits_opcode                  (inner_buffer_auto_in_2_b_bits_opcode),
    .auto_in_2_b_bits_param                   (inner_buffer_auto_in_2_b_bits_param),
    .auto_in_2_b_bits_size                    (inner_buffer_auto_in_2_b_bits_size),
    .auto_in_2_b_bits_source                  (inner_buffer_auto_in_2_b_bits_source),
    .auto_in_2_b_bits_address                 (inner_buffer_auto_in_2_b_bits_address),
    .auto_in_2_b_bits_mask                    (inner_buffer_auto_in_2_b_bits_mask),
    .auto_in_2_b_bits_data                    (inner_buffer_auto_in_2_b_bits_data),
    .auto_in_2_b_bits_corrupt                 (inner_buffer_auto_in_2_b_bits_corrupt),
    .auto_in_2_c_ready                        (inner_buffer_auto_in_2_c_ready),
    .auto_in_2_c_valid                        (inner_xbar_auto_out_2_c_valid),
    .auto_in_2_c_bits_opcode                  (inner_xbar_auto_out_2_c_bits_opcode),
    .auto_in_2_c_bits_param                   (inner_xbar_auto_out_2_c_bits_param),
    .auto_in_2_c_bits_size                    (inner_xbar_auto_out_2_c_bits_size),
    .auto_in_2_c_bits_source                  (inner_xbar_auto_out_2_c_bits_source),
    .auto_in_2_c_bits_address                 (inner_xbar_auto_out_2_c_bits_address),
    .auto_in_2_c_bits_user_reqSource          (inner_xbar_auto_out_2_c_bits_user_reqSource),
    .auto_in_2_c_bits_user_alias              (inner_xbar_auto_out_2_c_bits_user_alias),
    .auto_in_2_c_bits_user_vaddr              (inner_xbar_auto_out_2_c_bits_user_vaddr),
    .auto_in_2_c_bits_user_needHint           (inner_xbar_auto_out_2_c_bits_user_needHint),
    .auto_in_2_c_bits_echo_isKeyword          (inner_xbar_auto_out_2_c_bits_echo_isKeyword),
    .auto_in_2_c_bits_data                    (inner_xbar_auto_out_2_c_bits_data),
    .auto_in_2_c_bits_corrupt                 (inner_xbar_auto_out_2_c_bits_corrupt),
    .auto_in_2_d_ready                        (inner_xbar_auto_out_2_d_ready),
    .auto_in_2_d_valid                        (inner_buffer_auto_in_2_d_valid),
    .auto_in_2_d_bits_opcode                  (inner_buffer_auto_in_2_d_bits_opcode),
    .auto_in_2_d_bits_param                   (inner_buffer_auto_in_2_d_bits_param),
    .auto_in_2_d_bits_size                    (inner_buffer_auto_in_2_d_bits_size),
    .auto_in_2_d_bits_source                  (inner_buffer_auto_in_2_d_bits_source),
    .auto_in_2_d_bits_sink                    (inner_buffer_auto_in_2_d_bits_sink),
    .auto_in_2_d_bits_denied                  (inner_buffer_auto_in_2_d_bits_denied),
    .auto_in_2_d_bits_echo_isKeyword          (inner_buffer_auto_in_2_d_bits_echo_isKeyword),
    .auto_in_2_d_bits_data                    (inner_buffer_auto_in_2_d_bits_data),
    .auto_in_2_d_bits_corrupt                 (inner_buffer_auto_in_2_d_bits_corrupt),
    .auto_in_2_e_ready                        (inner_buffer_auto_in_2_e_ready),
    .auto_in_2_e_valid                        (inner_xbar_auto_out_2_e_valid),
    .auto_in_2_e_bits_sink                    (inner_xbar_auto_out_2_e_bits_sink),
    .auto_in_1_a_ready                        (inner_buffer_auto_in_1_a_ready),
    .auto_in_1_a_valid                        (inner_xbar_auto_out_1_a_valid),
    .auto_in_1_a_bits_opcode                  (inner_xbar_auto_out_1_a_bits_opcode),
    .auto_in_1_a_bits_param                   (inner_xbar_auto_out_1_a_bits_param),
    .auto_in_1_a_bits_size                    (inner_xbar_auto_out_1_a_bits_size),
    .auto_in_1_a_bits_source                  (inner_xbar_auto_out_1_a_bits_source),
    .auto_in_1_a_bits_address                 (inner_xbar_auto_out_1_a_bits_address),
    .auto_in_1_a_bits_user_reqSource          (inner_xbar_auto_out_1_a_bits_user_reqSource),
    .auto_in_1_a_bits_user_alias              (inner_xbar_auto_out_1_a_bits_user_alias),
    .auto_in_1_a_bits_user_vaddr              (inner_xbar_auto_out_1_a_bits_user_vaddr),
    .auto_in_1_a_bits_user_needHint           (inner_xbar_auto_out_1_a_bits_user_needHint),
    .auto_in_1_a_bits_echo_isKeyword          (inner_xbar_auto_out_1_a_bits_echo_isKeyword),
    .auto_in_1_a_bits_mask                    (inner_xbar_auto_out_1_a_bits_mask),
    .auto_in_1_a_bits_data                    (inner_xbar_auto_out_1_a_bits_data),
    .auto_in_1_a_bits_corrupt                 (inner_xbar_auto_out_1_a_bits_corrupt),
    .auto_in_1_b_ready                        (inner_xbar_auto_out_1_b_ready),
    .auto_in_1_b_valid                        (inner_buffer_auto_in_1_b_valid),
    .auto_in_1_b_bits_opcode                  (inner_buffer_auto_in_1_b_bits_opcode),
    .auto_in_1_b_bits_param                   (inner_buffer_auto_in_1_b_bits_param),
    .auto_in_1_b_bits_size                    (inner_buffer_auto_in_1_b_bits_size),
    .auto_in_1_b_bits_source                  (inner_buffer_auto_in_1_b_bits_source),
    .auto_in_1_b_bits_address                 (inner_buffer_auto_in_1_b_bits_address),
    .auto_in_1_b_bits_mask                    (inner_buffer_auto_in_1_b_bits_mask),
    .auto_in_1_b_bits_data                    (inner_buffer_auto_in_1_b_bits_data),
    .auto_in_1_b_bits_corrupt                 (inner_buffer_auto_in_1_b_bits_corrupt),
    .auto_in_1_c_ready                        (inner_buffer_auto_in_1_c_ready),
    .auto_in_1_c_valid                        (inner_xbar_auto_out_1_c_valid),
    .auto_in_1_c_bits_opcode                  (inner_xbar_auto_out_1_c_bits_opcode),
    .auto_in_1_c_bits_param                   (inner_xbar_auto_out_1_c_bits_param),
    .auto_in_1_c_bits_size                    (inner_xbar_auto_out_1_c_bits_size),
    .auto_in_1_c_bits_source                  (inner_xbar_auto_out_1_c_bits_source),
    .auto_in_1_c_bits_address                 (inner_xbar_auto_out_1_c_bits_address),
    .auto_in_1_c_bits_user_reqSource          (inner_xbar_auto_out_1_c_bits_user_reqSource),
    .auto_in_1_c_bits_user_alias              (inner_xbar_auto_out_1_c_bits_user_alias),
    .auto_in_1_c_bits_user_vaddr              (inner_xbar_auto_out_1_c_bits_user_vaddr),
    .auto_in_1_c_bits_user_needHint           (inner_xbar_auto_out_1_c_bits_user_needHint),
    .auto_in_1_c_bits_echo_isKeyword          (inner_xbar_auto_out_1_c_bits_echo_isKeyword),
    .auto_in_1_c_bits_data                    (inner_xbar_auto_out_1_c_bits_data),
    .auto_in_1_c_bits_corrupt                 (inner_xbar_auto_out_1_c_bits_corrupt),
    .auto_in_1_d_ready                        (inner_xbar_auto_out_1_d_ready),
    .auto_in_1_d_valid                        (inner_buffer_auto_in_1_d_valid),
    .auto_in_1_d_bits_opcode                  (inner_buffer_auto_in_1_d_bits_opcode),
    .auto_in_1_d_bits_param                   (inner_buffer_auto_in_1_d_bits_param),
    .auto_in_1_d_bits_size                    (inner_buffer_auto_in_1_d_bits_size),
    .auto_in_1_d_bits_source                  (inner_buffer_auto_in_1_d_bits_source),
    .auto_in_1_d_bits_sink                    (inner_buffer_auto_in_1_d_bits_sink),
    .auto_in_1_d_bits_denied                  (inner_buffer_auto_in_1_d_bits_denied),
    .auto_in_1_d_bits_echo_isKeyword          (inner_buffer_auto_in_1_d_bits_echo_isKeyword),
    .auto_in_1_d_bits_data                    (inner_buffer_auto_in_1_d_bits_data),
    .auto_in_1_d_bits_corrupt                 (inner_buffer_auto_in_1_d_bits_corrupt),
    .auto_in_1_e_ready                        (inner_buffer_auto_in_1_e_ready),
    .auto_in_1_e_valid                        (inner_xbar_auto_out_1_e_valid),
    .auto_in_1_e_bits_sink                    (inner_xbar_auto_out_1_e_bits_sink),
    .auto_in_0_a_ready                        (inner_buffer_auto_in_0_a_ready),
    .auto_in_0_a_valid                        (inner_xbar_auto_out_0_a_valid),
    .auto_in_0_a_bits_opcode                  (inner_xbar_auto_out_0_a_bits_opcode),
    .auto_in_0_a_bits_param                   (inner_xbar_auto_out_0_a_bits_param),
    .auto_in_0_a_bits_size                    (inner_xbar_auto_out_0_a_bits_size),
    .auto_in_0_a_bits_source                  (inner_xbar_auto_out_0_a_bits_source),
    .auto_in_0_a_bits_address                 (inner_xbar_auto_out_0_a_bits_address),
    .auto_in_0_a_bits_user_reqSource          (inner_xbar_auto_out_0_a_bits_user_reqSource),
    .auto_in_0_a_bits_user_alias              (inner_xbar_auto_out_0_a_bits_user_alias),
    .auto_in_0_a_bits_user_vaddr              (inner_xbar_auto_out_0_a_bits_user_vaddr),
    .auto_in_0_a_bits_user_needHint           (inner_xbar_auto_out_0_a_bits_user_needHint),
    .auto_in_0_a_bits_echo_isKeyword          (inner_xbar_auto_out_0_a_bits_echo_isKeyword),
    .auto_in_0_a_bits_mask                    (inner_xbar_auto_out_0_a_bits_mask),
    .auto_in_0_a_bits_data                    (inner_xbar_auto_out_0_a_bits_data),
    .auto_in_0_a_bits_corrupt                 (inner_xbar_auto_out_0_a_bits_corrupt),
    .auto_in_0_b_ready                        (inner_xbar_auto_out_0_b_ready),
    .auto_in_0_b_valid                        (inner_buffer_auto_in_0_b_valid),
    .auto_in_0_b_bits_opcode                  (inner_buffer_auto_in_0_b_bits_opcode),
    .auto_in_0_b_bits_param                   (inner_buffer_auto_in_0_b_bits_param),
    .auto_in_0_b_bits_size                    (inner_buffer_auto_in_0_b_bits_size),
    .auto_in_0_b_bits_source                  (inner_buffer_auto_in_0_b_bits_source),
    .auto_in_0_b_bits_address                 (inner_buffer_auto_in_0_b_bits_address),
    .auto_in_0_b_bits_mask                    (inner_buffer_auto_in_0_b_bits_mask),
    .auto_in_0_b_bits_data                    (inner_buffer_auto_in_0_b_bits_data),
    .auto_in_0_b_bits_corrupt                 (inner_buffer_auto_in_0_b_bits_corrupt),
    .auto_in_0_c_ready                        (inner_buffer_auto_in_0_c_ready),
    .auto_in_0_c_valid                        (inner_xbar_auto_out_0_c_valid),
    .auto_in_0_c_bits_opcode                  (inner_xbar_auto_out_0_c_bits_opcode),
    .auto_in_0_c_bits_param                   (inner_xbar_auto_out_0_c_bits_param),
    .auto_in_0_c_bits_size                    (inner_xbar_auto_out_0_c_bits_size),
    .auto_in_0_c_bits_source                  (inner_xbar_auto_out_0_c_bits_source),
    .auto_in_0_c_bits_address                 (inner_xbar_auto_out_0_c_bits_address),
    .auto_in_0_c_bits_user_reqSource          (inner_xbar_auto_out_0_c_bits_user_reqSource),
    .auto_in_0_c_bits_user_alias              (inner_xbar_auto_out_0_c_bits_user_alias),
    .auto_in_0_c_bits_user_vaddr              (inner_xbar_auto_out_0_c_bits_user_vaddr),
    .auto_in_0_c_bits_user_needHint           (inner_xbar_auto_out_0_c_bits_user_needHint),
    .auto_in_0_c_bits_echo_isKeyword          (inner_xbar_auto_out_0_c_bits_echo_isKeyword),
    .auto_in_0_c_bits_data                    (inner_xbar_auto_out_0_c_bits_data),
    .auto_in_0_c_bits_corrupt                 (inner_xbar_auto_out_0_c_bits_corrupt),
    .auto_in_0_d_ready                        (inner_xbar_auto_out_0_d_ready),
    .auto_in_0_d_valid                        (inner_buffer_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode                  (inner_buffer_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param                   (inner_buffer_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size                    (inner_buffer_auto_in_0_d_bits_size),
    .auto_in_0_d_bits_source                  (inner_buffer_auto_in_0_d_bits_source),
    .auto_in_0_d_bits_sink                    (inner_buffer_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied                  (inner_buffer_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_echo_isKeyword          (inner_buffer_auto_in_0_d_bits_echo_isKeyword),
    .auto_in_0_d_bits_data                    (inner_buffer_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt                 (inner_buffer_auto_in_0_d_bits_corrupt),
    .auto_in_0_e_ready                        (inner_buffer_auto_in_0_e_ready),
    .auto_in_0_e_valid                        (inner_xbar_auto_out_0_e_valid),
    .auto_in_0_e_bits_sink                    (inner_xbar_auto_out_0_e_bits_sink),
    .auto_out_3_a_ready                       (inner_l2cache_auto_in_3_a_ready),
    .auto_out_3_a_valid                       (inner_buffer_auto_out_3_a_valid),
    .auto_out_3_a_bits_opcode                 (inner_buffer_auto_out_3_a_bits_opcode),
    .auto_out_3_a_bits_param                  (inner_buffer_auto_out_3_a_bits_param),
    .auto_out_3_a_bits_size                   (inner_buffer_auto_out_3_a_bits_size),
    .auto_out_3_a_bits_source                 (inner_buffer_auto_out_3_a_bits_source),
    .auto_out_3_a_bits_address                (inner_buffer_auto_out_3_a_bits_address),
    .auto_out_3_a_bits_user_reqSource         (inner_buffer_auto_out_3_a_bits_user_reqSource),
    .auto_out_3_a_bits_user_alias             (inner_buffer_auto_out_3_a_bits_user_alias),
    .auto_out_3_a_bits_user_vaddr             (inner_buffer_auto_out_3_a_bits_user_vaddr),
    .auto_out_3_a_bits_user_needHint          (inner_buffer_auto_out_3_a_bits_user_needHint),
    .auto_out_3_a_bits_echo_isKeyword         (inner_buffer_auto_out_3_a_bits_echo_isKeyword),
    .auto_out_3_a_bits_corrupt                (inner_buffer_auto_out_3_a_bits_corrupt),
    .auto_out_3_b_ready                       (inner_buffer_auto_out_3_b_ready),
    .auto_out_3_b_valid                       (inner_l2cache_auto_in_3_b_valid),
    .auto_out_3_b_bits_opcode                 (inner_l2cache_auto_in_3_b_bits_opcode),
    .auto_out_3_b_bits_param                  (inner_l2cache_auto_in_3_b_bits_param),
    .auto_out_3_b_bits_address                (inner_l2cache_auto_in_3_b_bits_address),
    .auto_out_3_b_bits_data                   (inner_l2cache_auto_in_3_b_bits_data),
    .auto_out_3_c_ready                       (inner_l2cache_auto_in_3_c_ready),
    .auto_out_3_c_valid                       (inner_buffer_auto_out_3_c_valid),
    .auto_out_3_c_bits_opcode                 (inner_buffer_auto_out_3_c_bits_opcode),
    .auto_out_3_c_bits_param                  (inner_buffer_auto_out_3_c_bits_param),
    .auto_out_3_c_bits_size                   (inner_buffer_auto_out_3_c_bits_size),
    .auto_out_3_c_bits_source                 (inner_buffer_auto_out_3_c_bits_source),
    .auto_out_3_c_bits_address                (inner_buffer_auto_out_3_c_bits_address),
    .auto_out_3_c_bits_data                   (inner_buffer_auto_out_3_c_bits_data),
    .auto_out_3_c_bits_corrupt                (inner_buffer_auto_out_3_c_bits_corrupt),
    .auto_out_3_d_ready                       (inner_buffer_auto_out_3_d_ready),
    .auto_out_3_d_valid                       (inner_l2cache_auto_in_3_d_valid),
    .auto_out_3_d_bits_opcode                 (inner_l2cache_auto_in_3_d_bits_opcode),
    .auto_out_3_d_bits_param                  (inner_l2cache_auto_in_3_d_bits_param),
    .auto_out_3_d_bits_source                 (inner_l2cache_auto_in_3_d_bits_source),
    .auto_out_3_d_bits_sink                   (inner_l2cache_auto_in_3_d_bits_sink),
    .auto_out_3_d_bits_denied                 (inner_l2cache_auto_in_3_d_bits_denied),
    .auto_out_3_d_bits_echo_isKeyword         (inner_l2cache_auto_in_3_d_bits_echo_isKeyword),
    .auto_out_3_d_bits_data                   (inner_l2cache_auto_in_3_d_bits_data),
    .auto_out_3_d_bits_corrupt                (inner_l2cache_auto_in_3_d_bits_corrupt),
    .auto_out_3_e_valid                       (inner_buffer_auto_out_3_e_valid),
    .auto_out_3_e_bits_sink                   (inner_buffer_auto_out_3_e_bits_sink),
    .auto_out_2_a_ready                       (inner_l2cache_auto_in_2_a_ready),
    .auto_out_2_a_valid                       (inner_buffer_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode                 (inner_buffer_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param                  (inner_buffer_auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size                   (inner_buffer_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source                 (inner_buffer_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address                (inner_buffer_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_user_reqSource         (inner_buffer_auto_out_2_a_bits_user_reqSource),
    .auto_out_2_a_bits_user_alias             (inner_buffer_auto_out_2_a_bits_user_alias),
    .auto_out_2_a_bits_user_vaddr             (inner_buffer_auto_out_2_a_bits_user_vaddr),
    .auto_out_2_a_bits_user_needHint          (inner_buffer_auto_out_2_a_bits_user_needHint),
    .auto_out_2_a_bits_echo_isKeyword         (inner_buffer_auto_out_2_a_bits_echo_isKeyword),
    .auto_out_2_a_bits_corrupt                (inner_buffer_auto_out_2_a_bits_corrupt),
    .auto_out_2_b_ready                       (inner_buffer_auto_out_2_b_ready),
    .auto_out_2_b_valid                       (inner_l2cache_auto_in_2_b_valid),
    .auto_out_2_b_bits_opcode                 (inner_l2cache_auto_in_2_b_bits_opcode),
    .auto_out_2_b_bits_param                  (inner_l2cache_auto_in_2_b_bits_param),
    .auto_out_2_b_bits_address                (inner_l2cache_auto_in_2_b_bits_address),
    .auto_out_2_b_bits_data                   (inner_l2cache_auto_in_2_b_bits_data),
    .auto_out_2_c_ready                       (inner_l2cache_auto_in_2_c_ready),
    .auto_out_2_c_valid                       (inner_buffer_auto_out_2_c_valid),
    .auto_out_2_c_bits_opcode                 (inner_buffer_auto_out_2_c_bits_opcode),
    .auto_out_2_c_bits_param                  (inner_buffer_auto_out_2_c_bits_param),
    .auto_out_2_c_bits_size                   (inner_buffer_auto_out_2_c_bits_size),
    .auto_out_2_c_bits_source                 (inner_buffer_auto_out_2_c_bits_source),
    .auto_out_2_c_bits_address                (inner_buffer_auto_out_2_c_bits_address),
    .auto_out_2_c_bits_data                   (inner_buffer_auto_out_2_c_bits_data),
    .auto_out_2_c_bits_corrupt                (inner_buffer_auto_out_2_c_bits_corrupt),
    .auto_out_2_d_ready                       (inner_buffer_auto_out_2_d_ready),
    .auto_out_2_d_valid                       (inner_l2cache_auto_in_2_d_valid),
    .auto_out_2_d_bits_opcode                 (inner_l2cache_auto_in_2_d_bits_opcode),
    .auto_out_2_d_bits_param                  (inner_l2cache_auto_in_2_d_bits_param),
    .auto_out_2_d_bits_source                 (inner_l2cache_auto_in_2_d_bits_source),
    .auto_out_2_d_bits_sink                   (inner_l2cache_auto_in_2_d_bits_sink),
    .auto_out_2_d_bits_denied                 (inner_l2cache_auto_in_2_d_bits_denied),
    .auto_out_2_d_bits_echo_isKeyword         (inner_l2cache_auto_in_2_d_bits_echo_isKeyword),
    .auto_out_2_d_bits_data                   (inner_l2cache_auto_in_2_d_bits_data),
    .auto_out_2_d_bits_corrupt                (inner_l2cache_auto_in_2_d_bits_corrupt),
    .auto_out_2_e_valid                       (inner_buffer_auto_out_2_e_valid),
    .auto_out_2_e_bits_sink                   (inner_buffer_auto_out_2_e_bits_sink),
    .auto_out_1_a_ready                       (inner_l2cache_auto_in_1_a_ready),
    .auto_out_1_a_valid                       (inner_buffer_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode                 (inner_buffer_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param                  (inner_buffer_auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size                   (inner_buffer_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source                 (inner_buffer_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address                (inner_buffer_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_user_reqSource         (inner_buffer_auto_out_1_a_bits_user_reqSource),
    .auto_out_1_a_bits_user_alias             (inner_buffer_auto_out_1_a_bits_user_alias),
    .auto_out_1_a_bits_user_vaddr             (inner_buffer_auto_out_1_a_bits_user_vaddr),
    .auto_out_1_a_bits_user_needHint          (inner_buffer_auto_out_1_a_bits_user_needHint),
    .auto_out_1_a_bits_echo_isKeyword         (inner_buffer_auto_out_1_a_bits_echo_isKeyword),
    .auto_out_1_a_bits_corrupt                (inner_buffer_auto_out_1_a_bits_corrupt),
    .auto_out_1_b_ready                       (inner_buffer_auto_out_1_b_ready),
    .auto_out_1_b_valid                       (inner_l2cache_auto_in_1_b_valid),
    .auto_out_1_b_bits_opcode                 (inner_l2cache_auto_in_1_b_bits_opcode),
    .auto_out_1_b_bits_param                  (inner_l2cache_auto_in_1_b_bits_param),
    .auto_out_1_b_bits_address                (inner_l2cache_auto_in_1_b_bits_address),
    .auto_out_1_b_bits_data                   (inner_l2cache_auto_in_1_b_bits_data),
    .auto_out_1_c_ready                       (inner_l2cache_auto_in_1_c_ready),
    .auto_out_1_c_valid                       (inner_buffer_auto_out_1_c_valid),
    .auto_out_1_c_bits_opcode                 (inner_buffer_auto_out_1_c_bits_opcode),
    .auto_out_1_c_bits_param                  (inner_buffer_auto_out_1_c_bits_param),
    .auto_out_1_c_bits_size                   (inner_buffer_auto_out_1_c_bits_size),
    .auto_out_1_c_bits_source                 (inner_buffer_auto_out_1_c_bits_source),
    .auto_out_1_c_bits_address                (inner_buffer_auto_out_1_c_bits_address),
    .auto_out_1_c_bits_data                   (inner_buffer_auto_out_1_c_bits_data),
    .auto_out_1_c_bits_corrupt                (inner_buffer_auto_out_1_c_bits_corrupt),
    .auto_out_1_d_ready                       (inner_buffer_auto_out_1_d_ready),
    .auto_out_1_d_valid                       (inner_l2cache_auto_in_1_d_valid),
    .auto_out_1_d_bits_opcode                 (inner_l2cache_auto_in_1_d_bits_opcode),
    .auto_out_1_d_bits_param                  (inner_l2cache_auto_in_1_d_bits_param),
    .auto_out_1_d_bits_source                 (inner_l2cache_auto_in_1_d_bits_source),
    .auto_out_1_d_bits_sink                   (inner_l2cache_auto_in_1_d_bits_sink),
    .auto_out_1_d_bits_denied                 (inner_l2cache_auto_in_1_d_bits_denied),
    .auto_out_1_d_bits_echo_isKeyword         (inner_l2cache_auto_in_1_d_bits_echo_isKeyword),
    .auto_out_1_d_bits_data                   (inner_l2cache_auto_in_1_d_bits_data),
    .auto_out_1_d_bits_corrupt                (inner_l2cache_auto_in_1_d_bits_corrupt),
    .auto_out_1_e_valid                       (inner_buffer_auto_out_1_e_valid),
    .auto_out_1_e_bits_sink                   (inner_buffer_auto_out_1_e_bits_sink),
    .auto_out_0_a_ready                       (inner_l2cache_auto_in_0_a_ready),
    .auto_out_0_a_valid                       (inner_buffer_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode                 (inner_buffer_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param                  (inner_buffer_auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size                   (inner_buffer_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source                 (inner_buffer_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address                (inner_buffer_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_user_reqSource         (inner_buffer_auto_out_0_a_bits_user_reqSource),
    .auto_out_0_a_bits_user_alias             (inner_buffer_auto_out_0_a_bits_user_alias),
    .auto_out_0_a_bits_user_vaddr             (inner_buffer_auto_out_0_a_bits_user_vaddr),
    .auto_out_0_a_bits_user_needHint          (inner_buffer_auto_out_0_a_bits_user_needHint),
    .auto_out_0_a_bits_echo_isKeyword         (inner_buffer_auto_out_0_a_bits_echo_isKeyword),
    .auto_out_0_a_bits_corrupt                (inner_buffer_auto_out_0_a_bits_corrupt),
    .auto_out_0_b_ready                       (inner_buffer_auto_out_0_b_ready),
    .auto_out_0_b_valid                       (inner_l2cache_auto_in_0_b_valid),
    .auto_out_0_b_bits_opcode                 (inner_l2cache_auto_in_0_b_bits_opcode),
    .auto_out_0_b_bits_param                  (inner_l2cache_auto_in_0_b_bits_param),
    .auto_out_0_b_bits_address                (inner_l2cache_auto_in_0_b_bits_address),
    .auto_out_0_b_bits_data                   (inner_l2cache_auto_in_0_b_bits_data),
    .auto_out_0_c_ready                       (inner_l2cache_auto_in_0_c_ready),
    .auto_out_0_c_valid                       (inner_buffer_auto_out_0_c_valid),
    .auto_out_0_c_bits_opcode                 (inner_buffer_auto_out_0_c_bits_opcode),
    .auto_out_0_c_bits_param                  (inner_buffer_auto_out_0_c_bits_param),
    .auto_out_0_c_bits_size                   (inner_buffer_auto_out_0_c_bits_size),
    .auto_out_0_c_bits_source                 (inner_buffer_auto_out_0_c_bits_source),
    .auto_out_0_c_bits_address                (inner_buffer_auto_out_0_c_bits_address),
    .auto_out_0_c_bits_data                   (inner_buffer_auto_out_0_c_bits_data),
    .auto_out_0_c_bits_corrupt                (inner_buffer_auto_out_0_c_bits_corrupt),
    .auto_out_0_d_ready                       (inner_buffer_auto_out_0_d_ready),
    .auto_out_0_d_valid                       (inner_l2cache_auto_in_0_d_valid),
    .auto_out_0_d_bits_opcode                 (inner_l2cache_auto_in_0_d_bits_opcode),
    .auto_out_0_d_bits_param                  (inner_l2cache_auto_in_0_d_bits_param),
    .auto_out_0_d_bits_source                 (inner_l2cache_auto_in_0_d_bits_source),
    .auto_out_0_d_bits_sink                   (inner_l2cache_auto_in_0_d_bits_sink),
    .auto_out_0_d_bits_denied                 (inner_l2cache_auto_in_0_d_bits_denied),
    .auto_out_0_d_bits_echo_isKeyword         (inner_l2cache_auto_in_0_d_bits_echo_isKeyword),
    .auto_out_0_d_bits_data                   (inner_l2cache_auto_in_0_d_bits_data),
    .auto_out_0_d_bits_corrupt                (inner_l2cache_auto_in_0_d_bits_corrupt),
    .auto_out_0_e_valid                       (inner_buffer_auto_out_0_e_valid),
    .auto_out_0_e_bits_sink                   (inner_buffer_auto_out_0_e_bits_sink)
  );
  TLLogger inner_logger (
    .auto_in_a_ready                          (auto_inner_logger_in_0_a_ready),
    .auto_in_a_valid                          (auto_inner_logger_in_0_a_valid),
    .auto_in_a_bits_opcode                    (auto_inner_logger_in_0_a_bits_opcode),
    .auto_in_a_bits_param                     (auto_inner_logger_in_0_a_bits_param),
    .auto_in_a_bits_size                      (auto_inner_logger_in_0_a_bits_size),
    .auto_in_a_bits_source                    (auto_inner_logger_in_0_a_bits_source),
    .auto_in_a_bits_address                   (auto_inner_logger_in_0_a_bits_address),
    .auto_in_a_bits_user_alias                (auto_inner_logger_in_0_a_bits_user_alias),
    .auto_in_a_bits_user_vaddr                (auto_inner_logger_in_0_a_bits_user_vaddr),
    .auto_in_a_bits_user_reqSource            (auto_inner_logger_in_0_a_bits_user_reqSource),
    .auto_in_a_bits_user_needHint             (auto_inner_logger_in_0_a_bits_user_needHint),
    .auto_in_a_bits_echo_isKeyword            (auto_inner_logger_in_0_a_bits_echo_isKeyword),
    .auto_in_a_bits_mask                      (auto_inner_logger_in_0_a_bits_mask),
    .auto_in_a_bits_data                      (auto_inner_logger_in_0_a_bits_data),
    .auto_in_a_bits_corrupt                   (auto_inner_logger_in_0_a_bits_corrupt),
    .auto_in_b_ready                          (auto_inner_logger_in_0_b_ready),
    .auto_in_b_valid                          (auto_inner_logger_in_0_b_valid),
    .auto_in_b_bits_opcode                    (auto_inner_logger_in_0_b_bits_opcode),
    .auto_in_b_bits_param                     (auto_inner_logger_in_0_b_bits_param),
    .auto_in_b_bits_size                      (auto_inner_logger_in_0_b_bits_size),
    .auto_in_b_bits_source                    (auto_inner_logger_in_0_b_bits_source),
    .auto_in_b_bits_address                   (auto_inner_logger_in_0_b_bits_address),
    .auto_in_b_bits_mask                      (auto_inner_logger_in_0_b_bits_mask),
    .auto_in_b_bits_data                      (auto_inner_logger_in_0_b_bits_data),
    .auto_in_b_bits_corrupt                   (auto_inner_logger_in_0_b_bits_corrupt),
    .auto_in_c_ready                          (auto_inner_logger_in_0_c_ready),
    .auto_in_c_valid                          (auto_inner_logger_in_0_c_valid),
    .auto_in_c_bits_opcode                    (auto_inner_logger_in_0_c_bits_opcode),
    .auto_in_c_bits_param                     (auto_inner_logger_in_0_c_bits_param),
    .auto_in_c_bits_size                      (auto_inner_logger_in_0_c_bits_size),
    .auto_in_c_bits_source                    (auto_inner_logger_in_0_c_bits_source),
    .auto_in_c_bits_address                   (auto_inner_logger_in_0_c_bits_address),
    .auto_in_c_bits_user_alias                (auto_inner_logger_in_0_c_bits_user_alias),
    .auto_in_c_bits_user_vaddr                (auto_inner_logger_in_0_c_bits_user_vaddr),
    .auto_in_c_bits_user_reqSource            (auto_inner_logger_in_0_c_bits_user_reqSource),
    .auto_in_c_bits_user_needHint             (auto_inner_logger_in_0_c_bits_user_needHint),
    .auto_in_c_bits_echo_isKeyword            (auto_inner_logger_in_0_c_bits_echo_isKeyword),
    .auto_in_c_bits_data                      (auto_inner_logger_in_0_c_bits_data),
    .auto_in_c_bits_corrupt                   (auto_inner_logger_in_0_c_bits_corrupt),
    .auto_in_d_ready                          (auto_inner_logger_in_0_d_ready),
    .auto_in_d_valid                          (auto_inner_logger_in_0_d_valid),
    .auto_in_d_bits_opcode                    (auto_inner_logger_in_0_d_bits_opcode),
    .auto_in_d_bits_param                     (auto_inner_logger_in_0_d_bits_param),
    .auto_in_d_bits_size                      (auto_inner_logger_in_0_d_bits_size),
    .auto_in_d_bits_source                    (auto_inner_logger_in_0_d_bits_source),
    .auto_in_d_bits_sink                      (auto_inner_logger_in_0_d_bits_sink),
    .auto_in_d_bits_denied                    (auto_inner_logger_in_0_d_bits_denied),
    .auto_in_d_bits_echo_isKeyword            (auto_inner_logger_in_0_d_bits_echo_isKeyword),
    .auto_in_d_bits_data                      (auto_inner_logger_in_0_d_bits_data),
    .auto_in_d_bits_corrupt                   (auto_inner_logger_in_0_d_bits_corrupt),
    .auto_in_e_ready                          (auto_inner_logger_in_0_e_ready),
    .auto_in_e_valid                          (auto_inner_logger_in_0_e_valid),
    .auto_in_e_bits_sink                      (auto_inner_logger_in_0_e_bits_sink),
    .auto_out_a_ready                         (inner_busPMU_auto_in_0_a_ready),
    .auto_out_a_valid                         (inner_logger_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_logger_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (inner_logger_auto_out_a_bits_param),
    .auto_out_a_bits_size                     (inner_logger_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_logger_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_logger_auto_out_a_bits_address),
    .auto_out_a_bits_user_alias               (inner_logger_auto_out_a_bits_user_alias),
    .auto_out_a_bits_user_vaddr               (inner_logger_auto_out_a_bits_user_vaddr),
    .auto_out_a_bits_user_reqSource           (inner_logger_auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_user_needHint            (inner_logger_auto_out_a_bits_user_needHint),
    .auto_out_a_bits_echo_isKeyword           (inner_logger_auto_out_a_bits_echo_isKeyword),
    .auto_out_a_bits_mask                     (inner_logger_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_logger_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (inner_logger_auto_out_a_bits_corrupt),
    .auto_out_b_ready                         (inner_logger_auto_out_b_ready),
    .auto_out_b_valid                         (inner_busPMU_auto_in_0_b_valid),
    .auto_out_b_bits_opcode                   (inner_busPMU_auto_in_0_b_bits_opcode),
    .auto_out_b_bits_param                    (inner_busPMU_auto_in_0_b_bits_param),
    .auto_out_b_bits_size                     (inner_busPMU_auto_in_0_b_bits_size),
    .auto_out_b_bits_source                   (inner_busPMU_auto_in_0_b_bits_source),
    .auto_out_b_bits_address                  (inner_busPMU_auto_in_0_b_bits_address),
    .auto_out_b_bits_mask                     (inner_busPMU_auto_in_0_b_bits_mask),
    .auto_out_b_bits_data                     (inner_busPMU_auto_in_0_b_bits_data),
    .auto_out_b_bits_corrupt                  (inner_busPMU_auto_in_0_b_bits_corrupt),
    .auto_out_c_ready                         (inner_busPMU_auto_in_0_c_ready),
    .auto_out_c_valid                         (inner_logger_auto_out_c_valid),
    .auto_out_c_bits_opcode                   (inner_logger_auto_out_c_bits_opcode),
    .auto_out_c_bits_param                    (inner_logger_auto_out_c_bits_param),
    .auto_out_c_bits_size                     (inner_logger_auto_out_c_bits_size),
    .auto_out_c_bits_source                   (inner_logger_auto_out_c_bits_source),
    .auto_out_c_bits_address                  (inner_logger_auto_out_c_bits_address),
    .auto_out_c_bits_user_alias               (inner_logger_auto_out_c_bits_user_alias),
    .auto_out_c_bits_user_vaddr               (inner_logger_auto_out_c_bits_user_vaddr),
    .auto_out_c_bits_user_reqSource           (inner_logger_auto_out_c_bits_user_reqSource),
    .auto_out_c_bits_user_needHint            (inner_logger_auto_out_c_bits_user_needHint),
    .auto_out_c_bits_echo_isKeyword           (inner_logger_auto_out_c_bits_echo_isKeyword),
    .auto_out_c_bits_data                     (inner_logger_auto_out_c_bits_data),
    .auto_out_c_bits_corrupt                  (inner_logger_auto_out_c_bits_corrupt),
    .auto_out_d_ready                         (inner_logger_auto_out_d_ready),
    .auto_out_d_valid                         (inner_busPMU_auto_in_0_d_valid),
    .auto_out_d_bits_opcode                   (inner_busPMU_auto_in_0_d_bits_opcode),
    .auto_out_d_bits_param                    (inner_busPMU_auto_in_0_d_bits_param),
    .auto_out_d_bits_size                     (inner_busPMU_auto_in_0_d_bits_size),
    .auto_out_d_bits_source                   (inner_busPMU_auto_in_0_d_bits_source),
    .auto_out_d_bits_sink                     (inner_busPMU_auto_in_0_d_bits_sink),
    .auto_out_d_bits_denied                   (inner_busPMU_auto_in_0_d_bits_denied),
    .auto_out_d_bits_echo_isKeyword           (inner_busPMU_auto_in_0_d_bits_echo_isKeyword),
    .auto_out_d_bits_data                     (inner_busPMU_auto_in_0_d_bits_data),
    .auto_out_d_bits_corrupt                  (inner_busPMU_auto_in_0_d_bits_corrupt),
    .auto_out_e_ready                         (inner_busPMU_auto_in_0_e_ready),
    .auto_out_e_valid                         (inner_logger_auto_out_e_valid),
    .auto_out_e_bits_sink                     (inner_logger_auto_out_e_bits_sink)
  );
  TLLogger_1 inner_logger_1 (
    .auto_in_a_ready                          (auto_inner_logger_in_1_a_ready),
    .auto_in_a_valid                          (auto_inner_logger_in_1_a_valid),
    .auto_in_a_bits_opcode                    (auto_inner_logger_in_1_a_bits_opcode),
    .auto_in_a_bits_param                     (auto_inner_logger_in_1_a_bits_param),
    .auto_in_a_bits_size                      (auto_inner_logger_in_1_a_bits_size),
    .auto_in_a_bits_source                    (auto_inner_logger_in_1_a_bits_source),
    .auto_in_a_bits_address                   (auto_inner_logger_in_1_a_bits_address),
    .auto_in_a_bits_user_alias                (auto_inner_logger_in_1_a_bits_user_alias),
    .auto_in_a_bits_user_reqSource            (auto_inner_logger_in_1_a_bits_user_reqSource),
    .auto_in_a_bits_user_needHint             (auto_inner_logger_in_1_a_bits_user_needHint),
    .auto_in_a_bits_mask                      (auto_inner_logger_in_1_a_bits_mask),
    .auto_in_a_bits_data                      (auto_inner_logger_in_1_a_bits_data),
    .auto_in_a_bits_corrupt                   (auto_inner_logger_in_1_a_bits_corrupt),
    .auto_in_d_ready                          (auto_inner_logger_in_1_d_ready),
    .auto_in_d_valid                          (auto_inner_logger_in_1_d_valid),
    .auto_in_d_bits_opcode                    (auto_inner_logger_in_1_d_bits_opcode),
    .auto_in_d_bits_param                     (auto_inner_logger_in_1_d_bits_param),
    .auto_in_d_bits_size                      (auto_inner_logger_in_1_d_bits_size),
    .auto_in_d_bits_source                    (auto_inner_logger_in_1_d_bits_source),
    .auto_in_d_bits_sink                      (auto_inner_logger_in_1_d_bits_sink),
    .auto_in_d_bits_denied                    (auto_inner_logger_in_1_d_bits_denied),
    .auto_in_d_bits_data                      (auto_inner_logger_in_1_d_bits_data),
    .auto_in_d_bits_corrupt                   (auto_inner_logger_in_1_d_bits_corrupt),
    .auto_out_a_ready                         (inner_busPMU_auto_in_1_a_ready),
    .auto_out_a_valid                         (inner_logger_1_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_logger_1_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (inner_logger_1_auto_out_a_bits_param),
    .auto_out_a_bits_size                     (inner_logger_1_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_logger_1_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_logger_1_auto_out_a_bits_address),
    .auto_out_a_bits_user_alias               (inner_logger_1_auto_out_a_bits_user_alias),
    .auto_out_a_bits_user_reqSource           (inner_logger_1_auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_user_needHint            (inner_logger_1_auto_out_a_bits_user_needHint),
    .auto_out_a_bits_mask                     (inner_logger_1_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_logger_1_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (inner_logger_1_auto_out_a_bits_corrupt),
    .auto_out_d_ready                         (inner_logger_1_auto_out_d_ready),
    .auto_out_d_valid                         (inner_busPMU_auto_in_1_d_valid),
    .auto_out_d_bits_opcode                   (inner_busPMU_auto_in_1_d_bits_opcode),
    .auto_out_d_bits_param                    (inner_busPMU_auto_in_1_d_bits_param),
    .auto_out_d_bits_size                     (inner_busPMU_auto_in_1_d_bits_size),
    .auto_out_d_bits_source                   (inner_busPMU_auto_in_1_d_bits_source),
    .auto_out_d_bits_sink                     (inner_busPMU_auto_in_1_d_bits_sink),
    .auto_out_d_bits_denied                   (inner_busPMU_auto_in_1_d_bits_denied),
    .auto_out_d_bits_data                     (inner_busPMU_auto_in_1_d_bits_data),
    .auto_out_d_bits_corrupt                  (inner_busPMU_auto_in_1_d_bits_corrupt)
  );
  TLLogger_2 inner_logger_2 (
    .auto_in_a_ready                          (inner_logger_2_auto_in_a_ready),
    .auto_in_a_valid                          (inner_ptw_to_l2_buffer_auto_out_a_valid),
    .auto_in_a_bits_opcode                    (inner_ptw_to_l2_buffer_auto_out_a_bits_opcode),
    .auto_in_a_bits_param                     (inner_ptw_to_l2_buffer_auto_out_a_bits_param),
    .auto_in_a_bits_size                      (inner_ptw_to_l2_buffer_auto_out_a_bits_size),
    .auto_in_a_bits_source                    (inner_ptw_to_l2_buffer_auto_out_a_bits_source),
    .auto_in_a_bits_address                   (inner_ptw_to_l2_buffer_auto_out_a_bits_address),
    .auto_in_a_bits_user_reqSource            (inner_ptw_to_l2_buffer_auto_out_a_bits_user_reqSource),
    .auto_in_a_bits_mask                      (inner_ptw_to_l2_buffer_auto_out_a_bits_mask),
    .auto_in_a_bits_data                      (inner_ptw_to_l2_buffer_auto_out_a_bits_data),
    .auto_in_a_bits_corrupt                   (inner_ptw_to_l2_buffer_auto_out_a_bits_corrupt),
    .auto_in_d_ready                          (inner_ptw_to_l2_buffer_auto_out_d_ready),
    .auto_in_d_valid                          (inner_logger_2_auto_in_d_valid),
    .auto_in_d_bits_opcode                    (inner_logger_2_auto_in_d_bits_opcode),
    .auto_in_d_bits_param                     (inner_logger_2_auto_in_d_bits_param),
    .auto_in_d_bits_size                      (inner_logger_2_auto_in_d_bits_size),
    .auto_in_d_bits_source                    (inner_logger_2_auto_in_d_bits_source),
    .auto_in_d_bits_sink                      (inner_logger_2_auto_in_d_bits_sink),
    .auto_in_d_bits_denied                    (inner_logger_2_auto_in_d_bits_denied),
    .auto_in_d_bits_data                      (inner_logger_2_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt                   (inner_logger_2_auto_in_d_bits_corrupt),
    .auto_out_a_ready                         (inner_busPMU_auto_in_2_a_ready),
    .auto_out_a_valid                         (inner_logger_2_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_logger_2_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (inner_logger_2_auto_out_a_bits_param),
    .auto_out_a_bits_size                     (inner_logger_2_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_logger_2_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_logger_2_auto_out_a_bits_address),
    .auto_out_a_bits_user_reqSource           (inner_logger_2_auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_mask                     (inner_logger_2_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_logger_2_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (inner_logger_2_auto_out_a_bits_corrupt),
    .auto_out_d_ready                         (inner_logger_2_auto_out_d_ready),
    .auto_out_d_valid                         (inner_busPMU_auto_in_2_d_valid),
    .auto_out_d_bits_opcode                   (inner_busPMU_auto_in_2_d_bits_opcode),
    .auto_out_d_bits_param                    (inner_busPMU_auto_in_2_d_bits_param),
    .auto_out_d_bits_size                     (inner_busPMU_auto_in_2_d_bits_size),
    .auto_out_d_bits_source                   (inner_busPMU_auto_in_2_d_bits_source),
    .auto_out_d_bits_sink                     (inner_busPMU_auto_in_2_d_bits_sink),
    .auto_out_d_bits_denied                   (inner_busPMU_auto_in_2_d_bits_denied),
    .auto_out_d_bits_data                     (inner_busPMU_auto_in_2_d_bits_data),
    .auto_out_d_bits_corrupt                  (inner_busPMU_auto_in_2_d_bits_corrupt)
  );
  TLBuffer_6 inner_ptw_to_l2_buffer (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_a_ready                          (auto_inner_ptw_to_l2_buffer_in_a_ready),
    .auto_in_a_valid                          (auto_inner_ptw_to_l2_buffer_in_a_valid),
    .auto_in_a_bits_opcode                    (auto_inner_ptw_to_l2_buffer_in_a_bits_opcode),
    .auto_in_a_bits_param                     (auto_inner_ptw_to_l2_buffer_in_a_bits_param),
    .auto_in_a_bits_size                      (auto_inner_ptw_to_l2_buffer_in_a_bits_size),
    .auto_in_a_bits_source                    (auto_inner_ptw_to_l2_buffer_in_a_bits_source),
    .auto_in_a_bits_address                   (auto_inner_ptw_to_l2_buffer_in_a_bits_address),
    .auto_in_a_bits_user_reqSource            (auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource),
    .auto_in_a_bits_mask                      (auto_inner_ptw_to_l2_buffer_in_a_bits_mask),
    .auto_in_a_bits_data                      (auto_inner_ptw_to_l2_buffer_in_a_bits_data),
    .auto_in_a_bits_corrupt                   (auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt),
    .auto_in_d_ready                          (auto_inner_ptw_to_l2_buffer_in_d_ready),
    .auto_in_d_valid                          (auto_inner_ptw_to_l2_buffer_in_d_valid),
    .auto_in_d_bits_opcode                    (auto_inner_ptw_to_l2_buffer_in_d_bits_opcode),
    .auto_in_d_bits_param                     (auto_inner_ptw_to_l2_buffer_in_d_bits_param),
    .auto_in_d_bits_size                      (auto_inner_ptw_to_l2_buffer_in_d_bits_size),
    .auto_in_d_bits_source                    (auto_inner_ptw_to_l2_buffer_in_d_bits_source),
    .auto_in_d_bits_sink                      (auto_inner_ptw_to_l2_buffer_in_d_bits_sink),
    .auto_in_d_bits_denied                    (auto_inner_ptw_to_l2_buffer_in_d_bits_denied),
    .auto_in_d_bits_data                      (auto_inner_ptw_to_l2_buffer_in_d_bits_data),
    .auto_in_d_bits_corrupt                   (auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt),
    .auto_out_a_ready                         (inner_logger_2_auto_in_a_ready),
    .auto_out_a_valid                         (inner_ptw_to_l2_buffer_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_ptw_to_l2_buffer_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (inner_ptw_to_l2_buffer_auto_out_a_bits_param),
    .auto_out_a_bits_size                     (inner_ptw_to_l2_buffer_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_ptw_to_l2_buffer_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_ptw_to_l2_buffer_auto_out_a_bits_address),
    .auto_out_a_bits_user_reqSource           (inner_ptw_to_l2_buffer_auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_mask                     (inner_ptw_to_l2_buffer_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_ptw_to_l2_buffer_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (inner_ptw_to_l2_buffer_auto_out_a_bits_corrupt),
    .auto_out_d_ready                         (inner_ptw_to_l2_buffer_auto_out_d_ready),
    .auto_out_d_valid                         (inner_logger_2_auto_in_d_valid),
    .auto_out_d_bits_opcode                   (inner_logger_2_auto_in_d_bits_opcode),
    .auto_out_d_bits_param                    (inner_logger_2_auto_in_d_bits_param),
    .auto_out_d_bits_size                     (inner_logger_2_auto_in_d_bits_size),
    .auto_out_d_bits_source                   (inner_logger_2_auto_in_d_bits_source),
    .auto_out_d_bits_sink                     (inner_logger_2_auto_in_d_bits_sink),
    .auto_out_d_bits_denied                   (inner_logger_2_auto_in_d_bits_denied),
    .auto_out_d_bits_data                     (inner_logger_2_auto_in_d_bits_data),
    .auto_out_d_bits_corrupt                  (inner_logger_2_auto_in_d_bits_corrupt)
  );
  TLBuffer_15 inner_i_mmio_buffer (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_a_ready                          (auto_inner_i_mmio_buffer_in_a_ready),
    .auto_in_a_valid                          (auto_inner_i_mmio_buffer_in_a_valid),
    .auto_in_a_bits_opcode                    (4'h4),
    .auto_in_a_bits_param                     (auto_inner_i_mmio_buffer_in_a_bits_param),
    .auto_in_a_bits_size                      (2'h3),
    .auto_in_a_bits_source                    (1'h0),
    .auto_in_a_bits_address                   (auto_inner_i_mmio_buffer_in_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC       (auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM       (auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM),
    .auto_in_a_bits_mask                      (8'hFF),
    .auto_in_a_bits_data                      (64'h0),
    .auto_in_a_bits_corrupt                   (auto_inner_i_mmio_buffer_in_a_bits_corrupt),
    .auto_in_d_ready                          (auto_inner_i_mmio_buffer_in_d_ready),
    .auto_in_d_valid                          (auto_inner_i_mmio_buffer_in_d_valid),
    .auto_in_d_bits_opcode                    (auto_inner_i_mmio_buffer_in_d_bits_opcode),
    .auto_in_d_bits_param                     (auto_inner_i_mmio_buffer_in_d_bits_param),
    .auto_in_d_bits_size                      (auto_inner_i_mmio_buffer_in_d_bits_size),
    .auto_in_d_bits_source                    (auto_inner_i_mmio_buffer_in_d_bits_source),
    .auto_in_d_bits_sink                      (auto_inner_i_mmio_buffer_in_d_bits_sink),
    .auto_in_d_bits_denied                    (auto_inner_i_mmio_buffer_in_d_bits_denied),
    .auto_in_d_bits_data                      (auto_inner_i_mmio_buffer_in_d_bits_data),
    .auto_in_d_bits_corrupt                   (auto_inner_i_mmio_buffer_in_d_bits_corrupt),
    .auto_out_a_ready                         (inner_buffers_1_auto_in_a_ready),
    .auto_out_a_valid                         (inner_i_mmio_buffer_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_i_mmio_buffer_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (inner_i_mmio_buffer_auto_out_a_bits_param),
    .auto_out_a_bits_size                     (inner_i_mmio_buffer_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_i_mmio_buffer_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_i_mmio_buffer_auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC      (inner_i_mmio_buffer_auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM      (inner_i_mmio_buffer_auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_mask                     (inner_i_mmio_buffer_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_i_mmio_buffer_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (inner_i_mmio_buffer_auto_out_a_bits_corrupt),
    .auto_out_d_ready                         (inner_i_mmio_buffer_auto_out_d_ready),
    .auto_out_d_valid                         (inner_buffers_1_auto_in_d_valid),
    .auto_out_d_bits_opcode                   (inner_buffers_1_auto_in_d_bits_opcode),
    .auto_out_d_bits_param                    (inner_buffers_1_auto_in_d_bits_param),
    .auto_out_d_bits_size                     (inner_buffers_1_auto_in_d_bits_size),
    .auto_out_d_bits_source                   (inner_buffers_1_auto_in_d_bits_source),
    .auto_out_d_bits_sink                     (inner_buffers_1_auto_in_d_bits_sink),
    .auto_out_d_bits_denied                   (inner_buffers_1_auto_in_d_bits_denied),
    .auto_out_d_bits_data                     (inner_buffers_1_auto_in_d_bits_data),
    .auto_out_d_bits_corrupt                  (inner_buffers_1_auto_in_d_bits_corrupt)
  );
  IntBuffer inner_intBuffer (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_0                                (inner_beu_io_interrupt),
    .auto_out_0                               (auto_inner_intBuffer_out_0)
  );
  TL2CHICoupledL2 inner_l2cache (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_mmioBridge_mmio_in_a_ready          (inner_l2cache_auto_mmioBridge_mmio_in_a_ready),
    .auto_mmioBridge_mmio_in_a_valid          (inner_buffer_1_auto_out_a_valid),
    .auto_mmioBridge_mmio_in_a_bits_opcode    (inner_buffer_1_auto_out_a_bits_opcode),
    .auto_mmioBridge_mmio_in_a_bits_param     (inner_buffer_1_auto_out_a_bits_param),
    .auto_mmioBridge_mmio_in_a_bits_size      (inner_buffer_1_auto_out_a_bits_size),
    .auto_mmioBridge_mmio_in_a_bits_source    (inner_buffer_1_auto_out_a_bits_source),
    .auto_mmioBridge_mmio_in_a_bits_address   (inner_buffer_1_auto_out_a_bits_address),
    .auto_mmioBridge_mmio_in_a_bits_user_memBackType_MM (inner_buffer_1_auto_out_a_bits_user_memBackType_MM),
    .auto_mmioBridge_mmio_in_a_bits_user_memPageType_NC (inner_buffer_1_auto_out_a_bits_user_memPageType_NC),
    .auto_mmioBridge_mmio_in_a_bits_mask      (inner_buffer_1_auto_out_a_bits_mask),
    .auto_mmioBridge_mmio_in_a_bits_data      (inner_buffer_1_auto_out_a_bits_data),
    .auto_mmioBridge_mmio_in_a_bits_corrupt   (inner_buffer_1_auto_out_a_bits_corrupt),
    .auto_mmioBridge_mmio_in_d_ready          (inner_buffer_1_auto_out_d_ready),
    .auto_mmioBridge_mmio_in_d_valid          (inner_l2cache_auto_mmioBridge_mmio_in_d_valid),
    .auto_mmioBridge_mmio_in_d_bits_opcode    (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_opcode),
    .auto_mmioBridge_mmio_in_d_bits_param     (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_param),
    .auto_mmioBridge_mmio_in_d_bits_size      (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_size),
    .auto_mmioBridge_mmio_in_d_bits_source    (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_source),
    .auto_mmioBridge_mmio_in_d_bits_sink      (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_sink),
    .auto_mmioBridge_mmio_in_d_bits_denied    (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_denied),
    .auto_mmioBridge_mmio_in_d_bits_data      (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_data),
    .auto_mmioBridge_mmio_in_d_bits_corrupt   (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_corrupt),
    .auto_in_3_a_ready                        (inner_l2cache_auto_in_3_a_ready),
    .auto_in_3_a_valid                        (inner_buffer_auto_out_3_a_valid),
    .auto_in_3_a_bits_opcode                  (inner_buffer_auto_out_3_a_bits_opcode),
    .auto_in_3_a_bits_param                   (inner_buffer_auto_out_3_a_bits_param),
    .auto_in_3_a_bits_size                    (inner_buffer_auto_out_3_a_bits_size),
    .auto_in_3_a_bits_source                  (inner_buffer_auto_out_3_a_bits_source),
    .auto_in_3_a_bits_address                 (inner_buffer_auto_out_3_a_bits_address),
    .auto_in_3_a_bits_user_reqSource          (inner_buffer_auto_out_3_a_bits_user_reqSource),
    .auto_in_3_a_bits_user_alias              (inner_buffer_auto_out_3_a_bits_user_alias),
    .auto_in_3_a_bits_user_vaddr              (inner_buffer_auto_out_3_a_bits_user_vaddr),
    .auto_in_3_a_bits_user_needHint           (inner_buffer_auto_out_3_a_bits_user_needHint),
    .auto_in_3_a_bits_echo_isKeyword          (inner_buffer_auto_out_3_a_bits_echo_isKeyword),
    .auto_in_3_a_bits_corrupt                 (inner_buffer_auto_out_3_a_bits_corrupt),
    .auto_in_3_b_ready                        (inner_buffer_auto_out_3_b_ready),
    .auto_in_3_b_valid                        (inner_l2cache_auto_in_3_b_valid),
    .auto_in_3_b_bits_opcode                  (inner_l2cache_auto_in_3_b_bits_opcode),
    .auto_in_3_b_bits_param                   (inner_l2cache_auto_in_3_b_bits_param),
    .auto_in_3_b_bits_address                 (inner_l2cache_auto_in_3_b_bits_address),
    .auto_in_3_b_bits_data                    (inner_l2cache_auto_in_3_b_bits_data),
    .auto_in_3_c_ready                        (inner_l2cache_auto_in_3_c_ready),
    .auto_in_3_c_valid                        (inner_buffer_auto_out_3_c_valid),
    .auto_in_3_c_bits_opcode                  (inner_buffer_auto_out_3_c_bits_opcode),
    .auto_in_3_c_bits_param                   (inner_buffer_auto_out_3_c_bits_param),
    .auto_in_3_c_bits_size                    (inner_buffer_auto_out_3_c_bits_size),
    .auto_in_3_c_bits_source                  (inner_buffer_auto_out_3_c_bits_source),
    .auto_in_3_c_bits_address                 (inner_buffer_auto_out_3_c_bits_address),
    .auto_in_3_c_bits_data                    (inner_buffer_auto_out_3_c_bits_data),
    .auto_in_3_c_bits_corrupt                 (inner_buffer_auto_out_3_c_bits_corrupt),
    .auto_in_3_d_ready                        (inner_buffer_auto_out_3_d_ready),
    .auto_in_3_d_valid                        (inner_l2cache_auto_in_3_d_valid),
    .auto_in_3_d_bits_opcode                  (inner_l2cache_auto_in_3_d_bits_opcode),
    .auto_in_3_d_bits_param                   (inner_l2cache_auto_in_3_d_bits_param),
    .auto_in_3_d_bits_source                  (inner_l2cache_auto_in_3_d_bits_source),
    .auto_in_3_d_bits_sink                    (inner_l2cache_auto_in_3_d_bits_sink),
    .auto_in_3_d_bits_denied                  (inner_l2cache_auto_in_3_d_bits_denied),
    .auto_in_3_d_bits_echo_isKeyword          (inner_l2cache_auto_in_3_d_bits_echo_isKeyword),
    .auto_in_3_d_bits_data                    (inner_l2cache_auto_in_3_d_bits_data),
    .auto_in_3_d_bits_corrupt                 (inner_l2cache_auto_in_3_d_bits_corrupt),
    .auto_in_3_e_valid                        (inner_buffer_auto_out_3_e_valid),
    .auto_in_3_e_bits_sink                    (inner_buffer_auto_out_3_e_bits_sink),
    .auto_in_2_a_ready                        (inner_l2cache_auto_in_2_a_ready),
    .auto_in_2_a_valid                        (inner_buffer_auto_out_2_a_valid),
    .auto_in_2_a_bits_opcode                  (inner_buffer_auto_out_2_a_bits_opcode),
    .auto_in_2_a_bits_param                   (inner_buffer_auto_out_2_a_bits_param),
    .auto_in_2_a_bits_size                    (inner_buffer_auto_out_2_a_bits_size),
    .auto_in_2_a_bits_source                  (inner_buffer_auto_out_2_a_bits_source),
    .auto_in_2_a_bits_address                 (inner_buffer_auto_out_2_a_bits_address),
    .auto_in_2_a_bits_user_reqSource          (inner_buffer_auto_out_2_a_bits_user_reqSource),
    .auto_in_2_a_bits_user_alias              (inner_buffer_auto_out_2_a_bits_user_alias),
    .auto_in_2_a_bits_user_vaddr              (inner_buffer_auto_out_2_a_bits_user_vaddr),
    .auto_in_2_a_bits_user_needHint           (inner_buffer_auto_out_2_a_bits_user_needHint),
    .auto_in_2_a_bits_echo_isKeyword          (inner_buffer_auto_out_2_a_bits_echo_isKeyword),
    .auto_in_2_a_bits_corrupt                 (inner_buffer_auto_out_2_a_bits_corrupt),
    .auto_in_2_b_ready                        (inner_buffer_auto_out_2_b_ready),
    .auto_in_2_b_valid                        (inner_l2cache_auto_in_2_b_valid),
    .auto_in_2_b_bits_opcode                  (inner_l2cache_auto_in_2_b_bits_opcode),
    .auto_in_2_b_bits_param                   (inner_l2cache_auto_in_2_b_bits_param),
    .auto_in_2_b_bits_address                 (inner_l2cache_auto_in_2_b_bits_address),
    .auto_in_2_b_bits_data                    (inner_l2cache_auto_in_2_b_bits_data),
    .auto_in_2_c_ready                        (inner_l2cache_auto_in_2_c_ready),
    .auto_in_2_c_valid                        (inner_buffer_auto_out_2_c_valid),
    .auto_in_2_c_bits_opcode                  (inner_buffer_auto_out_2_c_bits_opcode),
    .auto_in_2_c_bits_param                   (inner_buffer_auto_out_2_c_bits_param),
    .auto_in_2_c_bits_size                    (inner_buffer_auto_out_2_c_bits_size),
    .auto_in_2_c_bits_source                  (inner_buffer_auto_out_2_c_bits_source),
    .auto_in_2_c_bits_address                 (inner_buffer_auto_out_2_c_bits_address),
    .auto_in_2_c_bits_data                    (inner_buffer_auto_out_2_c_bits_data),
    .auto_in_2_c_bits_corrupt                 (inner_buffer_auto_out_2_c_bits_corrupt),
    .auto_in_2_d_ready                        (inner_buffer_auto_out_2_d_ready),
    .auto_in_2_d_valid                        (inner_l2cache_auto_in_2_d_valid),
    .auto_in_2_d_bits_opcode                  (inner_l2cache_auto_in_2_d_bits_opcode),
    .auto_in_2_d_bits_param                   (inner_l2cache_auto_in_2_d_bits_param),
    .auto_in_2_d_bits_source                  (inner_l2cache_auto_in_2_d_bits_source),
    .auto_in_2_d_bits_sink                    (inner_l2cache_auto_in_2_d_bits_sink),
    .auto_in_2_d_bits_denied                  (inner_l2cache_auto_in_2_d_bits_denied),
    .auto_in_2_d_bits_echo_isKeyword          (inner_l2cache_auto_in_2_d_bits_echo_isKeyword),
    .auto_in_2_d_bits_data                    (inner_l2cache_auto_in_2_d_bits_data),
    .auto_in_2_d_bits_corrupt                 (inner_l2cache_auto_in_2_d_bits_corrupt),
    .auto_in_2_e_valid                        (inner_buffer_auto_out_2_e_valid),
    .auto_in_2_e_bits_sink                    (inner_buffer_auto_out_2_e_bits_sink),
    .auto_in_1_a_ready                        (inner_l2cache_auto_in_1_a_ready),
    .auto_in_1_a_valid                        (inner_buffer_auto_out_1_a_valid),
    .auto_in_1_a_bits_opcode                  (inner_buffer_auto_out_1_a_bits_opcode),
    .auto_in_1_a_bits_param                   (inner_buffer_auto_out_1_a_bits_param),
    .auto_in_1_a_bits_size                    (inner_buffer_auto_out_1_a_bits_size),
    .auto_in_1_a_bits_source                  (inner_buffer_auto_out_1_a_bits_source),
    .auto_in_1_a_bits_address                 (inner_buffer_auto_out_1_a_bits_address),
    .auto_in_1_a_bits_user_reqSource          (inner_buffer_auto_out_1_a_bits_user_reqSource),
    .auto_in_1_a_bits_user_alias              (inner_buffer_auto_out_1_a_bits_user_alias),
    .auto_in_1_a_bits_user_vaddr              (inner_buffer_auto_out_1_a_bits_user_vaddr),
    .auto_in_1_a_bits_user_needHint           (inner_buffer_auto_out_1_a_bits_user_needHint),
    .auto_in_1_a_bits_echo_isKeyword          (inner_buffer_auto_out_1_a_bits_echo_isKeyword),
    .auto_in_1_a_bits_corrupt                 (inner_buffer_auto_out_1_a_bits_corrupt),
    .auto_in_1_b_ready                        (inner_buffer_auto_out_1_b_ready),
    .auto_in_1_b_valid                        (inner_l2cache_auto_in_1_b_valid),
    .auto_in_1_b_bits_opcode                  (inner_l2cache_auto_in_1_b_bits_opcode),
    .auto_in_1_b_bits_param                   (inner_l2cache_auto_in_1_b_bits_param),
    .auto_in_1_b_bits_address                 (inner_l2cache_auto_in_1_b_bits_address),
    .auto_in_1_b_bits_data                    (inner_l2cache_auto_in_1_b_bits_data),
    .auto_in_1_c_ready                        (inner_l2cache_auto_in_1_c_ready),
    .auto_in_1_c_valid                        (inner_buffer_auto_out_1_c_valid),
    .auto_in_1_c_bits_opcode                  (inner_buffer_auto_out_1_c_bits_opcode),
    .auto_in_1_c_bits_param                   (inner_buffer_auto_out_1_c_bits_param),
    .auto_in_1_c_bits_size                    (inner_buffer_auto_out_1_c_bits_size),
    .auto_in_1_c_bits_source                  (inner_buffer_auto_out_1_c_bits_source),
    .auto_in_1_c_bits_address                 (inner_buffer_auto_out_1_c_bits_address),
    .auto_in_1_c_bits_data                    (inner_buffer_auto_out_1_c_bits_data),
    .auto_in_1_c_bits_corrupt                 (inner_buffer_auto_out_1_c_bits_corrupt),
    .auto_in_1_d_ready                        (inner_buffer_auto_out_1_d_ready),
    .auto_in_1_d_valid                        (inner_l2cache_auto_in_1_d_valid),
    .auto_in_1_d_bits_opcode                  (inner_l2cache_auto_in_1_d_bits_opcode),
    .auto_in_1_d_bits_param                   (inner_l2cache_auto_in_1_d_bits_param),
    .auto_in_1_d_bits_source                  (inner_l2cache_auto_in_1_d_bits_source),
    .auto_in_1_d_bits_sink                    (inner_l2cache_auto_in_1_d_bits_sink),
    .auto_in_1_d_bits_denied                  (inner_l2cache_auto_in_1_d_bits_denied),
    .auto_in_1_d_bits_echo_isKeyword          (inner_l2cache_auto_in_1_d_bits_echo_isKeyword),
    .auto_in_1_d_bits_data                    (inner_l2cache_auto_in_1_d_bits_data),
    .auto_in_1_d_bits_corrupt                 (inner_l2cache_auto_in_1_d_bits_corrupt),
    .auto_in_1_e_valid                        (inner_buffer_auto_out_1_e_valid),
    .auto_in_1_e_bits_sink                    (inner_buffer_auto_out_1_e_bits_sink),
    .auto_in_0_a_ready                        (inner_l2cache_auto_in_0_a_ready),
    .auto_in_0_a_valid                        (inner_buffer_auto_out_0_a_valid),
    .auto_in_0_a_bits_opcode                  (inner_buffer_auto_out_0_a_bits_opcode),
    .auto_in_0_a_bits_param                   (inner_buffer_auto_out_0_a_bits_param),
    .auto_in_0_a_bits_size                    (inner_buffer_auto_out_0_a_bits_size),
    .auto_in_0_a_bits_source                  (inner_buffer_auto_out_0_a_bits_source),
    .auto_in_0_a_bits_address                 (inner_buffer_auto_out_0_a_bits_address),
    .auto_in_0_a_bits_user_reqSource          (inner_buffer_auto_out_0_a_bits_user_reqSource),
    .auto_in_0_a_bits_user_alias              (inner_buffer_auto_out_0_a_bits_user_alias),
    .auto_in_0_a_bits_user_vaddr              (inner_buffer_auto_out_0_a_bits_user_vaddr),
    .auto_in_0_a_bits_user_needHint           (inner_buffer_auto_out_0_a_bits_user_needHint),
    .auto_in_0_a_bits_echo_isKeyword          (inner_buffer_auto_out_0_a_bits_echo_isKeyword),
    .auto_in_0_a_bits_corrupt                 (inner_buffer_auto_out_0_a_bits_corrupt),
    .auto_in_0_b_ready                        (inner_buffer_auto_out_0_b_ready),
    .auto_in_0_b_valid                        (inner_l2cache_auto_in_0_b_valid),
    .auto_in_0_b_bits_opcode                  (inner_l2cache_auto_in_0_b_bits_opcode),
    .auto_in_0_b_bits_param                   (inner_l2cache_auto_in_0_b_bits_param),
    .auto_in_0_b_bits_address                 (inner_l2cache_auto_in_0_b_bits_address),
    .auto_in_0_b_bits_data                    (inner_l2cache_auto_in_0_b_bits_data),
    .auto_in_0_c_ready                        (inner_l2cache_auto_in_0_c_ready),
    .auto_in_0_c_valid                        (inner_buffer_auto_out_0_c_valid),
    .auto_in_0_c_bits_opcode                  (inner_buffer_auto_out_0_c_bits_opcode),
    .auto_in_0_c_bits_param                   (inner_buffer_auto_out_0_c_bits_param),
    .auto_in_0_c_bits_size                    (inner_buffer_auto_out_0_c_bits_size),
    .auto_in_0_c_bits_source                  (inner_buffer_auto_out_0_c_bits_source),
    .auto_in_0_c_bits_address                 (inner_buffer_auto_out_0_c_bits_address),
    .auto_in_0_c_bits_data                    (inner_buffer_auto_out_0_c_bits_data),
    .auto_in_0_c_bits_corrupt                 (inner_buffer_auto_out_0_c_bits_corrupt),
    .auto_in_0_d_ready                        (inner_buffer_auto_out_0_d_ready),
    .auto_in_0_d_valid                        (inner_l2cache_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode                  (inner_l2cache_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param                   (inner_l2cache_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_source                  (inner_l2cache_auto_in_0_d_bits_source),
    .auto_in_0_d_bits_sink                    (inner_l2cache_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied                  (inner_l2cache_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_echo_isKeyword          (inner_l2cache_auto_in_0_d_bits_echo_isKeyword),
    .auto_in_0_d_bits_data                    (inner_l2cache_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt                 (inner_l2cache_auto_in_0_d_bits_corrupt),
    .auto_in_0_e_valid                        (inner_buffer_auto_out_0_e_valid),
    .auto_in_0_e_bits_sink                    (inner_buffer_auto_out_0_e_bits_sink),
    .auto_pf_recv_in_addr                     (auto_inner_l2cache_pf_recv_in_addr),
    .auto_pf_recv_in_pf_source                (auto_inner_l2cache_pf_recv_in_pf_source),
    .auto_pf_recv_in_addr_valid               (auto_inner_l2cache_pf_recv_in_addr_valid),
    .io_pfCtrlFromCore_l2_pf_master_en        (io_pfCtrlFromCore_l2_pf_master_en),
    .io_pfCtrlFromCore_l2_pf_recv_en          (io_pfCtrlFromCore_l2_pf_recv_en),
    .io_pfCtrlFromCore_l2_pbop_en             (io_pfCtrlFromCore_l2_pbop_en),
    .io_pfCtrlFromCore_l2_vbop_en             (io_pfCtrlFromCore_l2_vbop_en),
    .io_pfCtrlFromCore_l2_pf_delay_latency    (io_pfCtrlFromCore_l2_pf_delay_latency),
    .io_l2_hint_valid                         (io_l2_hint_valid),
    .io_l2_hint_bits_sourceId                 (inner_l2cache_io_l2_hint_bits_sourceId),
    .io_l2_hint_bits_isKeyword                (io_l2_hint_bits_isKeyword),
    .io_l2_tlb_req_req_valid                  (io_l2_tlb_req_req_valid),
    .io_l2_tlb_req_req_bits_vaddr             (io_l2_tlb_req_req_bits_vaddr),
    .io_l2_tlb_req_req_bits_cmd               (io_l2_tlb_req_req_bits_cmd),
    .io_l2_tlb_req_req_bits_isPrefetch        (io_l2_tlb_req_req_bits_isPrefetch),
    .io_l2_tlb_req_req_bits_kill              (io_l2_tlb_req_req_bits_kill),
    .io_l2_tlb_req_req_bits_no_translate      (io_l2_tlb_req_req_bits_no_translate),
    .io_l2_tlb_req_resp_valid                 (io_l2_tlb_req_resp_valid),
    .io_l2_tlb_req_resp_bits_paddr_0          (io_l2_tlb_req_resp_bits_paddr_0),
    .io_l2_tlb_req_resp_bits_pbmt             (io_l2_tlb_req_resp_bits_pbmt_0),
    .io_l2_tlb_req_resp_bits_miss             (io_l2_tlb_req_resp_bits_miss),
    .io_l2_tlb_req_resp_bits_excp_0_gpf_ld    (io_l2_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_pf_ld     (io_l2_tlb_req_resp_bits_excp_0_pf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_af_ld     (io_l2_tlb_req_resp_bits_excp_0_af_ld),
    .io_l2_tlb_req_pmp_resp_ld                (io_l2_pmp_resp_ld),
    .io_l2_tlb_req_pmp_resp_mmio              (io_l2_pmp_resp_mmio),
    .io_debugTopDown_robHeadPaddr_valid       (io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits        (io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l2MissMatch              (io_debugTopDown_l2MissMatch),
    .io_l2Miss                                (io_l2Miss),
    .io_error_valid                           (inner_l2cache_io_error_valid),
    .io_error_address                         (inner_l2cache_io_error_address),
    .io_dft_ram_hold                          (io_dft_ram_hold),
    .io_dft_ram_bypass                        (io_dft_ram_bypass),
    .io_dft_ram_bp_clken                      (io_dft_ram_bp_clken),
    .io_dft_ram_aux_clk                       (io_dft_ram_aux_clk),
    .io_dft_ram_aux_ckbp                      (io_dft_ram_aux_ckbp),
    .io_dft_ram_mcp_hold                      (io_dft_ram_mcp_hold),
    .io_dft_cgen                              (io_dft_cgen),
    .io_perf_1_value                          (io_perfEvents_1_value),
    .io_perf_2_value                          (io_perfEvents_2_value),
    .io_perf_3_value                          (io_perfEvents_3_value),
    .io_perf_4_value                          (io_perfEvents_4_value),
    .io_perf_5_value                          (io_perfEvents_5_value),
    .io_perf_6_value                          (io_perfEvents_6_value),
    .io_perf_7_value                          (io_perfEvents_7_value),
    .io_perf_8_value                          (io_perfEvents_8_value),
    .io_perf_9_value                          (io_perfEvents_9_value),
    .io_perf_10_value                         (io_perfEvents_10_value),
    .io_perf_11_value                         (io_perfEvents_11_value),
    .io_perf_12_value                         (io_perfEvents_12_value),
    .io_perf_13_value                         (io_perfEvents_13_value),
    .io_perf_14_value                         (io_perfEvents_14_value),
    .io_perf_15_value                         (io_perfEvents_15_value),
    .io_perf_16_value                         (io_perfEvents_16_value),
    .io_perf_17_value                         (io_perfEvents_17_value),
    .io_perf_18_value                         (io_perfEvents_18_value),
    .io_perf_19_value                         (io_perfEvents_19_value),
    .io_perf_20_value                         (io_perfEvents_20_value),
    .io_perf_21_value                         (io_perfEvents_21_value),
    .io_perf_22_value                         (io_perfEvents_22_value),
    .io_perf_23_value                         (io_perfEvents_23_value),
    .io_perf_24_value                         (io_perfEvents_24_value),
    .io_perf_25_value                         (io_perfEvents_25_value),
    .io_perf_26_value                         (io_perfEvents_26_value),
    .io_perf_27_value                         (io_perfEvents_27_value),
    .io_perf_28_value                         (io_perfEvents_28_value),
    .io_perf_29_value                         (io_perfEvents_29_value),
    .io_perf_30_value                         (io_perfEvents_30_value),
    .io_perf_31_value                         (io_perfEvents_31_value),
    .io_perf_32_value                         (io_perfEvents_32_value),
    .io_perf_33_value                         (io_perfEvents_33_value),
    .io_perf_34_value                         (io_perfEvents_34_value),
    .io_perf_35_value                         (io_perfEvents_35_value),
    .io_perf_36_value                         (io_perfEvents_36_value),
    .io_perf_37_value                         (io_perfEvents_37_value),
    .io_perf_38_value                         (io_perfEvents_38_value),
    .io_perf_39_value                         (io_perfEvents_39_value),
    .io_perf_40_value                         (io_perfEvents_40_value),
    .io_perf_41_value                         (io_perfEvents_41_value),
    .io_perf_42_value                         (io_perfEvents_42_value),
    .io_perf_43_value                         (io_perfEvents_43_value),
    .io_perf_44_value                         (io_perfEvents_44_value),
    .io_perf_45_value                         (io_perfEvents_45_value),
    .io_perf_46_value                         (io_perfEvents_46_value),
    .io_perf_47_value                         (io_perfEvents_47_value),
    .io_perf_48_value                         (io_perfEvents_48_value),
    .io_perf_49_value                         (io_perfEvents_49_value),
    .io_perf_50_value                         (io_perfEvents_50_value),
    .io_perf_51_value                         (io_perfEvents_51_value),
    .io_perf_52_value                         (io_perfEvents_52_value),
    .io_perf_53_value                         (io_perfEvents_53_value),
    .io_perf_54_value                         (io_perfEvents_54_value),
    .io_perf_55_value                         (io_perfEvents_55_value),
    .io_perf_56_value                         (io_perfEvents_56_value),
    .io_perf_57_value                         (io_perfEvents_57_value),
    .io_perf_58_value                         (io_perfEvents_58_value),
    .io_perf_59_value                         (io_perfEvents_59_value),
    .io_perf_60_value                         (io_perfEvents_60_value),
    .io_perf_61_value                         (io_perfEvents_61_value),
    .io_perf_62_value                         (io_perfEvents_62_value),
    .io_perf_63_value                         (io_perfEvents_63_value),
    .io_perf_64_value                         (io_perfEvents_64_value),
    .io_perf_65_value                         (io_perfEvents_65_value),
    .io_perf_66_value                         (io_perfEvents_66_value),
    .io_perf_67_value                         (io_perfEvents_67_value),
    .io_perf_68_value                         (io_perfEvents_68_value),
    .io_chi_txsactive                         (inner_l2cache_io_chi_txsactive),
    .io_chi_rxsactive                         (io_chi_rxsactive),
    .io_chi_syscoreq                          (inner_l2cache_io_chi_syscoreq),
    .io_chi_syscoack                          (io_chi_syscoack),
    .io_chi_tx_linkactivereq                  (inner_l2cache_io_chi_tx_linkactivereq),
    .io_chi_tx_linkactiveack                  (io_chi_tx_linkactiveack),
    .io_chi_tx_req_flitpend                   (inner_l2cache_io_chi_tx_req_flitpend),
    .io_chi_tx_req_flitv                      (inner_l2cache_io_chi_tx_req_flitv),
    .io_chi_tx_req_flit                       (inner_l2cache_io_chi_tx_req_flit),
    .io_chi_tx_req_lcrdv                      (io_chi_tx_req_lcrdv),
    .io_chi_tx_rsp_flitpend                   (inner_l2cache_io_chi_tx_rsp_flitpend),
    .io_chi_tx_rsp_flitv                      (inner_l2cache_io_chi_tx_rsp_flitv),
    .io_chi_tx_rsp_flit                       (inner_l2cache_io_chi_tx_rsp_flit),
    .io_chi_tx_rsp_lcrdv                      (io_chi_tx_rsp_lcrdv),
    .io_chi_tx_dat_flitpend                   (inner_l2cache_io_chi_tx_dat_flitpend),
    .io_chi_tx_dat_flitv                      (inner_l2cache_io_chi_tx_dat_flitv),
    .io_chi_tx_dat_flit                       (inner_l2cache_io_chi_tx_dat_flit),
    .io_chi_tx_dat_lcrdv                      (io_chi_tx_dat_lcrdv),
    .io_chi_rx_linkactivereq                  (io_chi_rx_linkactivereq),
    .io_chi_rx_linkactiveack                  (inner_l2cache_io_chi_rx_linkactiveack),
    .io_chi_rx_rsp_flitpend                   (io_chi_rx_rsp_flitpend),
    .io_chi_rx_rsp_flitv                      (io_chi_rx_rsp_flitv),
    .io_chi_rx_rsp_flit                       (io_chi_rx_rsp_flit),
    .io_chi_rx_rsp_lcrdv                      (inner_l2cache_io_chi_rx_rsp_lcrdv),
    .io_chi_rx_dat_flitpend                   (io_chi_rx_dat_flitpend),
    .io_chi_rx_dat_flitv                      (io_chi_rx_dat_flitv),
    .io_chi_rx_dat_flit                       (io_chi_rx_dat_flit),
    .io_chi_rx_dat_lcrdv                      (inner_l2cache_io_chi_rx_dat_lcrdv),
    .io_chi_rx_snp_flitpend                   (io_chi_rx_snp_flitpend),
    .io_chi_rx_snp_flitv                      (io_chi_rx_snp_flitv),
    .io_chi_rx_snp_flit                       (io_chi_rx_snp_flit),
    .io_chi_rx_snp_lcrdv                      (inner_l2cache_io_chi_rx_snp_lcrdv),
    .io_nodeID                                (io_nodeID)
  );
  TLBuffer_15 inner_buffers (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_a_ready                          (inner_buffers_auto_in_a_ready),
    .auto_in_a_valid                          (inner_buffers_1_auto_out_a_valid),
    .auto_in_a_bits_opcode                    (inner_buffers_1_auto_out_a_bits_opcode),
    .auto_in_a_bits_param                     (inner_buffers_1_auto_out_a_bits_param),
    .auto_in_a_bits_size                      (inner_buffers_1_auto_out_a_bits_size),
    .auto_in_a_bits_source                    (inner_buffers_1_auto_out_a_bits_source),
    .auto_in_a_bits_address                   (inner_buffers_1_auto_out_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC       (inner_buffers_1_auto_out_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM       (inner_buffers_1_auto_out_a_bits_user_memBackType_MM),
    .auto_in_a_bits_mask                      (inner_buffers_1_auto_out_a_bits_mask),
    .auto_in_a_bits_data                      (inner_buffers_1_auto_out_a_bits_data),
    .auto_in_a_bits_corrupt                   (inner_buffers_1_auto_out_a_bits_corrupt),
    .auto_in_d_ready                          (inner_buffers_1_auto_out_d_ready),
    .auto_in_d_valid                          (inner_buffers_auto_in_d_valid),
    .auto_in_d_bits_opcode                    (inner_buffers_auto_in_d_bits_opcode),
    .auto_in_d_bits_param                     (inner_buffers_auto_in_d_bits_param),
    .auto_in_d_bits_size                      (inner_buffers_auto_in_d_bits_size),
    .auto_in_d_bits_source                    (inner_buffers_auto_in_d_bits_source),
    .auto_in_d_bits_sink                      (inner_buffers_auto_in_d_bits_sink),
    .auto_in_d_bits_denied                    (inner_buffers_auto_in_d_bits_denied),
    .auto_in_d_bits_data                      (inner_buffers_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt                   (inner_buffers_auto_in_d_bits_corrupt),
    .auto_out_a_ready                         (inner_xbar_1_auto_in_0_a_ready),
    .auto_out_a_valid                         (inner_buffers_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_buffers_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (inner_buffers_auto_out_a_bits_param),
    .auto_out_a_bits_size                     (inner_buffers_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_buffers_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_buffers_auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC      (inner_buffers_auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM      (inner_buffers_auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_mask                     (inner_buffers_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_buffers_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (inner_buffers_auto_out_a_bits_corrupt),
    .auto_out_d_ready                         (inner_buffers_auto_out_d_ready),
    .auto_out_d_valid                         (inner_xbar_1_auto_in_0_d_valid),
    .auto_out_d_bits_opcode                   (inner_xbar_1_auto_in_0_d_bits_opcode),
    .auto_out_d_bits_param                    (inner_xbar_1_auto_in_0_d_bits_param),
    .auto_out_d_bits_size                     (inner_xbar_1_auto_in_0_d_bits_size),
    .auto_out_d_bits_source                   (1'h0),
    .auto_out_d_bits_sink                     (inner_xbar_1_auto_in_0_d_bits_sink),
    .auto_out_d_bits_denied                   (inner_xbar_1_auto_in_0_d_bits_denied),
    .auto_out_d_bits_data                     (inner_xbar_1_auto_in_0_d_bits_data),
    .auto_out_d_bits_corrupt                  (inner_xbar_1_auto_in_0_d_bits_corrupt)
  );
  TLBuffer_15 inner_buffers_1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_a_ready                          (inner_buffers_1_auto_in_a_ready),
    .auto_in_a_valid                          (inner_i_mmio_buffer_auto_out_a_valid),
    .auto_in_a_bits_opcode                    (inner_i_mmio_buffer_auto_out_a_bits_opcode),
    .auto_in_a_bits_param                     (inner_i_mmio_buffer_auto_out_a_bits_param),
    .auto_in_a_bits_size                      (inner_i_mmio_buffer_auto_out_a_bits_size),
    .auto_in_a_bits_source                    (inner_i_mmio_buffer_auto_out_a_bits_source),
    .auto_in_a_bits_address                   (inner_i_mmio_buffer_auto_out_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC       (inner_i_mmio_buffer_auto_out_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM       (inner_i_mmio_buffer_auto_out_a_bits_user_memBackType_MM),
    .auto_in_a_bits_mask                      (inner_i_mmio_buffer_auto_out_a_bits_mask),
    .auto_in_a_bits_data                      (inner_i_mmio_buffer_auto_out_a_bits_data),
    .auto_in_a_bits_corrupt                   (inner_i_mmio_buffer_auto_out_a_bits_corrupt),
    .auto_in_d_ready                          (inner_i_mmio_buffer_auto_out_d_ready),
    .auto_in_d_valid                          (inner_buffers_1_auto_in_d_valid),
    .auto_in_d_bits_opcode                    (inner_buffers_1_auto_in_d_bits_opcode),
    .auto_in_d_bits_param                     (inner_buffers_1_auto_in_d_bits_param),
    .auto_in_d_bits_size                      (inner_buffers_1_auto_in_d_bits_size),
    .auto_in_d_bits_source                    (inner_buffers_1_auto_in_d_bits_source),
    .auto_in_d_bits_sink                      (inner_buffers_1_auto_in_d_bits_sink),
    .auto_in_d_bits_denied                    (inner_buffers_1_auto_in_d_bits_denied),
    .auto_in_d_bits_data                      (inner_buffers_1_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt                   (inner_buffers_1_auto_in_d_bits_corrupt),
    .auto_out_a_ready                         (inner_buffers_auto_in_a_ready),
    .auto_out_a_valid                         (inner_buffers_1_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_buffers_1_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (inner_buffers_1_auto_out_a_bits_param),
    .auto_out_a_bits_size                     (inner_buffers_1_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_buffers_1_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_buffers_1_auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC      (inner_buffers_1_auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM      (inner_buffers_1_auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_mask                     (inner_buffers_1_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_buffers_1_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (inner_buffers_1_auto_out_a_bits_corrupt),
    .auto_out_d_ready                         (inner_buffers_1_auto_out_d_ready),
    .auto_out_d_valid                         (inner_buffers_auto_in_d_valid),
    .auto_out_d_bits_opcode                   (inner_buffers_auto_in_d_bits_opcode),
    .auto_out_d_bits_param                    (inner_buffers_auto_in_d_bits_param),
    .auto_out_d_bits_size                     (inner_buffers_auto_in_d_bits_size),
    .auto_out_d_bits_source                   (inner_buffers_auto_in_d_bits_source),
    .auto_out_d_bits_sink                     (inner_buffers_auto_in_d_bits_sink),
    .auto_out_d_bits_denied                   (inner_buffers_auto_in_d_bits_denied),
    .auto_out_d_bits_data                     (inner_buffers_auto_in_d_bits_data),
    .auto_out_d_bits_corrupt                  (inner_buffers_auto_in_d_bits_corrupt)
  );
  TLBuffer_8 inner_buffers_2 (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_a_ready                          (inner_buffers_2_auto_in_a_ready),
    .auto_in_a_valid                          (inner_buffers_3_auto_out_a_valid),
    .auto_in_a_bits_opcode                    (inner_buffers_3_auto_out_a_bits_opcode),
    .auto_in_a_bits_param                     (inner_buffers_3_auto_out_a_bits_param),
    .auto_in_a_bits_size                      (inner_buffers_3_auto_out_a_bits_size),
    .auto_in_a_bits_source                    (inner_buffers_3_auto_out_a_bits_source),
    .auto_in_a_bits_address                   (inner_buffers_3_auto_out_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC       (inner_buffers_3_auto_out_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM       (inner_buffers_3_auto_out_a_bits_user_memBackType_MM),
    .auto_in_a_bits_mask                      (inner_buffers_3_auto_out_a_bits_mask),
    .auto_in_a_bits_data                      (inner_buffers_3_auto_out_a_bits_data),
    .auto_in_a_bits_corrupt                   (inner_buffers_3_auto_out_a_bits_corrupt),
    .auto_in_d_ready                          (inner_buffers_3_auto_out_d_ready),
    .auto_in_d_valid                          (inner_buffers_2_auto_in_d_valid),
    .auto_in_d_bits_opcode                    (inner_buffers_2_auto_in_d_bits_opcode),
    .auto_in_d_bits_param                     (inner_buffers_2_auto_in_d_bits_param),
    .auto_in_d_bits_size                      (inner_buffers_2_auto_in_d_bits_size),
    .auto_in_d_bits_source                    (inner_buffers_2_auto_in_d_bits_source),
    .auto_in_d_bits_sink                      (inner_buffers_2_auto_in_d_bits_sink),
    .auto_in_d_bits_denied                    (inner_buffers_2_auto_in_d_bits_denied),
    .auto_in_d_bits_data                      (inner_buffers_2_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt                   (inner_buffers_2_auto_in_d_bits_corrupt),
    .auto_out_a_ready                         (inner_xbar_1_auto_in_1_a_ready),
    .auto_out_a_valid                         (inner_buffers_2_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_buffers_2_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (inner_buffers_2_auto_out_a_bits_param),
    .auto_out_a_bits_size                     (inner_buffers_2_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_buffers_2_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_buffers_2_auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC      (inner_buffers_2_auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM      (inner_buffers_2_auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_mask                     (inner_buffers_2_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_buffers_2_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (inner_buffers_2_auto_out_a_bits_corrupt),
    .auto_out_d_ready                         (inner_buffers_2_auto_out_d_ready),
    .auto_out_d_valid                         (inner_xbar_1_auto_in_1_d_valid),
    .auto_out_d_bits_opcode                   (inner_xbar_1_auto_in_1_d_bits_opcode),
    .auto_out_d_bits_param                    (inner_xbar_1_auto_in_1_d_bits_param),
    .auto_out_d_bits_size                     (inner_xbar_1_auto_in_1_d_bits_size),
    .auto_out_d_bits_source                   (inner_xbar_1_auto_in_1_d_bits_source),
    .auto_out_d_bits_sink                     (inner_xbar_1_auto_in_1_d_bits_sink),
    .auto_out_d_bits_denied                   (inner_xbar_1_auto_in_1_d_bits_denied),
    .auto_out_d_bits_data                     (inner_xbar_1_auto_in_1_d_bits_data),
    .auto_out_d_bits_corrupt                  (inner_xbar_1_auto_in_1_d_bits_corrupt)
  );
  TLBuffer_8 inner_buffers_3 (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_a_ready                          (auto_inner_buffers_in_a_ready),
    .auto_in_a_valid                          (auto_inner_buffers_in_a_valid),
    .auto_in_a_bits_opcode                    (auto_inner_buffers_in_a_bits_opcode),
    .auto_in_a_bits_param                     (auto_inner_buffers_in_a_bits_param),
    .auto_in_a_bits_size                      (auto_inner_buffers_in_a_bits_size),
    .auto_in_a_bits_source                    (auto_inner_buffers_in_a_bits_source),
    .auto_in_a_bits_address                   (auto_inner_buffers_in_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC       (auto_inner_buffers_in_a_bits_user_memBackType_MM),
    .auto_in_a_bits_user_memBackType_MM       (auto_inner_buffers_in_a_bits_user_memPageType_NC),
    .auto_in_a_bits_mask                      (auto_inner_buffers_in_a_bits_mask),
    .auto_in_a_bits_data                      (auto_inner_buffers_in_a_bits_data),
    .auto_in_a_bits_corrupt                   (auto_inner_buffers_in_a_bits_corrupt),
    .auto_in_d_ready                          (auto_inner_buffers_in_d_ready),
    .auto_in_d_valid                          (auto_inner_buffers_in_d_valid),
    .auto_in_d_bits_opcode                    (auto_inner_buffers_in_d_bits_opcode),
    .auto_in_d_bits_param                     (auto_inner_buffers_in_d_bits_param),
    .auto_in_d_bits_size                      (auto_inner_buffers_in_d_bits_size),
    .auto_in_d_bits_source                    (auto_inner_buffers_in_d_bits_source),
    .auto_in_d_bits_sink                      (auto_inner_buffers_in_d_bits_sink),
    .auto_in_d_bits_denied                    (auto_inner_buffers_in_d_bits_denied),
    .auto_in_d_bits_data                      (auto_inner_buffers_in_d_bits_data),
    .auto_in_d_bits_corrupt                   (auto_inner_buffers_in_d_bits_corrupt),
    .auto_out_a_ready                         (inner_buffers_2_auto_in_a_ready),
    .auto_out_a_valid                         (inner_buffers_3_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_buffers_3_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (inner_buffers_3_auto_out_a_bits_param),
    .auto_out_a_bits_size                     (inner_buffers_3_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_buffers_3_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_buffers_3_auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC      (inner_buffers_3_auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM      (inner_buffers_3_auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_mask                     (inner_buffers_3_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_buffers_3_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (inner_buffers_3_auto_out_a_bits_corrupt),
    .auto_out_d_ready                         (inner_buffers_3_auto_out_d_ready),
    .auto_out_d_valid                         (inner_buffers_2_auto_in_d_valid),
    .auto_out_d_bits_opcode                   (inner_buffers_2_auto_in_d_bits_opcode),
    .auto_out_d_bits_param                    (inner_buffers_2_auto_in_d_bits_param),
    .auto_out_d_bits_size                     (inner_buffers_2_auto_in_d_bits_size),
    .auto_out_d_bits_source                   (inner_buffers_2_auto_in_d_bits_source),
    .auto_out_d_bits_sink                     (inner_buffers_2_auto_in_d_bits_sink),
    .auto_out_d_bits_denied                   (inner_buffers_2_auto_in_d_bits_denied),
    .auto_out_d_bits_data                     (inner_buffers_2_auto_in_d_bits_data),
    .auto_out_d_bits_corrupt                  (inner_buffers_2_auto_in_d_bits_corrupt)
  );
  TLBuffer_20 inner_buffers_4 (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_a_ready                          (inner_buffers_4_auto_in_a_ready),
    .auto_in_a_valid                          (inner_xbar_1_auto_out_0_a_valid),
    .auto_in_a_bits_opcode                    (inner_xbar_1_auto_out_0_a_bits_opcode),
    .auto_in_a_bits_param                     (inner_xbar_1_auto_out_0_a_bits_param),
    .auto_in_a_bits_size                      (inner_xbar_1_auto_out_0_a_bits_size),
    .auto_in_a_bits_source                    (inner_xbar_1_auto_out_0_a_bits_source),
    .auto_in_a_bits_address                   (inner_xbar_1_auto_out_0_a_bits_address),
    .auto_in_a_bits_mask                      (inner_xbar_1_auto_out_0_a_bits_mask),
    .auto_in_a_bits_data                      (inner_xbar_1_auto_out_0_a_bits_data),
    .auto_in_a_bits_corrupt                   (inner_xbar_1_auto_out_0_a_bits_corrupt),
    .auto_in_d_ready                          (inner_xbar_1_auto_out_0_d_ready),
    .auto_in_d_valid                          (inner_buffers_4_auto_in_d_valid),
    .auto_in_d_bits_opcode                    (inner_buffers_4_auto_in_d_bits_opcode),
    .auto_in_d_bits_param                     (inner_buffers_4_auto_in_d_bits_param),
    .auto_in_d_bits_size                      (inner_buffers_4_auto_in_d_bits_size),
    .auto_in_d_bits_source                    (inner_buffers_4_auto_in_d_bits_source),
    .auto_in_d_bits_sink                      (inner_buffers_4_auto_in_d_bits_sink),
    .auto_in_d_bits_denied                    (inner_buffers_4_auto_in_d_bits_denied),
    .auto_in_d_bits_data                      (inner_buffers_4_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt                   (inner_buffers_4_auto_in_d_bits_corrupt),
    .auto_out_a_ready                         (inner_beu_auto_in_a_ready),
    .auto_out_a_valid                         (inner_buffers_4_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_buffers_4_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (),
    .auto_out_a_bits_size                     (inner_buffers_4_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_buffers_4_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_buffers_4_auto_out_a_bits_address),
    .auto_out_a_bits_mask                     (inner_buffers_4_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_buffers_4_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (),
    .auto_out_d_ready                         (inner_buffers_4_auto_out_d_ready),
    .auto_out_d_valid                         (inner_beu_auto_in_d_valid),
    .auto_out_d_bits_opcode                   (inner_beu_auto_in_d_bits_opcode),
    .auto_out_d_bits_param                    (2'h0),
    .auto_out_d_bits_size                     (inner_beu_auto_in_d_bits_size),
    .auto_out_d_bits_source                   (inner_beu_auto_in_d_bits_source),
    .auto_out_d_bits_sink                     (1'h0),
    .auto_out_d_bits_denied                   (1'h0),
    .auto_out_d_bits_data                     (inner_beu_auto_in_d_bits_data),
    .auto_out_d_bits_corrupt                  (1'h0)
  );
  TLBuffer_20 inner_buffers_5 (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_a_ready                          (inner_buffers_5_auto_in_a_ready),
    .auto_in_a_valid                          (inner_xbar_1_auto_out_1_a_valid),
    .auto_in_a_bits_opcode                    (inner_xbar_1_auto_out_1_a_bits_opcode),
    .auto_in_a_bits_param                     (inner_xbar_1_auto_out_1_a_bits_param),
    .auto_in_a_bits_size                      (inner_xbar_1_auto_out_1_a_bits_size),
    .auto_in_a_bits_source                    (inner_xbar_1_auto_out_1_a_bits_source),
    .auto_in_a_bits_address                   (inner_xbar_1_auto_out_1_a_bits_address),
    .auto_in_a_bits_mask                      (inner_xbar_1_auto_out_1_a_bits_mask),
    .auto_in_a_bits_data                      (inner_xbar_1_auto_out_1_a_bits_data),
    .auto_in_a_bits_corrupt                   (inner_xbar_1_auto_out_1_a_bits_corrupt),
    .auto_in_d_ready                          (inner_xbar_1_auto_out_1_d_ready),
    .auto_in_d_valid                          (inner_buffers_5_auto_in_d_valid),
    .auto_in_d_bits_opcode                    (inner_buffers_5_auto_in_d_bits_opcode),
    .auto_in_d_bits_param                     (inner_buffers_5_auto_in_d_bits_param),
    .auto_in_d_bits_size                      (inner_buffers_5_auto_in_d_bits_size),
    .auto_in_d_bits_source                    (inner_buffers_5_auto_in_d_bits_source),
    .auto_in_d_bits_sink                      (inner_buffers_5_auto_in_d_bits_sink),
    .auto_in_d_bits_denied                    (inner_buffers_5_auto_in_d_bits_denied),
    .auto_in_d_bits_data                      (inner_buffers_5_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt                   (inner_buffers_5_auto_in_d_bits_corrupt),
    .auto_out_a_ready                         (auto_inner_buffers_out_a_ready),
    .auto_out_a_valid                         (auto_inner_buffers_out_a_valid),
    .auto_out_a_bits_opcode                   (auto_inner_buffers_out_a_bits_opcode),
    .auto_out_a_bits_param                    (auto_inner_buffers_out_a_bits_param),
    .auto_out_a_bits_size                     (auto_inner_buffers_out_a_bits_size),
    .auto_out_a_bits_source                   (auto_inner_buffers_out_a_bits_source),
    .auto_out_a_bits_address                  (auto_inner_buffers_out_a_bits_address),
    .auto_out_a_bits_mask                     (auto_inner_buffers_out_a_bits_mask),
    .auto_out_a_bits_data                     (auto_inner_buffers_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (auto_inner_buffers_out_a_bits_corrupt),
    .auto_out_d_ready                         (auto_inner_buffers_out_d_ready),
    .auto_out_d_valid                         (auto_inner_buffers_out_d_valid),
    .auto_out_d_bits_opcode                   (auto_inner_buffers_out_d_bits_opcode),
    .auto_out_d_bits_param                    (auto_inner_buffers_out_d_bits_param),
    .auto_out_d_bits_size                     (auto_inner_buffers_out_d_bits_size),
    .auto_out_d_bits_source                   (auto_inner_buffers_out_d_bits_source),
    .auto_out_d_bits_sink                     (auto_inner_buffers_out_d_bits_sink),
    .auto_out_d_bits_denied                   (auto_inner_buffers_out_d_bits_denied),
    .auto_out_d_bits_data                     (auto_inner_buffers_out_d_bits_data),
    .auto_out_d_bits_corrupt                  (auto_inner_buffers_out_d_bits_corrupt)
  );
  TLBuffer_22 inner_buffer_1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .auto_in_a_ready                          (inner_buffer_1_auto_in_a_ready),
    .auto_in_a_valid                          (inner_xbar_1_auto_out_2_a_valid),
    .auto_in_a_bits_opcode                    (inner_xbar_1_auto_out_2_a_bits_opcode),
    .auto_in_a_bits_param                     (inner_xbar_1_auto_out_2_a_bits_param),
    .auto_in_a_bits_size                      (inner_xbar_1_auto_out_2_a_bits_size),
    .auto_in_a_bits_source                    (inner_xbar_1_auto_out_2_a_bits_source),
    .auto_in_a_bits_address                   (inner_xbar_1_auto_out_2_a_bits_address),
    .auto_in_a_bits_user_memBackType_MM       (inner_xbar_1_auto_out_2_a_bits_user_memBackType_MM),
    .auto_in_a_bits_user_memPageType_NC       (inner_xbar_1_auto_out_2_a_bits_user_memPageType_NC),
    .auto_in_a_bits_mask                      (inner_xbar_1_auto_out_2_a_bits_mask),
    .auto_in_a_bits_data                      (inner_xbar_1_auto_out_2_a_bits_data),
    .auto_in_a_bits_corrupt                   (inner_xbar_1_auto_out_2_a_bits_corrupt),
    .auto_in_d_ready                          (inner_xbar_1_auto_out_2_d_ready),
    .auto_in_d_valid                          (inner_buffer_1_auto_in_d_valid),
    .auto_in_d_bits_opcode                    (inner_buffer_1_auto_in_d_bits_opcode),
    .auto_in_d_bits_param                     (inner_buffer_1_auto_in_d_bits_param),
    .auto_in_d_bits_size                      (inner_buffer_1_auto_in_d_bits_size),
    .auto_in_d_bits_source                    (inner_buffer_1_auto_in_d_bits_source),
    .auto_in_d_bits_sink                      (inner_buffer_1_auto_in_d_bits_sink),
    .auto_in_d_bits_denied                    (inner_buffer_1_auto_in_d_bits_denied),
    .auto_in_d_bits_data                      (inner_buffer_1_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt                   (inner_buffer_1_auto_in_d_bits_corrupt),
    .auto_out_a_ready                         (inner_l2cache_auto_mmioBridge_mmio_in_a_ready),
    .auto_out_a_valid                         (inner_buffer_1_auto_out_a_valid),
    .auto_out_a_bits_opcode                   (inner_buffer_1_auto_out_a_bits_opcode),
    .auto_out_a_bits_param                    (inner_buffer_1_auto_out_a_bits_param),
    .auto_out_a_bits_size                     (inner_buffer_1_auto_out_a_bits_size),
    .auto_out_a_bits_source                   (inner_buffer_1_auto_out_a_bits_source),
    .auto_out_a_bits_address                  (inner_buffer_1_auto_out_a_bits_address),
    .auto_out_a_bits_user_memBackType_MM      (inner_buffer_1_auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_user_memPageType_NC      (inner_buffer_1_auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_mask                     (inner_buffer_1_auto_out_a_bits_mask),
    .auto_out_a_bits_data                     (inner_buffer_1_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt                  (inner_buffer_1_auto_out_a_bits_corrupt),
    .auto_out_d_ready                         (inner_buffer_1_auto_out_d_ready),
    .auto_out_d_valid                         (inner_l2cache_auto_mmioBridge_mmio_in_d_valid),
    .auto_out_d_bits_opcode                   (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_opcode),
    .auto_out_d_bits_param                    (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_param),
    .auto_out_d_bits_size                     (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_size),
    .auto_out_d_bits_source                   (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_source),
    .auto_out_d_bits_sink                     (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_sink),
    .auto_out_d_bits_denied                   (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_denied),
    .auto_out_d_bits_data                     (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_data),
    .auto_out_d_bits_corrupt                  (inner_l2cache_auto_mmioBridge_mmio_in_d_bits_corrupt)
  );
  DelayN_334 inner_resetDelayN (
    .clock                                    (clock),
    .io_in                                    (io_reset_vector_fromTile),
    .io_out                                   (io_reset_vector_toCore)
  );
  DelayNWithValid_203 inner_io_clintTime_toCore_pipMod (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_bits                               (io_clintTime_fromTile_bits),
    .io_in_valid                              (io_clintTime_fromTile_valid),
    .io_out_bits                              (io_clintTime_toCore_bits),
    .io_out_valid                             (io_clintTime_toCore_valid)
  );

  // ---- 顶层输出 ----
  assign auto_inner_nmi_int_out_0 = auto_inner_nmi_int_in_0;
  assign auto_inner_nmi_int_out_1 = auto_inner_nmi_int_in_1;
  assign auto_inner_plic_int_out_1_0 = auto_inner_plic_int_in_1_0;
  assign auto_inner_plic_int_out_0_0 = auto_inner_plic_int_in_0_0;
  assign auto_inner_debug_int_out_0 = auto_inner_debug_int_in_0;
  assign auto_inner_clint_int_out_0 = auto_inner_clint_int_in_0;
  assign auto_inner_clint_int_out_1 = auto_inner_clint_int_in_1;
  assign io_hartId_toCore = io_hartId_fromTile;
  assign io_msiInfo_toCore_valid = msiToCore_valid;
  assign io_msiInfo_toCore_bits = msiToCore_bits;
  assign io_msiAck_toTile = io_msiAck_fromCore;
  assign io_cpu_halt_toTile = cpuHaltToTile;
  assign io_cpu_critical_error_toTile = criticalErrorToTile;
  assign io_hartIsInReset_toTile = hartIsInReset;
  assign io_traceCoreInterface_fromCore_fromEncoder_enable = encoderOut_enable;
  assign io_traceCoreInterface_fromCore_fromEncoder_stall = encoderOut_stall;
  assign io_traceCoreInterface_toTile_toEncoder_priv = traceOut_priv;
  assign io_traceCoreInterface_toTile_toEncoder_mstatus = traceOut_mstatus;
  assign io_traceCoreInterface_toTile_toEncoder_trap_cause = traceOut_trapCause;
  assign io_traceCoreInterface_toTile_toEncoder_trap_tval = traceOut_trapTval;
  assign io_traceCoreInterface_toTile_toEncoder_groups_0_valid = traceOut_valid[0];
  assign io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr = traceOut_iaddr[0];
  assign io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype = traceOut_itype[0];
  assign io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire = traceOut_iretire[0];
  assign io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize = traceOut_ilastsize[0];
  assign io_traceCoreInterface_toTile_toEncoder_groups_1_valid = traceOut_valid[1];
  assign io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr = traceOut_iaddr[1];
  assign io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype = traceOut_itype[1];
  assign io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire = traceOut_iretire[1];
  assign io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize = traceOut_ilastsize[1];
  assign io_traceCoreInterface_toTile_toEncoder_groups_2_valid = traceOut_valid[2];
  assign io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr = traceOut_iaddr[2];
  assign io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype = traceOut_itype[2];
  assign io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire = traceOut_iretire[2];
  assign io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize = traceOut_ilastsize[2];
  assign io_l3Miss_toCore = l3MissToCore;
  assign io_chi_txsactive = inner_l2cache_io_chi_txsactive;
  assign io_chi_syscoreq = inner_l2cache_io_chi_syscoreq;
  assign io_chi_tx_linkactivereq = inner_l2cache_io_chi_tx_linkactivereq;
  assign io_chi_tx_req_flitpend = inner_l2cache_io_chi_tx_req_flitpend;
  assign io_chi_tx_req_flitv = inner_l2cache_io_chi_tx_req_flitv;
  assign io_chi_tx_req_flit = inner_l2cache_io_chi_tx_req_flit;
  assign io_chi_tx_rsp_flitpend = inner_l2cache_io_chi_tx_rsp_flitpend;
  assign io_chi_tx_rsp_flitv = inner_l2cache_io_chi_tx_rsp_flitv;
  assign io_chi_tx_rsp_flit = inner_l2cache_io_chi_tx_rsp_flit;
  assign io_chi_tx_dat_flitpend = inner_l2cache_io_chi_tx_dat_flitpend;
  assign io_chi_tx_dat_flitv = inner_l2cache_io_chi_tx_dat_flitv;
  assign io_chi_tx_dat_flit = inner_l2cache_io_chi_tx_dat_flit;
  assign io_chi_rx_linkactiveack = inner_l2cache_io_chi_rx_linkactiveack;
  assign io_chi_rx_rsp_lcrdv = inner_l2cache_io_chi_rx_rsp_lcrdv;
  assign io_chi_rx_dat_lcrdv = inner_l2cache_io_chi_rx_dat_lcrdv;
  assign io_chi_rx_snp_lcrdv = inner_l2cache_io_chi_rx_snp_lcrdv;
  assign io_l2_hint_bits_sourceId = inner_l2cache_io_l2_hint_bits_sourceId[3:0];

endmodule
// END GENERATED
