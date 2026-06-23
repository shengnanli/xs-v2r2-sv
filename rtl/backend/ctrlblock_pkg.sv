// ============================================================================
// ctrlblock_pkg —— 香山 V2R2 后端控制块（CtrlBlock）类型与参数包
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/backend/CtrlBlock.scala
//   （class CtrlBlock / class CtrlBlockImp）
//
// CtrlBlock 是后端「控制平面」总集成：把译码（DecodeStage）、融合译码
// （FusionDecoder）、重命名表（RenameTableWrapper）、重命名（Rename）、派遣
// （NewDispatch）、重排序缓冲（Rob）、重定向生成（RedirectGenerator）、PC 存储
// （pcMem）、内存依赖预测控制（MemCtrl）、快照（SnapshotGenerator）、Trace 等
// 子模块组装起来，做流水连接、重定向广播、异常/flush 路由与各级握手。
//
// 本包只放**架构常量与少量聚合类型**。CtrlBlock 的端口极宽（2522 个扁平端口，
// 多为子模块直通），故端口与子模块例化连线落在 ctrlblock_ports.svh /
// ctrlblock_inst.svh；真正属于「顶层 glue」的逻辑（重定向流水、decode buffer
// 状态机、写回打拍/压缩、快照选择、frontend flush 路由）落在可读核
// xs_CtrlBlock_core，用本包的参数 + struct/enum/function 表达。
// ============================================================================
package ctrlblock_pkg;

  // ----- 顶层宽度参数（昆明湖 V2R2 默认配置，与 golden 端口宽度一致）-----
  localparam int DecodeWidth   = 6;   // 译码 / 重命名 / 提交宽度
  localparam int RenameWidth   = 6;
  localparam int CommitWidth   = 6;
  localparam int RabCommitWidth = 6;
  localparam int FtqSize       = 64;  // FTQ 表项数（pcMem 深度）
  localparam int FtqPtrW       = 6;   // log2(FtqSize)
  localparam int VAddrBits     = 50;
  localparam int RobIdxW       = 8;   // RobPtr value 位宽（不含 flag）
  localparam int RobPtrW       = 8;   // RobPtr 总位宽（含 flag）

  // 重定向来源：jmp/brh exu redirect（NumRedirect 路）+ loadReplay（1）+ exception（1）
  localparam int NumRedirect   = 1;   // BackendRedirectNum-2 = jmp/brh 选最旧后只剩 1 路读口
  localparam int BackendRedirectNum = 3;  // ftqIdxAhead 路数 = jmp/brh + loadReplay + exception
  localparam int WbNum         = 27;  // io_fromWB_wbData 路数（index 0..26）

  localparam int InstOffsetBits = 1;  // RVC：PC 偏移以 2 字节为单位

  // ----- 重定向 level（RedirectLevel）-----
  // flushAfter：冲掉本条之后的指令（误预测分支自身仍执行）
  // flush     ：连本条一起冲（异常 / replay 自身）
  typedef enum logic {
    REDIR_FLUSH_AFTER = 1'b0,
    REDIR_FLUSH       = 1'b1
  } redirect_level_e;

  // ----- decode buffer 接收来源（用于 decode.io.in 的选择）-----
  // 当 decode buffer 头部有效时，DecodeStage 输入取自 buffer；否则取自 frontend。
  typedef enum logic {
    DECIN_FROM_BUF      = 1'b0,
    DECIN_FROM_FRONTEND = 1'b1
  } decin_src_e;

  // ----- 融合指令 commitType 编码（rename.io.in.bits.commitType 的 4 种取值）-----
  // 由相邻两条指令的 ftqPtr/ftqOffset 关系决定，用于 FTQ 更新。
  localparam logic [2:0] FUSE_COMMIT_SAME_OFF1 = 3'd4; // 同 ftqPtr, offset 差 1
  localparam logic [2:0] FUSE_COMMIT_SAME_OFF2 = 3'd5; // 同 ftqPtr, offset 差 2
  localparam logic [2:0] FUSE_COMMIT_DIFF_OFF0 = 3'd6; // 跨 ftqPtr, 次条 offset=0
  localparam logic [2:0] FUSE_COMMIT_DIFF_OFF1 = 3'd7; // 跨 ftqPtr, 次条 offset=1

  localparam int RenameSnapshotNum = 4;   // 快照槽位数(snpt io_valids_0..3)

  // ==========================================================================
  // 数据通路 glue 用聚合类型(round3 新增)
  // --------------------------------------------------------------------------
  // CtrlBlock 里有两条「打一拍 + 字段直通」的宽数据通路:
  //   (1) 写回回流到 Rob:io.fromWB.wbData[i] --RegEnable--> delayedNotFlushedWriteBack。
  //   (2) 派遣到 Rob 入队:dispatch.io.enqRob.req[i] --RegEnable--> rob.io.enq.req[i]。
  // golden 把这两条展开成上千个标量寄存器(_r_/_T_ 临时名)。为可读,我们把每路
  // 的全部字段收进一个 struct,用一条 RegEnable(整 struct)表达打拍,字段名表意。
  // 各 FU 的写回/uop 字段集合不同(异构),这里用「并集 struct」:某路不存在的字段
  // 在打包时驱 0,Rob 端只读它实际接的字段,功能等价且更易读。
  // ==========================================================================

  // ----- 写回回 Rob 的 ExuOutput 并集(io.fromWB.wbData[i].bits 全字段)-----
  // 共 27 路写回(WbNum),其中 0..24 暴露完整 robIdx(flag+value),25/26 为 Std FU
  // (只有 robIdx.value)。本 struct 覆盖 27 路中出现过的全部 bits 字段。
  typedef struct packed {
    // -- robIdx / 目的寄存器 --
    logic        robIdx_flag;
    logic [7:0]  robIdx_value;
    logic [6:0]  pdest;
    // -- 异常向量(ExceptionVec,稀疏出现 0..23 共 24 位中实际用到的下标)--
    logic [23:0] exceptionVec;          // 收成一个 24 位向量,按下标置位
    // -- flush / replay / 浮点标志 --
    logic        flushPipe;
    logic        replay;
    logic [4:0]  fflags;
    logic        wflags;
    logic        vxsat;
    logic [3:0]  trigger;
    logic        v0Wen;
    logic        vecWen;
    // -- 调试/性能 --
    logic        debug_isMMIO;
    logic        debug_isNCIO;
    logic        debug_isPerfCnt;
    logic [63:0] debugInfo_enqRsTime;
    logic [63:0] debugInfo_issueTime;
    logic [63:0] debugInfo_selectTime;
    // -- 向量 load/store 信息(vls)--
    logic        vls_isIndexed;
    logic        vls_isStrided;
    logic        vls_isVecLoad;
    logic        vls_isVlm;
    logic        vls_isWhole;
    logic [2:0]  vls_vdIdx;
    logic [2:0]  vls_vpu_nf;
    logic [1:0]  vls_vpu_veew;
    logic [2:0]  vls_vpu_vlmul;
    logic [1:0]  vls_vpu_vsew;
    logic [7:0]  vls_vpu_vstart;
    logic [6:0]  vls_vpu_vuopIdx;
    // -- 后端重定向(部分写回口携带 cfiUpdate,用于 exuRedirect 选最旧)--
    logic        redirect_valid;
    logic        redirect_bits_robIdx_flag;
    logic [7:0]  redirect_bits_robIdx_value;
    logic        redirect_bits_ftqIdx_flag;
    logic [5:0]  redirect_bits_ftqIdx_value;
    logic [3:0]  redirect_bits_ftqOffset;
    logic        redirect_bits_level;
    logic        redirect_bits_cfiUpdate_isMisPred;
    logic        redirect_bits_cfiUpdate_taken;
    logic        redirect_bits_cfiUpdate_backendIAF;
    logic        redirect_bits_cfiUpdate_backendIPF;
    logic        redirect_bits_cfiUpdate_backendIGPF;
    logic [49:0] redirect_bits_cfiUpdate_pc;
    logic [49:0] redirect_bits_cfiUpdate_target;
    logic [63:0] redirect_bits_fullTarget;
  } wb_exu_output_t;

  // ----- 派遣入 Rob 的 uop 并集(dispatch.io.enqRob.req[i].bits 全字段)-----
  // RenameWidth=6 路,字段对所有路一致,仅 snapshot 只在第 0 路出现。
  typedef struct packed {
    logic        robIdx_flag;
    logic [7:0]  robIdx_value;
    logic [7:0]  pdest;
    logic [5:0]  ldest;
    logic [31:0] instr;
    logic [2:0]  instrSize;
    logic [34:0] fuType;
    logic [8:0]  fuOpType;
    logic [2:0]  commitType;
    logic        ftqPtr_flag;
    logic [5:0]  ftqPtr_value;
    logic [3:0]  ftqOffset;
    logic [6:0]  numWB;
    // -- 写回/脏标志 --
    logic        rfWen;
    logic        fpWen;
    logic        vecWen;
    logic        v0Wen;
    logic        vlWen;
    logic        dirtyFs;
    logic        dirtyVs;
    // -- 异常 / 控制流属性 --
    logic        hasException;
    logic [22:0] exceptionVec;          // 稀疏下标收成位向量(0..22 中用到的位)
    logic        flushPipe;
    logic        blockBackward;
    logic        waitForward;
    logic        isXSTrap;
    logic        crossPageIPFFix;
    logic        isFetchMalAddr;
    logic        singleStep;
    logic        firstUop;
    logic        lastUop;
    logic        isMove;
    logic        eliminatedMove;
    logic        isVset;
    logic        vlsInstr;
    logic        replayInst;
    logic        wfflags;
    logic        preDecodeInfo_isRVC;
    logic        snapshot;               // 仅第 0 路有效
    // -- Trace --
    logic        traceBlockInPipe_ilastsize;
    logic [3:0]  traceBlockInPipe_iretire;
    logic [3:0]  traceBlockInPipe_itype;
    logic [3:0]  trigger;
    // -- 向量配置(vpu / specVConfig)--
    logic        vpu_vill;
    logic [2:0]  vpu_vlmul;
    logic        vpu_vma;
    logic        vpu_vta;
    logic [1:0]  vpu_vsew;
    logic        vpu_specVill;
    logic [2:0]  vpu_specVlmul;
    logic        vpu_specVma;
    logic        vpu_specVta;
    logic [1:0]  vpu_specVsew;
    // -- 调试时间戳(性能剖析用,各级流水盖戳)--
    logic [63:0] debugInfo_renameTime;
    logic [63:0] debugInfo_dispatchTime;
    logic [63:0] debugInfo_enqRsTime;
    logic [63:0] debugInfo_selectTime;
    logic [63:0] debugInfo_issueTime;
    logic [63:0] debugInfo_writebackTime;
  } rob_enq_uop_t;

  // ----- decode buffer 暂存的「译码输入 CtrlFlow」(decodeBufBits)-----
  // decode buffer 是 DecodeStage 之前的一级缓冲:当 DecodeStage 当拍没能吃下
  // frontend 送来的全部指令时,把剩余指令暂存在 buffer,下一拍优先从 buffer 取。
  // buffer 同时跟踪 valid(decodeBufValid,见 logic.svh 块2)与 payload(本 struct)。
  // payload 是 frontend.cfVec 的指令静态信息(StaticInst/CtrlFlow 子集),字段集合
  // 与 io_frontend_cfVec_*_bits_* 对齐;另含 exceptionVec 全 23 位(frontend 只给
  // 1/2/12/20 这几位,其余位 buffer 内默认 0,故 buffer 比 frontend 多出的异常位
  // 在「从 frontend 装载」时清 0,见 logic.svh 块2 的移位状态机)。
  // 字段宽度严格对齐 golden decodeBufBits_*_* 的 reg 声明。
  typedef struct packed {
    logic [31:0] instr;                 // 取指得到的 32 位指令(RVC 已对齐展开)
    logic [9:0]  foldpc;                // 折叠 PC(用于 mdp 哈希等)
    logic [23:0] exceptionVec;          // 异常向量(用到位 0..21,23;位 3/22 恒 0;含 frontend 的 1/2/12/20)
    logic        isFetchMalAddr;        // 取指地址非法
    logic [3:0]  trigger;               // 调试 trigger 命中向量
    logic        preDecodeInfo_isRVC;   // 预译码:是否 RVC
    logic [1:0]  preDecodeInfo_brType;  // 预译码:分支类型
    logic        pred_taken;            // 分支预测:taken
    logic        crossPageIPFFix;       // 跨页取指 page fault 修正标记
    logic        ftqPtr_flag;           // 所属 FTQ 表项指针 flag
    logic [5:0]  ftqPtr_value;          // 所属 FTQ 表项指针 value
    logic [3:0]  ftqOffset;             // 在 FTQ 表项内的偏移
    logic        isLastInFtqEntry;      // 是否 FTQ 表项内最后一条
  } decode_buf_bits_t;

  // ----- 环形队列指针(RobPtr)语义函数(昆明湖 V2R2)-----
  // RobPtr = {flag, value};flag 标记绕回奇偶。比较遵循 XiangShan
  // HasCircularQueuePtrHelper:isAfter/isBefore 用 flag 异或 + value 大小。
  // a 是否严格在 b 之后(a > b):flag 相同时 value 更大;flag 不同时 value 更小。
  //   等价式:differentFlag ^ (a.value > b.value)
  function automatic logic ptr_gt(
      input logic a_flag, input logic [RobIdxW-1:0] a_value,
      input logic b_flag, input logic [RobIdxW-1:0] b_value);
    logic diff_flag;
    logic value_gt;
    diff_flag = a_flag ^ b_flag;
    value_gt  = a_value > b_value;
    ptr_gt    = diff_flag ^ value_gt;
  endfunction

  // RobPtr.needFlush(redirect):该 robIdx 是否被一条更老(或同条且 flushItself)的
  // redirect 冲掉。
  //   redirect.valid &&
  //     (flushItself ? !ptr_gt(redir,this)            // redir<=this(含等于)
  //                  : !ptr_gt(redir,this) && redir!=this) // redir<this(严格更老)
  // 注:flushItself = (level == REDIR_FLUSH)。
  function automatic logic rob_need_flush(
      input logic [RobIdxW-1:0] this_value, input logic this_flag,
      input logic redir_valid, input logic [RobIdxW-1:0] redir_value,
      input logic redir_flag, input logic redir_flushItself);
    logic redir_older;       // redir 比 this 更老(redir < this)
    logic same_idx;          // 同一条
    redir_older = ptr_gt(this_flag, this_value, redir_flag, redir_value);
    same_idx    = (this_flag == redir_flag) && (this_value == redir_value);
    rob_need_flush = redir_valid &&
                     (redir_older || (redir_flushItself && same_idx));
  endfunction

endpackage : ctrlblock_pkg
