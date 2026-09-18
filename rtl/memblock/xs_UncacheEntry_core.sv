// =============================================================================
// xs_UncacheEntry_core —— LoadQueueUncache 的**单条** uncache(MMIO / NC) load 条目
//                         （UncacheEntry 家族 16 个变体共用的参数化核）
//
// 位置：MemBlock / LSU 的 LoadQueue 侧。一条 load 如果落在 uncacheable 区间
//       （MMIO 设备寄存器，或 NC = non-cacheable 普通内存），DCache 不能替它做，
//       必须整条搬到这里排队，由 Uncache 单元走总线单发单收。LoadQueueUncache
//       并排放 16 条本模块（entries_0..entries_15），每条装一笔在飞的 uncache load。
//
// 一条请求在本条目里走的四步（uncacheState）：
//   S_IDLE  收下请求后停在这里等发车条件：
//           · NC     —— 无条件可发（NC 访问没有副作用顺序要求）
//           · MMIO   —— 必须等自己成为 ROB 头（io_rob_pendingMMIOld 且
//                       req.uop.robIdx == 上一拍的 io_rob_pendingPtr）。
//                       MMIO 读有副作用，一旦发出去就不能被投机取消。
//   S_REQ   往 Uncache 总线发 req（addr/vaddr/mask/nc/memBackTypeMM/robIdx），
//           握手成功进 S_RESP。
//   S_RESP  等数据回来（io_uncache_resp）。数据、denied、corrupt 落寄存器。
//   S_WAIT  往 load 写回口送结果：NC 走 io_ncOut，MMIO 走 io_mmioOut +
//           io_mmioRawData。对方 ready 即完成，回 S_IDLE。
//
// 另一条与四步状态并行的握手：**slaveId**。Uncache 单元收下请求后会广播一个
// idResp{mid, sid}：mid 是"这笔是哪条 entry 的"，sid 是"我把它放在我的第几号槽"。
// 每条 entry 只认 mid == 自己的编号（ENTRY_ID，这就是家族 16 个变体唯一的差别），
// 认领时把 sid 记进 slave_id 并把 slave_accept 置起，供父级查询。
//
// flush（本条目作废）在四个状态里含义不同，这是本模块最容易看漏的地方：
//   S_IDLE / S_REQ  收到指向本条目的 redirect 立刻作废（还没发车，可以直接丢）；
//   S_RESP          **不能立刻丢** —— 请求已经在总线上，必须等 resp 回来才认账，
//                   所以 need_flush 先被 need_flush_q 记住，等 resp 那一拍才 flush；
//   S_WAIT          写回完成（writeback）或被 redirect 打中，都回 S_IDLE。
//
// 判据是 golden RTL（G1-canonical/golden-rtl/UncacheEntry*.sv），Chisel
// （XiangShan src/main/scala/xiangshan/mem/lsqueue/LoadQueueUncache.scala）只用来
// 解释"为什么"。几处"照抄 golden、不许抹平"的地方就地注明：
//
//   · req_uop_flushPipe / req_uop_replayInst 是两个**没有输入端口**的 payload 位。
//     父级对这两位给的是常数 0，firtool 于是把锁存写成 `q <= ~enq & q` ——
//     一个只会衰减到 0、再也起不来的寄存器，而它俩照样接到 mmioOut / ncOut 的
//     flushPipe / replayInst 输出上。**这两个寄存器必须原样保留**：FM 把寄存器当
//     自由变量、不做可达性分析，少一份就是 golden-only 死位，连双射都没有。
//
//   · pending_ptr_{flag,value}_q 的写使能是"新值与旧值不等才写"——
//     写同一个值和不写完全等价，所以这道使能在功能上是恒等的冗余。照抄。
//
//   · io_mmioOut / io_ncOut / io_exception 三处的 exceptionVec 都**不是**直接透传
//     req_uop_exceptionVec：第 5 位（loadAccessFault）被 denied 覆盖、第 19 位
//     （hardwareError）被 `corrupt & ~denied` 覆盖。对应地 golden 的输入端口表里
//     根本没有 io_req_bits_uop_exceptionVec_5 / _19（父级恒 0，被 firtool 消掉），
//     所以这两位也没有 req_uop_exceptionVec_5 / _19 寄存器。
//
//   · denied / corrupt 只在"收下新请求"那一拍清零（`~enq & q`），flush 不清。
//
// 家族 16 个变体（实测，见 verif/ut/UncacheEntry/gen.py 的 check_family()）：
//   除模块名外**逐字节只差一个常数** 7'hN（N = 0..F = 后缀 = 父级 entries_N 的槽号），
//   即本核的 ENTRY_ID 参数。没有一个变体有结构差异，故 16/16 全部由本核覆盖。
// =============================================================================
// 本文件导航（共 1654 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L689   状态定义
//   L702   被锁存的请求
//   L910   控制寄存器
//   L923   组合：握手、redirect 判定、发车条件
//   L990   时序：控制寄存器
//   L1032  时序：payload / slave_id / resp_data
//   L1243  输出：mmioOut / ncOut / mmioRawData / uncache.req / exception
//   L1250  BEGIN GENERATED(outputs)
//

module xs_UncacheEntry_core #(
  // 本条目在 LoadQueueUncache 里的槽号；只用在一处：认领 Uncache 的 idResp。
  parameter logic [6:0] ENTRY_ID = 7'd0
) (
  // BEGIN GENERATED(core-ports)  —— 端口表逐位抄自 G1 golden UncacheEntry.sv
  input            clock,
  input            reset,
  input            io_redirect_valid,
  input            io_redirect_bits_robIdx_flag,
  input  [7:0]     io_redirect_bits_robIdx_value,
  input            io_redirect_bits_level,
  output           io_flush,
  input            io_rob_pendingMMIOld,
  input            io_rob_pendingPtr_flag,
  input  [7:0]     io_rob_pendingPtr_value,
  output           io_mmioSelect,
  output           io_slaveId_valid,
  output [3:0]     io_slaveId_bits,
  input            io_req_valid,
  input  [31:0]    io_req_bits_uop_instr,
  input  [49:0]    io_req_bits_uop_pc,
  input  [9:0]     io_req_bits_uop_foldpc,
  input            io_req_bits_uop_exceptionVec_0,
  input            io_req_bits_uop_exceptionVec_1,
  input            io_req_bits_uop_exceptionVec_2,
  input            io_req_bits_uop_exceptionVec_3,
  input            io_req_bits_uop_exceptionVec_4,
  input            io_req_bits_uop_exceptionVec_6,
  input            io_req_bits_uop_exceptionVec_7,
  input            io_req_bits_uop_exceptionVec_8,
  input            io_req_bits_uop_exceptionVec_9,
  input            io_req_bits_uop_exceptionVec_10,
  input            io_req_bits_uop_exceptionVec_11,
  input            io_req_bits_uop_exceptionVec_12,
  input            io_req_bits_uop_exceptionVec_13,
  input            io_req_bits_uop_exceptionVec_14,
  input            io_req_bits_uop_exceptionVec_15,
  input            io_req_bits_uop_exceptionVec_16,
  input            io_req_bits_uop_exceptionVec_17,
  input            io_req_bits_uop_exceptionVec_18,
  input            io_req_bits_uop_exceptionVec_20,
  input            io_req_bits_uop_exceptionVec_21,
  input            io_req_bits_uop_exceptionVec_22,
  input            io_req_bits_uop_exceptionVec_23,
  input            io_req_bits_uop_isFetchMalAddr,
  input            io_req_bits_uop_hasException,
  input  [3:0]     io_req_bits_uop_trigger,
  input            io_req_bits_uop_preDecodeInfo_valid,
  input            io_req_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]     io_req_bits_uop_preDecodeInfo_brType,
  input            io_req_bits_uop_preDecodeInfo_isCall,
  input            io_req_bits_uop_preDecodeInfo_isRet,
  input            io_req_bits_uop_pred_taken,
  input            io_req_bits_uop_crossPageIPFFix,
  input            io_req_bits_uop_ftqPtr_flag,
  input  [5:0]     io_req_bits_uop_ftqPtr_value,
  input  [3:0]     io_req_bits_uop_ftqOffset,
  input            io_req_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]     io_req_bits_uop_srcType_0,
  input  [3:0]     io_req_bits_uop_srcType_1,
  input  [3:0]     io_req_bits_uop_srcType_2,
  input  [3:0]     io_req_bits_uop_srcType_3,
  input  [3:0]     io_req_bits_uop_srcType_4,
  input  [5:0]     io_req_bits_uop_ldest,
  input  [34:0]    io_req_bits_uop_fuType,
  input  [8:0]     io_req_bits_uop_fuOpType,
  input            io_req_bits_uop_rfWen,
  input            io_req_bits_uop_fpWen,
  input            io_req_bits_uop_vecWen,
  input            io_req_bits_uop_v0Wen,
  input            io_req_bits_uop_vlWen,
  input            io_req_bits_uop_isXSTrap,
  input            io_req_bits_uop_waitForward,
  input            io_req_bits_uop_blockBackward,
  input            io_req_bits_uop_canRobCompress,
  input  [3:0]     io_req_bits_uop_selImm,
  input  [31:0]    io_req_bits_uop_imm,
  input  [1:0]     io_req_bits_uop_fpu_typeTagOut,
  input            io_req_bits_uop_fpu_wflags,
  input  [1:0]     io_req_bits_uop_fpu_typ,
  input  [1:0]     io_req_bits_uop_fpu_fmt,
  input  [2:0]     io_req_bits_uop_fpu_rm,
  input            io_req_bits_uop_vpu_vill,
  input            io_req_bits_uop_vpu_vma,
  input            io_req_bits_uop_vpu_vta,
  input  [1:0]     io_req_bits_uop_vpu_vsew,
  input  [2:0]     io_req_bits_uop_vpu_vlmul,
  input            io_req_bits_uop_vpu_specVill,
  input            io_req_bits_uop_vpu_specVma,
  input            io_req_bits_uop_vpu_specVta,
  input  [1:0]     io_req_bits_uop_vpu_specVsew,
  input  [2:0]     io_req_bits_uop_vpu_specVlmul,
  input            io_req_bits_uop_vpu_vm,
  input  [7:0]     io_req_bits_uop_vpu_vstart,
  input  [2:0]     io_req_bits_uop_vpu_frm,
  input            io_req_bits_uop_vpu_fpu_isFpToVecInst,
  input            io_req_bits_uop_vpu_fpu_isFP32Instr,
  input            io_req_bits_uop_vpu_fpu_isFP64Instr,
  input            io_req_bits_uop_vpu_fpu_isReduction,
  input            io_req_bits_uop_vpu_fpu_isFoldTo1_2,
  input            io_req_bits_uop_vpu_fpu_isFoldTo1_4,
  input            io_req_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]     io_req_bits_uop_vpu_vxrm,
  input  [6:0]     io_req_bits_uop_vpu_vuopIdx,
  input            io_req_bits_uop_vpu_lastUop,
  input  [127:0]   io_req_bits_uop_vpu_vmask,
  input  [7:0]     io_req_bits_uop_vpu_vl,
  input  [2:0]     io_req_bits_uop_vpu_nf,
  input  [1:0]     io_req_bits_uop_vpu_veew,
  input            io_req_bits_uop_vpu_isReverse,
  input            io_req_bits_uop_vpu_isExt,
  input            io_req_bits_uop_vpu_isNarrow,
  input            io_req_bits_uop_vpu_isDstMask,
  input            io_req_bits_uop_vpu_isOpMask,
  input            io_req_bits_uop_vpu_isMove,
  input            io_req_bits_uop_vpu_isDependOldVd,
  input            io_req_bits_uop_vpu_isWritePartVd,
  input            io_req_bits_uop_vpu_isVleff,
  input            io_req_bits_uop_vlsInstr,
  input            io_req_bits_uop_wfflags,
  input            io_req_bits_uop_isMove,
  input            io_req_bits_uop_isDropAmocasSta,
  input  [6:0]     io_req_bits_uop_uopIdx,
  input            io_req_bits_uop_isVset,
  input            io_req_bits_uop_firstUop,
  input            io_req_bits_uop_lastUop,
  input  [6:0]     io_req_bits_uop_numUops,
  input  [6:0]     io_req_bits_uop_numWB,
  input  [2:0]     io_req_bits_uop_commitType,
  input            io_req_bits_uop_srcState_0,
  input            io_req_bits_uop_srcState_1,
  input            io_req_bits_uop_srcState_2,
  input            io_req_bits_uop_srcState_3,
  input            io_req_bits_uop_srcState_4,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_0_0,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_0_1,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_0_2,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_1_0,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_1_1,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_1_2,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_2_0,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_2_1,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_2_2,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_3_0,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_3_1,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_3_2,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_4_0,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_4_1,
  input  [1:0]     io_req_bits_uop_srcLoadDependency_4_2,
  input  [7:0]     io_req_bits_uop_psrc_0,
  input  [7:0]     io_req_bits_uop_psrc_1,
  input  [7:0]     io_req_bits_uop_psrc_2,
  input  [7:0]     io_req_bits_uop_psrc_3,
  input  [7:0]     io_req_bits_uop_psrc_4,
  input  [7:0]     io_req_bits_uop_pdest,
  input            io_req_bits_uop_useRegCache_0,
  input            io_req_bits_uop_useRegCache_1,
  input  [4:0]     io_req_bits_uop_regCacheIdx_0,
  input  [4:0]     io_req_bits_uop_regCacheIdx_1,
  input            io_req_bits_uop_robIdx_flag,
  input  [7:0]     io_req_bits_uop_robIdx_value,
  input  [2:0]     io_req_bits_uop_instrSize,
  input            io_req_bits_uop_dirtyFs,
  input            io_req_bits_uop_dirtyVs,
  input  [3:0]     io_req_bits_uop_traceBlockInPipe_itype,
  input  [3:0]     io_req_bits_uop_traceBlockInPipe_iretire,
  input            io_req_bits_uop_traceBlockInPipe_ilastsize,
  input            io_req_bits_uop_eliminatedMove,
  input            io_req_bits_uop_snapshot,
  input            io_req_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]    io_req_bits_uop_debugInfo_renameTime,
  input  [63:0]    io_req_bits_uop_debugInfo_dispatchTime,
  input  [63:0]    io_req_bits_uop_debugInfo_enqRsTime,
  input  [63:0]    io_req_bits_uop_debugInfo_selectTime,
  input  [63:0]    io_req_bits_uop_debugInfo_issueTime,
  input  [63:0]    io_req_bits_uop_debugInfo_writebackTime,
  input  [63:0]    io_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]    io_req_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]    io_req_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]    io_req_bits_uop_debug_seqNum_seqNum,
  input  [7:0]     io_req_bits_uop_debug_seqNum_uopIdx,
  input            io_req_bits_uop_storeSetHit,
  input            io_req_bits_uop_waitForRobIdx_flag,
  input  [7:0]     io_req_bits_uop_waitForRobIdx_value,
  input            io_req_bits_uop_loadWaitBit,
  input            io_req_bits_uop_loadWaitStrict,
  input  [4:0]     io_req_bits_uop_ssid,
  input            io_req_bits_uop_lqIdx_flag,
  input  [6:0]     io_req_bits_uop_lqIdx_value,
  input            io_req_bits_uop_sqIdx_flag,
  input  [5:0]     io_req_bits_uop_sqIdx_value,
  input            io_req_bits_uop_singleStep,
  input  [34:0]    io_req_bits_uop_debug_fuType,
  input            io_req_bits_uop_debug_sim_trig,
  input  [4:0]     io_req_bits_uop_numLsElem,
  input  [49:0]    io_req_bits_vaddr,
  input  [63:0]    io_req_bits_fullva,
  input  [47:0]    io_req_bits_paddr,
  input  [63:0]    io_req_bits_gpaddr,
  input  [15:0]    io_req_bits_mask,
  input            io_req_bits_nc,
  input            io_req_bits_mmio,
  input            io_req_bits_memBackTypeMM,
  input            io_req_bits_isHyper,
  input            io_req_bits_isForVSnonLeafPTE,
  input            io_req_bits_isvec,
  input            io_req_bits_is128bit,
  input            io_req_bits_vecActive,
  input  [6:0]     io_req_bits_schedIndex,
  input            io_mmioOut_ready,
  output           io_mmioOut_valid,
  output [31:0]    io_mmioOut_bits_uop_instr,
  output [49:0]    io_mmioOut_bits_uop_pc,
  output [9:0]     io_mmioOut_bits_uop_foldpc,
  output           io_mmioOut_bits_uop_exceptionVec_0,
  output           io_mmioOut_bits_uop_exceptionVec_1,
  output           io_mmioOut_bits_uop_exceptionVec_2,
  output           io_mmioOut_bits_uop_exceptionVec_3,
  output           io_mmioOut_bits_uop_exceptionVec_4,
  output           io_mmioOut_bits_uop_exceptionVec_5,
  output           io_mmioOut_bits_uop_exceptionVec_6,
  output           io_mmioOut_bits_uop_exceptionVec_7,
  output           io_mmioOut_bits_uop_exceptionVec_8,
  output           io_mmioOut_bits_uop_exceptionVec_9,
  output           io_mmioOut_bits_uop_exceptionVec_10,
  output           io_mmioOut_bits_uop_exceptionVec_11,
  output           io_mmioOut_bits_uop_exceptionVec_12,
  output           io_mmioOut_bits_uop_exceptionVec_13,
  output           io_mmioOut_bits_uop_exceptionVec_14,
  output           io_mmioOut_bits_uop_exceptionVec_15,
  output           io_mmioOut_bits_uop_exceptionVec_16,
  output           io_mmioOut_bits_uop_exceptionVec_17,
  output           io_mmioOut_bits_uop_exceptionVec_18,
  output           io_mmioOut_bits_uop_exceptionVec_19,
  output           io_mmioOut_bits_uop_exceptionVec_20,
  output           io_mmioOut_bits_uop_exceptionVec_21,
  output           io_mmioOut_bits_uop_exceptionVec_22,
  output           io_mmioOut_bits_uop_exceptionVec_23,
  output           io_mmioOut_bits_uop_isFetchMalAddr,
  output           io_mmioOut_bits_uop_hasException,
  output [3:0]     io_mmioOut_bits_uop_trigger,
  output           io_mmioOut_bits_uop_preDecodeInfo_valid,
  output           io_mmioOut_bits_uop_preDecodeInfo_isRVC,
  output [1:0]     io_mmioOut_bits_uop_preDecodeInfo_brType,
  output           io_mmioOut_bits_uop_preDecodeInfo_isCall,
  output           io_mmioOut_bits_uop_preDecodeInfo_isRet,
  output           io_mmioOut_bits_uop_pred_taken,
  output           io_mmioOut_bits_uop_crossPageIPFFix,
  output           io_mmioOut_bits_uop_ftqPtr_flag,
  output [5:0]     io_mmioOut_bits_uop_ftqPtr_value,
  output [3:0]     io_mmioOut_bits_uop_ftqOffset,
  output           io_mmioOut_bits_uop_satpFlushFirstFetchFault,
  output [3:0]     io_mmioOut_bits_uop_srcType_0,
  output [3:0]     io_mmioOut_bits_uop_srcType_1,
  output [3:0]     io_mmioOut_bits_uop_srcType_2,
  output [3:0]     io_mmioOut_bits_uop_srcType_3,
  output [3:0]     io_mmioOut_bits_uop_srcType_4,
  output [5:0]     io_mmioOut_bits_uop_ldest,
  output [34:0]    io_mmioOut_bits_uop_fuType,
  output [8:0]     io_mmioOut_bits_uop_fuOpType,
  output           io_mmioOut_bits_uop_rfWen,
  output           io_mmioOut_bits_uop_fpWen,
  output           io_mmioOut_bits_uop_vecWen,
  output           io_mmioOut_bits_uop_v0Wen,
  output           io_mmioOut_bits_uop_vlWen,
  output           io_mmioOut_bits_uop_isXSTrap,
  output           io_mmioOut_bits_uop_waitForward,
  output           io_mmioOut_bits_uop_blockBackward,
  output           io_mmioOut_bits_uop_flushPipe,
  output           io_mmioOut_bits_uop_canRobCompress,
  output [3:0]     io_mmioOut_bits_uop_selImm,
  output [31:0]    io_mmioOut_bits_uop_imm,
  output [1:0]     io_mmioOut_bits_uop_fpu_typeTagOut,
  output           io_mmioOut_bits_uop_fpu_wflags,
  output [1:0]     io_mmioOut_bits_uop_fpu_typ,
  output [1:0]     io_mmioOut_bits_uop_fpu_fmt,
  output [2:0]     io_mmioOut_bits_uop_fpu_rm,
  output           io_mmioOut_bits_uop_vpu_vill,
  output           io_mmioOut_bits_uop_vpu_vma,
  output           io_mmioOut_bits_uop_vpu_vta,
  output [1:0]     io_mmioOut_bits_uop_vpu_vsew,
  output [2:0]     io_mmioOut_bits_uop_vpu_vlmul,
  output           io_mmioOut_bits_uop_vpu_specVill,
  output           io_mmioOut_bits_uop_vpu_specVma,
  output           io_mmioOut_bits_uop_vpu_specVta,
  output [1:0]     io_mmioOut_bits_uop_vpu_specVsew,
  output [2:0]     io_mmioOut_bits_uop_vpu_specVlmul,
  output           io_mmioOut_bits_uop_vpu_vm,
  output [7:0]     io_mmioOut_bits_uop_vpu_vstart,
  output [2:0]     io_mmioOut_bits_uop_vpu_frm,
  output           io_mmioOut_bits_uop_vpu_fpu_isFpToVecInst,
  output           io_mmioOut_bits_uop_vpu_fpu_isFP32Instr,
  output           io_mmioOut_bits_uop_vpu_fpu_isFP64Instr,
  output           io_mmioOut_bits_uop_vpu_fpu_isReduction,
  output           io_mmioOut_bits_uop_vpu_fpu_isFoldTo1_2,
  output           io_mmioOut_bits_uop_vpu_fpu_isFoldTo1_4,
  output           io_mmioOut_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]     io_mmioOut_bits_uop_vpu_vxrm,
  output [6:0]     io_mmioOut_bits_uop_vpu_vuopIdx,
  output           io_mmioOut_bits_uop_vpu_lastUop,
  output [127:0]   io_mmioOut_bits_uop_vpu_vmask,
  output [7:0]     io_mmioOut_bits_uop_vpu_vl,
  output [2:0]     io_mmioOut_bits_uop_vpu_nf,
  output [1:0]     io_mmioOut_bits_uop_vpu_veew,
  output           io_mmioOut_bits_uop_vpu_isReverse,
  output           io_mmioOut_bits_uop_vpu_isExt,
  output           io_mmioOut_bits_uop_vpu_isNarrow,
  output           io_mmioOut_bits_uop_vpu_isDstMask,
  output           io_mmioOut_bits_uop_vpu_isOpMask,
  output           io_mmioOut_bits_uop_vpu_isMove,
  output           io_mmioOut_bits_uop_vpu_isDependOldVd,
  output           io_mmioOut_bits_uop_vpu_isWritePartVd,
  output           io_mmioOut_bits_uop_vpu_isVleff,
  output           io_mmioOut_bits_uop_vlsInstr,
  output           io_mmioOut_bits_uop_wfflags,
  output           io_mmioOut_bits_uop_isMove,
  output           io_mmioOut_bits_uop_isDropAmocasSta,
  output [6:0]     io_mmioOut_bits_uop_uopIdx,
  output           io_mmioOut_bits_uop_isVset,
  output           io_mmioOut_bits_uop_firstUop,
  output           io_mmioOut_bits_uop_lastUop,
  output [6:0]     io_mmioOut_bits_uop_numUops,
  output [6:0]     io_mmioOut_bits_uop_numWB,
  output [2:0]     io_mmioOut_bits_uop_commitType,
  output           io_mmioOut_bits_uop_srcState_0,
  output           io_mmioOut_bits_uop_srcState_1,
  output           io_mmioOut_bits_uop_srcState_2,
  output           io_mmioOut_bits_uop_srcState_3,
  output           io_mmioOut_bits_uop_srcState_4,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_0_0,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_0_1,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_0_2,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_1_0,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_1_1,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_1_2,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_2_0,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_2_1,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_2_2,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_3_0,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_3_1,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_3_2,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_4_0,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_4_1,
  output [1:0]     io_mmioOut_bits_uop_srcLoadDependency_4_2,
  output [7:0]     io_mmioOut_bits_uop_psrc_0,
  output [7:0]     io_mmioOut_bits_uop_psrc_1,
  output [7:0]     io_mmioOut_bits_uop_psrc_2,
  output [7:0]     io_mmioOut_bits_uop_psrc_3,
  output [7:0]     io_mmioOut_bits_uop_psrc_4,
  output [7:0]     io_mmioOut_bits_uop_pdest,
  output           io_mmioOut_bits_uop_useRegCache_0,
  output           io_mmioOut_bits_uop_useRegCache_1,
  output [4:0]     io_mmioOut_bits_uop_regCacheIdx_0,
  output [4:0]     io_mmioOut_bits_uop_regCacheIdx_1,
  output           io_mmioOut_bits_uop_robIdx_flag,
  output [7:0]     io_mmioOut_bits_uop_robIdx_value,
  output [2:0]     io_mmioOut_bits_uop_instrSize,
  output           io_mmioOut_bits_uop_dirtyFs,
  output           io_mmioOut_bits_uop_dirtyVs,
  output [3:0]     io_mmioOut_bits_uop_traceBlockInPipe_itype,
  output [3:0]     io_mmioOut_bits_uop_traceBlockInPipe_iretire,
  output           io_mmioOut_bits_uop_traceBlockInPipe_ilastsize,
  output           io_mmioOut_bits_uop_eliminatedMove,
  output           io_mmioOut_bits_uop_snapshot,
  output           io_mmioOut_bits_uop_debugInfo_eliminatedMove,
  output [63:0]    io_mmioOut_bits_uop_debugInfo_renameTime,
  output [63:0]    io_mmioOut_bits_uop_debugInfo_dispatchTime,
  output [63:0]    io_mmioOut_bits_uop_debugInfo_enqRsTime,
  output [63:0]    io_mmioOut_bits_uop_debugInfo_selectTime,
  output [63:0]    io_mmioOut_bits_uop_debugInfo_issueTime,
  output [63:0]    io_mmioOut_bits_uop_debugInfo_writebackTime,
  output [63:0]    io_mmioOut_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]    io_mmioOut_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]    io_mmioOut_bits_uop_debugInfo_tlbRespTime,
  output [55:0]    io_mmioOut_bits_uop_debug_seqNum_seqNum,
  output [7:0]     io_mmioOut_bits_uop_debug_seqNum_uopIdx,
  output           io_mmioOut_bits_uop_storeSetHit,
  output           io_mmioOut_bits_uop_waitForRobIdx_flag,
  output [7:0]     io_mmioOut_bits_uop_waitForRobIdx_value,
  output           io_mmioOut_bits_uop_loadWaitBit,
  output           io_mmioOut_bits_uop_loadWaitStrict,
  output [4:0]     io_mmioOut_bits_uop_ssid,
  output           io_mmioOut_bits_uop_lqIdx_flag,
  output [6:0]     io_mmioOut_bits_uop_lqIdx_value,
  output           io_mmioOut_bits_uop_sqIdx_flag,
  output [5:0]     io_mmioOut_bits_uop_sqIdx_value,
  output           io_mmioOut_bits_uop_singleStep,
  output           io_mmioOut_bits_uop_replayInst,
  output [34:0]    io_mmioOut_bits_uop_debug_fuType,
  output           io_mmioOut_bits_uop_debug_sim_trig,
  output [4:0]     io_mmioOut_bits_uop_numLsElem,
  output [47:0]    io_mmioOut_bits_debug_paddr,
  output [49:0]    io_mmioOut_bits_debug_vaddr,
  output [63:0]    io_mmioRawData_lqData,
  output [8:0]     io_mmioRawData_uop_fuOpType,
  output           io_mmioRawData_uop_fpWen,
  output [2:0]     io_mmioRawData_addrOffset,
  input            io_ncOut_ready,
  output           io_ncOut_valid,
  output [31:0]    io_ncOut_bits_uop_instr,
  output [49:0]    io_ncOut_bits_uop_pc,
  output [9:0]     io_ncOut_bits_uop_foldpc,
  output           io_ncOut_bits_uop_exceptionVec_0,
  output           io_ncOut_bits_uop_exceptionVec_1,
  output           io_ncOut_bits_uop_exceptionVec_2,
  output           io_ncOut_bits_uop_exceptionVec_3,
  output           io_ncOut_bits_uop_exceptionVec_4,
  output           io_ncOut_bits_uop_exceptionVec_5,
  output           io_ncOut_bits_uop_exceptionVec_6,
  output           io_ncOut_bits_uop_exceptionVec_7,
  output           io_ncOut_bits_uop_exceptionVec_8,
  output           io_ncOut_bits_uop_exceptionVec_9,
  output           io_ncOut_bits_uop_exceptionVec_10,
  output           io_ncOut_bits_uop_exceptionVec_11,
  output           io_ncOut_bits_uop_exceptionVec_12,
  output           io_ncOut_bits_uop_exceptionVec_13,
  output           io_ncOut_bits_uop_exceptionVec_14,
  output           io_ncOut_bits_uop_exceptionVec_15,
  output           io_ncOut_bits_uop_exceptionVec_16,
  output           io_ncOut_bits_uop_exceptionVec_17,
  output           io_ncOut_bits_uop_exceptionVec_18,
  output           io_ncOut_bits_uop_exceptionVec_19,
  output           io_ncOut_bits_uop_exceptionVec_20,
  output           io_ncOut_bits_uop_exceptionVec_21,
  output           io_ncOut_bits_uop_exceptionVec_22,
  output           io_ncOut_bits_uop_exceptionVec_23,
  output           io_ncOut_bits_uop_isFetchMalAddr,
  output           io_ncOut_bits_uop_hasException,
  output [3:0]     io_ncOut_bits_uop_trigger,
  output           io_ncOut_bits_uop_preDecodeInfo_valid,
  output           io_ncOut_bits_uop_preDecodeInfo_isRVC,
  output [1:0]     io_ncOut_bits_uop_preDecodeInfo_brType,
  output           io_ncOut_bits_uop_preDecodeInfo_isCall,
  output           io_ncOut_bits_uop_preDecodeInfo_isRet,
  output           io_ncOut_bits_uop_pred_taken,
  output           io_ncOut_bits_uop_crossPageIPFFix,
  output           io_ncOut_bits_uop_ftqPtr_flag,
  output [5:0]     io_ncOut_bits_uop_ftqPtr_value,
  output [3:0]     io_ncOut_bits_uop_ftqOffset,
  output           io_ncOut_bits_uop_satpFlushFirstFetchFault,
  output [3:0]     io_ncOut_bits_uop_srcType_0,
  output [3:0]     io_ncOut_bits_uop_srcType_1,
  output [3:0]     io_ncOut_bits_uop_srcType_2,
  output [3:0]     io_ncOut_bits_uop_srcType_3,
  output [3:0]     io_ncOut_bits_uop_srcType_4,
  output [5:0]     io_ncOut_bits_uop_ldest,
  output [34:0]    io_ncOut_bits_uop_fuType,
  output [8:0]     io_ncOut_bits_uop_fuOpType,
  output           io_ncOut_bits_uop_rfWen,
  output           io_ncOut_bits_uop_fpWen,
  output           io_ncOut_bits_uop_vecWen,
  output           io_ncOut_bits_uop_v0Wen,
  output           io_ncOut_bits_uop_vlWen,
  output           io_ncOut_bits_uop_isXSTrap,
  output           io_ncOut_bits_uop_waitForward,
  output           io_ncOut_bits_uop_blockBackward,
  output           io_ncOut_bits_uop_flushPipe,
  output           io_ncOut_bits_uop_canRobCompress,
  output [3:0]     io_ncOut_bits_uop_selImm,
  output [31:0]    io_ncOut_bits_uop_imm,
  output [1:0]     io_ncOut_bits_uop_fpu_typeTagOut,
  output           io_ncOut_bits_uop_fpu_wflags,
  output [1:0]     io_ncOut_bits_uop_fpu_typ,
  output [1:0]     io_ncOut_bits_uop_fpu_fmt,
  output [2:0]     io_ncOut_bits_uop_fpu_rm,
  output           io_ncOut_bits_uop_vpu_vill,
  output           io_ncOut_bits_uop_vpu_vma,
  output           io_ncOut_bits_uop_vpu_vta,
  output [1:0]     io_ncOut_bits_uop_vpu_vsew,
  output [2:0]     io_ncOut_bits_uop_vpu_vlmul,
  output           io_ncOut_bits_uop_vpu_specVill,
  output           io_ncOut_bits_uop_vpu_specVma,
  output           io_ncOut_bits_uop_vpu_specVta,
  output [1:0]     io_ncOut_bits_uop_vpu_specVsew,
  output [2:0]     io_ncOut_bits_uop_vpu_specVlmul,
  output           io_ncOut_bits_uop_vpu_vm,
  output [7:0]     io_ncOut_bits_uop_vpu_vstart,
  output [2:0]     io_ncOut_bits_uop_vpu_frm,
  output           io_ncOut_bits_uop_vpu_fpu_isFpToVecInst,
  output           io_ncOut_bits_uop_vpu_fpu_isFP32Instr,
  output           io_ncOut_bits_uop_vpu_fpu_isFP64Instr,
  output           io_ncOut_bits_uop_vpu_fpu_isReduction,
  output           io_ncOut_bits_uop_vpu_fpu_isFoldTo1_2,
  output           io_ncOut_bits_uop_vpu_fpu_isFoldTo1_4,
  output           io_ncOut_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]     io_ncOut_bits_uop_vpu_vxrm,
  output [6:0]     io_ncOut_bits_uop_vpu_vuopIdx,
  output           io_ncOut_bits_uop_vpu_lastUop,
  output [127:0]   io_ncOut_bits_uop_vpu_vmask,
  output [7:0]     io_ncOut_bits_uop_vpu_vl,
  output [2:0]     io_ncOut_bits_uop_vpu_nf,
  output [1:0]     io_ncOut_bits_uop_vpu_veew,
  output           io_ncOut_bits_uop_vpu_isReverse,
  output           io_ncOut_bits_uop_vpu_isExt,
  output           io_ncOut_bits_uop_vpu_isNarrow,
  output           io_ncOut_bits_uop_vpu_isDstMask,
  output           io_ncOut_bits_uop_vpu_isOpMask,
  output           io_ncOut_bits_uop_vpu_isMove,
  output           io_ncOut_bits_uop_vpu_isDependOldVd,
  output           io_ncOut_bits_uop_vpu_isWritePartVd,
  output           io_ncOut_bits_uop_vpu_isVleff,
  output           io_ncOut_bits_uop_vlsInstr,
  output           io_ncOut_bits_uop_wfflags,
  output           io_ncOut_bits_uop_isMove,
  output           io_ncOut_bits_uop_isDropAmocasSta,
  output [6:0]     io_ncOut_bits_uop_uopIdx,
  output           io_ncOut_bits_uop_isVset,
  output           io_ncOut_bits_uop_firstUop,
  output           io_ncOut_bits_uop_lastUop,
  output [6:0]     io_ncOut_bits_uop_numUops,
  output [6:0]     io_ncOut_bits_uop_numWB,
  output [2:0]     io_ncOut_bits_uop_commitType,
  output           io_ncOut_bits_uop_srcState_0,
  output           io_ncOut_bits_uop_srcState_1,
  output           io_ncOut_bits_uop_srcState_2,
  output           io_ncOut_bits_uop_srcState_3,
  output           io_ncOut_bits_uop_srcState_4,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_0_0,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_0_1,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_0_2,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_1_0,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_1_1,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_1_2,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_2_0,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_2_1,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_2_2,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_3_0,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_3_1,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_3_2,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_4_0,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_4_1,
  output [1:0]     io_ncOut_bits_uop_srcLoadDependency_4_2,
  output [7:0]     io_ncOut_bits_uop_psrc_0,
  output [7:0]     io_ncOut_bits_uop_psrc_1,
  output [7:0]     io_ncOut_bits_uop_psrc_2,
  output [7:0]     io_ncOut_bits_uop_psrc_3,
  output [7:0]     io_ncOut_bits_uop_psrc_4,
  output [7:0]     io_ncOut_bits_uop_pdest,
  output           io_ncOut_bits_uop_useRegCache_0,
  output           io_ncOut_bits_uop_useRegCache_1,
  output [4:0]     io_ncOut_bits_uop_regCacheIdx_0,
  output [4:0]     io_ncOut_bits_uop_regCacheIdx_1,
  output           io_ncOut_bits_uop_robIdx_flag,
  output [7:0]     io_ncOut_bits_uop_robIdx_value,
  output [2:0]     io_ncOut_bits_uop_instrSize,
  output           io_ncOut_bits_uop_dirtyFs,
  output           io_ncOut_bits_uop_dirtyVs,
  output [3:0]     io_ncOut_bits_uop_traceBlockInPipe_itype,
  output [3:0]     io_ncOut_bits_uop_traceBlockInPipe_iretire,
  output           io_ncOut_bits_uop_traceBlockInPipe_ilastsize,
  output           io_ncOut_bits_uop_eliminatedMove,
  output           io_ncOut_bits_uop_snapshot,
  output           io_ncOut_bits_uop_debugInfo_eliminatedMove,
  output [63:0]    io_ncOut_bits_uop_debugInfo_renameTime,
  output [63:0]    io_ncOut_bits_uop_debugInfo_dispatchTime,
  output [63:0]    io_ncOut_bits_uop_debugInfo_enqRsTime,
  output [63:0]    io_ncOut_bits_uop_debugInfo_selectTime,
  output [63:0]    io_ncOut_bits_uop_debugInfo_issueTime,
  output [63:0]    io_ncOut_bits_uop_debugInfo_writebackTime,
  output [63:0]    io_ncOut_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]    io_ncOut_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]    io_ncOut_bits_uop_debugInfo_tlbRespTime,
  output [55:0]    io_ncOut_bits_uop_debug_seqNum_seqNum,
  output [7:0]     io_ncOut_bits_uop_debug_seqNum_uopIdx,
  output           io_ncOut_bits_uop_storeSetHit,
  output           io_ncOut_bits_uop_waitForRobIdx_flag,
  output [7:0]     io_ncOut_bits_uop_waitForRobIdx_value,
  output           io_ncOut_bits_uop_loadWaitBit,
  output           io_ncOut_bits_uop_loadWaitStrict,
  output [4:0]     io_ncOut_bits_uop_ssid,
  output           io_ncOut_bits_uop_lqIdx_flag,
  output [6:0]     io_ncOut_bits_uop_lqIdx_value,
  output           io_ncOut_bits_uop_sqIdx_flag,
  output [5:0]     io_ncOut_bits_uop_sqIdx_value,
  output           io_ncOut_bits_uop_singleStep,
  output           io_ncOut_bits_uop_replayInst,
  output [34:0]    io_ncOut_bits_uop_debug_fuType,
  output           io_ncOut_bits_uop_debug_sim_trig,
  output [4:0]     io_ncOut_bits_uop_numLsElem,
  output [49:0]    io_ncOut_bits_vaddr,
  output [47:0]    io_ncOut_bits_paddr,
  output [128:0]   io_ncOut_bits_data,
  output           io_ncOut_bits_isvec,
  output           io_ncOut_bits_is128bit,
  output           io_ncOut_bits_vecActive,
  output [6:0]     io_ncOut_bits_schedIndex,
  input            io_uncache_req_ready,
  output           io_uncache_req_valid,
  output           io_uncache_req_bits_robIdx_flag,
  output [7:0]     io_uncache_req_bits_robIdx_value,
  output [47:0]    io_uncache_req_bits_addr,
  output [49:0]    io_uncache_req_bits_vaddr,
  output [7:0]     io_uncache_req_bits_mask,
  output           io_uncache_req_bits_nc,
  output           io_uncache_req_bits_memBackTypeMM,
  input            io_uncache_idResp_valid,
  input  [6:0]     io_uncache_idResp_bits_mid,
  input  [3:0]     io_uncache_idResp_bits_sid,
  input            io_uncache_resp_valid,
  input  [63:0]    io_uncache_resp_bits_data,
  input            io_uncache_resp_bits_denied,
  input            io_uncache_resp_bits_corrupt,
  output           io_exception_valid,
  output           io_exception_bits_uop_exceptionVec_3,
  output           io_exception_bits_uop_exceptionVec_4,
  output           io_exception_bits_uop_exceptionVec_5,
  output           io_exception_bits_uop_exceptionVec_13,
  output           io_exception_bits_uop_exceptionVec_19,
  output           io_exception_bits_uop_exceptionVec_21,
  output [6:0]     io_exception_bits_uop_uopIdx,
  output           io_exception_bits_uop_robIdx_flag,
  output [7:0]     io_exception_bits_uop_robIdx_value,
  output [63:0]    io_exception_bits_fullva,
  output [63:0]    io_exception_bits_gpaddr,
  output           io_exception_bits_isHyper,
  output           io_exception_bits_isForVSnonLeafPTE
  // END GENERATED
);

  // ---------------------------------------------------------------------------
  // 状态定义（uncacheState 的四步）
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    S_IDLE = 2'd0,  // 已收下请求（或空闲），等发车条件
    S_REQ  = 2'd1,  // 等 Uncache 总线收走 req
    S_RESP = 2'd2,  // 等 Uncache 回数据
    S_WAIT = 2'd3   // 等 load 写回口收走结果
  } state_e;

  state_e state;
  state_e next_state;

  // ---------------------------------------------------------------------------
  // 被锁存的请求（payload）
  //
  // 这一整段只做一件事：收下一条 uncache load 的**整个 bundle**，原样存住，
  // 到写回时再原样吐出去。190 个字段逐个列出是 golden 的展平形状，照抄。
  // 寄存器名沿用 golden 的 req_<字段>（本身就是语义名），便于逐个对照。
  // ★这一段整段不带复位★ —— golden 的复位域里只有下面「控制寄存器」那几个。
  // ---------------------------------------------------------------------------
  logic req_valid;   // 本条目当前装着一条有效请求（带复位）

  // BEGIN GENERATED(payload-decl)
  logic [31:0]    req_uop_instr;
  logic [49:0]    req_uop_pc;
  logic [9:0]     req_uop_foldpc;
  logic           req_uop_exceptionVec_0;
  logic           req_uop_exceptionVec_1;
  logic           req_uop_exceptionVec_2;
  logic           req_uop_exceptionVec_3;
  logic           req_uop_exceptionVec_4;
  logic           req_uop_exceptionVec_6;
  logic           req_uop_exceptionVec_7;
  logic           req_uop_exceptionVec_8;
  logic           req_uop_exceptionVec_9;
  logic           req_uop_exceptionVec_10;
  logic           req_uop_exceptionVec_11;
  logic           req_uop_exceptionVec_12;
  logic           req_uop_exceptionVec_13;
  logic           req_uop_exceptionVec_14;
  logic           req_uop_exceptionVec_15;
  logic           req_uop_exceptionVec_16;
  logic           req_uop_exceptionVec_17;
  logic           req_uop_exceptionVec_18;
  logic           req_uop_exceptionVec_20;
  logic           req_uop_exceptionVec_21;
  logic           req_uop_exceptionVec_22;
  logic           req_uop_exceptionVec_23;
  logic           req_uop_isFetchMalAddr;
  logic           req_uop_hasException;
  logic [3:0]     req_uop_trigger;
  logic           req_uop_preDecodeInfo_valid;
  logic           req_uop_preDecodeInfo_isRVC;
  logic [1:0]     req_uop_preDecodeInfo_brType;
  logic           req_uop_preDecodeInfo_isCall;
  logic           req_uop_preDecodeInfo_isRet;
  logic           req_uop_pred_taken;
  logic           req_uop_crossPageIPFFix;
  logic           req_uop_ftqPtr_flag;
  logic [5:0]     req_uop_ftqPtr_value;
  logic [3:0]     req_uop_ftqOffset;
  logic           req_uop_satpFlushFirstFetchFault;
  logic [3:0]     req_uop_srcType_0;
  logic [3:0]     req_uop_srcType_1;
  logic [3:0]     req_uop_srcType_2;
  logic [3:0]     req_uop_srcType_3;
  logic [3:0]     req_uop_srcType_4;
  logic [5:0]     req_uop_ldest;
  logic [34:0]    req_uop_fuType;
  logic [8:0]     req_uop_fuOpType;
  logic           req_uop_rfWen;
  logic           req_uop_fpWen;
  logic           req_uop_vecWen;
  logic           req_uop_v0Wen;
  logic           req_uop_vlWen;
  logic           req_uop_isXSTrap;
  logic           req_uop_waitForward;
  logic           req_uop_blockBackward;
  logic           req_uop_canRobCompress;
  logic [3:0]     req_uop_selImm;
  logic [31:0]    req_uop_imm;
  logic [1:0]     req_uop_fpu_typeTagOut;
  logic           req_uop_fpu_wflags;
  logic [1:0]     req_uop_fpu_typ;
  logic [1:0]     req_uop_fpu_fmt;
  logic [2:0]     req_uop_fpu_rm;
  logic           req_uop_vpu_vill;
  logic           req_uop_vpu_vma;
  logic           req_uop_vpu_vta;
  logic [1:0]     req_uop_vpu_vsew;
  logic [2:0]     req_uop_vpu_vlmul;
  logic           req_uop_vpu_specVill;
  logic           req_uop_vpu_specVma;
  logic           req_uop_vpu_specVta;
  logic [1:0]     req_uop_vpu_specVsew;
  logic [2:0]     req_uop_vpu_specVlmul;
  logic           req_uop_vpu_vm;
  logic [7:0]     req_uop_vpu_vstart;
  logic [2:0]     req_uop_vpu_frm;
  logic           req_uop_vpu_fpu_isFpToVecInst;
  logic           req_uop_vpu_fpu_isFP32Instr;
  logic           req_uop_vpu_fpu_isFP64Instr;
  logic           req_uop_vpu_fpu_isReduction;
  logic           req_uop_vpu_fpu_isFoldTo1_2;
  logic           req_uop_vpu_fpu_isFoldTo1_4;
  logic           req_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]     req_uop_vpu_vxrm;
  logic [6:0]     req_uop_vpu_vuopIdx;
  logic           req_uop_vpu_lastUop;
  logic [127:0]   req_uop_vpu_vmask;
  logic [7:0]     req_uop_vpu_vl;
  logic [2:0]     req_uop_vpu_nf;
  logic [1:0]     req_uop_vpu_veew;
  logic           req_uop_vpu_isReverse;
  logic           req_uop_vpu_isExt;
  logic           req_uop_vpu_isNarrow;
  logic           req_uop_vpu_isDstMask;
  logic           req_uop_vpu_isOpMask;
  logic           req_uop_vpu_isMove;
  logic           req_uop_vpu_isDependOldVd;
  logic           req_uop_vpu_isWritePartVd;
  logic           req_uop_vpu_isVleff;
  logic           req_uop_vlsInstr;
  logic           req_uop_wfflags;
  logic           req_uop_isMove;
  logic           req_uop_isDropAmocasSta;
  logic [6:0]     req_uop_uopIdx;
  logic           req_uop_isVset;
  logic           req_uop_firstUop;
  logic           req_uop_lastUop;
  logic [6:0]     req_uop_numUops;
  logic [6:0]     req_uop_numWB;
  logic [2:0]     req_uop_commitType;
  logic           req_uop_srcState_0;
  logic           req_uop_srcState_1;
  logic           req_uop_srcState_2;
  logic           req_uop_srcState_3;
  logic           req_uop_srcState_4;
  logic [1:0]     req_uop_srcLoadDependency_0_0;
  logic [1:0]     req_uop_srcLoadDependency_0_1;
  logic [1:0]     req_uop_srcLoadDependency_0_2;
  logic [1:0]     req_uop_srcLoadDependency_1_0;
  logic [1:0]     req_uop_srcLoadDependency_1_1;
  logic [1:0]     req_uop_srcLoadDependency_1_2;
  logic [1:0]     req_uop_srcLoadDependency_2_0;
  logic [1:0]     req_uop_srcLoadDependency_2_1;
  logic [1:0]     req_uop_srcLoadDependency_2_2;
  logic [1:0]     req_uop_srcLoadDependency_3_0;
  logic [1:0]     req_uop_srcLoadDependency_3_1;
  logic [1:0]     req_uop_srcLoadDependency_3_2;
  logic [1:0]     req_uop_srcLoadDependency_4_0;
  logic [1:0]     req_uop_srcLoadDependency_4_1;
  logic [1:0]     req_uop_srcLoadDependency_4_2;
  logic [7:0]     req_uop_psrc_0;
  logic [7:0]     req_uop_psrc_1;
  logic [7:0]     req_uop_psrc_2;
  logic [7:0]     req_uop_psrc_3;
  logic [7:0]     req_uop_psrc_4;
  logic [7:0]     req_uop_pdest;
  logic           req_uop_useRegCache_0;
  logic           req_uop_useRegCache_1;
  logic [4:0]     req_uop_regCacheIdx_0;
  logic [4:0]     req_uop_regCacheIdx_1;
  logic           req_uop_robIdx_flag;
  logic [7:0]     req_uop_robIdx_value;
  logic [2:0]     req_uop_instrSize;
  logic           req_uop_dirtyFs;
  logic           req_uop_dirtyVs;
  logic [3:0]     req_uop_traceBlockInPipe_itype;
  logic [3:0]     req_uop_traceBlockInPipe_iretire;
  logic           req_uop_traceBlockInPipe_ilastsize;
  logic           req_uop_eliminatedMove;
  logic           req_uop_snapshot;
  logic           req_uop_debugInfo_eliminatedMove;
  logic [63:0]    req_uop_debugInfo_renameTime;
  logic [63:0]    req_uop_debugInfo_dispatchTime;
  logic [63:0]    req_uop_debugInfo_enqRsTime;
  logic [63:0]    req_uop_debugInfo_selectTime;
  logic [63:0]    req_uop_debugInfo_issueTime;
  logic [63:0]    req_uop_debugInfo_writebackTime;
  logic [63:0]    req_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]    req_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]    req_uop_debugInfo_tlbRespTime;
  logic [55:0]    req_uop_debug_seqNum_seqNum;
  logic [7:0]     req_uop_debug_seqNum_uopIdx;
  logic           req_uop_storeSetHit;
  logic           req_uop_waitForRobIdx_flag;
  logic [7:0]     req_uop_waitForRobIdx_value;
  logic           req_uop_loadWaitBit;
  logic           req_uop_loadWaitStrict;
  logic [4:0]     req_uop_ssid;
  logic           req_uop_lqIdx_flag;
  logic [6:0]     req_uop_lqIdx_value;
  logic           req_uop_sqIdx_flag;
  logic [5:0]     req_uop_sqIdx_value;
  logic           req_uop_singleStep;
  logic [34:0]    req_uop_debug_fuType;
  logic           req_uop_debug_sim_trig;
  logic [4:0]     req_uop_numLsElem;
  logic [49:0]    req_vaddr;
  logic [63:0]    req_fullva;
  logic [47:0]    req_paddr;
  logic [63:0]    req_gpaddr;
  logic [15:0]    req_mask;
  logic           req_nc;
  logic           req_mmio;
  logic           req_memBackTypeMM;
  logic           req_isHyper;
  logic           req_isForVSnonLeafPTE;
  logic           req_isvec;
  logic           req_is128bit;
  logic           req_vecActive;
  logic [6:0]     req_schedIndex;
  // END GENERATED

  // 两个没有输入端口的 payload 位：父级恒 0，展开成"只会衰减到 0"的寄存器。
  // 一份都不许少（见文件头）。
  logic           req_uop_flushPipe;
  logic           req_uop_replayInst;

  // ---------------------------------------------------------------------------
  // 控制寄存器（golden 的复位域就是这一组 + req_valid，异步复位）
  // ---------------------------------------------------------------------------
  logic           slave_accept;         // 已认领 Uncache 的 idResp
  logic [3:0]     slave_id;             // 认领到的 sid（不复位）
  logic [63:0]    resp_data;            // Uncache 回来的数据（不复位）
  logic           denied;               // 总线拒绝 -> loadAccessFault
  logic           corrupt;              // 总线数据损坏 -> hardwareError
  logic           need_flush_q;         // S_RESP 期间被 redirect 打中，记账等 resp
  logic           pending_mmio_ld_q;    // io_rob_pendingMMIOld 打一拍
  logic           pending_ptr_flag_q;   // io_rob_pendingPtr 打一拍
  logic [7:0]     pending_ptr_value_q;

  // ---------------------------------------------------------------------------
  // 组合：握手、redirect 判定、发车条件
  // ---------------------------------------------------------------------------
  logic flush;              // 本拍本条目作废/退休（父级也要看，见 io_flush）
  logic need_flush;         // 本拍 redirect 打中本条目
  logic writeback;          // 本拍写回口成交
  logic slave_ack;          // 本拍 Uncache 的 idResp 是给本条目的
  logic can_send_req;       // 本拍允许发车（MMIO 要等 ROB 头）
  logic enq;                // 本拍收下一条新请求（payload 写使能）
  logic mmio_out_valid;
  logic nc_out_valid;
  logic uncache_req_valid;

  // CircularQueuePtr：{flag, value}。needFlush 与"是不是 ROB 头"都按它比。
  wire [8:0] req_rob_idx      = {req_uop_robIdx_flag, req_uop_robIdx_value};
  wire [8:0] redirect_rob_idx = {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value};
  wire [8:0] rob_pending_ptr  = {pending_ptr_flag_q, pending_ptr_value_q};

  // robIdx.needFlush(redirect)：
  //   level=1（精确 redirect，只冲掉这一条自己）时比"完全相等"；
  //   否则比"是不是排在 redirect 之后"——环形指针的 isAfter 展开成
  //   flag 异或 flag 再异或 (value > value)。
  //   ★ `>` 的优先级高于 `^`，golden 就是这么写的，别加括号改语义 ★
  assign need_flush = req_valid & io_redirect_valid
                    & ((io_redirect_bits_level & (req_rob_idx == redirect_rob_idx))
                       | (req_uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
                          ^ (req_uop_robIdx_value > io_redirect_bits_robIdx_value)));

  assign slave_ack = req_valid & io_uncache_idResp_valid
                   & (io_uncache_idResp_bits_mid == ENTRY_ID);

  assign uncache_req_valid = (state == S_REQ)  & ~need_flush;
  assign nc_out_valid      = (state == S_WAIT) & ~need_flush &  req_nc;
  assign mmio_out_valid    = (state == S_WAIT) & ~need_flush & ~req_nc;
  assign writeback = req_nc ? (io_ncOut_ready   & nc_out_valid)
                            : (io_mmioOut_ready & mmio_out_valid);

  // MMIO 读有副作用，必须等它成为 ROB 头才发；NC 无条件可发。
  assign can_send_req = req_valid & ~need_flush
                      & (req_nc | (pending_mmio_ld_q & (req_rob_idx == rob_pending_ptr)));

  // flush 在四个状态里含义不同（见文件头）。
  always_comb begin
    case (state)
      S_RESP : flush = io_uncache_resp_valid & (need_flush | need_flush_q);
      S_WAIT : flush = need_flush | writeback;
      default: flush = need_flush;   // S_IDLE / S_REQ：还没发车，直接丢
    endcase
  end

  // 收请求：flush 优先于 io_req_valid（golden 的 when(flush) 在最前面）。
  assign enq = ~flush & io_req_valid;

  always_comb begin
    next_state = state;
    case (state)
      S_IDLE : if (need_flush)      next_state = S_IDLE;
               else if (can_send_req) next_state = S_REQ;
      S_REQ  : if (need_flush)      next_state = S_IDLE;
               else if (io_uncache_req_ready & uncache_req_valid) next_state = S_RESP;
      S_RESP : if (io_uncache_resp_valid)
                 next_state = (need_flush | need_flush_q) ? S_IDLE : S_WAIT;
      S_WAIT : if (need_flush | writeback) next_state = S_IDLE;
      default: ;
    endcase
  end

  // ---------------------------------------------------------------------------
  // 时序：控制寄存器（异步复位域 —— golden 只有这几个带复位）
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      req_valid           <= 1'b0;
      slave_accept        <= 1'b0;
      state               <= S_IDLE;
      denied              <= 1'b0;
      corrupt             <= 1'b0;
      need_flush_q        <= 1'b0;
      pending_mmio_ld_q   <= 1'b0;
      pending_ptr_flag_q  <= 1'b0;
      pending_ptr_value_q <= 8'h0;
    end
    else begin
      // 优先级：flush 丢弃 > 收新请求 > 认领 idResp（只动 slave_*） > 写回完成。
      req_valid    <= ~flush & (io_req_valid | (slave_ack | ~writeback) & req_valid);
      slave_accept <= ~(flush | io_req_valid) & (slave_ack | ~writeback & slave_accept);
      state        <= next_state;

      // denied / corrupt：resp 那一拍取总线的值；否则只在"收下新请求"时清零。
      // ★flush 不清它俩★（golden 如此）。
      if (io_uncache_resp_valid) begin
        denied  <= io_uncache_resp_bits_denied;
        corrupt <= io_uncache_resp_bits_corrupt;
      end
      else begin
        denied  <= ~enq & denied;
        corrupt <= ~enq & corrupt;
      end

      need_flush_q      <= ~flush & (need_flush | need_flush_q);
      pending_mmio_ld_q <= io_rob_pendingMMIOld;
      // 写使能是"新值与旧值不等"——功能上恒等于无条件打拍，照抄 golden。
      if ({io_rob_pendingPtr_flag, io_rob_pendingPtr_value} != rob_pending_ptr) begin
        pending_ptr_flag_q  <= io_rob_pendingPtr_flag;
        pending_ptr_value_q <= io_rob_pendingPtr_value;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 时序：payload / slave_id / resp_data（**无复位**域）
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (enq) begin
      // BEGIN GENERATED(payload-latch)
      req_uop_instr <= io_req_bits_uop_instr;
      req_uop_pc <= io_req_bits_uop_pc;
      req_uop_foldpc <= io_req_bits_uop_foldpc;
      req_uop_exceptionVec_0 <= io_req_bits_uop_exceptionVec_0;
      req_uop_exceptionVec_1 <= io_req_bits_uop_exceptionVec_1;
      req_uop_exceptionVec_2 <= io_req_bits_uop_exceptionVec_2;
      req_uop_exceptionVec_3 <= io_req_bits_uop_exceptionVec_3;
      req_uop_exceptionVec_4 <= io_req_bits_uop_exceptionVec_4;
      req_uop_exceptionVec_6 <= io_req_bits_uop_exceptionVec_6;
      req_uop_exceptionVec_7 <= io_req_bits_uop_exceptionVec_7;
      req_uop_exceptionVec_8 <= io_req_bits_uop_exceptionVec_8;
      req_uop_exceptionVec_9 <= io_req_bits_uop_exceptionVec_9;
      req_uop_exceptionVec_10 <= io_req_bits_uop_exceptionVec_10;
      req_uop_exceptionVec_11 <= io_req_bits_uop_exceptionVec_11;
      req_uop_exceptionVec_12 <= io_req_bits_uop_exceptionVec_12;
      req_uop_exceptionVec_13 <= io_req_bits_uop_exceptionVec_13;
      req_uop_exceptionVec_14 <= io_req_bits_uop_exceptionVec_14;
      req_uop_exceptionVec_15 <= io_req_bits_uop_exceptionVec_15;
      req_uop_exceptionVec_16 <= io_req_bits_uop_exceptionVec_16;
      req_uop_exceptionVec_17 <= io_req_bits_uop_exceptionVec_17;
      req_uop_exceptionVec_18 <= io_req_bits_uop_exceptionVec_18;
      req_uop_exceptionVec_20 <= io_req_bits_uop_exceptionVec_20;
      req_uop_exceptionVec_21 <= io_req_bits_uop_exceptionVec_21;
      req_uop_exceptionVec_22 <= io_req_bits_uop_exceptionVec_22;
      req_uop_exceptionVec_23 <= io_req_bits_uop_exceptionVec_23;
      req_uop_isFetchMalAddr <= io_req_bits_uop_isFetchMalAddr;
      req_uop_hasException <= io_req_bits_uop_hasException;
      req_uop_trigger <= io_req_bits_uop_trigger;
      req_uop_preDecodeInfo_valid <= io_req_bits_uop_preDecodeInfo_valid;
      req_uop_preDecodeInfo_isRVC <= io_req_bits_uop_preDecodeInfo_isRVC;
      req_uop_preDecodeInfo_brType <= io_req_bits_uop_preDecodeInfo_brType;
      req_uop_preDecodeInfo_isCall <= io_req_bits_uop_preDecodeInfo_isCall;
      req_uop_preDecodeInfo_isRet <= io_req_bits_uop_preDecodeInfo_isRet;
      req_uop_pred_taken <= io_req_bits_uop_pred_taken;
      req_uop_crossPageIPFFix <= io_req_bits_uop_crossPageIPFFix;
      req_uop_ftqPtr_flag <= io_req_bits_uop_ftqPtr_flag;
      req_uop_ftqPtr_value <= io_req_bits_uop_ftqPtr_value;
      req_uop_ftqOffset <= io_req_bits_uop_ftqOffset;
      req_uop_satpFlushFirstFetchFault <= io_req_bits_uop_satpFlushFirstFetchFault;
      req_uop_srcType_0 <= io_req_bits_uop_srcType_0;
      req_uop_srcType_1 <= io_req_bits_uop_srcType_1;
      req_uop_srcType_2 <= io_req_bits_uop_srcType_2;
      req_uop_srcType_3 <= io_req_bits_uop_srcType_3;
      req_uop_srcType_4 <= io_req_bits_uop_srcType_4;
      req_uop_ldest <= io_req_bits_uop_ldest;
      req_uop_fuType <= io_req_bits_uop_fuType;
      req_uop_fuOpType <= io_req_bits_uop_fuOpType;
      req_uop_rfWen <= io_req_bits_uop_rfWen;
      req_uop_fpWen <= io_req_bits_uop_fpWen;
      req_uop_vecWen <= io_req_bits_uop_vecWen;
      req_uop_v0Wen <= io_req_bits_uop_v0Wen;
      req_uop_vlWen <= io_req_bits_uop_vlWen;
      req_uop_isXSTrap <= io_req_bits_uop_isXSTrap;
      req_uop_waitForward <= io_req_bits_uop_waitForward;
      req_uop_blockBackward <= io_req_bits_uop_blockBackward;
      req_uop_canRobCompress <= io_req_bits_uop_canRobCompress;
      req_uop_selImm <= io_req_bits_uop_selImm;
      req_uop_imm <= io_req_bits_uop_imm;
      req_uop_fpu_typeTagOut <= io_req_bits_uop_fpu_typeTagOut;
      req_uop_fpu_wflags <= io_req_bits_uop_fpu_wflags;
      req_uop_fpu_typ <= io_req_bits_uop_fpu_typ;
      req_uop_fpu_fmt <= io_req_bits_uop_fpu_fmt;
      req_uop_fpu_rm <= io_req_bits_uop_fpu_rm;
      req_uop_vpu_vill <= io_req_bits_uop_vpu_vill;
      req_uop_vpu_vma <= io_req_bits_uop_vpu_vma;
      req_uop_vpu_vta <= io_req_bits_uop_vpu_vta;
      req_uop_vpu_vsew <= io_req_bits_uop_vpu_vsew;
      req_uop_vpu_vlmul <= io_req_bits_uop_vpu_vlmul;
      req_uop_vpu_specVill <= io_req_bits_uop_vpu_specVill;
      req_uop_vpu_specVma <= io_req_bits_uop_vpu_specVma;
      req_uop_vpu_specVta <= io_req_bits_uop_vpu_specVta;
      req_uop_vpu_specVsew <= io_req_bits_uop_vpu_specVsew;
      req_uop_vpu_specVlmul <= io_req_bits_uop_vpu_specVlmul;
      req_uop_vpu_vm <= io_req_bits_uop_vpu_vm;
      req_uop_vpu_vstart <= io_req_bits_uop_vpu_vstart;
      req_uop_vpu_frm <= io_req_bits_uop_vpu_frm;
      req_uop_vpu_fpu_isFpToVecInst <= io_req_bits_uop_vpu_fpu_isFpToVecInst;
      req_uop_vpu_fpu_isFP32Instr <= io_req_bits_uop_vpu_fpu_isFP32Instr;
      req_uop_vpu_fpu_isFP64Instr <= io_req_bits_uop_vpu_fpu_isFP64Instr;
      req_uop_vpu_fpu_isReduction <= io_req_bits_uop_vpu_fpu_isReduction;
      req_uop_vpu_fpu_isFoldTo1_2 <= io_req_bits_uop_vpu_fpu_isFoldTo1_2;
      req_uop_vpu_fpu_isFoldTo1_4 <= io_req_bits_uop_vpu_fpu_isFoldTo1_4;
      req_uop_vpu_fpu_isFoldTo1_8 <= io_req_bits_uop_vpu_fpu_isFoldTo1_8;
      req_uop_vpu_vxrm <= io_req_bits_uop_vpu_vxrm;
      req_uop_vpu_vuopIdx <= io_req_bits_uop_vpu_vuopIdx;
      req_uop_vpu_lastUop <= io_req_bits_uop_vpu_lastUop;
      req_uop_vpu_vmask <= io_req_bits_uop_vpu_vmask;
      req_uop_vpu_vl <= io_req_bits_uop_vpu_vl;
      req_uop_vpu_nf <= io_req_bits_uop_vpu_nf;
      req_uop_vpu_veew <= io_req_bits_uop_vpu_veew;
      req_uop_vpu_isReverse <= io_req_bits_uop_vpu_isReverse;
      req_uop_vpu_isExt <= io_req_bits_uop_vpu_isExt;
      req_uop_vpu_isNarrow <= io_req_bits_uop_vpu_isNarrow;
      req_uop_vpu_isDstMask <= io_req_bits_uop_vpu_isDstMask;
      req_uop_vpu_isOpMask <= io_req_bits_uop_vpu_isOpMask;
      req_uop_vpu_isMove <= io_req_bits_uop_vpu_isMove;
      req_uop_vpu_isDependOldVd <= io_req_bits_uop_vpu_isDependOldVd;
      req_uop_vpu_isWritePartVd <= io_req_bits_uop_vpu_isWritePartVd;
      req_uop_vpu_isVleff <= io_req_bits_uop_vpu_isVleff;
      req_uop_vlsInstr <= io_req_bits_uop_vlsInstr;
      req_uop_wfflags <= io_req_bits_uop_wfflags;
      req_uop_isMove <= io_req_bits_uop_isMove;
      req_uop_isDropAmocasSta <= io_req_bits_uop_isDropAmocasSta;
      req_uop_uopIdx <= io_req_bits_uop_uopIdx;
      req_uop_isVset <= io_req_bits_uop_isVset;
      req_uop_firstUop <= io_req_bits_uop_firstUop;
      req_uop_lastUop <= io_req_bits_uop_lastUop;
      req_uop_numUops <= io_req_bits_uop_numUops;
      req_uop_numWB <= io_req_bits_uop_numWB;
      req_uop_commitType <= io_req_bits_uop_commitType;
      req_uop_srcState_0 <= io_req_bits_uop_srcState_0;
      req_uop_srcState_1 <= io_req_bits_uop_srcState_1;
      req_uop_srcState_2 <= io_req_bits_uop_srcState_2;
      req_uop_srcState_3 <= io_req_bits_uop_srcState_3;
      req_uop_srcState_4 <= io_req_bits_uop_srcState_4;
      req_uop_srcLoadDependency_0_0 <= io_req_bits_uop_srcLoadDependency_0_0;
      req_uop_srcLoadDependency_0_1 <= io_req_bits_uop_srcLoadDependency_0_1;
      req_uop_srcLoadDependency_0_2 <= io_req_bits_uop_srcLoadDependency_0_2;
      req_uop_srcLoadDependency_1_0 <= io_req_bits_uop_srcLoadDependency_1_0;
      req_uop_srcLoadDependency_1_1 <= io_req_bits_uop_srcLoadDependency_1_1;
      req_uop_srcLoadDependency_1_2 <= io_req_bits_uop_srcLoadDependency_1_2;
      req_uop_srcLoadDependency_2_0 <= io_req_bits_uop_srcLoadDependency_2_0;
      req_uop_srcLoadDependency_2_1 <= io_req_bits_uop_srcLoadDependency_2_1;
      req_uop_srcLoadDependency_2_2 <= io_req_bits_uop_srcLoadDependency_2_2;
      req_uop_srcLoadDependency_3_0 <= io_req_bits_uop_srcLoadDependency_3_0;
      req_uop_srcLoadDependency_3_1 <= io_req_bits_uop_srcLoadDependency_3_1;
      req_uop_srcLoadDependency_3_2 <= io_req_bits_uop_srcLoadDependency_3_2;
      req_uop_srcLoadDependency_4_0 <= io_req_bits_uop_srcLoadDependency_4_0;
      req_uop_srcLoadDependency_4_1 <= io_req_bits_uop_srcLoadDependency_4_1;
      req_uop_srcLoadDependency_4_2 <= io_req_bits_uop_srcLoadDependency_4_2;
      req_uop_psrc_0 <= io_req_bits_uop_psrc_0;
      req_uop_psrc_1 <= io_req_bits_uop_psrc_1;
      req_uop_psrc_2 <= io_req_bits_uop_psrc_2;
      req_uop_psrc_3 <= io_req_bits_uop_psrc_3;
      req_uop_psrc_4 <= io_req_bits_uop_psrc_4;
      req_uop_pdest <= io_req_bits_uop_pdest;
      req_uop_useRegCache_0 <= io_req_bits_uop_useRegCache_0;
      req_uop_useRegCache_1 <= io_req_bits_uop_useRegCache_1;
      req_uop_regCacheIdx_0 <= io_req_bits_uop_regCacheIdx_0;
      req_uop_regCacheIdx_1 <= io_req_bits_uop_regCacheIdx_1;
      req_uop_robIdx_flag <= io_req_bits_uop_robIdx_flag;
      req_uop_robIdx_value <= io_req_bits_uop_robIdx_value;
      req_uop_instrSize <= io_req_bits_uop_instrSize;
      req_uop_dirtyFs <= io_req_bits_uop_dirtyFs;
      req_uop_dirtyVs <= io_req_bits_uop_dirtyVs;
      req_uop_traceBlockInPipe_itype <= io_req_bits_uop_traceBlockInPipe_itype;
      req_uop_traceBlockInPipe_iretire <= io_req_bits_uop_traceBlockInPipe_iretire;
      req_uop_traceBlockInPipe_ilastsize <= io_req_bits_uop_traceBlockInPipe_ilastsize;
      req_uop_eliminatedMove <= io_req_bits_uop_eliminatedMove;
      req_uop_snapshot <= io_req_bits_uop_snapshot;
      req_uop_debugInfo_eliminatedMove <= io_req_bits_uop_debugInfo_eliminatedMove;
      req_uop_debugInfo_renameTime <= io_req_bits_uop_debugInfo_renameTime;
      req_uop_debugInfo_dispatchTime <= io_req_bits_uop_debugInfo_dispatchTime;
      req_uop_debugInfo_enqRsTime <= io_req_bits_uop_debugInfo_enqRsTime;
      req_uop_debugInfo_selectTime <= io_req_bits_uop_debugInfo_selectTime;
      req_uop_debugInfo_issueTime <= io_req_bits_uop_debugInfo_issueTime;
      req_uop_debugInfo_writebackTime <= io_req_bits_uop_debugInfo_writebackTime;
      req_uop_debugInfo_runahead_checkpoint_id <= io_req_bits_uop_debugInfo_runahead_checkpoint_id;
      req_uop_debugInfo_tlbFirstReqTime <= io_req_bits_uop_debugInfo_tlbFirstReqTime;
      req_uop_debugInfo_tlbRespTime <= io_req_bits_uop_debugInfo_tlbRespTime;
      req_uop_debug_seqNum_seqNum <= io_req_bits_uop_debug_seqNum_seqNum;
      req_uop_debug_seqNum_uopIdx <= io_req_bits_uop_debug_seqNum_uopIdx;
      req_uop_storeSetHit <= io_req_bits_uop_storeSetHit;
      req_uop_waitForRobIdx_flag <= io_req_bits_uop_waitForRobIdx_flag;
      req_uop_waitForRobIdx_value <= io_req_bits_uop_waitForRobIdx_value;
      req_uop_loadWaitBit <= io_req_bits_uop_loadWaitBit;
      req_uop_loadWaitStrict <= io_req_bits_uop_loadWaitStrict;
      req_uop_ssid <= io_req_bits_uop_ssid;
      req_uop_lqIdx_flag <= io_req_bits_uop_lqIdx_flag;
      req_uop_lqIdx_value <= io_req_bits_uop_lqIdx_value;
      req_uop_sqIdx_flag <= io_req_bits_uop_sqIdx_flag;
      req_uop_sqIdx_value <= io_req_bits_uop_sqIdx_value;
      req_uop_singleStep <= io_req_bits_uop_singleStep;
      req_uop_debug_fuType <= io_req_bits_uop_debug_fuType;
      req_uop_debug_sim_trig <= io_req_bits_uop_debug_sim_trig;
      req_uop_numLsElem <= io_req_bits_uop_numLsElem;
      req_vaddr <= io_req_bits_vaddr;
      req_fullva <= io_req_bits_fullva;
      req_paddr <= io_req_bits_paddr;
      req_gpaddr <= io_req_bits_gpaddr;
      req_mask <= io_req_bits_mask;
      req_nc <= io_req_bits_nc;
      req_mmio <= io_req_bits_mmio;
      req_memBackTypeMM <= io_req_bits_memBackTypeMM;
      req_isHyper <= io_req_bits_isHyper;
      req_isForVSnonLeafPTE <= io_req_bits_isForVSnonLeafPTE;
      req_isvec <= io_req_bits_isvec;
      req_is128bit <= io_req_bits_is128bit;
      req_vecActive <= io_req_bits_vecActive;
      req_schedIndex <= io_req_bits_schedIndex;
      // END GENERATED
    end

    // 这两位没有输入端口（父级恒 0）：写进来就是 0，之后再也起不来。照抄。
    req_uop_flushPipe  <= ~enq & req_uop_flushPipe;
    req_uop_replayInst <= ~enq & req_uop_replayInst;

    // 认领 idResp 记下 sid。收新请求的那一拍不认领（golden 的 elsewhen 次序）。
    if (~(flush | io_req_valid) & slave_ack)
      slave_id <= io_uncache_idResp_bits_sid;

    if (io_uncache_resp_valid)
      resp_data <= io_uncache_resp_bits_data;
  end

  // ---------------------------------------------------------------------------
  // 输出：mmioOut / ncOut / mmioRawData / uncache.req / exception
  //
  // 除下面这几根有真逻辑外，mmioOut / ncOut / exception 的 uop 字段全是把锁存的
  // req_* 原样吐出去（exceptionVec 第 5 / 19 位除外，见文件头）。
  // 整段由 gen.py 从 golden 的 404 条 assign 机械翻译（只换内部 wire 名），
  // 保证 401 个输出逐位对齐。
  // ---------------------------------------------------------------------------
  // BEGIN GENERATED(outputs)
  assign io_flush = flush;
  assign io_mmioSelect = (state != S_IDLE) & req_mmio;
  assign io_slaveId_valid = slave_accept;
  assign io_slaveId_bits = slave_id;
  assign io_mmioOut_valid = mmio_out_valid;
  assign io_mmioOut_bits_uop_instr = req_uop_instr;
  assign io_mmioOut_bits_uop_pc = req_uop_pc;
  assign io_mmioOut_bits_uop_foldpc = req_uop_foldpc;
  assign io_mmioOut_bits_uop_exceptionVec_0 = req_uop_exceptionVec_0;
  assign io_mmioOut_bits_uop_exceptionVec_1 = req_uop_exceptionVec_1;
  assign io_mmioOut_bits_uop_exceptionVec_2 = req_uop_exceptionVec_2;
  assign io_mmioOut_bits_uop_exceptionVec_3 = req_uop_exceptionVec_3;
  assign io_mmioOut_bits_uop_exceptionVec_4 = req_uop_exceptionVec_4;
  assign io_mmioOut_bits_uop_exceptionVec_5 = denied;
  assign io_mmioOut_bits_uop_exceptionVec_6 = req_uop_exceptionVec_6;
  assign io_mmioOut_bits_uop_exceptionVec_7 = req_uop_exceptionVec_7;
  assign io_mmioOut_bits_uop_exceptionVec_8 = req_uop_exceptionVec_8;
  assign io_mmioOut_bits_uop_exceptionVec_9 = req_uop_exceptionVec_9;
  assign io_mmioOut_bits_uop_exceptionVec_10 = req_uop_exceptionVec_10;
  assign io_mmioOut_bits_uop_exceptionVec_11 = req_uop_exceptionVec_11;
  assign io_mmioOut_bits_uop_exceptionVec_12 = req_uop_exceptionVec_12;
  assign io_mmioOut_bits_uop_exceptionVec_13 = req_uop_exceptionVec_13;
  assign io_mmioOut_bits_uop_exceptionVec_14 = req_uop_exceptionVec_14;
  assign io_mmioOut_bits_uop_exceptionVec_15 = req_uop_exceptionVec_15;
  assign io_mmioOut_bits_uop_exceptionVec_16 = req_uop_exceptionVec_16;
  assign io_mmioOut_bits_uop_exceptionVec_17 = req_uop_exceptionVec_17;
  assign io_mmioOut_bits_uop_exceptionVec_18 = req_uop_exceptionVec_18;
  assign io_mmioOut_bits_uop_exceptionVec_19 = corrupt & ~denied;
  assign io_mmioOut_bits_uop_exceptionVec_20 = req_uop_exceptionVec_20;
  assign io_mmioOut_bits_uop_exceptionVec_21 = req_uop_exceptionVec_21;
  assign io_mmioOut_bits_uop_exceptionVec_22 = req_uop_exceptionVec_22;
  assign io_mmioOut_bits_uop_exceptionVec_23 = req_uop_exceptionVec_23;
  assign io_mmioOut_bits_uop_isFetchMalAddr = req_uop_isFetchMalAddr;
  assign io_mmioOut_bits_uop_hasException = req_uop_hasException;
  assign io_mmioOut_bits_uop_trigger = req_uop_trigger;
  assign io_mmioOut_bits_uop_preDecodeInfo_valid = req_uop_preDecodeInfo_valid;
  assign io_mmioOut_bits_uop_preDecodeInfo_isRVC = req_uop_preDecodeInfo_isRVC;
  assign io_mmioOut_bits_uop_preDecodeInfo_brType = req_uop_preDecodeInfo_brType;
  assign io_mmioOut_bits_uop_preDecodeInfo_isCall = req_uop_preDecodeInfo_isCall;
  assign io_mmioOut_bits_uop_preDecodeInfo_isRet = req_uop_preDecodeInfo_isRet;
  assign io_mmioOut_bits_uop_pred_taken = req_uop_pred_taken;
  assign io_mmioOut_bits_uop_crossPageIPFFix = req_uop_crossPageIPFFix;
  assign io_mmioOut_bits_uop_ftqPtr_flag = req_uop_ftqPtr_flag;
  assign io_mmioOut_bits_uop_ftqPtr_value = req_uop_ftqPtr_value;
  assign io_mmioOut_bits_uop_ftqOffset = req_uop_ftqOffset;
  assign io_mmioOut_bits_uop_satpFlushFirstFetchFault = req_uop_satpFlushFirstFetchFault;
  assign io_mmioOut_bits_uop_srcType_0 = req_uop_srcType_0;
  assign io_mmioOut_bits_uop_srcType_1 = req_uop_srcType_1;
  assign io_mmioOut_bits_uop_srcType_2 = req_uop_srcType_2;
  assign io_mmioOut_bits_uop_srcType_3 = req_uop_srcType_3;
  assign io_mmioOut_bits_uop_srcType_4 = req_uop_srcType_4;
  assign io_mmioOut_bits_uop_ldest = req_uop_ldest;
  assign io_mmioOut_bits_uop_fuType = req_uop_fuType;
  assign io_mmioOut_bits_uop_fuOpType = req_uop_fuOpType;
  assign io_mmioOut_bits_uop_rfWen = req_uop_rfWen;
  assign io_mmioOut_bits_uop_fpWen = req_uop_fpWen;
  assign io_mmioOut_bits_uop_vecWen = req_uop_vecWen;
  assign io_mmioOut_bits_uop_v0Wen = req_uop_v0Wen;
  assign io_mmioOut_bits_uop_vlWen = req_uop_vlWen;
  assign io_mmioOut_bits_uop_isXSTrap = req_uop_isXSTrap;
  assign io_mmioOut_bits_uop_waitForward = req_uop_waitForward;
  assign io_mmioOut_bits_uop_blockBackward = req_uop_blockBackward;
  assign io_mmioOut_bits_uop_flushPipe = req_uop_flushPipe;
  assign io_mmioOut_bits_uop_canRobCompress = req_uop_canRobCompress;
  assign io_mmioOut_bits_uop_selImm = req_uop_selImm;
  assign io_mmioOut_bits_uop_imm = req_uop_imm;
  assign io_mmioOut_bits_uop_fpu_typeTagOut = req_uop_fpu_typeTagOut;
  assign io_mmioOut_bits_uop_fpu_wflags = req_uop_fpu_wflags;
  assign io_mmioOut_bits_uop_fpu_typ = req_uop_fpu_typ;
  assign io_mmioOut_bits_uop_fpu_fmt = req_uop_fpu_fmt;
  assign io_mmioOut_bits_uop_fpu_rm = req_uop_fpu_rm;
  assign io_mmioOut_bits_uop_vpu_vill = req_uop_vpu_vill;
  assign io_mmioOut_bits_uop_vpu_vma = req_uop_vpu_vma;
  assign io_mmioOut_bits_uop_vpu_vta = req_uop_vpu_vta;
  assign io_mmioOut_bits_uop_vpu_vsew = req_uop_vpu_vsew;
  assign io_mmioOut_bits_uop_vpu_vlmul = req_uop_vpu_vlmul;
  assign io_mmioOut_bits_uop_vpu_specVill = req_uop_vpu_specVill;
  assign io_mmioOut_bits_uop_vpu_specVma = req_uop_vpu_specVma;
  assign io_mmioOut_bits_uop_vpu_specVta = req_uop_vpu_specVta;
  assign io_mmioOut_bits_uop_vpu_specVsew = req_uop_vpu_specVsew;
  assign io_mmioOut_bits_uop_vpu_specVlmul = req_uop_vpu_specVlmul;
  assign io_mmioOut_bits_uop_vpu_vm = req_uop_vpu_vm;
  assign io_mmioOut_bits_uop_vpu_vstart = req_uop_vpu_vstart;
  assign io_mmioOut_bits_uop_vpu_frm = req_uop_vpu_frm;
  assign io_mmioOut_bits_uop_vpu_fpu_isFpToVecInst = req_uop_vpu_fpu_isFpToVecInst;
  assign io_mmioOut_bits_uop_vpu_fpu_isFP32Instr = req_uop_vpu_fpu_isFP32Instr;
  assign io_mmioOut_bits_uop_vpu_fpu_isFP64Instr = req_uop_vpu_fpu_isFP64Instr;
  assign io_mmioOut_bits_uop_vpu_fpu_isReduction = req_uop_vpu_fpu_isReduction;
  assign io_mmioOut_bits_uop_vpu_fpu_isFoldTo1_2 = req_uop_vpu_fpu_isFoldTo1_2;
  assign io_mmioOut_bits_uop_vpu_fpu_isFoldTo1_4 = req_uop_vpu_fpu_isFoldTo1_4;
  assign io_mmioOut_bits_uop_vpu_fpu_isFoldTo1_8 = req_uop_vpu_fpu_isFoldTo1_8;
  assign io_mmioOut_bits_uop_vpu_vxrm = req_uop_vpu_vxrm;
  assign io_mmioOut_bits_uop_vpu_vuopIdx = req_uop_vpu_vuopIdx;
  assign io_mmioOut_bits_uop_vpu_lastUop = req_uop_vpu_lastUop;
  assign io_mmioOut_bits_uop_vpu_vmask = req_uop_vpu_vmask;
  assign io_mmioOut_bits_uop_vpu_vl = req_uop_vpu_vl;
  assign io_mmioOut_bits_uop_vpu_nf = req_uop_vpu_nf;
  assign io_mmioOut_bits_uop_vpu_veew = req_uop_vpu_veew;
  assign io_mmioOut_bits_uop_vpu_isReverse = req_uop_vpu_isReverse;
  assign io_mmioOut_bits_uop_vpu_isExt = req_uop_vpu_isExt;
  assign io_mmioOut_bits_uop_vpu_isNarrow = req_uop_vpu_isNarrow;
  assign io_mmioOut_bits_uop_vpu_isDstMask = req_uop_vpu_isDstMask;
  assign io_mmioOut_bits_uop_vpu_isOpMask = req_uop_vpu_isOpMask;
  assign io_mmioOut_bits_uop_vpu_isMove = req_uop_vpu_isMove;
  assign io_mmioOut_bits_uop_vpu_isDependOldVd = req_uop_vpu_isDependOldVd;
  assign io_mmioOut_bits_uop_vpu_isWritePartVd = req_uop_vpu_isWritePartVd;
  assign io_mmioOut_bits_uop_vpu_isVleff = req_uop_vpu_isVleff;
  assign io_mmioOut_bits_uop_vlsInstr = req_uop_vlsInstr;
  assign io_mmioOut_bits_uop_wfflags = req_uop_wfflags;
  assign io_mmioOut_bits_uop_isMove = req_uop_isMove;
  assign io_mmioOut_bits_uop_isDropAmocasSta = req_uop_isDropAmocasSta;
  assign io_mmioOut_bits_uop_uopIdx = req_uop_uopIdx;
  assign io_mmioOut_bits_uop_isVset = req_uop_isVset;
  assign io_mmioOut_bits_uop_firstUop = req_uop_firstUop;
  assign io_mmioOut_bits_uop_lastUop = req_uop_lastUop;
  assign io_mmioOut_bits_uop_numUops = req_uop_numUops;
  assign io_mmioOut_bits_uop_numWB = req_uop_numWB;
  assign io_mmioOut_bits_uop_commitType = req_uop_commitType;
  assign io_mmioOut_bits_uop_srcState_0 = req_uop_srcState_0;
  assign io_mmioOut_bits_uop_srcState_1 = req_uop_srcState_1;
  assign io_mmioOut_bits_uop_srcState_2 = req_uop_srcState_2;
  assign io_mmioOut_bits_uop_srcState_3 = req_uop_srcState_3;
  assign io_mmioOut_bits_uop_srcState_4 = req_uop_srcState_4;
  assign io_mmioOut_bits_uop_srcLoadDependency_0_0 = req_uop_srcLoadDependency_0_0;
  assign io_mmioOut_bits_uop_srcLoadDependency_0_1 = req_uop_srcLoadDependency_0_1;
  assign io_mmioOut_bits_uop_srcLoadDependency_0_2 = req_uop_srcLoadDependency_0_2;
  assign io_mmioOut_bits_uop_srcLoadDependency_1_0 = req_uop_srcLoadDependency_1_0;
  assign io_mmioOut_bits_uop_srcLoadDependency_1_1 = req_uop_srcLoadDependency_1_1;
  assign io_mmioOut_bits_uop_srcLoadDependency_1_2 = req_uop_srcLoadDependency_1_2;
  assign io_mmioOut_bits_uop_srcLoadDependency_2_0 = req_uop_srcLoadDependency_2_0;
  assign io_mmioOut_bits_uop_srcLoadDependency_2_1 = req_uop_srcLoadDependency_2_1;
  assign io_mmioOut_bits_uop_srcLoadDependency_2_2 = req_uop_srcLoadDependency_2_2;
  assign io_mmioOut_bits_uop_srcLoadDependency_3_0 = req_uop_srcLoadDependency_3_0;
  assign io_mmioOut_bits_uop_srcLoadDependency_3_1 = req_uop_srcLoadDependency_3_1;
  assign io_mmioOut_bits_uop_srcLoadDependency_3_2 = req_uop_srcLoadDependency_3_2;
  assign io_mmioOut_bits_uop_srcLoadDependency_4_0 = req_uop_srcLoadDependency_4_0;
  assign io_mmioOut_bits_uop_srcLoadDependency_4_1 = req_uop_srcLoadDependency_4_1;
  assign io_mmioOut_bits_uop_srcLoadDependency_4_2 = req_uop_srcLoadDependency_4_2;
  assign io_mmioOut_bits_uop_psrc_0 = req_uop_psrc_0;
  assign io_mmioOut_bits_uop_psrc_1 = req_uop_psrc_1;
  assign io_mmioOut_bits_uop_psrc_2 = req_uop_psrc_2;
  assign io_mmioOut_bits_uop_psrc_3 = req_uop_psrc_3;
  assign io_mmioOut_bits_uop_psrc_4 = req_uop_psrc_4;
  assign io_mmioOut_bits_uop_pdest = req_uop_pdest;
  assign io_mmioOut_bits_uop_useRegCache_0 = req_uop_useRegCache_0;
  assign io_mmioOut_bits_uop_useRegCache_1 = req_uop_useRegCache_1;
  assign io_mmioOut_bits_uop_regCacheIdx_0 = req_uop_regCacheIdx_0;
  assign io_mmioOut_bits_uop_regCacheIdx_1 = req_uop_regCacheIdx_1;
  assign io_mmioOut_bits_uop_robIdx_flag = req_uop_robIdx_flag;
  assign io_mmioOut_bits_uop_robIdx_value = req_uop_robIdx_value;
  assign io_mmioOut_bits_uop_instrSize = req_uop_instrSize;
  assign io_mmioOut_bits_uop_dirtyFs = req_uop_dirtyFs;
  assign io_mmioOut_bits_uop_dirtyVs = req_uop_dirtyVs;
  assign io_mmioOut_bits_uop_traceBlockInPipe_itype = req_uop_traceBlockInPipe_itype;
  assign io_mmioOut_bits_uop_traceBlockInPipe_iretire = req_uop_traceBlockInPipe_iretire;
  assign io_mmioOut_bits_uop_traceBlockInPipe_ilastsize = req_uop_traceBlockInPipe_ilastsize;
  assign io_mmioOut_bits_uop_eliminatedMove = req_uop_eliminatedMove;
  assign io_mmioOut_bits_uop_snapshot = req_uop_snapshot;
  assign io_mmioOut_bits_uop_debugInfo_eliminatedMove = req_uop_debugInfo_eliminatedMove;
  assign io_mmioOut_bits_uop_debugInfo_renameTime = req_uop_debugInfo_renameTime;
  assign io_mmioOut_bits_uop_debugInfo_dispatchTime = req_uop_debugInfo_dispatchTime;
  assign io_mmioOut_bits_uop_debugInfo_enqRsTime = req_uop_debugInfo_enqRsTime;
  assign io_mmioOut_bits_uop_debugInfo_selectTime = req_uop_debugInfo_selectTime;
  assign io_mmioOut_bits_uop_debugInfo_issueTime = req_uop_debugInfo_issueTime;
  assign io_mmioOut_bits_uop_debugInfo_writebackTime = req_uop_debugInfo_writebackTime;
  assign io_mmioOut_bits_uop_debugInfo_runahead_checkpoint_id = req_uop_debugInfo_runahead_checkpoint_id;
  assign io_mmioOut_bits_uop_debugInfo_tlbFirstReqTime = req_uop_debugInfo_tlbFirstReqTime;
  assign io_mmioOut_bits_uop_debugInfo_tlbRespTime = req_uop_debugInfo_tlbRespTime;
  assign io_mmioOut_bits_uop_debug_seqNum_seqNum = req_uop_debug_seqNum_seqNum;
  assign io_mmioOut_bits_uop_debug_seqNum_uopIdx = req_uop_debug_seqNum_uopIdx;
  assign io_mmioOut_bits_uop_storeSetHit = req_uop_storeSetHit;
  assign io_mmioOut_bits_uop_waitForRobIdx_flag = req_uop_waitForRobIdx_flag;
  assign io_mmioOut_bits_uop_waitForRobIdx_value = req_uop_waitForRobIdx_value;
  assign io_mmioOut_bits_uop_loadWaitBit = req_uop_loadWaitBit;
  assign io_mmioOut_bits_uop_loadWaitStrict = req_uop_loadWaitStrict;
  assign io_mmioOut_bits_uop_ssid = req_uop_ssid;
  assign io_mmioOut_bits_uop_lqIdx_flag = req_uop_lqIdx_flag;
  assign io_mmioOut_bits_uop_lqIdx_value = req_uop_lqIdx_value;
  assign io_mmioOut_bits_uop_sqIdx_flag = req_uop_sqIdx_flag;
  assign io_mmioOut_bits_uop_sqIdx_value = req_uop_sqIdx_value;
  assign io_mmioOut_bits_uop_singleStep = req_uop_singleStep;
  assign io_mmioOut_bits_uop_replayInst = req_uop_replayInst;
  assign io_mmioOut_bits_uop_debug_fuType = req_uop_debug_fuType;
  assign io_mmioOut_bits_uop_debug_sim_trig = req_uop_debug_sim_trig;
  assign io_mmioOut_bits_uop_numLsElem = req_uop_numLsElem;
  assign io_mmioOut_bits_debug_paddr = req_paddr;
  assign io_mmioOut_bits_debug_vaddr = req_vaddr;
  assign io_mmioRawData_lqData = resp_data;
  assign io_mmioRawData_uop_fuOpType = req_uop_fuOpType;
  assign io_mmioRawData_uop_fpWen = req_uop_fpWen;
  assign io_mmioRawData_addrOffset = req_paddr[2:0];
  assign io_ncOut_valid = nc_out_valid;
  assign io_ncOut_bits_uop_instr = req_uop_instr;
  assign io_ncOut_bits_uop_pc = req_uop_pc;
  assign io_ncOut_bits_uop_foldpc = req_uop_foldpc;
  assign io_ncOut_bits_uop_exceptionVec_0 = req_uop_exceptionVec_0;
  assign io_ncOut_bits_uop_exceptionVec_1 = req_uop_exceptionVec_1;
  assign io_ncOut_bits_uop_exceptionVec_2 = req_uop_exceptionVec_2;
  assign io_ncOut_bits_uop_exceptionVec_3 = req_uop_exceptionVec_3;
  assign io_ncOut_bits_uop_exceptionVec_4 = req_uop_exceptionVec_4;
  assign io_ncOut_bits_uop_exceptionVec_5 = denied;
  assign io_ncOut_bits_uop_exceptionVec_6 = req_uop_exceptionVec_6;
  assign io_ncOut_bits_uop_exceptionVec_7 = req_uop_exceptionVec_7;
  assign io_ncOut_bits_uop_exceptionVec_8 = req_uop_exceptionVec_8;
  assign io_ncOut_bits_uop_exceptionVec_9 = req_uop_exceptionVec_9;
  assign io_ncOut_bits_uop_exceptionVec_10 = req_uop_exceptionVec_10;
  assign io_ncOut_bits_uop_exceptionVec_11 = req_uop_exceptionVec_11;
  assign io_ncOut_bits_uop_exceptionVec_12 = req_uop_exceptionVec_12;
  assign io_ncOut_bits_uop_exceptionVec_13 = req_uop_exceptionVec_13;
  assign io_ncOut_bits_uop_exceptionVec_14 = req_uop_exceptionVec_14;
  assign io_ncOut_bits_uop_exceptionVec_15 = req_uop_exceptionVec_15;
  assign io_ncOut_bits_uop_exceptionVec_16 = req_uop_exceptionVec_16;
  assign io_ncOut_bits_uop_exceptionVec_17 = req_uop_exceptionVec_17;
  assign io_ncOut_bits_uop_exceptionVec_18 = req_uop_exceptionVec_18;
  assign io_ncOut_bits_uop_exceptionVec_19 = corrupt & ~denied;
  assign io_ncOut_bits_uop_exceptionVec_20 = req_uop_exceptionVec_20;
  assign io_ncOut_bits_uop_exceptionVec_21 = req_uop_exceptionVec_21;
  assign io_ncOut_bits_uop_exceptionVec_22 = req_uop_exceptionVec_22;
  assign io_ncOut_bits_uop_exceptionVec_23 = req_uop_exceptionVec_23;
  assign io_ncOut_bits_uop_isFetchMalAddr = req_uop_isFetchMalAddr;
  assign io_ncOut_bits_uop_hasException = req_uop_hasException;
  assign io_ncOut_bits_uop_trigger = req_uop_trigger;
  assign io_ncOut_bits_uop_preDecodeInfo_valid = req_uop_preDecodeInfo_valid;
  assign io_ncOut_bits_uop_preDecodeInfo_isRVC = req_uop_preDecodeInfo_isRVC;
  assign io_ncOut_bits_uop_preDecodeInfo_brType = req_uop_preDecodeInfo_brType;
  assign io_ncOut_bits_uop_preDecodeInfo_isCall = req_uop_preDecodeInfo_isCall;
  assign io_ncOut_bits_uop_preDecodeInfo_isRet = req_uop_preDecodeInfo_isRet;
  assign io_ncOut_bits_uop_pred_taken = req_uop_pred_taken;
  assign io_ncOut_bits_uop_crossPageIPFFix = req_uop_crossPageIPFFix;
  assign io_ncOut_bits_uop_ftqPtr_flag = req_uop_ftqPtr_flag;
  assign io_ncOut_bits_uop_ftqPtr_value = req_uop_ftqPtr_value;
  assign io_ncOut_bits_uop_ftqOffset = req_uop_ftqOffset;
  assign io_ncOut_bits_uop_satpFlushFirstFetchFault = req_uop_satpFlushFirstFetchFault;
  assign io_ncOut_bits_uop_srcType_0 = req_uop_srcType_0;
  assign io_ncOut_bits_uop_srcType_1 = req_uop_srcType_1;
  assign io_ncOut_bits_uop_srcType_2 = req_uop_srcType_2;
  assign io_ncOut_bits_uop_srcType_3 = req_uop_srcType_3;
  assign io_ncOut_bits_uop_srcType_4 = req_uop_srcType_4;
  assign io_ncOut_bits_uop_ldest = req_uop_ldest;
  assign io_ncOut_bits_uop_fuType = req_uop_fuType;
  assign io_ncOut_bits_uop_fuOpType = req_uop_fuOpType;
  assign io_ncOut_bits_uop_rfWen = req_uop_rfWen;
  assign io_ncOut_bits_uop_fpWen = req_uop_fpWen;
  assign io_ncOut_bits_uop_vecWen = req_uop_vecWen;
  assign io_ncOut_bits_uop_v0Wen = req_uop_v0Wen;
  assign io_ncOut_bits_uop_vlWen = req_uop_vlWen;
  assign io_ncOut_bits_uop_isXSTrap = req_uop_isXSTrap;
  assign io_ncOut_bits_uop_waitForward = req_uop_waitForward;
  assign io_ncOut_bits_uop_blockBackward = req_uop_blockBackward;
  assign io_ncOut_bits_uop_flushPipe = req_uop_flushPipe;
  assign io_ncOut_bits_uop_canRobCompress = req_uop_canRobCompress;
  assign io_ncOut_bits_uop_selImm = req_uop_selImm;
  assign io_ncOut_bits_uop_imm = req_uop_imm;
  assign io_ncOut_bits_uop_fpu_typeTagOut = req_uop_fpu_typeTagOut;
  assign io_ncOut_bits_uop_fpu_wflags = req_uop_fpu_wflags;
  assign io_ncOut_bits_uop_fpu_typ = req_uop_fpu_typ;
  assign io_ncOut_bits_uop_fpu_fmt = req_uop_fpu_fmt;
  assign io_ncOut_bits_uop_fpu_rm = req_uop_fpu_rm;
  assign io_ncOut_bits_uop_vpu_vill = req_uop_vpu_vill;
  assign io_ncOut_bits_uop_vpu_vma = req_uop_vpu_vma;
  assign io_ncOut_bits_uop_vpu_vta = req_uop_vpu_vta;
  assign io_ncOut_bits_uop_vpu_vsew = req_uop_vpu_vsew;
  assign io_ncOut_bits_uop_vpu_vlmul = req_uop_vpu_vlmul;
  assign io_ncOut_bits_uop_vpu_specVill = req_uop_vpu_specVill;
  assign io_ncOut_bits_uop_vpu_specVma = req_uop_vpu_specVma;
  assign io_ncOut_bits_uop_vpu_specVta = req_uop_vpu_specVta;
  assign io_ncOut_bits_uop_vpu_specVsew = req_uop_vpu_specVsew;
  assign io_ncOut_bits_uop_vpu_specVlmul = req_uop_vpu_specVlmul;
  assign io_ncOut_bits_uop_vpu_vm = req_uop_vpu_vm;
  assign io_ncOut_bits_uop_vpu_vstart = req_uop_vpu_vstart;
  assign io_ncOut_bits_uop_vpu_frm = req_uop_vpu_frm;
  assign io_ncOut_bits_uop_vpu_fpu_isFpToVecInst = req_uop_vpu_fpu_isFpToVecInst;
  assign io_ncOut_bits_uop_vpu_fpu_isFP32Instr = req_uop_vpu_fpu_isFP32Instr;
  assign io_ncOut_bits_uop_vpu_fpu_isFP64Instr = req_uop_vpu_fpu_isFP64Instr;
  assign io_ncOut_bits_uop_vpu_fpu_isReduction = req_uop_vpu_fpu_isReduction;
  assign io_ncOut_bits_uop_vpu_fpu_isFoldTo1_2 = req_uop_vpu_fpu_isFoldTo1_2;
  assign io_ncOut_bits_uop_vpu_fpu_isFoldTo1_4 = req_uop_vpu_fpu_isFoldTo1_4;
  assign io_ncOut_bits_uop_vpu_fpu_isFoldTo1_8 = req_uop_vpu_fpu_isFoldTo1_8;
  assign io_ncOut_bits_uop_vpu_vxrm = req_uop_vpu_vxrm;
  assign io_ncOut_bits_uop_vpu_vuopIdx = req_uop_vpu_vuopIdx;
  assign io_ncOut_bits_uop_vpu_lastUop = req_uop_vpu_lastUop;
  assign io_ncOut_bits_uop_vpu_vmask = req_uop_vpu_vmask;
  assign io_ncOut_bits_uop_vpu_vl = req_uop_vpu_vl;
  assign io_ncOut_bits_uop_vpu_nf = req_uop_vpu_nf;
  assign io_ncOut_bits_uop_vpu_veew = req_uop_vpu_veew;
  assign io_ncOut_bits_uop_vpu_isReverse = req_uop_vpu_isReverse;
  assign io_ncOut_bits_uop_vpu_isExt = req_uop_vpu_isExt;
  assign io_ncOut_bits_uop_vpu_isNarrow = req_uop_vpu_isNarrow;
  assign io_ncOut_bits_uop_vpu_isDstMask = req_uop_vpu_isDstMask;
  assign io_ncOut_bits_uop_vpu_isOpMask = req_uop_vpu_isOpMask;
  assign io_ncOut_bits_uop_vpu_isMove = req_uop_vpu_isMove;
  assign io_ncOut_bits_uop_vpu_isDependOldVd = req_uop_vpu_isDependOldVd;
  assign io_ncOut_bits_uop_vpu_isWritePartVd = req_uop_vpu_isWritePartVd;
  assign io_ncOut_bits_uop_vpu_isVleff = req_uop_vpu_isVleff;
  assign io_ncOut_bits_uop_vlsInstr = req_uop_vlsInstr;
  assign io_ncOut_bits_uop_wfflags = req_uop_wfflags;
  assign io_ncOut_bits_uop_isMove = req_uop_isMove;
  assign io_ncOut_bits_uop_isDropAmocasSta = req_uop_isDropAmocasSta;
  assign io_ncOut_bits_uop_uopIdx = req_uop_uopIdx;
  assign io_ncOut_bits_uop_isVset = req_uop_isVset;
  assign io_ncOut_bits_uop_firstUop = req_uop_firstUop;
  assign io_ncOut_bits_uop_lastUop = req_uop_lastUop;
  assign io_ncOut_bits_uop_numUops = req_uop_numUops;
  assign io_ncOut_bits_uop_numWB = req_uop_numWB;
  assign io_ncOut_bits_uop_commitType = req_uop_commitType;
  assign io_ncOut_bits_uop_srcState_0 = req_uop_srcState_0;
  assign io_ncOut_bits_uop_srcState_1 = req_uop_srcState_1;
  assign io_ncOut_bits_uop_srcState_2 = req_uop_srcState_2;
  assign io_ncOut_bits_uop_srcState_3 = req_uop_srcState_3;
  assign io_ncOut_bits_uop_srcState_4 = req_uop_srcState_4;
  assign io_ncOut_bits_uop_srcLoadDependency_0_0 = req_uop_srcLoadDependency_0_0;
  assign io_ncOut_bits_uop_srcLoadDependency_0_1 = req_uop_srcLoadDependency_0_1;
  assign io_ncOut_bits_uop_srcLoadDependency_0_2 = req_uop_srcLoadDependency_0_2;
  assign io_ncOut_bits_uop_srcLoadDependency_1_0 = req_uop_srcLoadDependency_1_0;
  assign io_ncOut_bits_uop_srcLoadDependency_1_1 = req_uop_srcLoadDependency_1_1;
  assign io_ncOut_bits_uop_srcLoadDependency_1_2 = req_uop_srcLoadDependency_1_2;
  assign io_ncOut_bits_uop_srcLoadDependency_2_0 = req_uop_srcLoadDependency_2_0;
  assign io_ncOut_bits_uop_srcLoadDependency_2_1 = req_uop_srcLoadDependency_2_1;
  assign io_ncOut_bits_uop_srcLoadDependency_2_2 = req_uop_srcLoadDependency_2_2;
  assign io_ncOut_bits_uop_srcLoadDependency_3_0 = req_uop_srcLoadDependency_3_0;
  assign io_ncOut_bits_uop_srcLoadDependency_3_1 = req_uop_srcLoadDependency_3_1;
  assign io_ncOut_bits_uop_srcLoadDependency_3_2 = req_uop_srcLoadDependency_3_2;
  assign io_ncOut_bits_uop_srcLoadDependency_4_0 = req_uop_srcLoadDependency_4_0;
  assign io_ncOut_bits_uop_srcLoadDependency_4_1 = req_uop_srcLoadDependency_4_1;
  assign io_ncOut_bits_uop_srcLoadDependency_4_2 = req_uop_srcLoadDependency_4_2;
  assign io_ncOut_bits_uop_psrc_0 = req_uop_psrc_0;
  assign io_ncOut_bits_uop_psrc_1 = req_uop_psrc_1;
  assign io_ncOut_bits_uop_psrc_2 = req_uop_psrc_2;
  assign io_ncOut_bits_uop_psrc_3 = req_uop_psrc_3;
  assign io_ncOut_bits_uop_psrc_4 = req_uop_psrc_4;
  assign io_ncOut_bits_uop_pdest = req_uop_pdest;
  assign io_ncOut_bits_uop_useRegCache_0 = req_uop_useRegCache_0;
  assign io_ncOut_bits_uop_useRegCache_1 = req_uop_useRegCache_1;
  assign io_ncOut_bits_uop_regCacheIdx_0 = req_uop_regCacheIdx_0;
  assign io_ncOut_bits_uop_regCacheIdx_1 = req_uop_regCacheIdx_1;
  assign io_ncOut_bits_uop_robIdx_flag = req_uop_robIdx_flag;
  assign io_ncOut_bits_uop_robIdx_value = req_uop_robIdx_value;
  assign io_ncOut_bits_uop_instrSize = req_uop_instrSize;
  assign io_ncOut_bits_uop_dirtyFs = req_uop_dirtyFs;
  assign io_ncOut_bits_uop_dirtyVs = req_uop_dirtyVs;
  assign io_ncOut_bits_uop_traceBlockInPipe_itype = req_uop_traceBlockInPipe_itype;
  assign io_ncOut_bits_uop_traceBlockInPipe_iretire = req_uop_traceBlockInPipe_iretire;
  assign io_ncOut_bits_uop_traceBlockInPipe_ilastsize = req_uop_traceBlockInPipe_ilastsize;
  assign io_ncOut_bits_uop_eliminatedMove = req_uop_eliminatedMove;
  assign io_ncOut_bits_uop_snapshot = req_uop_snapshot;
  assign io_ncOut_bits_uop_debugInfo_eliminatedMove = req_uop_debugInfo_eliminatedMove;
  assign io_ncOut_bits_uop_debugInfo_renameTime = req_uop_debugInfo_renameTime;
  assign io_ncOut_bits_uop_debugInfo_dispatchTime = req_uop_debugInfo_dispatchTime;
  assign io_ncOut_bits_uop_debugInfo_enqRsTime = req_uop_debugInfo_enqRsTime;
  assign io_ncOut_bits_uop_debugInfo_selectTime = req_uop_debugInfo_selectTime;
  assign io_ncOut_bits_uop_debugInfo_issueTime = req_uop_debugInfo_issueTime;
  assign io_ncOut_bits_uop_debugInfo_writebackTime = req_uop_debugInfo_writebackTime;
  assign io_ncOut_bits_uop_debugInfo_runahead_checkpoint_id = req_uop_debugInfo_runahead_checkpoint_id;
  assign io_ncOut_bits_uop_debugInfo_tlbFirstReqTime = req_uop_debugInfo_tlbFirstReqTime;
  assign io_ncOut_bits_uop_debugInfo_tlbRespTime = req_uop_debugInfo_tlbRespTime;
  assign io_ncOut_bits_uop_debug_seqNum_seqNum = req_uop_debug_seqNum_seqNum;
  assign io_ncOut_bits_uop_debug_seqNum_uopIdx = req_uop_debug_seqNum_uopIdx;
  assign io_ncOut_bits_uop_storeSetHit = req_uop_storeSetHit;
  assign io_ncOut_bits_uop_waitForRobIdx_flag = req_uop_waitForRobIdx_flag;
  assign io_ncOut_bits_uop_waitForRobIdx_value = req_uop_waitForRobIdx_value;
  assign io_ncOut_bits_uop_loadWaitBit = req_uop_loadWaitBit;
  assign io_ncOut_bits_uop_loadWaitStrict = req_uop_loadWaitStrict;
  assign io_ncOut_bits_uop_ssid = req_uop_ssid;
  assign io_ncOut_bits_uop_lqIdx_flag = req_uop_lqIdx_flag;
  assign io_ncOut_bits_uop_lqIdx_value = req_uop_lqIdx_value;
  assign io_ncOut_bits_uop_sqIdx_flag = req_uop_sqIdx_flag;
  assign io_ncOut_bits_uop_sqIdx_value = req_uop_sqIdx_value;
  assign io_ncOut_bits_uop_singleStep = req_uop_singleStep;
  assign io_ncOut_bits_uop_replayInst = req_uop_replayInst;
  assign io_ncOut_bits_uop_debug_fuType = req_uop_debug_fuType;
  assign io_ncOut_bits_uop_debug_sim_trig = req_uop_debug_sim_trig;
  assign io_ncOut_bits_uop_numLsElem = req_uop_numLsElem;
  assign io_ncOut_bits_vaddr = req_vaddr;
  assign io_ncOut_bits_paddr = req_paddr;
  assign io_ncOut_bits_data = {65'h0, resp_data};
  assign io_ncOut_bits_isvec = req_isvec;
  assign io_ncOut_bits_is128bit = req_is128bit;
  assign io_ncOut_bits_vecActive = req_vecActive;
  assign io_ncOut_bits_schedIndex = req_schedIndex;
  assign io_uncache_req_valid = uncache_req_valid;
  assign io_uncache_req_bits_robIdx_flag = req_uop_robIdx_flag;
  assign io_uncache_req_bits_robIdx_value = req_uop_robIdx_value;
  assign io_uncache_req_bits_addr = req_paddr;
  assign io_uncache_req_bits_vaddr = req_vaddr;
  assign io_uncache_req_bits_mask = req_paddr[3] ? req_mask[15:8] : req_mask[7:0];
  assign io_uncache_req_bits_nc = req_nc;
  assign io_uncache_req_bits_memBackTypeMM = req_memBackTypeMM;
  assign io_exception_valid = writeback;
  assign io_exception_bits_uop_exceptionVec_3 = req_uop_exceptionVec_3;
  assign io_exception_bits_uop_exceptionVec_4 = req_uop_exceptionVec_4;
  assign io_exception_bits_uop_exceptionVec_5 = denied;
  assign io_exception_bits_uop_exceptionVec_13 = req_uop_exceptionVec_13;
  assign io_exception_bits_uop_exceptionVec_19 = corrupt & ~denied;
  assign io_exception_bits_uop_exceptionVec_21 = req_uop_exceptionVec_21;
  assign io_exception_bits_uop_uopIdx = req_uop_uopIdx;
  assign io_exception_bits_uop_robIdx_flag = req_uop_robIdx_flag;
  assign io_exception_bits_uop_robIdx_value = req_uop_robIdx_value;
  assign io_exception_bits_fullva = req_fullva;
  assign io_exception_bits_gpaddr = req_gpaddr;
  assign io_exception_bits_isHyper = req_isHyper;
  assign io_exception_bits_isForVSnonLeafPTE = req_isForVSnonLeafPTE;
  // END GENERATED

endmodule
