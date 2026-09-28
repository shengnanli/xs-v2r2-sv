// =============================================================================
// Arbiter16_MainPipeReq —— MissQueue 的 16 路 refill 请求仲裁器
//                          （xs_FixedPriorityArbiter_core 家族的一个变体）
//
// 位置：DCache MissQueue 出口。16 个 MissEntry（MSHR）各自在"数据回来了 / L2 hint 到了"
//   之后要进 MainPipe 做一次 refill（写 tag/meta/data、AMO 执行），它们在这里并成一路，
//   再送进 MainPipe s0 的 Arbiter4_MainPipeReq（第 1 路 refill）。
//   Scala：MissQueue.scala `arbiter(entries.map(_.io.main_pipe_req), io.main_pipe_req, ...)`
//   —— 即 chisel3.util.Arbiter：lowest-index-wins、无锁定、纯组合（见 xs_FixedPriorityArbiter_core.sv）。
//
// 本变体的参数与规模（按 G1 golden 现读）：
//   入口数 NUM_IN = 16；载荷 WIDTH = 401 位 = MainPipeReq 在 golden 端口上保留下来的 14 个字段
//   （见下面 miss_refill_req_t）。16 路字段集合完全相同 —— MissEntry 送出的
//   miss/probe 等常量字段已经被 firtool 折到下游 Arbiter4_MainPipeReq 里，这里一个常量都没有。
//   golden 端口 272 个 = 16 × (ready + valid + 14 载荷) + out_ready/out_valid + 14 载荷；
//   纯组合，无寄存器 / 无子模块。
//
// 结构：golden 同名端口表 -> 每路 14 个字段按输出端口顺序 MSB 优先拼成 401 位 ->
//   按"优先级从高到低"MSB 优先拼成 in_bits -> 例化 xs_FixedPriorityArbiter_core -> 拆包到输出。
//   端口表与逐路拼包是纯机械部分，由 scripts/gen_missq.py 从 golden 端口表生成（GENERATED 区）。
// =============================================================================

module Arbiter16_MainPipeReq(
  // BEGIN GENERATED(arb16-ports)
  output         io_in_0_ready,
  input          io_in_0_valid,
  input  [3:0]   io_in_0_bits_miss_id,
  input  [3:0]   io_in_0_bits_occupy_way,
  input          io_in_0_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_0_bits_source,
  input  [4:0]   io_in_0_bits_cmd,
  input  [49:0]  io_in_0_bits_vaddr,
  input  [47:0]  io_in_0_bits_addr,
  input  [2:0]   io_in_0_bits_word_idx,
  input  [127:0] io_in_0_bits_amo_data,
  input  [15:0]  io_in_0_bits_amo_mask,
  input  [127:0] io_in_0_bits_amo_cmp,
  input  [2:0]   io_in_0_bits_pf_source,
  input          io_in_0_bits_access,
  input  [5:0]   io_in_0_bits_id,
  output         io_in_1_ready,
  input          io_in_1_valid,
  input  [3:0]   io_in_1_bits_miss_id,
  input  [3:0]   io_in_1_bits_occupy_way,
  input          io_in_1_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_1_bits_source,
  input  [4:0]   io_in_1_bits_cmd,
  input  [49:0]  io_in_1_bits_vaddr,
  input  [47:0]  io_in_1_bits_addr,
  input  [2:0]   io_in_1_bits_word_idx,
  input  [127:0] io_in_1_bits_amo_data,
  input  [15:0]  io_in_1_bits_amo_mask,
  input  [127:0] io_in_1_bits_amo_cmp,
  input  [2:0]   io_in_1_bits_pf_source,
  input          io_in_1_bits_access,
  input  [5:0]   io_in_1_bits_id,
  output         io_in_2_ready,
  input          io_in_2_valid,
  input  [3:0]   io_in_2_bits_miss_id,
  input  [3:0]   io_in_2_bits_occupy_way,
  input          io_in_2_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_2_bits_source,
  input  [4:0]   io_in_2_bits_cmd,
  input  [49:0]  io_in_2_bits_vaddr,
  input  [47:0]  io_in_2_bits_addr,
  input  [2:0]   io_in_2_bits_word_idx,
  input  [127:0] io_in_2_bits_amo_data,
  input  [15:0]  io_in_2_bits_amo_mask,
  input  [127:0] io_in_2_bits_amo_cmp,
  input  [2:0]   io_in_2_bits_pf_source,
  input          io_in_2_bits_access,
  input  [5:0]   io_in_2_bits_id,
  output         io_in_3_ready,
  input          io_in_3_valid,
  input  [3:0]   io_in_3_bits_miss_id,
  input  [3:0]   io_in_3_bits_occupy_way,
  input          io_in_3_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_3_bits_source,
  input  [4:0]   io_in_3_bits_cmd,
  input  [49:0]  io_in_3_bits_vaddr,
  input  [47:0]  io_in_3_bits_addr,
  input  [2:0]   io_in_3_bits_word_idx,
  input  [127:0] io_in_3_bits_amo_data,
  input  [15:0]  io_in_3_bits_amo_mask,
  input  [127:0] io_in_3_bits_amo_cmp,
  input  [2:0]   io_in_3_bits_pf_source,
  input          io_in_3_bits_access,
  input  [5:0]   io_in_3_bits_id,
  output         io_in_4_ready,
  input          io_in_4_valid,
  input  [3:0]   io_in_4_bits_miss_id,
  input  [3:0]   io_in_4_bits_occupy_way,
  input          io_in_4_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_4_bits_source,
  input  [4:0]   io_in_4_bits_cmd,
  input  [49:0]  io_in_4_bits_vaddr,
  input  [47:0]  io_in_4_bits_addr,
  input  [2:0]   io_in_4_bits_word_idx,
  input  [127:0] io_in_4_bits_amo_data,
  input  [15:0]  io_in_4_bits_amo_mask,
  input  [127:0] io_in_4_bits_amo_cmp,
  input  [2:0]   io_in_4_bits_pf_source,
  input          io_in_4_bits_access,
  input  [5:0]   io_in_4_bits_id,
  output         io_in_5_ready,
  input          io_in_5_valid,
  input  [3:0]   io_in_5_bits_miss_id,
  input  [3:0]   io_in_5_bits_occupy_way,
  input          io_in_5_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_5_bits_source,
  input  [4:0]   io_in_5_bits_cmd,
  input  [49:0]  io_in_5_bits_vaddr,
  input  [47:0]  io_in_5_bits_addr,
  input  [2:0]   io_in_5_bits_word_idx,
  input  [127:0] io_in_5_bits_amo_data,
  input  [15:0]  io_in_5_bits_amo_mask,
  input  [127:0] io_in_5_bits_amo_cmp,
  input  [2:0]   io_in_5_bits_pf_source,
  input          io_in_5_bits_access,
  input  [5:0]   io_in_5_bits_id,
  output         io_in_6_ready,
  input          io_in_6_valid,
  input  [3:0]   io_in_6_bits_miss_id,
  input  [3:0]   io_in_6_bits_occupy_way,
  input          io_in_6_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_6_bits_source,
  input  [4:0]   io_in_6_bits_cmd,
  input  [49:0]  io_in_6_bits_vaddr,
  input  [47:0]  io_in_6_bits_addr,
  input  [2:0]   io_in_6_bits_word_idx,
  input  [127:0] io_in_6_bits_amo_data,
  input  [15:0]  io_in_6_bits_amo_mask,
  input  [127:0] io_in_6_bits_amo_cmp,
  input  [2:0]   io_in_6_bits_pf_source,
  input          io_in_6_bits_access,
  input  [5:0]   io_in_6_bits_id,
  output         io_in_7_ready,
  input          io_in_7_valid,
  input  [3:0]   io_in_7_bits_miss_id,
  input  [3:0]   io_in_7_bits_occupy_way,
  input          io_in_7_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_7_bits_source,
  input  [4:0]   io_in_7_bits_cmd,
  input  [49:0]  io_in_7_bits_vaddr,
  input  [47:0]  io_in_7_bits_addr,
  input  [2:0]   io_in_7_bits_word_idx,
  input  [127:0] io_in_7_bits_amo_data,
  input  [15:0]  io_in_7_bits_amo_mask,
  input  [127:0] io_in_7_bits_amo_cmp,
  input  [2:0]   io_in_7_bits_pf_source,
  input          io_in_7_bits_access,
  input  [5:0]   io_in_7_bits_id,
  output         io_in_8_ready,
  input          io_in_8_valid,
  input  [3:0]   io_in_8_bits_miss_id,
  input  [3:0]   io_in_8_bits_occupy_way,
  input          io_in_8_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_8_bits_source,
  input  [4:0]   io_in_8_bits_cmd,
  input  [49:0]  io_in_8_bits_vaddr,
  input  [47:0]  io_in_8_bits_addr,
  input  [2:0]   io_in_8_bits_word_idx,
  input  [127:0] io_in_8_bits_amo_data,
  input  [15:0]  io_in_8_bits_amo_mask,
  input  [127:0] io_in_8_bits_amo_cmp,
  input  [2:0]   io_in_8_bits_pf_source,
  input          io_in_8_bits_access,
  input  [5:0]   io_in_8_bits_id,
  output         io_in_9_ready,
  input          io_in_9_valid,
  input  [3:0]   io_in_9_bits_miss_id,
  input  [3:0]   io_in_9_bits_occupy_way,
  input          io_in_9_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_9_bits_source,
  input  [4:0]   io_in_9_bits_cmd,
  input  [49:0]  io_in_9_bits_vaddr,
  input  [47:0]  io_in_9_bits_addr,
  input  [2:0]   io_in_9_bits_word_idx,
  input  [127:0] io_in_9_bits_amo_data,
  input  [15:0]  io_in_9_bits_amo_mask,
  input  [127:0] io_in_9_bits_amo_cmp,
  input  [2:0]   io_in_9_bits_pf_source,
  input          io_in_9_bits_access,
  input  [5:0]   io_in_9_bits_id,
  output         io_in_10_ready,
  input          io_in_10_valid,
  input  [3:0]   io_in_10_bits_miss_id,
  input  [3:0]   io_in_10_bits_occupy_way,
  input          io_in_10_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_10_bits_source,
  input  [4:0]   io_in_10_bits_cmd,
  input  [49:0]  io_in_10_bits_vaddr,
  input  [47:0]  io_in_10_bits_addr,
  input  [2:0]   io_in_10_bits_word_idx,
  input  [127:0] io_in_10_bits_amo_data,
  input  [15:0]  io_in_10_bits_amo_mask,
  input  [127:0] io_in_10_bits_amo_cmp,
  input  [2:0]   io_in_10_bits_pf_source,
  input          io_in_10_bits_access,
  input  [5:0]   io_in_10_bits_id,
  output         io_in_11_ready,
  input          io_in_11_valid,
  input  [3:0]   io_in_11_bits_miss_id,
  input  [3:0]   io_in_11_bits_occupy_way,
  input          io_in_11_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_11_bits_source,
  input  [4:0]   io_in_11_bits_cmd,
  input  [49:0]  io_in_11_bits_vaddr,
  input  [47:0]  io_in_11_bits_addr,
  input  [2:0]   io_in_11_bits_word_idx,
  input  [127:0] io_in_11_bits_amo_data,
  input  [15:0]  io_in_11_bits_amo_mask,
  input  [127:0] io_in_11_bits_amo_cmp,
  input  [2:0]   io_in_11_bits_pf_source,
  input          io_in_11_bits_access,
  input  [5:0]   io_in_11_bits_id,
  output         io_in_12_ready,
  input          io_in_12_valid,
  input  [3:0]   io_in_12_bits_miss_id,
  input  [3:0]   io_in_12_bits_occupy_way,
  input          io_in_12_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_12_bits_source,
  input  [4:0]   io_in_12_bits_cmd,
  input  [49:0]  io_in_12_bits_vaddr,
  input  [47:0]  io_in_12_bits_addr,
  input  [2:0]   io_in_12_bits_word_idx,
  input  [127:0] io_in_12_bits_amo_data,
  input  [15:0]  io_in_12_bits_amo_mask,
  input  [127:0] io_in_12_bits_amo_cmp,
  input  [2:0]   io_in_12_bits_pf_source,
  input          io_in_12_bits_access,
  input  [5:0]   io_in_12_bits_id,
  output         io_in_13_ready,
  input          io_in_13_valid,
  input  [3:0]   io_in_13_bits_miss_id,
  input  [3:0]   io_in_13_bits_occupy_way,
  input          io_in_13_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_13_bits_source,
  input  [4:0]   io_in_13_bits_cmd,
  input  [49:0]  io_in_13_bits_vaddr,
  input  [47:0]  io_in_13_bits_addr,
  input  [2:0]   io_in_13_bits_word_idx,
  input  [127:0] io_in_13_bits_amo_data,
  input  [15:0]  io_in_13_bits_amo_mask,
  input  [127:0] io_in_13_bits_amo_cmp,
  input  [2:0]   io_in_13_bits_pf_source,
  input          io_in_13_bits_access,
  input  [5:0]   io_in_13_bits_id,
  output         io_in_14_ready,
  input          io_in_14_valid,
  input  [3:0]   io_in_14_bits_miss_id,
  input  [3:0]   io_in_14_bits_occupy_way,
  input          io_in_14_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_14_bits_source,
  input  [4:0]   io_in_14_bits_cmd,
  input  [49:0]  io_in_14_bits_vaddr,
  input  [47:0]  io_in_14_bits_addr,
  input  [2:0]   io_in_14_bits_word_idx,
  input  [127:0] io_in_14_bits_amo_data,
  input  [15:0]  io_in_14_bits_amo_mask,
  input  [127:0] io_in_14_bits_amo_cmp,
  input  [2:0]   io_in_14_bits_pf_source,
  input          io_in_14_bits_access,
  input  [5:0]   io_in_14_bits_id,
  output         io_in_15_ready,
  input          io_in_15_valid,
  input  [3:0]   io_in_15_bits_miss_id,
  input  [3:0]   io_in_15_bits_occupy_way,
  input          io_in_15_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_in_15_bits_source,
  input  [4:0]   io_in_15_bits_cmd,
  input  [49:0]  io_in_15_bits_vaddr,
  input  [47:0]  io_in_15_bits_addr,
  input  [2:0]   io_in_15_bits_word_idx,
  input  [127:0] io_in_15_bits_amo_data,
  input  [15:0]  io_in_15_bits_amo_mask,
  input  [127:0] io_in_15_bits_amo_cmp,
  input  [2:0]   io_in_15_bits_pf_source,
  input          io_in_15_bits_access,
  input  [5:0]   io_in_15_bits_id,
  input          io_out_ready,
  output         io_out_valid,
  output [3:0]   io_out_bits_miss_id,
  output [3:0]   io_out_bits_occupy_way,
  output         io_out_bits_miss_fail_cause_evict_btot,
  output [3:0]   io_out_bits_source,
  output [4:0]   io_out_bits_cmd,
  output [49:0]  io_out_bits_vaddr,
  output [47:0]  io_out_bits_addr,
  output [2:0]   io_out_bits_word_idx,
  output [127:0] io_out_bits_amo_data,
  output [15:0]  io_out_bits_amo_mask,
  output [127:0] io_out_bits_amo_cmp,
  output [2:0]   io_out_bits_pf_source,
  output         io_out_bits_access,
  output [5:0]   io_out_bits_id
  // END GENERATED
);

  // MissEntry 的 refill 请求在仲裁器端口上保留下来的字段（顺序 = golden 输出端口顺序）
  typedef struct packed {
    logic [3:0]   miss_id;                     // 发请求的 MSHR 号（MainPipe 回应时按它找回表项）
    logic [3:0]   occupy_way;                  // BtoT 升权失败时指定要占的路
    logic         miss_fail_cause_evict_btot;  // 置 1 时替换路用 occupy_way
    logic [3:0]   source;                      // 原始请求来源（0 load/1 store/2 amo/>=3 预取）
    logic [4:0]   cmd;                         // 内存命令
    logic [49:0]  vaddr;                       // 取 set 下标用
    logic [47:0]  addr;                        // 物理地址（行对齐）
    logic [2:0]   word_idx;                    // AMO 作用的 64 位字
    logic [127:0] amo_data;                    // AMO 操作数
    logic [15:0]  amo_mask;                    // AMO 字节掩码
    logic [127:0] amo_cmp;                     // AMOCAS 的比较值
    logic [2:0]   pf_source;                   // 预取来源
    logic         access;                      // 该行是否被非预取请求访问过
    logic [5:0]   id;                          // 原始请求 id
  } miss_refill_req_t;

  localparam int unsigned NUM_IN = 16;
  localparam int unsigned WIDTH  = $bits(miss_refill_req_t);   // 401

  // golden 端口数恒等式：272 个端口，其中 *_bits_* 载荷端口 16*14 + 14 = 238 个
  localparam int unsigned GOLDEN_PORTS      = 272;
  localparam int unsigned GOLDEN_BITS_PORTS = 238;

  // way_req[k] = 第 k 路（k 越小优先级越高）的载荷
  miss_refill_req_t        way_req [NUM_IN];
  // 核的约定：高位段 / 高位 valid = 第 0 路（优先级最高）
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  miss_refill_req_t        out_req;

  for (genvar k = 0; k < NUM_IN; k++) begin : g_pack
    assign in_bits_flat[(NUM_IN-1-k)*WIDTH +: WIDTH] = way_req[k];
  end

  // BEGIN GENERATED(arb16-ways)
  assign way_req[0] = {io_in_0_bits_miss_id, io_in_0_bits_occupy_way,
                       io_in_0_bits_miss_fail_cause_evict_btot, io_in_0_bits_source,
                       io_in_0_bits_cmd, io_in_0_bits_vaddr, io_in_0_bits_addr,
                       io_in_0_bits_word_idx, io_in_0_bits_amo_data, io_in_0_bits_amo_mask,
                       io_in_0_bits_amo_cmp, io_in_0_bits_pf_source, io_in_0_bits_access,
                       io_in_0_bits_id};
  assign way_req[1] = {io_in_1_bits_miss_id, io_in_1_bits_occupy_way,
                       io_in_1_bits_miss_fail_cause_evict_btot, io_in_1_bits_source,
                       io_in_1_bits_cmd, io_in_1_bits_vaddr, io_in_1_bits_addr,
                       io_in_1_bits_word_idx, io_in_1_bits_amo_data, io_in_1_bits_amo_mask,
                       io_in_1_bits_amo_cmp, io_in_1_bits_pf_source, io_in_1_bits_access,
                       io_in_1_bits_id};
  assign way_req[2] = {io_in_2_bits_miss_id, io_in_2_bits_occupy_way,
                       io_in_2_bits_miss_fail_cause_evict_btot, io_in_2_bits_source,
                       io_in_2_bits_cmd, io_in_2_bits_vaddr, io_in_2_bits_addr,
                       io_in_2_bits_word_idx, io_in_2_bits_amo_data, io_in_2_bits_amo_mask,
                       io_in_2_bits_amo_cmp, io_in_2_bits_pf_source, io_in_2_bits_access,
                       io_in_2_bits_id};
  assign way_req[3] = {io_in_3_bits_miss_id, io_in_3_bits_occupy_way,
                       io_in_3_bits_miss_fail_cause_evict_btot, io_in_3_bits_source,
                       io_in_3_bits_cmd, io_in_3_bits_vaddr, io_in_3_bits_addr,
                       io_in_3_bits_word_idx, io_in_3_bits_amo_data, io_in_3_bits_amo_mask,
                       io_in_3_bits_amo_cmp, io_in_3_bits_pf_source, io_in_3_bits_access,
                       io_in_3_bits_id};
  assign way_req[4] = {io_in_4_bits_miss_id, io_in_4_bits_occupy_way,
                       io_in_4_bits_miss_fail_cause_evict_btot, io_in_4_bits_source,
                       io_in_4_bits_cmd, io_in_4_bits_vaddr, io_in_4_bits_addr,
                       io_in_4_bits_word_idx, io_in_4_bits_amo_data, io_in_4_bits_amo_mask,
                       io_in_4_bits_amo_cmp, io_in_4_bits_pf_source, io_in_4_bits_access,
                       io_in_4_bits_id};
  assign way_req[5] = {io_in_5_bits_miss_id, io_in_5_bits_occupy_way,
                       io_in_5_bits_miss_fail_cause_evict_btot, io_in_5_bits_source,
                       io_in_5_bits_cmd, io_in_5_bits_vaddr, io_in_5_bits_addr,
                       io_in_5_bits_word_idx, io_in_5_bits_amo_data, io_in_5_bits_amo_mask,
                       io_in_5_bits_amo_cmp, io_in_5_bits_pf_source, io_in_5_bits_access,
                       io_in_5_bits_id};
  assign way_req[6] = {io_in_6_bits_miss_id, io_in_6_bits_occupy_way,
                       io_in_6_bits_miss_fail_cause_evict_btot, io_in_6_bits_source,
                       io_in_6_bits_cmd, io_in_6_bits_vaddr, io_in_6_bits_addr,
                       io_in_6_bits_word_idx, io_in_6_bits_amo_data, io_in_6_bits_amo_mask,
                       io_in_6_bits_amo_cmp, io_in_6_bits_pf_source, io_in_6_bits_access,
                       io_in_6_bits_id};
  assign way_req[7] = {io_in_7_bits_miss_id, io_in_7_bits_occupy_way,
                       io_in_7_bits_miss_fail_cause_evict_btot, io_in_7_bits_source,
                       io_in_7_bits_cmd, io_in_7_bits_vaddr, io_in_7_bits_addr,
                       io_in_7_bits_word_idx, io_in_7_bits_amo_data, io_in_7_bits_amo_mask,
                       io_in_7_bits_amo_cmp, io_in_7_bits_pf_source, io_in_7_bits_access,
                       io_in_7_bits_id};
  assign way_req[8] = {io_in_8_bits_miss_id, io_in_8_bits_occupy_way,
                       io_in_8_bits_miss_fail_cause_evict_btot, io_in_8_bits_source,
                       io_in_8_bits_cmd, io_in_8_bits_vaddr, io_in_8_bits_addr,
                       io_in_8_bits_word_idx, io_in_8_bits_amo_data, io_in_8_bits_amo_mask,
                       io_in_8_bits_amo_cmp, io_in_8_bits_pf_source, io_in_8_bits_access,
                       io_in_8_bits_id};
  assign way_req[9] = {io_in_9_bits_miss_id, io_in_9_bits_occupy_way,
                       io_in_9_bits_miss_fail_cause_evict_btot, io_in_9_bits_source,
                       io_in_9_bits_cmd, io_in_9_bits_vaddr, io_in_9_bits_addr,
                       io_in_9_bits_word_idx, io_in_9_bits_amo_data, io_in_9_bits_amo_mask,
                       io_in_9_bits_amo_cmp, io_in_9_bits_pf_source, io_in_9_bits_access,
                       io_in_9_bits_id};
  assign way_req[10] = {io_in_10_bits_miss_id, io_in_10_bits_occupy_way,
                        io_in_10_bits_miss_fail_cause_evict_btot, io_in_10_bits_source,
                        io_in_10_bits_cmd, io_in_10_bits_vaddr, io_in_10_bits_addr,
                        io_in_10_bits_word_idx, io_in_10_bits_amo_data, io_in_10_bits_amo_mask,
                        io_in_10_bits_amo_cmp, io_in_10_bits_pf_source, io_in_10_bits_access,
                        io_in_10_bits_id};
  assign way_req[11] = {io_in_11_bits_miss_id, io_in_11_bits_occupy_way,
                        io_in_11_bits_miss_fail_cause_evict_btot, io_in_11_bits_source,
                        io_in_11_bits_cmd, io_in_11_bits_vaddr, io_in_11_bits_addr,
                        io_in_11_bits_word_idx, io_in_11_bits_amo_data, io_in_11_bits_amo_mask,
                        io_in_11_bits_amo_cmp, io_in_11_bits_pf_source, io_in_11_bits_access,
                        io_in_11_bits_id};
  assign way_req[12] = {io_in_12_bits_miss_id, io_in_12_bits_occupy_way,
                        io_in_12_bits_miss_fail_cause_evict_btot, io_in_12_bits_source,
                        io_in_12_bits_cmd, io_in_12_bits_vaddr, io_in_12_bits_addr,
                        io_in_12_bits_word_idx, io_in_12_bits_amo_data, io_in_12_bits_amo_mask,
                        io_in_12_bits_amo_cmp, io_in_12_bits_pf_source, io_in_12_bits_access,
                        io_in_12_bits_id};
  assign way_req[13] = {io_in_13_bits_miss_id, io_in_13_bits_occupy_way,
                        io_in_13_bits_miss_fail_cause_evict_btot, io_in_13_bits_source,
                        io_in_13_bits_cmd, io_in_13_bits_vaddr, io_in_13_bits_addr,
                        io_in_13_bits_word_idx, io_in_13_bits_amo_data, io_in_13_bits_amo_mask,
                        io_in_13_bits_amo_cmp, io_in_13_bits_pf_source, io_in_13_bits_access,
                        io_in_13_bits_id};
  assign way_req[14] = {io_in_14_bits_miss_id, io_in_14_bits_occupy_way,
                        io_in_14_bits_miss_fail_cause_evict_btot, io_in_14_bits_source,
                        io_in_14_bits_cmd, io_in_14_bits_vaddr, io_in_14_bits_addr,
                        io_in_14_bits_word_idx, io_in_14_bits_amo_data, io_in_14_bits_amo_mask,
                        io_in_14_bits_amo_cmp, io_in_14_bits_pf_source, io_in_14_bits_access,
                        io_in_14_bits_id};
  assign way_req[15] = {io_in_15_bits_miss_id, io_in_15_bits_occupy_way,
                        io_in_15_bits_miss_fail_cause_evict_btot, io_in_15_bits_source,
                        io_in_15_bits_cmd, io_in_15_bits_vaddr, io_in_15_bits_addr,
                        io_in_15_bits_word_idx, io_in_15_bits_amo_data, io_in_15_bits_amo_mask,
                        io_in_15_bits_amo_cmp, io_in_15_bits_pf_source, io_in_15_bits_access,
                        io_in_15_bits_id};
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid, io_in_3_valid, io_in_4_valid, io_in_5_valid, io_in_6_valid, io_in_7_valid, io_in_8_valid, io_in_9_valid, io_in_10_valid, io_in_11_valid, io_in_12_valid, io_in_13_valid, io_in_14_valid, io_in_15_valid};
  assign io_in_0_ready = in_ready_vec[15];
  assign io_in_1_ready = in_ready_vec[14];
  assign io_in_2_ready = in_ready_vec[13];
  assign io_in_3_ready = in_ready_vec[12];
  assign io_in_4_ready = in_ready_vec[11];
  assign io_in_5_ready = in_ready_vec[10];
  assign io_in_6_ready = in_ready_vec[9];
  assign io_in_7_ready = in_ready_vec[8];
  assign io_in_8_ready = in_ready_vec[7];
  assign io_in_9_ready = in_ready_vec[6];
  assign io_in_10_ready = in_ready_vec[5];
  assign io_in_11_ready = in_ready_vec[4];
  assign io_in_12_ready = in_ready_vec[3];
  assign io_in_13_ready = in_ready_vec[2];
  assign io_in_14_ready = in_ready_vec[1];
  assign io_in_15_ready = in_ready_vec[0];
  // END GENERATED

  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    // 端口表事实：$bits 只认端口声明，输出端口位宽抄错这个常量立刻跟着变
    .PORT_BITS_OUT    ($bits({io_out_bits_miss_id, io_out_bits_occupy_way,
                              io_out_bits_miss_fail_cause_evict_btot, io_out_bits_source,
                              io_out_bits_cmd, io_out_bits_vaddr, io_out_bits_addr,
                              io_out_bits_word_idx, io_out_bits_amo_data, io_out_bits_amo_mask,
                              io_out_bits_amo_cmp, io_out_bits_pf_source, io_out_bits_access,
                              io_out_bits_id})),
    .PORT_BITS_LAST_IN($bits({io_in_15_bits_miss_id, io_in_15_bits_occupy_way,
                              io_in_15_bits_miss_fail_cause_evict_btot, io_in_15_bits_source,
                              io_in_15_bits_cmd, io_in_15_bits_vaddr, io_in_15_bits_addr,
                              io_in_15_bits_word_idx, io_in_15_bits_amo_data,
                              io_in_15_bits_amo_mask, io_in_15_bits_amo_cmp,
                              io_in_15_bits_pf_source, io_in_15_bits_access,
                              io_in_15_bits_id})),
    .GOLDEN_PORTS     (GOLDEN_PORTS),
    .GOLDEN_BITS_PORTS(GOLDEN_BITS_PORTS)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_req)
  );

  assign io_out_bits_miss_id                    = out_req.miss_id;
  assign io_out_bits_occupy_way                 = out_req.occupy_way;
  assign io_out_bits_miss_fail_cause_evict_btot = out_req.miss_fail_cause_evict_btot;
  assign io_out_bits_source                     = out_req.source;
  assign io_out_bits_cmd                        = out_req.cmd;
  assign io_out_bits_vaddr                      = out_req.vaddr;
  assign io_out_bits_addr                       = out_req.addr;
  assign io_out_bits_word_idx                   = out_req.word_idx;
  assign io_out_bits_amo_data                   = out_req.amo_data;
  assign io_out_bits_amo_mask                   = out_req.amo_mask;
  assign io_out_bits_amo_cmp                    = out_req.amo_cmp;
  assign io_out_bits_pf_source                  = out_req.pf_source;
  assign io_out_bits_access                     = out_req.access;
  assign io_out_bits_id                         = out_req.id;

endmodule
