// =============================================================================
//  MainPipe —— L1 DCache 主流水（可读重写核 xs_MainPipe_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/cache/dcache/mainpipe/MainPipe.scala
//  类型/常量/纯函数集中在 mainpipe_pkg（见 mainpipe_pkg.sv 文件头）。
//
//  【在 DCache 中的位置】
//    L1 DCache 有两条流水：LoadPipe（只读，处理 load）与本 MainPipe（写侧主流水）。
//    MainPipe 串行处理 5 类请求，经 Arbiter4 固定优先级合并后进入 s0：
//      ① probe   ——（最高优先级）来自 L2 的 snoop，需降级/写回本行；
//      ② refill  —— MissQueue 补块完成后回灌（仅 AMO miss 才走主流水补块）；
//      ③ store   —— sbuffer 写回的整行 store；
//      ④ atomic  ——（最低）AMO / LR / SC。
//    四源 payload 统一成 mainpipe_req_t。replace 请求由 refill 通道携带 replace 标志。
//
//  【4 级流水职责】
//    s0 仲裁+发起读：选请求，算 set index，发 Meta/Tag SRAM 读，算 bank 读写 mask。
//    s1 命中判定   ：收 Meta/Tag，做 tag ECC 比对得 way one-hot、命中、一致性权限；
//                    选替换 way（replacement / pseudo-error 注入 / BtoT evict）；发 Data 读。
//    s2 选数据+分流：收 Data；判 store/AMO 命中→s3，miss→MissQueue，evict 冲突→replay；
//                    合并 store 写数据（不含 cache 旧数据）；驱动 miss_req / wbq 冲突检查。
//    s3 落盘       ：合并 cache 旧数据 + AMOALU 结果；写 Data/Meta/Tag/flag 阵列；
//                    触发 Writeback；维护 LR/SC 保留锁（lrsc_count/addr）；回 store/atomic resp。
//
//  【本配置裁剪（golden firtool 已固化，须对齐）】
//    * 大量下游 ready 恒 1：meta_read/write、tag_write、data_write(含 dup)、wb_dup、
//      外部 s3_ready 等在本顶层例化里退化为常量，故 s3_*_can_go 不再含这些 ready 项。
//      仅 io_miss_req_ready / io_wb_ready / io_data_readline_ready / io_tag_read_ready
//      是真输入端口。
//    * StoreWaitThreshold=0（Constantin 默认）→ storeCanAccept 恒真，storeWaitCycles
//      计数器被裁掉；io_data_read / io_force_write 端口被裁。
//    * io.status（非 dup 版本）输出未被顶层使用，firtool 裁掉；仅保留 status_dup×24。
//    * EnableTagEcc=true：tag 为 43 位 SECDED 编码，命中需 tag 相等且无 ECC 错。
//
//  ⚠ 端口集合与 golden MainPipe 完全一致（扁平 io_*），便于 wrapper 直通、UT/FM 对齐。
//    可读核内部用 mainpipe_req_t struct 表达每级流水 payload，用 enum/纯函数表达
//    一致性状态机与数据合并。AMOALU / Arbiter4_MainPipeReq 两个子模块作 golden 黑盒例化。
// =============================================================================
module xs_MainPipe_core
  import mainpipe_pkg::*;
(
  input          clock,
  input          reset,
  // ====== probe 请求（源①，最高优先级，来自 L2 snoop）======
  output         io_probe_req_ready,
  input          io_probe_req_valid,
  input  [1:0]   io_probe_req_bits_probe_param,
  input          io_probe_req_bits_probe_need_data,
  input  [49:0]  io_probe_req_bits_vaddr,
  input  [47:0]  io_probe_req_bits_addr,
  input  [5:0]   io_probe_req_bits_id,
  // ====== miss 请求输出（s2 store/AMO miss → MissQueue）======
  input          io_miss_req_ready,
  output         io_miss_req_valid,
  output [3:0]   io_miss_req_bits_source,
  output [4:0]   io_miss_req_bits_cmd,
  output [47:0]  io_miss_req_bits_addr,
  output [49:0]  io_miss_req_bits_vaddr,
  output         io_miss_req_bits_full_overwrite,
  output [2:0]   io_miss_req_bits_word_idx,
  output [127:0] io_miss_req_bits_amo_data,
  output [15:0]  io_miss_req_bits_amo_mask,
  output [127:0] io_miss_req_bits_amo_cmp,
  output [1:0]   io_miss_req_bits_req_coh_state,
  output [5:0]   io_miss_req_bits_id,
  output         io_miss_req_bits_isBtoT,
  output [3:0]   io_miss_req_bits_occupy_way,
  output         io_miss_req_bits_cancel,
  output [511:0] io_miss_req_bits_store_data,
  output [63:0]  io_miss_req_bits_store_mask,
  // ====== refill 请求（源②，MissQueue 补块回灌，含 replace）======
  output         io_refill_req_ready,
  input          io_refill_req_valid,
  input          io_refill_req_bits_miss,
  input  [3:0]   io_refill_req_bits_miss_id,
  input  [3:0]   io_refill_req_bits_occupy_way,
  input          io_refill_req_bits_miss_fail_cause_evict_btot,
  input  [3:0]   io_refill_req_bits_source,
  input  [4:0]   io_refill_req_bits_cmd,
  input  [49:0]  io_refill_req_bits_vaddr,
  input  [47:0]  io_refill_req_bits_addr,
  input  [2:0]   io_refill_req_bits_word_idx,
  input  [127:0] io_refill_req_bits_amo_data,
  input  [15:0]  io_refill_req_bits_amo_mask,
  input  [127:0] io_refill_req_bits_amo_cmp,
  input  [2:0]   io_refill_req_bits_pf_source,
  input          io_refill_req_bits_access,
  input  [5:0]   io_refill_req_bits_id,
  // ====== wbq 冲突检查（s2 miss 时把要补的块地址送 WritebackQueue 查冲突）======
  output         io_wbq_conflict_check_valid,
  output [47:0]  io_wbq_conflict_check_bits,
  input          io_wbq_block_miss_req,
  // ====== store 请求（源③，sbuffer 整行写）======
  output         io_store_req_ready,
  input          io_store_req_valid,
  input  [49:0]  io_store_req_bits_vaddr,
  input  [47:0]  io_store_req_bits_addr,
  input  [511:0] io_store_req_bits_data,
  input  [63:0]  io_store_req_bits_mask,
  input  [5:0]   io_store_req_bits_id,
  output         io_store_replay_resp_valid,   // store miss/replay → sbuffer 重发
  output [5:0]   io_store_replay_resp_bits_id,
  output         io_store_hit_resp_valid,      // store 命中写完 → sbuffer 释放
  output [5:0]   io_store_hit_resp_bits_id,
  // ====== atomic 请求（源④，AMO/LR/SC）======
  output         io_atomic_req_ready,
  input          io_atomic_req_valid,
  input  [4:0]   io_atomic_req_bits_cmd,
  input  [49:0]  io_atomic_req_bits_vaddr,
  input  [47:0]  io_atomic_req_bits_addr,
  input  [2:0]   io_atomic_req_bits_word_idx,
  input  [127:0] io_atomic_req_bits_amo_data,
  input  [15:0]  io_atomic_req_bits_amo_mask,
  input  [127:0] io_atomic_req_bits_amo_cmp,
  output         io_atomic_resp_valid,
  output [3:0]   io_atomic_resp_bits_source,
  output [127:0] io_atomic_resp_bits_data,
  output         io_atomic_resp_bits_miss,
  output [3:0]   io_atomic_resp_bits_miss_id,
  output         io_atomic_resp_bits_replay,
  output         io_atomic_resp_bits_error,
  output         io_atomic_resp_bits_ack_miss_queue,
  output [5:0]   io_atomic_resp_bits_id,
  // ====== 给 MissQueue 的流水状态信息 ======
  output         io_mainpipe_info_s2_valid,
  output [3:0]   io_mainpipe_info_s2_miss_id,
  output         io_mainpipe_info_s2_replay_to_mq,
  output         io_mainpipe_info_s2_evict_BtoT_way,
  output [3:0]   io_mainpipe_info_s2_next_evict_way,
  output         io_mainpipe_info_s3_valid,
  output [3:0]   io_mainpipe_info_s3_miss_id,
  output         io_mainpipe_info_s3_refill_resp,
  // ====== MissQueue 回灌数据（s2/s3 合并到 cacheline）======
  input          io_refill_info_valid,
  input  [511:0] io_refill_info_bits_store_data,
  input  [63:0]  io_refill_info_bits_store_mask,
  input  [1:0]   io_refill_info_bits_miss_param,
  input          io_refill_info_bits_error,
  // ====== Writeback 输出（s3 写回脏行/降级）======
  input          io_wb_ready,
  output         io_wb_valid,
  output [2:0]   io_wb_bits_param,
  output         io_wb_bits_voluntary,
  output         io_wb_bits_hasData,
  output         io_wb_bits_corrupt,
  output         io_wb_bits_dirty,
  output [47:0]  io_wb_bits_addr,
  output [511:0] io_wb_bits_data,
  // ====== Data SRAM 读（整行读，s1 发起）======
  output         io_data_read_intend,
  input          io_data_readline_ready,
  output         io_data_readline_valid,
  output [3:0]   io_data_readline_bits_way_en,
  output [47:0]  io_data_readline_bits_addr,
  output [7:0]   io_data_readline_bits_rmask,
  output         io_data_readline_can_go,
  output         io_data_readline_stall,
  output         io_data_readline_can_resp,
  input  [63:0]  io_data_resp_0_raw_data,
  input  [63:0]  io_data_resp_1_raw_data,
  input  [63:0]  io_data_resp_2_raw_data,
  input  [63:0]  io_data_resp_3_raw_data,
  input  [63:0]  io_data_resp_4_raw_data,
  input  [63:0]  io_data_resp_5_raw_data,
  input  [63:0]  io_data_resp_6_raw_data,
  input  [63:0]  io_data_resp_7_raw_data,
  input          io_readline_error,
  input          io_readline_error_delayed,
  // ====== Data SRAM 写（s3 落盘，含 8 份 ctrl 复制）======
  output         io_data_write_valid,
  output [7:0]   io_data_write_bits_wmask,
  output [63:0]  io_data_write_bits_data_0,
  output [63:0]  io_data_write_bits_data_1,
  output [63:0]  io_data_write_bits_data_2,
  output [63:0]  io_data_write_bits_data_3,
  output [63:0]  io_data_write_bits_data_4,
  output [63:0]  io_data_write_bits_data_5,
  output [63:0]  io_data_write_bits_data_6,
  output [63:0]  io_data_write_bits_data_7,
  output         io_data_write_dup_0_valid,
  output [3:0]   io_data_write_dup_0_bits_way_en,
  output [47:0]  io_data_write_dup_0_bits_addr,
  output         io_data_write_dup_1_valid,
  output [3:0]   io_data_write_dup_1_bits_way_en,
  output [47:0]  io_data_write_dup_1_bits_addr,
  output         io_data_write_dup_2_valid,
  output [3:0]   io_data_write_dup_2_bits_way_en,
  output [47:0]  io_data_write_dup_2_bits_addr,
  output         io_data_write_dup_3_valid,
  output [3:0]   io_data_write_dup_3_bits_way_en,
  output [47:0]  io_data_write_dup_3_bits_addr,
  output         io_data_write_dup_4_valid,
  output [3:0]   io_data_write_dup_4_bits_way_en,
  output [47:0]  io_data_write_dup_4_bits_addr,
  output         io_data_write_dup_5_valid,
  output [3:0]   io_data_write_dup_5_bits_way_en,
  output [47:0]  io_data_write_dup_5_bits_addr,
  output         io_data_write_dup_6_valid,
  output [3:0]   io_data_write_dup_6_bits_way_en,
  output [47:0]  io_data_write_dup_6_bits_addr,
  output         io_data_write_dup_7_valid,
  output [3:0]   io_data_write_dup_7_bits_way_en,
  output [47:0]  io_data_write_dup_7_bits_addr,
  // ====== Meta SRAM 读写 ======
  output         io_meta_read_valid,
  output [7:0]   io_meta_read_bits_idx,
  input  [1:0]   io_meta_resp_0_coh_state,
  input  [1:0]   io_meta_resp_1_coh_state,
  input  [1:0]   io_meta_resp_2_coh_state,
  input  [1:0]   io_meta_resp_3_coh_state,
  output         io_meta_write_valid,
  output [7:0]   io_meta_write_bits_idx,
  output [3:0]   io_meta_write_bits_way_en,
  output [1:0]   io_meta_write_bits_meta_coh_state,
  // 附加 meta（error/prefetch/access 标志）
  input          io_extra_meta_resp_0_error,
  input  [2:0]   io_extra_meta_resp_0_prefetch,
  input          io_extra_meta_resp_0_access,
  input          io_extra_meta_resp_1_error,
  input  [2:0]   io_extra_meta_resp_1_prefetch,
  input          io_extra_meta_resp_1_access,
  input          io_extra_meta_resp_2_error,
  input  [2:0]   io_extra_meta_resp_2_prefetch,
  input          io_extra_meta_resp_2_access,
  input          io_extra_meta_resp_3_error,
  input  [2:0]   io_extra_meta_resp_3_prefetch,
  input          io_extra_meta_resp_3_access,
  output         io_error_flag_write_valid,
  output [7:0]   io_error_flag_write_bits_idx,
  output [3:0]   io_error_flag_write_bits_way_en,
  output         io_error_flag_write_bits_flag,
  output         io_prefetch_flag_write_valid,
  output [7:0]   io_prefetch_flag_write_bits_idx,
  output [3:0]   io_prefetch_flag_write_bits_way_en,
  output [2:0]   io_prefetch_flag_write_bits_source,
  output         io_access_flag_write_valid,
  output [7:0]   io_access_flag_write_bits_idx,
  output [3:0]   io_access_flag_write_bits_way_en,
  output         io_access_flag_write_bits_flag,
  // ====== Tag SRAM 读写 ======
  input          io_tag_read_ready,
  output         io_tag_read_valid,
  output [7:0]   io_tag_read_bits_idx,
  input  [42:0]  io_tag_resp_0,
  input  [42:0]  io_tag_resp_1,
  input  [42:0]  io_tag_resp_2,
  input  [42:0]  io_tag_resp_3,
  output         io_tag_write_valid,
  output [7:0]   io_tag_write_bits_idx,
  output [3:0]   io_tag_write_bits_way_en,
  output [35:0]  io_tag_write_bits_tag,
  output         io_tag_write_intend,
  // ====== 替换算法接口 ======
  output         io_replace_access_valid,
  output [7:0]   io_replace_access_bits_set,
  output [1:0]   io_replace_access_bits_way,
  output [7:0]   io_replace_way_set_bits,
  input  [1:0]   io_replace_way_way,
  output [7:0]   io_evict_set,
  input  [3:0]   io_btot_ways_for_set,
  // ====== 替换块写回地址（→ MissQueue block 检查）======
  output [47:0]  io_replace_req_bits_addr,
  output [49:0]  io_replace_req_bits_vaddr,
  input          io_replace_block,
  // ====== SMS 预取 evict 提示 ======
  output         io_sms_agt_evict_req_valid,
  output [49:0]  io_sms_agt_evict_req_bits_vaddr,
  // ====== 流水状态扇出复制（24 份，喂给各处 set/way 冲突检查）======
  output         io_status_dup_0_s1_valid,
  output [7:0]   io_status_dup_0_s1_bits_set,
  output [3:0]   io_status_dup_0_s1_bits_way_en,
  output         io_status_dup_0_s2_valid,
  output [7:0]   io_status_dup_0_s2_bits_set,
  output [3:0]   io_status_dup_0_s2_bits_way_en,
  output         io_status_dup_0_s3_valid,
  output [7:0]   io_status_dup_0_s3_bits_set,
  output [3:0]   io_status_dup_0_s3_bits_way_en,
  output         io_status_dup_1_s1_valid,  output [7:0] io_status_dup_1_s1_bits_set,  output [3:0] io_status_dup_1_s1_bits_way_en,
  output         io_status_dup_1_s2_valid,  output [7:0] io_status_dup_1_s2_bits_set,  output [3:0] io_status_dup_1_s2_bits_way_en,
  output         io_status_dup_1_s3_valid,  output [7:0] io_status_dup_1_s3_bits_set,  output [3:0] io_status_dup_1_s3_bits_way_en,
  output         io_status_dup_2_s1_valid,  output [7:0] io_status_dup_2_s1_bits_set,  output [3:0] io_status_dup_2_s1_bits_way_en,
  output         io_status_dup_2_s2_valid,  output [7:0] io_status_dup_2_s2_bits_set,  output [3:0] io_status_dup_2_s2_bits_way_en,
  output         io_status_dup_2_s3_valid,  output [7:0] io_status_dup_2_s3_bits_set,  output [3:0] io_status_dup_2_s3_bits_way_en,
  output         io_status_dup_3_s1_valid,  output [7:0] io_status_dup_3_s1_bits_set,  output [3:0] io_status_dup_3_s1_bits_way_en,
  output         io_status_dup_3_s2_valid,  output [7:0] io_status_dup_3_s2_bits_set,  output [3:0] io_status_dup_3_s2_bits_way_en,
  output         io_status_dup_3_s3_valid,  output [7:0] io_status_dup_3_s3_bits_set,  output [3:0] io_status_dup_3_s3_bits_way_en,
  output         io_status_dup_4_s1_valid,  output [7:0] io_status_dup_4_s1_bits_set,  output [3:0] io_status_dup_4_s1_bits_way_en,
  output         io_status_dup_4_s2_valid,  output [7:0] io_status_dup_4_s2_bits_set,  output [3:0] io_status_dup_4_s2_bits_way_en,
  output         io_status_dup_4_s3_valid,  output [7:0] io_status_dup_4_s3_bits_set,  output [3:0] io_status_dup_4_s3_bits_way_en,
  output         io_status_dup_5_s1_valid,  output [7:0] io_status_dup_5_s1_bits_set,  output [3:0] io_status_dup_5_s1_bits_way_en,
  output         io_status_dup_5_s2_valid,  output [7:0] io_status_dup_5_s2_bits_set,  output [3:0] io_status_dup_5_s2_bits_way_en,
  output         io_status_dup_5_s3_valid,  output [7:0] io_status_dup_5_s3_bits_set,  output [3:0] io_status_dup_5_s3_bits_way_en,
  output         io_status_dup_6_s1_valid,  output [7:0] io_status_dup_6_s1_bits_set,  output [3:0] io_status_dup_6_s1_bits_way_en,
  output         io_status_dup_6_s2_valid,  output [7:0] io_status_dup_6_s2_bits_set,  output [3:0] io_status_dup_6_s2_bits_way_en,
  output         io_status_dup_6_s3_valid,  output [7:0] io_status_dup_6_s3_bits_set,  output [3:0] io_status_dup_6_s3_bits_way_en,
  output         io_status_dup_7_s1_valid,  output [7:0] io_status_dup_7_s1_bits_set,  output [3:0] io_status_dup_7_s1_bits_way_en,
  output         io_status_dup_7_s2_valid,  output [7:0] io_status_dup_7_s2_bits_set,  output [3:0] io_status_dup_7_s2_bits_way_en,
  output         io_status_dup_7_s3_valid,  output [7:0] io_status_dup_7_s3_bits_set,  output [3:0] io_status_dup_7_s3_bits_way_en,
  output         io_status_dup_8_s1_valid,  output [7:0] io_status_dup_8_s1_bits_set,  output [3:0] io_status_dup_8_s1_bits_way_en,
  output         io_status_dup_8_s2_valid,  output [7:0] io_status_dup_8_s2_bits_set,  output [3:0] io_status_dup_8_s2_bits_way_en,
  output         io_status_dup_8_s3_valid,  output [7:0] io_status_dup_8_s3_bits_set,  output [3:0] io_status_dup_8_s3_bits_way_en,
  output         io_status_dup_9_s1_valid,  output [7:0] io_status_dup_9_s1_bits_set,  output [3:0] io_status_dup_9_s1_bits_way_en,
  output         io_status_dup_9_s2_valid,  output [7:0] io_status_dup_9_s2_bits_set,  output [3:0] io_status_dup_9_s2_bits_way_en,
  output         io_status_dup_9_s3_valid,  output [7:0] io_status_dup_9_s3_bits_set,  output [3:0] io_status_dup_9_s3_bits_way_en,
  output         io_status_dup_10_s1_valid, output [7:0] io_status_dup_10_s1_bits_set, output [3:0] io_status_dup_10_s1_bits_way_en,
  output         io_status_dup_10_s2_valid, output [7:0] io_status_dup_10_s2_bits_set, output [3:0] io_status_dup_10_s2_bits_way_en,
  output         io_status_dup_10_s3_valid, output [7:0] io_status_dup_10_s3_bits_set, output [3:0] io_status_dup_10_s3_bits_way_en,
  output         io_status_dup_11_s1_valid, output [7:0] io_status_dup_11_s1_bits_set, output [3:0] io_status_dup_11_s1_bits_way_en,
  output         io_status_dup_11_s2_valid, output [7:0] io_status_dup_11_s2_bits_set, output [3:0] io_status_dup_11_s2_bits_way_en,
  output         io_status_dup_11_s3_valid, output [7:0] io_status_dup_11_s3_bits_set, output [3:0] io_status_dup_11_s3_bits_way_en,
  output         io_status_dup_12_s1_valid, output [7:0] io_status_dup_12_s1_bits_set, output [3:0] io_status_dup_12_s1_bits_way_en,
  output         io_status_dup_12_s2_valid, output [7:0] io_status_dup_12_s2_bits_set, output [3:0] io_status_dup_12_s2_bits_way_en,
  output         io_status_dup_12_s3_valid, output [7:0] io_status_dup_12_s3_bits_set, output [3:0] io_status_dup_12_s3_bits_way_en,
  output         io_status_dup_13_s1_valid, output [7:0] io_status_dup_13_s1_bits_set, output [3:0] io_status_dup_13_s1_bits_way_en,
  output         io_status_dup_13_s2_valid, output [7:0] io_status_dup_13_s2_bits_set, output [3:0] io_status_dup_13_s2_bits_way_en,
  output         io_status_dup_13_s3_valid, output [7:0] io_status_dup_13_s3_bits_set, output [3:0] io_status_dup_13_s3_bits_way_en,
  output         io_status_dup_14_s1_valid, output [7:0] io_status_dup_14_s1_bits_set, output [3:0] io_status_dup_14_s1_bits_way_en,
  output         io_status_dup_14_s2_valid, output [7:0] io_status_dup_14_s2_bits_set, output [3:0] io_status_dup_14_s2_bits_way_en,
  output         io_status_dup_14_s3_valid, output [7:0] io_status_dup_14_s3_bits_set, output [3:0] io_status_dup_14_s3_bits_way_en,
  output         io_status_dup_15_s1_valid, output [7:0] io_status_dup_15_s1_bits_set, output [3:0] io_status_dup_15_s1_bits_way_en,
  output         io_status_dup_15_s2_valid, output [7:0] io_status_dup_15_s2_bits_set, output [3:0] io_status_dup_15_s2_bits_way_en,
  output         io_status_dup_15_s3_valid, output [7:0] io_status_dup_15_s3_bits_set, output [3:0] io_status_dup_15_s3_bits_way_en,
  output         io_status_dup_16_s1_valid, output [7:0] io_status_dup_16_s1_bits_set, output [3:0] io_status_dup_16_s1_bits_way_en,
  output         io_status_dup_16_s2_valid, output [7:0] io_status_dup_16_s2_bits_set, output [3:0] io_status_dup_16_s2_bits_way_en,
  output         io_status_dup_16_s3_valid, output [7:0] io_status_dup_16_s3_bits_set, output [3:0] io_status_dup_16_s3_bits_way_en,
  output         io_status_dup_17_s1_valid, output [7:0] io_status_dup_17_s1_bits_set, output [3:0] io_status_dup_17_s1_bits_way_en,
  output         io_status_dup_17_s2_valid, output [7:0] io_status_dup_17_s2_bits_set, output [3:0] io_status_dup_17_s2_bits_way_en,
  output         io_status_dup_17_s3_valid, output [7:0] io_status_dup_17_s3_bits_set, output [3:0] io_status_dup_17_s3_bits_way_en,
  output         io_status_dup_18_s1_valid, output [7:0] io_status_dup_18_s1_bits_set, output [3:0] io_status_dup_18_s1_bits_way_en,
  output         io_status_dup_18_s2_valid, output [7:0] io_status_dup_18_s2_bits_set, output [3:0] io_status_dup_18_s2_bits_way_en,
  output         io_status_dup_18_s3_valid, output [7:0] io_status_dup_18_s3_bits_set, output [3:0] io_status_dup_18_s3_bits_way_en,
  output         io_status_dup_19_s1_valid, output [7:0] io_status_dup_19_s1_bits_set, output [3:0] io_status_dup_19_s1_bits_way_en,
  output         io_status_dup_19_s2_valid, output [7:0] io_status_dup_19_s2_bits_set, output [3:0] io_status_dup_19_s2_bits_way_en,
  output         io_status_dup_19_s3_valid, output [7:0] io_status_dup_19_s3_bits_set, output [3:0] io_status_dup_19_s3_bits_way_en,
  output         io_status_dup_20_s1_valid, output [7:0] io_status_dup_20_s1_bits_set, output [3:0] io_status_dup_20_s1_bits_way_en,
  output         io_status_dup_20_s2_valid, output [7:0] io_status_dup_20_s2_bits_set, output [3:0] io_status_dup_20_s2_bits_way_en,
  output         io_status_dup_20_s3_valid, output [7:0] io_status_dup_20_s3_bits_set, output [3:0] io_status_dup_20_s3_bits_way_en,
  output         io_status_dup_21_s1_valid, output [7:0] io_status_dup_21_s1_bits_set, output [3:0] io_status_dup_21_s1_bits_way_en,
  output         io_status_dup_21_s2_valid, output [7:0] io_status_dup_21_s2_bits_set, output [3:0] io_status_dup_21_s2_bits_way_en,
  output         io_status_dup_21_s3_valid, output [7:0] io_status_dup_21_s3_bits_set, output [3:0] io_status_dup_21_s3_bits_way_en,
  output         io_status_dup_22_s1_valid, output [7:0] io_status_dup_22_s1_bits_set, output [3:0] io_status_dup_22_s1_bits_way_en,
  output         io_status_dup_22_s2_valid, output [7:0] io_status_dup_22_s2_bits_set, output [3:0] io_status_dup_22_s2_bits_way_en,
  output         io_status_dup_22_s3_valid, output [7:0] io_status_dup_22_s3_bits_set, output [3:0] io_status_dup_22_s3_bits_way_en,
  output         io_status_dup_23_s1_valid, output [7:0] io_status_dup_23_s1_bits_set, output [3:0] io_status_dup_23_s1_bits_way_en,
  output         io_status_dup_23_s2_valid, output [7:0] io_status_dup_23_s2_bits_set, output [3:0] io_status_dup_23_s2_bits_way_en,
  output         io_status_dup_23_s3_valid, output [7:0] io_status_dup_23_s3_bits_set, output [3:0] io_status_dup_23_s3_bits_way_en,
  // ====== LR/SC 保留锁 ======
  output         io_lrsc_locked_block_valid,
  output [47:0]  io_lrsc_locked_block_bits,
  input          io_invalid_resv_set,
  output         io_update_resv_set,
  output         io_block_lr,
  // ====== ECC error 上报 ======
  output         io_error_valid,
  output [47:0]  io_error_bits_paddr,
  output         io_error_bits_report_to_beu,
  input          io_pseudo_error_valid,
  input          io_pseudo_error_bits_0_valid,
  input  [63:0]  io_pseudo_error_bits_0_mask,
  output         io_pseudo_tag_error_inj_done,
  output         io_pseudo_data_error_inj_done,
  // ====== bloom filter（预取地址布隆过滤）======
  output         io_bloom_filter_query_set_valid,
  output [11:0]  io_bloom_filter_query_set_bits_addr,
  output         io_bloom_filter_query_clr_valid,
  output [11:0]  io_bloom_filter_query_clr_bits_addr,
  // ====== perf 事件 ======
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value
);

  // ===========================================================================
  //  公共：set 冲突信号（s1/s2/s3 占用的 set 与 s0 新请求/store 直查 set 相同）
  //  这些在各级算出后统一参与 req.ready / store_req.ready，故先前向声明。
  // ===========================================================================
  logic s1_valid, s2_valid, s3_valid;
  logic [IDX_BITS-1:0] s0_idx, s1_idx, s2_idx, s3_idx, store_idx;
  logic s1_can_go, s2_can_go, s3_can_go;
  logic s1_ready, s2_ready, s3_ready;

  // s0 新请求 set 与下游各级冲突（阻止读出同 set 时与在途请求竞争）
  logic s1_s0_conflict, s2_s0_conflict, s3_s0_conflict;
  logic s1_s0_conflict_store, s2_s0_conflict_store, s3_s0_conflict_store;
  assign s1_s0_conflict = s1_valid && (s0_idx == s1_idx);
  assign s2_s0_conflict = s2_valid && (s0_idx == s2_idx);
  assign s3_s0_conflict = s3_valid && (s3_idx == s0_idx);
  assign s1_s0_conflict_store = s1_valid && (store_idx == s1_idx);
  assign s2_s0_conflict_store = s2_valid && (store_idx == s2_idx);
  assign s3_s0_conflict_store = s3_valid && (s3_idx == store_idx);
  wire set_conflict       = s1_s0_conflict || s2_s0_conflict || s3_s0_conflict;
  wire store_set_conflict = s1_s0_conflict_store || s2_s0_conflict_store || s3_s0_conflict_store;

  // ===========================================================================
  //  S0：四源仲裁 + 发 Meta/Tag 读 + 算 bank 读写 mask
  // ===========================================================================
  // 四源（probe/refill/store/atomic）由调用者直连到 Arbiter4 的 in_0..in_3。
  // 本配置 storeCanAccept 恒真（StoreWaitThreshold=0、io_data_read 端口被裁），
  // 故 store 通道 valid 直通 io_store_req_valid，无需 storeWaitCycles 节流逻辑。

  // ---- 仲裁后的 s0 请求（Arbiter4_MainPipeReq 黑盒，固定优先级 probe>refill>store>atomic）----
  logic                    arb_out_valid;
  mainpipe_req_t           s0_req;
  logic                    req_ready;   // s0 能否吃下当前仲裁结果

  // 注：store 源(in_2)的 source/cmd 等由 Arbiter4 内部填好（source=STORE、cmd=M_XWR），
  //     故此处无需对 store_req 做 convertStoreReq 整形；直接把 io_store_req 接到 in_2。
  Arbiter4_MainPipeReq main_pipe_req_arb (
    // in_0 = probe（Arbiter 为纯组合，无 clock/reset）
    .io_in_0_ready              (io_probe_req_ready),
    .io_in_0_valid              (io_probe_req_valid),
    .io_in_0_bits_probe_param   (io_probe_req_bits_probe_param),
    .io_in_0_bits_probe_need_data(io_probe_req_bits_probe_need_data),
    .io_in_0_bits_vaddr         (io_probe_req_bits_vaddr),
    .io_in_0_bits_addr          (io_probe_req_bits_addr),
    .io_in_0_bits_id            (io_probe_req_bits_id),
    // in_1 = refill
    .io_in_1_ready              (io_refill_req_ready),
    .io_in_1_valid              (io_refill_req_valid),
    .io_in_1_bits_miss          (io_refill_req_bits_miss),
    .io_in_1_bits_miss_id       (io_refill_req_bits_miss_id),
    .io_in_1_bits_occupy_way    (io_refill_req_bits_occupy_way),
    .io_in_1_bits_miss_fail_cause_evict_btot(io_refill_req_bits_miss_fail_cause_evict_btot),
    .io_in_1_bits_source        (io_refill_req_bits_source),
    .io_in_1_bits_cmd           (io_refill_req_bits_cmd),
    .io_in_1_bits_vaddr         (io_refill_req_bits_vaddr),
    .io_in_1_bits_addr          (io_refill_req_bits_addr),
    .io_in_1_bits_word_idx      (io_refill_req_bits_word_idx),
    .io_in_1_bits_amo_data      (io_refill_req_bits_amo_data),
    .io_in_1_bits_amo_mask      (io_refill_req_bits_amo_mask),
    .io_in_1_bits_amo_cmp       (io_refill_req_bits_amo_cmp),
    .io_in_1_bits_pf_source     (io_refill_req_bits_pf_source),
    .io_in_1_bits_access        (io_refill_req_bits_access),
    .io_in_1_bits_id            (io_refill_req_bits_id),
    // in_2 = store（valid 已含 storeCanAccept，本配置恒真；ready 不接，store_req.ready 单独算）
    .io_in_2_valid              (io_store_req_valid),
    .io_in_2_bits_vaddr         (io_store_req_bits_vaddr),
    .io_in_2_bits_addr          (io_store_req_bits_addr),
    .io_in_2_bits_store_data    (io_store_req_bits_data),
    .io_in_2_bits_store_mask    (io_store_req_bits_mask),
    .io_in_2_bits_id            (io_store_req_bits_id),
    // in_3 = atomic
    .io_in_3_ready              (io_atomic_req_ready),
    .io_in_3_valid              (io_atomic_req_valid),
    .io_in_3_bits_cmd           (io_atomic_req_bits_cmd),
    .io_in_3_bits_vaddr         (io_atomic_req_bits_vaddr),
    .io_in_3_bits_addr          (io_atomic_req_bits_addr),
    .io_in_3_bits_word_idx      (io_atomic_req_bits_word_idx),
    .io_in_3_bits_amo_data      (io_atomic_req_bits_amo_data),
    .io_in_3_bits_amo_mask      (io_atomic_req_bits_amo_mask),
    .io_in_3_bits_amo_cmp       (io_atomic_req_bits_amo_cmp),
    // out
    .io_out_ready               (req_ready),
    .io_out_valid               (arb_out_valid),
    .io_out_bits_miss           (s0_req.miss),
    .io_out_bits_miss_id        (s0_req.miss_id),
    .io_out_bits_occupy_way     (s0_req.occupy_way),
    .io_out_bits_miss_fail_cause_evict_btot(s0_req.miss_fail_cause_evict_btot),
    .io_out_bits_probe          (s0_req.probe),
    .io_out_bits_probe_param    (s0_req.probe_param),
    .io_out_bits_probe_need_data(s0_req.probe_need_data),
    .io_out_bits_source         (s0_req.source),
    .io_out_bits_cmd            (s0_req.cmd),
    .io_out_bits_vaddr          (s0_req.vaddr),
    .io_out_bits_addr           (s0_req.addr),
    .io_out_bits_store_data     (s0_req.store_data),
    .io_out_bits_store_mask     (s0_req.store_mask),
    .io_out_bits_word_idx       (s0_req.word_idx),
    .io_out_bits_amo_data       (s0_req.amo_data),
    .io_out_bits_amo_mask       (s0_req.amo_mask),
    .io_out_bits_amo_cmp        (s0_req.amo_cmp),
    .io_out_bits_pf_source      (s0_req.pf_source),
    .io_out_bits_access         (s0_req.access),
    .io_out_bits_id             (s0_req.id)
  );
  // Arbiter 不输出 error/replace 字段（store/probe/atomic 不带），s0 显式置 0：
  assign s0_req.error   = 1'b0;
  assign s0_req.replace = 1'b0;

  assign s0_idx    = get_idx(s0_req.vaddr);
  assign store_idx = get_idx(io_store_req_bits_vaddr);

  // s0 推进条件：tag 读就绪 + s1 空 + 无 set 冲突（meta_read 恒 ready，省略）。
  assign req_ready  = io_tag_read_ready && s1_ready && !set_conflict;
  wire   s0_fire    = arb_out_valid && req_ready;

  // store_req.ready 单独算（与仲裁并行，缩短关键路径）：tag 读就绪 + s1 空 +
  //   无 store-set 冲突 + 无更高优先级源占用。
  assign io_store_req_ready = io_tag_read_ready && s1_ready && !store_set_conflict
                              && !io_probe_req_valid && !io_refill_req_valid && !io_atomic_req_valid;

  // ---- bank 读写 mask：store_mask 每字节 1 bit，按 8 个 bank 切片 ----
  //   bank_write[i]      : 该 bank 有任意字节要写
  //   bank_full_write[i] : 该 bank 全字节覆写（无需读旧数据合并）
  logic [N_BANKS-1:0] bank_write, bank_full_write;
  always_comb begin
    for (int i = 0; i < N_BANKS; i++) begin
      bank_write[i]      = |mask_of_bank(i, s0_req.store_mask);
      bank_full_write[i] = &mask_of_bank(i, s0_req.store_mask);
    end
  end
  // store 只需读「部分写」的 bank（要与旧数据合并）；probe/amo/miss/replace 需整行读。
  wire [N_BANKS-1:0] banked_store_rmask = bank_write & ~bank_full_write;
  wire [N_BANKS-1:0] banked_full_rmask  = {N_BANKS{1'b1}};

  wire store_need_data   = !s0_req.probe && req_is_store(s0_req) && (|banked_store_rmask);
  wire amo_need_data     = !s0_req.probe && req_is_amo(s0_req);
  wire banked_need_data  = store_need_data || s0_req.probe || amo_need_data
                           || s0_req.miss || s0_req.replace;
  wire [N_BANKS-1:0] s0_banked_rmask =
        store_need_data ? banked_store_rmask :
        (s0_req.probe || amo_need_data || s0_req.miss || s0_req.replace) ? banked_full_rmask :
        '0;
  // store 写 mask（s2 用）：每个有字节要写的 bank 置位。
  wire [N_BANKS-1:0] banked_store_wmask = bank_write;

  // ---- Meta / Tag 读发起 ----
  assign io_meta_read_valid      = arb_out_valid;
  assign io_meta_read_bits_idx   = get_idx(s0_req.vaddr);
  // replace 请求只读其指定 way 的 meta；其余整行（4 way）都读。
  // 注：golden 中 meta way_en 端口被裁（meta 全读），这里不暴露 way_en 输出。
  assign io_tag_read_valid       = arb_out_valid && !s0_req.replace;
  assign io_tag_read_bits_idx    = get_idx(s0_req.vaddr);
  wire   s0_need_tag             = io_tag_read_valid;

  // ===========================================================================
  //  S1：命中判定 + 替换 way 选择 + 发 Data 读
  // ===========================================================================
  mainpipe_req_t        s1_req;
  logic [N_BANKS-1:0]   s1_banked_rmask, s1_banked_store_wmask;
  logic                 s1_need_data, s1_need_tag;
  logic [WAY_BITS-1:0]  s1_dmway;

  always_ff @(posedge clock) begin
    if (s0_fire) begin
      s1_req                <= s0_req;
      s1_need_data          <= banked_need_data;
      s1_banked_rmask       <= s0_banked_rmask;
      s1_banked_store_wmask <= banked_store_wmask;
      s1_need_tag           <= s0_need_tag;
      s1_dmway              <= direct_map_way(s0_req.vaddr);
    end
  end
  assign s1_idx = get_idx(s1_req.vaddr);

  // s1 valid 推进
  always_ff @(posedge clock) begin
    if (reset)            s1_valid <= 1'b0;
    else if (s0_fire)     s1_valid <= 1'b1;
    else if (s1_valid && s1_can_go) s1_valid <= 1'b0;
  end
  wire s1_fire = s1_valid && s1_can_go;
  assign s1_can_go = s2_ready && (io_data_readline_ready || !s1_need_data);
  assign s1_ready  = !s1_valid || s1_can_go;

  // ---- meta / encTag 在 s1 锁存（s0_fire 当拍取 SRAM 输出，之后保持）----
  //   GatedValidRegNext(s0_fire)：上一拍 s0_fire → 本拍直接采 SRAM 组合输出；
  //   否则保持上次锁存值（s1 多拍停留时数据不变）。
  logic s1_meta_sel;       // = RegNext(s0_fire)：选 SRAM 直出 vs 锁存
  logic [1:0]  meta_hold   [N_WAYS];
  logic [ENC_TAG_BITS-1:0] enctag_hold [N_WAYS];
  always_ff @(posedge clock) if (reset) s1_meta_sel <= 1'b0; else s1_meta_sel <= s0_fire;

  // pseudo error 注入：把 tag 低 36 位按 mask 翻转，模拟 tag ECC 错误。
  wire [TAG_BITS-1:0] pseudo_tag_toggle =
        (io_pseudo_error_valid && io_pseudo_error_bits_0_valid)
        ? io_pseudo_error_bits_0_mask[TAG_BITS-1:0] : '0;

  logic [1:0]              meta_resp_in   [N_WAYS];
  logic [ENC_TAG_BITS-1:0] enctag_real    [N_WAYS]; // 未注入的真 encTag
  logic [ENC_TAG_BITS-1:0] enctag_pseudo  [N_WAYS]; // 注入后的 encTag
  always_comb begin
    meta_resp_in[0] = io_meta_resp_0_coh_state; meta_resp_in[1] = io_meta_resp_1_coh_state;
    meta_resp_in[2] = io_meta_resp_2_coh_state; meta_resp_in[3] = io_meta_resp_3_coh_state;
    enctag_real[0]  = io_tag_resp_0; enctag_real[1] = io_tag_resp_1;
    enctag_real[2]  = io_tag_resp_2; enctag_real[3] = io_tag_resp_3;
    for (int w = 0; w < N_WAYS; w++)
      enctag_pseudo[w] = {enctag_real[w][ENC_TAG_BITS-1:TAG_BITS],
                          enctag_real[w][TAG_BITS-1:0] ^ pseudo_tag_toggle};
  end
  // 保持寄存器：当本拍刚从 SRAM 取值（s1_meta_sel）且 s1 仍有效时，把 SRAM/注入后
  //   的值锁存下来；s1 多拍停留（s1_meta_sel=0）时一直用这份锁存值（与 golden
  //   r_0/r_1_0 的 RegEnable(s1_valid & last_REG) 语义一致）。
  always_ff @(posedge clock) if (s1_valid && s1_meta_sel) begin
    for (int w = 0; w < N_WAYS; w++) begin
      meta_hold[w]   <= meta_resp_in[w];
      enctag_hold[w] <= enctag_pseudo[w];
    end
  end
  logic [1:0]              meta_resp [N_WAYS];
  logic [ENC_TAG_BITS-1:0] enctag    [N_WAYS];
  always_comb for (int w = 0; w < N_WAYS; w++) begin
    meta_resp[w] = s1_meta_sel ? meta_resp_in[w]  : meta_hold[w];
    enctag[w]    = s1_meta_sel ? enctag_pseudo[w] : enctag_hold[w];
  end

  // ---- tag 命中判定（per way，含 ECC 检错）----
  logic [N_WAYS-1:0] s1_meta_valid;    // coh != Nothing
  logic [N_WAYS-1:0] s1_tag_errors;    // 该 way valid 且 encTag ECC 错
  logic [N_WAYS-1:0] s1_tag_ecc_match; // tag 相等 + 无 ECC 错 + valid → 真命中 way
  logic [N_WAYS-1:0] s1_real_tag_eq;   // 不含 ECC 的纯 tag 相等（pseudo 注入路径用）
  always_comb begin
    for (int w = 0; w < N_WAYS; w++) begin
      s1_meta_valid[w] = (meta_resp[w] != COH_NOTHING);
      s1_tag_errors[w] = s1_meta_valid[w] && tag_ecc_error(enctag[w]);
      s1_tag_ecc_match[w] = (enctag[w][TAG_BITS-1:0] == get_tag(s1_req.addr))
                            && !s1_tag_errors[w] && s1_meta_valid[w];
      s1_real_tag_eq[w] = (enctag_real[w][TAG_BITS-1:0] == get_tag(s1_req.addr))
                          && s1_meta_valid[w];
    end
  end
  wire s1_tag_match          = |s1_tag_ecc_match;
  wire s1_has_real_tag_eq    = |s1_real_tag_eq;
  wire [N_WAYS-1:0] s1_real_tag_match_oh = priority_oh(s1_real_tag_eq);

  // ---- 命中行的一致性元数据 / 附加 meta（按命中 way one-hot 选）----
  //   注：one-hot 选择写成 always_comb 而非纯函数——函数读 module 级数组（meta_resp/
  //   enctag）但不经参数传入时，连续赋值的敏感表不含这些数组，会漏触发更新。
  logic [1:0] s1_hit_coh_raw;
  always_comb begin
    s1_hit_coh_raw = '0;
    for (int w = 0; w < N_WAYS; w++) if (s1_tag_ecc_match[w]) s1_hit_coh_raw = s1_hit_coh_raw | meta_resp[w];
  end
  logic s1_flag_error; logic [PF_SRC_BITS-1:0] s1_prefetch_meta; logic s1_access_meta;
  always_comb begin
    s1_flag_error = 1'b0; s1_prefetch_meta = '0; s1_access_meta = 1'b0;
    for (int w = 0; w < N_WAYS; w++) if (s1_tag_ecc_match[w]) begin
      case (w)
        0: begin s1_flag_error |= io_extra_meta_resp_0_error; s1_prefetch_meta |= io_extra_meta_resp_0_prefetch; s1_access_meta |= io_extra_meta_resp_0_access; end
        1: begin s1_flag_error |= io_extra_meta_resp_1_error; s1_prefetch_meta |= io_extra_meta_resp_1_prefetch; s1_access_meta |= io_extra_meta_resp_1_access; end
        2: begin s1_flag_error |= io_extra_meta_resp_2_error; s1_prefetch_meta |= io_extra_meta_resp_2_prefetch; s1_access_meta |= io_extra_meta_resp_2_access; end
        3: begin s1_flag_error |= io_extra_meta_resp_3_error; s1_prefetch_meta |= io_extra_meta_resp_3_prefetch; s1_access_meta |= io_extra_meta_resp_3_access; end
      endcase
    end
  end
  coh_e s1_hit_coh; assign s1_hit_coh = coh_e'(s1_hit_coh_raw);

  // ---- 替换 way 选择 ----
  //   优先选无效 way（PriorityMux）；否则用替换算法返回的 way / BtoT evict 指定 way /
  //   pseudo-error 真 tag 命中 way。结果在 s1 锁存保持。
  logic [N_WAYS-1:0] s1_invalid_vec;
  always_comb for (int w = 0; w < N_WAYS; w++) s1_invalid_vec[w] = (meta_resp[w] == COH_NOTHING);

  logic [N_WAYS-1:0] s1_repl_way_en_r;
  wire  [N_WAYS-1:0] s1_repl_way_en_comb =
        (io_pseudo_error_valid && s1_has_real_tag_eq) ? s1_real_tag_match_oh :
        s1_req.miss_fail_cause_evict_btot             ? s1_req.occupy_way    :
                                                        (4'b1 << io_replace_way_way);
  always_ff @(posedge clock) if (s1_valid && s1_meta_sel) s1_repl_way_en_r <= s1_repl_way_en_comb;
  wire [N_WAYS-1:0] s1_repl_way_en = s1_meta_sel ? s1_repl_way_en_comb : s1_repl_way_en_r;

  // 替换 way 的 tag / coh / prefetch 标志 / 真 encTag（均按 s1_repl_way_en one-hot 选）
  logic [TAG_BITS-1:0]     s1_repl_tag;
  logic [1:0]              s1_repl_coh_raw;
  logic [PF_SRC_BITS-1:0]  s1_repl_pf;
  logic [ENC_TAG_BITS-1:0] s1_real_enctag;
  always_comb begin
    s1_repl_tag = '0; s1_repl_coh_raw = '0; s1_repl_pf = '0; s1_real_enctag = '0;
    for (int w = 0; w < N_WAYS; w++) if (s1_repl_way_en[w]) begin
      s1_repl_tag    = s1_repl_tag    | enctag[w][TAG_BITS-1:0];
      s1_repl_coh_raw= s1_repl_coh_raw| meta_resp[w];
      s1_real_enctag = s1_real_enctag | enctag_real[w];
    end
    for (int w = 0; w < N_WAYS; w++) if (s1_repl_way_en[w]) case (w)
      0: s1_repl_pf = s1_repl_pf | io_extra_meta_resp_0_prefetch;
      1: s1_repl_pf = s1_repl_pf | io_extra_meta_resp_1_prefetch;
      2: s1_repl_pf = s1_repl_pf | io_extra_meta_resp_2_prefetch;
      3: s1_repl_pf = s1_repl_pf | io_extra_meta_resp_3_prefetch;
    endcase
  end
  coh_e s1_repl_coh; assign s1_repl_coh = coh_e'(s1_repl_coh_raw);

  wire s1_need_replacement = s1_req.miss && !s1_tag_match;
  // miss 走替换/pseudo 注入时用 repl way；否则用命中 way
  wire [N_WAYS-1:0] s1_way_en =
        (io_pseudo_error_valid || s1_need_replacement) ? s1_repl_way_en : s1_tag_ecc_match;

  // ---- 一致性权限（onAccess）----
  //   grow_starter 返回 {has_perm, grow_param, new_coh}。
  wire [4:0] s1_access_res = grow_starter(categorize(s1_req.cmd), s1_hit_coh);
  wire       s1_has_permission = s1_access_res[4];
  wire [1:0] s1_shrink_perm    = s1_access_res[3:2]; // 实为 grow_param
  coh_e      s1_new_hit_coh; assign s1_new_hit_coh = coh_e'(s1_access_res[1:0]);
  wire       s1_grow_perm = (s1_shrink_perm == PERM_BtoT) && !s1_has_permission;

  wire s1_isStore = !s1_req.replace && !s1_req.probe && !s1_req.miss && req_is_store(s1_req);
  wire s1_isAMO   = !s1_req.replace && !s1_req.probe && !s1_req.miss && req_is_amo(s1_req) && (s1_req.cmd != M_XSC);
  wire s1_pregen_can_go_to_mq = (s1_isStore || s1_isAMO) && !(s1_tag_match && s1_has_permission);
  wire s1_need_eviction = s1_req.miss && !s1_tag_match && (s1_repl_coh != COH_NOTHING);

  // ---- 发 Data 整行读 ----
  assign io_data_read_intend       = s1_valid && s1_need_data;
  assign io_data_readline_valid    = s1_valid && s1_need_data;
  assign io_data_readline_bits_rmask = s1_banked_rmask;
  assign io_data_readline_bits_way_en = s1_way_en;
  assign io_data_readline_bits_addr   = s1_req.vaddr[PADDR_BITS-1:0];

  // ===========================================================================
  //  S2：选数据 + 分流（命中→s3 / miss→MissQueue / evict 冲突→replay）
  // ===========================================================================
  mainpipe_req_t s2_req;
  logic [N_WAYS-1:0] s2_tag_errors, s2_tag_ecc_match_way, s2_way_en;
  logic s2_tag_match, s2_has_real_tag_eq, s2_has_permission, s2_grow_perm_r;
  logic s2_need_replacement, s2_need_eviction, s2_need_data, s2_need_tag;
  logic s2_isStore, s2_has_pseudo_inj, s2_flag_error;
  coh_e s2_hit_coh, s2_new_hit_coh, s2_repl_coh, s2_coh_r;
  logic [TAG_BITS-1:0] s2_repl_tag, s2_tag_r;
  logic [PF_SRC_BITS-1:0] s2_repl_pf;
  logic [ENC_TAG_BITS-1:0] s2_real_enctag;
  logic [N_BANKS-1:0] s2_banked_store_wmask;
  logic s2_can_go_to_mq; // = RegEnable(s1_pregen_can_go_to_mq, s1_fire)

  // s2 分流条件（组合）；具体表达式在下方 s2_hit / s3_ready 等可见后定义。
  logic s2_can_go_to_s3, s2_can_go_to_mq_no_data;
  wire s2_fire_to_s3 = s2_valid && s2_can_go_to_s3;
  wire s2_fire       = s2_valid && s2_can_go;

  always_ff @(posedge clock) if (reset) s2_has_pseudo_inj <= 1'b0;
                            else if (s1_fire) s2_has_pseudo_inj <= io_pseudo_error_valid;
  always_ff @(posedge clock) if (s1_fire) begin
    s2_req               <= s1_req;
    s2_tag_errors        <= s1_tag_errors;
    s2_tag_match         <= s1_tag_match;
    s2_has_real_tag_eq   <= s1_has_real_tag_eq;
    s2_tag_ecc_match_way <= s1_tag_ecc_match;
    s2_hit_coh           <= s1_hit_coh;
    s2_has_permission    <= s1_has_permission;
    s2_new_hit_coh       <= s1_new_hit_coh;
    s2_grow_perm_r       <= s1_grow_perm;
    s2_repl_tag          <= s1_repl_tag;
    s2_repl_coh          <= s1_repl_coh;
    s2_repl_pf           <= s1_repl_pf;
    s2_real_enctag       <= s1_real_enctag;
    s2_need_replacement  <= s1_need_replacement;
    s2_need_eviction     <= s1_need_eviction;
    s2_need_data         <= s1_need_data;
    s2_need_tag          <= s1_need_tag;
    s2_way_en            <= s1_way_en;
    s2_tag_r             <= s1_repl_tag; // 注：s2_tag = need_repl?repl:hit；hit tag = repl_tag(=命中way tag 经 repl 选择) — 见下
    s2_coh_r             <= s1_hit_coh;
    s2_banked_store_wmask<= s1_banked_store_wmask;
    s2_flag_error        <= s1_flag_error;
    s2_isStore           <= s1_isStore;
    s2_can_go_to_mq      <= s1_pregen_can_go_to_mq;
  end
  // 注：golden 的 s2_tag = Mux(need_repl, repl_tag, RegEnable(s1_tag)),
  //     而 s1_tag = s1_hit_tag = get_tag(s1_req.addr)。这里直接用 s2_req.addr 的 tag 重算命中 tag。
  wire [TAG_BITS-1:0] s2_hit_tag = get_tag(s2_req.addr);
  wire [TAG_BITS-1:0] s2_tag = s2_need_replacement ? s2_repl_tag : s2_hit_tag;
  coh_e s2_coh; assign s2_coh = s2_need_replacement ? s2_repl_coh : s2_coh_r;

  assign s2_idx = get_idx(s2_req.vaddr);
  wire s2_grow_perm = s2_grow_perm_r && s2_tag_match;

  // s2 valid 推进
  always_ff @(posedge clock) begin
    if (reset)             s2_valid <= 1'b0;
    else if (s1_fire)      s2_valid <= 1'b1;
    else if (s2_fire)      s2_valid <= 1'b0;
  end
  assign s2_ready = !s2_valid || s2_can_go;

  // ---- pseudo error 注入：真 tag 命中 way 的 encTag 无 ECC 错（用于把 refill way 对齐）----
  wire s2_real_tag_has_error = tag_ecc_error(s2_real_enctag);
  wire s2_refill_tag_eq_way  = s2_has_pseudo_inj && s2_has_real_tag_eq && !s2_real_tag_has_error;

  // ---- tag ECC error 上报判定（EnableTagEcc）----
  wire s2_sc = (s2_req.cmd == M_XSC);
  wire s2_probe_or_atomic = (s2_req.probe || (req_is_amo(s2_req) && !s2_sc)) && !s2_req.miss;
  wire s2_tag_error = ((s2_probe_or_atomic && !s2_tag_match && (|s2_tag_errors))
                       || (!s2_probe_or_atomic && (|(s2_tag_errors & s2_way_en)))) && s2_need_tag;
  wire s2_l2_error  = io_refill_info_valid ? io_refill_info_bits_error : s2_req.error;
  wire s2_error     = s2_flag_error || s2_tag_error || s2_l2_error;
  wire s2_may_report_data_error = s2_need_data && (s2_coh != COH_NOTHING);

  wire s2_hit       = (s2_tag_match || s2_refill_tag_eq_way) && s2_has_permission;
  wire s2_amo_hit   = s2_hit && !s2_req.probe && !s2_req.miss && req_is_amo(s2_req);
  wire s2_store_hit = s2_hit && !s2_req.probe && !s2_req.miss && req_is_store(s2_req);
  wire s2_should_not_report_ecc_error =
        !s2_req.miss && ((req_is_amo(s2_req) && (s2_req.cmd != M_XLR)) || req_is_store(s2_req));

  // ---- BtoT 升权失败：全组里 BtoT 占用 way > nWays-2 且本请求要升 BtoT ----
  wire [2:0] btot_popcnt = io_btot_ways_for_set[0] + io_btot_ways_for_set[1]
                         + io_btot_ways_for_set[2] + io_btot_ways_for_set[3];
  wire s2_grow_perm_fail = (btot_popcnt > (N_WAYS-2)) && s2_grow_perm;

  // ---- 分流：能否进 s3 / 进 MissQueue / replay ----
  wire s2_replace_block = io_replace_block && s2_valid && s2_need_eviction && !s2_refill_tag_eq_way;
  wire s2_req_miss_without_data = s2_valid && s2_req.miss && !io_refill_info_valid;
  // no-data replay 计数寄存器：miss 但 refill 数据未到，可阻 1 拍再 replay
  logic s2_can_go_to_mq_no_data_r;
  always_ff @(posedge clock) begin
    if (reset)         s2_can_go_to_mq_no_data_r <= 1'b0;
    else if (s2_valid) s2_can_go_to_mq_no_data_r <= s2_req_miss_without_data && !s2_can_go_to_mq_no_data;
  end
  assign s2_can_go_to_mq_no_data = s2_req_miss_without_data && s2_can_go_to_mq_no_data_r;
  wire s2_can_go_to_mq_replay = s2_can_go_to_mq_no_data || s2_replace_block;
  // 能进 s3：SC / replace / probe 无条件可进；miss 需 refill 数据已到且不被 evict 阻塞；
  //          store/AMO 命中才进，否则去 MissQueue。最后与 s3_ready 相与。
  wire s2_can_go_to_s3_core =
        s2_sc || s2_req.replace || s2_req.probe ||
        (s2_req.miss ? (io_refill_info_valid && !s2_replace_block)
                     : ((req_is_store(s2_req) || req_is_amo(s2_req)) && s2_hit));
  assign s2_can_go_to_s3 = s2_can_go_to_s3_core && s3_ready;
  assign s2_can_go = s2_can_go_to_s3 || s2_can_go_to_mq || s2_can_go_to_mq_replay;

  wire replay = !io_miss_req_ready || io_wbq_block_miss_req;

  // ---- s2 合并 store 写数据（仅 store 数据，不含 cache 旧数据；s3 再合 cache）----
  //   amo hit 时不与 store 数据合并（用读出的 SRAM 数据做 AMO）。
  logic [ROW_BYTES-1:0] s2_merge_mask [N_BANKS];
  logic [ROW_BITS-1:0]  s2_store_data_merged_nc [N_BANKS]; // nc = no-cache
  always_comb begin
    for (int i = 0; i < N_BANKS; i++) begin
      automatic logic [ROW_BITS-1:0] new_data =
            data_of_bank(i, s2_req.miss ? io_refill_info_bits_store_data : s2_req.store_data);
      s2_merge_mask[i] = s2_amo_hit ? '0 :
            mask_of_bank(i, s2_req.miss ? io_refill_info_bits_store_mask : s2_req.store_mask);
      s2_store_data_merged_nc[i] = merge_put('0, new_data, s2_merge_mask[i]);
    end
  end

  // data readline 流控
  logic s2_fire_to_s3_q;
  always_ff @(posedge clock) if (reset) s2_fire_to_s3_q <= 1'b0; else s2_fire_to_s3_q <= s1_fire; // data_readline_can_go = RegNext(s1_fire)
  assign io_data_readline_can_go   = s2_fire_to_s3_q;
  assign io_data_readline_stall    = s2_valid;
  assign io_data_readline_can_resp = s2_fire_to_s3;

  assign io_pseudo_tag_error_inj_done  = s1_fire && (|s1_meta_valid);
  assign io_pseudo_data_error_inj_done = s2_fire_to_s3 && (s2_tag_error || s2_hit) && s2_may_report_data_error;

  // ===========================================================================
  //  S3：合并 cache 旧数据 / AMOALU 结果，落盘 Data/Meta/Tag，写回，维护 LR/SC
  // ===========================================================================
  mainpipe_req_t s3_req;
  logic [1:0] s3_miss_param;
  // miss_dirty 在本配置无端口（refill_info 不带），恒 false：refill 新状态只取决于
  // cmd 类别 + grant param（见 miss_coh_gen 的 dirty=0 路径）。
  wire s3_miss_dirty = 1'b0;
  logic [TAG_BITS-1:0] s3_tag; logic s3_tag_match;
  coh_e s3_coh, s3_hit_coh, s3_new_hit_coh;
  logic s3_hit, s3_amo_hit, s3_store_hit, s3_need_replacement;
  logic [N_WAYS-1:0] s3_way_en;
  logic [N_BANKS-1:0] s3_banked_store_wmask;
  logic [ROW_BITS-1:0]  s3_store_data_merged_nc [N_BANKS];
  logic [ROW_BYTES-1:0] s3_merge_mask_inv [N_BANKS]; // = ~s2_merge_mask（合 cache 旧数据用）

  always_ff @(posedge clock) if (s2_fire_to_s3) begin
    s3_req           <= s2_req;
    s3_miss_param    <= io_refill_info_bits_miss_param;
    s3_tag           <= s2_tag;
    s3_tag_match     <= s2_tag_match;
    s3_coh           <= s2_coh;
    s3_hit           <= s2_hit;
    s3_amo_hit       <= s2_amo_hit;
    s3_store_hit     <= s2_store_hit;
    s3_hit_coh       <= s2_hit_coh;
    s3_new_hit_coh   <= s2_new_hit_coh;
    s3_way_en        <= s2_way_en;
    s3_banked_store_wmask <= s2_banked_store_wmask;
    s3_idx           <= s2_idx;
    s3_need_replacement <= s2_need_replacement && !s2_refill_tag_eq_way;
    for (int i = 0; i < N_BANKS; i++) begin
      s3_store_data_merged_nc[i] <= s2_store_data_merged_nc[i];
      s3_merge_mask_inv[i]       <= ~s2_merge_mask[i];
    end
  end

  // s3 valid 推进
  always_ff @(posedge clock) begin
    if (reset)              s3_valid <= 1'b0;
    else if (s2_fire_to_s3) s3_valid <= 1'b1;
    else if (s3_valid && s3_can_go) s3_valid <= 1'b0;
  end
  wire s3_fire = s3_valid && s3_can_go;

  // ---- 读出的 cache 数据合进 store 数据（部分写 bank 用旧数据补齐）----
  logic [ROW_BITS-1:0] s3_data [N_BANKS];
  always_comb begin
    s3_data[0]=io_data_resp_0_raw_data; s3_data[1]=io_data_resp_1_raw_data;
    s3_data[2]=io_data_resp_2_raw_data; s3_data[3]=io_data_resp_3_raw_data;
    s3_data[4]=io_data_resp_4_raw_data; s3_data[5]=io_data_resp_5_raw_data;
    s3_data[6]=io_data_resp_6_raw_data; s3_data[7]=io_data_resp_7_raw_data;
  end
  logic [ROW_BITS-1:0] s3_store_data_merged [N_BANKS];
  always_comb for (int i = 0; i < N_BANKS; i++)
    s3_store_data_merged[i] = merge_put(s3_store_data_merged_nc[i], s3_data[i], s3_merge_mask_inv[i]);

  wire [ROW_BITS-1:0] s3_data_word = s3_store_data_merged[s3_req.word_idx];
  // quad word：第 i bank 与下一 bank 拼成 128 位（最后 bank 高位补 0）
  logic [QUAD_BITS-1:0] s3_data_quad_word;
  always_comb begin
    s3_data_quad_word = {{ROW_BITS{1'b0}}, s3_store_data_merged[N_BANKS-1]};
    for (int i = 0; i < N_BANKS-1; i++)
      if (s3_req.word_idx == i)
        s3_data_quad_word = {s3_store_data_merged[i+1], s3_store_data_merged[i]};
  end

  // ---- LR/SC 与 AMO 命令译码 ----
  wire s3_lr  = !s3_req.probe && req_is_amo(s3_req) && (s3_req.cmd == M_XLR);
  wire s3_sc  = !s3_req.probe && req_is_amo(s3_req) && (s3_req.cmd == M_XSC);
  wire s3_cas = !s3_req.probe && req_is_amo(s3_req) && is_amo_cas(s3_req.cmd);
  wire amo_wait_amoalu = req_is_amo(s3_req) && (s3_req.cmd != M_XLR) && (s3_req.cmd != M_XSC)
                         && !is_amo_cas(s3_req.cmd);

  logic [LRSC_CNT_BITS-1:0] lrsc_count;
  logic [PADDR_BITS-1:0]    lrsc_addr;
  wire lrsc_valid = lrsc_count > LRSC_BACKOFF;
  wire [PADDR_BITS-1:0] s3_block_addr = {s3_req.addr[PADDR_BITS-1:6], 6'b0};
  wire s3_lrsc_addr_match = lrsc_valid && (lrsc_addr == s3_block_addr);
  wire s3_sc_fail = s3_sc && (!s3_lrsc_addr_match || !s3_hit);

  // CAS 比较失败：amo_cmp 与读出 quad word 在 amo_mask 字节上不等
  logic [QUAD_BITS-1:0] cas_full_mask;
  always_comb for (int b = 0; b < QUAD_BYTES; b++) cas_full_mask[b*8 +: 8] = {8{s3_req.amo_mask[b]}};
  wire s3_cas_fail = s3_cas && (|(cas_full_mask & (s3_req.amo_cmp ^ s3_data_quad_word)));

  wire s3_can_do_amo = (s3_req.miss && !s3_req.probe && req_is_amo(s3_req)) || s3_amo_hit;
  wire s3_can_do_amo_write = s3_can_do_amo && is_write(s3_req.cmd) && !s3_sc_fail && !s3_cas_fail;

  // ---- AMOALU（黑盒）：对命中字做算术/逻辑 AMO ----
  wire [WORD_BITS-1:0] amoalu_out;
  AMOALU amoalu (
    .io_mask (s3_req.amo_mask[WORD_BYTES-1:0]),
    .io_cmd  (s3_req.cmd),
    .io_lhs  (s3_data_word),
    .io_rhs  (s3_req.amo_data[WORD_BITS-1:0]),
    .io_out  (amoalu_out)
  );
  wire s3_s_amoalu;            // AMOALU 结果已锁存标志
  wire do_amoalu = amo_wait_amoalu && s3_valid && !s3_s_amoalu;

  // ---- 三类 AMO 写数据合并（普通 AMO / SC / CAS）----
  logic [ROW_BITS-1:0] s3_amo_data_merged [N_BANKS];
  logic [ROW_BITS-1:0] s3_sc_data_merged  [N_BANKS];
  logic [ROW_BITS-1:0] s3_cas_data_merged [N_BANKS];
  always_comb for (int i = 0; i < N_BANKS; i++) begin
    automatic logic [ROW_BITS-1:0] old_data = s3_store_data_merged[i];
    automatic logic [ROW_BYTES-1:0] amo_wmask = (s3_req.word_idx == i) ? {ROW_BYTES{1'b1}} : '0;
    s3_amo_data_merged[i] = merge_put(old_data, amoalu_out, amo_wmask);
    // SC：命中字且未失败时写 amo_data
    s3_sc_data_merged[i]  = merge_put(old_data, s3_req.amo_data[WORD_BITS-1:0],
          ((s3_req.word_idx == i) && !s3_sc_fail) ? s3_req.amo_mask[WORD_BYTES-1:0] : '0);
    // CAS：低字选 word_idx 命中；CASQ 的高字选偶 bank 的下一字（i 为奇数且 word_idx==i-1）
    begin
      automatic logic l_select = !s3_cas_fail && (s3_req.word_idx == i);
      automatic logic h_select = !s3_cas_fail && (s3_req.cmd == M_XA_CASQ)
                                 && ((i % 2 == 1) ? (s3_req.word_idx == (i-1)) : 1'b0);
      s3_cas_data_merged[i] = merge_put(old_data,
            h_select ? s3_req.amo_data[QUAD_BITS-1:WORD_BITS] : s3_req.amo_data[WORD_BITS-1:0],
            h_select ? s3_req.amo_mask[QUAD_BYTES-1:WORD_BYTES] :
            l_select ? s3_req.amo_mask[WORD_BYTES-1:0] : '0);
    end
  end
  // AMOALU 结果锁存（do_amoalu 当拍锁存，给下一拍写 SRAM）
  logic [ROW_BITS-1:0] s3_amo_data_merged_reg [N_BANKS];
  always_ff @(posedge clock) if (do_amoalu)
    for (int i = 0; i < N_BANKS; i++) s3_amo_data_merged_reg[i] <= s3_amo_data_merged[i];

  // ---- 一致性状态机：probe 降级 / miss 补块新状态 / store/amo 升权 ----
  wire [5:0] probe_shrink = shrink_helper(s3_req.probe_param, s3_coh);
  coh_e probe_new_coh; assign probe_new_coh = coh_e'(probe_shrink[1:0]);
  wire [2:0] probe_shrink_param = probe_shrink[4:2];
  // miss flush 降级 param（onCacheControl(M_FLUSH) → cmdToPermCap=toN）
  wire [5:0] miss_flush_shrink = shrink_helper(PERM_toN, s3_coh);
  wire [2:0] miss_shrink_param = miss_flush_shrink[4:2];

  wire miss_update_meta  = s3_req.miss;
  wire probe_update_meta = s3_req.probe && s3_tag_match && (s3_coh != probe_new_coh);
  wire store_update_meta = req_is_store(s3_req) && !s3_req.probe && (s3_hit_coh != s3_new_hit_coh);
  wire amo_update_meta   = req_is_amo(s3_req) && !s3_req.probe && (s3_hit_coh != s3_new_hit_coh) && !s3_sc_fail;
  wire update_meta = (miss_update_meta || probe_update_meta || store_update_meta || amo_update_meta) && !s3_req.replace;

  coh_e miss_new_coh; assign miss_new_coh = miss_coh_gen(categorize(s3_req.cmd), s3_miss_param, s3_miss_dirty);
  coh_e new_coh;
  assign new_coh = miss_update_meta  ? miss_new_coh  :
                   probe_update_meta ? probe_new_coh :
                   (store_update_meta || amo_update_meta) ? s3_new_hit_coh : COH_NOTHING;

  wire update_data = s3_req.miss || s3_store_hit || s3_can_do_amo_write;

  // ---- s3 各类请求能否完成（本配置下游写口恒 ready，故仅 probe/miss 看 wb_ready）----
  wire s3_store_can_go   = req_is_store(s3_req) && !s3_req.probe && !s3_req.miss;
  wire s3_amo_can_go     = (s3_amo_hit && (s3_s_amoalu || !amo_wait_amoalu)) || s3_sc_fail;
  wire s3_miss_can_go    = s3_req.miss && (s3_s_amoalu || !amo_wait_amoalu) && io_wb_ready;
  wire s3_replace_nothing= s3_req.replace && (s3_coh == COH_NOTHING);
  assign s3_can_go = (s3_req.probe && io_wb_ready) || s3_store_can_go || s3_amo_can_go
                     || s3_miss_can_go || (s3_req.replace && (s3_replace_nothing || io_wb_ready));
  wire s3_update_data_cango = s3_store_can_go || s3_amo_can_go || s3_miss_can_go;
  assign s3_ready = !s3_valid || s3_can_go;

  // s3_s_amoalu：等 AMOALU 那一拍置 1，请求完成清 0
  logic s3_s_amoalu_r;
  always_ff @(posedge clock) begin
    if (reset)          s3_s_amoalu_r <= 1'b0;
    else if (do_amoalu) s3_s_amoalu_r <= 1'b1;
    else if (s3_fire)   s3_s_amoalu_r <= 1'b0;
  end
  assign s3_s_amoalu = s3_s_amoalu_r;

  // ---- LR/SC 保留锁维护 ----
  always_ff @(posedge clock) begin
    if (reset) lrsc_count <= '0;
    else if (s3_valid && (s3_lr || s3_sc)) begin
      if (s3_can_do_amo && s3_lr) lrsc_count <= LRSC_CYCLES - 1;
      else                        lrsc_count <= '0;
    end else if (io_invalid_resv_set) lrsc_count <= '0;
    else if (lrsc_count > 0)          lrsc_count <= lrsc_count - 1;
  end
  always_ff @(posedge clock)
    if (s3_valid && (s3_lr || s3_sc) && s3_can_do_amo && s3_lr) lrsc_addr <= s3_block_addr;

  logic io_block_lr_q;
  always_ff @(posedge clock) if (reset) io_block_lr_q <= 1'b0; else io_block_lr_q <= (lrsc_count > 0);
  assign io_lrsc_locked_block_valid = lrsc_valid;
  assign io_lrsc_locked_block_bits  = lrsc_addr;
  assign io_block_lr                = io_block_lr_q;
  assign io_update_resv_set         = s3_valid && s3_lr && s3_can_do_amo;

  // ---- 写回判定 ----
  wire miss_wb    = s3_req.miss && s3_need_replacement && (s3_coh != COH_NOTHING);
  wire need_wb    = miss_wb || s3_req.probe || s3_req.replace;
  wire [2:0] writeback_param = s3_req.probe ? probe_shrink_param : miss_shrink_param;
  // alwaysReleaseData=true：probe 要数据 / Dirty / (miss|replace 且非 Nothing) 才带数据
  wire writeback_data = (s3_tag_match && s3_req.probe && s3_req.probe_need_data)
                        || (s3_coh == COH_DIRTY)
                        || ((miss_wb || s3_req.replace) && (s3_coh != COH_NOTHING));

  // ---- s3 error 上报寄存器（beu / wb 两条路径）----
  logic s3_tag_error_beu, s3_tag_error_wb, s3_data_error_beu_r, s3_data_error_wb_r;
  logic s3_l2_error_wb, s3_flag_error_beu, s3_l2_error_beu;
  logic s3_error_beu_r, s3_error_wb_r; logic [PADDR_BITS-1:0] s3_error_paddr_beu_r;
  always_ff @(posedge clock) begin
    if (reset) begin
      // 仅这两个汇总错误位 golden 复位（其余 beu/wb 位无观测前不影响输出）。
      s3_error_beu_r <= 1'b0;
      s3_error_wb_r  <= 1'b0;
    end else begin
      if (s2_fire) begin
        s3_tag_error_beu    <= s2_tag_error;
        s3_data_error_beu_r <= s2_may_report_data_error;
        s3_l2_error_beu     <= s2_l2_error;
        s3_flag_error_beu   <= s2_flag_error;
        s3_error_beu_r      <= s2_error;
        // 存块对齐地址（低 6 位清零），与 golden get_block_addr 后再打拍一致。
        s3_error_paddr_beu_r<= {s2_tag, s2_req.vaddr[11:6], 6'b0};
      end
      if (s2_fire_to_s3) begin
        s3_tag_error_wb     <= s2_tag_error;
        s3_data_error_wb_r  <= s2_may_report_data_error;
        s3_l2_error_wb      <= s2_l2_error;
        s3_error_wb_r       <= s2_error;
      end
    end
  end
  wire s3_data_error_beu = io_readline_error && s3_data_error_beu_r;
  wire s3_data_error_wb  = io_readline_error_delayed && s3_data_error_wb_r;
  wire s3_error_beu = s3_error_beu_r || s3_data_error_beu;
  wire s3_error_wb  = s3_error_wb_r  || s3_data_error_wb;

  // ===========================================================================
  //  输出装配
  // ===========================================================================
  // ---- miss_req（s2 store/AMO miss → MissQueue）----
  assign io_miss_req_valid          = s2_valid && s2_can_go_to_mq;
  assign io_miss_req_bits_source    = s2_req.source;
  assign io_miss_req_bits_cmd       = s2_req.cmd;
  assign io_miss_req_bits_addr      = s2_req.addr;
  assign io_miss_req_bits_vaddr     = s2_req.vaddr;
  assign io_miss_req_bits_full_overwrite = req_is_store(s2_req) && (&s2_req.store_mask);
  assign io_miss_req_bits_word_idx  = s2_req.word_idx;
  assign io_miss_req_bits_amo_data  = s2_req.amo_data;
  assign io_miss_req_bits_amo_mask  = s2_req.amo_mask;
  assign io_miss_req_bits_amo_cmp   = s2_req.amo_cmp;
  assign io_miss_req_bits_req_coh_state = s2_hit_coh;
  assign io_miss_req_bits_id        = s2_req.id;
  assign io_miss_req_bits_isBtoT    = s2_grow_perm;
  assign io_miss_req_bits_occupy_way= s2_tag_ecc_match_way;
  assign io_miss_req_bits_cancel    = s2_grow_perm_fail;
  assign io_miss_req_bits_store_data= s2_req.store_data;
  assign io_miss_req_bits_store_mask= s2_req.store_mask;
  assign io_miss_req_bits_pf_source = L1_HW_PREFETCH_NULL; // miss_req 不带预取源（被裁，无端口）

  assign io_wbq_conflict_check_valid = s2_valid && s2_can_go_to_mq;
  assign io_wbq_conflict_check_bits  = s2_req.addr;

  // ---- store replay / hit resp ----
  assign io_store_replay_resp_valid = s2_valid && ((s2_can_go_to_mq && replay && req_is_store(s2_req))
                                                   || (s2_grow_perm_fail && s2_isStore));
  assign io_store_replay_resp_bits_id = s2_req.id;
  assign io_store_hit_resp_valid = s3_valid && (s3_store_can_go || (s3_miss_can_go && req_is_store(s3_req)));
  assign io_store_hit_resp_bits_id = s3_req.id;

  // ---- atomic resp（replay 优先于 hit）----
  wire atomic_replay_resp_valid = s2_valid && ((s2_can_go_to_mq && replay) || s2_grow_perm_fail) && req_is_amo(s2_req);
  wire atomic_hit_resp_valid    = s3_valid && (s3_amo_can_go || (s3_miss_can_go && req_is_amo(s3_req)));
  assign io_atomic_resp_valid   = atomic_replay_resp_valid || atomic_hit_resp_valid;
  assign io_atomic_resp_bits_source = atomic_replay_resp_valid ? s2_req.source : s3_req.source;
  assign io_atomic_resp_bits_data   = atomic_replay_resp_valid ? '0 :
                                      s3_sc ? {{(QUAD_BITS-1){1'b0}}, s3_sc_fail} : s3_data_quad_word;
  assign io_atomic_resp_bits_miss   = atomic_replay_resp_valid;
  assign io_atomic_resp_bits_miss_id= atomic_replay_resp_valid ? '0 : s3_req.miss_id;
  assign io_atomic_resp_bits_replay = atomic_replay_resp_valid;
  assign io_atomic_resp_bits_error  = !atomic_replay_resp_valid && (s3_error_wb_r || s3_data_error_wb);
  assign io_atomic_resp_bits_ack_miss_queue = !atomic_replay_resp_valid && s3_req.miss;
  assign io_atomic_resp_bits_id     = atomic_replay_resp_valid ? '0 : {{(REQ_ID_BITS-1){1'b0}}, lrsc_valid};

  // ---- Meta / flag 写（s3）----
  assign io_meta_write_valid          = s3_fire && update_meta;
  assign io_meta_write_bits_idx       = s3_idx;
  assign io_meta_write_bits_way_en    = s3_way_en;
  assign io_meta_write_bits_meta_coh_state = new_coh;

  assign io_error_flag_write_valid    = s3_fire && update_meta && (s3_l2_error_wb || s3_req.miss);
  assign io_error_flag_write_bits_idx = s3_idx;
  assign io_error_flag_write_bits_way_en = s3_way_en;
  assign io_error_flag_write_bits_flag   = s3_l2_error_wb;

  assign io_prefetch_flag_write_valid = s3_fire && s3_req.miss;
  assign io_prefetch_flag_write_bits_idx = s3_idx;
  assign io_prefetch_flag_write_bits_way_en = s3_way_en;
  assign io_prefetch_flag_write_bits_source = s3_req.pf_source;

  assign io_access_flag_write_valid   = s3_fire && !s3_req.probe && !s3_req.replace;
  assign io_access_flag_write_bits_idx= s3_idx;
  assign io_access_flag_write_bits_way_en = s3_way_en;
  assign io_access_flag_write_bits_flag   = s3_req.miss ? s3_req.access : 1'b1;

  // ---- Tag 写（s3 miss 补块时写新 tag）----
  assign io_tag_write_valid    = s3_fire && s3_req.miss;
  assign io_tag_write_bits_idx = s3_idx;
  assign io_tag_write_bits_way_en = s3_way_en;
  assign io_tag_write_bits_tag = get_tag(s3_req.addr);
  assign io_tag_write_intend   = s3_req.miss && s3_valid;

  // ---- Data 写（s3）----
  // banked_wmask：miss 整行写 / store 用 store wmask / AMO 写命中字(CASQ 写 2 字)
  logic [N_BANKS-1:0] banked_wmask;
  always_comb begin
    if (s3_req.miss)            banked_wmask = '1;
    else if (s3_store_hit)      banked_wmask = s3_banked_store_wmask;
    else if (s3_can_do_amo_write) begin
      if (s3_req.cmd == M_XA_CASQ) begin
        // CASQ：按 quad_word_idx 点亮相邻两 bank
        banked_wmask = '0;
        for (int q = 0; q < N_BANKS/2; q++)
          if (quad_word_idx(s3_req) == q) banked_wmask[2*q +: 2] = 2'b11;
      end else banked_wmask = (8'b1 << s3_req.word_idx);
    end else banked_wmask = '0;
  end

  // 写数据多选：AMO(等 alu，用锁存值) / SC / CAS / 普通 store
  logic [ROW_BITS-1:0] s3_write_data [N_BANKS];
  always_comb for (int i = 0; i < N_BANKS; i++)
    s3_write_data[i] = amo_wait_amoalu ? s3_amo_data_merged_reg[i] :
                       s3_sc           ? s3_sc_data_merged[i]  :
                       s3_cas          ? s3_cas_data_merged[i] :
                                         s3_store_data_merged[i];
  assign io_data_write_valid     = s3_valid && s3_update_data_cango && update_data;
  assign io_data_write_bits_wmask= banked_wmask;
  assign io_data_write_bits_data_0 = s3_write_data[0];
  assign io_data_write_bits_data_1 = s3_write_data[1];
  assign io_data_write_bits_data_2 = s3_write_data[2];
  assign io_data_write_bits_data_3 = s3_write_data[3];
  assign io_data_write_bits_data_4 = s3_write_data[4];
  assign io_data_write_bits_data_5 = s3_write_data[5];
  assign io_data_write_bits_data_6 = s3_write_data[6];
  assign io_data_write_bits_data_7 = s3_write_data[7];
  // 8 份 data_write ctrl 复制（way_en/addr 喂各 bank 阵列，缩短扇出，与主写口同源）
  `define DW_DUP(N) \
    assign io_data_write_dup_``N``_valid = s3_valid && s3_update_data_cango && update_data; \
    assign io_data_write_dup_``N``_bits_way_en = s3_way_en; \
    assign io_data_write_dup_``N``_bits_addr = s3_req.vaddr[PADDR_BITS-1:0];
  `DW_DUP(0) `DW_DUP(1) `DW_DUP(2) `DW_DUP(3)
  `DW_DUP(4) `DW_DUP(5) `DW_DUP(6) `DW_DUP(7)
  `undef DW_DUP

  // ---- Writeback ----
  assign io_wb_valid = s3_valid && (
        (s3_req.replace && !s3_replace_nothing) ||
        (s3_req.probe) ||                                   // probe 可去 wbq（meta_write 恒 ready）
        (s3_req.miss && (s3_s_amoalu || !amo_wait_amoalu))  // amo miss 去 wbq（tag/data/meta_write 恒 ready）
      ) && need_wb;
  assign io_wb_bits_addr      = {s3_tag, s3_req.vaddr[11:6], 6'b0};
  assign io_wb_bits_param     = writeback_param;
  assign io_wb_bits_voluntary = s3_req.miss || s3_req.replace;
  assign io_wb_bits_hasData   = writeback_data && !s3_tag_error_wb;
  assign io_wb_bits_dirty     = (s3_coh == COH_DIRTY);
  assign io_wb_bits_data      = {s3_data[7], s3_data[6], s3_data[5], s3_data[4],
                                 s3_data[3], s3_data[2], s3_data[1], s3_data[0]};
  assign io_wb_bits_corrupt   = s3_tag_error_wb || s3_data_error_wb;

  // ---- replace 接口（s2 需驱逐时发要替换的块地址）----
  assign io_replace_req_bits_addr  = {s2_tag, s2_req.vaddr[11:6], 6'b0};
  assign io_replace_req_bits_vaddr = s2_req.vaddr;
  assign io_evict_set              = get_idx(s2_req.vaddr);

  // ---- replace 算法访问更新（s3 命中/补块更新 plru）----
  logic replace_access_valid_q;
  always_ff @(posedge clock) if (reset) replace_access_valid_q <= 1'b0; else replace_access_valid_q <= s2_fire_to_s3;
  assign io_replace_access_valid = replace_access_valid_q && !s3_req.probe
                                   && (s3_req.miss || ((req_is_amo(s3_req) || req_is_store(s3_req)) && s3_hit));
  assign io_replace_access_bits_set = s3_idx;
  assign io_replace_access_bits_way = oh_to_way(s3_way_en);

  logic replace_way_set_valid_q;
  always_ff @(posedge clock) if (reset) replace_way_set_valid_q <= 1'b0; else replace_way_set_valid_q <= s0_fire;
  assign io_replace_way_set_bits = s1_idx;

  // ---- SMS evict 提示（s2 miss → s3 时发，延一拍）----
  wire sms_agt_evict_valid = s2_valid && s2_req.miss && s2_fire_to_s3;
  logic sms_evict_valid_q; logic [VADDR_BITS-1:0] sms_evict_vaddr_q;
  always_ff @(posedge clock) begin
    if (reset) sms_evict_valid_q <= 1'b0;
    else       sms_evict_valid_q <= sms_agt_evict_valid;
    if (sms_agt_evict_valid)
      sms_evict_vaddr_q <= {s2_repl_tag[TAG_BITS-1:2], s2_req.vaddr[13:12], {(VADDR_BITS-TAG_BITS){1'b0}}};
  end
  assign io_sms_agt_evict_req_valid      = sms_evict_valid_q;
  assign io_sms_agt_evict_req_bits_vaddr = sms_evict_vaddr_q;

  // ---- bloom filter（驱逐预取块 set / 命中预取块 clr）----
  //   set：s2 miss 驱逐一个「非预取来的」有效块，且本请求来自 L1 预取 → 把被驱逐块入布隆。
  //   addr 为 BloomQuery.get_addr：对 block 地址做折叠 hash（12 位）。
  wire bloom_set_valid = s2_fire_to_s3 && s2_req.miss && !is_from_l1_prefetch(s2_repl_pf)
                         && (s2_repl_coh != COH_NOTHING) && is_from_l1_prefetch(s2_req.pf_source);
  assign io_bloom_filter_query_set_valid = bloom_set_valid;
  assign io_bloom_filter_query_set_bits_addr =
        {s2_repl_tag[5:0], s2_req.vaddr[11:6]} ^ s2_repl_tag[17:6];
  assign io_bloom_filter_query_clr_valid = s3_fire && is_from_l1_prefetch(s3_req.pf_source);
  assign io_bloom_filter_query_clr_bits_addr = s3_req.addr[17:6] ^ s3_req.addr[29:18];

  // ---- MissQueue 信息 ----
  logic s3_refill_resp_q;
  always_ff @(posedge clock) s3_refill_resp_q <= s2_valid && s2_req.miss && s2_fire_to_s3;
  assign io_mainpipe_info_s2_valid    = s2_valid && s2_req.miss;
  assign io_mainpipe_info_s2_miss_id  = s2_req.miss_id;
  assign io_mainpipe_info_s2_replay_to_mq   = s2_can_go_to_mq_no_data;
  assign io_mainpipe_info_s2_evict_BtoT_way = s2_replace_block;
  assign io_mainpipe_info_s2_next_evict_way = priority_oh(~io_btot_ways_for_set);
  assign io_mainpipe_info_s3_valid    = s3_valid;
  assign io_mainpipe_info_s3_miss_id  = s3_req.miss_id;
  assign io_mainpipe_info_s3_refill_resp = s3_refill_resp_q;

  // ---- ECC error 上报 BEU/CSR（s2_fire 后一拍）----
  logic error_valid_gate_q, report_beu_q;
  always_ff @(posedge clock) begin
    if (reset) error_valid_gate_q <= 1'b0;
    else       error_valid_gate_q <= s2_fire && !s2_should_not_report_ecc_error;
    report_beu_q       <= s2_fire; // golden io_error_bits_report_to_beu_REG 无复位
  end
  assign io_error_valid = s3_error_beu && error_valid_gate_q;
  assign io_error_bits_report_to_beu = (s3_tag_error_beu || s3_data_error_beu) && report_beu_q;
  assign io_error_bits_paddr = s3_error_paddr_beu_r; // 已块对齐

  // ---- 流水状态扇出复制（24 份；s1 set 在 s0_fire 锁存，s2/s3 逐级打拍）----
  logic [IDX_BITS-1:0] status_s1_set_q, status_s2_set_q, status_s3_set_q;
  logic [N_WAYS-1:0]   status_s3_way_q;
  logic                status_s2_notrepl_q, status_s3_notrepl_q;
  always_ff @(posedge clock) begin
    if (s0_fire)        status_s1_set_q <= get_idx(s0_req.vaddr);
    if (s1_fire)        status_s2_set_q <= get_idx(s1_req.vaddr);
    if (s2_fire_to_s3) begin status_s3_set_q <= get_idx(s2_req.vaddr); status_s3_way_q <= s2_way_en; end
    if (s1_fire)        status_s2_notrepl_q <= !s1_req.replace;
    if (s2_fire_to_s3)  status_s3_notrepl_q <= !s2_req.replace;
  end
  wire status_s1_valid = s1_valid;
  wire status_s2_valid = s2_valid && status_s2_notrepl_q;
  wire status_s3_valid = s3_valid && status_s3_notrepl_q;

  // 24 份完全相同：用宏展开（机械复制，对齐 golden 扁平输出）
  `define STAT_DUP(N) \
    assign io_status_dup_``N``_s1_valid = status_s1_valid; \
    assign io_status_dup_``N``_s1_bits_set = status_s1_set_q; \
    assign io_status_dup_``N``_s1_bits_way_en = s1_way_en; \
    assign io_status_dup_``N``_s2_valid = status_s2_valid; \
    assign io_status_dup_``N``_s2_bits_set = status_s2_set_q; \
    assign io_status_dup_``N``_s2_bits_way_en = s2_way_en; \
    assign io_status_dup_``N``_s3_valid = status_s3_valid; \
    assign io_status_dup_``N``_s3_bits_set = status_s3_set_q; \
    assign io_status_dup_``N``_s3_bits_way_en = status_s3_way_q;
  `STAT_DUP(0)  `STAT_DUP(1)  `STAT_DUP(2)  `STAT_DUP(3)  `STAT_DUP(4)  `STAT_DUP(5)
  `STAT_DUP(6)  `STAT_DUP(7)  `STAT_DUP(8)  `STAT_DUP(9)  `STAT_DUP(10) `STAT_DUP(11)
  `STAT_DUP(12) `STAT_DUP(13) `STAT_DUP(14) `STAT_DUP(15) `STAT_DUP(16) `STAT_DUP(17)
  `STAT_DUP(18) `STAT_DUP(19) `STAT_DUP(20) `STAT_DUP(21) `STAT_DUP(22) `STAT_DUP(23)
  `undef STAT_DUP

  // ---- perf 事件（延 2 拍）----
  logic p0_q, p0_q2; logic [2:0] p1_q, p1_q2;
  wire [2:0] occupancy = s0_fire + s1_valid + s2_valid + s3_valid;
  always_ff @(posedge clock) begin
    p0_q <= s0_fire; p0_q2 <= p0_q;
    p1_q <= occupancy; p1_q2 <= p1_q;
  end
  assign io_perf_0_value = {5'b0, p0_q2};
  assign io_perf_1_value = {3'b0, p1_q2};

endmodule
