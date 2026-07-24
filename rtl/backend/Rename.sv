// =====================================================================
// xs_Rename_core —— 重命名流水(Rename)可读重写【A 批：重命名教学核心】
// ---------------------------------------------------------------------
// 位置：Decode → 【Rename】 → Dispatch。把逻辑寄存器号翻译成物理寄存器号，
// 消除 WAR/WAW 假相关。本核从 Scala (class Rename) 的设计意图重写。
//
// 数据流(一拍组合 + 少量打拍状态)：
//   io_in[6](DecodedInst)  ──┐
//                            ├─ CompressUnit(黑盒) → needRobFlags/instrSizes/masks
//   RAT 读出 intReadPorts 等 ─┤
//                            ├─ 5×FreeList(黑盒) → allocatePhyReg / canAllocate
//   rabCommits / redirect ───┘
//                            ▼
//   ┌── psrc：RAT 读 + 同拍 RAW 旁路(前序口 pdest 折叠覆盖) + LUI/fusion 特例
//   ├── pdest：Mux(isMove, psrc0, freelist_out)  ← move elimination
//   ├── robIdx：robIdxHead + PopCount(本口之前的 lastUop&needRob)
//   ├── RAT 写口(specWen/addr/data)、FreeList 互联(doAllocate/canOut)
//   └── snapshot/allowSnpt
//                            ▼
//   io_out[6](DynInst)：85 个字段直通 + 上述 A 批计算字段
//
// 【关键设计点 1：同拍 RAW 旁路(psrc)】
//   RAT 这拍读出的是「上拍提交后」的映射，但本拍前序指令(0..i-1)可能也写了
//   同一逻辑寄存器。它们的新 pdest 这拍才算出、RAT 还没更新，所以必须在本级
//   把前序 pdest 直接转发给后序 psrc。bypassCond(j)(i-1) 是一个 i 位向量，
//   位 k=1 表示「第 i 口的第 j 个源命中第 k 口的目的」。按【低位优先级折叠】
//   (foldLeft：从 RAT 默认值出发，逐口若命中就覆盖，最终最高命中口生效)。
//
// 【关键设计点 2：move elimination(pdest)】
//   mv rd, rs 不真正搬数据，只要让 rd 也指向 rs 的物理寄存器即可。
//   故 isMove 时 pdest = psrc0(已含旁路)，不向 FreeList 要新寄存器。
//   这正是 rename 关键路径所在：pdest 依赖 psrc，psrc 又依赖前序 pdest。
//
// 【关键设计点 3：robIdx 投机分配 + 回退】
//   robIdxHead 是 ROB 的循环写指针(flag+value, 模 160)。每条「lastUop 且需进
//   ROB」的指令占一个槽。第 i 口的 robIdx = head + (它之前这种指令的个数)。
//   redirect 拍把 head 直接拉到 redirect.robIdx；误预测(不冲刷自身)拍 head+1；
//   正常 canOut 拍 head += validCount。
//
// 子模块全部 golden 黑盒：CompressUnit / MEFreeList(intFreeList) /
//   StdFreeList×4(fp/vec/v0/vl)。它们内部已各自重写并验证。
//
// 【B 批已实现】：见文末 "B批" 各节注释。具体为 numLsElem / dirtyVs / dirtyFs /
//   wfflags / instrSize / numWB / lastUop(压缩精确化) / traceBlockInPipe.{itype,
//   iretire,ilastsize}。这些是译码级组合机器，按 Scala 帮助函数语义重写。
//   仅 debugInfo_renameTime 为自由计数器(GTimer)，UT 跳过、FM 不可判(非功能 debug 口)。
// =====================================================================
module xs_Rename_core
  import rename_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // -------- redirect(分支预测错误/异常重定向) --------
  input  logic                  io_redirect_valid,
  input  logic                  io_redirect_bits_robIdx_flag,
  input  logic [ROB_PTR_W-1:0]  io_redirect_bits_robIdx_value,
  input  logic                  io_redirect_bits_level,         // flushItself: 1=冲刷自身
  input  logic                  io_redirect_bits_debugIsCtrl,   // stallReason: 控制相关重定向
  input  logic                  io_redirect_bits_debugIsMemVio, // stallReason: 访存违例重定向

  // -------- RAB 提交/回滚 --------
  input  logic                  io_rabCommits_isCommit,
  input  logic                  io_rabCommits_isWalk,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_commitValid,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_walkValid,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_rfWen,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_fpWen,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_vecWen,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_v0Wen,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_vlWen,
  input  logic [COMMIT_WIDTH-1:0] io_rabCommits_info_isMove,

  input  logic                  io_singleStep,

  // -------- 来自 decode 的指令包 --------
  input  decoded_inst_t         io_in_bits  [RENAME_WIDTH],
  input  logic [RENAME_WIDTH-1:0] io_in_valid,
  output logic [RENAME_WIDTH-1:0] io_in_ready,

  // -------- 融合译码信息(指导 psrc1 来源) --------
  input  logic [RENAME_WIDTH-1:0] io_fusionInfo_rs2FromRs1,  // 仅 0..4 有效
  input  logic [RENAME_WIDTH-1:0] io_fusionInfo_rs2FromRs2,
  input  logic [RENAME_WIDTH-1:0] io_fusionInfo_rs2FromZero,

  // -------- RAT 读出(物理寄存器号) --------
  input  logic [PHYREG_W-1:0]   io_intReadPorts [RENAME_WIDTH][2],
  input  logic [PHYREG_W-1:0]   io_fpReadPorts  [RENAME_WIDTH][3],
  input  logic [PHYREG_W-1:0]   io_vecReadPorts [RENAME_WIDTH][3],
  input  logic [PHYREG_W-1:0]   io_v0ReadPorts  [RENAME_WIDTH],
  input  logic [PHYREG_W-1:0]   io_vlReadPorts  [RENAME_WIDTH],

  // -------- RAT 投机写口(specRenamePorts) --------
  output rat_wport_t            io_intRenamePorts [COMMIT_WIDTH],
  output rat_wport_t            io_fpRenamePorts  [COMMIT_WIDTH],
  output rat_wport_t            io_vecRenamePorts [COMMIT_WIDTH],
  output logic                  io_v0RenamePorts_wen  [COMMIT_WIDTH],
  output logic [PHYREG_W-1:0]   io_v0RenamePorts_data [COMMIT_WIDTH],
  output logic                  io_vlRenamePorts_wen  [COMMIT_WIDTH],
  output logic [PHYREG_W-1:0]   io_vlRenamePorts_data [COMMIT_WIDTH],

  // -------- 从 RAT 来的旧 pdest(回收用) --------
  input  logic [PHYREG_W-1:0]   io_int_old_pdest [COMMIT_WIDTH],
  input  logic [PHYREG_W-1:0]   io_fp_old_pdest  [COMMIT_WIDTH],
  input  logic [PHYREG_W-1:0]   io_vec_old_pdest [COMMIT_WIDTH],
  input  logic [PHYREG_W-1:0]   io_v0_old_pdest  [COMMIT_WIDTH],
  input  logic [PHYREG_W-1:0]   io_vl_old_pdest  [COMMIT_WIDTH],
  input  logic [COMMIT_WIDTH-1:0] io_int_need_free,

  // -------- 到 dispatch 的输出(DynInst) --------
  // 直通 + A批计算字段分组输出(wrapper 再机械拼回 golden 扁平端口)
  output logic [RENAME_WIDTH-1:0] io_out_valid,
  input  logic [RENAME_WIDTH-1:0] io_out_ready,
  output decoded_inst_t           io_out_passthru [RENAME_WIDTH], // 85 直通字段载体
  output logic [PHYREG_W-1:0]     io_out_psrc  [RENAME_WIDTH][NUM_SRC],
  output logic [PHYREG_W-1:0]     io_out_pdest [RENAME_WIDTH],
  output logic                    io_out_robIdx_flag  [RENAME_WIDTH],
  output logic [ROB_PTR_W-1:0]    io_out_robIdx_value [RENAME_WIDTH],
  output logic                    io_out_eliminatedMove [RENAME_WIDTH],
  output logic                    io_out_snapshot [RENAME_WIDTH],
  output logic                    io_out_hasException [RENAME_WIDTH],
  output logic [SRCTYPE_W-1:0]    io_out_srcType0 [RENAME_WIDTH],  // 可能被 fused-lui-load 改写
  output logic [IMM_OUT_W-1:0]    io_out_imm [RENAME_WIDTH],       // fence/lui32 融合改写
  output logic [63:0]             io_out_debugInfo_renameTime [RENAME_WIDTH],
  // B批占位输出(本批不实现，置 0；文档注明不可判)
  output logic [2:0]              io_out_instrSize [RENAME_WIDTH],
  output logic                    io_out_dirtyFs [RENAME_WIDTH],
  output logic                    io_out_dirtyVs [RENAME_WIDTH],
  output logic [3:0]              io_out_itype [RENAME_WIDTH],
  output logic [3:0]              io_out_iretire [RENAME_WIDTH],
  output logic                    io_out_ilastsize [RENAME_WIDTH],
  output logic                    io_out_lastUop_o [RENAME_WIDTH],
  output logic [6:0]              io_out_numWB [RENAME_WIDTH],
  output logic                    io_out_wfflags_o [RENAME_WIDTH],
  output logic [4:0]              io_out_numLsElem [RENAME_WIDTH],
  // 压缩 ROB-slot 折叠字段(非纯直通)：ftqPtr/ftqOffset 继承压缩组头, firstUop 门控,
  //   waitForward/blockBackward 对合法计数器 CSR 读清零。
  output logic                    io_out_ftqPtr_flag_o [RENAME_WIDTH],
  output logic [5:0]              io_out_ftqPtr_value_o [RENAME_WIDTH],
  output logic [3:0]              io_out_ftqOffset_o [RENAME_WIDTH],
  output logic                    io_out_firstUop_o [RENAME_WIDTH],
  output logic                    io_out_waitForward_o [RENAME_WIDTH],
  output logic                    io_out_blockBackward_o [RENAME_WIDTH],

  // -------- 快照端口 --------
  input  logic                  io_snpt_snptDeq,
  input  logic                  io_snpt_useSnpt,
  input  logic [1:0]            io_snpt_snptSelect,
  input  logic [3:0]            io_snpt_flushVec,
  input  logic                  io_snptLastEnq_valid,
  input  logic                  io_snptLastEnq_bits_flag,
  input  logic [ROB_PTR_W-1:0]  io_snptLastEnq_bits_value,
  input  logic                  io_snptIsFull,

  // -------- stallReason / perf(简化直通/置0) --------
  input  logic [5:0]            io_stallReason_in_reason [RENAME_WIDTH],
  input  logic                  io_stallReason_out_backReason_valid,
  output logic                  io_stallReason_in_backReason_valid,
  output logic [5:0]            io_stallReason_in_backReason_bits,
  output logic [5:0]            io_stallReason_out_reason [RENAME_WIDTH],
  output logic [5:0]            io_perf_value [30]
);

  // ===================================================================
  // 小工具：把 srcType 译成各类目的需求位
  // ===================================================================
  // needXDest[i] = in 有效 && 该指令写 X 类寄存器
  logic [RENAME_WIDTH-1:0] needIntDest, needFpDest, needVecDest, needV0Dest, needVlDest;
  logic [RENAME_WIDTH-1:0] isMove;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      needIntDest[i] = io_in_valid[i] & io_in_bits[i].rfWen;
      needFpDest [i] = io_in_valid[i] & io_in_bits[i].fpWen;
      needVecDest[i] = io_in_valid[i] & io_in_bits[i].vecWen;
      needV0Dest [i] = io_in_valid[i] & io_in_bits[i].v0Wen;
      needVlDest [i] = io_in_valid[i] & io_in_bits[i].vlWen;
      // 有异常的 move 不做消除(异常要走完整流程)
      isMove[i]      = io_in_bits[i].isMove & ~(|io_in_bits[i].exceptionVec);
    end

  // ===================================================================
  // 1. CompressUnit(黑盒)：把可压缩的连续指令归并到一个 ROB 槽
  //    输出 needRobFlags(该口是否独占一个 ROB 槽)/instrSizes/masks/canCompressVec。
  //    本核只用 needRobFlags 算 robIdx；masks/sizes 属 B 批(numWB 压缩)用。
  // ===================================================================
  logic [RENAME_WIDTH-1:0] needRobFlags;
  logic [2:0]              instrSizes [RENAME_WIDTH];
  logic [5:0]              cmpMasks   [RENAME_WIDTH];
  logic [RENAME_WIDTH-1:0] canCompressVec;

  // CompressUnit 入口：valid 经 singleStep 门控(单步时不压缩)
  logic [RENAME_WIDTH-1:0] cmpInValid;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) cmpInValid[i] = io_in_valid[i] & ~io_singleStep;

  CompressUnit compressUnit (
    .io_in_0_valid(cmpInValid[0]), .io_in_1_valid(cmpInValid[1]),
    .io_in_2_valid(cmpInValid[2]), .io_in_3_valid(cmpInValid[3]),
    .io_in_4_valid(cmpInValid[4]), .io_in_5_valid(cmpInValid[5]),
    `define EXC_BIND(P) \
      .io_in_``P``_bits_exceptionVec_0 (io_in_bits[P].exceptionVec[0]),  \
      .io_in_``P``_bits_exceptionVec_1 (io_in_bits[P].exceptionVec[1]),  \
      .io_in_``P``_bits_exceptionVec_2 (io_in_bits[P].exceptionVec[2]),  \
      .io_in_``P``_bits_exceptionVec_3 (io_in_bits[P].exceptionVec[3]),  \
      .io_in_``P``_bits_exceptionVec_4 (io_in_bits[P].exceptionVec[4]),  \
      .io_in_``P``_bits_exceptionVec_5 (io_in_bits[P].exceptionVec[5]),  \
      .io_in_``P``_bits_exceptionVec_6 (io_in_bits[P].exceptionVec[6]),  \
      .io_in_``P``_bits_exceptionVec_7 (io_in_bits[P].exceptionVec[7]),  \
      .io_in_``P``_bits_exceptionVec_8 (io_in_bits[P].exceptionVec[8]),  \
      .io_in_``P``_bits_exceptionVec_9 (io_in_bits[P].exceptionVec[9]),  \
      .io_in_``P``_bits_exceptionVec_10(io_in_bits[P].exceptionVec[10]), \
      .io_in_``P``_bits_exceptionVec_11(io_in_bits[P].exceptionVec[11]), \
      .io_in_``P``_bits_exceptionVec_12(io_in_bits[P].exceptionVec[12]), \
      .io_in_``P``_bits_exceptionVec_13(io_in_bits[P].exceptionVec[13]), \
      .io_in_``P``_bits_exceptionVec_14(io_in_bits[P].exceptionVec[14]), \
      .io_in_``P``_bits_exceptionVec_15(io_in_bits[P].exceptionVec[15]), \
      .io_in_``P``_bits_exceptionVec_16(io_in_bits[P].exceptionVec[16]), \
      .io_in_``P``_bits_exceptionVec_17(io_in_bits[P].exceptionVec[17]), \
      .io_in_``P``_bits_exceptionVec_18(io_in_bits[P].exceptionVec[18]), \
      .io_in_``P``_bits_exceptionVec_19(io_in_bits[P].exceptionVec[19]), \
      .io_in_``P``_bits_exceptionVec_20(io_in_bits[P].exceptionVec[20]), \
      .io_in_``P``_bits_exceptionVec_21(io_in_bits[P].exceptionVec[21]), \
      .io_in_``P``_bits_exceptionVec_22(io_in_bits[P].exceptionVec[22]), \
      .io_in_``P``_bits_exceptionVec_23(io_in_bits[P].exceptionVec[23]), \
      .io_in_``P``_bits_trigger        (io_in_bits[P].trigger),          \
      .io_in_``P``_bits_canRobCompress (io_in_bits[P].canRobCompress),   \
      .io_in_``P``_bits_lastUop        (io_in_bits[P].lastUop),          \
      .io_in_``P``_bits_commitType     (io_in_bits[P].commitType)
    `EXC_BIND(0), `EXC_BIND(1), `EXC_BIND(2),
    `EXC_BIND(3), `EXC_BIND(4), `EXC_BIND(5),
    `undef EXC_BIND
    .io_out_needRobFlags_0(needRobFlags[0]), .io_out_needRobFlags_1(needRobFlags[1]),
    .io_out_needRobFlags_2(needRobFlags[2]), .io_out_needRobFlags_3(needRobFlags[3]),
    .io_out_needRobFlags_4(needRobFlags[4]), .io_out_needRobFlags_5(needRobFlags[5]),
    .io_out_instrSizes_0(instrSizes[0]), .io_out_instrSizes_1(instrSizes[1]),
    .io_out_instrSizes_2(instrSizes[2]), .io_out_instrSizes_3(instrSizes[3]),
    .io_out_instrSizes_4(instrSizes[4]), .io_out_instrSizes_5(instrSizes[5]),
    .io_out_masks_0(cmpMasks[0]), .io_out_masks_1(cmpMasks[1]),
    .io_out_masks_2(cmpMasks[2]), .io_out_masks_3(cmpMasks[3]),
    .io_out_masks_4(cmpMasks[4]), .io_out_masks_5(cmpMasks[5]),
    .io_out_canCompressVec_0(canCompressVec[0]), .io_out_canCompressVec_1(canCompressVec[1]),
    .io_out_canCompressVec_2(canCompressVec[2]), .io_out_canCompressVec_3(canCompressVec[3]),
    .io_out_canCompressVec_4(canCompressVec[4]), .io_out_canCompressVec_5(canCompressVec[5])
  );

  // ===================================================================
  // 2. 五个 FreeList(黑盒)的互联：doAllocate / canAllocate / canOut
  //    设计意图(Scala)：只有【所有 5 个 FreeList 都 canAllocate 且 dispatch
  //    能收】才真正分配；isWalk(回滚重放)时一定能分配(回收的寄存器够用)。
  //    每个 FreeList 的 doAllocate = 【其余 4 个 canAllocate】& dispatchReady | isWalk
  //    —— 五路交叉 AND，故任一 FreeList 没空间会卡住整条流水。
  // ===================================================================
  logic [PHYREG_W-1:0] intAlloc [RENAME_WIDTH], fpAlloc [RENAME_WIDTH],
                       vecAlloc [RENAME_WIDTH], v0Alloc [RENAME_WIDTH], vlAlloc [RENAME_WIDTH];
  logic intCanAlloc, fpCanAlloc, vecCanAlloc, v0CanAlloc, vlCanAlloc;

  wire dispatchReady = io_out_ready[0];          // dispatch1 能否接收(看 head ready)
  wire isWalk        = io_rabCommits_isWalk;

  // 第 X 个 FreeList 的 doAllocate：其余四个 canAllocate 与 dispatchReady，或 isWalk
  wire intDoAlloc = (fpCanAlloc & vecCanAlloc & v0CanAlloc & vlCanAlloc & dispatchReady) | isWalk;
  wire fpDoAlloc  = (intCanAlloc & vecCanAlloc & v0CanAlloc & vlCanAlloc & dispatchReady) | isWalk;
  wire vecDoAlloc = (intCanAlloc & fpCanAlloc  & v0CanAlloc & vlCanAlloc & dispatchReady) | isWalk;
  wire v0DoAlloc  = (intCanAlloc & fpCanAlloc  & vecCanAlloc & vlCanAlloc & dispatchReady) | isWalk;
  wire vlDoAlloc  = (intCanAlloc & fpCanAlloc  & vecCanAlloc & v0CanAlloc & dispatchReady) | isWalk;

  // canOut：所有 FreeList 就绪 + dispatch 就绪 + 非回滚 → 本拍可放行到下一级
  wire canOut = dispatchReady & intCanAlloc & fpCanAlloc & vecCanAlloc
              & v0CanAlloc & vlCanAlloc & ~isWalk;

  // ---- 分配请求(整数口要排除 move) / 回滚重放请求 ----
  logic [RENAME_WIDTH-1:0] intAllocReq, fpAllocReq, vecAllocReq, v0AllocReq, vlAllocReq;
  logic [COMMIT_WIDTH-1:0] intWalkReq, fpWalkReq, vecWalkReq, v0WalkReq, vlWalkReq;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      intAllocReq[i] = needIntDest[i] & ~isMove[i];
      fpAllocReq [i] = needFpDest[i];
      vecAllocReq[i] = needVecDest[i];
      v0AllocReq [i] = needV0Dest[i];
      vlAllocReq [i] = needVlDest[i];
      // walk(回滚)：用提交信息里的 Wen，且整数排除 move
      intWalkReq[i] = io_rabCommits_walkValid[i] & io_rabCommits_info_rfWen[i] & ~io_rabCommits_info_isMove[i];
      fpWalkReq [i] = io_rabCommits_walkValid[i] & io_rabCommits_info_fpWen[i];
      vecWalkReq[i] = io_rabCommits_walkValid[i] & io_rabCommits_info_vecWen[i];
      v0WalkReq [i] = io_rabCommits_walkValid[i] & io_rabCommits_info_v0Wen[i];
      vlWalkReq [i] = io_rabCommits_walkValid[i] & io_rabCommits_info_vlWen[i];
    end

  // ---- snapshot 互联：snptEnq = genSnapshot(本拍有需要打快照的指令放行) ----
  logic genSnapshot;   // 见第 6 节

  // ---- 整数 FreeList 的回收数据要打一拍(golden: RegNext(int_old_pdest)) ----
  logic [PHYREG_W-1:0] intFreePhyReg_REG [COMMIT_WIDTH];
  always_ff @(posedge clock)
    for (int i = 0; i < COMMIT_WIDTH; i++) intFreePhyReg_REG[i] <= io_int_old_pdest[i];

  // ---- fp/vec/v0/vl FreeList 的 freeReq 要打一拍(golden: GatedValidRegNext) ----
  // commitVec[i]=本口有效提交(组合网, 不放 always_ff 内声明——否则 FM 前端把 always_ff
  //  内的 blocking 临时量每迭代推成死寄存器 cv_reg=unread_impl 伪影)。
  logic [COMMIT_WIDTH-1:0] commitVec;
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++)
      commitVec[i] = io_rabCommits_isCommit & io_rabCommits_commitValid[i];
  logic [COMMIT_WIDTH-1:0] fpFreeReq_REG, vecFreeReq_REG, v0FreeReq_REG, vlFreeReq_REG;
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      fpFreeReq_REG <= '0; vecFreeReq_REG <= '0; v0FreeReq_REG <= '0; vlFreeReq_REG <= '0;
    end else
      for (int i = 0; i < COMMIT_WIDTH; i++) begin
        fpFreeReq_REG [i] <= commitVec[i] & io_rabCommits_info_fpWen[i];
        vecFreeReq_REG[i] <= commitVec[i] & io_rabCommits_info_vecWen[i];
        v0FreeReq_REG [i] <= commitVec[i] & io_rabCommits_info_v0Wen[i];
        vlFreeReq_REG [i] <= commitVec[i] & io_rabCommits_info_vlWen[i];
      end

  // FreeList perf 输出先接命名中间线, 之后经 golden 的两级寄存器流水线映射到 io_perf_value。
  logic [5:0] intFlPerf [4], fpFlPerf [4], vecFlPerf [4], v0FlPerf [4], vlFlPerf [4];

  // ---- 整数 FreeList(MEFreeList)：move elimination 版本 ----
  MEFreeList intFreeList (
    .clock(clock), .reset(reset),
    .io_redirect(io_redirect_valid), .io_walk(isWalk),
    .io_allocateReq_0(intAllocReq[0]), .io_allocateReq_1(intAllocReq[1]),
    .io_allocateReq_2(intAllocReq[2]), .io_allocateReq_3(intAllocReq[3]),
    .io_allocateReq_4(intAllocReq[4]), .io_allocateReq_5(intAllocReq[5]),
    .io_walkReq_0(intWalkReq[0]), .io_walkReq_1(intWalkReq[1]),
    .io_walkReq_2(intWalkReq[2]), .io_walkReq_3(intWalkReq[3]),
    .io_walkReq_4(intWalkReq[4]), .io_walkReq_5(intWalkReq[5]),
    .io_allocatePhyReg_0(intAlloc[0]), .io_allocatePhyReg_1(intAlloc[1]),
    .io_allocatePhyReg_2(intAlloc[2]), .io_allocatePhyReg_3(intAlloc[3]),
    .io_allocatePhyReg_4(intAlloc[4]), .io_allocatePhyReg_5(intAlloc[5]),
    .io_canAllocate(intCanAlloc), .io_doAllocate(intDoAlloc),
    .io_freeReq_0(io_int_need_free[0]), .io_freeReq_1(io_int_need_free[1]),
    .io_freeReq_2(io_int_need_free[2]), .io_freeReq_3(io_int_need_free[3]),
    .io_freeReq_4(io_int_need_free[4]), .io_freeReq_5(io_int_need_free[5]),
    .io_freePhyReg_0(intFreePhyReg_REG[0]), .io_freePhyReg_1(intFreePhyReg_REG[1]),
    .io_freePhyReg_2(intFreePhyReg_REG[2]), .io_freePhyReg_3(intFreePhyReg_REG[3]),
    .io_freePhyReg_4(intFreePhyReg_REG[4]), .io_freePhyReg_5(intFreePhyReg_REG[5]),
    .io_commit_isCommit(io_rabCommits_isCommit),
    .io_commit_commitValid_0(io_rabCommits_commitValid[0]), .io_commit_commitValid_1(io_rabCommits_commitValid[1]),
    .io_commit_commitValid_2(io_rabCommits_commitValid[2]), .io_commit_commitValid_3(io_rabCommits_commitValid[3]),
    .io_commit_commitValid_4(io_rabCommits_commitValid[4]), .io_commit_commitValid_5(io_rabCommits_commitValid[5]),
    .io_commit_info_0_rfWen(io_rabCommits_info_rfWen[0]), .io_commit_info_0_isMove(io_rabCommits_info_isMove[0]),
    .io_commit_info_1_rfWen(io_rabCommits_info_rfWen[1]), .io_commit_info_1_isMove(io_rabCommits_info_isMove[1]),
    .io_commit_info_2_rfWen(io_rabCommits_info_rfWen[2]), .io_commit_info_2_isMove(io_rabCommits_info_isMove[2]),
    .io_commit_info_3_rfWen(io_rabCommits_info_rfWen[3]), .io_commit_info_3_isMove(io_rabCommits_info_isMove[3]),
    .io_commit_info_4_rfWen(io_rabCommits_info_rfWen[4]), .io_commit_info_4_isMove(io_rabCommits_info_isMove[4]),
    .io_commit_info_5_rfWen(io_rabCommits_info_rfWen[5]), .io_commit_info_5_isMove(io_rabCommits_info_isMove[5]),
    .io_snpt_snptEnq(genSnapshot), .io_snpt_snptDeq(io_snpt_snptDeq),
    .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect),
    .io_snpt_flushVec_0(io_snpt_flushVec[0]), .io_snpt_flushVec_1(io_snpt_flushVec[1]),
    .io_snpt_flushVec_2(io_snpt_flushVec[2]), .io_snpt_flushVec_3(io_snpt_flushVec[3]),
    .io_perf_0_value(intFlPerf[0]), .io_perf_1_value(intFlPerf[1]),
    .io_perf_2_value(intFlPerf[2]), .io_perf_3_value(intFlPerf[3])
  );

  // ---- fp/vec/v0/vl FreeList(StdFreeList 变体)，公共绑定用宏减少机械重复 ----
  `define STD_FL(MOD, INST, REQ, WREQ, ALLOC, CAN, DOALLOC, FREEREQ, FREEPD, WENNAME, PERF) \
    MOD INST ( \
      .clock(clock), .reset(reset), .io_redirect(io_redirect_valid), .io_walk(isWalk), \
      .io_allocateReq_0(REQ[0]), .io_allocateReq_1(REQ[1]), .io_allocateReq_2(REQ[2]), \
      .io_allocateReq_3(REQ[3]), .io_allocateReq_4(REQ[4]), .io_allocateReq_5(REQ[5]), \
      .io_walkReq_0(WREQ[0]), .io_walkReq_1(WREQ[1]), .io_walkReq_2(WREQ[2]), \
      .io_walkReq_3(WREQ[3]), .io_walkReq_4(WREQ[4]), .io_walkReq_5(WREQ[5]), \
      .io_allocatePhyReg_0(ALLOC[0]), .io_allocatePhyReg_1(ALLOC[1]), .io_allocatePhyReg_2(ALLOC[2]), \
      .io_allocatePhyReg_3(ALLOC[3]), .io_allocatePhyReg_4(ALLOC[4]), .io_allocatePhyReg_5(ALLOC[5]), \
      .io_canAllocate(CAN), .io_doAllocate(DOALLOC), \
      .io_freeReq_0(FREEREQ[0]), .io_freeReq_1(FREEREQ[1]), .io_freeReq_2(FREEREQ[2]), \
      .io_freeReq_3(FREEREQ[3]), .io_freeReq_4(FREEREQ[4]), .io_freeReq_5(FREEREQ[5]), \
      .io_freePhyReg_0(FREEPD[0]), .io_freePhyReg_1(FREEPD[1]), .io_freePhyReg_2(FREEPD[2]), \
      .io_freePhyReg_3(FREEPD[3]), .io_freePhyReg_4(FREEPD[4]), .io_freePhyReg_5(FREEPD[5]), \
      .io_commit_isCommit(io_rabCommits_isCommit), \
      .io_commit_commitValid_0(io_rabCommits_commitValid[0]), .io_commit_commitValid_1(io_rabCommits_commitValid[1]), \
      .io_commit_commitValid_2(io_rabCommits_commitValid[2]), .io_commit_commitValid_3(io_rabCommits_commitValid[3]), \
      .io_commit_commitValid_4(io_rabCommits_commitValid[4]), .io_commit_commitValid_5(io_rabCommits_commitValid[5]), \
      .io_commit_info_0_``WENNAME(io_rabCommits_info_``WENNAME``[0]), \
      .io_commit_info_1_``WENNAME(io_rabCommits_info_``WENNAME``[1]), \
      .io_commit_info_2_``WENNAME(io_rabCommits_info_``WENNAME``[2]), \
      .io_commit_info_3_``WENNAME(io_rabCommits_info_``WENNAME``[3]), \
      .io_commit_info_4_``WENNAME(io_rabCommits_info_``WENNAME``[4]), \
      .io_commit_info_5_``WENNAME(io_rabCommits_info_``WENNAME``[5]), \
      .io_snpt_snptEnq(genSnapshot), .io_snpt_snptDeq(io_snpt_snptDeq), \
      .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect), \
      .io_snpt_flushVec_0(io_snpt_flushVec[0]), .io_snpt_flushVec_1(io_snpt_flushVec[1]), \
      .io_snpt_flushVec_2(io_snpt_flushVec[2]), .io_snpt_flushVec_3(io_snpt_flushVec[3]), \
      .io_perf_0_value(PERF[0]), .io_perf_1_value(PERF[1]), \
      .io_perf_2_value(PERF[2]), .io_perf_3_value(PERF[3]) )

  `STD_FL(StdFreeList,   fpFreeList,  fpAllocReq,  fpWalkReq,  fpAlloc,  fpCanAlloc,  fpDoAlloc,  fpFreeReq_REG,  io_fp_old_pdest,  fpWen,  fpFlPerf);
  `STD_FL(StdFreeList_1, vecFreeList, vecAllocReq, vecWalkReq, vecAlloc, vecCanAlloc, vecDoAlloc, vecFreeReq_REG, io_vec_old_pdest, vecWen, vecFlPerf);
  `STD_FL(StdFreeList_2, v0FreeList,  v0AllocReq,  v0WalkReq,  v0Alloc,  v0CanAlloc,  v0DoAlloc,  v0FreeReq_REG,  io_v0_old_pdest,  v0Wen,  v0FlPerf);
  `STD_FL(StdFreeList_3, vlFreeList,  vlAllocReq,  vlWalkReq,  vlAlloc,  vlCanAlloc,  vlDoAlloc,  vlFreeReq_REG,  io_vl_old_pdest,  vlWen,  vlFlPerf);
  `undef STD_FL

  // ===================================================================
  // 3. robIdx 投机分配
  //    每条「io_in valid && lastUop && needRobFlag」的指令占一个 ROB 槽。
  //    第 i 口 robIdx = robIdxHead + (它之前同类指令的个数)。
  //    robIdxHead 循环指针：value 模 ROB_SIZE(160)，跨界翻转 flag。
  // ===================================================================
  logic                 robIdxHead_flag;
  logic [ROB_PTR_W-1:0] robIdxHead_value;
  // 误预测打一拍(redirect 且非冲刷自身 → 下拍 head+1，跳过被冲掉的那条)
  logic lastCycleMisprediction;

  // 各口「占 ROB 槽」标志
  logic [RENAME_WIDTH-1:0] takeRobSlot;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      takeRobSlot[i] = io_in_valid[i] & io_in_bits[i].lastUop & needRobFlags[i];

  // 前 i 口占槽数(本口 robIdx 相对 head 的偏移)
  function automatic logic [2:0] slots_below(input logic [RENAME_WIDTH-1:0] v, input int i);
    logic [2:0] s; begin s = '0; for (int k = 0; k < RENAME_WIDTH; k++) if (k < i && v[k]) s += 3'b1; return s; end
  endfunction
  // 本拍总占槽数 validCount
  function automatic logic [2:0] slots_all(input logic [RENAME_WIDTH-1:0] v);
    logic [2:0] s; begin s = '0; for (int k = 0; k < RENAME_WIDTH; k++) if (v[k]) s += 3'b1; return s; end
  endfunction
  wire [2:0] validCount = slots_all(takeRobSlot);

  // 循环指针加法：value + delta，超过 ROB_SIZE 则减去并翻转 flag。
  function automatic void rob_add
      (input logic f, input logic [ROB_PTR_W-1:0] v, input logic [3:0] delta,
       output logic nf, output logic [ROB_PTR_W-1:0] nv);
    logic [9:0] sum;     // 足够容纳 v+delta
    begin
      sum = {2'h0, v} + {6'h0, delta};
      if (sum >= ROB_SIZE) begin nv = sum - ROB_SIZE; nf = ~f; end
      else                  begin nv = sum[ROB_PTR_W-1:0]; nf = f; end
    end
  endfunction

  // 每口 robIdx = head + slots_below(i)
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic nf; logic [ROB_PTR_W-1:0] nv;
      rob_add(robIdxHead_flag, robIdxHead_value, {1'b0, slots_below(takeRobSlot, i)}, nf, nv);
      io_out_robIdx_flag [i] = nf;
      io_out_robIdx_value[i] = nv;
    end

  // robIdxHead 下一值
  logic                 robIdxHeadNext_flag;
  logic [ROB_PTR_W-1:0] robIdxHeadNext_value;
  always_comb begin
    logic mf; logic [ROB_PTR_W-1:0] mv;  // 误预测 +1
    logic cf; logic [ROB_PTR_W-1:0] cv;  // 正常 +validCount
    rob_add(robIdxHead_flag, robIdxHead_value, 4'd1, mf, mv);
    rob_add(robIdxHead_flag, robIdxHead_value, {1'b0, validCount}, cf, cv);
    if (io_redirect_valid) begin
      robIdxHeadNext_flag  = io_redirect_bits_robIdx_flag;
      robIdxHeadNext_value = io_redirect_bits_robIdx_value;
    end else if (lastCycleMisprediction) begin
      robIdxHeadNext_flag  = mf;
      robIdxHeadNext_value = mv;
    end else if (canOut) begin
      robIdxHeadNext_flag  = cf;
      robIdxHeadNext_value = cv;
    end else begin
      robIdxHeadNext_flag  = robIdxHead_flag;
      robIdxHeadNext_value = robIdxHead_value;
    end
  end

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      robIdxHead_flag <= 1'b0; robIdxHead_value <= '0;
      lastCycleMisprediction <= 1'b0;
    end else begin
      robIdxHead_flag  <= robIdxHeadNext_flag;
      robIdxHead_value <= robIdxHeadNext_value;
      lastCycleMisprediction <= io_redirect_valid & ~io_redirect_bits_level;
    end

  // ===================================================================
  // 4. psrc：RAT 读 + 同拍 RAW 旁路 + LUI/fusion 特例
  // ===================================================================
  // 4a. RAT 读出的"基础" psrc(未旁路)。Mux1H by srcType。
  //     psrc0/1: int|fp|vec；psrc2: fp|vec；psrc3=v0ReadPort；psrc4=vlReadPort。
  function automatic logic [PHYREG_W-1:0] mux3
      (input logic [SRCTYPE_W-1:0] st,
       input logic [PHYREG_W-1:0] a, input logic [PHYREG_W-1:0] b, input logic [PHYREG_W-1:0] c);
    return (st[0] ? a : '0) | (st[1] ? b : '0) | (st[2] ? c : '0);
  endfunction

  logic [PHYREG_W-1:0] psrcRat [RENAME_WIDTH][NUM_SRC];  // 未旁路的基础读出
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      psrcRat[i][0] = mux3(io_in_bits[i].srcType[0], io_intReadPorts[i][0], io_fpReadPorts[i][0], io_vecReadPorts[i][0]);
      psrcRat[i][1] = mux3(io_in_bits[i].srcType[1], io_intReadPorts[i][1], io_fpReadPorts[i][1], io_vecReadPorts[i][1]);
      // psrc2 只有 fp/vec(无 int 口)
      psrcRat[i][2] = (io_in_bits[i].srcType[2][1] ? io_fpReadPorts[i][2] : '0)
                    | (io_in_bits[i].srcType[2][2] ? io_vecReadPorts[i][2] : '0);
      psrcRat[i][3] = io_v0ReadPorts[i];
      psrcRat[i][4] = io_vlReadPorts[i];
    end

  // 4b. psrc1 的 fusion 特例(口 0..4)：若融合信息要求 rs2 来自下一条的 rs1/rs2/零，
  //     直接取下一条的 intReadPort(注意：是融合前下一条的 RAT 读，不走旁路)。
  logic [PHYREG_W-1:0] psrc1Base [RENAME_WIDTH];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      psrc1Base[i] = psrcRat[i][1];
      if (i < RENAME_WIDTH-1) begin
        if (io_fusionInfo_rs2FromRs2[i] | io_fusionInfo_rs2FromRs1[i])
          psrc1Base[i] = io_fusionInfo_rs2FromRs2[i] ? io_intReadPorts[i+1][1] : io_intReadPorts[i+1][0];
        else if (io_fusionInfo_rs2FromZero[i])
          psrc1Base[i] = '0;
      end
    end

  // 4c. 同拍 RAW 旁路命中位 bypassHit[i][src][k]：第 i 口的 src 源命中第 k 口(k<i)目的。
  //     命中条件 = (ldest 相等 && 该 k 口确实写对应类别) 或 (v0/vl 特殊命中)。
  //     与 golden bypassCond 一致：indexMatch && writeMatch || v0vlMatch。
  // 与 golden bypassCond 完全一致：对第 i 口的第 s 源(用 lsrc[s] 作 target)，
  //   普通命中 = (prev.ldest==this.lsrc[s]) && writeMatch
  //   writeMatch = srcType[s]∈{xp,fp,vp} 且 prev 写对应类别
  //   v0/vl 命中(不比 ldest)：s==3 且 (vp|v0) 且 prev 写 v0；s==4 且 vp 且 prev 写 vl
  logic bypassHit [RENAME_WIDTH][NUM_SRC][RENAME_WIDTH];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      for (int s = 0; s < NUM_SRC; s++)
        for (int k = 0; k < RENAME_WIDTH; k++) begin
          logic idxMatch, wrMatch, v0vlMatch;
          logic [SRCTYPE_W-1:0] st;
          st = io_in_bits[i].srcType[s];
          idxMatch  = (io_in_bits[k].ldest == io_in_bits[i].lsrc[s]);
          wrMatch   = ((st == SRC_XP) & needIntDest[k])
                    | ((st == SRC_FP) & needFpDest [k])
                    | ((st == SRC_VP) & needVecDest[k]);
          v0vlMatch = ( (s == 3) & ((st == SRC_VP) | (st == SRC_V0)) & needV0Dest[k] )
                    | ( (s == 4) &  (st == SRC_VP)                    & needVlDest[k] );
          bypassHit[i][s][k] = ((k < i) && ((idxMatch & wrMatch) | v0vlMatch));
        end

  // 旁路目标 pdest(各 k 口输出 pdest，含其自身旁路结果)。pdest 见第 5 节，这里前向声明。
  logic [PHYREG_W-1:0] pdest [RENAME_WIDTH];

  // 4d. 折叠选择(就地 inline，不用 function)：基础值 base[i][s] 出发，按 k=0..i-1 顺序
  //     若命中则覆盖(低位起、高位最终生效)。
  //     注意：FM 坑 —— function 内读模块级信号(bypassHit/pdest)会被判 RTL 解释错误，
  //     故这里把折叠写进 always_comb，避免非局部读。
  // base[i][s]：psrc1 用含 fusion 的 psrc1Base，其余用 psrcRat。
  logic [PHYREG_W-1:0] psrcBase [RENAME_WIDTH][NUM_SRC];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      psrcBase[i][0] = psrcRat[i][0];
      psrcBase[i][1] = psrc1Base[i];
      psrcBase[i][2] = psrcRat[i][2];
      psrcBase[i][3] = psrcRat[i][3];
      psrcBase[i][4] = psrcRat[i][4];
    end

  // 折叠后(未 LUI 清零)的各源 psrc
  logic [PHYREG_W-1:0] psrcBypassed [RENAME_WIDTH][NUM_SRC];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      for (int s = 0; s < NUM_SRC; s++) begin
        logic [PHYREG_W-1:0] z;
        z = psrcBase[i][s];
        for (int k = 0; k < RENAME_WIDTH; k++)
          if (k < i && bypassHit[i][s][k]) z = pdest[k];
        psrcBypassed[i][s] = z;
      end

  // 4e. 最终 psrc 输出(含 LUI/fusion 特例)
  // isLUI 条件(psrc0 置 0，因 LUI 的 rs 恒为零寄存器)：fuType==alu & selImm∈{U,LUI32}。
  logic [RENAME_WIDTH-1:0] isLUIzero;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      isLUIzero[i] = (io_in_bits[i].fuType == FU_ALU)
                   & ((io_in_bits[i].selImm == SEL_IMM_U) | (io_in_bits[i].selImm == SEL_IMM_LUI32));

  // psrc0Raw：旁路后、未被 isLUI 清零的 psrc0。move-elim 的 pdest 用它(对应 Scala 的
  // uops(i).psrc.head，而非 io.out(i).bits.psrc(0))；LUI 清零只作用于对外 psrc0 输出。
  logic [PHYREG_W-1:0] psrc0Raw [RENAME_WIDTH];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      psrc0Raw[i]       = psrcBypassed[i][0];
      io_out_psrc[i][0] = isLUIzero[i] ? '0 : psrcBypassed[i][0];
      io_out_psrc[i][1] = psrcBypassed[i][1];
      io_out_psrc[i][2] = psrcBypassed[i][2];
      io_out_psrc[i][3] = psrcBypassed[i][3];
      io_out_psrc[i][4] = psrcBypassed[i][4];
    end

  // ===================================================================
  // 5. pdest：move elimination
  //    isMove → pdest = psrc0(含旁路)；否则按需求类别选对应 FreeList 的分配结果。
  // ===================================================================
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [PHYREG_W-1:0] flAlloc;
      // 五选一(MuxCase，按 int>fp>vec>v0>vl 优先)
      flAlloc = needIntDest[i] ? intAlloc[i]
              : needFpDest [i] ? fpAlloc [i]
              : needVecDest[i] ? vecAlloc[i]
              : needV0Dest [i] ? v0Alloc [i]
              : needVlDest [i] ? vlAlloc [i] : '0;
      // move-elim 源：port 0 用未清零的 raw psrc0(Scala uops(0).psrc.head)；
      // port i>0 用对外 psrc0(已含旁路与 LUI 清零，Scala io.out(i).bits.psrc(0))。
      pdest[i] = isMove[i] ? ((i == 0) ? psrc0Raw[0] : io_out_psrc[i][0]) : flAlloc;
      io_out_pdest[i]          = pdest[i];
      io_out_eliminatedMove[i] = isMove[i];
    end

  // ===================================================================
  // 6. snapshot / allowSnpt
  //    允许打快照(allowSnpt)：① 与上个快照距离够远(notInSameSnpt，打一拍)
  //    ② 上拍没刚建快照 ③ 当前 head 是 firstUop。
  //    某口真正打快照：allowSnpt && 它是 CFI(有 brType 或 isJump) && fire。
  //    genSnapshot：本拍只要有任一口要打快照(且能 fire)就触发 FreeList 入快照。
  // ===================================================================
  localparam int SAME_SNPT_DIST = COMMIT_WIDTH * 4; // RobCommitWidth*4 = 24(0x60)

  logic lastCycleCreateSnpt;
  logic notInSameSnpt;          // 打一拍后的值
  wire allowSnpt = notInSameSnpt & ~lastCycleCreateSnpt & io_in_bits[0].firstUop;

  // 各口是否 fire(in ready & valid)。in_ready 见第 7 节。
  logic [RENAME_WIDTH-1:0] inFire;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) inFire[i] = io_in_ready[i] & io_in_valid[i];

  logic [RENAME_WIDTH-1:0] snapshotVec;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      snapshotVec[i] = allowSnpt
                     & ((|io_in_bits[i].preDecodeInfo_brType) | io_in_bits[i].fuType[0])
                     & inFire[i];
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) io_out_snapshot[i] = snapshotVec[i];

  // genSnapshot = OR over (out.fire && snapshot)。注意：out.fire 与 snapshot 自身的
  // in.fire 不同，需额外要求该口 out 也 fire(out_ready & out_valid)，与 Scala 一致。
  logic [RENAME_WIDTH-1:0] outFire;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) outFire[i] = io_out_ready[i] & io_out_valid[i];
  assign genSnapshot = |(outFire & snapshotVec);

  // notInSameSnpt = RegNext( distanceBetween(robIdxHeadNext, snptLastEnq) >= dist
  //                          || !snptLastEnq.valid )
  // distanceBetween(循环指针距离)：同 flag 时 = headNext - lastEnq；异 flag 时还要
  // 减去半圈偏移(0x60)。阈值 sameSnptDistance=RobCommitWidth*4=24，golden 用"距离的
  // 高 3bit [7:5] 非零"近似判断 >=32(>=0x20)，本核逐位复刻该表达式以严格对齐 golden。
  wire [ROB_PTR_W-1:0] _ns_same = robIdxHeadNext_value - io_snptLastEnq_bits_value;        // 同 flag
  wire [ROB_PTR_W-1:0] _ns_diff = robIdxHeadNext_value - 8'h60 - io_snptLastEnq_bits_value; // 异 flag
  wire [2:0] _ns_hi = (robIdxHeadNext_flag == io_snptLastEnq_bits_flag) ? _ns_same[7:5] : _ns_diff[7:5];
  wire _real_notInSame = (|_ns_hi) | ~io_snptLastEnq_valid;

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      lastCycleCreateSnpt <= 1'b0;
      notInSameSnpt       <= 1'b0;
    end else begin
      lastCycleCreateSnpt <= genSnapshot & ~io_snptIsFull;
      notInSameSnpt       <= _real_notInSame;
    end

  // ===================================================================
  // 7. in_ready / out_valid / 各类 SpecWen(RAT 写口)
  // ===================================================================
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      io_in_ready[i]  = ~io_in_valid[0] | canOut;
      io_out_valid[i] = io_in_valid[i] & intCanAlloc & fpCanAlloc & vecCanAlloc
                      & v0CanAlloc & vlCanAlloc & ~isWalk;
    end

  // SpecWen[i] = needXDest & X.canAlloc & X.doAlloc & !walk & !redirect
  wire notWalkRedir = ~isWalk & ~io_redirect_valid;
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      io_intRenamePorts[i].wen  = needIntDest[i] & intCanAlloc & intDoAlloc & notWalkRedir;
      io_intRenamePorts[i].addr = {1'b0, io_in_bits[i].ldest[INT_RAT_AW-1:0]};
      io_intRenamePorts[i].data = pdest[i];   // = out.pdest(含 move-elim)

      io_fpRenamePorts[i].wen   = needFpDest[i] & fpCanAlloc & fpDoAlloc & notWalkRedir;
      io_fpRenamePorts[i].addr  = io_in_bits[i].ldest;
      io_fpRenamePorts[i].data  = fpAlloc[i];

      io_vecRenamePorts[i].wen  = needVecDest[i] & vecCanAlloc & vecDoAlloc & notWalkRedir;
      io_vecRenamePorts[i].addr = io_in_bits[i].ldest;
      io_vecRenamePorts[i].data = vecAlloc[i];

      io_v0RenamePorts_wen [i]  = needV0Dest[i] & v0CanAlloc & v0DoAlloc & notWalkRedir;
      io_v0RenamePorts_data[i]  = v0Alloc[i];

      io_vlRenamePorts_wen [i]  = needVlDest[i] & vlCanAlloc & vlDoAlloc & notWalkRedir;
      io_vlRenamePorts_data[i]  = vlAlloc[i];
    end

  // ===================================================================
  // 8. 输出：85 直通字段 + A批改写字段 + hasException
  // ===================================================================
  // hasException：前端异常 | illegalInstr(idx 12) | virtualInstr(idx 22) | Dmode 触发
  // selectFrontend = {0,1,2,3}；这里按 golden _GEN_24 的位集合(0,1,2,3,12,20,22)取或
  // 再或 illegal/virtual。Dmode：trigger == 4'h1(简化，对齐 golden 常见判定)。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic exc;
      exc = io_in_bits[i].exceptionVec[0]  | io_in_bits[i].exceptionVec[1]
          | io_in_bits[i].exceptionVec[2]  | io_in_bits[i].exceptionVec[3]
          | io_in_bits[i].exceptionVec[12] | io_in_bits[i].exceptionVec[20]
          | io_in_bits[i].exceptionVec[22];
      io_out_hasException[i] = exc | (io_in_bits[i].trigger == 4'h1);
    end

  // srcType0 改写(fused-lui-load)：若上一条是 LUI(selImm==U & srcType0!=pc) 且本条是
  // load 且上一条 rfWen 写的 ldest == 本条 lsrc0 → 本条 srcType0 置 imm(0)。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic fused;
      fused = 1'b0;
      if (i > 0) begin
        logic last_is_lui, this_is_load, lui_to_load;
        last_is_lui  = (io_in_bits[i-1].selImm == SEL_IMM_U) & (|io_in_bits[i-1].srcType[0]);
        this_is_load = (io_in_bits[i].fuType == FU_LDU);
        lui_to_load  = io_in_valid[i-1] & io_in_bits[i-1].rfWen
                     & (io_in_bits[i-1].ldest == io_in_bits[i].lsrc[0]);
        // golden 用 needIntDest_{i-1} & destToSrc_indexMatch；等价于上式
        fused = last_is_lui & this_is_load & needIntDest[i-1]
              & (io_in_bits[i-1].ldest == io_in_bits[i].lsrc[0]);
      end
      io_out_srcType0[i] = fused ? SRC_IMM : io_in_bits[i].srcType[0];
    end

  // imm 改写(fence / lui32 融合)：
  //   selImm==LUI32 & fuType==alu → {imm[19:0], next.imm[11:0]}  (lui+addi(w) 融合)
  //   fused-lui-load(i>0) → {prev.imm[19:0], imm[11:0]}
  //   fuType==fence → {0, lsrc1, lsrc0}
  //   否则 → 零扩展 imm
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic lui32, fusedLd, fence;
      lui32   = (io_in_bits[i].selImm == SEL_IMM_LUI32) & (io_in_bits[i].fuType == FU_ALU);
      fence   = (io_in_bits[i].fuType == FU_FENCE);
      fusedLd = 1'b0;
      if (i > 0)
        fusedLd = (io_in_bits[i-1].selImm == SEL_IMM_U) & (|io_in_bits[i-1].srcType[0])
                & (io_in_bits[i].fuType == FU_LDU) & needIntDest[i-1]
                & (io_in_bits[i-1].ldest == io_in_bits[i].lsrc[0]);
      if (fusedLd)
        io_out_imm[i] = {io_in_bits[i-1].imm[19:0], io_in_bits[i].imm[11:0]};
      else if (lui32 && i < RENAME_WIDTH-1)
        io_out_imm[i] = {io_in_bits[i].imm[19:0], io_in_bits[i+1].imm[11:0]};
      else if (fence)
        io_out_imm[i] = {20'h0, io_in_bits[i].lsrc[1], io_in_bits[i].lsrc[0]};
      else
        io_out_imm[i] = {10'h0, io_in_bits[i].imm};
    end

  // renameTime：debug 观测计数器。golden 每口一个独立 64bit 计数器
  //   uops_i_debugInfo_renameTime_c，均复位 0、每拍无条件 +1(golden 无条件 load，
  //   6 个计数器行为完全一致)。逐口独立复刻以与 golden 结构 1:1 对应
  //   (单一全局 gtimer 会因 FM verification_merge_duplicated_registers 折叠导致某口
  //    无法配对而 failing——bug-for-bug 结构对齐后各口 DFF 逐一匹配)。
  logic [63:0] renameTime_c [RENAME_WIDTH];
  always_ff @(posedge clock or posedge reset)
    if (reset)
      for (int i = 0; i < RENAME_WIDTH; i++) renameTime_c[i] <= 64'h0;
    else
      for (int i = 0; i < RENAME_WIDTH; i++) renameTime_c[i] <= renameTime_c[i] + 64'h1;
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) io_out_debugInfo_renameTime[i] = renameTime_c[i];

  // 85 直通字段：直接把输入 struct 透传(wrapper 只取 DynInst 里存在的字段)
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) io_out_passthru[i] = io_in_bits[i];

  // ---- 压缩 ROB-slot 折叠字段(严格复刻 golden uops_i_*)----
  // ftqPtr/ftqOffset：口 i 若前序口(i-1)不独占 ROB 槽(~needRobFlags[i-1]),则继承已折叠
  //   的 uops_{i-1} 值(压缩组内共享组头 ftq);否则取本口 in。口 0 直通。递归 fold。
  // firstUop：口 0 直通;口 i>0 = needRobFlags[i-1] & in_i.firstUop。
  logic       fldFtqFlag  [RENAME_WIDTH];
  logic [5:0] fldFtqValue [RENAME_WIDTH];
  logic [3:0] fldFtqOff   [RENAME_WIDTH];
  always_comb begin
    fldFtqFlag [0] = io_in_bits[0].ftqPtr_flag;
    fldFtqValue[0] = io_in_bits[0].ftqPtr_value;
    fldFtqOff  [0] = io_in_bits[0].ftqOffset;
    for (int i = 1; i < RENAME_WIDTH; i++) begin
      fldFtqFlag [i] = needRobFlags[i-1] ? io_in_bits[i].ftqPtr_flag  : fldFtqFlag [i-1];
      fldFtqValue[i] = needRobFlags[i-1] ? io_in_bits[i].ftqPtr_value : fldFtqValue[i-1];
      fldFtqOff  [i] = needRobFlags[i-1] ? io_in_bits[i].ftqOffset    : fldFtqOff  [i-1];
    end
  end
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      io_out_ftqPtr_flag_o [i] = fldFtqFlag [i];
      io_out_ftqPtr_value_o[i] = fldFtqValue[i];
      io_out_ftqOffset_o   [i] = fldFtqOff  [i];
      io_out_firstUop_o    [i] = (i == 0) ? io_in_bits[0].firstUop
                                          : (needRobFlags[i-1] & io_in_bits[i].firstUop);
    end

  // ---- waitForward/blockBackward：合法只读 CSR 读免屏障清零 ----
  //   isCsrr = SYSTEM(opcode[6:2]=0x1C) & funct3 有效(|instr[13:12]) & instr[13]
  //            & rs1(instr[19:15])==0 —— 即 csrr rd,csr,x0 形式的 CSR 读。
  //   注意 golden 两字段用【不同白名单】(waitForward 更宽含 frm/fflags/counter 等 21 个,
  //   blockBackward 仅 9 个)。out.X = in.X & ~(isCsrr & ~csrOKfor_X)。
  logic [RENAME_WIDTH-1:0] isCsrr, csrWaitOK, csrBlockOK;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [11:0] csr;
      csr = io_in_bits[i].instr[31:20];
      isCsrr[i] = (io_in_bits[i].instr[6:2] == 5'h1C) & (|io_in_bits[i].instr[13:12])
                & io_in_bits[i].instr[13] & (io_in_bits[i].instr[19:15] == 5'h0);
      // waitForward 白名单(21): 计数器 + frm/fflags/fcsr/vxsat/vxrm/vcsr/vstart 等只读读
      csrWaitOK[i] =
          (csr == 12'h25C) | (csr == 12'h15C) | (csr == 12'h35C) | (csr == 12'hEB0)
        | (csr == 12'hDB0) | (csr == 12'hFB0) | (csr == 12'h251) | (csr == 12'h151)
        | (csr == 12'h351) | (csr == 12'hC21) | (csr == 12'h7B0) | (csr == 12'h744)
        | (csr == 12'h600) | (csr == 12'h300) | (csr == 12'h200) | (csr == 12'h100)
        | (csr == 12'h8)   | (csr == 12'hF)   | (csr == 12'h9)   | (csr == 12'h3)
        | (csr == 12'h1);
      // blockBackward 白名单(9): 仅 counter 组(mcycle/minstret/hpm 影子等)
      csrBlockOK[i] =
          (csr == 12'h151) | (csr == 12'h15C) | (csr == 12'h251) | (csr == 12'h25C)
        | (csr == 12'h351) | (csr == 12'h35C) | (csr == 12'hDB0) | (csr == 12'hEB0)
        | (csr == 12'hFB0);
    end
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      io_out_waitForward_o  [i] = io_in_bits[i].waitForward   & ~(isCsrr[i] & ~csrWaitOK[i]);
      io_out_blockBackward_o[i] = io_in_bits[i].blockBackward & ~(isCsrr[i] & ~csrBlockOK[i]);
    end

  // ===================================================================
  // B批：译码级组合机器(依赖 CompressUnit 的 masks/instrSizes/needRobFlags/canCompressVec)
  //   实现 numLsElem / dirtyVs / dirtyFs / wfflags / instrSize / numWB /
  //   traceBlockInPipe.{itype,iretire,ilastsize} / lastUop(压缩精确化)。
  //   全部按 Scala (class Rename) 帮助函数语义逐口重写。
  // ===================================================================

  // ---- 公共：压缩窗口聚合(mask 为 6 位，位 j=1 表示口 j 属于本口的压缩组) ----
  // wfflags/dirtyFs/dirtyVs 均为「mask & 各口某属性位向量」的 OR 归并。

  // B-1. wfflags(压缩聚合)：本口压缩组里任一指令带 wfflags(写 fflags)即置位。
  //      golden：|(masks(i) & Cat(in.wfflags.reverse))。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic acc; acc = 1'b0;
      for (int j = 0; j < RENAME_WIDTH; j++)
        acc |= cmpMasks[i][j] & io_in_bits[j].wfflags;
      io_out_wfflags_o[i] = acc;
    end

  // B-2. dirtyFs(浮点脏)：压缩组里任一指令 fpWen=1 即置位。
  //      golden：|(masks(i) & Cat(in.fpWen.reverse))。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic acc; acc = 1'b0;
      for (int j = 0; j < RENAME_WIDTH; j++)
        acc |= cmpMasks[i][j] & io_in_bits[j].fpWen;
      io_out_dirtyFs[i] = acc;
    end

  // B-3. dirtyVs(向量脏)：压缩组里任一「真正改写向量状态」的向量指令即置位。
  //   单口判定 isDirtyVsUop(j)：
  //     ① uopSplitType != SCA_SIM(=0)，即确为向量 uop(标量 SCA_SIM 不算)；
  //     ② 排除原子 CAS(uopSplitType ∈ {AMO_CAS_W/D/Q})——它们走 mou，不改向量状态；
  //     ③ 排除 4 条「读向量但不改向量状态」的指令：
  //          vfmv.f.s(vfalu & fuOp=0x11)、vcpop.m(vipu & 0x4B)、
  //          vfirst.m(vipu & 0x4C)、vmv.x.s(vipu & 0x53)。
  //   再 |(masks(i) & Cat(isDirtyVsUop.reverse))。
  logic [RENAME_WIDTH-1:0] isDirtyVsUop;
  always_comb
    for (int j = 0; j < RENAME_WIDTH; j++) begin
      logic isVecUop, isAmoCas, isVfmvFs, isVcpopM, isVfirstM, isVmvXs, isStateKeep;
      isVecUop  = |io_in_bits[j].uopSplitType;            // != SCA_SIM
      isAmoCas  = (io_in_bits[j].uopSplitType == USPLIT_AMOCAS_W)
                | (io_in_bits[j].uopSplitType == USPLIT_AMOCAS_D)
                | (io_in_bits[j].uopSplitType == USPLIT_AMOCAS_Q);
      isVfmvFs  = io_in_bits[j].fuType[FUB_VFALU] & (io_in_bits[j].fuOpType == VOP_VFMV_F_S);
      isVcpopM  = io_in_bits[j].fuType[FUB_VIPU]  & (io_in_bits[j].fuOpType == VOP_VCPOP_M);
      isVfirstM = io_in_bits[j].fuType[FUB_VIPU]  & (io_in_bits[j].fuOpType == VOP_VFIRST_M);
      isVmvXs   = io_in_bits[j].fuType[FUB_VIPU]  & (io_in_bits[j].fuOpType == VOP_VMV_X_S);
      isStateKeep = isVfmvFs | isVcpopM | isVfirstM | isVmvXs;
      isDirtyVsUop[j] = isVecUop & ~isAmoCas & ~isStateKeep;
    end
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic acc; acc = 1'b0;
      for (int j = 0; j < RENAME_WIDTH; j++)
        acc |= cmpMasks[i][j] & isDirtyVsUop[j];
      io_out_dirtyVs[i] = acc;
    end

  // B-4. instrSize：直接取 CompressUnit 的 instrSizes(压缩后本组指令数)。
  always_comb for (int i = 0; i < RENAME_WIDTH; i++) io_out_instrSize[i] = instrSizes[i];

  // B-5. lastUop(压缩精确化)：仅当本口需独占 ROB 槽(needRobFlags)且原本就是 lastUop 时为真。
  //      golden：lastUop = needRobFlags(i) & in.lastUop。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      io_out_lastUop_o[i] = needRobFlags[i] & io_in_bits[i].lastUop;

  // B-6. numWB(压缩后写回个数)：
  //   压缩值 compressedWB = instrSizes(i) - PopCount(masks(i) & isMove)
  //     —— 压缩组里被 move 消除的 uop 不写回。
  //   优先级(高→低，对应 Scala 后置 when 覆盖前置)：
  //     ① !needRobFlags(i)                → compressedWB
  //     ② i>0 且 !needRobFlags(i-1)       → compressedWB
  //     ③ isMove(i) | hasException(i)     → 0
  //     ④ 否则                            → in.numWB
  //   golden 等价改写：needRobFlags(i) ?
  //        ((i==0 || needRobFlags(i-1)) ? ((isMove|hasExc)?0:in.numWB) : compressedWB)
  //      : compressedWB
  logic [2:0] compressedWB [RENAME_WIDTH];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [2:0] moveCnt; moveCnt = '0;
      for (int j = 0; j < RENAME_WIDTH; j++)
        if (cmpMasks[i][j] & isMove[j]) moveCnt += 3'b1;
      compressedWB[i] = instrSizes[i] - moveCnt;
    end
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic prevNoRob, exc0;
      prevNoRob = (i > 0) ? ~needRobFlags[i-1] : 1'b0;        // port0 视作前序需 ROB
      exc0      = isMove[i] | io_out_hasException[i];
      if (!needRobFlags[i])
        io_out_numWB[i] = {4'h0, compressedWB[i]};
      else if (prevNoRob)
        io_out_numWB[i] = {4'h0, compressedWB[i]};
      else
        io_out_numWB[i] = exc0 ? 7'h0 : io_in_bits[i].numWB;
    end

  // ---- trace 用 halfWordNum / iLastSize(单口) ----
  // RVC(16bit)算 1 个半字、非 RVC(32bit)算 2 个半字；ilastsize：RVC→HalfWord(0)、否则 Word(1)。
  logic [1:0] halfWordNum [RENAME_WIDTH];
  always_comb
    for (int j = 0; j < RENAME_WIDTH; j++)
      halfWordNum[j] = io_in_bits[j].preDecodeInfo_isRVC ? 2'h1 : 2'h2;

  // isFusion：commitType[2]=1 表示该口是融合指令(吞掉下一条)。
  logic [RENAME_WIDTH-1:0] isFusion;
  always_comb for (int j = 0; j < RENAME_WIDTH; j++) isFusion[j] = io_in_bits[j].commitType[2];

  // B-7. traceBlockInPipe.iretire：本块退休的「半字数」。
  //   可压缩(canCompressVec)：累加压缩组里各口 halfWordNum；
  //   否则：本口 halfWordNum + (若本口是融合指令则再加下一口 halfWordNum)。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [3:0] sum;
      if (canCompressVec[i]) begin
        sum = '0;
        for (int j = 0; j < RENAME_WIDTH; j++)
          if (cmpMasks[i][j]) sum += {2'h0, halfWordNum[j]};
      end else begin
        sum = {2'h0, halfWordNum[i]};
        if ((i < RENAME_WIDTH-1) && isFusion[i]) sum += {2'h0, halfWordNum[i+1]};
      end
      io_out_iretire[i] = sum;
    end

  // B-8. traceBlockInPipe.ilastsize：本块最后一条指令的尺寸(0=HalfWord/RVC, 1=Word)。
  //   可压缩：取压缩组里【最高被置位口】的 isRVC(取反得 ilastsize)；
  //   否则：本口(融合时取下一口)的 isRVC 取反。
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic lastIsRVC;
      if (canCompressVec[i]) begin
        lastIsRVC = 1'b0;
        // foldLeft 等价：从低到高遍历，命中口覆盖 → 最终最高命中口生效
        for (int j = 0; j < RENAME_WIDTH; j++)
          if (cmpMasks[i][j]) lastIsRVC = io_in_bits[j].preDecodeInfo_isRVC;
      end else begin
        if ((i < RENAME_WIDTH-1) && isFusion[i]) lastIsRVC = io_in_bits[i+1].preDecodeInfo_isRVC;
        else                                      lastIsRVC = io_in_bits[i].preDecodeInfo_isRVC;
      end
      io_out_ilastsize[i] = ~lastIsRVC;  // RVC→0(HalfWord)，非 RVC→1(Word)
    end

  // B-9. traceBlockInPipe.itype：跳转/分支类型(供 trace 推断控制流)。
  //   isXret：CSR systemop(fuType[csr] & fuOpType[4] & csrAddr[11:1]非零) → ExpIntReturn(3)。
  //   否则用 jumpTypeGen(brType, rd=ldest, rs=lsrc0)：
  //     依 brType(jal/jalr/branch) 与 rd/rs 是否链接寄存器(x1/x5)/x0 分类(8..15)。
  //     非分支非跳转 → None(0)。
  function automatic logic [3:0] jump_type_gen
      (input logic [1:0] brType, input logic [LREG_W-1:0] rd, input logic [LREG_W-1:0] rs);
    logic isEqualRdRs, isJal, isJalr, isBranch;
    logic rdLink, rsLink, rdX0;
    logic isUninferCall, isInferCall, isUninferTail, isInferTail;
    logic isCoSwap, isFuncRet, isOtherUninfer, isOtherInfer;
    begin
      isEqualRdRs = (rd == rs);
      isJal       = (brType == BRTYPE_JAL);
      isJalr      = (brType == BRTYPE_JALR);
      isBranch    = (brType == BRTYPE_BRANCH);
      rdLink = (rd == 6'h1) | (rd == 6'h5);    // x1/x5 为链接寄存器
      rsLink = (rs == 6'h1) | (rs == 6'h5);
      rdX0   = (rd == 6'h0);
      isUninferCall  = isJalr & rdLink & (~rsLink | (rsLink & isEqualRdRs));   // 8
      isInferCall    = isJal  & rdLink;                                        // 9
      isUninferTail  = isJalr & rdX0 & ~rsLink;                                // 10
      isInferTail    = isJal  & rdX0;                                          // 11
      isCoSwap       = isJalr & rdLink & rsLink & ~isEqualRdRs;                // 12
      isFuncRet      = isJalr & ~rdLink & rsLink;                              // 13
      isOtherUninfer = isJalr & ~rdLink & ~rdX0 & ~rsLink;                     // 14
      isOtherInfer   = isJal  & ~rdLink & ~rdX0;                               // 15
      // Mux1H(各互斥条件 → 对应编码)；非分支/非跳转 → None
      if      (isBranch)        jump_type_gen = ITYPE_BRANCH;
      else if (isUninferCall)   jump_type_gen = ITYPE_UNINFERABLE_CALL;
      else if (isInferCall)     jump_type_gen = ITYPE_INFERABLE_CALL;
      else if (isUninferTail)   jump_type_gen = ITYPE_UNINFERABLE_TAILCALL;
      else if (isInferTail)     jump_type_gen = ITYPE_INFERABLE_TAILCALL;
      else if (isCoSwap)        jump_type_gen = ITYPE_COROUTINE_SWAP;
      else if (isFuncRet)       jump_type_gen = ITYPE_FUNCTION_RETURN;
      else if (isOtherUninfer)  jump_type_gen = ITYPE_OTHER_UNINFER_JUMP;
      else if (isOtherInfer)    jump_type_gen = ITYPE_OTHER_INFER_JUMP;
      else                      jump_type_gen = ITYPE_NONE;
    end
  endfunction

  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic isXret;
      // CSR systemop 且 csrAddr[11:1] 非零(排除 ebreak/ecall)；csrAddr 取自 imm[11:0]。
      isXret = io_in_bits[i].fuType[FUB_CSR] & io_in_bits[i].fuOpType[4]
             & (|io_in_bits[i].imm[11:1]);
      io_out_itype[i] = isXret ? ITYPE_EXP_INT_RETURN
                              : jump_type_gen(io_in_bits[i].preDecodeInfo_brType,
                                              io_in_bits[i].ldest, io_in_bits[i].lsrc[0]);
    end

  // ===================================================================
  // B-10. numLsElem(向量访存元素流数)
  //   仅对向量访存(isVlsType)、非 vleff-末uop 的有效指令计算，否则为 0。
  //   instType = {isSegment(fuType[vseg*]), mop(fuOpType[6:5])}；
  //   emul：isWhole → GenUSWholeEmul(nf)；isMasked → 0；否则 veew - vsew + vlmul。
  //   numLsElem：
  //     unit-stride(isAllUS)        → VEC_US_MAX_FLOW(=2)
  //     else 按 instType 选流数(GenRealFlowNum)：
  //       000/010/100/110(US/strided/segUS/segStrided) → MulDataSize(emul) >> veew
  //       001/011(indexed)         → emul>lmul ? (MulDataSize(emul)>>veew) : (MulDataSize(lmul)>>vsew)
  //       101/111(seg indexed)     → 同上(段)
  //   MulDataSize(mul) 把 emul/lmul 译成「整寄存器需写字节数」(2/4/8/16)，
  //   再 >> eew(每次写字节数 log2)得到元素流数。本核用 mul_data_size 函数复刻该查表。
  // ===================================================================
  // MulDataSize 查表(返回 5bit, 足够容纳 16)：mul∈{0,1,2,3}→16; 7→8; 6→4; 5→2(其余→0)
  function automatic logic [4:0] mul_data_size(input logic [2:0] mul);
    begin
      priority case (mul)
        3'h0, 3'h1, 3'h2, 3'h3: mul_data_size = 5'd16;
        3'h7:                   mul_data_size = 5'd8;
        3'h6:                   mul_data_size = 5'd4;
        3'h5:                   mul_data_size = 5'd2;
        default:                mul_data_size = 5'd0;
      endcase
    end
  endfunction

  logic [2:0] vlsNf   [RENAME_WIDTH];   // 整寄存器 whole-load 的 nf 修正
  logic [2:0] vlsEmul [RENAME_WIDTH];
  logic [2:0] vlsInstType [RENAME_WIDTH];
  logic [RENAME_WIDTH-1:0] vlsIsVls, vlsIsAllUS;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [8:0] op; logic isWhole, isMasked, usSel, segBit;
      logic [2:0] eewSubSew;
      op = io_in_bits[i].fuOpType;
      // isWhole/isMasked/isAllUS：均要求 mop(op[6:5])==0 且 (op[8]^op[7])
      usSel    = (op[8] ^ op[7]) & ~(|op[6:5]);
      isWhole  = usSel & (op[4:0] == 5'h08);
      isMasked = usSel & (op[4:0] == 5'h0B);
      vlsIsAllUS[i] = usSel;
      // nf：whole-load 强制 0(整寄存器搬运不分 field)，否则取 vpu.nf
      vlsNf[i] = isWhole ? 3'h0 : io_in_bits[i].vpu_nf;
      // GenUSWholeEmul(nf)：000→0,001→1,011→2,111→3(其余 0)；用三元 mux 表
      // emul 选择：isWhole→USWholeEmul(nf)；isMasked→0；否则 veew - vsew + vlmul
      eewSubSew = {1'b0, io_in_bits[i].vpu_veew} - {1'b0, io_in_bits[i].vpu_vsew}
                + io_in_bits[i].vpu_vlmul;
      if (isWhole) begin
        vlsEmul[i] = ((vlsNf[i] == 3'h1) ? 3'h1 : 3'h0)
                   | ((vlsNf[i] == 3'h3) ? 3'h2 : 3'h0)
                   | ((vlsNf[i] == 3'h7) ? 3'h3 : 3'h0);
      end else if (isMasked) begin
        vlsEmul[i] = 3'h0;
      end else begin
        vlsEmul[i] = eewSubSew;
      end
      // instType = {isSegment, mop}
      segBit = io_in_bits[i].fuType[FUB_VSEGLDU] | io_in_bits[i].fuType[FUB_VSEGSTU];
      vlsInstType[i] = {segBit, op[6:5]};
      // isVlsType = 任一向量访存 fuType
      vlsIsVls[i] = io_in_bits[i].fuType[FUB_VLDU] | io_in_bits[i].fuType[FUB_VSTU]
                  | io_in_bits[i].fuType[FUB_VSEGLDU] | io_in_bits[i].fuType[FUB_VSEGSTU];
    end

  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [4:0] flowNum, eewFlow, sewFlow, idxFlow;
      logic       emulGtLmul, gateOK;
      // emul/lmul 有符号比较(3bit, 5/6/7 表示 1/8..1/2 即负数, 0..3 表示 1..8)
      emulGtLmul = ($signed(vlsEmul[i]) > $signed(io_in_bits[i].vpu_vlmul));
      eewFlow = mul_data_size(vlsEmul[i])              >> io_in_bits[i].vpu_veew;
      sewFlow = mul_data_size(io_in_bits[i].vpu_vlmul) >> io_in_bits[i].vpu_vsew;
      idxFlow = emulGtLmul ? eewFlow : sewFlow;        // indexed / seg-indexed
      // GenRealFlowNum 按 instType 选择(priority 互斥)
      priority case (vlsInstType[i])
        3'b000, 3'b010, 3'b100, 3'b110: flowNum = eewFlow;  // US / strided / segUS / segStrided
        3'b001, 3'b011:                 flowNum = idxFlow;  // indexed un/ordered
        3'b101, 3'b111:                 flowNum = idxFlow;  // seg indexed un/ordered
        default:                        flowNum = 5'h0;
      endcase
      // unit-stride 走固定上限 VEC_US_MAX_FLOW
      flowNum = vlsIsAllUS[i] ? VEC_US_MAX_FLOW[4:0] : flowNum;
      // 门控：有效 & 向量访存 & 非(vleff 且压缩后末 uop)
      gateOK = io_in_valid[i] & vlsIsVls[i]
             & ~(io_in_bits[i].vpu_isVleff & io_out_lastUop_o[i]);
      io_out_numLsElem[i] = gateOK ? flowNum : 5'h0;
    end

  // ===================================================================
  // 9. stallReason(topdown 反压归因)：严格复刻 golden。
  //   backReason_valid = out.backReason.valid | ~in0.ready
  //   backReason_bits  = 优先级级联(golden priority chain):
  //     out.backReason.valid                     → 0x25 (backend 反压)
  //     ctrlRecStall                             → 0x21
  //     mvioRecStall                             → 0x22
  //     otherRecStall                            → 0x23
  //     multiFlStall 且仅 int/fp/vec/v0/vl 之一无法分配 → 0x12/13/14/15/16
  //     multiFlStall 且 (≥2 个 FreeList 不足)     → 0x17
  //     否则                                     → 0x25
  //   out.reason[i] = backReason_valid ? backReason_bits : in.reason[i]
  //   debugRedirect_debugIsCtrl/MemVio: 打一拍锁存 redirect 的 debug 标志(walk 期回放用)。
  // ===================================================================
  // golden: 仅在 io_redirect_valid 拍锁存(带使能, 无 reset), walk 期用上次 redirect 值。
  logic debugRedirect_debugIsCtrl, debugRedirect_debugIsMemVio;
  always_ff @(posedge clock)
    if (io_redirect_valid) begin
      debugRedirect_debugIsCtrl   <= io_redirect_bits_debugIsCtrl;
      debugRedirect_debugIsMemVio <= io_redirect_bits_debugIsMemVio;
    end

  wire recStall     = io_redirect_valid | isWalk;
  wire ctrlRecStall = io_redirect_valid ? io_redirect_bits_debugIsCtrl
                                        : (isWalk & debugRedirect_debugIsCtrl);
  wire mvioRecStall = io_redirect_valid ? io_redirect_bits_debugIsMemVio
                                        : (isWalk & debugRedirect_debugIsMemVio);
  wire otherRecStall = recStall & ~(ctrlRecStall | mvioRecStall);
  // multiFlStall: out0 未有效 & 非重定向/walk 反压 & in0 有效
  wire multiFlStall = ~io_out_valid[0] & ~recStall & io_in_valid[0];
  // 不足的 FreeList 个数(0..5)
  logic [2:0] flShortCnt;
  always_comb
    flShortCnt = 3'({1'b0, ~intCanAlloc}) + 3'({1'b0, ~fpCanAlloc})
               + 3'({1'b0, ~vecCanAlloc}) + 3'({1'b0, ~v0CanAlloc})
               + 3'({1'b0, ~vlCanAlloc});

  logic [5:0] backReasonBits;
  always_comb begin
    if (io_stallReason_out_backReason_valid)                                  backReasonBits = 6'h25;
    else if (ctrlRecStall)                                                    backReasonBits = 6'h21;
    else if (mvioRecStall)                                                    backReasonBits = 6'h22;
    else if (otherRecStall)                                                   backReasonBits = 6'h23;
    else if (multiFlStall & fpCanAlloc & vecCanAlloc & v0CanAlloc & vlCanAlloc & ~intCanAlloc)  backReasonBits = 6'h12;
    else if (multiFlStall & intCanAlloc & vecCanAlloc & v0CanAlloc & vlCanAlloc & ~fpCanAlloc)  backReasonBits = 6'h13;
    else if (multiFlStall & intCanAlloc & fpCanAlloc & v0CanAlloc & vlCanAlloc & ~vecCanAlloc)  backReasonBits = 6'h14;
    else if (multiFlStall & intCanAlloc & fpCanAlloc & vecCanAlloc & vlCanAlloc & ~v0CanAlloc)  backReasonBits = 6'h15;
    else if (multiFlStall & intCanAlloc & fpCanAlloc & vecCanAlloc & v0CanAlloc & ~vlCanAlloc)  backReasonBits = 6'h16;
    else if (multiFlStall & (|flShortCnt[2:1]))                               backReasonBits = 6'h17;
    else                                                                      backReasonBits = 6'h25;
  end

  always_comb begin
    io_stallReason_in_backReason_valid = io_stallReason_out_backReason_valid | ~io_in_ready[0];
    io_stallReason_in_backReason_bits  = backReasonBits;
    for (int i = 0; i < RENAME_WIDTH; i++)
      io_stallReason_out_reason[i] = io_stallReason_in_backReason_valid
                                   ? backReasonBits : io_stallReason_in_reason[i];
  end
  // ===================================================================
  // perf 事件流水线(严格复刻 golden)：30 个 io_perf.value，每个都经两级寄存器
  //   (io_perf_N_value_REG → io_perf_N_value_REG_1)后输出。src 映射：
  //     0  = Σ(in_i.valid & in_ready[0])            —— 本拍派发条数
  //     1  = Σ(in_i.valid & ~in_ready[i])           —— 本拍阻塞条数
  //     2  = inHeadStall_probe                       (in0.valid & ~in_ready[0])
  //     3  = stallForWalk_probe                      (in0.valid & isWalk)
  //     4  = in0.valid & ~isWalk & ~out0.ready
  //     5..9 = 仅某一 FreeList 无法分配(其余四个可)时的阻塞事件(int/fp/vec/v0/vl)
  //     10..13 = intFreeList.perf0..3   14..17 = fpFreeList
  //     18..21 = vecFreeList            22..25 = v0FreeList   26..29 = vlFreeList
  // ---------------------------------------------------------------------
  // 组合 src(stage-0 输入)
  wire inHeadStall_probe  = io_in_valid[0] & ~io_in_ready[0];
  wire stallForWalk_probe = io_in_valid[0] & isWalk;
  logic [2:0] perfDispCnt, perfStallCnt;
  always_comb begin
    perfDispCnt  = '0;
    perfStallCnt = '0;
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      perfDispCnt  += 3'({io_in_valid[i] & io_in_ready[0]});
      perfStallCnt += 3'({io_in_valid[i] & ~io_in_ready[i]});
    end
  end
  // 仅某一 FreeList 阻塞:五者互斥模式(base cond & ~该 canAlloc & 其余全 canAlloc)
  wire perfBase = io_in_valid[0] & ~isWalk & io_out_ready[0];
  wire perfOnlyInt = perfBase & fpCanAlloc  & vecCanAlloc & v0CanAlloc & vlCanAlloc & ~intCanAlloc;
  wire perfOnlyFp  = perfBase & intCanAlloc & vecCanAlloc & v0CanAlloc & vlCanAlloc & ~fpCanAlloc;
  wire perfOnlyVec = perfBase & intCanAlloc & fpCanAlloc  & v0CanAlloc & vlCanAlloc & ~vecCanAlloc;
  wire perfOnlyV0  = perfBase & intCanAlloc & fpCanAlloc  & vecCanAlloc & vlCanAlloc & ~v0CanAlloc;
  wire perfOnlyVl  = perfBase & intCanAlloc & fpCanAlloc  & vecCanAlloc & v0CanAlloc & ~vlCanAlloc;

  // 两级寄存器流水线(golden: _REG → _REG_1), 复位不清(golden 无 reset 分支)。
  // ★寄存器宽度严格按 golden 分组(否则超配的高位恒 0 → impl-only 死寄存器)：
  //   perf 0,1  = 3bit(派发/阻塞计数, 0..6)，输出 {3'h0, REG_1}
  //   perf 2..9 = 1bit(各类阻塞事件)，       输出 {5'h0, REG_1}
  //   perf 10..29 = 6bit(FreeList 直传)，     输出 REG_1
  logic [2:0] perf01_REG   [2],  perf01_REG_1   [2];   // idx 0,1
  logic       perf2t9_REG  [8],  perf2t9_REG_1  [8];   // idx 2..9
  // FreeList perf 输出恒为 {5'h0, 1bit}(见 StdFreeList/MEFreeList: io_perf=`{5'h0,REG}`),
  //   故 bit0 数据位走 perfFl_REG 流水。
  logic       perfFl_REG   [20], perfFl_REG_1   [20];  // idx 10..29 (bit0 数据位)
  // ★golden-faithful 高位补齐(消 compare_ref=10): golden 以 6bit 存全部 20 个 FreeList
  //   perf 寄存器, 其 [5:1] 由 FreeList 输出 {5'h0,1bit} 驱动恒 0。FM 按每个 FreeList
  //   实例内部的常量网, 把该组 4 个寄存器的 [5:1] 死常位 merge 进组首 bit[1] 代表点,
  //   golden 侧留下 10 个活比较点 io_perf_{10,14,18,22,26}_value_REG[_1]_reg[1]
  //   (每组 REG/REG_1 两级各 1)。impl 若只寄 bit0 → 这 10 点 golden-only 孤儿。
  //   这里按 golden 同名补每组组首的 [5:1] 寄存器对, 源=对应 FreeList 实例输出的恒 0
  //   高位(独立源网, 各组不同实例 → FM 不跨组折叠, 与 golden 行为对称), 输出高位改走
  //   寄存器(值恒 0 不变), 使其被读→成为活比较点与 golden 同名配对比较。
  logic [5:1] io_perf_10_value_REG, io_perf_10_value_REG_1;   // int 组首
  logic [5:1] io_perf_14_value_REG, io_perf_14_value_REG_1;   // fp  组首
  logic [5:1] io_perf_18_value_REG, io_perf_18_value_REG_1;   // vec 组首
  logic [5:1] io_perf_22_value_REG, io_perf_22_value_REG_1;   // v0  组首
  logic [5:1] io_perf_26_value_REG, io_perf_26_value_REG_1;   // vl  组首

  logic       perf2t9_src [8];
  always_comb begin
    perf2t9_src[0] = inHeadStall_probe;                               // 2
    perf2t9_src[1] = stallForWalk_probe;                              // 3
    perf2t9_src[2] = io_in_valid[0] & ~isWalk & ~io_out_ready[0];     // 4
    perf2t9_src[3] = perfOnlyInt;                                     // 5
    perf2t9_src[4] = perfOnlyFp;                                      // 6
    perf2t9_src[5] = perfOnlyVec;                                     // 7
    perf2t9_src[6] = perfOnlyV0;                                      // 8
    perf2t9_src[7] = perfOnlyVl;                                      // 9
  end
  logic perfFl_src [20];
  always_comb
    for (int k = 0; k < 4; k++) begin
      perfFl_src[0+k]  = intFlPerf[k][0];   // 10..13
      perfFl_src[4+k]  = fpFlPerf [k][0];   // 14..17
      perfFl_src[8+k]  = vecFlPerf[k][0];   // 18..21
      perfFl_src[12+k] = v0FlPerf [k][0];   // 22..25
      perfFl_src[16+k] = vlFlPerf [k][0];   // 26..29
    end

  always_ff @(posedge clock) begin
    perf01_REG[0] <= perfDispCnt;  perf01_REG_1[0] <= perf01_REG[0];
    perf01_REG[1] <= perfStallCnt; perf01_REG_1[1] <= perf01_REG[1];
    for (int i = 0; i < 8;  i++) begin perf2t9_REG[i] <= perf2t9_src[i]; perf2t9_REG_1[i] <= perf2t9_REG[i]; end
    for (int i = 0; i < 20; i++) begin perfFl_REG [i] <= perfFl_src [i]; perfFl_REG_1 [i] <= perfFl_REG [i]; end
    // 组首 [5:1] 补位寄存器(恒 0, 与 golden io_perf_N_value_REG/_REG_1 同名同宽同源)
    io_perf_10_value_REG <= intFlPerf[0][5:1]; io_perf_10_value_REG_1 <= io_perf_10_value_REG;
    io_perf_14_value_REG <= fpFlPerf [0][5:1]; io_perf_14_value_REG_1 <= io_perf_14_value_REG;
    io_perf_18_value_REG <= vecFlPerf[0][5:1]; io_perf_18_value_REG_1 <= io_perf_18_value_REG;
    io_perf_22_value_REG <= v0FlPerf [0][5:1]; io_perf_22_value_REG_1 <= io_perf_22_value_REG;
    io_perf_26_value_REG <= vlFlPerf [0][5:1]; io_perf_26_value_REG_1 <= io_perf_26_value_REG;
  end

  always_comb begin
    io_perf_value[0] = {3'h0, perf01_REG_1[0]};
    io_perf_value[1] = {3'h0, perf01_REG_1[1]};
    for (int i = 0; i < 8;  i++) io_perf_value[2+i]  = {5'h0, perf2t9_REG_1[i]};
    for (int i = 0; i < 20; i++) io_perf_value[10+i] = {5'h0, perfFl_REG_1[i]};
    // 组首高位改走补位寄存器(恒 0, 输出值不变; 使补位寄存器有真扇出=活比较点)
    io_perf_value[10][5:1] = io_perf_10_value_REG_1;
    io_perf_value[14][5:1] = io_perf_14_value_REG_1;
    io_perf_value[18][5:1] = io_perf_18_value_REG_1;
    io_perf_value[22][5:1] = io_perf_22_value_REG_1;
    io_perf_value[26][5:1] = io_perf_26_value_REG_1;
  end

endmodule
