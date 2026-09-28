// =====================================================================
// LoadMisalignBuffer.sv —— 跨 16 字节边界的非对齐 load：拆成两个对齐子访问、各自访存、再拼回来（单条目缓冲）
// ---------------------------------------------------------------------
// 位置：MemBlock 里 3 条 LoadUnit 共用 1 个。DCache 一次只能读一个对齐的 16B 块，所以 LoadUnit
//   在 s0 查出"地址不对齐且跨 16B"的 load 时，s1 不读数据、s3 把它交进本缓冲（enq）。
//   没跨 16B 的非对齐 load 不来这里：LoadUnit 当作一次 128 位访问自己做完。
// 与 LoadUnit 的往返（接口语义见 rtl/memblock/LoadUnit.sv 的 SRC_MAB 来源）：
//   splitLoadReq  → LoadUnit s0 的最高优先级来源 SRC_MAB：一个对齐的子访问，照常走 TLB/DCache；
//   splitLoadResp ← LoadUnit s3 送回这个子访问的结果（数据 / 异常 / uncache / 要不要 replay）；
//   最后再发一个 misalignNeedWakeUp 的"唤醒"请求：它不访存，只是借 LoadUnit 的流水拿到写回口、
//   唤醒依赖者；它回到 s3 的那一拍（splitLoadResp.misalignNeedWakeUp）本缓冲把拼好的数据写回。
// 状态机（bufferState）：
//   s_idle → s_split（算出低/高两个对齐子访问）→ s_req（发 curPtr 指向的那个）→ s_resp（等它回来）
//     → 还有没发的 / 要 replay：回 s_req；两个都回来了：s_comb_wakeup_rep（拼数据；标量再发唤醒请求）
//     → s_wb（标量写 ROB / 向量写 vecWriteBack）→ s_idle
//   子访问报异常或落在 uncache 空间：立刻 s_wb 带异常写回（uncache 一律报 loadAddrMisaligned 交软件）。
//   任何时刻 redirect 冲掉本条目：回 s_idle。
// 本配置（KunminghuV2Config）下 firtool 删掉了上层没接的输出：io.rob、overwriteExpBuf、
//   flushLdExpBuff、loadMisalignFull，以及 writeBack 里 isFromLoadUnit 等字段；vecWriteBack.ready
//   在上层恒 1，所以没有这个端口（fire == valid）。
// 文件结构：loadmisalignbuffer_pkg → xs_LoadMisalignBuffer_core（手写可读核）→ golden 同名 wrapper（生成）。
//   GENERATED 段由 scripts/gen_lmisalign.py 从 golden 端口表/寄存器表生成（--check 查漂移）。
// =====================================================================
// 本文件导航（按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位；行号由生成器维护）：
// BEGIN GENERATED(nav) —— scripts/gen_lmisalign.py 生成，勿手改
//   L42    loadmisalignbuffer_pkg：常量、状态编码、接口 struct、拆分方案表与小工具函数
//   L501   xs_LoadMisalignBuffer_core —— 可读核：全部状态
//   L570   §1 入队
//   L599   §2 状态机
//   L666   §3 拆分成两个对齐子访问
//   L714   §4 发请求
//   L731   §5 收响应：异常 / uncache / replay
//   L847   §6 结果拼接
//   L878   §7 写回
//   L919   §8 整包寄存器（生成）
//   L3080  golden 同名 wrapper（生成）
// END GENERATED(nav)
// =====================================================================

package loadmisalignbuffer_pkg;

  // ---------------- 常量 ----------------
  localparam int NUM_ENQ = 3;           // LoadPipelineWidth：3 条 load 流水都能往里塞
  localparam int XLEN    = 64;

  // 访问宽度编码（fuOpType[1:0] / alignedType[1:0]）
  localparam logic [1:0] SZ_B = 2'b00;
  localparam logic [1:0] SZ_H = 2'b01;
  localparam logic [1:0] SZ_W = 2'b10;
  localparam logic [1:0] SZ_D = 2'b11;

  // LSUOpType（xiangshan/package.scala）：结果扩展方式由它决定
  localparam logic [8:0] OP_LB     = 9'h00;
  localparam logic [8:0] OP_LH     = 9'h01;
  localparam logic [8:0] OP_LW     = 9'h02;
  localparam logic [8:0] OP_LD     = 9'h03;
  localparam logic [8:0] OP_LBU    = 9'h04;
  localparam logic [8:0] OP_LHU    = 9'h05;
  localparam logic [8:0] OP_LWU    = 9'h06;
  localparam logic [8:0] OP_HLVB   = 9'h10;
  localparam logic [8:0] OP_HLVH   = 9'h11;
  localparam logic [8:0] OP_HLVW   = 9'h12;
  localparam logic [8:0] OP_HLVD   = 9'h13;
  localparam logic [8:0] OP_HLVBU  = 9'h14;
  localparam logic [8:0] OP_HLVHU  = 9'h15;
  localparam logic [8:0] OP_HLVWU  = 9'h16;
  localparam logic [8:0] OP_HLVXHU = 9'h1D;
  localparam logic [8:0] OP_HLVXWU = 9'h1E;

  // 异常号（ExceptionNO）：LduCfg / VlduCfg 只产生这 6 个
  localparam int EXC_BREAKPOINT    = 3;
  localparam int EXC_LD_MISALIGN   = 4;    // loadAddrMisaligned
  localparam int EXC_LD_ACCESS     = 5;
  localparam int EXC_LD_PAGE       = 13;
  localparam int EXC_HW_ERROR      = 19;
  localparam int EXC_LD_GUEST_PAGE = 21;
  localparam logic [23:0] LDU_EXC_MASK = (24'h1 << EXC_BREAKPOINT) | (24'h1 << EXC_LD_MISALIGN)
                                       | (24'h1 << EXC_LD_ACCESS)  | (24'h1 << EXC_LD_PAGE)
                                       | (24'h1 << EXC_HW_ERROR)   | (24'h1 << EXC_LD_GUEST_PAGE);

  localparam logic [3:0] TRIG_ACT_DEBUG_MODE = 4'h1;   // TriggerAction.DebugMode

  // ---------------- 状态机 ----------------
  typedef enum logic [2:0] {
    S_IDLE            = 3'd0,   // 空闲，等入队
    S_SPLIT           = 3'd1,   // 把非对齐 load 拆成低/高两个对齐子访问
    S_REQ             = 3'd2,   // 发 curPtr 指向的子访问
    S_RESP            = 3'd3,   // 等子访问从 LoadUnit s3 回来
    S_COMB_WAKEUP_REP = 3'd4,   // 拼数据；标量再发一个唤醒请求
    S_WB              = 3'd5    // 写回
  } state_e;

  // BEGIN GENERATED(types) —— scripts/gen_lmisalign.py 生成，勿手改
  // DynInst（后端微操作）在本模块出现过的全部字段；各接口只用其中一部分，其余在 wrapper 里补 0 / 丢弃
  typedef struct packed {
    logic [31:0]     instr;
    logic [49:0]     pc;
    logic [9:0]      foldpc;
    logic [23:0]     exceptionVec;
    logic            isFetchMalAddr;
    logic            hasException;
    logic [3:0]      trigger;
    logic            preDecodeInfo_valid;
    logic            preDecodeInfo_isRVC;
    logic [1:0]      preDecodeInfo_brType;
    logic            preDecodeInfo_isCall;
    logic            preDecodeInfo_isRet;
    logic            pred_taken;
    logic            crossPageIPFFix;
    logic            ftqPtr_flag;
    logic [5:0]      ftqPtr_value;
    logic [3:0]      ftqOffset;
    logic            satpFlushFirstFetchFault;
    logic [3:0]      srcType_0;
    logic [3:0]      srcType_1;
    logic [3:0]      srcType_2;
    logic [3:0]      srcType_3;
    logic [3:0]      srcType_4;
    logic [5:0]      ldest;
    logic [34:0]     fuType;
    logic [8:0]      fuOpType;
    logic            rfWen;
    logic            fpWen;
    logic            vecWen;
    logic            v0Wen;
    logic            vlWen;
    logic            isXSTrap;
    logic            waitForward;
    logic            blockBackward;
    logic            flushPipe;
    logic            canRobCompress;
    logic [3:0]      selImm;
    logic [31:0]     imm;
    logic [1:0]      fpu_typeTagOut;
    logic            fpu_wflags;
    logic [1:0]      fpu_typ;
    logic [1:0]      fpu_fmt;
    logic [2:0]      fpu_rm;
    logic            vpu_vill;
    logic            vpu_vma;
    logic            vpu_vta;
    logic [1:0]      vpu_vsew;
    logic [2:0]      vpu_vlmul;
    logic            vpu_specVill;
    logic            vpu_specVma;
    logic            vpu_specVta;
    logic [1:0]      vpu_specVsew;
    logic [2:0]      vpu_specVlmul;
    logic            vpu_vm;
    logic [7:0]      vpu_vstart;
    logic [2:0]      vpu_frm;
    logic            vpu_fpu_isFpToVecInst;
    logic            vpu_fpu_isFP32Instr;
    logic            vpu_fpu_isFP64Instr;
    logic            vpu_fpu_isReduction;
    logic            vpu_fpu_isFoldTo1_2;
    logic            vpu_fpu_isFoldTo1_4;
    logic            vpu_fpu_isFoldTo1_8;
    logic [1:0]      vpu_vxrm;
    logic [6:0]      vpu_vuopIdx;
    logic            vpu_lastUop;
    logic [127:0]    vpu_vmask;
    logic [7:0]      vpu_vl;
    logic [2:0]      vpu_nf;
    logic [1:0]      vpu_veew;
    logic            vpu_isReverse;
    logic            vpu_isExt;
    logic            vpu_isNarrow;
    logic            vpu_isDstMask;
    logic            vpu_isOpMask;
    logic            vpu_isMove;
    logic            vpu_isDependOldVd;
    logic            vpu_isWritePartVd;
    logic            vpu_isVleff;
    logic            vlsInstr;
    logic            wfflags;
    logic            isMove;
    logic            isDropAmocasSta;
    logic [6:0]      uopIdx;
    logic            isVset;
    logic            firstUop;
    logic            lastUop;
    logic [6:0]      numUops;
    logic [6:0]      numWB;
    logic [2:0]      commitType;
    logic            srcState_0;
    logic            srcState_1;
    logic            srcState_2;
    logic            srcState_3;
    logic            srcState_4;
    logic [1:0]      srcLoadDependency_0_0;
    logic [1:0]      srcLoadDependency_0_1;
    logic [1:0]      srcLoadDependency_0_2;
    logic [1:0]      srcLoadDependency_1_0;
    logic [1:0]      srcLoadDependency_1_1;
    logic [1:0]      srcLoadDependency_1_2;
    logic [1:0]      srcLoadDependency_2_0;
    logic [1:0]      srcLoadDependency_2_1;
    logic [1:0]      srcLoadDependency_2_2;
    logic [1:0]      srcLoadDependency_3_0;
    logic [1:0]      srcLoadDependency_3_1;
    logic [1:0]      srcLoadDependency_3_2;
    logic [1:0]      srcLoadDependency_4_0;
    logic [1:0]      srcLoadDependency_4_1;
    logic [1:0]      srcLoadDependency_4_2;
    logic [7:0]      psrc_0;
    logic [7:0]      psrc_1;
    logic [7:0]      psrc_2;
    logic [7:0]      psrc_3;
    logic [7:0]      psrc_4;
    logic [7:0]      pdest;
    logic            useRegCache_0;
    logic            useRegCache_1;
    logic [4:0]      regCacheIdx_0;
    logic [4:0]      regCacheIdx_1;
    logic            robIdx_flag;
    logic [7:0]      robIdx_value;
    logic [2:0]      instrSize;
    logic            dirtyFs;
    logic            dirtyVs;
    logic [3:0]      traceBlockInPipe_itype;
    logic [3:0]      traceBlockInPipe_iretire;
    logic            traceBlockInPipe_ilastsize;
    logic            eliminatedMove;
    logic            snapshot;
    logic            debugInfo_eliminatedMove;
    logic [63:0]     debugInfo_renameTime;
    logic [63:0]     debugInfo_dispatchTime;
    logic [63:0]     debugInfo_enqRsTime;
    logic [63:0]     debugInfo_selectTime;
    logic [63:0]     debugInfo_issueTime;
    logic [63:0]     debugInfo_writebackTime;
    logic [63:0]     debugInfo_runahead_checkpoint_id;
    logic [63:0]     debugInfo_tlbFirstReqTime;
    logic [63:0]     debugInfo_tlbRespTime;
    logic [55:0]     debug_seqNum_seqNum;
    logic [7:0]      debug_seqNum_uopIdx;
    logic            storeSetHit;
    logic            waitForRobIdx_flag;
    logic [7:0]      waitForRobIdx_value;
    logic            loadWaitBit;
    logic            loadWaitStrict;
    logic [4:0]      ssid;
    logic            lqIdx_flag;
    logic [6:0]      lqIdx_value;
    logic            sqIdx_flag;
    logic [5:0]      sqIdx_value;
    logic            singleStep;
    logic            replayInst;
    logic [34:0]     debug_fuType;
    logic            debug_sim_trig;
    logic [4:0]      numLsElem;
  } uop_t;

  // Redirect（后端重定向）：本模块只用 robIdx 与 level
  typedef struct packed {
    logic            robIdx_flag;
    logic [7:0]      robIdx_value;
    logic            level;
  } redirect_t;

  // MisalignBufferEnqIO.req：LoadUnit s3 送进来的非对齐 load（LqWriteBundle 的子集），也是条目本体 req 的类型
  typedef struct packed {
    uop_t            uop;
    logic [49:0]     vaddr;
    logic [63:0]     fullva;
    logic            vaNeedExt;
    logic [47:0]     paddr;
    logic [63:0]     gpaddr;
    logic [15:0]     mask;
    logic            isForVSnonLeafPTE;
    logic            isvec;
    logic [7:0]      elemIdx;
    logic [2:0]      alignedType;
    logic [3:0]      mbIndex;
    logic [7:0]      elemIdxInsideVd;
    logic [15:0]     vecTriggerMask;
  } enq_req_t;

  // LsPipelineBundle：发回 LoadUnit s0 的对齐子访问（两个子访问寄存器 splitLoadReqs 也是这个类型）
  typedef struct packed {
    uop_t            uop;
    logic [49:0]     vaddr;
    logic [63:0]     fullva;
    logic            vaNeedExt;
    logic [47:0]     paddr;
    logic [63:0]     gpaddr;
    logic [15:0]     mask;
    logic            nc;
    logic            mmio;
    logic            memBackTypeMM;
    logic            isForVSnonLeafPTE;
    logic            isvec;
    logic            is128bit;
    logic            vecActive;
    logic [3:0]      mshrid;
    logic [6:0]      schedIndex;
    logic            isFinalSplit;
    logic            misalignNeedWakeUp;
  } split_req_t;

  // LqWriteBundle：子访问从 LoadUnit s3 回来的结果
  typedef struct packed {
    uop_t            uop;
    logic [49:0]     vaddr;
    logic [63:0]     fullva;
    logic            vaNeedExt;
    logic [47:0]     paddr;
    logic [63:0]     gpaddr;
    logic [128:0]    data;
    logic            nc;
    logic            mmio;
    logic            memBackTypeMM;
    logic            isForVSnonLeafPTE;
    logic            vecActive;
    logic            misalignNeedWakeUp;
    logic [10:0]     rep_info_cause;
  } split_resp_t;

  // MemExuOutput：标量写回（写 ROB / 唤醒）
  typedef struct packed {
    uop_t            uop;
    logic [63:0]     data;
    logic            debug_isMMIO;
    logic            debug_isNCIO;
    logic [47:0]     debug_paddr;
    logic [49:0]     debug_vaddr;
  } wb_t;

  // VecPipelineFeedbackIO：向量元素写回（送向量合并缓冲）
  typedef struct packed {
    logic [3:0]      mBIndex;
    logic [23:0]     exceptionVec;
    logic            hasException;
    logic [63:0]     vaddr;
    logic            vaNeedExt;
    logic [63:0]     gpaddr;
    logic            isForVSnonLeafPTE;
    logic [7:0]      vstart;
    logic [15:0]     vecTriggerMask;
    logic [7:0]      elemIdx;
    logic [15:0]     mask;
    logic [2:0]      alignedType;
    logic [7:0]      elemIdxInsideVd;
    logic [127:0]    vecdata;
  } vec_wb_t;
  // END GENERATED(types)

  // ---------------- 拆分方案 ----------------
  // 一个宽度为 size、起点为 vaddr 的非对齐访问，拆成两个"自然对齐"的子访问：
  //   低半：宽度 lo_size，起点 vaddr - lo_shift（往回退到对齐位置）；结果右移 lo_shift 字节后取 lo_width 字节；
  //   高半：宽度 hi_size，起点 vaddr + lo_width（紧接低半取走的最后一个字节）；结果取最低 hi_width 字节。
  //   lo_width + hi_width = 原访问的字节数。
  // valid=0 的组合（lb，或本来就对齐的 lw/ld）不该出现在这里（golden 只有断言）：两个子访问地址/掩码为 0、
  //   fuOpType 保持原值，四个结果移位/宽度寄存器不更新 —— 照 Chisel 的 switch 缺省行为原样保留。
  typedef struct packed {
    logic       valid;
    logic [1:0] lo_size;
    logic [2:0] lo_shift;
    logic [2:0] lo_width;
    logic [1:0] hi_size;
    logic [2:0] hi_width;
  } split_plan_t;

  function automatic split_plan_t split_plan(logic [1:0] size, logic [2:0] off);
    split_plan_t p;
    p = '0;
    unique case (size)
      SZ_H: p = '{1'b1, SZ_B, 3'd0, 3'd1, SZ_B, 3'd1};
      SZ_W:
        unique case (off[1:0])
          2'b01:   p = '{1'b1, SZ_W, 3'd1, 3'd3, SZ_B, 3'd1};
          2'b10:   p = '{1'b1, SZ_H, 3'd0, 3'd2, SZ_H, 3'd2};
          2'b11:   p = '{1'b1, SZ_B, 3'd0, 3'd1, SZ_W, 3'd3};
          default: p = '0;
        endcase
      SZ_D:
        unique case (off)
          3'b001:  p = '{1'b1, SZ_D, 3'd1, 3'd7, SZ_B, 3'd1};
          3'b010:  p = '{1'b1, SZ_D, 3'd2, 3'd6, SZ_H, 3'd2};
          3'b011:  p = '{1'b1, SZ_D, 3'd3, 3'd5, SZ_W, 3'd3};
          3'b100:  p = '{1'b1, SZ_W, 3'd0, 3'd4, SZ_W, 3'd4};
          3'b101:  p = '{1'b1, SZ_W, 3'd1, 3'd3, SZ_D, 3'd5};
          3'b110:  p = '{1'b1, SZ_H, 3'd0, 3'd2, SZ_D, 3'd6};
          3'b111:  p = '{1'b1, SZ_B, 3'd0, 3'd1, SZ_D, 3'd7};
          default: p = '0;
        endcase
      default: p = '0;   // SZ_B：单字节不会非对齐
    endcase
    return p;
  endfunction

  // 访问宽度 → 字节掩码（未移位）
  function automatic logic [7:0] size_mask(logic [1:0] size);
    unique case (size)
      SZ_B:    return 8'h01;
      SZ_H:    return 8'h03;
      SZ_W:    return 8'h0F;
      default: return 8'hFF;
    endcase
  endfunction

  // 访问宽度 → 最后一个字节相对起点的偏移（size 字节数 - 1）
  function automatic logic [2:0] size_last_byte(logic [1:0] size);
    unique case (size)
      SZ_B:    return 3'd0;
      SZ_H:    return 3'd1;
      SZ_W:    return 3'd3;
      default: return 3'd7;
    endcase
  endfunction

  // RobPtr.needFlush(redirect)：被冲掉 = 比重定向点更年轻，或 level=flushItself 时就是它自己
  function automatic logic rob_need_flush(logic redir_valid, logic redir_level,
                                          logic redir_flag, logic [7:0] redir_value,
                                          logic flag, logic [7:0] value);
    logic same, after;
    same  = {flag, value} == {redir_flag, redir_value};
    after = flag ^ redir_flag ^ (value > redir_value);   // isAfter：环形指针比新旧
    return redir_valid & (redir_level & same | after);
  endfunction

  // Hypervisor load 的两个标志（LSUOpType.isHlv / isHlvx）
  function automatic logic is_hlv(logic [8:0] op);
    return op[4] & ~op[5] & (op[8:7] == 2'b00);
  endfunction
  function automatic logic is_hlvx(logic [8:0] op);
    return op[4] & op[3] & ~op[5] & (op[8:7] == 2'b00);
  endfunction

  // getShiftAndTruncateData：data 右移 shift 字节，再只留最低 width 字节（width=0 时全 0）
  function automatic logic [63:0] shift_and_truncate(logic [2:0] shift, logic [2:0] width,
                                                     logic [63:0] data);
    logic [63:0] shifted, keep;
    shifted = data >> {shift, 3'b000};
    keep    = (64'h1 << {width, 3'b000}) - 64'h1;
    return shifted & keep;
  endfunction

  // rdataHelper：标量 load 按 fuOpType 做符号/零扩展；fp load（fpWen）的 lh/lw 做 NaN-boxing（高位全 1）
  function automatic logic [63:0] rdata_scalar(logic [8:0] op, logic fp_wen, logic [63:0] d);
    unique case (op)
      OP_LB, OP_HLVB:                return {{56{d[7]}}, d[7:0]};
      OP_LH:                         return fp_wen ? {48'hFFFF_FFFF_FFFF, d[15:0]} : {{48{d[15]}}, d[15:0]};
      OP_HLVH:                       return {{48{d[15]}}, d[15:0]};
      OP_LW:                         return fp_wen ? {32'hFFFF_FFFF, d[31:0]} : {{32{d[31]}}, d[31:0]};
      OP_HLVW:                       return {{32{d[31]}}, d[31:0]};
      OP_LD, OP_HLVD:                return d;                   // fp ld 的 box(D) 就是原值
      OP_LBU, OP_HLVBU:              return {56'h0, d[7:0]};
      OP_LHU, OP_HLVHU, OP_HLVXHU:   return {48'h0, d[15:0]};
      OP_LWU, OP_HLVWU, OP_HLVXWU:   return {32'h0, d[31:0]};
      default:                       return 64'h0;
    endcase
  endfunction

  // rdataVecHelper：向量元素按 alignedType（3 位整值比较）零扩展；4..7 得 0
  function automatic logic [63:0] rdata_vec(logic [2:0] aligned_type, logic [63:0] d);
    unique case (aligned_type)
      3'd0:    return {56'h0, d[7:0]};
      3'd1:    return {48'h0, d[15:0]};
      3'd2:    return {32'h0, d[31:0]};
      3'd3:    return d;
      default: return 64'h0;
    endcase
  endfunction

  // genRdataOH：入队时就把"写回时怎么扩展"编成 9 位独热码存起来（下标见 new_rdata）
  function automatic logic [8:0] gen_rdata_oh(logic [8:0] op, logic fp_wen);
    logic [8:0] s;
    s[8] = (op == OP_LW) & fp_wen;
    s[7] = (op == OP_LH) & fp_wen;
    s[6] = (op == OP_LW) & ~fp_wen | (op == OP_HLVW);
    s[5] = (op == OP_LH) & ~fp_wen | (op == OP_HLVH);
    s[4] = (op == OP_LB) | (op == OP_HLVB);
    s[3] = (op == OP_LD) | (op == OP_HLVD);
    s[2] = (op == OP_LWU) | (op == OP_HLVWU) | (op == OP_HLVXWU);
    s[1] = (op == OP_LHU) | (op == OP_HLVHU) | (op == OP_HLVXHU);
    s[0] = (op == OP_LBU) | (op == OP_HLVBU);
    return s;
  endfunction

  // newRdataHelper：按独热码 Mux1H（多位同时为 1 时按位或，与 golden 一致）
  function automatic logic [63:0] new_rdata(logic [8:0] sel, logic [63:0] d);
    logic [63:0] r;
    r = '0;
    if (sel[0]) r |= {56'h0, d[7:0]};
    if (sel[1]) r |= {48'h0, d[15:0]};
    if (sel[2]) r |= {32'h0, d[31:0]};
    if (sel[3]) r |= d;
    if (sel[4]) r |= {{56{d[7]}}, d[7:0]};
    if (sel[5]) r |= {{48{d[15]}}, d[15:0]};
    if (sel[6]) r |= {{32{d[31]}}, d[31:0]};
    if (sel[7]) r |= {48'hFFFF_FFFF_FFFF, d[15:0]};   // FPU.box(H)
    if (sel[8]) r |= {32'hFFFF_FFFF, d[31:0]};         // FPU.box(S)
    return r;
  endfunction

endpackage

// =====================================================================
// xs_LoadMisalignBuffer_core —— 可读核
// =====================================================================
module xs_LoadMisalignBuffer_core
  import loadmisalignbuffer_pkg::*;
(
  input  logic                      clock,
  input  logic                      reset,
  input  logic                      redirect_valid,
  input  redirect_t                 redirect,
  input  logic [NUM_ENQ-1:0]        enq_valid,
  input  enq_req_t [NUM_ENQ-1:0]    enq_bits,
  output logic [NUM_ENQ-1:0]        enq_ready,
  input  logic                      split_req_ready,
  output logic                      split_req_valid,
  output split_req_t                split_req,
  input  logic                      split_resp_valid,
  input  split_resp_t               split_resp,
  input  logic                      wb_ready,
  output logic                      wb_valid,
  output wb_t                       wb,
  output logic                      vec_wb_valid,
  output vec_wb_t                   vec_wb,
  input  logic                      load_out_valid,      // LoadUnit 本拍自己要写回：让路
  input  logic                      load_vec_out_valid   // 同上，向量写回口
);

  // ===================================================================
  // 本模块的全部状态（寄存器名与 golden 逐个相同，便于对照）
  // ===================================================================
  // 条目本体：入队那一拍整包锁存的 load（LqWriteBundle 的子集）；子访问异常时部分地址字段被改写
  enq_req_t    req, req_nxt;
  // 两个对齐子访问（LsPipelineBundle），s_split 时算好存下，s_req 按 curPtr 发出
  split_req_t  split_reqs [2];
  split_req_t  split_new  [2];
  logic        split_now;               // 本拍把 split_new 写进 split_reqs

  logic        req_valid;
  state_e      bufferState;
  logic [1:0]  unSentLoads;             // 还没成功回来的子访问（按下标置位）
  logic        curPtr;                  // 当前在处理第几个子访问
  logic [8:0]  data_select;             // 写回扩展方式独热码（入队时由 fuOpType 算出）
  logic        globalException;         // 某个子访问报了异常
  logic        globalUncache;           // 某个子访问落在 MMIO / NC 空间
  logic        globalMMIO;              // 以下三个只进 debug / 向量写回
  logic        globalNC;
  logic        globalMemBackTypeMM;
  logic [2:0]  lowResultShift, lowResultWidth, highResultShift, highResultWidth;
  logic [128:0] splitLoadResp_0_data, splitLoadResp_1_data;   // 两个子访问回来的原始数据
  logic [63:0] combinedData;            // 拼好、扩展好的结果
  // 累计异常：只有 LduCfg 的 6 位（3/4/5/13/19/21）是寄存器，其余位恒 0
  logic        exceptionVec_3, exceptionVec_4, exceptionVec_5;
  logic        exceptionVec_13, exceptionVec_19, exceptionVec_21;
  logic        REG;                     // RegNext(!req_valid)：只给 perf 计数 "alloc" 用，本配置无出口

  // 整包寄存器 req / split_reqs 的逐字段声明与读写在核末尾 §8（生成）

  // 异常累计寄存器的向量视图
  logic [23:0] exc_q, exc_d;
  always_comb begin
    exc_q = '0;
    exc_q[EXC_BREAKPOINT]    = exceptionVec_3;
    exc_q[EXC_LD_MISALIGN]   = exceptionVec_4;
    exc_q[EXC_LD_ACCESS]     = exceptionVec_5;
    exc_q[EXC_LD_PAGE]       = exceptionVec_13;
    exc_q[EXC_HW_ERROR]      = exceptionVec_19;
    exc_q[EXC_LD_GUEST_PAGE] = exceptionVec_21;
  end

  // ===================================================================
  // §1 入队：3 条 load 流水里按口号优先级收一条（只在空闲时收）
  // ===================================================================
  logic      can_enq;
  enq_req_t  enq_sel;
  always_comb begin
    // ready：条目空，且口号更小的口没人 ready（ParallelPriorityMux 的选择顺序）
    for (int i = 0; i < NUM_ENQ; i++) begin
      enq_ready[i] = ~req_valid & enq_valid[i];
      for (int j = 0; j < i; j++)
        enq_ready[i] = enq_ready[i] & ~enq_ready[j];
    end
    // 选中的请求：第一个 valid 的口；一个都没有时落到最后一口（无所谓，can_enq=0）
    enq_sel = enq_bits[NUM_ENQ-1];
    for (int i = NUM_ENQ - 2; i >= 0; i--)
      if (enq_valid[i]) enq_sel = enq_bits[i];
    // 真正写入：空、有人来、且来者没被本拍的 redirect 冲掉（ready 不看 redirect）
    can_enq = ~req_valid & (|enq_valid)
            & ~rob_need_flush(redirect_valid, redirect.level, redirect.robIdx_flag,
                              redirect.robIdx_value,
                              enq_sel.uop.robIdx_flag, enq_sel.uop.robIdx_value);
  end

  // 条目被 redirect 冲掉
  logic flush;
  assign flush = req_valid & rob_need_flush(redirect_valid, redirect.level, redirect.robIdx_flag,
                                            redirect.robIdx_value,
                                            req.uop.robIdx_flag, req.uop.robIdx_value);

  // ===================================================================
  // §2 状态机：s_idle → s_split → s_req ⇄ s_resp → s_comb_wakeup_rep → s_wb → s_idle
  // ===================================================================
  // 子访问响应的分类（hasException / isUncache / need_rep）
  logic resp_has_exc, resp_uncache, resp_need_rep, resp_abort;
  assign resp_has_exc  = split_resp.vecActive & (|(split_resp.uop.exceptionVec & LDU_EXC_MASK))
                       | split_resp.uop.trigger == TRIG_ACT_DEBUG_MODE;
  assign resp_uncache  = split_resp.mmio | split_resp.nc;
  assign resp_need_rep = |split_resp.rep_info_cause;
  assign resp_abort    = resp_has_exc | resp_uncache;   // 不再往下拆，直接带异常写回

  // 响应落到本条目：状态机只看 valid（不核对 robIdx）；数据 / 指针 / 异常的更新还要 robIdx 相等
  logic resp_in_wait, resp_match;
  assign resp_in_wait = split_resp_valid & (bufferState == S_RESP);
  assign resp_match   = resp_in_wait
                      & ({req.uop.robIdx_flag, req.uop.robIdx_value}
                         == {split_resp.uop.robIdx_flag, split_resp.uop.robIdx_value});

  logic need_wakeup_req;      // 标量 load 拼完数据后，要再发一个唤醒请求去拿写回口
  logic split_req_fire;
  logic wb_release;           // 写回完成，条目释放
  assign need_wakeup_req = (bufferState == S_COMB_WAKEUP_REP) & ~req.isvec;
  assign split_req_fire  = split_req_ready & split_req_valid;
  // vecWriteBack.ready 在上层恒 1，fire 就是 valid
  assign wb_release      = (bufferState == S_WB) & (req.isvec ? vec_wb_valid : wb_ready & wb_valid);

  state_e bufferState_nxt;
  logic   req_valid_nxt;
  always_comb begin
    bufferState_nxt = bufferState;
    unique case (bufferState)
      S_IDLE:  if (req_valid) bufferState_nxt = S_SPLIT;
      S_SPLIT: bufferState_nxt = S_REQ;
      S_REQ:   if (split_req_fire) bufferState_nxt = S_RESP;
      S_RESP:
        if (split_resp_valid) begin
          if (resp_abort)
            bufferState_nxt = S_WB;
          else if (resp_need_rep | (|(unSentLoads & ~(2'b01 << curPtr))))
            bufferState_nxt = S_REQ;              // 要重发，或另一个还没发
          else
            bufferState_nxt = S_COMB_WAKEUP_REP;  // 两个都回来了
        end
      S_COMB_WAKEUP_REP:
        if (req.isvec)              bufferState_nxt = S_WB;       // 向量不需要唤醒请求
        else if (split_req_fire)    bufferState_nxt = S_WB;       // 唤醒请求发出去了
      S_WB:    if (wb_release) bufferState_nxt = S_IDLE;
      default: ;                                                  // 6/7 不可达，保持
    endcase
    if (flush) bufferState_nxt = S_IDLE;

    req_valid_nxt = req_valid;
    if (can_enq)    req_valid_nxt = 1'b1;
    if (wb_release) req_valid_nxt = 1'b0;
    if (flush)      req_valid_nxt = 1'b0;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      req_valid   <= 1'b0;
      bufferState <= S_IDLE;
    end else begin
      req_valid   <= req_valid_nxt;
      bufferState <= bufferState_nxt;
    end
  end

  // ===================================================================
  // §3 拆分：s_split 这一拍把 req 拆成低/高两个对齐子访问
  // ===================================================================
  // 访问宽度：向量看 alignedType，标量看 fuOpType 低 2 位
  logic [1:0]  aligned_size;
  logic [4:0]  high_addr;          // 最后一个字节地址的 [4:0]
  logic        cross16;            // 跨 16B 边界（进本缓冲的前提；不跨时 golden 只有断言）
  split_plan_t plan;
  assign aligned_size = req.isvec ? req.alignedType[1:0] : req.uop.fuOpType[1:0];
  assign high_addr    = 5'(size_last_byte(aligned_size)) + req.vaddr[4:0];
  assign cross16      = req_valid & (high_addr[4] != req.vaddr[4]);
  assign plan         = split_plan(aligned_size, req.vaddr[2:0]);
  assign split_now    = (bufferState == S_SPLIT) & cross16;

  always_comb begin
    for (int k = 0; k < 2; k++) begin
      // 两半都从原 uop 复制（清掉非对齐异常位）；其余 LsPipelineBundle 字段是 0
      split_new[k]                  = '0;
      split_new[k].uop              = req.uop;
      split_new[k].uop.exceptionVec[EXC_LD_MISALIGN] = 1'b0;
      split_new[k].fullva           = req.fullva;
    end
    if (plan.valid) begin
      split_new[0].uop.fuOpType = 9'(plan.lo_size);
      split_new[0].vaddr        = req.vaddr - 50'(plan.lo_shift);
      split_new[1].uop.fuOpType = 9'(plan.hi_size);
      split_new[1].vaddr        = req.vaddr + 50'(plan.lo_width);
    end
    // 字节掩码 = 子访问宽度的掩码移到它在 16B 块里的位置（不合法组合时 vaddr=0、宽度掩码=0）
    split_new[0].mask = plan.valid ? 16'(16'(size_mask(plan.lo_size)) << split_new[0].vaddr[3:0]) : 16'h0;
    split_new[1].mask = plan.valid ? 16'(16'(size_mask(plan.hi_size)) << split_new[1].vaddr[3:0]) : 16'h0;
  end

  // 结果拼接要用的移位 / 宽度：拆分时记下（不合法组合时保持旧值）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      lowResultShift  <= 3'd0;
      lowResultWidth  <= 3'd0;
      highResultShift <= 3'd0;
      highResultWidth <= 3'd0;
    end else if (split_now & plan.valid) begin
      lowResultShift  <= plan.lo_shift;
      lowResultWidth  <= plan.lo_width;
      highResultShift <= 3'd0;
      highResultWidth <= plan.hi_width;
    end
  end

  // ===================================================================
  // §4 发请求：s_req 发当前子访问；s_comb_wakeup_rep 发唤醒请求（同一个口）
  // ===================================================================
  always_comb begin
    split_req_valid = req_valid & ((bufferState == S_REQ)
                                   | (bufferState == S_COMB_WAKEUP_REP) & need_wakeup_req & ~req.isvec);
    split_req                    = split_reqs[curPtr];
    split_req.isvec              = req.isvec;
    split_req.misalignNeedWakeUp = need_wakeup_req;
    split_req.isFinalSplit       = curPtr & ~need_wakeup_req;   // 发第二个子访问时标"最后一片"
    // 向量：fuOpType 原样用 req 的（子访问宽度走 alignedType，本配置那个输出被 DCE）；
    // 标量：宽度换成子访问的，并恢复 H 扩展 load 的 hlv / hlvx 标志（{hlv, hlvx, 0, size}）
    split_req.uop.fuOpType = req.isvec ? req.uop.fuOpType
                           : {4'b0000, is_hlv(req.uop.fuOpType), is_hlvx(req.uop.fuOpType),
                              1'b0, split_reqs[curPtr].uop.fuOpType[1:0]};
  end

  // ===================================================================
  // §5 收响应：记数据、推进 curPtr / unSentLoads、累计异常；异常 / uncache 时改写 req 的地址
  // ===================================================================
  logic [1:0] unSentLoads_nxt;
  logic       curPtr_nxt;
  always_comb begin
    unSentLoads_nxt = unSentLoads;
    curPtr_nxt      = curPtr;
    exc_d           = exc_q;
    // 写回完成：清零
    if (wb_release) begin
      unSentLoads_nxt = 2'b00;
      curPtr_nxt      = 1'b0;
    end
    // 拆分：两个都待发，从低半开始；异常累计清零（不管跨没跨 16B）
    if (split_now) begin
      unSentLoads_nxt = 2'b11;
      curPtr_nxt      = 1'b0;
    end
    if (bufferState == S_SPLIT)
      exc_d = '0;
    // 子访问回来了
    if (resp_match) begin
      if (resp_uncache) begin
        // 落在 uncache 空间：不做了，改报 loadAddrMisaligned 交给软件模拟
        unSentLoads_nxt = 2'b00;
        exc_d           = '0;
        exc_d[EXC_LD_MISALIGN] = 1'b1;
      end else if (resp_has_exc) begin
        unSentLoads_nxt = 2'b00;
        exc_d           = exc_q | (split_resp.uop.exceptionVec & LDU_EXC_MASK);
      end else if (!resp_need_rep) begin
        // 成功：这一片完成，指向下一片
        unSentLoads_nxt = unSentLoads & ~(2'b01 << curPtr);
        curPtr_nxt      = curPtr + 1'b1;
        exc_d           = '0;
      end
      // 要 replay：什么都不变，回 s_req 重发同一片
    end
    if (flush) begin
      unSentLoads_nxt = 2'b00;
      curPtr_nxt      = 1'b0;
    end
  end

  // 全局标志：s_resp 收到异常 / uncache 时记下，写回完成或被冲掉时清零
  logic gExc_nxt, gUnc_nxt, gMMIO_nxt, gNC_nxt, gMM_nxt;
  always_comb begin
    {gExc_nxt, gUnc_nxt, gMMIO_nxt, gNC_nxt, gMM_nxt} =
      {globalException, globalUncache, globalMMIO, globalNC, globalMemBackTypeMM};
    if (resp_in_wait & resp_abort)
      {gExc_nxt, gUnc_nxt, gMMIO_nxt, gNC_nxt, gMM_nxt} =
        {resp_has_exc, resp_uncache, split_resp.mmio, split_resp.nc, split_resp.memBackTypeMM};
    if (wb_release | flush)
      {gExc_nxt, gUnc_nxt, gMMIO_nxt, gNC_nxt, gMM_nxt} = '0;
  end

  // req 的次态：入队时整包写入；子访问异常 / uncache 时换成出事那一片的地址（异常要报它）
  always_comb begin
    req_nxt = req;
    if (can_enq)
      req_nxt = enq_sel;
    if (resp_in_wait & resp_abort) begin
      req_nxt.vaddr             = split_resp.vaddr;
      req_nxt.fullva            = split_resp.fullva;
      req_nxt.vaNeedExt         = split_resp.vaNeedExt;
      req_nxt.paddr             = split_resp.paddr;
      req_nxt.gpaddr            = split_resp.gpaddr;
      req_nxt.isForVSnonLeafPTE = split_resp.isForVSnonLeafPTE;
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      unSentLoads         <= 2'b00;
      curPtr              <= 1'b0;
      globalException     <= 1'b0;
      globalUncache       <= 1'b0;
      globalMMIO          <= 1'b0;
      globalNC            <= 1'b0;
      globalMemBackTypeMM <= 1'b0;
      exceptionVec_3      <= 1'b0;
      exceptionVec_4      <= 1'b0;
      exceptionVec_5      <= 1'b0;
      exceptionVec_13     <= 1'b0;
      exceptionVec_19     <= 1'b0;
      exceptionVec_21     <= 1'b0;
      splitLoadResp_0_data <= '0;
      splitLoadResp_1_data <= '0;
      data_select         <= 9'h0;
    end else begin
      unSentLoads         <= unSentLoads_nxt;
      curPtr              <= curPtr_nxt;
      globalException     <= gExc_nxt;
      globalUncache       <= gUnc_nxt;
      globalMMIO          <= gMMIO_nxt;
      globalNC            <= gNC_nxt;
      globalMemBackTypeMM <= gMM_nxt;
      exceptionVec_3      <= exc_d[EXC_BREAKPOINT];
      exceptionVec_4      <= exc_d[EXC_LD_MISALIGN];
      exceptionVec_5      <= exc_d[EXC_LD_ACCESS];
      exceptionVec_13     <= exc_d[EXC_LD_PAGE];
      exceptionVec_19     <= exc_d[EXC_HW_ERROR];
      exceptionVec_21     <= exc_d[EXC_LD_GUEST_PAGE];
      // 子访问的原始数据按 curPtr 存到对应槽（只有 robIdx 对上的响应才算）
      if (resp_match & ~curPtr) splitLoadResp_0_data <= split_resp.data;
      if (resp_match &  curPtr) splitLoadResp_1_data <= split_resp.data;
      if (can_enq)
        data_select <= gen_rdata_oh(enq_sel.uop.fuOpType, enq_sel.uop.fpWen);
    end
  end

  always_ff @(posedge clock) begin
    REG <= ~req_valid;
  end

  // ===================================================================
  // §6 结果拼接：低半取 lowResultWidth 字节放在低位，高半接在后面，再按 load 类型扩展
  // ===================================================================
  logic [63:0] low_part, high_part;
  logic [7:0]  low_bytes  [8];
  logic [7:0]  high_bytes [8];
  logic [7:0]  cat_bytes  [8];
  logic [63:0] cat_result;
  always_comb begin
    low_part  = shift_and_truncate(lowResultShift,  lowResultWidth,  splitLoadResp_0_data[63:0]);
    high_part = shift_and_truncate(highResultShift, highResultWidth, splitLoadResp_1_data[63:0]);
    for (int i = 0; i < 8; i++) begin
      low_bytes[i]  = low_part[8*i +: 8];
      high_bytes[i] = high_part[8*i +: 8];
    end
    // 第 i 字节：i < 低半宽度取低半第 i 字节，否则取高半第 (i - 低半宽度) 字节（3 位回绕）
    for (int i = 0; i < 8; i++) begin
      if (3'(i) < lowResultWidth) cat_bytes[i] = low_bytes[i];
      else                        cat_bytes[i] = high_bytes[3'(3'(i) - lowResultWidth)];
      cat_result[8*i +: 8] = cat_bytes[i];
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      combinedData <= 64'h0;
    else if (bufferState == S_COMB_WAKEUP_REP)
      combinedData <= req.isvec ? rdata_vec(req.alignedType, cat_result)
                                : rdata_scalar(req.uop.fuOpType, req.uop.fpWen, cat_result);
  end

  // ===================================================================
  // §7 写回：标量走 writeBack（要等唤醒请求回到 s3 才发，除非是异常写回），向量走 vecWriteBack
  // ===================================================================
  logic abort_wb;   // 异常 / uncache 写回
  assign abort_wb = globalUncache | globalException;

  always_comb begin
    wb_valid = req_valid & (bufferState == S_WB)
             & (split_resp_valid & split_resp.misalignNeedWakeUp | abort_wb)
             & ~load_out_valid & ~req.isvec;
    wb                   = '0;
    wb.uop               = req.uop;
    // 异常只在异常 / uncache 写回时带出（正常写回时累计寄存器可能残留，不能带）
    wb.uop.exceptionVec  = abort_wb ? (exc_q & LDU_EXC_MASK) : 24'h0;
    wb.uop.rfWen         = ~globalException & ~globalUncache & req.uop.rfWen;
    wb.uop.flushPipe     = 1'b0;
    wb.uop.replayInst    = 1'b0;
    wb.data              = new_rdata(data_select, combinedData);
    wb.debug_isMMIO      = globalMMIO;
    wb.debug_isNCIO      = globalNC & ~globalMemBackTypeMM;
    wb.debug_paddr       = req.paddr;
    wb.debug_vaddr       = req.vaddr;

    vec_wb_valid = req_valid & (bufferState == S_WB) & ~load_vec_out_valid & req.isvec;
    vec_wb                   = '0;
    vec_wb.mBIndex           = req.mbIndex;
    vec_wb.exceptionVec      = exc_q & LDU_EXC_MASK;    // VlduCfg 与 LduCfg 同 6 位
    vec_wb.hasException      = globalException;
    vec_wb.vaddr             = req.fullva;
    vec_wb.vaNeedExt         = req.vaNeedExt;
    vec_wb.gpaddr            = req.gpaddr;
    vec_wb.isForVSnonLeafPTE = req.isForVSnonLeafPTE;
    vec_wb.vstart            = req.uop.vpu_vstart;
    vec_wb.vecTriggerMask    = req.vecTriggerMask;
    vec_wb.elemIdx           = req.elemIdx;
    vec_wb.mask              = req.mask;
    vec_wb.alignedType       = req.alignedType;
    vec_wb.elemIdxInsideVd   = req.elemIdxInsideVd;
    vec_wb.vecdata           = {64'h0, combinedData};
  end

  // ===================================================================
  // §8 整包寄存器（生成）：req / splitLoadReqs_0/1 按 golden 留下的字段逐个存
  // ===================================================================
  // 字段集合 = golden 的 reg 声明（firtool 删掉了读不到的字段，例如 req 的 exceptionVec_4 / flushPipe）；
  // 核里其余逻辑只通过 struct 视图 req / split_reqs 读、通过 req_nxt / split_new 写。
  // BEGIN GENERATED(regs) —— scripts/gen_lmisalign.py 生成，勿手改
  // ---- req：入队时整包锁存，子访问异常时改写地址字段（无复位；次态 req_nxt 见 §5）：golden 留下的 191 个字段 ----
  logic [31:0]    req_uop_instr;
  logic [49:0]    req_uop_pc;
  logic [9:0]     req_uop_foldpc;
  logic           req_uop_exceptionVec_0;
  logic           req_uop_exceptionVec_1;
  logic           req_uop_exceptionVec_2;
  logic           req_uop_exceptionVec_3;
  logic           req_uop_exceptionVec_5;
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
  logic           req_uop_exceptionVec_19;
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
  logic           req_uop_replayInst;
  logic [34:0]    req_uop_debug_fuType;
  logic           req_uop_debug_sim_trig;
  logic [4:0]     req_uop_numLsElem;
  logic [49:0]    req_vaddr;
  logic [63:0]    req_fullva;
  logic           req_vaNeedExt;
  logic [47:0]    req_paddr;
  logic [63:0]    req_gpaddr;
  logic [15:0]    req_mask;
  logic           req_isForVSnonLeafPTE;
  logic           req_isvec;
  logic [7:0]     req_elemIdx;
  logic [2:0]     req_alignedType;
  logic [3:0]     req_mbIndex;
  logic [7:0]     req_elemIdxInsideVd;
  logic [15:0]    req_vecTriggerMask;
  always_ff @(posedge clock) begin
    req_uop_instr <= req_nxt.uop.instr;
    req_uop_pc <= req_nxt.uop.pc;
    req_uop_foldpc <= req_nxt.uop.foldpc;
    req_uop_exceptionVec_0 <= req_nxt.uop.exceptionVec[0];
    req_uop_exceptionVec_1 <= req_nxt.uop.exceptionVec[1];
    req_uop_exceptionVec_2 <= req_nxt.uop.exceptionVec[2];
    req_uop_exceptionVec_3 <= req_nxt.uop.exceptionVec[3];
    req_uop_exceptionVec_5 <= req_nxt.uop.exceptionVec[5];
    req_uop_exceptionVec_6 <= req_nxt.uop.exceptionVec[6];
    req_uop_exceptionVec_7 <= req_nxt.uop.exceptionVec[7];
    req_uop_exceptionVec_8 <= req_nxt.uop.exceptionVec[8];
    req_uop_exceptionVec_9 <= req_nxt.uop.exceptionVec[9];
    req_uop_exceptionVec_10 <= req_nxt.uop.exceptionVec[10];
    req_uop_exceptionVec_11 <= req_nxt.uop.exceptionVec[11];
    req_uop_exceptionVec_12 <= req_nxt.uop.exceptionVec[12];
    req_uop_exceptionVec_13 <= req_nxt.uop.exceptionVec[13];
    req_uop_exceptionVec_14 <= req_nxt.uop.exceptionVec[14];
    req_uop_exceptionVec_15 <= req_nxt.uop.exceptionVec[15];
    req_uop_exceptionVec_16 <= req_nxt.uop.exceptionVec[16];
    req_uop_exceptionVec_17 <= req_nxt.uop.exceptionVec[17];
    req_uop_exceptionVec_18 <= req_nxt.uop.exceptionVec[18];
    req_uop_exceptionVec_19 <= req_nxt.uop.exceptionVec[19];
    req_uop_exceptionVec_20 <= req_nxt.uop.exceptionVec[20];
    req_uop_exceptionVec_21 <= req_nxt.uop.exceptionVec[21];
    req_uop_exceptionVec_22 <= req_nxt.uop.exceptionVec[22];
    req_uop_exceptionVec_23 <= req_nxt.uop.exceptionVec[23];
    req_uop_isFetchMalAddr <= req_nxt.uop.isFetchMalAddr;
    req_uop_hasException <= req_nxt.uop.hasException;
    req_uop_trigger <= req_nxt.uop.trigger;
    req_uop_preDecodeInfo_valid <= req_nxt.uop.preDecodeInfo_valid;
    req_uop_preDecodeInfo_isRVC <= req_nxt.uop.preDecodeInfo_isRVC;
    req_uop_preDecodeInfo_brType <= req_nxt.uop.preDecodeInfo_brType;
    req_uop_preDecodeInfo_isCall <= req_nxt.uop.preDecodeInfo_isCall;
    req_uop_preDecodeInfo_isRet <= req_nxt.uop.preDecodeInfo_isRet;
    req_uop_pred_taken <= req_nxt.uop.pred_taken;
    req_uop_crossPageIPFFix <= req_nxt.uop.crossPageIPFFix;
    req_uop_ftqPtr_flag <= req_nxt.uop.ftqPtr_flag;
    req_uop_ftqPtr_value <= req_nxt.uop.ftqPtr_value;
    req_uop_ftqOffset <= req_nxt.uop.ftqOffset;
    req_uop_satpFlushFirstFetchFault <= req_nxt.uop.satpFlushFirstFetchFault;
    req_uop_srcType_0 <= req_nxt.uop.srcType_0;
    req_uop_srcType_1 <= req_nxt.uop.srcType_1;
    req_uop_srcType_2 <= req_nxt.uop.srcType_2;
    req_uop_srcType_3 <= req_nxt.uop.srcType_3;
    req_uop_srcType_4 <= req_nxt.uop.srcType_4;
    req_uop_ldest <= req_nxt.uop.ldest;
    req_uop_fuType <= req_nxt.uop.fuType;
    req_uop_fuOpType <= req_nxt.uop.fuOpType;
    req_uop_rfWen <= req_nxt.uop.rfWen;
    req_uop_fpWen <= req_nxt.uop.fpWen;
    req_uop_vecWen <= req_nxt.uop.vecWen;
    req_uop_v0Wen <= req_nxt.uop.v0Wen;
    req_uop_vlWen <= req_nxt.uop.vlWen;
    req_uop_isXSTrap <= req_nxt.uop.isXSTrap;
    req_uop_waitForward <= req_nxt.uop.waitForward;
    req_uop_blockBackward <= req_nxt.uop.blockBackward;
    req_uop_canRobCompress <= req_nxt.uop.canRobCompress;
    req_uop_selImm <= req_nxt.uop.selImm;
    req_uop_imm <= req_nxt.uop.imm;
    req_uop_fpu_typeTagOut <= req_nxt.uop.fpu_typeTagOut;
    req_uop_fpu_wflags <= req_nxt.uop.fpu_wflags;
    req_uop_fpu_typ <= req_nxt.uop.fpu_typ;
    req_uop_fpu_fmt <= req_nxt.uop.fpu_fmt;
    req_uop_fpu_rm <= req_nxt.uop.fpu_rm;
    req_uop_vpu_vill <= req_nxt.uop.vpu_vill;
    req_uop_vpu_vma <= req_nxt.uop.vpu_vma;
    req_uop_vpu_vta <= req_nxt.uop.vpu_vta;
    req_uop_vpu_vsew <= req_nxt.uop.vpu_vsew;
    req_uop_vpu_vlmul <= req_nxt.uop.vpu_vlmul;
    req_uop_vpu_specVill <= req_nxt.uop.vpu_specVill;
    req_uop_vpu_specVma <= req_nxt.uop.vpu_specVma;
    req_uop_vpu_specVta <= req_nxt.uop.vpu_specVta;
    req_uop_vpu_specVsew <= req_nxt.uop.vpu_specVsew;
    req_uop_vpu_specVlmul <= req_nxt.uop.vpu_specVlmul;
    req_uop_vpu_vm <= req_nxt.uop.vpu_vm;
    req_uop_vpu_vstart <= req_nxt.uop.vpu_vstart;
    req_uop_vpu_frm <= req_nxt.uop.vpu_frm;
    req_uop_vpu_fpu_isFpToVecInst <= req_nxt.uop.vpu_fpu_isFpToVecInst;
    req_uop_vpu_fpu_isFP32Instr <= req_nxt.uop.vpu_fpu_isFP32Instr;
    req_uop_vpu_fpu_isFP64Instr <= req_nxt.uop.vpu_fpu_isFP64Instr;
    req_uop_vpu_fpu_isReduction <= req_nxt.uop.vpu_fpu_isReduction;
    req_uop_vpu_fpu_isFoldTo1_2 <= req_nxt.uop.vpu_fpu_isFoldTo1_2;
    req_uop_vpu_fpu_isFoldTo1_4 <= req_nxt.uop.vpu_fpu_isFoldTo1_4;
    req_uop_vpu_fpu_isFoldTo1_8 <= req_nxt.uop.vpu_fpu_isFoldTo1_8;
    req_uop_vpu_vxrm <= req_nxt.uop.vpu_vxrm;
    req_uop_vpu_vuopIdx <= req_nxt.uop.vpu_vuopIdx;
    req_uop_vpu_lastUop <= req_nxt.uop.vpu_lastUop;
    req_uop_vpu_vmask <= req_nxt.uop.vpu_vmask;
    req_uop_vpu_vl <= req_nxt.uop.vpu_vl;
    req_uop_vpu_nf <= req_nxt.uop.vpu_nf;
    req_uop_vpu_veew <= req_nxt.uop.vpu_veew;
    req_uop_vpu_isReverse <= req_nxt.uop.vpu_isReverse;
    req_uop_vpu_isExt <= req_nxt.uop.vpu_isExt;
    req_uop_vpu_isNarrow <= req_nxt.uop.vpu_isNarrow;
    req_uop_vpu_isDstMask <= req_nxt.uop.vpu_isDstMask;
    req_uop_vpu_isOpMask <= req_nxt.uop.vpu_isOpMask;
    req_uop_vpu_isMove <= req_nxt.uop.vpu_isMove;
    req_uop_vpu_isDependOldVd <= req_nxt.uop.vpu_isDependOldVd;
    req_uop_vpu_isWritePartVd <= req_nxt.uop.vpu_isWritePartVd;
    req_uop_vpu_isVleff <= req_nxt.uop.vpu_isVleff;
    req_uop_vlsInstr <= req_nxt.uop.vlsInstr;
    req_uop_wfflags <= req_nxt.uop.wfflags;
    req_uop_isMove <= req_nxt.uop.isMove;
    req_uop_isDropAmocasSta <= req_nxt.uop.isDropAmocasSta;
    req_uop_uopIdx <= req_nxt.uop.uopIdx;
    req_uop_isVset <= req_nxt.uop.isVset;
    req_uop_firstUop <= req_nxt.uop.firstUop;
    req_uop_lastUop <= req_nxt.uop.lastUop;
    req_uop_numUops <= req_nxt.uop.numUops;
    req_uop_numWB <= req_nxt.uop.numWB;
    req_uop_commitType <= req_nxt.uop.commitType;
    req_uop_srcState_0 <= req_nxt.uop.srcState_0;
    req_uop_srcState_1 <= req_nxt.uop.srcState_1;
    req_uop_srcState_2 <= req_nxt.uop.srcState_2;
    req_uop_srcState_3 <= req_nxt.uop.srcState_3;
    req_uop_srcState_4 <= req_nxt.uop.srcState_4;
    req_uop_srcLoadDependency_0_0 <= req_nxt.uop.srcLoadDependency_0_0;
    req_uop_srcLoadDependency_0_1 <= req_nxt.uop.srcLoadDependency_0_1;
    req_uop_srcLoadDependency_0_2 <= req_nxt.uop.srcLoadDependency_0_2;
    req_uop_srcLoadDependency_1_0 <= req_nxt.uop.srcLoadDependency_1_0;
    req_uop_srcLoadDependency_1_1 <= req_nxt.uop.srcLoadDependency_1_1;
    req_uop_srcLoadDependency_1_2 <= req_nxt.uop.srcLoadDependency_1_2;
    req_uop_srcLoadDependency_2_0 <= req_nxt.uop.srcLoadDependency_2_0;
    req_uop_srcLoadDependency_2_1 <= req_nxt.uop.srcLoadDependency_2_1;
    req_uop_srcLoadDependency_2_2 <= req_nxt.uop.srcLoadDependency_2_2;
    req_uop_srcLoadDependency_3_0 <= req_nxt.uop.srcLoadDependency_3_0;
    req_uop_srcLoadDependency_3_1 <= req_nxt.uop.srcLoadDependency_3_1;
    req_uop_srcLoadDependency_3_2 <= req_nxt.uop.srcLoadDependency_3_2;
    req_uop_srcLoadDependency_4_0 <= req_nxt.uop.srcLoadDependency_4_0;
    req_uop_srcLoadDependency_4_1 <= req_nxt.uop.srcLoadDependency_4_1;
    req_uop_srcLoadDependency_4_2 <= req_nxt.uop.srcLoadDependency_4_2;
    req_uop_psrc_0 <= req_nxt.uop.psrc_0;
    req_uop_psrc_1 <= req_nxt.uop.psrc_1;
    req_uop_psrc_2 <= req_nxt.uop.psrc_2;
    req_uop_psrc_3 <= req_nxt.uop.psrc_3;
    req_uop_psrc_4 <= req_nxt.uop.psrc_4;
    req_uop_pdest <= req_nxt.uop.pdest;
    req_uop_useRegCache_0 <= req_nxt.uop.useRegCache_0;
    req_uop_useRegCache_1 <= req_nxt.uop.useRegCache_1;
    req_uop_regCacheIdx_0 <= req_nxt.uop.regCacheIdx_0;
    req_uop_regCacheIdx_1 <= req_nxt.uop.regCacheIdx_1;
    req_uop_robIdx_flag <= req_nxt.uop.robIdx_flag;
    req_uop_robIdx_value <= req_nxt.uop.robIdx_value;
    req_uop_instrSize <= req_nxt.uop.instrSize;
    req_uop_dirtyFs <= req_nxt.uop.dirtyFs;
    req_uop_dirtyVs <= req_nxt.uop.dirtyVs;
    req_uop_traceBlockInPipe_itype <= req_nxt.uop.traceBlockInPipe_itype;
    req_uop_traceBlockInPipe_iretire <= req_nxt.uop.traceBlockInPipe_iretire;
    req_uop_traceBlockInPipe_ilastsize <= req_nxt.uop.traceBlockInPipe_ilastsize;
    req_uop_eliminatedMove <= req_nxt.uop.eliminatedMove;
    req_uop_snapshot <= req_nxt.uop.snapshot;
    req_uop_debugInfo_eliminatedMove <= req_nxt.uop.debugInfo_eliminatedMove;
    req_uop_debugInfo_renameTime <= req_nxt.uop.debugInfo_renameTime;
    req_uop_debugInfo_dispatchTime <= req_nxt.uop.debugInfo_dispatchTime;
    req_uop_debugInfo_enqRsTime <= req_nxt.uop.debugInfo_enqRsTime;
    req_uop_debugInfo_selectTime <= req_nxt.uop.debugInfo_selectTime;
    req_uop_debugInfo_issueTime <= req_nxt.uop.debugInfo_issueTime;
    req_uop_debugInfo_writebackTime <= req_nxt.uop.debugInfo_writebackTime;
    req_uop_debugInfo_runahead_checkpoint_id <= req_nxt.uop.debugInfo_runahead_checkpoint_id;
    req_uop_debugInfo_tlbFirstReqTime <= req_nxt.uop.debugInfo_tlbFirstReqTime;
    req_uop_debugInfo_tlbRespTime <= req_nxt.uop.debugInfo_tlbRespTime;
    req_uop_debug_seqNum_seqNum <= req_nxt.uop.debug_seqNum_seqNum;
    req_uop_debug_seqNum_uopIdx <= req_nxt.uop.debug_seqNum_uopIdx;
    req_uop_storeSetHit <= req_nxt.uop.storeSetHit;
    req_uop_waitForRobIdx_flag <= req_nxt.uop.waitForRobIdx_flag;
    req_uop_waitForRobIdx_value <= req_nxt.uop.waitForRobIdx_value;
    req_uop_loadWaitBit <= req_nxt.uop.loadWaitBit;
    req_uop_loadWaitStrict <= req_nxt.uop.loadWaitStrict;
    req_uop_ssid <= req_nxt.uop.ssid;
    req_uop_lqIdx_flag <= req_nxt.uop.lqIdx_flag;
    req_uop_lqIdx_value <= req_nxt.uop.lqIdx_value;
    req_uop_sqIdx_flag <= req_nxt.uop.sqIdx_flag;
    req_uop_sqIdx_value <= req_nxt.uop.sqIdx_value;
    req_uop_singleStep <= req_nxt.uop.singleStep;
    req_uop_replayInst <= req_nxt.uop.replayInst;
    req_uop_debug_fuType <= req_nxt.uop.debug_fuType;
    req_uop_debug_sim_trig <= req_nxt.uop.debug_sim_trig;
    req_uop_numLsElem <= req_nxt.uop.numLsElem;
    req_vaddr <= req_nxt.vaddr;
    req_fullva <= req_nxt.fullva;
    req_vaNeedExt <= req_nxt.vaNeedExt;
    req_paddr <= req_nxt.paddr;
    req_gpaddr <= req_nxt.gpaddr;
    req_mask <= req_nxt.mask;
    req_isForVSnonLeafPTE <= req_nxt.isForVSnonLeafPTE;
    req_isvec <= req_nxt.isvec;
    req_elemIdx <= req_nxt.elemIdx;
    req_alignedType <= req_nxt.alignedType;
    req_mbIndex <= req_nxt.mbIndex;
    req_elemIdxInsideVd <= req_nxt.elemIdxInsideVd;
    req_vecTriggerMask <= req_nxt.vecTriggerMask;
  end
  always_comb begin
    req = '0;   // golden 没留的字段恒 0
    req.uop.instr = req_uop_instr;
    req.uop.pc = req_uop_pc;
    req.uop.foldpc = req_uop_foldpc;
    req.uop.exceptionVec[0] = req_uop_exceptionVec_0;
    req.uop.exceptionVec[1] = req_uop_exceptionVec_1;
    req.uop.exceptionVec[2] = req_uop_exceptionVec_2;
    req.uop.exceptionVec[3] = req_uop_exceptionVec_3;
    req.uop.exceptionVec[5] = req_uop_exceptionVec_5;
    req.uop.exceptionVec[6] = req_uop_exceptionVec_6;
    req.uop.exceptionVec[7] = req_uop_exceptionVec_7;
    req.uop.exceptionVec[8] = req_uop_exceptionVec_8;
    req.uop.exceptionVec[9] = req_uop_exceptionVec_9;
    req.uop.exceptionVec[10] = req_uop_exceptionVec_10;
    req.uop.exceptionVec[11] = req_uop_exceptionVec_11;
    req.uop.exceptionVec[12] = req_uop_exceptionVec_12;
    req.uop.exceptionVec[13] = req_uop_exceptionVec_13;
    req.uop.exceptionVec[14] = req_uop_exceptionVec_14;
    req.uop.exceptionVec[15] = req_uop_exceptionVec_15;
    req.uop.exceptionVec[16] = req_uop_exceptionVec_16;
    req.uop.exceptionVec[17] = req_uop_exceptionVec_17;
    req.uop.exceptionVec[18] = req_uop_exceptionVec_18;
    req.uop.exceptionVec[19] = req_uop_exceptionVec_19;
    req.uop.exceptionVec[20] = req_uop_exceptionVec_20;
    req.uop.exceptionVec[21] = req_uop_exceptionVec_21;
    req.uop.exceptionVec[22] = req_uop_exceptionVec_22;
    req.uop.exceptionVec[23] = req_uop_exceptionVec_23;
    req.uop.isFetchMalAddr = req_uop_isFetchMalAddr;
    req.uop.hasException = req_uop_hasException;
    req.uop.trigger = req_uop_trigger;
    req.uop.preDecodeInfo_valid = req_uop_preDecodeInfo_valid;
    req.uop.preDecodeInfo_isRVC = req_uop_preDecodeInfo_isRVC;
    req.uop.preDecodeInfo_brType = req_uop_preDecodeInfo_brType;
    req.uop.preDecodeInfo_isCall = req_uop_preDecodeInfo_isCall;
    req.uop.preDecodeInfo_isRet = req_uop_preDecodeInfo_isRet;
    req.uop.pred_taken = req_uop_pred_taken;
    req.uop.crossPageIPFFix = req_uop_crossPageIPFFix;
    req.uop.ftqPtr_flag = req_uop_ftqPtr_flag;
    req.uop.ftqPtr_value = req_uop_ftqPtr_value;
    req.uop.ftqOffset = req_uop_ftqOffset;
    req.uop.satpFlushFirstFetchFault = req_uop_satpFlushFirstFetchFault;
    req.uop.srcType_0 = req_uop_srcType_0;
    req.uop.srcType_1 = req_uop_srcType_1;
    req.uop.srcType_2 = req_uop_srcType_2;
    req.uop.srcType_3 = req_uop_srcType_3;
    req.uop.srcType_4 = req_uop_srcType_4;
    req.uop.ldest = req_uop_ldest;
    req.uop.fuType = req_uop_fuType;
    req.uop.fuOpType = req_uop_fuOpType;
    req.uop.rfWen = req_uop_rfWen;
    req.uop.fpWen = req_uop_fpWen;
    req.uop.vecWen = req_uop_vecWen;
    req.uop.v0Wen = req_uop_v0Wen;
    req.uop.vlWen = req_uop_vlWen;
    req.uop.isXSTrap = req_uop_isXSTrap;
    req.uop.waitForward = req_uop_waitForward;
    req.uop.blockBackward = req_uop_blockBackward;
    req.uop.canRobCompress = req_uop_canRobCompress;
    req.uop.selImm = req_uop_selImm;
    req.uop.imm = req_uop_imm;
    req.uop.fpu_typeTagOut = req_uop_fpu_typeTagOut;
    req.uop.fpu_wflags = req_uop_fpu_wflags;
    req.uop.fpu_typ = req_uop_fpu_typ;
    req.uop.fpu_fmt = req_uop_fpu_fmt;
    req.uop.fpu_rm = req_uop_fpu_rm;
    req.uop.vpu_vill = req_uop_vpu_vill;
    req.uop.vpu_vma = req_uop_vpu_vma;
    req.uop.vpu_vta = req_uop_vpu_vta;
    req.uop.vpu_vsew = req_uop_vpu_vsew;
    req.uop.vpu_vlmul = req_uop_vpu_vlmul;
    req.uop.vpu_specVill = req_uop_vpu_specVill;
    req.uop.vpu_specVma = req_uop_vpu_specVma;
    req.uop.vpu_specVta = req_uop_vpu_specVta;
    req.uop.vpu_specVsew = req_uop_vpu_specVsew;
    req.uop.vpu_specVlmul = req_uop_vpu_specVlmul;
    req.uop.vpu_vm = req_uop_vpu_vm;
    req.uop.vpu_vstart = req_uop_vpu_vstart;
    req.uop.vpu_frm = req_uop_vpu_frm;
    req.uop.vpu_fpu_isFpToVecInst = req_uop_vpu_fpu_isFpToVecInst;
    req.uop.vpu_fpu_isFP32Instr = req_uop_vpu_fpu_isFP32Instr;
    req.uop.vpu_fpu_isFP64Instr = req_uop_vpu_fpu_isFP64Instr;
    req.uop.vpu_fpu_isReduction = req_uop_vpu_fpu_isReduction;
    req.uop.vpu_fpu_isFoldTo1_2 = req_uop_vpu_fpu_isFoldTo1_2;
    req.uop.vpu_fpu_isFoldTo1_4 = req_uop_vpu_fpu_isFoldTo1_4;
    req.uop.vpu_fpu_isFoldTo1_8 = req_uop_vpu_fpu_isFoldTo1_8;
    req.uop.vpu_vxrm = req_uop_vpu_vxrm;
    req.uop.vpu_vuopIdx = req_uop_vpu_vuopIdx;
    req.uop.vpu_lastUop = req_uop_vpu_lastUop;
    req.uop.vpu_vmask = req_uop_vpu_vmask;
    req.uop.vpu_vl = req_uop_vpu_vl;
    req.uop.vpu_nf = req_uop_vpu_nf;
    req.uop.vpu_veew = req_uop_vpu_veew;
    req.uop.vpu_isReverse = req_uop_vpu_isReverse;
    req.uop.vpu_isExt = req_uop_vpu_isExt;
    req.uop.vpu_isNarrow = req_uop_vpu_isNarrow;
    req.uop.vpu_isDstMask = req_uop_vpu_isDstMask;
    req.uop.vpu_isOpMask = req_uop_vpu_isOpMask;
    req.uop.vpu_isMove = req_uop_vpu_isMove;
    req.uop.vpu_isDependOldVd = req_uop_vpu_isDependOldVd;
    req.uop.vpu_isWritePartVd = req_uop_vpu_isWritePartVd;
    req.uop.vpu_isVleff = req_uop_vpu_isVleff;
    req.uop.vlsInstr = req_uop_vlsInstr;
    req.uop.wfflags = req_uop_wfflags;
    req.uop.isMove = req_uop_isMove;
    req.uop.isDropAmocasSta = req_uop_isDropAmocasSta;
    req.uop.uopIdx = req_uop_uopIdx;
    req.uop.isVset = req_uop_isVset;
    req.uop.firstUop = req_uop_firstUop;
    req.uop.lastUop = req_uop_lastUop;
    req.uop.numUops = req_uop_numUops;
    req.uop.numWB = req_uop_numWB;
    req.uop.commitType = req_uop_commitType;
    req.uop.srcState_0 = req_uop_srcState_0;
    req.uop.srcState_1 = req_uop_srcState_1;
    req.uop.srcState_2 = req_uop_srcState_2;
    req.uop.srcState_3 = req_uop_srcState_3;
    req.uop.srcState_4 = req_uop_srcState_4;
    req.uop.srcLoadDependency_0_0 = req_uop_srcLoadDependency_0_0;
    req.uop.srcLoadDependency_0_1 = req_uop_srcLoadDependency_0_1;
    req.uop.srcLoadDependency_0_2 = req_uop_srcLoadDependency_0_2;
    req.uop.srcLoadDependency_1_0 = req_uop_srcLoadDependency_1_0;
    req.uop.srcLoadDependency_1_1 = req_uop_srcLoadDependency_1_1;
    req.uop.srcLoadDependency_1_2 = req_uop_srcLoadDependency_1_2;
    req.uop.srcLoadDependency_2_0 = req_uop_srcLoadDependency_2_0;
    req.uop.srcLoadDependency_2_1 = req_uop_srcLoadDependency_2_1;
    req.uop.srcLoadDependency_2_2 = req_uop_srcLoadDependency_2_2;
    req.uop.srcLoadDependency_3_0 = req_uop_srcLoadDependency_3_0;
    req.uop.srcLoadDependency_3_1 = req_uop_srcLoadDependency_3_1;
    req.uop.srcLoadDependency_3_2 = req_uop_srcLoadDependency_3_2;
    req.uop.srcLoadDependency_4_0 = req_uop_srcLoadDependency_4_0;
    req.uop.srcLoadDependency_4_1 = req_uop_srcLoadDependency_4_1;
    req.uop.srcLoadDependency_4_2 = req_uop_srcLoadDependency_4_2;
    req.uop.psrc_0 = req_uop_psrc_0;
    req.uop.psrc_1 = req_uop_psrc_1;
    req.uop.psrc_2 = req_uop_psrc_2;
    req.uop.psrc_3 = req_uop_psrc_3;
    req.uop.psrc_4 = req_uop_psrc_4;
    req.uop.pdest = req_uop_pdest;
    req.uop.useRegCache_0 = req_uop_useRegCache_0;
    req.uop.useRegCache_1 = req_uop_useRegCache_1;
    req.uop.regCacheIdx_0 = req_uop_regCacheIdx_0;
    req.uop.regCacheIdx_1 = req_uop_regCacheIdx_1;
    req.uop.robIdx_flag = req_uop_robIdx_flag;
    req.uop.robIdx_value = req_uop_robIdx_value;
    req.uop.instrSize = req_uop_instrSize;
    req.uop.dirtyFs = req_uop_dirtyFs;
    req.uop.dirtyVs = req_uop_dirtyVs;
    req.uop.traceBlockInPipe_itype = req_uop_traceBlockInPipe_itype;
    req.uop.traceBlockInPipe_iretire = req_uop_traceBlockInPipe_iretire;
    req.uop.traceBlockInPipe_ilastsize = req_uop_traceBlockInPipe_ilastsize;
    req.uop.eliminatedMove = req_uop_eliminatedMove;
    req.uop.snapshot = req_uop_snapshot;
    req.uop.debugInfo_eliminatedMove = req_uop_debugInfo_eliminatedMove;
    req.uop.debugInfo_renameTime = req_uop_debugInfo_renameTime;
    req.uop.debugInfo_dispatchTime = req_uop_debugInfo_dispatchTime;
    req.uop.debugInfo_enqRsTime = req_uop_debugInfo_enqRsTime;
    req.uop.debugInfo_selectTime = req_uop_debugInfo_selectTime;
    req.uop.debugInfo_issueTime = req_uop_debugInfo_issueTime;
    req.uop.debugInfo_writebackTime = req_uop_debugInfo_writebackTime;
    req.uop.debugInfo_runahead_checkpoint_id = req_uop_debugInfo_runahead_checkpoint_id;
    req.uop.debugInfo_tlbFirstReqTime = req_uop_debugInfo_tlbFirstReqTime;
    req.uop.debugInfo_tlbRespTime = req_uop_debugInfo_tlbRespTime;
    req.uop.debug_seqNum_seqNum = req_uop_debug_seqNum_seqNum;
    req.uop.debug_seqNum_uopIdx = req_uop_debug_seqNum_uopIdx;
    req.uop.storeSetHit = req_uop_storeSetHit;
    req.uop.waitForRobIdx_flag = req_uop_waitForRobIdx_flag;
    req.uop.waitForRobIdx_value = req_uop_waitForRobIdx_value;
    req.uop.loadWaitBit = req_uop_loadWaitBit;
    req.uop.loadWaitStrict = req_uop_loadWaitStrict;
    req.uop.ssid = req_uop_ssid;
    req.uop.lqIdx_flag = req_uop_lqIdx_flag;
    req.uop.lqIdx_value = req_uop_lqIdx_value;
    req.uop.sqIdx_flag = req_uop_sqIdx_flag;
    req.uop.sqIdx_value = req_uop_sqIdx_value;
    req.uop.singleStep = req_uop_singleStep;
    req.uop.replayInst = req_uop_replayInst;
    req.uop.debug_fuType = req_uop_debug_fuType;
    req.uop.debug_sim_trig = req_uop_debug_sim_trig;
    req.uop.numLsElem = req_uop_numLsElem;
    req.vaddr = req_vaddr;
    req.fullva = req_fullva;
    req.vaNeedExt = req_vaNeedExt;
    req.paddr = req_paddr;
    req.gpaddr = req_gpaddr;
    req.mask = req_mask;
    req.isForVSnonLeafPTE = req_isForVSnonLeafPTE;
    req.isvec = req_isvec;
    req.elemIdx = req_elemIdx;
    req.alignedType = req_alignedType;
    req.mbIndex = req_mbIndex;
    req.elemIdxInsideVd = req_elemIdxInsideVd;
    req.vecTriggerMask = req_vecTriggerMask;
  end

  // ---- splitLoadReqs(0)：低地址那一半子访问（异步复位为 0；s_split 且跨 16B 时写入，见 §3）：golden 留下的 194 个字段 ----
  logic [31:0]    splitLoadReqs_0_uop_instr;
  logic [49:0]    splitLoadReqs_0_uop_pc;
  logic [9:0]     splitLoadReqs_0_uop_foldpc;
  logic           splitLoadReqs_0_uop_exceptionVec_0;
  logic           splitLoadReqs_0_uop_exceptionVec_1;
  logic           splitLoadReqs_0_uop_exceptionVec_2;
  logic           splitLoadReqs_0_uop_exceptionVec_3;
  logic           splitLoadReqs_0_uop_exceptionVec_4;
  logic           splitLoadReqs_0_uop_exceptionVec_5;
  logic           splitLoadReqs_0_uop_exceptionVec_6;
  logic           splitLoadReqs_0_uop_exceptionVec_7;
  logic           splitLoadReqs_0_uop_exceptionVec_8;
  logic           splitLoadReqs_0_uop_exceptionVec_9;
  logic           splitLoadReqs_0_uop_exceptionVec_10;
  logic           splitLoadReqs_0_uop_exceptionVec_11;
  logic           splitLoadReqs_0_uop_exceptionVec_12;
  logic           splitLoadReqs_0_uop_exceptionVec_13;
  logic           splitLoadReqs_0_uop_exceptionVec_14;
  logic           splitLoadReqs_0_uop_exceptionVec_15;
  logic           splitLoadReqs_0_uop_exceptionVec_16;
  logic           splitLoadReqs_0_uop_exceptionVec_17;
  logic           splitLoadReqs_0_uop_exceptionVec_18;
  logic           splitLoadReqs_0_uop_exceptionVec_19;
  logic           splitLoadReqs_0_uop_exceptionVec_20;
  logic           splitLoadReqs_0_uop_exceptionVec_21;
  logic           splitLoadReqs_0_uop_exceptionVec_22;
  logic           splitLoadReqs_0_uop_exceptionVec_23;
  logic           splitLoadReqs_0_uop_isFetchMalAddr;
  logic           splitLoadReqs_0_uop_hasException;
  logic [3:0]     splitLoadReqs_0_uop_trigger;
  logic           splitLoadReqs_0_uop_preDecodeInfo_valid;
  logic           splitLoadReqs_0_uop_preDecodeInfo_isRVC;
  logic [1:0]     splitLoadReqs_0_uop_preDecodeInfo_brType;
  logic           splitLoadReqs_0_uop_preDecodeInfo_isCall;
  logic           splitLoadReqs_0_uop_preDecodeInfo_isRet;
  logic           splitLoadReqs_0_uop_pred_taken;
  logic           splitLoadReqs_0_uop_crossPageIPFFix;
  logic           splitLoadReqs_0_uop_ftqPtr_flag;
  logic [5:0]     splitLoadReqs_0_uop_ftqPtr_value;
  logic [3:0]     splitLoadReqs_0_uop_ftqOffset;
  logic           splitLoadReqs_0_uop_satpFlushFirstFetchFault;
  logic [3:0]     splitLoadReqs_0_uop_srcType_0;
  logic [3:0]     splitLoadReqs_0_uop_srcType_1;
  logic [3:0]     splitLoadReqs_0_uop_srcType_2;
  logic [3:0]     splitLoadReqs_0_uop_srcType_3;
  logic [3:0]     splitLoadReqs_0_uop_srcType_4;
  logic [5:0]     splitLoadReqs_0_uop_ldest;
  logic [34:0]    splitLoadReqs_0_uop_fuType;
  logic [8:0]     splitLoadReqs_0_uop_fuOpType;
  logic           splitLoadReqs_0_uop_rfWen;
  logic           splitLoadReqs_0_uop_fpWen;
  logic           splitLoadReqs_0_uop_vecWen;
  logic           splitLoadReqs_0_uop_v0Wen;
  logic           splitLoadReqs_0_uop_vlWen;
  logic           splitLoadReqs_0_uop_isXSTrap;
  logic           splitLoadReqs_0_uop_waitForward;
  logic           splitLoadReqs_0_uop_blockBackward;
  logic           splitLoadReqs_0_uop_flushPipe;
  logic           splitLoadReqs_0_uop_canRobCompress;
  logic [3:0]     splitLoadReqs_0_uop_selImm;
  logic [31:0]    splitLoadReqs_0_uop_imm;
  logic [1:0]     splitLoadReqs_0_uop_fpu_typeTagOut;
  logic           splitLoadReqs_0_uop_fpu_wflags;
  logic [1:0]     splitLoadReqs_0_uop_fpu_typ;
  logic [1:0]     splitLoadReqs_0_uop_fpu_fmt;
  logic [2:0]     splitLoadReqs_0_uop_fpu_rm;
  logic           splitLoadReqs_0_uop_vpu_vill;
  logic           splitLoadReqs_0_uop_vpu_vma;
  logic           splitLoadReqs_0_uop_vpu_vta;
  logic [1:0]     splitLoadReqs_0_uop_vpu_vsew;
  logic [2:0]     splitLoadReqs_0_uop_vpu_vlmul;
  logic           splitLoadReqs_0_uop_vpu_specVill;
  logic           splitLoadReqs_0_uop_vpu_specVma;
  logic           splitLoadReqs_0_uop_vpu_specVta;
  logic [1:0]     splitLoadReqs_0_uop_vpu_specVsew;
  logic [2:0]     splitLoadReqs_0_uop_vpu_specVlmul;
  logic           splitLoadReqs_0_uop_vpu_vm;
  logic [7:0]     splitLoadReqs_0_uop_vpu_vstart;
  logic [2:0]     splitLoadReqs_0_uop_vpu_frm;
  logic           splitLoadReqs_0_uop_vpu_fpu_isFpToVecInst;
  logic           splitLoadReqs_0_uop_vpu_fpu_isFP32Instr;
  logic           splitLoadReqs_0_uop_vpu_fpu_isFP64Instr;
  logic           splitLoadReqs_0_uop_vpu_fpu_isReduction;
  logic           splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_2;
  logic           splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_4;
  logic           splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]     splitLoadReqs_0_uop_vpu_vxrm;
  logic [6:0]     splitLoadReqs_0_uop_vpu_vuopIdx;
  logic           splitLoadReqs_0_uop_vpu_lastUop;
  logic [127:0]   splitLoadReqs_0_uop_vpu_vmask;
  logic [7:0]     splitLoadReqs_0_uop_vpu_vl;
  logic [2:0]     splitLoadReqs_0_uop_vpu_nf;
  logic [1:0]     splitLoadReqs_0_uop_vpu_veew;
  logic           splitLoadReqs_0_uop_vpu_isReverse;
  logic           splitLoadReqs_0_uop_vpu_isExt;
  logic           splitLoadReqs_0_uop_vpu_isNarrow;
  logic           splitLoadReqs_0_uop_vpu_isDstMask;
  logic           splitLoadReqs_0_uop_vpu_isOpMask;
  logic           splitLoadReqs_0_uop_vpu_isMove;
  logic           splitLoadReqs_0_uop_vpu_isDependOldVd;
  logic           splitLoadReqs_0_uop_vpu_isWritePartVd;
  logic           splitLoadReqs_0_uop_vpu_isVleff;
  logic           splitLoadReqs_0_uop_vlsInstr;
  logic           splitLoadReqs_0_uop_wfflags;
  logic           splitLoadReqs_0_uop_isMove;
  logic           splitLoadReqs_0_uop_isDropAmocasSta;
  logic [6:0]     splitLoadReqs_0_uop_uopIdx;
  logic           splitLoadReqs_0_uop_isVset;
  logic           splitLoadReqs_0_uop_firstUop;
  logic           splitLoadReqs_0_uop_lastUop;
  logic [6:0]     splitLoadReqs_0_uop_numUops;
  logic [6:0]     splitLoadReqs_0_uop_numWB;
  logic [2:0]     splitLoadReqs_0_uop_commitType;
  logic           splitLoadReqs_0_uop_srcState_0;
  logic           splitLoadReqs_0_uop_srcState_1;
  logic           splitLoadReqs_0_uop_srcState_2;
  logic           splitLoadReqs_0_uop_srcState_3;
  logic           splitLoadReqs_0_uop_srcState_4;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_0_0;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_0_1;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_0_2;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_1_0;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_1_1;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_1_2;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_2_0;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_2_1;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_2_2;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_3_0;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_3_1;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_3_2;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_4_0;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_4_1;
  logic [1:0]     splitLoadReqs_0_uop_srcLoadDependency_4_2;
  logic [7:0]     splitLoadReqs_0_uop_psrc_0;
  logic [7:0]     splitLoadReqs_0_uop_psrc_1;
  logic [7:0]     splitLoadReqs_0_uop_psrc_2;
  logic [7:0]     splitLoadReqs_0_uop_psrc_3;
  logic [7:0]     splitLoadReqs_0_uop_psrc_4;
  logic [7:0]     splitLoadReqs_0_uop_pdest;
  logic           splitLoadReqs_0_uop_useRegCache_0;
  logic           splitLoadReqs_0_uop_useRegCache_1;
  logic [4:0]     splitLoadReqs_0_uop_regCacheIdx_0;
  logic [4:0]     splitLoadReqs_0_uop_regCacheIdx_1;
  logic           splitLoadReqs_0_uop_robIdx_flag;
  logic [7:0]     splitLoadReqs_0_uop_robIdx_value;
  logic [2:0]     splitLoadReqs_0_uop_instrSize;
  logic           splitLoadReqs_0_uop_dirtyFs;
  logic           splitLoadReqs_0_uop_dirtyVs;
  logic [3:0]     splitLoadReqs_0_uop_traceBlockInPipe_itype;
  logic [3:0]     splitLoadReqs_0_uop_traceBlockInPipe_iretire;
  logic           splitLoadReqs_0_uop_traceBlockInPipe_ilastsize;
  logic           splitLoadReqs_0_uop_eliminatedMove;
  logic           splitLoadReqs_0_uop_snapshot;
  logic           splitLoadReqs_0_uop_debugInfo_eliminatedMove;
  logic [63:0]    splitLoadReqs_0_uop_debugInfo_renameTime;
  logic [63:0]    splitLoadReqs_0_uop_debugInfo_dispatchTime;
  logic [63:0]    splitLoadReqs_0_uop_debugInfo_enqRsTime;
  logic [63:0]    splitLoadReqs_0_uop_debugInfo_selectTime;
  logic [63:0]    splitLoadReqs_0_uop_debugInfo_issueTime;
  logic [63:0]    splitLoadReqs_0_uop_debugInfo_writebackTime;
  logic [63:0]    splitLoadReqs_0_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]    splitLoadReqs_0_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]    splitLoadReqs_0_uop_debugInfo_tlbRespTime;
  logic [55:0]    splitLoadReqs_0_uop_debug_seqNum_seqNum;
  logic [7:0]     splitLoadReqs_0_uop_debug_seqNum_uopIdx;
  logic           splitLoadReqs_0_uop_storeSetHit;
  logic           splitLoadReqs_0_uop_waitForRobIdx_flag;
  logic [7:0]     splitLoadReqs_0_uop_waitForRobIdx_value;
  logic           splitLoadReqs_0_uop_loadWaitBit;
  logic           splitLoadReqs_0_uop_loadWaitStrict;
  logic [4:0]     splitLoadReqs_0_uop_ssid;
  logic           splitLoadReqs_0_uop_lqIdx_flag;
  logic [6:0]     splitLoadReqs_0_uop_lqIdx_value;
  logic           splitLoadReqs_0_uop_sqIdx_flag;
  logic [5:0]     splitLoadReqs_0_uop_sqIdx_value;
  logic           splitLoadReqs_0_uop_singleStep;
  logic           splitLoadReqs_0_uop_replayInst;
  logic [34:0]    splitLoadReqs_0_uop_debug_fuType;
  logic           splitLoadReqs_0_uop_debug_sim_trig;
  logic [4:0]     splitLoadReqs_0_uop_numLsElem;
  logic [49:0]    splitLoadReqs_0_vaddr;
  logic [63:0]    splitLoadReqs_0_fullva;
  logic           splitLoadReqs_0_vaNeedExt;
  logic [47:0]    splitLoadReqs_0_paddr;
  logic [63:0]    splitLoadReqs_0_gpaddr;
  logic [15:0]    splitLoadReqs_0_mask;
  logic           splitLoadReqs_0_nc;
  logic           splitLoadReqs_0_mmio;
  logic           splitLoadReqs_0_memBackTypeMM;
  logic           splitLoadReqs_0_isForVSnonLeafPTE;
  logic           splitLoadReqs_0_is128bit;
  logic           splitLoadReqs_0_vecActive;
  logic [3:0]     splitLoadReqs_0_mshrid;
  logic [6:0]     splitLoadReqs_0_schedIndex;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      splitLoadReqs_0_uop_instr <= '0;
      splitLoadReqs_0_uop_pc <= '0;
      splitLoadReqs_0_uop_foldpc <= '0;
      splitLoadReqs_0_uop_exceptionVec_0 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_1 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_2 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_3 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_4 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_5 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_6 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_7 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_8 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_9 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_10 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_11 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_12 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_13 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_14 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_15 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_16 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_17 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_18 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_19 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_20 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_21 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_22 <= 1'b0;
      splitLoadReqs_0_uop_exceptionVec_23 <= 1'b0;
      splitLoadReqs_0_uop_isFetchMalAddr <= 1'b0;
      splitLoadReqs_0_uop_hasException <= 1'b0;
      splitLoadReqs_0_uop_trigger <= '0;
      splitLoadReqs_0_uop_preDecodeInfo_valid <= 1'b0;
      splitLoadReqs_0_uop_preDecodeInfo_isRVC <= 1'b0;
      splitLoadReqs_0_uop_preDecodeInfo_brType <= '0;
      splitLoadReqs_0_uop_preDecodeInfo_isCall <= 1'b0;
      splitLoadReqs_0_uop_preDecodeInfo_isRet <= 1'b0;
      splitLoadReqs_0_uop_pred_taken <= 1'b0;
      splitLoadReqs_0_uop_crossPageIPFFix <= 1'b0;
      splitLoadReqs_0_uop_ftqPtr_flag <= 1'b0;
      splitLoadReqs_0_uop_ftqPtr_value <= '0;
      splitLoadReqs_0_uop_ftqOffset <= '0;
      splitLoadReqs_0_uop_satpFlushFirstFetchFault <= 1'b0;
      splitLoadReqs_0_uop_srcType_0 <= '0;
      splitLoadReqs_0_uop_srcType_1 <= '0;
      splitLoadReqs_0_uop_srcType_2 <= '0;
      splitLoadReqs_0_uop_srcType_3 <= '0;
      splitLoadReqs_0_uop_srcType_4 <= '0;
      splitLoadReqs_0_uop_ldest <= '0;
      splitLoadReqs_0_uop_fuType <= '0;
      splitLoadReqs_0_uop_fuOpType <= '0;
      splitLoadReqs_0_uop_rfWen <= 1'b0;
      splitLoadReqs_0_uop_fpWen <= 1'b0;
      splitLoadReqs_0_uop_vecWen <= 1'b0;
      splitLoadReqs_0_uop_v0Wen <= 1'b0;
      splitLoadReqs_0_uop_vlWen <= 1'b0;
      splitLoadReqs_0_uop_isXSTrap <= 1'b0;
      splitLoadReqs_0_uop_waitForward <= 1'b0;
      splitLoadReqs_0_uop_blockBackward <= 1'b0;
      splitLoadReqs_0_uop_flushPipe <= 1'b0;
      splitLoadReqs_0_uop_canRobCompress <= 1'b0;
      splitLoadReqs_0_uop_selImm <= '0;
      splitLoadReqs_0_uop_imm <= '0;
      splitLoadReqs_0_uop_fpu_typeTagOut <= '0;
      splitLoadReqs_0_uop_fpu_wflags <= 1'b0;
      splitLoadReqs_0_uop_fpu_typ <= '0;
      splitLoadReqs_0_uop_fpu_fmt <= '0;
      splitLoadReqs_0_uop_fpu_rm <= '0;
      splitLoadReqs_0_uop_vpu_vill <= 1'b0;
      splitLoadReqs_0_uop_vpu_vma <= 1'b0;
      splitLoadReqs_0_uop_vpu_vta <= 1'b0;
      splitLoadReqs_0_uop_vpu_vsew <= '0;
      splitLoadReqs_0_uop_vpu_vlmul <= '0;
      splitLoadReqs_0_uop_vpu_specVill <= 1'b0;
      splitLoadReqs_0_uop_vpu_specVma <= 1'b0;
      splitLoadReqs_0_uop_vpu_specVta <= 1'b0;
      splitLoadReqs_0_uop_vpu_specVsew <= '0;
      splitLoadReqs_0_uop_vpu_specVlmul <= '0;
      splitLoadReqs_0_uop_vpu_vm <= 1'b0;
      splitLoadReqs_0_uop_vpu_vstart <= '0;
      splitLoadReqs_0_uop_vpu_frm <= '0;
      splitLoadReqs_0_uop_vpu_fpu_isFpToVecInst <= 1'b0;
      splitLoadReqs_0_uop_vpu_fpu_isFP32Instr <= 1'b0;
      splitLoadReqs_0_uop_vpu_fpu_isFP64Instr <= 1'b0;
      splitLoadReqs_0_uop_vpu_fpu_isReduction <= 1'b0;
      splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_2 <= 1'b0;
      splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_4 <= 1'b0;
      splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_8 <= 1'b0;
      splitLoadReqs_0_uop_vpu_vxrm <= '0;
      splitLoadReqs_0_uop_vpu_vuopIdx <= '0;
      splitLoadReqs_0_uop_vpu_lastUop <= 1'b0;
      splitLoadReqs_0_uop_vpu_vmask <= '0;
      splitLoadReqs_0_uop_vpu_vl <= '0;
      splitLoadReqs_0_uop_vpu_nf <= '0;
      splitLoadReqs_0_uop_vpu_veew <= '0;
      splitLoadReqs_0_uop_vpu_isReverse <= 1'b0;
      splitLoadReqs_0_uop_vpu_isExt <= 1'b0;
      splitLoadReqs_0_uop_vpu_isNarrow <= 1'b0;
      splitLoadReqs_0_uop_vpu_isDstMask <= 1'b0;
      splitLoadReqs_0_uop_vpu_isOpMask <= 1'b0;
      splitLoadReqs_0_uop_vpu_isMove <= 1'b0;
      splitLoadReqs_0_uop_vpu_isDependOldVd <= 1'b0;
      splitLoadReqs_0_uop_vpu_isWritePartVd <= 1'b0;
      splitLoadReqs_0_uop_vpu_isVleff <= 1'b0;
      splitLoadReqs_0_uop_vlsInstr <= 1'b0;
      splitLoadReqs_0_uop_wfflags <= 1'b0;
      splitLoadReqs_0_uop_isMove <= 1'b0;
      splitLoadReqs_0_uop_isDropAmocasSta <= 1'b0;
      splitLoadReqs_0_uop_uopIdx <= '0;
      splitLoadReqs_0_uop_isVset <= 1'b0;
      splitLoadReqs_0_uop_firstUop <= 1'b0;
      splitLoadReqs_0_uop_lastUop <= 1'b0;
      splitLoadReqs_0_uop_numUops <= '0;
      splitLoadReqs_0_uop_numWB <= '0;
      splitLoadReqs_0_uop_commitType <= '0;
      splitLoadReqs_0_uop_srcState_0 <= 1'b0;
      splitLoadReqs_0_uop_srcState_1 <= 1'b0;
      splitLoadReqs_0_uop_srcState_2 <= 1'b0;
      splitLoadReqs_0_uop_srcState_3 <= 1'b0;
      splitLoadReqs_0_uop_srcState_4 <= 1'b0;
      splitLoadReqs_0_uop_srcLoadDependency_0_0 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_0_1 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_0_2 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_1_0 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_1_1 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_1_2 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_2_0 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_2_1 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_2_2 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_3_0 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_3_1 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_3_2 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_4_0 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_4_1 <= '0;
      splitLoadReqs_0_uop_srcLoadDependency_4_2 <= '0;
      splitLoadReqs_0_uop_psrc_0 <= '0;
      splitLoadReqs_0_uop_psrc_1 <= '0;
      splitLoadReqs_0_uop_psrc_2 <= '0;
      splitLoadReqs_0_uop_psrc_3 <= '0;
      splitLoadReqs_0_uop_psrc_4 <= '0;
      splitLoadReqs_0_uop_pdest <= '0;
      splitLoadReqs_0_uop_useRegCache_0 <= 1'b0;
      splitLoadReqs_0_uop_useRegCache_1 <= 1'b0;
      splitLoadReqs_0_uop_regCacheIdx_0 <= '0;
      splitLoadReqs_0_uop_regCacheIdx_1 <= '0;
      splitLoadReqs_0_uop_robIdx_flag <= 1'b0;
      splitLoadReqs_0_uop_robIdx_value <= '0;
      splitLoadReqs_0_uop_instrSize <= '0;
      splitLoadReqs_0_uop_dirtyFs <= 1'b0;
      splitLoadReqs_0_uop_dirtyVs <= 1'b0;
      splitLoadReqs_0_uop_traceBlockInPipe_itype <= '0;
      splitLoadReqs_0_uop_traceBlockInPipe_iretire <= '0;
      splitLoadReqs_0_uop_traceBlockInPipe_ilastsize <= 1'b0;
      splitLoadReqs_0_uop_eliminatedMove <= 1'b0;
      splitLoadReqs_0_uop_snapshot <= 1'b0;
      splitLoadReqs_0_uop_debugInfo_eliminatedMove <= 1'b0;
      splitLoadReqs_0_uop_debugInfo_renameTime <= '0;
      splitLoadReqs_0_uop_debugInfo_dispatchTime <= '0;
      splitLoadReqs_0_uop_debugInfo_enqRsTime <= '0;
      splitLoadReqs_0_uop_debugInfo_selectTime <= '0;
      splitLoadReqs_0_uop_debugInfo_issueTime <= '0;
      splitLoadReqs_0_uop_debugInfo_writebackTime <= '0;
      splitLoadReqs_0_uop_debugInfo_runahead_checkpoint_id <= '0;
      splitLoadReqs_0_uop_debugInfo_tlbFirstReqTime <= '0;
      splitLoadReqs_0_uop_debugInfo_tlbRespTime <= '0;
      splitLoadReqs_0_uop_debug_seqNum_seqNum <= '0;
      splitLoadReqs_0_uop_debug_seqNum_uopIdx <= '0;
      splitLoadReqs_0_uop_storeSetHit <= 1'b0;
      splitLoadReqs_0_uop_waitForRobIdx_flag <= 1'b0;
      splitLoadReqs_0_uop_waitForRobIdx_value <= '0;
      splitLoadReqs_0_uop_loadWaitBit <= 1'b0;
      splitLoadReqs_0_uop_loadWaitStrict <= 1'b0;
      splitLoadReqs_0_uop_ssid <= '0;
      splitLoadReqs_0_uop_lqIdx_flag <= 1'b0;
      splitLoadReqs_0_uop_lqIdx_value <= '0;
      splitLoadReqs_0_uop_sqIdx_flag <= 1'b0;
      splitLoadReqs_0_uop_sqIdx_value <= '0;
      splitLoadReqs_0_uop_singleStep <= 1'b0;
      splitLoadReqs_0_uop_replayInst <= 1'b0;
      splitLoadReqs_0_uop_debug_fuType <= '0;
      splitLoadReqs_0_uop_debug_sim_trig <= 1'b0;
      splitLoadReqs_0_uop_numLsElem <= '0;
      splitLoadReqs_0_vaddr <= '0;
      splitLoadReqs_0_fullva <= '0;
      splitLoadReqs_0_vaNeedExt <= 1'b0;
      splitLoadReqs_0_paddr <= '0;
      splitLoadReqs_0_gpaddr <= '0;
      splitLoadReqs_0_mask <= '0;
      splitLoadReqs_0_nc <= 1'b0;
      splitLoadReqs_0_mmio <= 1'b0;
      splitLoadReqs_0_memBackTypeMM <= 1'b0;
      splitLoadReqs_0_isForVSnonLeafPTE <= 1'b0;
      splitLoadReqs_0_is128bit <= 1'b0;
      splitLoadReqs_0_vecActive <= 1'b0;
      splitLoadReqs_0_mshrid <= '0;
      splitLoadReqs_0_schedIndex <= '0;
    end else if (split_now) begin
      splitLoadReqs_0_uop_instr <= split_new[0].uop.instr;
      splitLoadReqs_0_uop_pc <= split_new[0].uop.pc;
      splitLoadReqs_0_uop_foldpc <= split_new[0].uop.foldpc;
      splitLoadReqs_0_uop_exceptionVec_0 <= split_new[0].uop.exceptionVec[0];
      splitLoadReqs_0_uop_exceptionVec_1 <= split_new[0].uop.exceptionVec[1];
      splitLoadReqs_0_uop_exceptionVec_2 <= split_new[0].uop.exceptionVec[2];
      splitLoadReqs_0_uop_exceptionVec_3 <= split_new[0].uop.exceptionVec[3];
      splitLoadReqs_0_uop_exceptionVec_4 <= split_new[0].uop.exceptionVec[4];
      splitLoadReqs_0_uop_exceptionVec_5 <= split_new[0].uop.exceptionVec[5];
      splitLoadReqs_0_uop_exceptionVec_6 <= split_new[0].uop.exceptionVec[6];
      splitLoadReqs_0_uop_exceptionVec_7 <= split_new[0].uop.exceptionVec[7];
      splitLoadReqs_0_uop_exceptionVec_8 <= split_new[0].uop.exceptionVec[8];
      splitLoadReqs_0_uop_exceptionVec_9 <= split_new[0].uop.exceptionVec[9];
      splitLoadReqs_0_uop_exceptionVec_10 <= split_new[0].uop.exceptionVec[10];
      splitLoadReqs_0_uop_exceptionVec_11 <= split_new[0].uop.exceptionVec[11];
      splitLoadReqs_0_uop_exceptionVec_12 <= split_new[0].uop.exceptionVec[12];
      splitLoadReqs_0_uop_exceptionVec_13 <= split_new[0].uop.exceptionVec[13];
      splitLoadReqs_0_uop_exceptionVec_14 <= split_new[0].uop.exceptionVec[14];
      splitLoadReqs_0_uop_exceptionVec_15 <= split_new[0].uop.exceptionVec[15];
      splitLoadReqs_0_uop_exceptionVec_16 <= split_new[0].uop.exceptionVec[16];
      splitLoadReqs_0_uop_exceptionVec_17 <= split_new[0].uop.exceptionVec[17];
      splitLoadReqs_0_uop_exceptionVec_18 <= split_new[0].uop.exceptionVec[18];
      splitLoadReqs_0_uop_exceptionVec_19 <= split_new[0].uop.exceptionVec[19];
      splitLoadReqs_0_uop_exceptionVec_20 <= split_new[0].uop.exceptionVec[20];
      splitLoadReqs_0_uop_exceptionVec_21 <= split_new[0].uop.exceptionVec[21];
      splitLoadReqs_0_uop_exceptionVec_22 <= split_new[0].uop.exceptionVec[22];
      splitLoadReqs_0_uop_exceptionVec_23 <= split_new[0].uop.exceptionVec[23];
      splitLoadReqs_0_uop_isFetchMalAddr <= split_new[0].uop.isFetchMalAddr;
      splitLoadReqs_0_uop_hasException <= split_new[0].uop.hasException;
      splitLoadReqs_0_uop_trigger <= split_new[0].uop.trigger;
      splitLoadReqs_0_uop_preDecodeInfo_valid <= split_new[0].uop.preDecodeInfo_valid;
      splitLoadReqs_0_uop_preDecodeInfo_isRVC <= split_new[0].uop.preDecodeInfo_isRVC;
      splitLoadReqs_0_uop_preDecodeInfo_brType <= split_new[0].uop.preDecodeInfo_brType;
      splitLoadReqs_0_uop_preDecodeInfo_isCall <= split_new[0].uop.preDecodeInfo_isCall;
      splitLoadReqs_0_uop_preDecodeInfo_isRet <= split_new[0].uop.preDecodeInfo_isRet;
      splitLoadReqs_0_uop_pred_taken <= split_new[0].uop.pred_taken;
      splitLoadReqs_0_uop_crossPageIPFFix <= split_new[0].uop.crossPageIPFFix;
      splitLoadReqs_0_uop_ftqPtr_flag <= split_new[0].uop.ftqPtr_flag;
      splitLoadReqs_0_uop_ftqPtr_value <= split_new[0].uop.ftqPtr_value;
      splitLoadReqs_0_uop_ftqOffset <= split_new[0].uop.ftqOffset;
      splitLoadReqs_0_uop_satpFlushFirstFetchFault <= split_new[0].uop.satpFlushFirstFetchFault;
      splitLoadReqs_0_uop_srcType_0 <= split_new[0].uop.srcType_0;
      splitLoadReqs_0_uop_srcType_1 <= split_new[0].uop.srcType_1;
      splitLoadReqs_0_uop_srcType_2 <= split_new[0].uop.srcType_2;
      splitLoadReqs_0_uop_srcType_3 <= split_new[0].uop.srcType_3;
      splitLoadReqs_0_uop_srcType_4 <= split_new[0].uop.srcType_4;
      splitLoadReqs_0_uop_ldest <= split_new[0].uop.ldest;
      splitLoadReqs_0_uop_fuType <= split_new[0].uop.fuType;
      splitLoadReqs_0_uop_fuOpType <= split_new[0].uop.fuOpType;
      splitLoadReqs_0_uop_rfWen <= split_new[0].uop.rfWen;
      splitLoadReqs_0_uop_fpWen <= split_new[0].uop.fpWen;
      splitLoadReqs_0_uop_vecWen <= split_new[0].uop.vecWen;
      splitLoadReqs_0_uop_v0Wen <= split_new[0].uop.v0Wen;
      splitLoadReqs_0_uop_vlWen <= split_new[0].uop.vlWen;
      splitLoadReqs_0_uop_isXSTrap <= split_new[0].uop.isXSTrap;
      splitLoadReqs_0_uop_waitForward <= split_new[0].uop.waitForward;
      splitLoadReqs_0_uop_blockBackward <= split_new[0].uop.blockBackward;
      splitLoadReqs_0_uop_flushPipe <= split_new[0].uop.flushPipe;
      splitLoadReqs_0_uop_canRobCompress <= split_new[0].uop.canRobCompress;
      splitLoadReqs_0_uop_selImm <= split_new[0].uop.selImm;
      splitLoadReqs_0_uop_imm <= split_new[0].uop.imm;
      splitLoadReqs_0_uop_fpu_typeTagOut <= split_new[0].uop.fpu_typeTagOut;
      splitLoadReqs_0_uop_fpu_wflags <= split_new[0].uop.fpu_wflags;
      splitLoadReqs_0_uop_fpu_typ <= split_new[0].uop.fpu_typ;
      splitLoadReqs_0_uop_fpu_fmt <= split_new[0].uop.fpu_fmt;
      splitLoadReqs_0_uop_fpu_rm <= split_new[0].uop.fpu_rm;
      splitLoadReqs_0_uop_vpu_vill <= split_new[0].uop.vpu_vill;
      splitLoadReqs_0_uop_vpu_vma <= split_new[0].uop.vpu_vma;
      splitLoadReqs_0_uop_vpu_vta <= split_new[0].uop.vpu_vta;
      splitLoadReqs_0_uop_vpu_vsew <= split_new[0].uop.vpu_vsew;
      splitLoadReqs_0_uop_vpu_vlmul <= split_new[0].uop.vpu_vlmul;
      splitLoadReqs_0_uop_vpu_specVill <= split_new[0].uop.vpu_specVill;
      splitLoadReqs_0_uop_vpu_specVma <= split_new[0].uop.vpu_specVma;
      splitLoadReqs_0_uop_vpu_specVta <= split_new[0].uop.vpu_specVta;
      splitLoadReqs_0_uop_vpu_specVsew <= split_new[0].uop.vpu_specVsew;
      splitLoadReqs_0_uop_vpu_specVlmul <= split_new[0].uop.vpu_specVlmul;
      splitLoadReqs_0_uop_vpu_vm <= split_new[0].uop.vpu_vm;
      splitLoadReqs_0_uop_vpu_vstart <= split_new[0].uop.vpu_vstart;
      splitLoadReqs_0_uop_vpu_frm <= split_new[0].uop.vpu_frm;
      splitLoadReqs_0_uop_vpu_fpu_isFpToVecInst <= split_new[0].uop.vpu_fpu_isFpToVecInst;
      splitLoadReqs_0_uop_vpu_fpu_isFP32Instr <= split_new[0].uop.vpu_fpu_isFP32Instr;
      splitLoadReqs_0_uop_vpu_fpu_isFP64Instr <= split_new[0].uop.vpu_fpu_isFP64Instr;
      splitLoadReqs_0_uop_vpu_fpu_isReduction <= split_new[0].uop.vpu_fpu_isReduction;
      splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_2 <= split_new[0].uop.vpu_fpu_isFoldTo1_2;
      splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_4 <= split_new[0].uop.vpu_fpu_isFoldTo1_4;
      splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_8 <= split_new[0].uop.vpu_fpu_isFoldTo1_8;
      splitLoadReqs_0_uop_vpu_vxrm <= split_new[0].uop.vpu_vxrm;
      splitLoadReqs_0_uop_vpu_vuopIdx <= split_new[0].uop.vpu_vuopIdx;
      splitLoadReqs_0_uop_vpu_lastUop <= split_new[0].uop.vpu_lastUop;
      splitLoadReqs_0_uop_vpu_vmask <= split_new[0].uop.vpu_vmask;
      splitLoadReqs_0_uop_vpu_vl <= split_new[0].uop.vpu_vl;
      splitLoadReqs_0_uop_vpu_nf <= split_new[0].uop.vpu_nf;
      splitLoadReqs_0_uop_vpu_veew <= split_new[0].uop.vpu_veew;
      splitLoadReqs_0_uop_vpu_isReverse <= split_new[0].uop.vpu_isReverse;
      splitLoadReqs_0_uop_vpu_isExt <= split_new[0].uop.vpu_isExt;
      splitLoadReqs_0_uop_vpu_isNarrow <= split_new[0].uop.vpu_isNarrow;
      splitLoadReqs_0_uop_vpu_isDstMask <= split_new[0].uop.vpu_isDstMask;
      splitLoadReqs_0_uop_vpu_isOpMask <= split_new[0].uop.vpu_isOpMask;
      splitLoadReqs_0_uop_vpu_isMove <= split_new[0].uop.vpu_isMove;
      splitLoadReqs_0_uop_vpu_isDependOldVd <= split_new[0].uop.vpu_isDependOldVd;
      splitLoadReqs_0_uop_vpu_isWritePartVd <= split_new[0].uop.vpu_isWritePartVd;
      splitLoadReqs_0_uop_vpu_isVleff <= split_new[0].uop.vpu_isVleff;
      splitLoadReqs_0_uop_vlsInstr <= split_new[0].uop.vlsInstr;
      splitLoadReqs_0_uop_wfflags <= split_new[0].uop.wfflags;
      splitLoadReqs_0_uop_isMove <= split_new[0].uop.isMove;
      splitLoadReqs_0_uop_isDropAmocasSta <= split_new[0].uop.isDropAmocasSta;
      splitLoadReqs_0_uop_uopIdx <= split_new[0].uop.uopIdx;
      splitLoadReqs_0_uop_isVset <= split_new[0].uop.isVset;
      splitLoadReqs_0_uop_firstUop <= split_new[0].uop.firstUop;
      splitLoadReqs_0_uop_lastUop <= split_new[0].uop.lastUop;
      splitLoadReqs_0_uop_numUops <= split_new[0].uop.numUops;
      splitLoadReqs_0_uop_numWB <= split_new[0].uop.numWB;
      splitLoadReqs_0_uop_commitType <= split_new[0].uop.commitType;
      splitLoadReqs_0_uop_srcState_0 <= split_new[0].uop.srcState_0;
      splitLoadReqs_0_uop_srcState_1 <= split_new[0].uop.srcState_1;
      splitLoadReqs_0_uop_srcState_2 <= split_new[0].uop.srcState_2;
      splitLoadReqs_0_uop_srcState_3 <= split_new[0].uop.srcState_3;
      splitLoadReqs_0_uop_srcState_4 <= split_new[0].uop.srcState_4;
      splitLoadReqs_0_uop_srcLoadDependency_0_0 <= split_new[0].uop.srcLoadDependency_0_0;
      splitLoadReqs_0_uop_srcLoadDependency_0_1 <= split_new[0].uop.srcLoadDependency_0_1;
      splitLoadReqs_0_uop_srcLoadDependency_0_2 <= split_new[0].uop.srcLoadDependency_0_2;
      splitLoadReqs_0_uop_srcLoadDependency_1_0 <= split_new[0].uop.srcLoadDependency_1_0;
      splitLoadReqs_0_uop_srcLoadDependency_1_1 <= split_new[0].uop.srcLoadDependency_1_1;
      splitLoadReqs_0_uop_srcLoadDependency_1_2 <= split_new[0].uop.srcLoadDependency_1_2;
      splitLoadReqs_0_uop_srcLoadDependency_2_0 <= split_new[0].uop.srcLoadDependency_2_0;
      splitLoadReqs_0_uop_srcLoadDependency_2_1 <= split_new[0].uop.srcLoadDependency_2_1;
      splitLoadReqs_0_uop_srcLoadDependency_2_2 <= split_new[0].uop.srcLoadDependency_2_2;
      splitLoadReqs_0_uop_srcLoadDependency_3_0 <= split_new[0].uop.srcLoadDependency_3_0;
      splitLoadReqs_0_uop_srcLoadDependency_3_1 <= split_new[0].uop.srcLoadDependency_3_1;
      splitLoadReqs_0_uop_srcLoadDependency_3_2 <= split_new[0].uop.srcLoadDependency_3_2;
      splitLoadReqs_0_uop_srcLoadDependency_4_0 <= split_new[0].uop.srcLoadDependency_4_0;
      splitLoadReqs_0_uop_srcLoadDependency_4_1 <= split_new[0].uop.srcLoadDependency_4_1;
      splitLoadReqs_0_uop_srcLoadDependency_4_2 <= split_new[0].uop.srcLoadDependency_4_2;
      splitLoadReqs_0_uop_psrc_0 <= split_new[0].uop.psrc_0;
      splitLoadReqs_0_uop_psrc_1 <= split_new[0].uop.psrc_1;
      splitLoadReqs_0_uop_psrc_2 <= split_new[0].uop.psrc_2;
      splitLoadReqs_0_uop_psrc_3 <= split_new[0].uop.psrc_3;
      splitLoadReqs_0_uop_psrc_4 <= split_new[0].uop.psrc_4;
      splitLoadReqs_0_uop_pdest <= split_new[0].uop.pdest;
      splitLoadReqs_0_uop_useRegCache_0 <= split_new[0].uop.useRegCache_0;
      splitLoadReqs_0_uop_useRegCache_1 <= split_new[0].uop.useRegCache_1;
      splitLoadReqs_0_uop_regCacheIdx_0 <= split_new[0].uop.regCacheIdx_0;
      splitLoadReqs_0_uop_regCacheIdx_1 <= split_new[0].uop.regCacheIdx_1;
      splitLoadReqs_0_uop_robIdx_flag <= split_new[0].uop.robIdx_flag;
      splitLoadReqs_0_uop_robIdx_value <= split_new[0].uop.robIdx_value;
      splitLoadReqs_0_uop_instrSize <= split_new[0].uop.instrSize;
      splitLoadReqs_0_uop_dirtyFs <= split_new[0].uop.dirtyFs;
      splitLoadReqs_0_uop_dirtyVs <= split_new[0].uop.dirtyVs;
      splitLoadReqs_0_uop_traceBlockInPipe_itype <= split_new[0].uop.traceBlockInPipe_itype;
      splitLoadReqs_0_uop_traceBlockInPipe_iretire <= split_new[0].uop.traceBlockInPipe_iretire;
      splitLoadReqs_0_uop_traceBlockInPipe_ilastsize <= split_new[0].uop.traceBlockInPipe_ilastsize;
      splitLoadReqs_0_uop_eliminatedMove <= split_new[0].uop.eliminatedMove;
      splitLoadReqs_0_uop_snapshot <= split_new[0].uop.snapshot;
      splitLoadReqs_0_uop_debugInfo_eliminatedMove <= split_new[0].uop.debugInfo_eliminatedMove;
      splitLoadReqs_0_uop_debugInfo_renameTime <= split_new[0].uop.debugInfo_renameTime;
      splitLoadReqs_0_uop_debugInfo_dispatchTime <= split_new[0].uop.debugInfo_dispatchTime;
      splitLoadReqs_0_uop_debugInfo_enqRsTime <= split_new[0].uop.debugInfo_enqRsTime;
      splitLoadReqs_0_uop_debugInfo_selectTime <= split_new[0].uop.debugInfo_selectTime;
      splitLoadReqs_0_uop_debugInfo_issueTime <= split_new[0].uop.debugInfo_issueTime;
      splitLoadReqs_0_uop_debugInfo_writebackTime <= split_new[0].uop.debugInfo_writebackTime;
      splitLoadReqs_0_uop_debugInfo_runahead_checkpoint_id <= split_new[0].uop.debugInfo_runahead_checkpoint_id;
      splitLoadReqs_0_uop_debugInfo_tlbFirstReqTime <= split_new[0].uop.debugInfo_tlbFirstReqTime;
      splitLoadReqs_0_uop_debugInfo_tlbRespTime <= split_new[0].uop.debugInfo_tlbRespTime;
      splitLoadReqs_0_uop_debug_seqNum_seqNum <= split_new[0].uop.debug_seqNum_seqNum;
      splitLoadReqs_0_uop_debug_seqNum_uopIdx <= split_new[0].uop.debug_seqNum_uopIdx;
      splitLoadReqs_0_uop_storeSetHit <= split_new[0].uop.storeSetHit;
      splitLoadReqs_0_uop_waitForRobIdx_flag <= split_new[0].uop.waitForRobIdx_flag;
      splitLoadReqs_0_uop_waitForRobIdx_value <= split_new[0].uop.waitForRobIdx_value;
      splitLoadReqs_0_uop_loadWaitBit <= split_new[0].uop.loadWaitBit;
      splitLoadReqs_0_uop_loadWaitStrict <= split_new[0].uop.loadWaitStrict;
      splitLoadReqs_0_uop_ssid <= split_new[0].uop.ssid;
      splitLoadReqs_0_uop_lqIdx_flag <= split_new[0].uop.lqIdx_flag;
      splitLoadReqs_0_uop_lqIdx_value <= split_new[0].uop.lqIdx_value;
      splitLoadReqs_0_uop_sqIdx_flag <= split_new[0].uop.sqIdx_flag;
      splitLoadReqs_0_uop_sqIdx_value <= split_new[0].uop.sqIdx_value;
      splitLoadReqs_0_uop_singleStep <= split_new[0].uop.singleStep;
      splitLoadReqs_0_uop_replayInst <= split_new[0].uop.replayInst;
      splitLoadReqs_0_uop_debug_fuType <= split_new[0].uop.debug_fuType;
      splitLoadReqs_0_uop_debug_sim_trig <= split_new[0].uop.debug_sim_trig;
      splitLoadReqs_0_uop_numLsElem <= split_new[0].uop.numLsElem;
      splitLoadReqs_0_vaddr <= split_new[0].vaddr;
      splitLoadReqs_0_fullva <= split_new[0].fullva;
      splitLoadReqs_0_vaNeedExt <= split_new[0].vaNeedExt;
      splitLoadReqs_0_paddr <= split_new[0].paddr;
      splitLoadReqs_0_gpaddr <= split_new[0].gpaddr;
      splitLoadReqs_0_mask <= split_new[0].mask;
      splitLoadReqs_0_nc <= split_new[0].nc;
      splitLoadReqs_0_mmio <= split_new[0].mmio;
      splitLoadReqs_0_memBackTypeMM <= split_new[0].memBackTypeMM;
      splitLoadReqs_0_isForVSnonLeafPTE <= split_new[0].isForVSnonLeafPTE;
      splitLoadReqs_0_is128bit <= split_new[0].is128bit;
      splitLoadReqs_0_vecActive <= split_new[0].vecActive;
      splitLoadReqs_0_mshrid <= split_new[0].mshrid;
      splitLoadReqs_0_schedIndex <= split_new[0].schedIndex;
    end
  end
  always_comb begin
    split_reqs[0] = '0;   // golden 没留的字段恒 0
    split_reqs[0].uop.instr = splitLoadReqs_0_uop_instr;
    split_reqs[0].uop.pc = splitLoadReqs_0_uop_pc;
    split_reqs[0].uop.foldpc = splitLoadReqs_0_uop_foldpc;
    split_reqs[0].uop.exceptionVec[0] = splitLoadReqs_0_uop_exceptionVec_0;
    split_reqs[0].uop.exceptionVec[1] = splitLoadReqs_0_uop_exceptionVec_1;
    split_reqs[0].uop.exceptionVec[2] = splitLoadReqs_0_uop_exceptionVec_2;
    split_reqs[0].uop.exceptionVec[3] = splitLoadReqs_0_uop_exceptionVec_3;
    split_reqs[0].uop.exceptionVec[4] = splitLoadReqs_0_uop_exceptionVec_4;
    split_reqs[0].uop.exceptionVec[5] = splitLoadReqs_0_uop_exceptionVec_5;
    split_reqs[0].uop.exceptionVec[6] = splitLoadReqs_0_uop_exceptionVec_6;
    split_reqs[0].uop.exceptionVec[7] = splitLoadReqs_0_uop_exceptionVec_7;
    split_reqs[0].uop.exceptionVec[8] = splitLoadReqs_0_uop_exceptionVec_8;
    split_reqs[0].uop.exceptionVec[9] = splitLoadReqs_0_uop_exceptionVec_9;
    split_reqs[0].uop.exceptionVec[10] = splitLoadReqs_0_uop_exceptionVec_10;
    split_reqs[0].uop.exceptionVec[11] = splitLoadReqs_0_uop_exceptionVec_11;
    split_reqs[0].uop.exceptionVec[12] = splitLoadReqs_0_uop_exceptionVec_12;
    split_reqs[0].uop.exceptionVec[13] = splitLoadReqs_0_uop_exceptionVec_13;
    split_reqs[0].uop.exceptionVec[14] = splitLoadReqs_0_uop_exceptionVec_14;
    split_reqs[0].uop.exceptionVec[15] = splitLoadReqs_0_uop_exceptionVec_15;
    split_reqs[0].uop.exceptionVec[16] = splitLoadReqs_0_uop_exceptionVec_16;
    split_reqs[0].uop.exceptionVec[17] = splitLoadReqs_0_uop_exceptionVec_17;
    split_reqs[0].uop.exceptionVec[18] = splitLoadReqs_0_uop_exceptionVec_18;
    split_reqs[0].uop.exceptionVec[19] = splitLoadReqs_0_uop_exceptionVec_19;
    split_reqs[0].uop.exceptionVec[20] = splitLoadReqs_0_uop_exceptionVec_20;
    split_reqs[0].uop.exceptionVec[21] = splitLoadReqs_0_uop_exceptionVec_21;
    split_reqs[0].uop.exceptionVec[22] = splitLoadReqs_0_uop_exceptionVec_22;
    split_reqs[0].uop.exceptionVec[23] = splitLoadReqs_0_uop_exceptionVec_23;
    split_reqs[0].uop.isFetchMalAddr = splitLoadReqs_0_uop_isFetchMalAddr;
    split_reqs[0].uop.hasException = splitLoadReqs_0_uop_hasException;
    split_reqs[0].uop.trigger = splitLoadReqs_0_uop_trigger;
    split_reqs[0].uop.preDecodeInfo_valid = splitLoadReqs_0_uop_preDecodeInfo_valid;
    split_reqs[0].uop.preDecodeInfo_isRVC = splitLoadReqs_0_uop_preDecodeInfo_isRVC;
    split_reqs[0].uop.preDecodeInfo_brType = splitLoadReqs_0_uop_preDecodeInfo_brType;
    split_reqs[0].uop.preDecodeInfo_isCall = splitLoadReqs_0_uop_preDecodeInfo_isCall;
    split_reqs[0].uop.preDecodeInfo_isRet = splitLoadReqs_0_uop_preDecodeInfo_isRet;
    split_reqs[0].uop.pred_taken = splitLoadReqs_0_uop_pred_taken;
    split_reqs[0].uop.crossPageIPFFix = splitLoadReqs_0_uop_crossPageIPFFix;
    split_reqs[0].uop.ftqPtr_flag = splitLoadReqs_0_uop_ftqPtr_flag;
    split_reqs[0].uop.ftqPtr_value = splitLoadReqs_0_uop_ftqPtr_value;
    split_reqs[0].uop.ftqOffset = splitLoadReqs_0_uop_ftqOffset;
    split_reqs[0].uop.satpFlushFirstFetchFault = splitLoadReqs_0_uop_satpFlushFirstFetchFault;
    split_reqs[0].uop.srcType_0 = splitLoadReqs_0_uop_srcType_0;
    split_reqs[0].uop.srcType_1 = splitLoadReqs_0_uop_srcType_1;
    split_reqs[0].uop.srcType_2 = splitLoadReqs_0_uop_srcType_2;
    split_reqs[0].uop.srcType_3 = splitLoadReqs_0_uop_srcType_3;
    split_reqs[0].uop.srcType_4 = splitLoadReqs_0_uop_srcType_4;
    split_reqs[0].uop.ldest = splitLoadReqs_0_uop_ldest;
    split_reqs[0].uop.fuType = splitLoadReqs_0_uop_fuType;
    split_reqs[0].uop.fuOpType = splitLoadReqs_0_uop_fuOpType;
    split_reqs[0].uop.rfWen = splitLoadReqs_0_uop_rfWen;
    split_reqs[0].uop.fpWen = splitLoadReqs_0_uop_fpWen;
    split_reqs[0].uop.vecWen = splitLoadReqs_0_uop_vecWen;
    split_reqs[0].uop.v0Wen = splitLoadReqs_0_uop_v0Wen;
    split_reqs[0].uop.vlWen = splitLoadReqs_0_uop_vlWen;
    split_reqs[0].uop.isXSTrap = splitLoadReqs_0_uop_isXSTrap;
    split_reqs[0].uop.waitForward = splitLoadReqs_0_uop_waitForward;
    split_reqs[0].uop.blockBackward = splitLoadReqs_0_uop_blockBackward;
    split_reqs[0].uop.flushPipe = splitLoadReqs_0_uop_flushPipe;
    split_reqs[0].uop.canRobCompress = splitLoadReqs_0_uop_canRobCompress;
    split_reqs[0].uop.selImm = splitLoadReqs_0_uop_selImm;
    split_reqs[0].uop.imm = splitLoadReqs_0_uop_imm;
    split_reqs[0].uop.fpu_typeTagOut = splitLoadReqs_0_uop_fpu_typeTagOut;
    split_reqs[0].uop.fpu_wflags = splitLoadReqs_0_uop_fpu_wflags;
    split_reqs[0].uop.fpu_typ = splitLoadReqs_0_uop_fpu_typ;
    split_reqs[0].uop.fpu_fmt = splitLoadReqs_0_uop_fpu_fmt;
    split_reqs[0].uop.fpu_rm = splitLoadReqs_0_uop_fpu_rm;
    split_reqs[0].uop.vpu_vill = splitLoadReqs_0_uop_vpu_vill;
    split_reqs[0].uop.vpu_vma = splitLoadReqs_0_uop_vpu_vma;
    split_reqs[0].uop.vpu_vta = splitLoadReqs_0_uop_vpu_vta;
    split_reqs[0].uop.vpu_vsew = splitLoadReqs_0_uop_vpu_vsew;
    split_reqs[0].uop.vpu_vlmul = splitLoadReqs_0_uop_vpu_vlmul;
    split_reqs[0].uop.vpu_specVill = splitLoadReqs_0_uop_vpu_specVill;
    split_reqs[0].uop.vpu_specVma = splitLoadReqs_0_uop_vpu_specVma;
    split_reqs[0].uop.vpu_specVta = splitLoadReqs_0_uop_vpu_specVta;
    split_reqs[0].uop.vpu_specVsew = splitLoadReqs_0_uop_vpu_specVsew;
    split_reqs[0].uop.vpu_specVlmul = splitLoadReqs_0_uop_vpu_specVlmul;
    split_reqs[0].uop.vpu_vm = splitLoadReqs_0_uop_vpu_vm;
    split_reqs[0].uop.vpu_vstart = splitLoadReqs_0_uop_vpu_vstart;
    split_reqs[0].uop.vpu_frm = splitLoadReqs_0_uop_vpu_frm;
    split_reqs[0].uop.vpu_fpu_isFpToVecInst = splitLoadReqs_0_uop_vpu_fpu_isFpToVecInst;
    split_reqs[0].uop.vpu_fpu_isFP32Instr = splitLoadReqs_0_uop_vpu_fpu_isFP32Instr;
    split_reqs[0].uop.vpu_fpu_isFP64Instr = splitLoadReqs_0_uop_vpu_fpu_isFP64Instr;
    split_reqs[0].uop.vpu_fpu_isReduction = splitLoadReqs_0_uop_vpu_fpu_isReduction;
    split_reqs[0].uop.vpu_fpu_isFoldTo1_2 = splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_2;
    split_reqs[0].uop.vpu_fpu_isFoldTo1_4 = splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_4;
    split_reqs[0].uop.vpu_fpu_isFoldTo1_8 = splitLoadReqs_0_uop_vpu_fpu_isFoldTo1_8;
    split_reqs[0].uop.vpu_vxrm = splitLoadReqs_0_uop_vpu_vxrm;
    split_reqs[0].uop.vpu_vuopIdx = splitLoadReqs_0_uop_vpu_vuopIdx;
    split_reqs[0].uop.vpu_lastUop = splitLoadReqs_0_uop_vpu_lastUop;
    split_reqs[0].uop.vpu_vmask = splitLoadReqs_0_uop_vpu_vmask;
    split_reqs[0].uop.vpu_vl = splitLoadReqs_0_uop_vpu_vl;
    split_reqs[0].uop.vpu_nf = splitLoadReqs_0_uop_vpu_nf;
    split_reqs[0].uop.vpu_veew = splitLoadReqs_0_uop_vpu_veew;
    split_reqs[0].uop.vpu_isReverse = splitLoadReqs_0_uop_vpu_isReverse;
    split_reqs[0].uop.vpu_isExt = splitLoadReqs_0_uop_vpu_isExt;
    split_reqs[0].uop.vpu_isNarrow = splitLoadReqs_0_uop_vpu_isNarrow;
    split_reqs[0].uop.vpu_isDstMask = splitLoadReqs_0_uop_vpu_isDstMask;
    split_reqs[0].uop.vpu_isOpMask = splitLoadReqs_0_uop_vpu_isOpMask;
    split_reqs[0].uop.vpu_isMove = splitLoadReqs_0_uop_vpu_isMove;
    split_reqs[0].uop.vpu_isDependOldVd = splitLoadReqs_0_uop_vpu_isDependOldVd;
    split_reqs[0].uop.vpu_isWritePartVd = splitLoadReqs_0_uop_vpu_isWritePartVd;
    split_reqs[0].uop.vpu_isVleff = splitLoadReqs_0_uop_vpu_isVleff;
    split_reqs[0].uop.vlsInstr = splitLoadReqs_0_uop_vlsInstr;
    split_reqs[0].uop.wfflags = splitLoadReqs_0_uop_wfflags;
    split_reqs[0].uop.isMove = splitLoadReqs_0_uop_isMove;
    split_reqs[0].uop.isDropAmocasSta = splitLoadReqs_0_uop_isDropAmocasSta;
    split_reqs[0].uop.uopIdx = splitLoadReqs_0_uop_uopIdx;
    split_reqs[0].uop.isVset = splitLoadReqs_0_uop_isVset;
    split_reqs[0].uop.firstUop = splitLoadReqs_0_uop_firstUop;
    split_reqs[0].uop.lastUop = splitLoadReqs_0_uop_lastUop;
    split_reqs[0].uop.numUops = splitLoadReqs_0_uop_numUops;
    split_reqs[0].uop.numWB = splitLoadReqs_0_uop_numWB;
    split_reqs[0].uop.commitType = splitLoadReqs_0_uop_commitType;
    split_reqs[0].uop.srcState_0 = splitLoadReqs_0_uop_srcState_0;
    split_reqs[0].uop.srcState_1 = splitLoadReqs_0_uop_srcState_1;
    split_reqs[0].uop.srcState_2 = splitLoadReqs_0_uop_srcState_2;
    split_reqs[0].uop.srcState_3 = splitLoadReqs_0_uop_srcState_3;
    split_reqs[0].uop.srcState_4 = splitLoadReqs_0_uop_srcState_4;
    split_reqs[0].uop.srcLoadDependency_0_0 = splitLoadReqs_0_uop_srcLoadDependency_0_0;
    split_reqs[0].uop.srcLoadDependency_0_1 = splitLoadReqs_0_uop_srcLoadDependency_0_1;
    split_reqs[0].uop.srcLoadDependency_0_2 = splitLoadReqs_0_uop_srcLoadDependency_0_2;
    split_reqs[0].uop.srcLoadDependency_1_0 = splitLoadReqs_0_uop_srcLoadDependency_1_0;
    split_reqs[0].uop.srcLoadDependency_1_1 = splitLoadReqs_0_uop_srcLoadDependency_1_1;
    split_reqs[0].uop.srcLoadDependency_1_2 = splitLoadReqs_0_uop_srcLoadDependency_1_2;
    split_reqs[0].uop.srcLoadDependency_2_0 = splitLoadReqs_0_uop_srcLoadDependency_2_0;
    split_reqs[0].uop.srcLoadDependency_2_1 = splitLoadReqs_0_uop_srcLoadDependency_2_1;
    split_reqs[0].uop.srcLoadDependency_2_2 = splitLoadReqs_0_uop_srcLoadDependency_2_2;
    split_reqs[0].uop.srcLoadDependency_3_0 = splitLoadReqs_0_uop_srcLoadDependency_3_0;
    split_reqs[0].uop.srcLoadDependency_3_1 = splitLoadReqs_0_uop_srcLoadDependency_3_1;
    split_reqs[0].uop.srcLoadDependency_3_2 = splitLoadReqs_0_uop_srcLoadDependency_3_2;
    split_reqs[0].uop.srcLoadDependency_4_0 = splitLoadReqs_0_uop_srcLoadDependency_4_0;
    split_reqs[0].uop.srcLoadDependency_4_1 = splitLoadReqs_0_uop_srcLoadDependency_4_1;
    split_reqs[0].uop.srcLoadDependency_4_2 = splitLoadReqs_0_uop_srcLoadDependency_4_2;
    split_reqs[0].uop.psrc_0 = splitLoadReqs_0_uop_psrc_0;
    split_reqs[0].uop.psrc_1 = splitLoadReqs_0_uop_psrc_1;
    split_reqs[0].uop.psrc_2 = splitLoadReqs_0_uop_psrc_2;
    split_reqs[0].uop.psrc_3 = splitLoadReqs_0_uop_psrc_3;
    split_reqs[0].uop.psrc_4 = splitLoadReqs_0_uop_psrc_4;
    split_reqs[0].uop.pdest = splitLoadReqs_0_uop_pdest;
    split_reqs[0].uop.useRegCache_0 = splitLoadReqs_0_uop_useRegCache_0;
    split_reqs[0].uop.useRegCache_1 = splitLoadReqs_0_uop_useRegCache_1;
    split_reqs[0].uop.regCacheIdx_0 = splitLoadReqs_0_uop_regCacheIdx_0;
    split_reqs[0].uop.regCacheIdx_1 = splitLoadReqs_0_uop_regCacheIdx_1;
    split_reqs[0].uop.robIdx_flag = splitLoadReqs_0_uop_robIdx_flag;
    split_reqs[0].uop.robIdx_value = splitLoadReqs_0_uop_robIdx_value;
    split_reqs[0].uop.instrSize = splitLoadReqs_0_uop_instrSize;
    split_reqs[0].uop.dirtyFs = splitLoadReqs_0_uop_dirtyFs;
    split_reqs[0].uop.dirtyVs = splitLoadReqs_0_uop_dirtyVs;
    split_reqs[0].uop.traceBlockInPipe_itype = splitLoadReqs_0_uop_traceBlockInPipe_itype;
    split_reqs[0].uop.traceBlockInPipe_iretire = splitLoadReqs_0_uop_traceBlockInPipe_iretire;
    split_reqs[0].uop.traceBlockInPipe_ilastsize = splitLoadReqs_0_uop_traceBlockInPipe_ilastsize;
    split_reqs[0].uop.eliminatedMove = splitLoadReqs_0_uop_eliminatedMove;
    split_reqs[0].uop.snapshot = splitLoadReqs_0_uop_snapshot;
    split_reqs[0].uop.debugInfo_eliminatedMove = splitLoadReqs_0_uop_debugInfo_eliminatedMove;
    split_reqs[0].uop.debugInfo_renameTime = splitLoadReqs_0_uop_debugInfo_renameTime;
    split_reqs[0].uop.debugInfo_dispatchTime = splitLoadReqs_0_uop_debugInfo_dispatchTime;
    split_reqs[0].uop.debugInfo_enqRsTime = splitLoadReqs_0_uop_debugInfo_enqRsTime;
    split_reqs[0].uop.debugInfo_selectTime = splitLoadReqs_0_uop_debugInfo_selectTime;
    split_reqs[0].uop.debugInfo_issueTime = splitLoadReqs_0_uop_debugInfo_issueTime;
    split_reqs[0].uop.debugInfo_writebackTime = splitLoadReqs_0_uop_debugInfo_writebackTime;
    split_reqs[0].uop.debugInfo_runahead_checkpoint_id = splitLoadReqs_0_uop_debugInfo_runahead_checkpoint_id;
    split_reqs[0].uop.debugInfo_tlbFirstReqTime = splitLoadReqs_0_uop_debugInfo_tlbFirstReqTime;
    split_reqs[0].uop.debugInfo_tlbRespTime = splitLoadReqs_0_uop_debugInfo_tlbRespTime;
    split_reqs[0].uop.debug_seqNum_seqNum = splitLoadReqs_0_uop_debug_seqNum_seqNum;
    split_reqs[0].uop.debug_seqNum_uopIdx = splitLoadReqs_0_uop_debug_seqNum_uopIdx;
    split_reqs[0].uop.storeSetHit = splitLoadReqs_0_uop_storeSetHit;
    split_reqs[0].uop.waitForRobIdx_flag = splitLoadReqs_0_uop_waitForRobIdx_flag;
    split_reqs[0].uop.waitForRobIdx_value = splitLoadReqs_0_uop_waitForRobIdx_value;
    split_reqs[0].uop.loadWaitBit = splitLoadReqs_0_uop_loadWaitBit;
    split_reqs[0].uop.loadWaitStrict = splitLoadReqs_0_uop_loadWaitStrict;
    split_reqs[0].uop.ssid = splitLoadReqs_0_uop_ssid;
    split_reqs[0].uop.lqIdx_flag = splitLoadReqs_0_uop_lqIdx_flag;
    split_reqs[0].uop.lqIdx_value = splitLoadReqs_0_uop_lqIdx_value;
    split_reqs[0].uop.sqIdx_flag = splitLoadReqs_0_uop_sqIdx_flag;
    split_reqs[0].uop.sqIdx_value = splitLoadReqs_0_uop_sqIdx_value;
    split_reqs[0].uop.singleStep = splitLoadReqs_0_uop_singleStep;
    split_reqs[0].uop.replayInst = splitLoadReqs_0_uop_replayInst;
    split_reqs[0].uop.debug_fuType = splitLoadReqs_0_uop_debug_fuType;
    split_reqs[0].uop.debug_sim_trig = splitLoadReqs_0_uop_debug_sim_trig;
    split_reqs[0].uop.numLsElem = splitLoadReqs_0_uop_numLsElem;
    split_reqs[0].vaddr = splitLoadReqs_0_vaddr;
    split_reqs[0].fullva = splitLoadReqs_0_fullva;
    split_reqs[0].vaNeedExt = splitLoadReqs_0_vaNeedExt;
    split_reqs[0].paddr = splitLoadReqs_0_paddr;
    split_reqs[0].gpaddr = splitLoadReqs_0_gpaddr;
    split_reqs[0].mask = splitLoadReqs_0_mask;
    split_reqs[0].nc = splitLoadReqs_0_nc;
    split_reqs[0].mmio = splitLoadReqs_0_mmio;
    split_reqs[0].memBackTypeMM = splitLoadReqs_0_memBackTypeMM;
    split_reqs[0].isForVSnonLeafPTE = splitLoadReqs_0_isForVSnonLeafPTE;
    split_reqs[0].is128bit = splitLoadReqs_0_is128bit;
    split_reqs[0].vecActive = splitLoadReqs_0_vecActive;
    split_reqs[0].mshrid = splitLoadReqs_0_mshrid;
    split_reqs[0].schedIndex = splitLoadReqs_0_schedIndex;
  end

  // ---- splitLoadReqs(1)：高地址那一半子访问（同上）：golden 留下的 194 个字段 ----
  logic [31:0]    splitLoadReqs_1_uop_instr;
  logic [49:0]    splitLoadReqs_1_uop_pc;
  logic [9:0]     splitLoadReqs_1_uop_foldpc;
  logic           splitLoadReqs_1_uop_exceptionVec_0;
  logic           splitLoadReqs_1_uop_exceptionVec_1;
  logic           splitLoadReqs_1_uop_exceptionVec_2;
  logic           splitLoadReqs_1_uop_exceptionVec_3;
  logic           splitLoadReqs_1_uop_exceptionVec_4;
  logic           splitLoadReqs_1_uop_exceptionVec_5;
  logic           splitLoadReqs_1_uop_exceptionVec_6;
  logic           splitLoadReqs_1_uop_exceptionVec_7;
  logic           splitLoadReqs_1_uop_exceptionVec_8;
  logic           splitLoadReqs_1_uop_exceptionVec_9;
  logic           splitLoadReqs_1_uop_exceptionVec_10;
  logic           splitLoadReqs_1_uop_exceptionVec_11;
  logic           splitLoadReqs_1_uop_exceptionVec_12;
  logic           splitLoadReqs_1_uop_exceptionVec_13;
  logic           splitLoadReqs_1_uop_exceptionVec_14;
  logic           splitLoadReqs_1_uop_exceptionVec_15;
  logic           splitLoadReqs_1_uop_exceptionVec_16;
  logic           splitLoadReqs_1_uop_exceptionVec_17;
  logic           splitLoadReqs_1_uop_exceptionVec_18;
  logic           splitLoadReqs_1_uop_exceptionVec_19;
  logic           splitLoadReqs_1_uop_exceptionVec_20;
  logic           splitLoadReqs_1_uop_exceptionVec_21;
  logic           splitLoadReqs_1_uop_exceptionVec_22;
  logic           splitLoadReqs_1_uop_exceptionVec_23;
  logic           splitLoadReqs_1_uop_isFetchMalAddr;
  logic           splitLoadReqs_1_uop_hasException;
  logic [3:0]     splitLoadReqs_1_uop_trigger;
  logic           splitLoadReqs_1_uop_preDecodeInfo_valid;
  logic           splitLoadReqs_1_uop_preDecodeInfo_isRVC;
  logic [1:0]     splitLoadReqs_1_uop_preDecodeInfo_brType;
  logic           splitLoadReqs_1_uop_preDecodeInfo_isCall;
  logic           splitLoadReqs_1_uop_preDecodeInfo_isRet;
  logic           splitLoadReqs_1_uop_pred_taken;
  logic           splitLoadReqs_1_uop_crossPageIPFFix;
  logic           splitLoadReqs_1_uop_ftqPtr_flag;
  logic [5:0]     splitLoadReqs_1_uop_ftqPtr_value;
  logic [3:0]     splitLoadReqs_1_uop_ftqOffset;
  logic           splitLoadReqs_1_uop_satpFlushFirstFetchFault;
  logic [3:0]     splitLoadReqs_1_uop_srcType_0;
  logic [3:0]     splitLoadReqs_1_uop_srcType_1;
  logic [3:0]     splitLoadReqs_1_uop_srcType_2;
  logic [3:0]     splitLoadReqs_1_uop_srcType_3;
  logic [3:0]     splitLoadReqs_1_uop_srcType_4;
  logic [5:0]     splitLoadReqs_1_uop_ldest;
  logic [34:0]    splitLoadReqs_1_uop_fuType;
  logic [8:0]     splitLoadReqs_1_uop_fuOpType;
  logic           splitLoadReqs_1_uop_rfWen;
  logic           splitLoadReqs_1_uop_fpWen;
  logic           splitLoadReqs_1_uop_vecWen;
  logic           splitLoadReqs_1_uop_v0Wen;
  logic           splitLoadReqs_1_uop_vlWen;
  logic           splitLoadReqs_1_uop_isXSTrap;
  logic           splitLoadReqs_1_uop_waitForward;
  logic           splitLoadReqs_1_uop_blockBackward;
  logic           splitLoadReqs_1_uop_flushPipe;
  logic           splitLoadReqs_1_uop_canRobCompress;
  logic [3:0]     splitLoadReqs_1_uop_selImm;
  logic [31:0]    splitLoadReqs_1_uop_imm;
  logic [1:0]     splitLoadReqs_1_uop_fpu_typeTagOut;
  logic           splitLoadReqs_1_uop_fpu_wflags;
  logic [1:0]     splitLoadReqs_1_uop_fpu_typ;
  logic [1:0]     splitLoadReqs_1_uop_fpu_fmt;
  logic [2:0]     splitLoadReqs_1_uop_fpu_rm;
  logic           splitLoadReqs_1_uop_vpu_vill;
  logic           splitLoadReqs_1_uop_vpu_vma;
  logic           splitLoadReqs_1_uop_vpu_vta;
  logic [1:0]     splitLoadReqs_1_uop_vpu_vsew;
  logic [2:0]     splitLoadReqs_1_uop_vpu_vlmul;
  logic           splitLoadReqs_1_uop_vpu_specVill;
  logic           splitLoadReqs_1_uop_vpu_specVma;
  logic           splitLoadReqs_1_uop_vpu_specVta;
  logic [1:0]     splitLoadReqs_1_uop_vpu_specVsew;
  logic [2:0]     splitLoadReqs_1_uop_vpu_specVlmul;
  logic           splitLoadReqs_1_uop_vpu_vm;
  logic [7:0]     splitLoadReqs_1_uop_vpu_vstart;
  logic [2:0]     splitLoadReqs_1_uop_vpu_frm;
  logic           splitLoadReqs_1_uop_vpu_fpu_isFpToVecInst;
  logic           splitLoadReqs_1_uop_vpu_fpu_isFP32Instr;
  logic           splitLoadReqs_1_uop_vpu_fpu_isFP64Instr;
  logic           splitLoadReqs_1_uop_vpu_fpu_isReduction;
  logic           splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_2;
  logic           splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_4;
  logic           splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]     splitLoadReqs_1_uop_vpu_vxrm;
  logic [6:0]     splitLoadReqs_1_uop_vpu_vuopIdx;
  logic           splitLoadReqs_1_uop_vpu_lastUop;
  logic [127:0]   splitLoadReqs_1_uop_vpu_vmask;
  logic [7:0]     splitLoadReqs_1_uop_vpu_vl;
  logic [2:0]     splitLoadReqs_1_uop_vpu_nf;
  logic [1:0]     splitLoadReqs_1_uop_vpu_veew;
  logic           splitLoadReqs_1_uop_vpu_isReverse;
  logic           splitLoadReqs_1_uop_vpu_isExt;
  logic           splitLoadReqs_1_uop_vpu_isNarrow;
  logic           splitLoadReqs_1_uop_vpu_isDstMask;
  logic           splitLoadReqs_1_uop_vpu_isOpMask;
  logic           splitLoadReqs_1_uop_vpu_isMove;
  logic           splitLoadReqs_1_uop_vpu_isDependOldVd;
  logic           splitLoadReqs_1_uop_vpu_isWritePartVd;
  logic           splitLoadReqs_1_uop_vpu_isVleff;
  logic           splitLoadReqs_1_uop_vlsInstr;
  logic           splitLoadReqs_1_uop_wfflags;
  logic           splitLoadReqs_1_uop_isMove;
  logic           splitLoadReqs_1_uop_isDropAmocasSta;
  logic [6:0]     splitLoadReqs_1_uop_uopIdx;
  logic           splitLoadReqs_1_uop_isVset;
  logic           splitLoadReqs_1_uop_firstUop;
  logic           splitLoadReqs_1_uop_lastUop;
  logic [6:0]     splitLoadReqs_1_uop_numUops;
  logic [6:0]     splitLoadReqs_1_uop_numWB;
  logic [2:0]     splitLoadReqs_1_uop_commitType;
  logic           splitLoadReqs_1_uop_srcState_0;
  logic           splitLoadReqs_1_uop_srcState_1;
  logic           splitLoadReqs_1_uop_srcState_2;
  logic           splitLoadReqs_1_uop_srcState_3;
  logic           splitLoadReqs_1_uop_srcState_4;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_0_0;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_0_1;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_0_2;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_1_0;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_1_1;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_1_2;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_2_0;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_2_1;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_2_2;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_3_0;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_3_1;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_3_2;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_4_0;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_4_1;
  logic [1:0]     splitLoadReqs_1_uop_srcLoadDependency_4_2;
  logic [7:0]     splitLoadReqs_1_uop_psrc_0;
  logic [7:0]     splitLoadReqs_1_uop_psrc_1;
  logic [7:0]     splitLoadReqs_1_uop_psrc_2;
  logic [7:0]     splitLoadReqs_1_uop_psrc_3;
  logic [7:0]     splitLoadReqs_1_uop_psrc_4;
  logic [7:0]     splitLoadReqs_1_uop_pdest;
  logic           splitLoadReqs_1_uop_useRegCache_0;
  logic           splitLoadReqs_1_uop_useRegCache_1;
  logic [4:0]     splitLoadReqs_1_uop_regCacheIdx_0;
  logic [4:0]     splitLoadReqs_1_uop_regCacheIdx_1;
  logic           splitLoadReqs_1_uop_robIdx_flag;
  logic [7:0]     splitLoadReqs_1_uop_robIdx_value;
  logic [2:0]     splitLoadReqs_1_uop_instrSize;
  logic           splitLoadReqs_1_uop_dirtyFs;
  logic           splitLoadReqs_1_uop_dirtyVs;
  logic [3:0]     splitLoadReqs_1_uop_traceBlockInPipe_itype;
  logic [3:0]     splitLoadReqs_1_uop_traceBlockInPipe_iretire;
  logic           splitLoadReqs_1_uop_traceBlockInPipe_ilastsize;
  logic           splitLoadReqs_1_uop_eliminatedMove;
  logic           splitLoadReqs_1_uop_snapshot;
  logic           splitLoadReqs_1_uop_debugInfo_eliminatedMove;
  logic [63:0]    splitLoadReqs_1_uop_debugInfo_renameTime;
  logic [63:0]    splitLoadReqs_1_uop_debugInfo_dispatchTime;
  logic [63:0]    splitLoadReqs_1_uop_debugInfo_enqRsTime;
  logic [63:0]    splitLoadReqs_1_uop_debugInfo_selectTime;
  logic [63:0]    splitLoadReqs_1_uop_debugInfo_issueTime;
  logic [63:0]    splitLoadReqs_1_uop_debugInfo_writebackTime;
  logic [63:0]    splitLoadReqs_1_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]    splitLoadReqs_1_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]    splitLoadReqs_1_uop_debugInfo_tlbRespTime;
  logic [55:0]    splitLoadReqs_1_uop_debug_seqNum_seqNum;
  logic [7:0]     splitLoadReqs_1_uop_debug_seqNum_uopIdx;
  logic           splitLoadReqs_1_uop_storeSetHit;
  logic           splitLoadReqs_1_uop_waitForRobIdx_flag;
  logic [7:0]     splitLoadReqs_1_uop_waitForRobIdx_value;
  logic           splitLoadReqs_1_uop_loadWaitBit;
  logic           splitLoadReqs_1_uop_loadWaitStrict;
  logic [4:0]     splitLoadReqs_1_uop_ssid;
  logic           splitLoadReqs_1_uop_lqIdx_flag;
  logic [6:0]     splitLoadReqs_1_uop_lqIdx_value;
  logic           splitLoadReqs_1_uop_sqIdx_flag;
  logic [5:0]     splitLoadReqs_1_uop_sqIdx_value;
  logic           splitLoadReqs_1_uop_singleStep;
  logic           splitLoadReqs_1_uop_replayInst;
  logic [34:0]    splitLoadReqs_1_uop_debug_fuType;
  logic           splitLoadReqs_1_uop_debug_sim_trig;
  logic [4:0]     splitLoadReqs_1_uop_numLsElem;
  logic [49:0]    splitLoadReqs_1_vaddr;
  logic [63:0]    splitLoadReqs_1_fullva;
  logic           splitLoadReqs_1_vaNeedExt;
  logic [47:0]    splitLoadReqs_1_paddr;
  logic [63:0]    splitLoadReqs_1_gpaddr;
  logic [15:0]    splitLoadReqs_1_mask;
  logic           splitLoadReqs_1_nc;
  logic           splitLoadReqs_1_mmio;
  logic           splitLoadReqs_1_memBackTypeMM;
  logic           splitLoadReqs_1_isForVSnonLeafPTE;
  logic           splitLoadReqs_1_is128bit;
  logic           splitLoadReqs_1_vecActive;
  logic [3:0]     splitLoadReqs_1_mshrid;
  logic [6:0]     splitLoadReqs_1_schedIndex;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      splitLoadReqs_1_uop_instr <= '0;
      splitLoadReqs_1_uop_pc <= '0;
      splitLoadReqs_1_uop_foldpc <= '0;
      splitLoadReqs_1_uop_exceptionVec_0 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_1 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_2 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_3 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_4 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_5 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_6 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_7 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_8 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_9 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_10 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_11 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_12 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_13 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_14 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_15 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_16 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_17 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_18 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_19 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_20 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_21 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_22 <= 1'b0;
      splitLoadReqs_1_uop_exceptionVec_23 <= 1'b0;
      splitLoadReqs_1_uop_isFetchMalAddr <= 1'b0;
      splitLoadReqs_1_uop_hasException <= 1'b0;
      splitLoadReqs_1_uop_trigger <= '0;
      splitLoadReqs_1_uop_preDecodeInfo_valid <= 1'b0;
      splitLoadReqs_1_uop_preDecodeInfo_isRVC <= 1'b0;
      splitLoadReqs_1_uop_preDecodeInfo_brType <= '0;
      splitLoadReqs_1_uop_preDecodeInfo_isCall <= 1'b0;
      splitLoadReqs_1_uop_preDecodeInfo_isRet <= 1'b0;
      splitLoadReqs_1_uop_pred_taken <= 1'b0;
      splitLoadReqs_1_uop_crossPageIPFFix <= 1'b0;
      splitLoadReqs_1_uop_ftqPtr_flag <= 1'b0;
      splitLoadReqs_1_uop_ftqPtr_value <= '0;
      splitLoadReqs_1_uop_ftqOffset <= '0;
      splitLoadReqs_1_uop_satpFlushFirstFetchFault <= 1'b0;
      splitLoadReqs_1_uop_srcType_0 <= '0;
      splitLoadReqs_1_uop_srcType_1 <= '0;
      splitLoadReqs_1_uop_srcType_2 <= '0;
      splitLoadReqs_1_uop_srcType_3 <= '0;
      splitLoadReqs_1_uop_srcType_4 <= '0;
      splitLoadReqs_1_uop_ldest <= '0;
      splitLoadReqs_1_uop_fuType <= '0;
      splitLoadReqs_1_uop_fuOpType <= '0;
      splitLoadReqs_1_uop_rfWen <= 1'b0;
      splitLoadReqs_1_uop_fpWen <= 1'b0;
      splitLoadReqs_1_uop_vecWen <= 1'b0;
      splitLoadReqs_1_uop_v0Wen <= 1'b0;
      splitLoadReqs_1_uop_vlWen <= 1'b0;
      splitLoadReqs_1_uop_isXSTrap <= 1'b0;
      splitLoadReqs_1_uop_waitForward <= 1'b0;
      splitLoadReqs_1_uop_blockBackward <= 1'b0;
      splitLoadReqs_1_uop_flushPipe <= 1'b0;
      splitLoadReqs_1_uop_canRobCompress <= 1'b0;
      splitLoadReqs_1_uop_selImm <= '0;
      splitLoadReqs_1_uop_imm <= '0;
      splitLoadReqs_1_uop_fpu_typeTagOut <= '0;
      splitLoadReqs_1_uop_fpu_wflags <= 1'b0;
      splitLoadReqs_1_uop_fpu_typ <= '0;
      splitLoadReqs_1_uop_fpu_fmt <= '0;
      splitLoadReqs_1_uop_fpu_rm <= '0;
      splitLoadReqs_1_uop_vpu_vill <= 1'b0;
      splitLoadReqs_1_uop_vpu_vma <= 1'b0;
      splitLoadReqs_1_uop_vpu_vta <= 1'b0;
      splitLoadReqs_1_uop_vpu_vsew <= '0;
      splitLoadReqs_1_uop_vpu_vlmul <= '0;
      splitLoadReqs_1_uop_vpu_specVill <= 1'b0;
      splitLoadReqs_1_uop_vpu_specVma <= 1'b0;
      splitLoadReqs_1_uop_vpu_specVta <= 1'b0;
      splitLoadReqs_1_uop_vpu_specVsew <= '0;
      splitLoadReqs_1_uop_vpu_specVlmul <= '0;
      splitLoadReqs_1_uop_vpu_vm <= 1'b0;
      splitLoadReqs_1_uop_vpu_vstart <= '0;
      splitLoadReqs_1_uop_vpu_frm <= '0;
      splitLoadReqs_1_uop_vpu_fpu_isFpToVecInst <= 1'b0;
      splitLoadReqs_1_uop_vpu_fpu_isFP32Instr <= 1'b0;
      splitLoadReqs_1_uop_vpu_fpu_isFP64Instr <= 1'b0;
      splitLoadReqs_1_uop_vpu_fpu_isReduction <= 1'b0;
      splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_2 <= 1'b0;
      splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_4 <= 1'b0;
      splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_8 <= 1'b0;
      splitLoadReqs_1_uop_vpu_vxrm <= '0;
      splitLoadReqs_1_uop_vpu_vuopIdx <= '0;
      splitLoadReqs_1_uop_vpu_lastUop <= 1'b0;
      splitLoadReqs_1_uop_vpu_vmask <= '0;
      splitLoadReqs_1_uop_vpu_vl <= '0;
      splitLoadReqs_1_uop_vpu_nf <= '0;
      splitLoadReqs_1_uop_vpu_veew <= '0;
      splitLoadReqs_1_uop_vpu_isReverse <= 1'b0;
      splitLoadReqs_1_uop_vpu_isExt <= 1'b0;
      splitLoadReqs_1_uop_vpu_isNarrow <= 1'b0;
      splitLoadReqs_1_uop_vpu_isDstMask <= 1'b0;
      splitLoadReqs_1_uop_vpu_isOpMask <= 1'b0;
      splitLoadReqs_1_uop_vpu_isMove <= 1'b0;
      splitLoadReqs_1_uop_vpu_isDependOldVd <= 1'b0;
      splitLoadReqs_1_uop_vpu_isWritePartVd <= 1'b0;
      splitLoadReqs_1_uop_vpu_isVleff <= 1'b0;
      splitLoadReqs_1_uop_vlsInstr <= 1'b0;
      splitLoadReqs_1_uop_wfflags <= 1'b0;
      splitLoadReqs_1_uop_isMove <= 1'b0;
      splitLoadReqs_1_uop_isDropAmocasSta <= 1'b0;
      splitLoadReqs_1_uop_uopIdx <= '0;
      splitLoadReqs_1_uop_isVset <= 1'b0;
      splitLoadReqs_1_uop_firstUop <= 1'b0;
      splitLoadReqs_1_uop_lastUop <= 1'b0;
      splitLoadReqs_1_uop_numUops <= '0;
      splitLoadReqs_1_uop_numWB <= '0;
      splitLoadReqs_1_uop_commitType <= '0;
      splitLoadReqs_1_uop_srcState_0 <= 1'b0;
      splitLoadReqs_1_uop_srcState_1 <= 1'b0;
      splitLoadReqs_1_uop_srcState_2 <= 1'b0;
      splitLoadReqs_1_uop_srcState_3 <= 1'b0;
      splitLoadReqs_1_uop_srcState_4 <= 1'b0;
      splitLoadReqs_1_uop_srcLoadDependency_0_0 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_0_1 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_0_2 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_1_0 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_1_1 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_1_2 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_2_0 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_2_1 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_2_2 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_3_0 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_3_1 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_3_2 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_4_0 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_4_1 <= '0;
      splitLoadReqs_1_uop_srcLoadDependency_4_2 <= '0;
      splitLoadReqs_1_uop_psrc_0 <= '0;
      splitLoadReqs_1_uop_psrc_1 <= '0;
      splitLoadReqs_1_uop_psrc_2 <= '0;
      splitLoadReqs_1_uop_psrc_3 <= '0;
      splitLoadReqs_1_uop_psrc_4 <= '0;
      splitLoadReqs_1_uop_pdest <= '0;
      splitLoadReqs_1_uop_useRegCache_0 <= 1'b0;
      splitLoadReqs_1_uop_useRegCache_1 <= 1'b0;
      splitLoadReqs_1_uop_regCacheIdx_0 <= '0;
      splitLoadReqs_1_uop_regCacheIdx_1 <= '0;
      splitLoadReqs_1_uop_robIdx_flag <= 1'b0;
      splitLoadReqs_1_uop_robIdx_value <= '0;
      splitLoadReqs_1_uop_instrSize <= '0;
      splitLoadReqs_1_uop_dirtyFs <= 1'b0;
      splitLoadReqs_1_uop_dirtyVs <= 1'b0;
      splitLoadReqs_1_uop_traceBlockInPipe_itype <= '0;
      splitLoadReqs_1_uop_traceBlockInPipe_iretire <= '0;
      splitLoadReqs_1_uop_traceBlockInPipe_ilastsize <= 1'b0;
      splitLoadReqs_1_uop_eliminatedMove <= 1'b0;
      splitLoadReqs_1_uop_snapshot <= 1'b0;
      splitLoadReqs_1_uop_debugInfo_eliminatedMove <= 1'b0;
      splitLoadReqs_1_uop_debugInfo_renameTime <= '0;
      splitLoadReqs_1_uop_debugInfo_dispatchTime <= '0;
      splitLoadReqs_1_uop_debugInfo_enqRsTime <= '0;
      splitLoadReqs_1_uop_debugInfo_selectTime <= '0;
      splitLoadReqs_1_uop_debugInfo_issueTime <= '0;
      splitLoadReqs_1_uop_debugInfo_writebackTime <= '0;
      splitLoadReqs_1_uop_debugInfo_runahead_checkpoint_id <= '0;
      splitLoadReqs_1_uop_debugInfo_tlbFirstReqTime <= '0;
      splitLoadReqs_1_uop_debugInfo_tlbRespTime <= '0;
      splitLoadReqs_1_uop_debug_seqNum_seqNum <= '0;
      splitLoadReqs_1_uop_debug_seqNum_uopIdx <= '0;
      splitLoadReqs_1_uop_storeSetHit <= 1'b0;
      splitLoadReqs_1_uop_waitForRobIdx_flag <= 1'b0;
      splitLoadReqs_1_uop_waitForRobIdx_value <= '0;
      splitLoadReqs_1_uop_loadWaitBit <= 1'b0;
      splitLoadReqs_1_uop_loadWaitStrict <= 1'b0;
      splitLoadReqs_1_uop_ssid <= '0;
      splitLoadReqs_1_uop_lqIdx_flag <= 1'b0;
      splitLoadReqs_1_uop_lqIdx_value <= '0;
      splitLoadReqs_1_uop_sqIdx_flag <= 1'b0;
      splitLoadReqs_1_uop_sqIdx_value <= '0;
      splitLoadReqs_1_uop_singleStep <= 1'b0;
      splitLoadReqs_1_uop_replayInst <= 1'b0;
      splitLoadReqs_1_uop_debug_fuType <= '0;
      splitLoadReqs_1_uop_debug_sim_trig <= 1'b0;
      splitLoadReqs_1_uop_numLsElem <= '0;
      splitLoadReqs_1_vaddr <= '0;
      splitLoadReqs_1_fullva <= '0;
      splitLoadReqs_1_vaNeedExt <= 1'b0;
      splitLoadReqs_1_paddr <= '0;
      splitLoadReqs_1_gpaddr <= '0;
      splitLoadReqs_1_mask <= '0;
      splitLoadReqs_1_nc <= 1'b0;
      splitLoadReqs_1_mmio <= 1'b0;
      splitLoadReqs_1_memBackTypeMM <= 1'b0;
      splitLoadReqs_1_isForVSnonLeafPTE <= 1'b0;
      splitLoadReqs_1_is128bit <= 1'b0;
      splitLoadReqs_1_vecActive <= 1'b0;
      splitLoadReqs_1_mshrid <= '0;
      splitLoadReqs_1_schedIndex <= '0;
    end else if (split_now) begin
      splitLoadReqs_1_uop_instr <= split_new[1].uop.instr;
      splitLoadReqs_1_uop_pc <= split_new[1].uop.pc;
      splitLoadReqs_1_uop_foldpc <= split_new[1].uop.foldpc;
      splitLoadReqs_1_uop_exceptionVec_0 <= split_new[1].uop.exceptionVec[0];
      splitLoadReqs_1_uop_exceptionVec_1 <= split_new[1].uop.exceptionVec[1];
      splitLoadReqs_1_uop_exceptionVec_2 <= split_new[1].uop.exceptionVec[2];
      splitLoadReqs_1_uop_exceptionVec_3 <= split_new[1].uop.exceptionVec[3];
      splitLoadReqs_1_uop_exceptionVec_4 <= split_new[1].uop.exceptionVec[4];
      splitLoadReqs_1_uop_exceptionVec_5 <= split_new[1].uop.exceptionVec[5];
      splitLoadReqs_1_uop_exceptionVec_6 <= split_new[1].uop.exceptionVec[6];
      splitLoadReqs_1_uop_exceptionVec_7 <= split_new[1].uop.exceptionVec[7];
      splitLoadReqs_1_uop_exceptionVec_8 <= split_new[1].uop.exceptionVec[8];
      splitLoadReqs_1_uop_exceptionVec_9 <= split_new[1].uop.exceptionVec[9];
      splitLoadReqs_1_uop_exceptionVec_10 <= split_new[1].uop.exceptionVec[10];
      splitLoadReqs_1_uop_exceptionVec_11 <= split_new[1].uop.exceptionVec[11];
      splitLoadReqs_1_uop_exceptionVec_12 <= split_new[1].uop.exceptionVec[12];
      splitLoadReqs_1_uop_exceptionVec_13 <= split_new[1].uop.exceptionVec[13];
      splitLoadReqs_1_uop_exceptionVec_14 <= split_new[1].uop.exceptionVec[14];
      splitLoadReqs_1_uop_exceptionVec_15 <= split_new[1].uop.exceptionVec[15];
      splitLoadReqs_1_uop_exceptionVec_16 <= split_new[1].uop.exceptionVec[16];
      splitLoadReqs_1_uop_exceptionVec_17 <= split_new[1].uop.exceptionVec[17];
      splitLoadReqs_1_uop_exceptionVec_18 <= split_new[1].uop.exceptionVec[18];
      splitLoadReqs_1_uop_exceptionVec_19 <= split_new[1].uop.exceptionVec[19];
      splitLoadReqs_1_uop_exceptionVec_20 <= split_new[1].uop.exceptionVec[20];
      splitLoadReqs_1_uop_exceptionVec_21 <= split_new[1].uop.exceptionVec[21];
      splitLoadReqs_1_uop_exceptionVec_22 <= split_new[1].uop.exceptionVec[22];
      splitLoadReqs_1_uop_exceptionVec_23 <= split_new[1].uop.exceptionVec[23];
      splitLoadReqs_1_uop_isFetchMalAddr <= split_new[1].uop.isFetchMalAddr;
      splitLoadReqs_1_uop_hasException <= split_new[1].uop.hasException;
      splitLoadReqs_1_uop_trigger <= split_new[1].uop.trigger;
      splitLoadReqs_1_uop_preDecodeInfo_valid <= split_new[1].uop.preDecodeInfo_valid;
      splitLoadReqs_1_uop_preDecodeInfo_isRVC <= split_new[1].uop.preDecodeInfo_isRVC;
      splitLoadReqs_1_uop_preDecodeInfo_brType <= split_new[1].uop.preDecodeInfo_brType;
      splitLoadReqs_1_uop_preDecodeInfo_isCall <= split_new[1].uop.preDecodeInfo_isCall;
      splitLoadReqs_1_uop_preDecodeInfo_isRet <= split_new[1].uop.preDecodeInfo_isRet;
      splitLoadReqs_1_uop_pred_taken <= split_new[1].uop.pred_taken;
      splitLoadReqs_1_uop_crossPageIPFFix <= split_new[1].uop.crossPageIPFFix;
      splitLoadReqs_1_uop_ftqPtr_flag <= split_new[1].uop.ftqPtr_flag;
      splitLoadReqs_1_uop_ftqPtr_value <= split_new[1].uop.ftqPtr_value;
      splitLoadReqs_1_uop_ftqOffset <= split_new[1].uop.ftqOffset;
      splitLoadReqs_1_uop_satpFlushFirstFetchFault <= split_new[1].uop.satpFlushFirstFetchFault;
      splitLoadReqs_1_uop_srcType_0 <= split_new[1].uop.srcType_0;
      splitLoadReqs_1_uop_srcType_1 <= split_new[1].uop.srcType_1;
      splitLoadReqs_1_uop_srcType_2 <= split_new[1].uop.srcType_2;
      splitLoadReqs_1_uop_srcType_3 <= split_new[1].uop.srcType_3;
      splitLoadReqs_1_uop_srcType_4 <= split_new[1].uop.srcType_4;
      splitLoadReqs_1_uop_ldest <= split_new[1].uop.ldest;
      splitLoadReqs_1_uop_fuType <= split_new[1].uop.fuType;
      splitLoadReqs_1_uop_fuOpType <= split_new[1].uop.fuOpType;
      splitLoadReqs_1_uop_rfWen <= split_new[1].uop.rfWen;
      splitLoadReqs_1_uop_fpWen <= split_new[1].uop.fpWen;
      splitLoadReqs_1_uop_vecWen <= split_new[1].uop.vecWen;
      splitLoadReqs_1_uop_v0Wen <= split_new[1].uop.v0Wen;
      splitLoadReqs_1_uop_vlWen <= split_new[1].uop.vlWen;
      splitLoadReqs_1_uop_isXSTrap <= split_new[1].uop.isXSTrap;
      splitLoadReqs_1_uop_waitForward <= split_new[1].uop.waitForward;
      splitLoadReqs_1_uop_blockBackward <= split_new[1].uop.blockBackward;
      splitLoadReqs_1_uop_flushPipe <= split_new[1].uop.flushPipe;
      splitLoadReqs_1_uop_canRobCompress <= split_new[1].uop.canRobCompress;
      splitLoadReqs_1_uop_selImm <= split_new[1].uop.selImm;
      splitLoadReqs_1_uop_imm <= split_new[1].uop.imm;
      splitLoadReqs_1_uop_fpu_typeTagOut <= split_new[1].uop.fpu_typeTagOut;
      splitLoadReqs_1_uop_fpu_wflags <= split_new[1].uop.fpu_wflags;
      splitLoadReqs_1_uop_fpu_typ <= split_new[1].uop.fpu_typ;
      splitLoadReqs_1_uop_fpu_fmt <= split_new[1].uop.fpu_fmt;
      splitLoadReqs_1_uop_fpu_rm <= split_new[1].uop.fpu_rm;
      splitLoadReqs_1_uop_vpu_vill <= split_new[1].uop.vpu_vill;
      splitLoadReqs_1_uop_vpu_vma <= split_new[1].uop.vpu_vma;
      splitLoadReqs_1_uop_vpu_vta <= split_new[1].uop.vpu_vta;
      splitLoadReqs_1_uop_vpu_vsew <= split_new[1].uop.vpu_vsew;
      splitLoadReqs_1_uop_vpu_vlmul <= split_new[1].uop.vpu_vlmul;
      splitLoadReqs_1_uop_vpu_specVill <= split_new[1].uop.vpu_specVill;
      splitLoadReqs_1_uop_vpu_specVma <= split_new[1].uop.vpu_specVma;
      splitLoadReqs_1_uop_vpu_specVta <= split_new[1].uop.vpu_specVta;
      splitLoadReqs_1_uop_vpu_specVsew <= split_new[1].uop.vpu_specVsew;
      splitLoadReqs_1_uop_vpu_specVlmul <= split_new[1].uop.vpu_specVlmul;
      splitLoadReqs_1_uop_vpu_vm <= split_new[1].uop.vpu_vm;
      splitLoadReqs_1_uop_vpu_vstart <= split_new[1].uop.vpu_vstart;
      splitLoadReqs_1_uop_vpu_frm <= split_new[1].uop.vpu_frm;
      splitLoadReqs_1_uop_vpu_fpu_isFpToVecInst <= split_new[1].uop.vpu_fpu_isFpToVecInst;
      splitLoadReqs_1_uop_vpu_fpu_isFP32Instr <= split_new[1].uop.vpu_fpu_isFP32Instr;
      splitLoadReqs_1_uop_vpu_fpu_isFP64Instr <= split_new[1].uop.vpu_fpu_isFP64Instr;
      splitLoadReqs_1_uop_vpu_fpu_isReduction <= split_new[1].uop.vpu_fpu_isReduction;
      splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_2 <= split_new[1].uop.vpu_fpu_isFoldTo1_2;
      splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_4 <= split_new[1].uop.vpu_fpu_isFoldTo1_4;
      splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_8 <= split_new[1].uop.vpu_fpu_isFoldTo1_8;
      splitLoadReqs_1_uop_vpu_vxrm <= split_new[1].uop.vpu_vxrm;
      splitLoadReqs_1_uop_vpu_vuopIdx <= split_new[1].uop.vpu_vuopIdx;
      splitLoadReqs_1_uop_vpu_lastUop <= split_new[1].uop.vpu_lastUop;
      splitLoadReqs_1_uop_vpu_vmask <= split_new[1].uop.vpu_vmask;
      splitLoadReqs_1_uop_vpu_vl <= split_new[1].uop.vpu_vl;
      splitLoadReqs_1_uop_vpu_nf <= split_new[1].uop.vpu_nf;
      splitLoadReqs_1_uop_vpu_veew <= split_new[1].uop.vpu_veew;
      splitLoadReqs_1_uop_vpu_isReverse <= split_new[1].uop.vpu_isReverse;
      splitLoadReqs_1_uop_vpu_isExt <= split_new[1].uop.vpu_isExt;
      splitLoadReqs_1_uop_vpu_isNarrow <= split_new[1].uop.vpu_isNarrow;
      splitLoadReqs_1_uop_vpu_isDstMask <= split_new[1].uop.vpu_isDstMask;
      splitLoadReqs_1_uop_vpu_isOpMask <= split_new[1].uop.vpu_isOpMask;
      splitLoadReqs_1_uop_vpu_isMove <= split_new[1].uop.vpu_isMove;
      splitLoadReqs_1_uop_vpu_isDependOldVd <= split_new[1].uop.vpu_isDependOldVd;
      splitLoadReqs_1_uop_vpu_isWritePartVd <= split_new[1].uop.vpu_isWritePartVd;
      splitLoadReqs_1_uop_vpu_isVleff <= split_new[1].uop.vpu_isVleff;
      splitLoadReqs_1_uop_vlsInstr <= split_new[1].uop.vlsInstr;
      splitLoadReqs_1_uop_wfflags <= split_new[1].uop.wfflags;
      splitLoadReqs_1_uop_isMove <= split_new[1].uop.isMove;
      splitLoadReqs_1_uop_isDropAmocasSta <= split_new[1].uop.isDropAmocasSta;
      splitLoadReqs_1_uop_uopIdx <= split_new[1].uop.uopIdx;
      splitLoadReqs_1_uop_isVset <= split_new[1].uop.isVset;
      splitLoadReqs_1_uop_firstUop <= split_new[1].uop.firstUop;
      splitLoadReqs_1_uop_lastUop <= split_new[1].uop.lastUop;
      splitLoadReqs_1_uop_numUops <= split_new[1].uop.numUops;
      splitLoadReqs_1_uop_numWB <= split_new[1].uop.numWB;
      splitLoadReqs_1_uop_commitType <= split_new[1].uop.commitType;
      splitLoadReqs_1_uop_srcState_0 <= split_new[1].uop.srcState_0;
      splitLoadReqs_1_uop_srcState_1 <= split_new[1].uop.srcState_1;
      splitLoadReqs_1_uop_srcState_2 <= split_new[1].uop.srcState_2;
      splitLoadReqs_1_uop_srcState_3 <= split_new[1].uop.srcState_3;
      splitLoadReqs_1_uop_srcState_4 <= split_new[1].uop.srcState_4;
      splitLoadReqs_1_uop_srcLoadDependency_0_0 <= split_new[1].uop.srcLoadDependency_0_0;
      splitLoadReqs_1_uop_srcLoadDependency_0_1 <= split_new[1].uop.srcLoadDependency_0_1;
      splitLoadReqs_1_uop_srcLoadDependency_0_2 <= split_new[1].uop.srcLoadDependency_0_2;
      splitLoadReqs_1_uop_srcLoadDependency_1_0 <= split_new[1].uop.srcLoadDependency_1_0;
      splitLoadReqs_1_uop_srcLoadDependency_1_1 <= split_new[1].uop.srcLoadDependency_1_1;
      splitLoadReqs_1_uop_srcLoadDependency_1_2 <= split_new[1].uop.srcLoadDependency_1_2;
      splitLoadReqs_1_uop_srcLoadDependency_2_0 <= split_new[1].uop.srcLoadDependency_2_0;
      splitLoadReqs_1_uop_srcLoadDependency_2_1 <= split_new[1].uop.srcLoadDependency_2_1;
      splitLoadReqs_1_uop_srcLoadDependency_2_2 <= split_new[1].uop.srcLoadDependency_2_2;
      splitLoadReqs_1_uop_srcLoadDependency_3_0 <= split_new[1].uop.srcLoadDependency_3_0;
      splitLoadReqs_1_uop_srcLoadDependency_3_1 <= split_new[1].uop.srcLoadDependency_3_1;
      splitLoadReqs_1_uop_srcLoadDependency_3_2 <= split_new[1].uop.srcLoadDependency_3_2;
      splitLoadReqs_1_uop_srcLoadDependency_4_0 <= split_new[1].uop.srcLoadDependency_4_0;
      splitLoadReqs_1_uop_srcLoadDependency_4_1 <= split_new[1].uop.srcLoadDependency_4_1;
      splitLoadReqs_1_uop_srcLoadDependency_4_2 <= split_new[1].uop.srcLoadDependency_4_2;
      splitLoadReqs_1_uop_psrc_0 <= split_new[1].uop.psrc_0;
      splitLoadReqs_1_uop_psrc_1 <= split_new[1].uop.psrc_1;
      splitLoadReqs_1_uop_psrc_2 <= split_new[1].uop.psrc_2;
      splitLoadReqs_1_uop_psrc_3 <= split_new[1].uop.psrc_3;
      splitLoadReqs_1_uop_psrc_4 <= split_new[1].uop.psrc_4;
      splitLoadReqs_1_uop_pdest <= split_new[1].uop.pdest;
      splitLoadReqs_1_uop_useRegCache_0 <= split_new[1].uop.useRegCache_0;
      splitLoadReqs_1_uop_useRegCache_1 <= split_new[1].uop.useRegCache_1;
      splitLoadReqs_1_uop_regCacheIdx_0 <= split_new[1].uop.regCacheIdx_0;
      splitLoadReqs_1_uop_regCacheIdx_1 <= split_new[1].uop.regCacheIdx_1;
      splitLoadReqs_1_uop_robIdx_flag <= split_new[1].uop.robIdx_flag;
      splitLoadReqs_1_uop_robIdx_value <= split_new[1].uop.robIdx_value;
      splitLoadReqs_1_uop_instrSize <= split_new[1].uop.instrSize;
      splitLoadReqs_1_uop_dirtyFs <= split_new[1].uop.dirtyFs;
      splitLoadReqs_1_uop_dirtyVs <= split_new[1].uop.dirtyVs;
      splitLoadReqs_1_uop_traceBlockInPipe_itype <= split_new[1].uop.traceBlockInPipe_itype;
      splitLoadReqs_1_uop_traceBlockInPipe_iretire <= split_new[1].uop.traceBlockInPipe_iretire;
      splitLoadReqs_1_uop_traceBlockInPipe_ilastsize <= split_new[1].uop.traceBlockInPipe_ilastsize;
      splitLoadReqs_1_uop_eliminatedMove <= split_new[1].uop.eliminatedMove;
      splitLoadReqs_1_uop_snapshot <= split_new[1].uop.snapshot;
      splitLoadReqs_1_uop_debugInfo_eliminatedMove <= split_new[1].uop.debugInfo_eliminatedMove;
      splitLoadReqs_1_uop_debugInfo_renameTime <= split_new[1].uop.debugInfo_renameTime;
      splitLoadReqs_1_uop_debugInfo_dispatchTime <= split_new[1].uop.debugInfo_dispatchTime;
      splitLoadReqs_1_uop_debugInfo_enqRsTime <= split_new[1].uop.debugInfo_enqRsTime;
      splitLoadReqs_1_uop_debugInfo_selectTime <= split_new[1].uop.debugInfo_selectTime;
      splitLoadReqs_1_uop_debugInfo_issueTime <= split_new[1].uop.debugInfo_issueTime;
      splitLoadReqs_1_uop_debugInfo_writebackTime <= split_new[1].uop.debugInfo_writebackTime;
      splitLoadReqs_1_uop_debugInfo_runahead_checkpoint_id <= split_new[1].uop.debugInfo_runahead_checkpoint_id;
      splitLoadReqs_1_uop_debugInfo_tlbFirstReqTime <= split_new[1].uop.debugInfo_tlbFirstReqTime;
      splitLoadReqs_1_uop_debugInfo_tlbRespTime <= split_new[1].uop.debugInfo_tlbRespTime;
      splitLoadReqs_1_uop_debug_seqNum_seqNum <= split_new[1].uop.debug_seqNum_seqNum;
      splitLoadReqs_1_uop_debug_seqNum_uopIdx <= split_new[1].uop.debug_seqNum_uopIdx;
      splitLoadReqs_1_uop_storeSetHit <= split_new[1].uop.storeSetHit;
      splitLoadReqs_1_uop_waitForRobIdx_flag <= split_new[1].uop.waitForRobIdx_flag;
      splitLoadReqs_1_uop_waitForRobIdx_value <= split_new[1].uop.waitForRobIdx_value;
      splitLoadReqs_1_uop_loadWaitBit <= split_new[1].uop.loadWaitBit;
      splitLoadReqs_1_uop_loadWaitStrict <= split_new[1].uop.loadWaitStrict;
      splitLoadReqs_1_uop_ssid <= split_new[1].uop.ssid;
      splitLoadReqs_1_uop_lqIdx_flag <= split_new[1].uop.lqIdx_flag;
      splitLoadReqs_1_uop_lqIdx_value <= split_new[1].uop.lqIdx_value;
      splitLoadReqs_1_uop_sqIdx_flag <= split_new[1].uop.sqIdx_flag;
      splitLoadReqs_1_uop_sqIdx_value <= split_new[1].uop.sqIdx_value;
      splitLoadReqs_1_uop_singleStep <= split_new[1].uop.singleStep;
      splitLoadReqs_1_uop_replayInst <= split_new[1].uop.replayInst;
      splitLoadReqs_1_uop_debug_fuType <= split_new[1].uop.debug_fuType;
      splitLoadReqs_1_uop_debug_sim_trig <= split_new[1].uop.debug_sim_trig;
      splitLoadReqs_1_uop_numLsElem <= split_new[1].uop.numLsElem;
      splitLoadReqs_1_vaddr <= split_new[1].vaddr;
      splitLoadReqs_1_fullva <= split_new[1].fullva;
      splitLoadReqs_1_vaNeedExt <= split_new[1].vaNeedExt;
      splitLoadReqs_1_paddr <= split_new[1].paddr;
      splitLoadReqs_1_gpaddr <= split_new[1].gpaddr;
      splitLoadReqs_1_mask <= split_new[1].mask;
      splitLoadReqs_1_nc <= split_new[1].nc;
      splitLoadReqs_1_mmio <= split_new[1].mmio;
      splitLoadReqs_1_memBackTypeMM <= split_new[1].memBackTypeMM;
      splitLoadReqs_1_isForVSnonLeafPTE <= split_new[1].isForVSnonLeafPTE;
      splitLoadReqs_1_is128bit <= split_new[1].is128bit;
      splitLoadReqs_1_vecActive <= split_new[1].vecActive;
      splitLoadReqs_1_mshrid <= split_new[1].mshrid;
      splitLoadReqs_1_schedIndex <= split_new[1].schedIndex;
    end
  end
  always_comb begin
    split_reqs[1] = '0;   // golden 没留的字段恒 0
    split_reqs[1].uop.instr = splitLoadReqs_1_uop_instr;
    split_reqs[1].uop.pc = splitLoadReqs_1_uop_pc;
    split_reqs[1].uop.foldpc = splitLoadReqs_1_uop_foldpc;
    split_reqs[1].uop.exceptionVec[0] = splitLoadReqs_1_uop_exceptionVec_0;
    split_reqs[1].uop.exceptionVec[1] = splitLoadReqs_1_uop_exceptionVec_1;
    split_reqs[1].uop.exceptionVec[2] = splitLoadReqs_1_uop_exceptionVec_2;
    split_reqs[1].uop.exceptionVec[3] = splitLoadReqs_1_uop_exceptionVec_3;
    split_reqs[1].uop.exceptionVec[4] = splitLoadReqs_1_uop_exceptionVec_4;
    split_reqs[1].uop.exceptionVec[5] = splitLoadReqs_1_uop_exceptionVec_5;
    split_reqs[1].uop.exceptionVec[6] = splitLoadReqs_1_uop_exceptionVec_6;
    split_reqs[1].uop.exceptionVec[7] = splitLoadReqs_1_uop_exceptionVec_7;
    split_reqs[1].uop.exceptionVec[8] = splitLoadReqs_1_uop_exceptionVec_8;
    split_reqs[1].uop.exceptionVec[9] = splitLoadReqs_1_uop_exceptionVec_9;
    split_reqs[1].uop.exceptionVec[10] = splitLoadReqs_1_uop_exceptionVec_10;
    split_reqs[1].uop.exceptionVec[11] = splitLoadReqs_1_uop_exceptionVec_11;
    split_reqs[1].uop.exceptionVec[12] = splitLoadReqs_1_uop_exceptionVec_12;
    split_reqs[1].uop.exceptionVec[13] = splitLoadReqs_1_uop_exceptionVec_13;
    split_reqs[1].uop.exceptionVec[14] = splitLoadReqs_1_uop_exceptionVec_14;
    split_reqs[1].uop.exceptionVec[15] = splitLoadReqs_1_uop_exceptionVec_15;
    split_reqs[1].uop.exceptionVec[16] = splitLoadReqs_1_uop_exceptionVec_16;
    split_reqs[1].uop.exceptionVec[17] = splitLoadReqs_1_uop_exceptionVec_17;
    split_reqs[1].uop.exceptionVec[18] = splitLoadReqs_1_uop_exceptionVec_18;
    split_reqs[1].uop.exceptionVec[19] = splitLoadReqs_1_uop_exceptionVec_19;
    split_reqs[1].uop.exceptionVec[20] = splitLoadReqs_1_uop_exceptionVec_20;
    split_reqs[1].uop.exceptionVec[21] = splitLoadReqs_1_uop_exceptionVec_21;
    split_reqs[1].uop.exceptionVec[22] = splitLoadReqs_1_uop_exceptionVec_22;
    split_reqs[1].uop.exceptionVec[23] = splitLoadReqs_1_uop_exceptionVec_23;
    split_reqs[1].uop.isFetchMalAddr = splitLoadReqs_1_uop_isFetchMalAddr;
    split_reqs[1].uop.hasException = splitLoadReqs_1_uop_hasException;
    split_reqs[1].uop.trigger = splitLoadReqs_1_uop_trigger;
    split_reqs[1].uop.preDecodeInfo_valid = splitLoadReqs_1_uop_preDecodeInfo_valid;
    split_reqs[1].uop.preDecodeInfo_isRVC = splitLoadReqs_1_uop_preDecodeInfo_isRVC;
    split_reqs[1].uop.preDecodeInfo_brType = splitLoadReqs_1_uop_preDecodeInfo_brType;
    split_reqs[1].uop.preDecodeInfo_isCall = splitLoadReqs_1_uop_preDecodeInfo_isCall;
    split_reqs[1].uop.preDecodeInfo_isRet = splitLoadReqs_1_uop_preDecodeInfo_isRet;
    split_reqs[1].uop.pred_taken = splitLoadReqs_1_uop_pred_taken;
    split_reqs[1].uop.crossPageIPFFix = splitLoadReqs_1_uop_crossPageIPFFix;
    split_reqs[1].uop.ftqPtr_flag = splitLoadReqs_1_uop_ftqPtr_flag;
    split_reqs[1].uop.ftqPtr_value = splitLoadReqs_1_uop_ftqPtr_value;
    split_reqs[1].uop.ftqOffset = splitLoadReqs_1_uop_ftqOffset;
    split_reqs[1].uop.satpFlushFirstFetchFault = splitLoadReqs_1_uop_satpFlushFirstFetchFault;
    split_reqs[1].uop.srcType_0 = splitLoadReqs_1_uop_srcType_0;
    split_reqs[1].uop.srcType_1 = splitLoadReqs_1_uop_srcType_1;
    split_reqs[1].uop.srcType_2 = splitLoadReqs_1_uop_srcType_2;
    split_reqs[1].uop.srcType_3 = splitLoadReqs_1_uop_srcType_3;
    split_reqs[1].uop.srcType_4 = splitLoadReqs_1_uop_srcType_4;
    split_reqs[1].uop.ldest = splitLoadReqs_1_uop_ldest;
    split_reqs[1].uop.fuType = splitLoadReqs_1_uop_fuType;
    split_reqs[1].uop.fuOpType = splitLoadReqs_1_uop_fuOpType;
    split_reqs[1].uop.rfWen = splitLoadReqs_1_uop_rfWen;
    split_reqs[1].uop.fpWen = splitLoadReqs_1_uop_fpWen;
    split_reqs[1].uop.vecWen = splitLoadReqs_1_uop_vecWen;
    split_reqs[1].uop.v0Wen = splitLoadReqs_1_uop_v0Wen;
    split_reqs[1].uop.vlWen = splitLoadReqs_1_uop_vlWen;
    split_reqs[1].uop.isXSTrap = splitLoadReqs_1_uop_isXSTrap;
    split_reqs[1].uop.waitForward = splitLoadReqs_1_uop_waitForward;
    split_reqs[1].uop.blockBackward = splitLoadReqs_1_uop_blockBackward;
    split_reqs[1].uop.flushPipe = splitLoadReqs_1_uop_flushPipe;
    split_reqs[1].uop.canRobCompress = splitLoadReqs_1_uop_canRobCompress;
    split_reqs[1].uop.selImm = splitLoadReqs_1_uop_selImm;
    split_reqs[1].uop.imm = splitLoadReqs_1_uop_imm;
    split_reqs[1].uop.fpu_typeTagOut = splitLoadReqs_1_uop_fpu_typeTagOut;
    split_reqs[1].uop.fpu_wflags = splitLoadReqs_1_uop_fpu_wflags;
    split_reqs[1].uop.fpu_typ = splitLoadReqs_1_uop_fpu_typ;
    split_reqs[1].uop.fpu_fmt = splitLoadReqs_1_uop_fpu_fmt;
    split_reqs[1].uop.fpu_rm = splitLoadReqs_1_uop_fpu_rm;
    split_reqs[1].uop.vpu_vill = splitLoadReqs_1_uop_vpu_vill;
    split_reqs[1].uop.vpu_vma = splitLoadReqs_1_uop_vpu_vma;
    split_reqs[1].uop.vpu_vta = splitLoadReqs_1_uop_vpu_vta;
    split_reqs[1].uop.vpu_vsew = splitLoadReqs_1_uop_vpu_vsew;
    split_reqs[1].uop.vpu_vlmul = splitLoadReqs_1_uop_vpu_vlmul;
    split_reqs[1].uop.vpu_specVill = splitLoadReqs_1_uop_vpu_specVill;
    split_reqs[1].uop.vpu_specVma = splitLoadReqs_1_uop_vpu_specVma;
    split_reqs[1].uop.vpu_specVta = splitLoadReqs_1_uop_vpu_specVta;
    split_reqs[1].uop.vpu_specVsew = splitLoadReqs_1_uop_vpu_specVsew;
    split_reqs[1].uop.vpu_specVlmul = splitLoadReqs_1_uop_vpu_specVlmul;
    split_reqs[1].uop.vpu_vm = splitLoadReqs_1_uop_vpu_vm;
    split_reqs[1].uop.vpu_vstart = splitLoadReqs_1_uop_vpu_vstart;
    split_reqs[1].uop.vpu_frm = splitLoadReqs_1_uop_vpu_frm;
    split_reqs[1].uop.vpu_fpu_isFpToVecInst = splitLoadReqs_1_uop_vpu_fpu_isFpToVecInst;
    split_reqs[1].uop.vpu_fpu_isFP32Instr = splitLoadReqs_1_uop_vpu_fpu_isFP32Instr;
    split_reqs[1].uop.vpu_fpu_isFP64Instr = splitLoadReqs_1_uop_vpu_fpu_isFP64Instr;
    split_reqs[1].uop.vpu_fpu_isReduction = splitLoadReqs_1_uop_vpu_fpu_isReduction;
    split_reqs[1].uop.vpu_fpu_isFoldTo1_2 = splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_2;
    split_reqs[1].uop.vpu_fpu_isFoldTo1_4 = splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_4;
    split_reqs[1].uop.vpu_fpu_isFoldTo1_8 = splitLoadReqs_1_uop_vpu_fpu_isFoldTo1_8;
    split_reqs[1].uop.vpu_vxrm = splitLoadReqs_1_uop_vpu_vxrm;
    split_reqs[1].uop.vpu_vuopIdx = splitLoadReqs_1_uop_vpu_vuopIdx;
    split_reqs[1].uop.vpu_lastUop = splitLoadReqs_1_uop_vpu_lastUop;
    split_reqs[1].uop.vpu_vmask = splitLoadReqs_1_uop_vpu_vmask;
    split_reqs[1].uop.vpu_vl = splitLoadReqs_1_uop_vpu_vl;
    split_reqs[1].uop.vpu_nf = splitLoadReqs_1_uop_vpu_nf;
    split_reqs[1].uop.vpu_veew = splitLoadReqs_1_uop_vpu_veew;
    split_reqs[1].uop.vpu_isReverse = splitLoadReqs_1_uop_vpu_isReverse;
    split_reqs[1].uop.vpu_isExt = splitLoadReqs_1_uop_vpu_isExt;
    split_reqs[1].uop.vpu_isNarrow = splitLoadReqs_1_uop_vpu_isNarrow;
    split_reqs[1].uop.vpu_isDstMask = splitLoadReqs_1_uop_vpu_isDstMask;
    split_reqs[1].uop.vpu_isOpMask = splitLoadReqs_1_uop_vpu_isOpMask;
    split_reqs[1].uop.vpu_isMove = splitLoadReqs_1_uop_vpu_isMove;
    split_reqs[1].uop.vpu_isDependOldVd = splitLoadReqs_1_uop_vpu_isDependOldVd;
    split_reqs[1].uop.vpu_isWritePartVd = splitLoadReqs_1_uop_vpu_isWritePartVd;
    split_reqs[1].uop.vpu_isVleff = splitLoadReqs_1_uop_vpu_isVleff;
    split_reqs[1].uop.vlsInstr = splitLoadReqs_1_uop_vlsInstr;
    split_reqs[1].uop.wfflags = splitLoadReqs_1_uop_wfflags;
    split_reqs[1].uop.isMove = splitLoadReqs_1_uop_isMove;
    split_reqs[1].uop.isDropAmocasSta = splitLoadReqs_1_uop_isDropAmocasSta;
    split_reqs[1].uop.uopIdx = splitLoadReqs_1_uop_uopIdx;
    split_reqs[1].uop.isVset = splitLoadReqs_1_uop_isVset;
    split_reqs[1].uop.firstUop = splitLoadReqs_1_uop_firstUop;
    split_reqs[1].uop.lastUop = splitLoadReqs_1_uop_lastUop;
    split_reqs[1].uop.numUops = splitLoadReqs_1_uop_numUops;
    split_reqs[1].uop.numWB = splitLoadReqs_1_uop_numWB;
    split_reqs[1].uop.commitType = splitLoadReqs_1_uop_commitType;
    split_reqs[1].uop.srcState_0 = splitLoadReqs_1_uop_srcState_0;
    split_reqs[1].uop.srcState_1 = splitLoadReqs_1_uop_srcState_1;
    split_reqs[1].uop.srcState_2 = splitLoadReqs_1_uop_srcState_2;
    split_reqs[1].uop.srcState_3 = splitLoadReqs_1_uop_srcState_3;
    split_reqs[1].uop.srcState_4 = splitLoadReqs_1_uop_srcState_4;
    split_reqs[1].uop.srcLoadDependency_0_0 = splitLoadReqs_1_uop_srcLoadDependency_0_0;
    split_reqs[1].uop.srcLoadDependency_0_1 = splitLoadReqs_1_uop_srcLoadDependency_0_1;
    split_reqs[1].uop.srcLoadDependency_0_2 = splitLoadReqs_1_uop_srcLoadDependency_0_2;
    split_reqs[1].uop.srcLoadDependency_1_0 = splitLoadReqs_1_uop_srcLoadDependency_1_0;
    split_reqs[1].uop.srcLoadDependency_1_1 = splitLoadReqs_1_uop_srcLoadDependency_1_1;
    split_reqs[1].uop.srcLoadDependency_1_2 = splitLoadReqs_1_uop_srcLoadDependency_1_2;
    split_reqs[1].uop.srcLoadDependency_2_0 = splitLoadReqs_1_uop_srcLoadDependency_2_0;
    split_reqs[1].uop.srcLoadDependency_2_1 = splitLoadReqs_1_uop_srcLoadDependency_2_1;
    split_reqs[1].uop.srcLoadDependency_2_2 = splitLoadReqs_1_uop_srcLoadDependency_2_2;
    split_reqs[1].uop.srcLoadDependency_3_0 = splitLoadReqs_1_uop_srcLoadDependency_3_0;
    split_reqs[1].uop.srcLoadDependency_3_1 = splitLoadReqs_1_uop_srcLoadDependency_3_1;
    split_reqs[1].uop.srcLoadDependency_3_2 = splitLoadReqs_1_uop_srcLoadDependency_3_2;
    split_reqs[1].uop.srcLoadDependency_4_0 = splitLoadReqs_1_uop_srcLoadDependency_4_0;
    split_reqs[1].uop.srcLoadDependency_4_1 = splitLoadReqs_1_uop_srcLoadDependency_4_1;
    split_reqs[1].uop.srcLoadDependency_4_2 = splitLoadReqs_1_uop_srcLoadDependency_4_2;
    split_reqs[1].uop.psrc_0 = splitLoadReqs_1_uop_psrc_0;
    split_reqs[1].uop.psrc_1 = splitLoadReqs_1_uop_psrc_1;
    split_reqs[1].uop.psrc_2 = splitLoadReqs_1_uop_psrc_2;
    split_reqs[1].uop.psrc_3 = splitLoadReqs_1_uop_psrc_3;
    split_reqs[1].uop.psrc_4 = splitLoadReqs_1_uop_psrc_4;
    split_reqs[1].uop.pdest = splitLoadReqs_1_uop_pdest;
    split_reqs[1].uop.useRegCache_0 = splitLoadReqs_1_uop_useRegCache_0;
    split_reqs[1].uop.useRegCache_1 = splitLoadReqs_1_uop_useRegCache_1;
    split_reqs[1].uop.regCacheIdx_0 = splitLoadReqs_1_uop_regCacheIdx_0;
    split_reqs[1].uop.regCacheIdx_1 = splitLoadReqs_1_uop_regCacheIdx_1;
    split_reqs[1].uop.robIdx_flag = splitLoadReqs_1_uop_robIdx_flag;
    split_reqs[1].uop.robIdx_value = splitLoadReqs_1_uop_robIdx_value;
    split_reqs[1].uop.instrSize = splitLoadReqs_1_uop_instrSize;
    split_reqs[1].uop.dirtyFs = splitLoadReqs_1_uop_dirtyFs;
    split_reqs[1].uop.dirtyVs = splitLoadReqs_1_uop_dirtyVs;
    split_reqs[1].uop.traceBlockInPipe_itype = splitLoadReqs_1_uop_traceBlockInPipe_itype;
    split_reqs[1].uop.traceBlockInPipe_iretire = splitLoadReqs_1_uop_traceBlockInPipe_iretire;
    split_reqs[1].uop.traceBlockInPipe_ilastsize = splitLoadReqs_1_uop_traceBlockInPipe_ilastsize;
    split_reqs[1].uop.eliminatedMove = splitLoadReqs_1_uop_eliminatedMove;
    split_reqs[1].uop.snapshot = splitLoadReqs_1_uop_snapshot;
    split_reqs[1].uop.debugInfo_eliminatedMove = splitLoadReqs_1_uop_debugInfo_eliminatedMove;
    split_reqs[1].uop.debugInfo_renameTime = splitLoadReqs_1_uop_debugInfo_renameTime;
    split_reqs[1].uop.debugInfo_dispatchTime = splitLoadReqs_1_uop_debugInfo_dispatchTime;
    split_reqs[1].uop.debugInfo_enqRsTime = splitLoadReqs_1_uop_debugInfo_enqRsTime;
    split_reqs[1].uop.debugInfo_selectTime = splitLoadReqs_1_uop_debugInfo_selectTime;
    split_reqs[1].uop.debugInfo_issueTime = splitLoadReqs_1_uop_debugInfo_issueTime;
    split_reqs[1].uop.debugInfo_writebackTime = splitLoadReqs_1_uop_debugInfo_writebackTime;
    split_reqs[1].uop.debugInfo_runahead_checkpoint_id = splitLoadReqs_1_uop_debugInfo_runahead_checkpoint_id;
    split_reqs[1].uop.debugInfo_tlbFirstReqTime = splitLoadReqs_1_uop_debugInfo_tlbFirstReqTime;
    split_reqs[1].uop.debugInfo_tlbRespTime = splitLoadReqs_1_uop_debugInfo_tlbRespTime;
    split_reqs[1].uop.debug_seqNum_seqNum = splitLoadReqs_1_uop_debug_seqNum_seqNum;
    split_reqs[1].uop.debug_seqNum_uopIdx = splitLoadReqs_1_uop_debug_seqNum_uopIdx;
    split_reqs[1].uop.storeSetHit = splitLoadReqs_1_uop_storeSetHit;
    split_reqs[1].uop.waitForRobIdx_flag = splitLoadReqs_1_uop_waitForRobIdx_flag;
    split_reqs[1].uop.waitForRobIdx_value = splitLoadReqs_1_uop_waitForRobIdx_value;
    split_reqs[1].uop.loadWaitBit = splitLoadReqs_1_uop_loadWaitBit;
    split_reqs[1].uop.loadWaitStrict = splitLoadReqs_1_uop_loadWaitStrict;
    split_reqs[1].uop.ssid = splitLoadReqs_1_uop_ssid;
    split_reqs[1].uop.lqIdx_flag = splitLoadReqs_1_uop_lqIdx_flag;
    split_reqs[1].uop.lqIdx_value = splitLoadReqs_1_uop_lqIdx_value;
    split_reqs[1].uop.sqIdx_flag = splitLoadReqs_1_uop_sqIdx_flag;
    split_reqs[1].uop.sqIdx_value = splitLoadReqs_1_uop_sqIdx_value;
    split_reqs[1].uop.singleStep = splitLoadReqs_1_uop_singleStep;
    split_reqs[1].uop.replayInst = splitLoadReqs_1_uop_replayInst;
    split_reqs[1].uop.debug_fuType = splitLoadReqs_1_uop_debug_fuType;
    split_reqs[1].uop.debug_sim_trig = splitLoadReqs_1_uop_debug_sim_trig;
    split_reqs[1].uop.numLsElem = splitLoadReqs_1_uop_numLsElem;
    split_reqs[1].vaddr = splitLoadReqs_1_vaddr;
    split_reqs[1].fullva = splitLoadReqs_1_fullva;
    split_reqs[1].vaNeedExt = splitLoadReqs_1_vaNeedExt;
    split_reqs[1].paddr = splitLoadReqs_1_paddr;
    split_reqs[1].gpaddr = splitLoadReqs_1_gpaddr;
    split_reqs[1].mask = splitLoadReqs_1_mask;
    split_reqs[1].nc = splitLoadReqs_1_nc;
    split_reqs[1].mmio = splitLoadReqs_1_mmio;
    split_reqs[1].memBackTypeMM = splitLoadReqs_1_memBackTypeMM;
    split_reqs[1].isForVSnonLeafPTE = splitLoadReqs_1_isForVSnonLeafPTE;
    split_reqs[1].is128bit = splitLoadReqs_1_is128bit;
    split_reqs[1].vecActive = splitLoadReqs_1_vecActive;
    split_reqs[1].mshrid = splitLoadReqs_1_mshrid;
    split_reqs[1].schedIndex = splitLoadReqs_1_schedIndex;
  end
  // END GENERATED(regs)

endmodule

// =====================================================================
// golden 同名 wrapper —— 端口逐位照抄 golden，拆装成 struct 接核
// =====================================================================
// BEGIN GENERATED(wrapper) —— scripts/gen_lmisalign.py 生成，勿手改
module LoadMisalignBuffer
  import loadmisalignbuffer_pkg::*;
(
  input           clock,
  input           reset,
  input           io_redirect_valid,
  input           io_redirect_bits_robIdx_flag,
  input  [7:0]    io_redirect_bits_robIdx_value,
  input           io_redirect_bits_level,
  output          io_enq_0_req_ready,
  input           io_enq_0_req_valid,
  input  [31:0]   io_enq_0_req_bits_uop_instr,
  input  [49:0]   io_enq_0_req_bits_uop_pc,
  input  [9:0]    io_enq_0_req_bits_uop_foldpc,
  input           io_enq_0_req_bits_uop_exceptionVec_0,
  input           io_enq_0_req_bits_uop_exceptionVec_1,
  input           io_enq_0_req_bits_uop_exceptionVec_2,
  input           io_enq_0_req_bits_uop_exceptionVec_3,
  input           io_enq_0_req_bits_uop_exceptionVec_5,
  input           io_enq_0_req_bits_uop_exceptionVec_6,
  input           io_enq_0_req_bits_uop_exceptionVec_7,
  input           io_enq_0_req_bits_uop_exceptionVec_8,
  input           io_enq_0_req_bits_uop_exceptionVec_9,
  input           io_enq_0_req_bits_uop_exceptionVec_10,
  input           io_enq_0_req_bits_uop_exceptionVec_11,
  input           io_enq_0_req_bits_uop_exceptionVec_12,
  input           io_enq_0_req_bits_uop_exceptionVec_13,
  input           io_enq_0_req_bits_uop_exceptionVec_14,
  input           io_enq_0_req_bits_uop_exceptionVec_15,
  input           io_enq_0_req_bits_uop_exceptionVec_16,
  input           io_enq_0_req_bits_uop_exceptionVec_17,
  input           io_enq_0_req_bits_uop_exceptionVec_18,
  input           io_enq_0_req_bits_uop_exceptionVec_19,
  input           io_enq_0_req_bits_uop_exceptionVec_20,
  input           io_enq_0_req_bits_uop_exceptionVec_21,
  input           io_enq_0_req_bits_uop_exceptionVec_22,
  input           io_enq_0_req_bits_uop_exceptionVec_23,
  input           io_enq_0_req_bits_uop_isFetchMalAddr,
  input           io_enq_0_req_bits_uop_hasException,
  input  [3:0]    io_enq_0_req_bits_uop_trigger,
  input           io_enq_0_req_bits_uop_preDecodeInfo_valid,
  input           io_enq_0_req_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]    io_enq_0_req_bits_uop_preDecodeInfo_brType,
  input           io_enq_0_req_bits_uop_preDecodeInfo_isCall,
  input           io_enq_0_req_bits_uop_preDecodeInfo_isRet,
  input           io_enq_0_req_bits_uop_pred_taken,
  input           io_enq_0_req_bits_uop_crossPageIPFFix,
  input           io_enq_0_req_bits_uop_ftqPtr_flag,
  input  [5:0]    io_enq_0_req_bits_uop_ftqPtr_value,
  input  [3:0]    io_enq_0_req_bits_uop_ftqOffset,
  input           io_enq_0_req_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]    io_enq_0_req_bits_uop_srcType_0,
  input  [3:0]    io_enq_0_req_bits_uop_srcType_1,
  input  [3:0]    io_enq_0_req_bits_uop_srcType_2,
  input  [3:0]    io_enq_0_req_bits_uop_srcType_3,
  input  [3:0]    io_enq_0_req_bits_uop_srcType_4,
  input  [5:0]    io_enq_0_req_bits_uop_ldest,
  input  [34:0]   io_enq_0_req_bits_uop_fuType,
  input  [8:0]    io_enq_0_req_bits_uop_fuOpType,
  input           io_enq_0_req_bits_uop_rfWen,
  input           io_enq_0_req_bits_uop_fpWen,
  input           io_enq_0_req_bits_uop_vecWen,
  input           io_enq_0_req_bits_uop_v0Wen,
  input           io_enq_0_req_bits_uop_vlWen,
  input           io_enq_0_req_bits_uop_isXSTrap,
  input           io_enq_0_req_bits_uop_waitForward,
  input           io_enq_0_req_bits_uop_blockBackward,
  input           io_enq_0_req_bits_uop_canRobCompress,
  input  [3:0]    io_enq_0_req_bits_uop_selImm,
  input  [31:0]   io_enq_0_req_bits_uop_imm,
  input  [1:0]    io_enq_0_req_bits_uop_fpu_typeTagOut,
  input           io_enq_0_req_bits_uop_fpu_wflags,
  input  [1:0]    io_enq_0_req_bits_uop_fpu_typ,
  input  [1:0]    io_enq_0_req_bits_uop_fpu_fmt,
  input  [2:0]    io_enq_0_req_bits_uop_fpu_rm,
  input           io_enq_0_req_bits_uop_vpu_vill,
  input           io_enq_0_req_bits_uop_vpu_vma,
  input           io_enq_0_req_bits_uop_vpu_vta,
  input  [1:0]    io_enq_0_req_bits_uop_vpu_vsew,
  input  [2:0]    io_enq_0_req_bits_uop_vpu_vlmul,
  input           io_enq_0_req_bits_uop_vpu_specVill,
  input           io_enq_0_req_bits_uop_vpu_specVma,
  input           io_enq_0_req_bits_uop_vpu_specVta,
  input  [1:0]    io_enq_0_req_bits_uop_vpu_specVsew,
  input  [2:0]    io_enq_0_req_bits_uop_vpu_specVlmul,
  input           io_enq_0_req_bits_uop_vpu_vm,
  input  [7:0]    io_enq_0_req_bits_uop_vpu_vstart,
  input  [2:0]    io_enq_0_req_bits_uop_vpu_frm,
  input           io_enq_0_req_bits_uop_vpu_fpu_isFpToVecInst,
  input           io_enq_0_req_bits_uop_vpu_fpu_isFP32Instr,
  input           io_enq_0_req_bits_uop_vpu_fpu_isFP64Instr,
  input           io_enq_0_req_bits_uop_vpu_fpu_isReduction,
  input           io_enq_0_req_bits_uop_vpu_fpu_isFoldTo1_2,
  input           io_enq_0_req_bits_uop_vpu_fpu_isFoldTo1_4,
  input           io_enq_0_req_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]    io_enq_0_req_bits_uop_vpu_vxrm,
  input  [6:0]    io_enq_0_req_bits_uop_vpu_vuopIdx,
  input           io_enq_0_req_bits_uop_vpu_lastUop,
  input  [127:0]  io_enq_0_req_bits_uop_vpu_vmask,
  input  [7:0]    io_enq_0_req_bits_uop_vpu_vl,
  input  [2:0]    io_enq_0_req_bits_uop_vpu_nf,
  input  [1:0]    io_enq_0_req_bits_uop_vpu_veew,
  input           io_enq_0_req_bits_uop_vpu_isReverse,
  input           io_enq_0_req_bits_uop_vpu_isExt,
  input           io_enq_0_req_bits_uop_vpu_isNarrow,
  input           io_enq_0_req_bits_uop_vpu_isDstMask,
  input           io_enq_0_req_bits_uop_vpu_isOpMask,
  input           io_enq_0_req_bits_uop_vpu_isMove,
  input           io_enq_0_req_bits_uop_vpu_isDependOldVd,
  input           io_enq_0_req_bits_uop_vpu_isWritePartVd,
  input           io_enq_0_req_bits_uop_vpu_isVleff,
  input           io_enq_0_req_bits_uop_vlsInstr,
  input           io_enq_0_req_bits_uop_wfflags,
  input           io_enq_0_req_bits_uop_isMove,
  input           io_enq_0_req_bits_uop_isDropAmocasSta,
  input  [6:0]    io_enq_0_req_bits_uop_uopIdx,
  input           io_enq_0_req_bits_uop_isVset,
  input           io_enq_0_req_bits_uop_firstUop,
  input           io_enq_0_req_bits_uop_lastUop,
  input  [6:0]    io_enq_0_req_bits_uop_numUops,
  input  [6:0]    io_enq_0_req_bits_uop_numWB,
  input  [2:0]    io_enq_0_req_bits_uop_commitType,
  input           io_enq_0_req_bits_uop_srcState_0,
  input           io_enq_0_req_bits_uop_srcState_1,
  input           io_enq_0_req_bits_uop_srcState_2,
  input           io_enq_0_req_bits_uop_srcState_3,
  input           io_enq_0_req_bits_uop_srcState_4,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_0_0,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_0_1,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_0_2,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_1_0,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_1_1,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_1_2,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_2_0,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_2_1,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_2_2,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_3_0,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_3_1,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_3_2,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_4_0,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_4_1,
  input  [1:0]    io_enq_0_req_bits_uop_srcLoadDependency_4_2,
  input  [7:0]    io_enq_0_req_bits_uop_psrc_0,
  input  [7:0]    io_enq_0_req_bits_uop_psrc_1,
  input  [7:0]    io_enq_0_req_bits_uop_psrc_2,
  input  [7:0]    io_enq_0_req_bits_uop_psrc_3,
  input  [7:0]    io_enq_0_req_bits_uop_psrc_4,
  input  [7:0]    io_enq_0_req_bits_uop_pdest,
  input           io_enq_0_req_bits_uop_useRegCache_0,
  input           io_enq_0_req_bits_uop_useRegCache_1,
  input  [4:0]    io_enq_0_req_bits_uop_regCacheIdx_0,
  input  [4:0]    io_enq_0_req_bits_uop_regCacheIdx_1,
  input           io_enq_0_req_bits_uop_robIdx_flag,
  input  [7:0]    io_enq_0_req_bits_uop_robIdx_value,
  input  [2:0]    io_enq_0_req_bits_uop_instrSize,
  input           io_enq_0_req_bits_uop_dirtyFs,
  input           io_enq_0_req_bits_uop_dirtyVs,
  input  [3:0]    io_enq_0_req_bits_uop_traceBlockInPipe_itype,
  input  [3:0]    io_enq_0_req_bits_uop_traceBlockInPipe_iretire,
  input           io_enq_0_req_bits_uop_traceBlockInPipe_ilastsize,
  input           io_enq_0_req_bits_uop_eliminatedMove,
  input           io_enq_0_req_bits_uop_snapshot,
  input           io_enq_0_req_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_enq_0_req_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_enq_0_req_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_enq_0_req_bits_uop_debug_seqNum_uopIdx,
  input           io_enq_0_req_bits_uop_storeSetHit,
  input           io_enq_0_req_bits_uop_waitForRobIdx_flag,
  input  [7:0]    io_enq_0_req_bits_uop_waitForRobIdx_value,
  input           io_enq_0_req_bits_uop_loadWaitBit,
  input           io_enq_0_req_bits_uop_loadWaitStrict,
  input  [4:0]    io_enq_0_req_bits_uop_ssid,
  input           io_enq_0_req_bits_uop_lqIdx_flag,
  input  [6:0]    io_enq_0_req_bits_uop_lqIdx_value,
  input           io_enq_0_req_bits_uop_sqIdx_flag,
  input  [5:0]    io_enq_0_req_bits_uop_sqIdx_value,
  input           io_enq_0_req_bits_uop_singleStep,
  input           io_enq_0_req_bits_uop_replayInst,
  input  [34:0]   io_enq_0_req_bits_uop_debug_fuType,
  input           io_enq_0_req_bits_uop_debug_sim_trig,
  input  [4:0]    io_enq_0_req_bits_uop_numLsElem,
  input  [49:0]   io_enq_0_req_bits_vaddr,
  input  [63:0]   io_enq_0_req_bits_fullva,
  input           io_enq_0_req_bits_vaNeedExt,
  input  [47:0]   io_enq_0_req_bits_paddr,
  input  [63:0]   io_enq_0_req_bits_gpaddr,
  input  [15:0]   io_enq_0_req_bits_mask,
  input           io_enq_0_req_bits_isForVSnonLeafPTE,
  input           io_enq_0_req_bits_isvec,
  input  [7:0]    io_enq_0_req_bits_elemIdx,
  input  [2:0]    io_enq_0_req_bits_alignedType,
  input  [3:0]    io_enq_0_req_bits_mbIndex,
  input  [7:0]    io_enq_0_req_bits_elemIdxInsideVd,
  input  [15:0]   io_enq_0_req_bits_vecTriggerMask,
  output          io_enq_1_req_ready,
  input           io_enq_1_req_valid,
  input  [31:0]   io_enq_1_req_bits_uop_instr,
  input  [49:0]   io_enq_1_req_bits_uop_pc,
  input  [9:0]    io_enq_1_req_bits_uop_foldpc,
  input           io_enq_1_req_bits_uop_exceptionVec_0,
  input           io_enq_1_req_bits_uop_exceptionVec_1,
  input           io_enq_1_req_bits_uop_exceptionVec_2,
  input           io_enq_1_req_bits_uop_exceptionVec_3,
  input           io_enq_1_req_bits_uop_exceptionVec_5,
  input           io_enq_1_req_bits_uop_exceptionVec_6,
  input           io_enq_1_req_bits_uop_exceptionVec_7,
  input           io_enq_1_req_bits_uop_exceptionVec_8,
  input           io_enq_1_req_bits_uop_exceptionVec_9,
  input           io_enq_1_req_bits_uop_exceptionVec_10,
  input           io_enq_1_req_bits_uop_exceptionVec_11,
  input           io_enq_1_req_bits_uop_exceptionVec_12,
  input           io_enq_1_req_bits_uop_exceptionVec_13,
  input           io_enq_1_req_bits_uop_exceptionVec_14,
  input           io_enq_1_req_bits_uop_exceptionVec_15,
  input           io_enq_1_req_bits_uop_exceptionVec_16,
  input           io_enq_1_req_bits_uop_exceptionVec_17,
  input           io_enq_1_req_bits_uop_exceptionVec_18,
  input           io_enq_1_req_bits_uop_exceptionVec_19,
  input           io_enq_1_req_bits_uop_exceptionVec_20,
  input           io_enq_1_req_bits_uop_exceptionVec_21,
  input           io_enq_1_req_bits_uop_exceptionVec_22,
  input           io_enq_1_req_bits_uop_exceptionVec_23,
  input           io_enq_1_req_bits_uop_isFetchMalAddr,
  input           io_enq_1_req_bits_uop_hasException,
  input  [3:0]    io_enq_1_req_bits_uop_trigger,
  input           io_enq_1_req_bits_uop_preDecodeInfo_valid,
  input           io_enq_1_req_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]    io_enq_1_req_bits_uop_preDecodeInfo_brType,
  input           io_enq_1_req_bits_uop_preDecodeInfo_isCall,
  input           io_enq_1_req_bits_uop_preDecodeInfo_isRet,
  input           io_enq_1_req_bits_uop_pred_taken,
  input           io_enq_1_req_bits_uop_crossPageIPFFix,
  input           io_enq_1_req_bits_uop_ftqPtr_flag,
  input  [5:0]    io_enq_1_req_bits_uop_ftqPtr_value,
  input  [3:0]    io_enq_1_req_bits_uop_ftqOffset,
  input           io_enq_1_req_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]    io_enq_1_req_bits_uop_srcType_0,
  input  [3:0]    io_enq_1_req_bits_uop_srcType_1,
  input  [3:0]    io_enq_1_req_bits_uop_srcType_2,
  input  [3:0]    io_enq_1_req_bits_uop_srcType_3,
  input  [3:0]    io_enq_1_req_bits_uop_srcType_4,
  input  [5:0]    io_enq_1_req_bits_uop_ldest,
  input  [34:0]   io_enq_1_req_bits_uop_fuType,
  input  [8:0]    io_enq_1_req_bits_uop_fuOpType,
  input           io_enq_1_req_bits_uop_rfWen,
  input           io_enq_1_req_bits_uop_fpWen,
  input           io_enq_1_req_bits_uop_vecWen,
  input           io_enq_1_req_bits_uop_v0Wen,
  input           io_enq_1_req_bits_uop_vlWen,
  input           io_enq_1_req_bits_uop_isXSTrap,
  input           io_enq_1_req_bits_uop_waitForward,
  input           io_enq_1_req_bits_uop_blockBackward,
  input           io_enq_1_req_bits_uop_canRobCompress,
  input  [3:0]    io_enq_1_req_bits_uop_selImm,
  input  [31:0]   io_enq_1_req_bits_uop_imm,
  input  [1:0]    io_enq_1_req_bits_uop_fpu_typeTagOut,
  input           io_enq_1_req_bits_uop_fpu_wflags,
  input  [1:0]    io_enq_1_req_bits_uop_fpu_typ,
  input  [1:0]    io_enq_1_req_bits_uop_fpu_fmt,
  input  [2:0]    io_enq_1_req_bits_uop_fpu_rm,
  input           io_enq_1_req_bits_uop_vpu_vill,
  input           io_enq_1_req_bits_uop_vpu_vma,
  input           io_enq_1_req_bits_uop_vpu_vta,
  input  [1:0]    io_enq_1_req_bits_uop_vpu_vsew,
  input  [2:0]    io_enq_1_req_bits_uop_vpu_vlmul,
  input           io_enq_1_req_bits_uop_vpu_specVill,
  input           io_enq_1_req_bits_uop_vpu_specVma,
  input           io_enq_1_req_bits_uop_vpu_specVta,
  input  [1:0]    io_enq_1_req_bits_uop_vpu_specVsew,
  input  [2:0]    io_enq_1_req_bits_uop_vpu_specVlmul,
  input           io_enq_1_req_bits_uop_vpu_vm,
  input  [7:0]    io_enq_1_req_bits_uop_vpu_vstart,
  input  [2:0]    io_enq_1_req_bits_uop_vpu_frm,
  input           io_enq_1_req_bits_uop_vpu_fpu_isFpToVecInst,
  input           io_enq_1_req_bits_uop_vpu_fpu_isFP32Instr,
  input           io_enq_1_req_bits_uop_vpu_fpu_isFP64Instr,
  input           io_enq_1_req_bits_uop_vpu_fpu_isReduction,
  input           io_enq_1_req_bits_uop_vpu_fpu_isFoldTo1_2,
  input           io_enq_1_req_bits_uop_vpu_fpu_isFoldTo1_4,
  input           io_enq_1_req_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]    io_enq_1_req_bits_uop_vpu_vxrm,
  input  [6:0]    io_enq_1_req_bits_uop_vpu_vuopIdx,
  input           io_enq_1_req_bits_uop_vpu_lastUop,
  input  [127:0]  io_enq_1_req_bits_uop_vpu_vmask,
  input  [7:0]    io_enq_1_req_bits_uop_vpu_vl,
  input  [2:0]    io_enq_1_req_bits_uop_vpu_nf,
  input  [1:0]    io_enq_1_req_bits_uop_vpu_veew,
  input           io_enq_1_req_bits_uop_vpu_isReverse,
  input           io_enq_1_req_bits_uop_vpu_isExt,
  input           io_enq_1_req_bits_uop_vpu_isNarrow,
  input           io_enq_1_req_bits_uop_vpu_isDstMask,
  input           io_enq_1_req_bits_uop_vpu_isOpMask,
  input           io_enq_1_req_bits_uop_vpu_isMove,
  input           io_enq_1_req_bits_uop_vpu_isDependOldVd,
  input           io_enq_1_req_bits_uop_vpu_isWritePartVd,
  input           io_enq_1_req_bits_uop_vpu_isVleff,
  input           io_enq_1_req_bits_uop_vlsInstr,
  input           io_enq_1_req_bits_uop_wfflags,
  input           io_enq_1_req_bits_uop_isMove,
  input           io_enq_1_req_bits_uop_isDropAmocasSta,
  input  [6:0]    io_enq_1_req_bits_uop_uopIdx,
  input           io_enq_1_req_bits_uop_isVset,
  input           io_enq_1_req_bits_uop_firstUop,
  input           io_enq_1_req_bits_uop_lastUop,
  input  [6:0]    io_enq_1_req_bits_uop_numUops,
  input  [6:0]    io_enq_1_req_bits_uop_numWB,
  input  [2:0]    io_enq_1_req_bits_uop_commitType,
  input           io_enq_1_req_bits_uop_srcState_0,
  input           io_enq_1_req_bits_uop_srcState_1,
  input           io_enq_1_req_bits_uop_srcState_2,
  input           io_enq_1_req_bits_uop_srcState_3,
  input           io_enq_1_req_bits_uop_srcState_4,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_0_0,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_0_1,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_0_2,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_1_0,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_1_1,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_1_2,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_2_0,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_2_1,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_2_2,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_3_0,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_3_1,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_3_2,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_4_0,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_4_1,
  input  [1:0]    io_enq_1_req_bits_uop_srcLoadDependency_4_2,
  input  [7:0]    io_enq_1_req_bits_uop_psrc_0,
  input  [7:0]    io_enq_1_req_bits_uop_psrc_1,
  input  [7:0]    io_enq_1_req_bits_uop_psrc_2,
  input  [7:0]    io_enq_1_req_bits_uop_psrc_3,
  input  [7:0]    io_enq_1_req_bits_uop_psrc_4,
  input  [7:0]    io_enq_1_req_bits_uop_pdest,
  input           io_enq_1_req_bits_uop_useRegCache_0,
  input           io_enq_1_req_bits_uop_useRegCache_1,
  input  [4:0]    io_enq_1_req_bits_uop_regCacheIdx_0,
  input  [4:0]    io_enq_1_req_bits_uop_regCacheIdx_1,
  input           io_enq_1_req_bits_uop_robIdx_flag,
  input  [7:0]    io_enq_1_req_bits_uop_robIdx_value,
  input  [2:0]    io_enq_1_req_bits_uop_instrSize,
  input           io_enq_1_req_bits_uop_dirtyFs,
  input           io_enq_1_req_bits_uop_dirtyVs,
  input  [3:0]    io_enq_1_req_bits_uop_traceBlockInPipe_itype,
  input  [3:0]    io_enq_1_req_bits_uop_traceBlockInPipe_iretire,
  input           io_enq_1_req_bits_uop_traceBlockInPipe_ilastsize,
  input           io_enq_1_req_bits_uop_eliminatedMove,
  input           io_enq_1_req_bits_uop_snapshot,
  input           io_enq_1_req_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_enq_1_req_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_enq_1_req_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_enq_1_req_bits_uop_debug_seqNum_uopIdx,
  input           io_enq_1_req_bits_uop_storeSetHit,
  input           io_enq_1_req_bits_uop_waitForRobIdx_flag,
  input  [7:0]    io_enq_1_req_bits_uop_waitForRobIdx_value,
  input           io_enq_1_req_bits_uop_loadWaitBit,
  input           io_enq_1_req_bits_uop_loadWaitStrict,
  input  [4:0]    io_enq_1_req_bits_uop_ssid,
  input           io_enq_1_req_bits_uop_lqIdx_flag,
  input  [6:0]    io_enq_1_req_bits_uop_lqIdx_value,
  input           io_enq_1_req_bits_uop_sqIdx_flag,
  input  [5:0]    io_enq_1_req_bits_uop_sqIdx_value,
  input           io_enq_1_req_bits_uop_singleStep,
  input           io_enq_1_req_bits_uop_replayInst,
  input  [34:0]   io_enq_1_req_bits_uop_debug_fuType,
  input           io_enq_1_req_bits_uop_debug_sim_trig,
  input  [4:0]    io_enq_1_req_bits_uop_numLsElem,
  input  [49:0]   io_enq_1_req_bits_vaddr,
  input  [63:0]   io_enq_1_req_bits_fullva,
  input           io_enq_1_req_bits_vaNeedExt,
  input  [47:0]   io_enq_1_req_bits_paddr,
  input  [63:0]   io_enq_1_req_bits_gpaddr,
  input  [15:0]   io_enq_1_req_bits_mask,
  input           io_enq_1_req_bits_isForVSnonLeafPTE,
  input           io_enq_1_req_bits_isvec,
  input  [7:0]    io_enq_1_req_bits_elemIdx,
  input  [2:0]    io_enq_1_req_bits_alignedType,
  input  [3:0]    io_enq_1_req_bits_mbIndex,
  input  [7:0]    io_enq_1_req_bits_elemIdxInsideVd,
  input  [15:0]   io_enq_1_req_bits_vecTriggerMask,
  output          io_enq_2_req_ready,
  input           io_enq_2_req_valid,
  input  [31:0]   io_enq_2_req_bits_uop_instr,
  input  [49:0]   io_enq_2_req_bits_uop_pc,
  input  [9:0]    io_enq_2_req_bits_uop_foldpc,
  input           io_enq_2_req_bits_uop_exceptionVec_0,
  input           io_enq_2_req_bits_uop_exceptionVec_1,
  input           io_enq_2_req_bits_uop_exceptionVec_2,
  input           io_enq_2_req_bits_uop_exceptionVec_3,
  input           io_enq_2_req_bits_uop_exceptionVec_5,
  input           io_enq_2_req_bits_uop_exceptionVec_6,
  input           io_enq_2_req_bits_uop_exceptionVec_7,
  input           io_enq_2_req_bits_uop_exceptionVec_8,
  input           io_enq_2_req_bits_uop_exceptionVec_9,
  input           io_enq_2_req_bits_uop_exceptionVec_10,
  input           io_enq_2_req_bits_uop_exceptionVec_11,
  input           io_enq_2_req_bits_uop_exceptionVec_12,
  input           io_enq_2_req_bits_uop_exceptionVec_13,
  input           io_enq_2_req_bits_uop_exceptionVec_14,
  input           io_enq_2_req_bits_uop_exceptionVec_15,
  input           io_enq_2_req_bits_uop_exceptionVec_16,
  input           io_enq_2_req_bits_uop_exceptionVec_17,
  input           io_enq_2_req_bits_uop_exceptionVec_18,
  input           io_enq_2_req_bits_uop_exceptionVec_19,
  input           io_enq_2_req_bits_uop_exceptionVec_20,
  input           io_enq_2_req_bits_uop_exceptionVec_21,
  input           io_enq_2_req_bits_uop_exceptionVec_22,
  input           io_enq_2_req_bits_uop_exceptionVec_23,
  input           io_enq_2_req_bits_uop_isFetchMalAddr,
  input           io_enq_2_req_bits_uop_hasException,
  input  [3:0]    io_enq_2_req_bits_uop_trigger,
  input           io_enq_2_req_bits_uop_preDecodeInfo_valid,
  input           io_enq_2_req_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]    io_enq_2_req_bits_uop_preDecodeInfo_brType,
  input           io_enq_2_req_bits_uop_preDecodeInfo_isCall,
  input           io_enq_2_req_bits_uop_preDecodeInfo_isRet,
  input           io_enq_2_req_bits_uop_pred_taken,
  input           io_enq_2_req_bits_uop_crossPageIPFFix,
  input           io_enq_2_req_bits_uop_ftqPtr_flag,
  input  [5:0]    io_enq_2_req_bits_uop_ftqPtr_value,
  input  [3:0]    io_enq_2_req_bits_uop_ftqOffset,
  input           io_enq_2_req_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]    io_enq_2_req_bits_uop_srcType_0,
  input  [3:0]    io_enq_2_req_bits_uop_srcType_1,
  input  [3:0]    io_enq_2_req_bits_uop_srcType_2,
  input  [3:0]    io_enq_2_req_bits_uop_srcType_3,
  input  [3:0]    io_enq_2_req_bits_uop_srcType_4,
  input  [5:0]    io_enq_2_req_bits_uop_ldest,
  input  [34:0]   io_enq_2_req_bits_uop_fuType,
  input  [8:0]    io_enq_2_req_bits_uop_fuOpType,
  input           io_enq_2_req_bits_uop_rfWen,
  input           io_enq_2_req_bits_uop_fpWen,
  input           io_enq_2_req_bits_uop_vecWen,
  input           io_enq_2_req_bits_uop_v0Wen,
  input           io_enq_2_req_bits_uop_vlWen,
  input           io_enq_2_req_bits_uop_isXSTrap,
  input           io_enq_2_req_bits_uop_waitForward,
  input           io_enq_2_req_bits_uop_blockBackward,
  input           io_enq_2_req_bits_uop_canRobCompress,
  input  [3:0]    io_enq_2_req_bits_uop_selImm,
  input  [31:0]   io_enq_2_req_bits_uop_imm,
  input  [1:0]    io_enq_2_req_bits_uop_fpu_typeTagOut,
  input           io_enq_2_req_bits_uop_fpu_wflags,
  input  [1:0]    io_enq_2_req_bits_uop_fpu_typ,
  input  [1:0]    io_enq_2_req_bits_uop_fpu_fmt,
  input  [2:0]    io_enq_2_req_bits_uop_fpu_rm,
  input           io_enq_2_req_bits_uop_vpu_vill,
  input           io_enq_2_req_bits_uop_vpu_vma,
  input           io_enq_2_req_bits_uop_vpu_vta,
  input  [1:0]    io_enq_2_req_bits_uop_vpu_vsew,
  input  [2:0]    io_enq_2_req_bits_uop_vpu_vlmul,
  input           io_enq_2_req_bits_uop_vpu_specVill,
  input           io_enq_2_req_bits_uop_vpu_specVma,
  input           io_enq_2_req_bits_uop_vpu_specVta,
  input  [1:0]    io_enq_2_req_bits_uop_vpu_specVsew,
  input  [2:0]    io_enq_2_req_bits_uop_vpu_specVlmul,
  input           io_enq_2_req_bits_uop_vpu_vm,
  input  [7:0]    io_enq_2_req_bits_uop_vpu_vstart,
  input  [2:0]    io_enq_2_req_bits_uop_vpu_frm,
  input           io_enq_2_req_bits_uop_vpu_fpu_isFpToVecInst,
  input           io_enq_2_req_bits_uop_vpu_fpu_isFP32Instr,
  input           io_enq_2_req_bits_uop_vpu_fpu_isFP64Instr,
  input           io_enq_2_req_bits_uop_vpu_fpu_isReduction,
  input           io_enq_2_req_bits_uop_vpu_fpu_isFoldTo1_2,
  input           io_enq_2_req_bits_uop_vpu_fpu_isFoldTo1_4,
  input           io_enq_2_req_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]    io_enq_2_req_bits_uop_vpu_vxrm,
  input  [6:0]    io_enq_2_req_bits_uop_vpu_vuopIdx,
  input           io_enq_2_req_bits_uop_vpu_lastUop,
  input  [127:0]  io_enq_2_req_bits_uop_vpu_vmask,
  input  [7:0]    io_enq_2_req_bits_uop_vpu_vl,
  input  [2:0]    io_enq_2_req_bits_uop_vpu_nf,
  input  [1:0]    io_enq_2_req_bits_uop_vpu_veew,
  input           io_enq_2_req_bits_uop_vpu_isReverse,
  input           io_enq_2_req_bits_uop_vpu_isExt,
  input           io_enq_2_req_bits_uop_vpu_isNarrow,
  input           io_enq_2_req_bits_uop_vpu_isDstMask,
  input           io_enq_2_req_bits_uop_vpu_isOpMask,
  input           io_enq_2_req_bits_uop_vpu_isMove,
  input           io_enq_2_req_bits_uop_vpu_isDependOldVd,
  input           io_enq_2_req_bits_uop_vpu_isWritePartVd,
  input           io_enq_2_req_bits_uop_vpu_isVleff,
  input           io_enq_2_req_bits_uop_vlsInstr,
  input           io_enq_2_req_bits_uop_wfflags,
  input           io_enq_2_req_bits_uop_isMove,
  input           io_enq_2_req_bits_uop_isDropAmocasSta,
  input  [6:0]    io_enq_2_req_bits_uop_uopIdx,
  input           io_enq_2_req_bits_uop_isVset,
  input           io_enq_2_req_bits_uop_firstUop,
  input           io_enq_2_req_bits_uop_lastUop,
  input  [6:0]    io_enq_2_req_bits_uop_numUops,
  input  [6:0]    io_enq_2_req_bits_uop_numWB,
  input  [2:0]    io_enq_2_req_bits_uop_commitType,
  input           io_enq_2_req_bits_uop_srcState_0,
  input           io_enq_2_req_bits_uop_srcState_1,
  input           io_enq_2_req_bits_uop_srcState_2,
  input           io_enq_2_req_bits_uop_srcState_3,
  input           io_enq_2_req_bits_uop_srcState_4,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_0_0,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_0_1,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_0_2,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_1_0,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_1_1,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_1_2,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_2_0,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_2_1,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_2_2,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_3_0,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_3_1,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_3_2,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_4_0,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_4_1,
  input  [1:0]    io_enq_2_req_bits_uop_srcLoadDependency_4_2,
  input  [7:0]    io_enq_2_req_bits_uop_psrc_0,
  input  [7:0]    io_enq_2_req_bits_uop_psrc_1,
  input  [7:0]    io_enq_2_req_bits_uop_psrc_2,
  input  [7:0]    io_enq_2_req_bits_uop_psrc_3,
  input  [7:0]    io_enq_2_req_bits_uop_psrc_4,
  input  [7:0]    io_enq_2_req_bits_uop_pdest,
  input           io_enq_2_req_bits_uop_useRegCache_0,
  input           io_enq_2_req_bits_uop_useRegCache_1,
  input  [4:0]    io_enq_2_req_bits_uop_regCacheIdx_0,
  input  [4:0]    io_enq_2_req_bits_uop_regCacheIdx_1,
  input           io_enq_2_req_bits_uop_robIdx_flag,
  input  [7:0]    io_enq_2_req_bits_uop_robIdx_value,
  input  [2:0]    io_enq_2_req_bits_uop_instrSize,
  input           io_enq_2_req_bits_uop_dirtyFs,
  input           io_enq_2_req_bits_uop_dirtyVs,
  input  [3:0]    io_enq_2_req_bits_uop_traceBlockInPipe_itype,
  input  [3:0]    io_enq_2_req_bits_uop_traceBlockInPipe_iretire,
  input           io_enq_2_req_bits_uop_traceBlockInPipe_ilastsize,
  input           io_enq_2_req_bits_uop_eliminatedMove,
  input           io_enq_2_req_bits_uop_snapshot,
  input           io_enq_2_req_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_enq_2_req_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_enq_2_req_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_enq_2_req_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_enq_2_req_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_enq_2_req_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_enq_2_req_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_enq_2_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_enq_2_req_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_enq_2_req_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_enq_2_req_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_enq_2_req_bits_uop_debug_seqNum_uopIdx,
  input           io_enq_2_req_bits_uop_storeSetHit,
  input           io_enq_2_req_bits_uop_waitForRobIdx_flag,
  input  [7:0]    io_enq_2_req_bits_uop_waitForRobIdx_value,
  input           io_enq_2_req_bits_uop_loadWaitBit,
  input           io_enq_2_req_bits_uop_loadWaitStrict,
  input  [4:0]    io_enq_2_req_bits_uop_ssid,
  input           io_enq_2_req_bits_uop_lqIdx_flag,
  input  [6:0]    io_enq_2_req_bits_uop_lqIdx_value,
  input           io_enq_2_req_bits_uop_sqIdx_flag,
  input  [5:0]    io_enq_2_req_bits_uop_sqIdx_value,
  input           io_enq_2_req_bits_uop_singleStep,
  input           io_enq_2_req_bits_uop_replayInst,
  input  [34:0]   io_enq_2_req_bits_uop_debug_fuType,
  input           io_enq_2_req_bits_uop_debug_sim_trig,
  input  [4:0]    io_enq_2_req_bits_uop_numLsElem,
  input  [49:0]   io_enq_2_req_bits_vaddr,
  input  [63:0]   io_enq_2_req_bits_fullva,
  input           io_enq_2_req_bits_vaNeedExt,
  input  [47:0]   io_enq_2_req_bits_paddr,
  input  [63:0]   io_enq_2_req_bits_gpaddr,
  input  [15:0]   io_enq_2_req_bits_mask,
  input           io_enq_2_req_bits_isForVSnonLeafPTE,
  input           io_enq_2_req_bits_isvec,
  input  [7:0]    io_enq_2_req_bits_elemIdx,
  input  [2:0]    io_enq_2_req_bits_alignedType,
  input  [3:0]    io_enq_2_req_bits_mbIndex,
  input  [7:0]    io_enq_2_req_bits_elemIdxInsideVd,
  input  [15:0]   io_enq_2_req_bits_vecTriggerMask,
  input           io_splitLoadReq_ready,
  output          io_splitLoadReq_valid,
  output [31:0]   io_splitLoadReq_bits_uop_instr,
  output [49:0]   io_splitLoadReq_bits_uop_pc,
  output [9:0]    io_splitLoadReq_bits_uop_foldpc,
  output          io_splitLoadReq_bits_uop_exceptionVec_0,
  output          io_splitLoadReq_bits_uop_exceptionVec_1,
  output          io_splitLoadReq_bits_uop_exceptionVec_2,
  output          io_splitLoadReq_bits_uop_exceptionVec_3,
  output          io_splitLoadReq_bits_uop_exceptionVec_4,
  output          io_splitLoadReq_bits_uop_exceptionVec_5,
  output          io_splitLoadReq_bits_uop_exceptionVec_6,
  output          io_splitLoadReq_bits_uop_exceptionVec_7,
  output          io_splitLoadReq_bits_uop_exceptionVec_8,
  output          io_splitLoadReq_bits_uop_exceptionVec_9,
  output          io_splitLoadReq_bits_uop_exceptionVec_10,
  output          io_splitLoadReq_bits_uop_exceptionVec_11,
  output          io_splitLoadReq_bits_uop_exceptionVec_12,
  output          io_splitLoadReq_bits_uop_exceptionVec_13,
  output          io_splitLoadReq_bits_uop_exceptionVec_14,
  output          io_splitLoadReq_bits_uop_exceptionVec_15,
  output          io_splitLoadReq_bits_uop_exceptionVec_16,
  output          io_splitLoadReq_bits_uop_exceptionVec_17,
  output          io_splitLoadReq_bits_uop_exceptionVec_18,
  output          io_splitLoadReq_bits_uop_exceptionVec_19,
  output          io_splitLoadReq_bits_uop_exceptionVec_20,
  output          io_splitLoadReq_bits_uop_exceptionVec_21,
  output          io_splitLoadReq_bits_uop_exceptionVec_22,
  output          io_splitLoadReq_bits_uop_exceptionVec_23,
  output          io_splitLoadReq_bits_uop_isFetchMalAddr,
  output          io_splitLoadReq_bits_uop_hasException,
  output [3:0]    io_splitLoadReq_bits_uop_trigger,
  output          io_splitLoadReq_bits_uop_preDecodeInfo_valid,
  output          io_splitLoadReq_bits_uop_preDecodeInfo_isRVC,
  output [1:0]    io_splitLoadReq_bits_uop_preDecodeInfo_brType,
  output          io_splitLoadReq_bits_uop_preDecodeInfo_isCall,
  output          io_splitLoadReq_bits_uop_preDecodeInfo_isRet,
  output          io_splitLoadReq_bits_uop_pred_taken,
  output          io_splitLoadReq_bits_uop_crossPageIPFFix,
  output          io_splitLoadReq_bits_uop_ftqPtr_flag,
  output [5:0]    io_splitLoadReq_bits_uop_ftqPtr_value,
  output [3:0]    io_splitLoadReq_bits_uop_ftqOffset,
  output          io_splitLoadReq_bits_uop_satpFlushFirstFetchFault,
  output [3:0]    io_splitLoadReq_bits_uop_srcType_0,
  output [3:0]    io_splitLoadReq_bits_uop_srcType_1,
  output [3:0]    io_splitLoadReq_bits_uop_srcType_2,
  output [3:0]    io_splitLoadReq_bits_uop_srcType_3,
  output [3:0]    io_splitLoadReq_bits_uop_srcType_4,
  output [5:0]    io_splitLoadReq_bits_uop_ldest,
  output [34:0]   io_splitLoadReq_bits_uop_fuType,
  output [8:0]    io_splitLoadReq_bits_uop_fuOpType,
  output          io_splitLoadReq_bits_uop_rfWen,
  output          io_splitLoadReq_bits_uop_fpWen,
  output          io_splitLoadReq_bits_uop_vecWen,
  output          io_splitLoadReq_bits_uop_v0Wen,
  output          io_splitLoadReq_bits_uop_vlWen,
  output          io_splitLoadReq_bits_uop_isXSTrap,
  output          io_splitLoadReq_bits_uop_waitForward,
  output          io_splitLoadReq_bits_uop_blockBackward,
  output          io_splitLoadReq_bits_uop_flushPipe,
  output          io_splitLoadReq_bits_uop_canRobCompress,
  output [3:0]    io_splitLoadReq_bits_uop_selImm,
  output [31:0]   io_splitLoadReq_bits_uop_imm,
  output [1:0]    io_splitLoadReq_bits_uop_fpu_typeTagOut,
  output          io_splitLoadReq_bits_uop_fpu_wflags,
  output [1:0]    io_splitLoadReq_bits_uop_fpu_typ,
  output [1:0]    io_splitLoadReq_bits_uop_fpu_fmt,
  output [2:0]    io_splitLoadReq_bits_uop_fpu_rm,
  output          io_splitLoadReq_bits_uop_vpu_vill,
  output          io_splitLoadReq_bits_uop_vpu_vma,
  output          io_splitLoadReq_bits_uop_vpu_vta,
  output [1:0]    io_splitLoadReq_bits_uop_vpu_vsew,
  output [2:0]    io_splitLoadReq_bits_uop_vpu_vlmul,
  output          io_splitLoadReq_bits_uop_vpu_specVill,
  output          io_splitLoadReq_bits_uop_vpu_specVma,
  output          io_splitLoadReq_bits_uop_vpu_specVta,
  output [1:0]    io_splitLoadReq_bits_uop_vpu_specVsew,
  output [2:0]    io_splitLoadReq_bits_uop_vpu_specVlmul,
  output          io_splitLoadReq_bits_uop_vpu_vm,
  output [7:0]    io_splitLoadReq_bits_uop_vpu_vstart,
  output [2:0]    io_splitLoadReq_bits_uop_vpu_frm,
  output          io_splitLoadReq_bits_uop_vpu_fpu_isFpToVecInst,
  output          io_splitLoadReq_bits_uop_vpu_fpu_isFP32Instr,
  output          io_splitLoadReq_bits_uop_vpu_fpu_isFP64Instr,
  output          io_splitLoadReq_bits_uop_vpu_fpu_isReduction,
  output          io_splitLoadReq_bits_uop_vpu_fpu_isFoldTo1_2,
  output          io_splitLoadReq_bits_uop_vpu_fpu_isFoldTo1_4,
  output          io_splitLoadReq_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]    io_splitLoadReq_bits_uop_vpu_vxrm,
  output [6:0]    io_splitLoadReq_bits_uop_vpu_vuopIdx,
  output          io_splitLoadReq_bits_uop_vpu_lastUop,
  output [127:0]  io_splitLoadReq_bits_uop_vpu_vmask,
  output [7:0]    io_splitLoadReq_bits_uop_vpu_vl,
  output [2:0]    io_splitLoadReq_bits_uop_vpu_nf,
  output [1:0]    io_splitLoadReq_bits_uop_vpu_veew,
  output          io_splitLoadReq_bits_uop_vpu_isReverse,
  output          io_splitLoadReq_bits_uop_vpu_isExt,
  output          io_splitLoadReq_bits_uop_vpu_isNarrow,
  output          io_splitLoadReq_bits_uop_vpu_isDstMask,
  output          io_splitLoadReq_bits_uop_vpu_isOpMask,
  output          io_splitLoadReq_bits_uop_vpu_isMove,
  output          io_splitLoadReq_bits_uop_vpu_isDependOldVd,
  output          io_splitLoadReq_bits_uop_vpu_isWritePartVd,
  output          io_splitLoadReq_bits_uop_vpu_isVleff,
  output          io_splitLoadReq_bits_uop_vlsInstr,
  output          io_splitLoadReq_bits_uop_wfflags,
  output          io_splitLoadReq_bits_uop_isMove,
  output          io_splitLoadReq_bits_uop_isDropAmocasSta,
  output [6:0]    io_splitLoadReq_bits_uop_uopIdx,
  output          io_splitLoadReq_bits_uop_isVset,
  output          io_splitLoadReq_bits_uop_firstUop,
  output          io_splitLoadReq_bits_uop_lastUop,
  output [6:0]    io_splitLoadReq_bits_uop_numUops,
  output [6:0]    io_splitLoadReq_bits_uop_numWB,
  output [2:0]    io_splitLoadReq_bits_uop_commitType,
  output          io_splitLoadReq_bits_uop_srcState_0,
  output          io_splitLoadReq_bits_uop_srcState_1,
  output          io_splitLoadReq_bits_uop_srcState_2,
  output          io_splitLoadReq_bits_uop_srcState_3,
  output          io_splitLoadReq_bits_uop_srcState_4,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_0_0,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_0_1,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_0_2,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_1_0,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_1_1,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_1_2,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_2_0,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_2_1,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_2_2,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_3_0,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_3_1,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_3_2,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_4_0,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_4_1,
  output [1:0]    io_splitLoadReq_bits_uop_srcLoadDependency_4_2,
  output [7:0]    io_splitLoadReq_bits_uop_psrc_0,
  output [7:0]    io_splitLoadReq_bits_uop_psrc_1,
  output [7:0]    io_splitLoadReq_bits_uop_psrc_2,
  output [7:0]    io_splitLoadReq_bits_uop_psrc_3,
  output [7:0]    io_splitLoadReq_bits_uop_psrc_4,
  output [7:0]    io_splitLoadReq_bits_uop_pdest,
  output          io_splitLoadReq_bits_uop_useRegCache_0,
  output          io_splitLoadReq_bits_uop_useRegCache_1,
  output [4:0]    io_splitLoadReq_bits_uop_regCacheIdx_0,
  output [4:0]    io_splitLoadReq_bits_uop_regCacheIdx_1,
  output          io_splitLoadReq_bits_uop_robIdx_flag,
  output [7:0]    io_splitLoadReq_bits_uop_robIdx_value,
  output [2:0]    io_splitLoadReq_bits_uop_instrSize,
  output          io_splitLoadReq_bits_uop_dirtyFs,
  output          io_splitLoadReq_bits_uop_dirtyVs,
  output [3:0]    io_splitLoadReq_bits_uop_traceBlockInPipe_itype,
  output [3:0]    io_splitLoadReq_bits_uop_traceBlockInPipe_iretire,
  output          io_splitLoadReq_bits_uop_traceBlockInPipe_ilastsize,
  output          io_splitLoadReq_bits_uop_eliminatedMove,
  output          io_splitLoadReq_bits_uop_snapshot,
  output          io_splitLoadReq_bits_uop_debugInfo_eliminatedMove,
  output [63:0]   io_splitLoadReq_bits_uop_debugInfo_renameTime,
  output [63:0]   io_splitLoadReq_bits_uop_debugInfo_dispatchTime,
  output [63:0]   io_splitLoadReq_bits_uop_debugInfo_enqRsTime,
  output [63:0]   io_splitLoadReq_bits_uop_debugInfo_selectTime,
  output [63:0]   io_splitLoadReq_bits_uop_debugInfo_issueTime,
  output [63:0]   io_splitLoadReq_bits_uop_debugInfo_writebackTime,
  output [63:0]   io_splitLoadReq_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]   io_splitLoadReq_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]   io_splitLoadReq_bits_uop_debugInfo_tlbRespTime,
  output [55:0]   io_splitLoadReq_bits_uop_debug_seqNum_seqNum,
  output [7:0]    io_splitLoadReq_bits_uop_debug_seqNum_uopIdx,
  output          io_splitLoadReq_bits_uop_storeSetHit,
  output          io_splitLoadReq_bits_uop_waitForRobIdx_flag,
  output [7:0]    io_splitLoadReq_bits_uop_waitForRobIdx_value,
  output          io_splitLoadReq_bits_uop_loadWaitBit,
  output          io_splitLoadReq_bits_uop_loadWaitStrict,
  output [4:0]    io_splitLoadReq_bits_uop_ssid,
  output          io_splitLoadReq_bits_uop_lqIdx_flag,
  output [6:0]    io_splitLoadReq_bits_uop_lqIdx_value,
  output          io_splitLoadReq_bits_uop_sqIdx_flag,
  output [5:0]    io_splitLoadReq_bits_uop_sqIdx_value,
  output          io_splitLoadReq_bits_uop_singleStep,
  output          io_splitLoadReq_bits_uop_replayInst,
  output [34:0]   io_splitLoadReq_bits_uop_debug_fuType,
  output          io_splitLoadReq_bits_uop_debug_sim_trig,
  output [4:0]    io_splitLoadReq_bits_uop_numLsElem,
  output [49:0]   io_splitLoadReq_bits_vaddr,
  output [63:0]   io_splitLoadReq_bits_fullva,
  output          io_splitLoadReq_bits_vaNeedExt,
  output [47:0]   io_splitLoadReq_bits_paddr,
  output [63:0]   io_splitLoadReq_bits_gpaddr,
  output [15:0]   io_splitLoadReq_bits_mask,
  output          io_splitLoadReq_bits_nc,
  output          io_splitLoadReq_bits_mmio,
  output          io_splitLoadReq_bits_memBackTypeMM,
  output          io_splitLoadReq_bits_isForVSnonLeafPTE,
  output          io_splitLoadReq_bits_isvec,
  output          io_splitLoadReq_bits_is128bit,
  output          io_splitLoadReq_bits_vecActive,
  output [3:0]    io_splitLoadReq_bits_mshrid,
  output [6:0]    io_splitLoadReq_bits_schedIndex,
  output          io_splitLoadReq_bits_isFinalSplit,
  output          io_splitLoadReq_bits_misalignNeedWakeUp,
  input           io_splitLoadResp_valid,
  input           io_splitLoadResp_bits_uop_exceptionVec_3,
  input           io_splitLoadResp_bits_uop_exceptionVec_4,
  input           io_splitLoadResp_bits_uop_exceptionVec_5,
  input           io_splitLoadResp_bits_uop_exceptionVec_13,
  input           io_splitLoadResp_bits_uop_exceptionVec_19,
  input           io_splitLoadResp_bits_uop_exceptionVec_21,
  input  [3:0]    io_splitLoadResp_bits_uop_trigger,
  input           io_splitLoadResp_bits_uop_robIdx_flag,
  input  [7:0]    io_splitLoadResp_bits_uop_robIdx_value,
  input  [49:0]   io_splitLoadResp_bits_vaddr,
  input  [63:0]   io_splitLoadResp_bits_fullva,
  input           io_splitLoadResp_bits_vaNeedExt,
  input  [47:0]   io_splitLoadResp_bits_paddr,
  input  [63:0]   io_splitLoadResp_bits_gpaddr,
  input  [128:0]  io_splitLoadResp_bits_data,
  input           io_splitLoadResp_bits_nc,
  input           io_splitLoadResp_bits_mmio,
  input           io_splitLoadResp_bits_memBackTypeMM,
  input           io_splitLoadResp_bits_isForVSnonLeafPTE,
  input           io_splitLoadResp_bits_vecActive,
  input           io_splitLoadResp_bits_misalignNeedWakeUp,
  input           io_splitLoadResp_bits_rep_info_cause_0,
  input           io_splitLoadResp_bits_rep_info_cause_1,
  input           io_splitLoadResp_bits_rep_info_cause_2,
  input           io_splitLoadResp_bits_rep_info_cause_3,
  input           io_splitLoadResp_bits_rep_info_cause_4,
  input           io_splitLoadResp_bits_rep_info_cause_5,
  input           io_splitLoadResp_bits_rep_info_cause_6,
  input           io_splitLoadResp_bits_rep_info_cause_7,
  input           io_splitLoadResp_bits_rep_info_cause_8,
  input           io_splitLoadResp_bits_rep_info_cause_9,
  input           io_splitLoadResp_bits_rep_info_cause_10,
  input           io_writeBack_ready,
  output          io_writeBack_valid,
  output          io_writeBack_bits_uop_exceptionVec_3,
  output          io_writeBack_bits_uop_exceptionVec_4,
  output          io_writeBack_bits_uop_exceptionVec_5,
  output          io_writeBack_bits_uop_exceptionVec_13,
  output          io_writeBack_bits_uop_exceptionVec_19,
  output          io_writeBack_bits_uop_exceptionVec_21,
  output [3:0]    io_writeBack_bits_uop_trigger,
  output          io_writeBack_bits_uop_preDecodeInfo_valid,
  output          io_writeBack_bits_uop_preDecodeInfo_isRVC,
  output [1:0]    io_writeBack_bits_uop_preDecodeInfo_brType,
  output          io_writeBack_bits_uop_preDecodeInfo_isCall,
  output          io_writeBack_bits_uop_preDecodeInfo_isRet,
  output          io_writeBack_bits_uop_rfWen,
  output          io_writeBack_bits_uop_fpWen,
  output [7:0]    io_writeBack_bits_uop_pdest,
  output          io_writeBack_bits_uop_robIdx_flag,
  output [7:0]    io_writeBack_bits_uop_robIdx_value,
  output          io_writeBack_bits_uop_debugInfo_eliminatedMove,
  output [63:0]   io_writeBack_bits_uop_debugInfo_renameTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_dispatchTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_enqRsTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_selectTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_issueTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_writebackTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]   io_writeBack_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]   io_writeBack_bits_uop_debugInfo_tlbRespTime,
  output [55:0]   io_writeBack_bits_uop_debug_seqNum_seqNum,
  output [7:0]    io_writeBack_bits_uop_debug_seqNum_uopIdx,
  output          io_writeBack_bits_uop_lqIdx_flag,
  output [6:0]    io_writeBack_bits_uop_lqIdx_value,
  output [63:0]   io_writeBack_bits_data,
  output          io_writeBack_bits_debug_isMMIO,
  output          io_writeBack_bits_debug_isNCIO,
  output [47:0]   io_writeBack_bits_debug_paddr,
  output [49:0]   io_writeBack_bits_debug_vaddr,
  output          io_vecWriteBack_valid,
  output [3:0]    io_vecWriteBack_bits_mBIndex,
  output          io_vecWriteBack_bits_exceptionVec_3,
  output          io_vecWriteBack_bits_exceptionVec_4,
  output          io_vecWriteBack_bits_exceptionVec_5,
  output          io_vecWriteBack_bits_exceptionVec_13,
  output          io_vecWriteBack_bits_exceptionVec_19,
  output          io_vecWriteBack_bits_exceptionVec_21,
  output          io_vecWriteBack_bits_hasException,
  output [63:0]   io_vecWriteBack_bits_vaddr,
  output          io_vecWriteBack_bits_vaNeedExt,
  output [63:0]   io_vecWriteBack_bits_gpaddr,
  output          io_vecWriteBack_bits_isForVSnonLeafPTE,
  output [7:0]    io_vecWriteBack_bits_vstart,
  output [15:0]   io_vecWriteBack_bits_vecTriggerMask,
  output [7:0]    io_vecWriteBack_bits_elemIdx,
  output [15:0]   io_vecWriteBack_bits_mask,
  output [2:0]    io_vecWriteBack_bits_alignedType,
  output [7:0]    io_vecWriteBack_bits_elemIdxInsideVd,
  output [127:0]  io_vecWriteBack_bits_vecdata,
  input           io_loadOutValid,
  input           io_loadVecOutValid
);

  // 核端的 struct / 向量信号
  redirect_t   redirect;
  enq_req_t    [NUM_ENQ-1:0] enq_bits;
  split_req_t  split_req;
  split_resp_t split_resp;
  wb_t         wb;
  vec_wb_t     vec_wb;
  logic [NUM_ENQ-1:0] enq_valid, enq_ready;

  always_comb begin
    redirect = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    redirect.robIdx_flag = io_redirect_bits_robIdx_flag;
    redirect.robIdx_value = io_redirect_bits_robIdx_value;
    redirect.level = io_redirect_bits_level;
  end
  always_comb begin
    enq_bits[0] = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    enq_bits[0].uop.instr = io_enq_0_req_bits_uop_instr;
    enq_bits[0].uop.pc = io_enq_0_req_bits_uop_pc;
    enq_bits[0].uop.foldpc = io_enq_0_req_bits_uop_foldpc;
    enq_bits[0].uop.exceptionVec[0] = io_enq_0_req_bits_uop_exceptionVec_0;
    enq_bits[0].uop.exceptionVec[1] = io_enq_0_req_bits_uop_exceptionVec_1;
    enq_bits[0].uop.exceptionVec[2] = io_enq_0_req_bits_uop_exceptionVec_2;
    enq_bits[0].uop.exceptionVec[3] = io_enq_0_req_bits_uop_exceptionVec_3;
    enq_bits[0].uop.exceptionVec[5] = io_enq_0_req_bits_uop_exceptionVec_5;
    enq_bits[0].uop.exceptionVec[6] = io_enq_0_req_bits_uop_exceptionVec_6;
    enq_bits[0].uop.exceptionVec[7] = io_enq_0_req_bits_uop_exceptionVec_7;
    enq_bits[0].uop.exceptionVec[8] = io_enq_0_req_bits_uop_exceptionVec_8;
    enq_bits[0].uop.exceptionVec[9] = io_enq_0_req_bits_uop_exceptionVec_9;
    enq_bits[0].uop.exceptionVec[10] = io_enq_0_req_bits_uop_exceptionVec_10;
    enq_bits[0].uop.exceptionVec[11] = io_enq_0_req_bits_uop_exceptionVec_11;
    enq_bits[0].uop.exceptionVec[12] = io_enq_0_req_bits_uop_exceptionVec_12;
    enq_bits[0].uop.exceptionVec[13] = io_enq_0_req_bits_uop_exceptionVec_13;
    enq_bits[0].uop.exceptionVec[14] = io_enq_0_req_bits_uop_exceptionVec_14;
    enq_bits[0].uop.exceptionVec[15] = io_enq_0_req_bits_uop_exceptionVec_15;
    enq_bits[0].uop.exceptionVec[16] = io_enq_0_req_bits_uop_exceptionVec_16;
    enq_bits[0].uop.exceptionVec[17] = io_enq_0_req_bits_uop_exceptionVec_17;
    enq_bits[0].uop.exceptionVec[18] = io_enq_0_req_bits_uop_exceptionVec_18;
    enq_bits[0].uop.exceptionVec[19] = io_enq_0_req_bits_uop_exceptionVec_19;
    enq_bits[0].uop.exceptionVec[20] = io_enq_0_req_bits_uop_exceptionVec_20;
    enq_bits[0].uop.exceptionVec[21] = io_enq_0_req_bits_uop_exceptionVec_21;
    enq_bits[0].uop.exceptionVec[22] = io_enq_0_req_bits_uop_exceptionVec_22;
    enq_bits[0].uop.exceptionVec[23] = io_enq_0_req_bits_uop_exceptionVec_23;
    enq_bits[0].uop.isFetchMalAddr = io_enq_0_req_bits_uop_isFetchMalAddr;
    enq_bits[0].uop.hasException = io_enq_0_req_bits_uop_hasException;
    enq_bits[0].uop.trigger = io_enq_0_req_bits_uop_trigger;
    enq_bits[0].uop.preDecodeInfo_valid = io_enq_0_req_bits_uop_preDecodeInfo_valid;
    enq_bits[0].uop.preDecodeInfo_isRVC = io_enq_0_req_bits_uop_preDecodeInfo_isRVC;
    enq_bits[0].uop.preDecodeInfo_brType = io_enq_0_req_bits_uop_preDecodeInfo_brType;
    enq_bits[0].uop.preDecodeInfo_isCall = io_enq_0_req_bits_uop_preDecodeInfo_isCall;
    enq_bits[0].uop.preDecodeInfo_isRet = io_enq_0_req_bits_uop_preDecodeInfo_isRet;
    enq_bits[0].uop.pred_taken = io_enq_0_req_bits_uop_pred_taken;
    enq_bits[0].uop.crossPageIPFFix = io_enq_0_req_bits_uop_crossPageIPFFix;
    enq_bits[0].uop.ftqPtr_flag = io_enq_0_req_bits_uop_ftqPtr_flag;
    enq_bits[0].uop.ftqPtr_value = io_enq_0_req_bits_uop_ftqPtr_value;
    enq_bits[0].uop.ftqOffset = io_enq_0_req_bits_uop_ftqOffset;
    enq_bits[0].uop.satpFlushFirstFetchFault = io_enq_0_req_bits_uop_satpFlushFirstFetchFault;
    enq_bits[0].uop.srcType_0 = io_enq_0_req_bits_uop_srcType_0;
    enq_bits[0].uop.srcType_1 = io_enq_0_req_bits_uop_srcType_1;
    enq_bits[0].uop.srcType_2 = io_enq_0_req_bits_uop_srcType_2;
    enq_bits[0].uop.srcType_3 = io_enq_0_req_bits_uop_srcType_3;
    enq_bits[0].uop.srcType_4 = io_enq_0_req_bits_uop_srcType_4;
    enq_bits[0].uop.ldest = io_enq_0_req_bits_uop_ldest;
    enq_bits[0].uop.fuType = io_enq_0_req_bits_uop_fuType;
    enq_bits[0].uop.fuOpType = io_enq_0_req_bits_uop_fuOpType;
    enq_bits[0].uop.rfWen = io_enq_0_req_bits_uop_rfWen;
    enq_bits[0].uop.fpWen = io_enq_0_req_bits_uop_fpWen;
    enq_bits[0].uop.vecWen = io_enq_0_req_bits_uop_vecWen;
    enq_bits[0].uop.v0Wen = io_enq_0_req_bits_uop_v0Wen;
    enq_bits[0].uop.vlWen = io_enq_0_req_bits_uop_vlWen;
    enq_bits[0].uop.isXSTrap = io_enq_0_req_bits_uop_isXSTrap;
    enq_bits[0].uop.waitForward = io_enq_0_req_bits_uop_waitForward;
    enq_bits[0].uop.blockBackward = io_enq_0_req_bits_uop_blockBackward;
    enq_bits[0].uop.canRobCompress = io_enq_0_req_bits_uop_canRobCompress;
    enq_bits[0].uop.selImm = io_enq_0_req_bits_uop_selImm;
    enq_bits[0].uop.imm = io_enq_0_req_bits_uop_imm;
    enq_bits[0].uop.fpu_typeTagOut = io_enq_0_req_bits_uop_fpu_typeTagOut;
    enq_bits[0].uop.fpu_wflags = io_enq_0_req_bits_uop_fpu_wflags;
    enq_bits[0].uop.fpu_typ = io_enq_0_req_bits_uop_fpu_typ;
    enq_bits[0].uop.fpu_fmt = io_enq_0_req_bits_uop_fpu_fmt;
    enq_bits[0].uop.fpu_rm = io_enq_0_req_bits_uop_fpu_rm;
    enq_bits[0].uop.vpu_vill = io_enq_0_req_bits_uop_vpu_vill;
    enq_bits[0].uop.vpu_vma = io_enq_0_req_bits_uop_vpu_vma;
    enq_bits[0].uop.vpu_vta = io_enq_0_req_bits_uop_vpu_vta;
    enq_bits[0].uop.vpu_vsew = io_enq_0_req_bits_uop_vpu_vsew;
    enq_bits[0].uop.vpu_vlmul = io_enq_0_req_bits_uop_vpu_vlmul;
    enq_bits[0].uop.vpu_specVill = io_enq_0_req_bits_uop_vpu_specVill;
    enq_bits[0].uop.vpu_specVma = io_enq_0_req_bits_uop_vpu_specVma;
    enq_bits[0].uop.vpu_specVta = io_enq_0_req_bits_uop_vpu_specVta;
    enq_bits[0].uop.vpu_specVsew = io_enq_0_req_bits_uop_vpu_specVsew;
    enq_bits[0].uop.vpu_specVlmul = io_enq_0_req_bits_uop_vpu_specVlmul;
    enq_bits[0].uop.vpu_vm = io_enq_0_req_bits_uop_vpu_vm;
    enq_bits[0].uop.vpu_vstart = io_enq_0_req_bits_uop_vpu_vstart;
    enq_bits[0].uop.vpu_frm = io_enq_0_req_bits_uop_vpu_frm;
    enq_bits[0].uop.vpu_fpu_isFpToVecInst = io_enq_0_req_bits_uop_vpu_fpu_isFpToVecInst;
    enq_bits[0].uop.vpu_fpu_isFP32Instr = io_enq_0_req_bits_uop_vpu_fpu_isFP32Instr;
    enq_bits[0].uop.vpu_fpu_isFP64Instr = io_enq_0_req_bits_uop_vpu_fpu_isFP64Instr;
    enq_bits[0].uop.vpu_fpu_isReduction = io_enq_0_req_bits_uop_vpu_fpu_isReduction;
    enq_bits[0].uop.vpu_fpu_isFoldTo1_2 = io_enq_0_req_bits_uop_vpu_fpu_isFoldTo1_2;
    enq_bits[0].uop.vpu_fpu_isFoldTo1_4 = io_enq_0_req_bits_uop_vpu_fpu_isFoldTo1_4;
    enq_bits[0].uop.vpu_fpu_isFoldTo1_8 = io_enq_0_req_bits_uop_vpu_fpu_isFoldTo1_8;
    enq_bits[0].uop.vpu_vxrm = io_enq_0_req_bits_uop_vpu_vxrm;
    enq_bits[0].uop.vpu_vuopIdx = io_enq_0_req_bits_uop_vpu_vuopIdx;
    enq_bits[0].uop.vpu_lastUop = io_enq_0_req_bits_uop_vpu_lastUop;
    enq_bits[0].uop.vpu_vmask = io_enq_0_req_bits_uop_vpu_vmask;
    enq_bits[0].uop.vpu_vl = io_enq_0_req_bits_uop_vpu_vl;
    enq_bits[0].uop.vpu_nf = io_enq_0_req_bits_uop_vpu_nf;
    enq_bits[0].uop.vpu_veew = io_enq_0_req_bits_uop_vpu_veew;
    enq_bits[0].uop.vpu_isReverse = io_enq_0_req_bits_uop_vpu_isReverse;
    enq_bits[0].uop.vpu_isExt = io_enq_0_req_bits_uop_vpu_isExt;
    enq_bits[0].uop.vpu_isNarrow = io_enq_0_req_bits_uop_vpu_isNarrow;
    enq_bits[0].uop.vpu_isDstMask = io_enq_0_req_bits_uop_vpu_isDstMask;
    enq_bits[0].uop.vpu_isOpMask = io_enq_0_req_bits_uop_vpu_isOpMask;
    enq_bits[0].uop.vpu_isMove = io_enq_0_req_bits_uop_vpu_isMove;
    enq_bits[0].uop.vpu_isDependOldVd = io_enq_0_req_bits_uop_vpu_isDependOldVd;
    enq_bits[0].uop.vpu_isWritePartVd = io_enq_0_req_bits_uop_vpu_isWritePartVd;
    enq_bits[0].uop.vpu_isVleff = io_enq_0_req_bits_uop_vpu_isVleff;
    enq_bits[0].uop.vlsInstr = io_enq_0_req_bits_uop_vlsInstr;
    enq_bits[0].uop.wfflags = io_enq_0_req_bits_uop_wfflags;
    enq_bits[0].uop.isMove = io_enq_0_req_bits_uop_isMove;
    enq_bits[0].uop.isDropAmocasSta = io_enq_0_req_bits_uop_isDropAmocasSta;
    enq_bits[0].uop.uopIdx = io_enq_0_req_bits_uop_uopIdx;
    enq_bits[0].uop.isVset = io_enq_0_req_bits_uop_isVset;
    enq_bits[0].uop.firstUop = io_enq_0_req_bits_uop_firstUop;
    enq_bits[0].uop.lastUop = io_enq_0_req_bits_uop_lastUop;
    enq_bits[0].uop.numUops = io_enq_0_req_bits_uop_numUops;
    enq_bits[0].uop.numWB = io_enq_0_req_bits_uop_numWB;
    enq_bits[0].uop.commitType = io_enq_0_req_bits_uop_commitType;
    enq_bits[0].uop.srcState_0 = io_enq_0_req_bits_uop_srcState_0;
    enq_bits[0].uop.srcState_1 = io_enq_0_req_bits_uop_srcState_1;
    enq_bits[0].uop.srcState_2 = io_enq_0_req_bits_uop_srcState_2;
    enq_bits[0].uop.srcState_3 = io_enq_0_req_bits_uop_srcState_3;
    enq_bits[0].uop.srcState_4 = io_enq_0_req_bits_uop_srcState_4;
    enq_bits[0].uop.srcLoadDependency_0_0 = io_enq_0_req_bits_uop_srcLoadDependency_0_0;
    enq_bits[0].uop.srcLoadDependency_0_1 = io_enq_0_req_bits_uop_srcLoadDependency_0_1;
    enq_bits[0].uop.srcLoadDependency_0_2 = io_enq_0_req_bits_uop_srcLoadDependency_0_2;
    enq_bits[0].uop.srcLoadDependency_1_0 = io_enq_0_req_bits_uop_srcLoadDependency_1_0;
    enq_bits[0].uop.srcLoadDependency_1_1 = io_enq_0_req_bits_uop_srcLoadDependency_1_1;
    enq_bits[0].uop.srcLoadDependency_1_2 = io_enq_0_req_bits_uop_srcLoadDependency_1_2;
    enq_bits[0].uop.srcLoadDependency_2_0 = io_enq_0_req_bits_uop_srcLoadDependency_2_0;
    enq_bits[0].uop.srcLoadDependency_2_1 = io_enq_0_req_bits_uop_srcLoadDependency_2_1;
    enq_bits[0].uop.srcLoadDependency_2_2 = io_enq_0_req_bits_uop_srcLoadDependency_2_2;
    enq_bits[0].uop.srcLoadDependency_3_0 = io_enq_0_req_bits_uop_srcLoadDependency_3_0;
    enq_bits[0].uop.srcLoadDependency_3_1 = io_enq_0_req_bits_uop_srcLoadDependency_3_1;
    enq_bits[0].uop.srcLoadDependency_3_2 = io_enq_0_req_bits_uop_srcLoadDependency_3_2;
    enq_bits[0].uop.srcLoadDependency_4_0 = io_enq_0_req_bits_uop_srcLoadDependency_4_0;
    enq_bits[0].uop.srcLoadDependency_4_1 = io_enq_0_req_bits_uop_srcLoadDependency_4_1;
    enq_bits[0].uop.srcLoadDependency_4_2 = io_enq_0_req_bits_uop_srcLoadDependency_4_2;
    enq_bits[0].uop.psrc_0 = io_enq_0_req_bits_uop_psrc_0;
    enq_bits[0].uop.psrc_1 = io_enq_0_req_bits_uop_psrc_1;
    enq_bits[0].uop.psrc_2 = io_enq_0_req_bits_uop_psrc_2;
    enq_bits[0].uop.psrc_3 = io_enq_0_req_bits_uop_psrc_3;
    enq_bits[0].uop.psrc_4 = io_enq_0_req_bits_uop_psrc_4;
    enq_bits[0].uop.pdest = io_enq_0_req_bits_uop_pdest;
    enq_bits[0].uop.useRegCache_0 = io_enq_0_req_bits_uop_useRegCache_0;
    enq_bits[0].uop.useRegCache_1 = io_enq_0_req_bits_uop_useRegCache_1;
    enq_bits[0].uop.regCacheIdx_0 = io_enq_0_req_bits_uop_regCacheIdx_0;
    enq_bits[0].uop.regCacheIdx_1 = io_enq_0_req_bits_uop_regCacheIdx_1;
    enq_bits[0].uop.robIdx_flag = io_enq_0_req_bits_uop_robIdx_flag;
    enq_bits[0].uop.robIdx_value = io_enq_0_req_bits_uop_robIdx_value;
    enq_bits[0].uop.instrSize = io_enq_0_req_bits_uop_instrSize;
    enq_bits[0].uop.dirtyFs = io_enq_0_req_bits_uop_dirtyFs;
    enq_bits[0].uop.dirtyVs = io_enq_0_req_bits_uop_dirtyVs;
    enq_bits[0].uop.traceBlockInPipe_itype = io_enq_0_req_bits_uop_traceBlockInPipe_itype;
    enq_bits[0].uop.traceBlockInPipe_iretire = io_enq_0_req_bits_uop_traceBlockInPipe_iretire;
    enq_bits[0].uop.traceBlockInPipe_ilastsize = io_enq_0_req_bits_uop_traceBlockInPipe_ilastsize;
    enq_bits[0].uop.eliminatedMove = io_enq_0_req_bits_uop_eliminatedMove;
    enq_bits[0].uop.snapshot = io_enq_0_req_bits_uop_snapshot;
    enq_bits[0].uop.debugInfo_eliminatedMove = io_enq_0_req_bits_uop_debugInfo_eliminatedMove;
    enq_bits[0].uop.debugInfo_renameTime = io_enq_0_req_bits_uop_debugInfo_renameTime;
    enq_bits[0].uop.debugInfo_dispatchTime = io_enq_0_req_bits_uop_debugInfo_dispatchTime;
    enq_bits[0].uop.debugInfo_enqRsTime = io_enq_0_req_bits_uop_debugInfo_enqRsTime;
    enq_bits[0].uop.debugInfo_selectTime = io_enq_0_req_bits_uop_debugInfo_selectTime;
    enq_bits[0].uop.debugInfo_issueTime = io_enq_0_req_bits_uop_debugInfo_issueTime;
    enq_bits[0].uop.debugInfo_writebackTime = io_enq_0_req_bits_uop_debugInfo_writebackTime;
    enq_bits[0].uop.debugInfo_runahead_checkpoint_id = io_enq_0_req_bits_uop_debugInfo_runahead_checkpoint_id;
    enq_bits[0].uop.debugInfo_tlbFirstReqTime = io_enq_0_req_bits_uop_debugInfo_tlbFirstReqTime;
    enq_bits[0].uop.debugInfo_tlbRespTime = io_enq_0_req_bits_uop_debugInfo_tlbRespTime;
    enq_bits[0].uop.debug_seqNum_seqNum = io_enq_0_req_bits_uop_debug_seqNum_seqNum;
    enq_bits[0].uop.debug_seqNum_uopIdx = io_enq_0_req_bits_uop_debug_seqNum_uopIdx;
    enq_bits[0].uop.storeSetHit = io_enq_0_req_bits_uop_storeSetHit;
    enq_bits[0].uop.waitForRobIdx_flag = io_enq_0_req_bits_uop_waitForRobIdx_flag;
    enq_bits[0].uop.waitForRobIdx_value = io_enq_0_req_bits_uop_waitForRobIdx_value;
    enq_bits[0].uop.loadWaitBit = io_enq_0_req_bits_uop_loadWaitBit;
    enq_bits[0].uop.loadWaitStrict = io_enq_0_req_bits_uop_loadWaitStrict;
    enq_bits[0].uop.ssid = io_enq_0_req_bits_uop_ssid;
    enq_bits[0].uop.lqIdx_flag = io_enq_0_req_bits_uop_lqIdx_flag;
    enq_bits[0].uop.lqIdx_value = io_enq_0_req_bits_uop_lqIdx_value;
    enq_bits[0].uop.sqIdx_flag = io_enq_0_req_bits_uop_sqIdx_flag;
    enq_bits[0].uop.sqIdx_value = io_enq_0_req_bits_uop_sqIdx_value;
    enq_bits[0].uop.singleStep = io_enq_0_req_bits_uop_singleStep;
    enq_bits[0].uop.replayInst = io_enq_0_req_bits_uop_replayInst;
    enq_bits[0].uop.debug_fuType = io_enq_0_req_bits_uop_debug_fuType;
    enq_bits[0].uop.debug_sim_trig = io_enq_0_req_bits_uop_debug_sim_trig;
    enq_bits[0].uop.numLsElem = io_enq_0_req_bits_uop_numLsElem;
    enq_bits[0].vaddr = io_enq_0_req_bits_vaddr;
    enq_bits[0].fullva = io_enq_0_req_bits_fullva;
    enq_bits[0].vaNeedExt = io_enq_0_req_bits_vaNeedExt;
    enq_bits[0].paddr = io_enq_0_req_bits_paddr;
    enq_bits[0].gpaddr = io_enq_0_req_bits_gpaddr;
    enq_bits[0].mask = io_enq_0_req_bits_mask;
    enq_bits[0].isForVSnonLeafPTE = io_enq_0_req_bits_isForVSnonLeafPTE;
    enq_bits[0].isvec = io_enq_0_req_bits_isvec;
    enq_bits[0].elemIdx = io_enq_0_req_bits_elemIdx;
    enq_bits[0].alignedType = io_enq_0_req_bits_alignedType;
    enq_bits[0].mbIndex = io_enq_0_req_bits_mbIndex;
    enq_bits[0].elemIdxInsideVd = io_enq_0_req_bits_elemIdxInsideVd;
    enq_bits[0].vecTriggerMask = io_enq_0_req_bits_vecTriggerMask;
  end
  always_comb begin
    enq_bits[1] = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    enq_bits[1].uop.instr = io_enq_1_req_bits_uop_instr;
    enq_bits[1].uop.pc = io_enq_1_req_bits_uop_pc;
    enq_bits[1].uop.foldpc = io_enq_1_req_bits_uop_foldpc;
    enq_bits[1].uop.exceptionVec[0] = io_enq_1_req_bits_uop_exceptionVec_0;
    enq_bits[1].uop.exceptionVec[1] = io_enq_1_req_bits_uop_exceptionVec_1;
    enq_bits[1].uop.exceptionVec[2] = io_enq_1_req_bits_uop_exceptionVec_2;
    enq_bits[1].uop.exceptionVec[3] = io_enq_1_req_bits_uop_exceptionVec_3;
    enq_bits[1].uop.exceptionVec[5] = io_enq_1_req_bits_uop_exceptionVec_5;
    enq_bits[1].uop.exceptionVec[6] = io_enq_1_req_bits_uop_exceptionVec_6;
    enq_bits[1].uop.exceptionVec[7] = io_enq_1_req_bits_uop_exceptionVec_7;
    enq_bits[1].uop.exceptionVec[8] = io_enq_1_req_bits_uop_exceptionVec_8;
    enq_bits[1].uop.exceptionVec[9] = io_enq_1_req_bits_uop_exceptionVec_9;
    enq_bits[1].uop.exceptionVec[10] = io_enq_1_req_bits_uop_exceptionVec_10;
    enq_bits[1].uop.exceptionVec[11] = io_enq_1_req_bits_uop_exceptionVec_11;
    enq_bits[1].uop.exceptionVec[12] = io_enq_1_req_bits_uop_exceptionVec_12;
    enq_bits[1].uop.exceptionVec[13] = io_enq_1_req_bits_uop_exceptionVec_13;
    enq_bits[1].uop.exceptionVec[14] = io_enq_1_req_bits_uop_exceptionVec_14;
    enq_bits[1].uop.exceptionVec[15] = io_enq_1_req_bits_uop_exceptionVec_15;
    enq_bits[1].uop.exceptionVec[16] = io_enq_1_req_bits_uop_exceptionVec_16;
    enq_bits[1].uop.exceptionVec[17] = io_enq_1_req_bits_uop_exceptionVec_17;
    enq_bits[1].uop.exceptionVec[18] = io_enq_1_req_bits_uop_exceptionVec_18;
    enq_bits[1].uop.exceptionVec[19] = io_enq_1_req_bits_uop_exceptionVec_19;
    enq_bits[1].uop.exceptionVec[20] = io_enq_1_req_bits_uop_exceptionVec_20;
    enq_bits[1].uop.exceptionVec[21] = io_enq_1_req_bits_uop_exceptionVec_21;
    enq_bits[1].uop.exceptionVec[22] = io_enq_1_req_bits_uop_exceptionVec_22;
    enq_bits[1].uop.exceptionVec[23] = io_enq_1_req_bits_uop_exceptionVec_23;
    enq_bits[1].uop.isFetchMalAddr = io_enq_1_req_bits_uop_isFetchMalAddr;
    enq_bits[1].uop.hasException = io_enq_1_req_bits_uop_hasException;
    enq_bits[1].uop.trigger = io_enq_1_req_bits_uop_trigger;
    enq_bits[1].uop.preDecodeInfo_valid = io_enq_1_req_bits_uop_preDecodeInfo_valid;
    enq_bits[1].uop.preDecodeInfo_isRVC = io_enq_1_req_bits_uop_preDecodeInfo_isRVC;
    enq_bits[1].uop.preDecodeInfo_brType = io_enq_1_req_bits_uop_preDecodeInfo_brType;
    enq_bits[1].uop.preDecodeInfo_isCall = io_enq_1_req_bits_uop_preDecodeInfo_isCall;
    enq_bits[1].uop.preDecodeInfo_isRet = io_enq_1_req_bits_uop_preDecodeInfo_isRet;
    enq_bits[1].uop.pred_taken = io_enq_1_req_bits_uop_pred_taken;
    enq_bits[1].uop.crossPageIPFFix = io_enq_1_req_bits_uop_crossPageIPFFix;
    enq_bits[1].uop.ftqPtr_flag = io_enq_1_req_bits_uop_ftqPtr_flag;
    enq_bits[1].uop.ftqPtr_value = io_enq_1_req_bits_uop_ftqPtr_value;
    enq_bits[1].uop.ftqOffset = io_enq_1_req_bits_uop_ftqOffset;
    enq_bits[1].uop.satpFlushFirstFetchFault = io_enq_1_req_bits_uop_satpFlushFirstFetchFault;
    enq_bits[1].uop.srcType_0 = io_enq_1_req_bits_uop_srcType_0;
    enq_bits[1].uop.srcType_1 = io_enq_1_req_bits_uop_srcType_1;
    enq_bits[1].uop.srcType_2 = io_enq_1_req_bits_uop_srcType_2;
    enq_bits[1].uop.srcType_3 = io_enq_1_req_bits_uop_srcType_3;
    enq_bits[1].uop.srcType_4 = io_enq_1_req_bits_uop_srcType_4;
    enq_bits[1].uop.ldest = io_enq_1_req_bits_uop_ldest;
    enq_bits[1].uop.fuType = io_enq_1_req_bits_uop_fuType;
    enq_bits[1].uop.fuOpType = io_enq_1_req_bits_uop_fuOpType;
    enq_bits[1].uop.rfWen = io_enq_1_req_bits_uop_rfWen;
    enq_bits[1].uop.fpWen = io_enq_1_req_bits_uop_fpWen;
    enq_bits[1].uop.vecWen = io_enq_1_req_bits_uop_vecWen;
    enq_bits[1].uop.v0Wen = io_enq_1_req_bits_uop_v0Wen;
    enq_bits[1].uop.vlWen = io_enq_1_req_bits_uop_vlWen;
    enq_bits[1].uop.isXSTrap = io_enq_1_req_bits_uop_isXSTrap;
    enq_bits[1].uop.waitForward = io_enq_1_req_bits_uop_waitForward;
    enq_bits[1].uop.blockBackward = io_enq_1_req_bits_uop_blockBackward;
    enq_bits[1].uop.canRobCompress = io_enq_1_req_bits_uop_canRobCompress;
    enq_bits[1].uop.selImm = io_enq_1_req_bits_uop_selImm;
    enq_bits[1].uop.imm = io_enq_1_req_bits_uop_imm;
    enq_bits[1].uop.fpu_typeTagOut = io_enq_1_req_bits_uop_fpu_typeTagOut;
    enq_bits[1].uop.fpu_wflags = io_enq_1_req_bits_uop_fpu_wflags;
    enq_bits[1].uop.fpu_typ = io_enq_1_req_bits_uop_fpu_typ;
    enq_bits[1].uop.fpu_fmt = io_enq_1_req_bits_uop_fpu_fmt;
    enq_bits[1].uop.fpu_rm = io_enq_1_req_bits_uop_fpu_rm;
    enq_bits[1].uop.vpu_vill = io_enq_1_req_bits_uop_vpu_vill;
    enq_bits[1].uop.vpu_vma = io_enq_1_req_bits_uop_vpu_vma;
    enq_bits[1].uop.vpu_vta = io_enq_1_req_bits_uop_vpu_vta;
    enq_bits[1].uop.vpu_vsew = io_enq_1_req_bits_uop_vpu_vsew;
    enq_bits[1].uop.vpu_vlmul = io_enq_1_req_bits_uop_vpu_vlmul;
    enq_bits[1].uop.vpu_specVill = io_enq_1_req_bits_uop_vpu_specVill;
    enq_bits[1].uop.vpu_specVma = io_enq_1_req_bits_uop_vpu_specVma;
    enq_bits[1].uop.vpu_specVta = io_enq_1_req_bits_uop_vpu_specVta;
    enq_bits[1].uop.vpu_specVsew = io_enq_1_req_bits_uop_vpu_specVsew;
    enq_bits[1].uop.vpu_specVlmul = io_enq_1_req_bits_uop_vpu_specVlmul;
    enq_bits[1].uop.vpu_vm = io_enq_1_req_bits_uop_vpu_vm;
    enq_bits[1].uop.vpu_vstart = io_enq_1_req_bits_uop_vpu_vstart;
    enq_bits[1].uop.vpu_frm = io_enq_1_req_bits_uop_vpu_frm;
    enq_bits[1].uop.vpu_fpu_isFpToVecInst = io_enq_1_req_bits_uop_vpu_fpu_isFpToVecInst;
    enq_bits[1].uop.vpu_fpu_isFP32Instr = io_enq_1_req_bits_uop_vpu_fpu_isFP32Instr;
    enq_bits[1].uop.vpu_fpu_isFP64Instr = io_enq_1_req_bits_uop_vpu_fpu_isFP64Instr;
    enq_bits[1].uop.vpu_fpu_isReduction = io_enq_1_req_bits_uop_vpu_fpu_isReduction;
    enq_bits[1].uop.vpu_fpu_isFoldTo1_2 = io_enq_1_req_bits_uop_vpu_fpu_isFoldTo1_2;
    enq_bits[1].uop.vpu_fpu_isFoldTo1_4 = io_enq_1_req_bits_uop_vpu_fpu_isFoldTo1_4;
    enq_bits[1].uop.vpu_fpu_isFoldTo1_8 = io_enq_1_req_bits_uop_vpu_fpu_isFoldTo1_8;
    enq_bits[1].uop.vpu_vxrm = io_enq_1_req_bits_uop_vpu_vxrm;
    enq_bits[1].uop.vpu_vuopIdx = io_enq_1_req_bits_uop_vpu_vuopIdx;
    enq_bits[1].uop.vpu_lastUop = io_enq_1_req_bits_uop_vpu_lastUop;
    enq_bits[1].uop.vpu_vmask = io_enq_1_req_bits_uop_vpu_vmask;
    enq_bits[1].uop.vpu_vl = io_enq_1_req_bits_uop_vpu_vl;
    enq_bits[1].uop.vpu_nf = io_enq_1_req_bits_uop_vpu_nf;
    enq_bits[1].uop.vpu_veew = io_enq_1_req_bits_uop_vpu_veew;
    enq_bits[1].uop.vpu_isReverse = io_enq_1_req_bits_uop_vpu_isReverse;
    enq_bits[1].uop.vpu_isExt = io_enq_1_req_bits_uop_vpu_isExt;
    enq_bits[1].uop.vpu_isNarrow = io_enq_1_req_bits_uop_vpu_isNarrow;
    enq_bits[1].uop.vpu_isDstMask = io_enq_1_req_bits_uop_vpu_isDstMask;
    enq_bits[1].uop.vpu_isOpMask = io_enq_1_req_bits_uop_vpu_isOpMask;
    enq_bits[1].uop.vpu_isMove = io_enq_1_req_bits_uop_vpu_isMove;
    enq_bits[1].uop.vpu_isDependOldVd = io_enq_1_req_bits_uop_vpu_isDependOldVd;
    enq_bits[1].uop.vpu_isWritePartVd = io_enq_1_req_bits_uop_vpu_isWritePartVd;
    enq_bits[1].uop.vpu_isVleff = io_enq_1_req_bits_uop_vpu_isVleff;
    enq_bits[1].uop.vlsInstr = io_enq_1_req_bits_uop_vlsInstr;
    enq_bits[1].uop.wfflags = io_enq_1_req_bits_uop_wfflags;
    enq_bits[1].uop.isMove = io_enq_1_req_bits_uop_isMove;
    enq_bits[1].uop.isDropAmocasSta = io_enq_1_req_bits_uop_isDropAmocasSta;
    enq_bits[1].uop.uopIdx = io_enq_1_req_bits_uop_uopIdx;
    enq_bits[1].uop.isVset = io_enq_1_req_bits_uop_isVset;
    enq_bits[1].uop.firstUop = io_enq_1_req_bits_uop_firstUop;
    enq_bits[1].uop.lastUop = io_enq_1_req_bits_uop_lastUop;
    enq_bits[1].uop.numUops = io_enq_1_req_bits_uop_numUops;
    enq_bits[1].uop.numWB = io_enq_1_req_bits_uop_numWB;
    enq_bits[1].uop.commitType = io_enq_1_req_bits_uop_commitType;
    enq_bits[1].uop.srcState_0 = io_enq_1_req_bits_uop_srcState_0;
    enq_bits[1].uop.srcState_1 = io_enq_1_req_bits_uop_srcState_1;
    enq_bits[1].uop.srcState_2 = io_enq_1_req_bits_uop_srcState_2;
    enq_bits[1].uop.srcState_3 = io_enq_1_req_bits_uop_srcState_3;
    enq_bits[1].uop.srcState_4 = io_enq_1_req_bits_uop_srcState_4;
    enq_bits[1].uop.srcLoadDependency_0_0 = io_enq_1_req_bits_uop_srcLoadDependency_0_0;
    enq_bits[1].uop.srcLoadDependency_0_1 = io_enq_1_req_bits_uop_srcLoadDependency_0_1;
    enq_bits[1].uop.srcLoadDependency_0_2 = io_enq_1_req_bits_uop_srcLoadDependency_0_2;
    enq_bits[1].uop.srcLoadDependency_1_0 = io_enq_1_req_bits_uop_srcLoadDependency_1_0;
    enq_bits[1].uop.srcLoadDependency_1_1 = io_enq_1_req_bits_uop_srcLoadDependency_1_1;
    enq_bits[1].uop.srcLoadDependency_1_2 = io_enq_1_req_bits_uop_srcLoadDependency_1_2;
    enq_bits[1].uop.srcLoadDependency_2_0 = io_enq_1_req_bits_uop_srcLoadDependency_2_0;
    enq_bits[1].uop.srcLoadDependency_2_1 = io_enq_1_req_bits_uop_srcLoadDependency_2_1;
    enq_bits[1].uop.srcLoadDependency_2_2 = io_enq_1_req_bits_uop_srcLoadDependency_2_2;
    enq_bits[1].uop.srcLoadDependency_3_0 = io_enq_1_req_bits_uop_srcLoadDependency_3_0;
    enq_bits[1].uop.srcLoadDependency_3_1 = io_enq_1_req_bits_uop_srcLoadDependency_3_1;
    enq_bits[1].uop.srcLoadDependency_3_2 = io_enq_1_req_bits_uop_srcLoadDependency_3_2;
    enq_bits[1].uop.srcLoadDependency_4_0 = io_enq_1_req_bits_uop_srcLoadDependency_4_0;
    enq_bits[1].uop.srcLoadDependency_4_1 = io_enq_1_req_bits_uop_srcLoadDependency_4_1;
    enq_bits[1].uop.srcLoadDependency_4_2 = io_enq_1_req_bits_uop_srcLoadDependency_4_2;
    enq_bits[1].uop.psrc_0 = io_enq_1_req_bits_uop_psrc_0;
    enq_bits[1].uop.psrc_1 = io_enq_1_req_bits_uop_psrc_1;
    enq_bits[1].uop.psrc_2 = io_enq_1_req_bits_uop_psrc_2;
    enq_bits[1].uop.psrc_3 = io_enq_1_req_bits_uop_psrc_3;
    enq_bits[1].uop.psrc_4 = io_enq_1_req_bits_uop_psrc_4;
    enq_bits[1].uop.pdest = io_enq_1_req_bits_uop_pdest;
    enq_bits[1].uop.useRegCache_0 = io_enq_1_req_bits_uop_useRegCache_0;
    enq_bits[1].uop.useRegCache_1 = io_enq_1_req_bits_uop_useRegCache_1;
    enq_bits[1].uop.regCacheIdx_0 = io_enq_1_req_bits_uop_regCacheIdx_0;
    enq_bits[1].uop.regCacheIdx_1 = io_enq_1_req_bits_uop_regCacheIdx_1;
    enq_bits[1].uop.robIdx_flag = io_enq_1_req_bits_uop_robIdx_flag;
    enq_bits[1].uop.robIdx_value = io_enq_1_req_bits_uop_robIdx_value;
    enq_bits[1].uop.instrSize = io_enq_1_req_bits_uop_instrSize;
    enq_bits[1].uop.dirtyFs = io_enq_1_req_bits_uop_dirtyFs;
    enq_bits[1].uop.dirtyVs = io_enq_1_req_bits_uop_dirtyVs;
    enq_bits[1].uop.traceBlockInPipe_itype = io_enq_1_req_bits_uop_traceBlockInPipe_itype;
    enq_bits[1].uop.traceBlockInPipe_iretire = io_enq_1_req_bits_uop_traceBlockInPipe_iretire;
    enq_bits[1].uop.traceBlockInPipe_ilastsize = io_enq_1_req_bits_uop_traceBlockInPipe_ilastsize;
    enq_bits[1].uop.eliminatedMove = io_enq_1_req_bits_uop_eliminatedMove;
    enq_bits[1].uop.snapshot = io_enq_1_req_bits_uop_snapshot;
    enq_bits[1].uop.debugInfo_eliminatedMove = io_enq_1_req_bits_uop_debugInfo_eliminatedMove;
    enq_bits[1].uop.debugInfo_renameTime = io_enq_1_req_bits_uop_debugInfo_renameTime;
    enq_bits[1].uop.debugInfo_dispatchTime = io_enq_1_req_bits_uop_debugInfo_dispatchTime;
    enq_bits[1].uop.debugInfo_enqRsTime = io_enq_1_req_bits_uop_debugInfo_enqRsTime;
    enq_bits[1].uop.debugInfo_selectTime = io_enq_1_req_bits_uop_debugInfo_selectTime;
    enq_bits[1].uop.debugInfo_issueTime = io_enq_1_req_bits_uop_debugInfo_issueTime;
    enq_bits[1].uop.debugInfo_writebackTime = io_enq_1_req_bits_uop_debugInfo_writebackTime;
    enq_bits[1].uop.debugInfo_runahead_checkpoint_id = io_enq_1_req_bits_uop_debugInfo_runahead_checkpoint_id;
    enq_bits[1].uop.debugInfo_tlbFirstReqTime = io_enq_1_req_bits_uop_debugInfo_tlbFirstReqTime;
    enq_bits[1].uop.debugInfo_tlbRespTime = io_enq_1_req_bits_uop_debugInfo_tlbRespTime;
    enq_bits[1].uop.debug_seqNum_seqNum = io_enq_1_req_bits_uop_debug_seqNum_seqNum;
    enq_bits[1].uop.debug_seqNum_uopIdx = io_enq_1_req_bits_uop_debug_seqNum_uopIdx;
    enq_bits[1].uop.storeSetHit = io_enq_1_req_bits_uop_storeSetHit;
    enq_bits[1].uop.waitForRobIdx_flag = io_enq_1_req_bits_uop_waitForRobIdx_flag;
    enq_bits[1].uop.waitForRobIdx_value = io_enq_1_req_bits_uop_waitForRobIdx_value;
    enq_bits[1].uop.loadWaitBit = io_enq_1_req_bits_uop_loadWaitBit;
    enq_bits[1].uop.loadWaitStrict = io_enq_1_req_bits_uop_loadWaitStrict;
    enq_bits[1].uop.ssid = io_enq_1_req_bits_uop_ssid;
    enq_bits[1].uop.lqIdx_flag = io_enq_1_req_bits_uop_lqIdx_flag;
    enq_bits[1].uop.lqIdx_value = io_enq_1_req_bits_uop_lqIdx_value;
    enq_bits[1].uop.sqIdx_flag = io_enq_1_req_bits_uop_sqIdx_flag;
    enq_bits[1].uop.sqIdx_value = io_enq_1_req_bits_uop_sqIdx_value;
    enq_bits[1].uop.singleStep = io_enq_1_req_bits_uop_singleStep;
    enq_bits[1].uop.replayInst = io_enq_1_req_bits_uop_replayInst;
    enq_bits[1].uop.debug_fuType = io_enq_1_req_bits_uop_debug_fuType;
    enq_bits[1].uop.debug_sim_trig = io_enq_1_req_bits_uop_debug_sim_trig;
    enq_bits[1].uop.numLsElem = io_enq_1_req_bits_uop_numLsElem;
    enq_bits[1].vaddr = io_enq_1_req_bits_vaddr;
    enq_bits[1].fullva = io_enq_1_req_bits_fullva;
    enq_bits[1].vaNeedExt = io_enq_1_req_bits_vaNeedExt;
    enq_bits[1].paddr = io_enq_1_req_bits_paddr;
    enq_bits[1].gpaddr = io_enq_1_req_bits_gpaddr;
    enq_bits[1].mask = io_enq_1_req_bits_mask;
    enq_bits[1].isForVSnonLeafPTE = io_enq_1_req_bits_isForVSnonLeafPTE;
    enq_bits[1].isvec = io_enq_1_req_bits_isvec;
    enq_bits[1].elemIdx = io_enq_1_req_bits_elemIdx;
    enq_bits[1].alignedType = io_enq_1_req_bits_alignedType;
    enq_bits[1].mbIndex = io_enq_1_req_bits_mbIndex;
    enq_bits[1].elemIdxInsideVd = io_enq_1_req_bits_elemIdxInsideVd;
    enq_bits[1].vecTriggerMask = io_enq_1_req_bits_vecTriggerMask;
  end
  always_comb begin
    enq_bits[2] = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    enq_bits[2].uop.instr = io_enq_2_req_bits_uop_instr;
    enq_bits[2].uop.pc = io_enq_2_req_bits_uop_pc;
    enq_bits[2].uop.foldpc = io_enq_2_req_bits_uop_foldpc;
    enq_bits[2].uop.exceptionVec[0] = io_enq_2_req_bits_uop_exceptionVec_0;
    enq_bits[2].uop.exceptionVec[1] = io_enq_2_req_bits_uop_exceptionVec_1;
    enq_bits[2].uop.exceptionVec[2] = io_enq_2_req_bits_uop_exceptionVec_2;
    enq_bits[2].uop.exceptionVec[3] = io_enq_2_req_bits_uop_exceptionVec_3;
    enq_bits[2].uop.exceptionVec[5] = io_enq_2_req_bits_uop_exceptionVec_5;
    enq_bits[2].uop.exceptionVec[6] = io_enq_2_req_bits_uop_exceptionVec_6;
    enq_bits[2].uop.exceptionVec[7] = io_enq_2_req_bits_uop_exceptionVec_7;
    enq_bits[2].uop.exceptionVec[8] = io_enq_2_req_bits_uop_exceptionVec_8;
    enq_bits[2].uop.exceptionVec[9] = io_enq_2_req_bits_uop_exceptionVec_9;
    enq_bits[2].uop.exceptionVec[10] = io_enq_2_req_bits_uop_exceptionVec_10;
    enq_bits[2].uop.exceptionVec[11] = io_enq_2_req_bits_uop_exceptionVec_11;
    enq_bits[2].uop.exceptionVec[12] = io_enq_2_req_bits_uop_exceptionVec_12;
    enq_bits[2].uop.exceptionVec[13] = io_enq_2_req_bits_uop_exceptionVec_13;
    enq_bits[2].uop.exceptionVec[14] = io_enq_2_req_bits_uop_exceptionVec_14;
    enq_bits[2].uop.exceptionVec[15] = io_enq_2_req_bits_uop_exceptionVec_15;
    enq_bits[2].uop.exceptionVec[16] = io_enq_2_req_bits_uop_exceptionVec_16;
    enq_bits[2].uop.exceptionVec[17] = io_enq_2_req_bits_uop_exceptionVec_17;
    enq_bits[2].uop.exceptionVec[18] = io_enq_2_req_bits_uop_exceptionVec_18;
    enq_bits[2].uop.exceptionVec[19] = io_enq_2_req_bits_uop_exceptionVec_19;
    enq_bits[2].uop.exceptionVec[20] = io_enq_2_req_bits_uop_exceptionVec_20;
    enq_bits[2].uop.exceptionVec[21] = io_enq_2_req_bits_uop_exceptionVec_21;
    enq_bits[2].uop.exceptionVec[22] = io_enq_2_req_bits_uop_exceptionVec_22;
    enq_bits[2].uop.exceptionVec[23] = io_enq_2_req_bits_uop_exceptionVec_23;
    enq_bits[2].uop.isFetchMalAddr = io_enq_2_req_bits_uop_isFetchMalAddr;
    enq_bits[2].uop.hasException = io_enq_2_req_bits_uop_hasException;
    enq_bits[2].uop.trigger = io_enq_2_req_bits_uop_trigger;
    enq_bits[2].uop.preDecodeInfo_valid = io_enq_2_req_bits_uop_preDecodeInfo_valid;
    enq_bits[2].uop.preDecodeInfo_isRVC = io_enq_2_req_bits_uop_preDecodeInfo_isRVC;
    enq_bits[2].uop.preDecodeInfo_brType = io_enq_2_req_bits_uop_preDecodeInfo_brType;
    enq_bits[2].uop.preDecodeInfo_isCall = io_enq_2_req_bits_uop_preDecodeInfo_isCall;
    enq_bits[2].uop.preDecodeInfo_isRet = io_enq_2_req_bits_uop_preDecodeInfo_isRet;
    enq_bits[2].uop.pred_taken = io_enq_2_req_bits_uop_pred_taken;
    enq_bits[2].uop.crossPageIPFFix = io_enq_2_req_bits_uop_crossPageIPFFix;
    enq_bits[2].uop.ftqPtr_flag = io_enq_2_req_bits_uop_ftqPtr_flag;
    enq_bits[2].uop.ftqPtr_value = io_enq_2_req_bits_uop_ftqPtr_value;
    enq_bits[2].uop.ftqOffset = io_enq_2_req_bits_uop_ftqOffset;
    enq_bits[2].uop.satpFlushFirstFetchFault = io_enq_2_req_bits_uop_satpFlushFirstFetchFault;
    enq_bits[2].uop.srcType_0 = io_enq_2_req_bits_uop_srcType_0;
    enq_bits[2].uop.srcType_1 = io_enq_2_req_bits_uop_srcType_1;
    enq_bits[2].uop.srcType_2 = io_enq_2_req_bits_uop_srcType_2;
    enq_bits[2].uop.srcType_3 = io_enq_2_req_bits_uop_srcType_3;
    enq_bits[2].uop.srcType_4 = io_enq_2_req_bits_uop_srcType_4;
    enq_bits[2].uop.ldest = io_enq_2_req_bits_uop_ldest;
    enq_bits[2].uop.fuType = io_enq_2_req_bits_uop_fuType;
    enq_bits[2].uop.fuOpType = io_enq_2_req_bits_uop_fuOpType;
    enq_bits[2].uop.rfWen = io_enq_2_req_bits_uop_rfWen;
    enq_bits[2].uop.fpWen = io_enq_2_req_bits_uop_fpWen;
    enq_bits[2].uop.vecWen = io_enq_2_req_bits_uop_vecWen;
    enq_bits[2].uop.v0Wen = io_enq_2_req_bits_uop_v0Wen;
    enq_bits[2].uop.vlWen = io_enq_2_req_bits_uop_vlWen;
    enq_bits[2].uop.isXSTrap = io_enq_2_req_bits_uop_isXSTrap;
    enq_bits[2].uop.waitForward = io_enq_2_req_bits_uop_waitForward;
    enq_bits[2].uop.blockBackward = io_enq_2_req_bits_uop_blockBackward;
    enq_bits[2].uop.canRobCompress = io_enq_2_req_bits_uop_canRobCompress;
    enq_bits[2].uop.selImm = io_enq_2_req_bits_uop_selImm;
    enq_bits[2].uop.imm = io_enq_2_req_bits_uop_imm;
    enq_bits[2].uop.fpu_typeTagOut = io_enq_2_req_bits_uop_fpu_typeTagOut;
    enq_bits[2].uop.fpu_wflags = io_enq_2_req_bits_uop_fpu_wflags;
    enq_bits[2].uop.fpu_typ = io_enq_2_req_bits_uop_fpu_typ;
    enq_bits[2].uop.fpu_fmt = io_enq_2_req_bits_uop_fpu_fmt;
    enq_bits[2].uop.fpu_rm = io_enq_2_req_bits_uop_fpu_rm;
    enq_bits[2].uop.vpu_vill = io_enq_2_req_bits_uop_vpu_vill;
    enq_bits[2].uop.vpu_vma = io_enq_2_req_bits_uop_vpu_vma;
    enq_bits[2].uop.vpu_vta = io_enq_2_req_bits_uop_vpu_vta;
    enq_bits[2].uop.vpu_vsew = io_enq_2_req_bits_uop_vpu_vsew;
    enq_bits[2].uop.vpu_vlmul = io_enq_2_req_bits_uop_vpu_vlmul;
    enq_bits[2].uop.vpu_specVill = io_enq_2_req_bits_uop_vpu_specVill;
    enq_bits[2].uop.vpu_specVma = io_enq_2_req_bits_uop_vpu_specVma;
    enq_bits[2].uop.vpu_specVta = io_enq_2_req_bits_uop_vpu_specVta;
    enq_bits[2].uop.vpu_specVsew = io_enq_2_req_bits_uop_vpu_specVsew;
    enq_bits[2].uop.vpu_specVlmul = io_enq_2_req_bits_uop_vpu_specVlmul;
    enq_bits[2].uop.vpu_vm = io_enq_2_req_bits_uop_vpu_vm;
    enq_bits[2].uop.vpu_vstart = io_enq_2_req_bits_uop_vpu_vstart;
    enq_bits[2].uop.vpu_frm = io_enq_2_req_bits_uop_vpu_frm;
    enq_bits[2].uop.vpu_fpu_isFpToVecInst = io_enq_2_req_bits_uop_vpu_fpu_isFpToVecInst;
    enq_bits[2].uop.vpu_fpu_isFP32Instr = io_enq_2_req_bits_uop_vpu_fpu_isFP32Instr;
    enq_bits[2].uop.vpu_fpu_isFP64Instr = io_enq_2_req_bits_uop_vpu_fpu_isFP64Instr;
    enq_bits[2].uop.vpu_fpu_isReduction = io_enq_2_req_bits_uop_vpu_fpu_isReduction;
    enq_bits[2].uop.vpu_fpu_isFoldTo1_2 = io_enq_2_req_bits_uop_vpu_fpu_isFoldTo1_2;
    enq_bits[2].uop.vpu_fpu_isFoldTo1_4 = io_enq_2_req_bits_uop_vpu_fpu_isFoldTo1_4;
    enq_bits[2].uop.vpu_fpu_isFoldTo1_8 = io_enq_2_req_bits_uop_vpu_fpu_isFoldTo1_8;
    enq_bits[2].uop.vpu_vxrm = io_enq_2_req_bits_uop_vpu_vxrm;
    enq_bits[2].uop.vpu_vuopIdx = io_enq_2_req_bits_uop_vpu_vuopIdx;
    enq_bits[2].uop.vpu_lastUop = io_enq_2_req_bits_uop_vpu_lastUop;
    enq_bits[2].uop.vpu_vmask = io_enq_2_req_bits_uop_vpu_vmask;
    enq_bits[2].uop.vpu_vl = io_enq_2_req_bits_uop_vpu_vl;
    enq_bits[2].uop.vpu_nf = io_enq_2_req_bits_uop_vpu_nf;
    enq_bits[2].uop.vpu_veew = io_enq_2_req_bits_uop_vpu_veew;
    enq_bits[2].uop.vpu_isReverse = io_enq_2_req_bits_uop_vpu_isReverse;
    enq_bits[2].uop.vpu_isExt = io_enq_2_req_bits_uop_vpu_isExt;
    enq_bits[2].uop.vpu_isNarrow = io_enq_2_req_bits_uop_vpu_isNarrow;
    enq_bits[2].uop.vpu_isDstMask = io_enq_2_req_bits_uop_vpu_isDstMask;
    enq_bits[2].uop.vpu_isOpMask = io_enq_2_req_bits_uop_vpu_isOpMask;
    enq_bits[2].uop.vpu_isMove = io_enq_2_req_bits_uop_vpu_isMove;
    enq_bits[2].uop.vpu_isDependOldVd = io_enq_2_req_bits_uop_vpu_isDependOldVd;
    enq_bits[2].uop.vpu_isWritePartVd = io_enq_2_req_bits_uop_vpu_isWritePartVd;
    enq_bits[2].uop.vpu_isVleff = io_enq_2_req_bits_uop_vpu_isVleff;
    enq_bits[2].uop.vlsInstr = io_enq_2_req_bits_uop_vlsInstr;
    enq_bits[2].uop.wfflags = io_enq_2_req_bits_uop_wfflags;
    enq_bits[2].uop.isMove = io_enq_2_req_bits_uop_isMove;
    enq_bits[2].uop.isDropAmocasSta = io_enq_2_req_bits_uop_isDropAmocasSta;
    enq_bits[2].uop.uopIdx = io_enq_2_req_bits_uop_uopIdx;
    enq_bits[2].uop.isVset = io_enq_2_req_bits_uop_isVset;
    enq_bits[2].uop.firstUop = io_enq_2_req_bits_uop_firstUop;
    enq_bits[2].uop.lastUop = io_enq_2_req_bits_uop_lastUop;
    enq_bits[2].uop.numUops = io_enq_2_req_bits_uop_numUops;
    enq_bits[2].uop.numWB = io_enq_2_req_bits_uop_numWB;
    enq_bits[2].uop.commitType = io_enq_2_req_bits_uop_commitType;
    enq_bits[2].uop.srcState_0 = io_enq_2_req_bits_uop_srcState_0;
    enq_bits[2].uop.srcState_1 = io_enq_2_req_bits_uop_srcState_1;
    enq_bits[2].uop.srcState_2 = io_enq_2_req_bits_uop_srcState_2;
    enq_bits[2].uop.srcState_3 = io_enq_2_req_bits_uop_srcState_3;
    enq_bits[2].uop.srcState_4 = io_enq_2_req_bits_uop_srcState_4;
    enq_bits[2].uop.srcLoadDependency_0_0 = io_enq_2_req_bits_uop_srcLoadDependency_0_0;
    enq_bits[2].uop.srcLoadDependency_0_1 = io_enq_2_req_bits_uop_srcLoadDependency_0_1;
    enq_bits[2].uop.srcLoadDependency_0_2 = io_enq_2_req_bits_uop_srcLoadDependency_0_2;
    enq_bits[2].uop.srcLoadDependency_1_0 = io_enq_2_req_bits_uop_srcLoadDependency_1_0;
    enq_bits[2].uop.srcLoadDependency_1_1 = io_enq_2_req_bits_uop_srcLoadDependency_1_1;
    enq_bits[2].uop.srcLoadDependency_1_2 = io_enq_2_req_bits_uop_srcLoadDependency_1_2;
    enq_bits[2].uop.srcLoadDependency_2_0 = io_enq_2_req_bits_uop_srcLoadDependency_2_0;
    enq_bits[2].uop.srcLoadDependency_2_1 = io_enq_2_req_bits_uop_srcLoadDependency_2_1;
    enq_bits[2].uop.srcLoadDependency_2_2 = io_enq_2_req_bits_uop_srcLoadDependency_2_2;
    enq_bits[2].uop.srcLoadDependency_3_0 = io_enq_2_req_bits_uop_srcLoadDependency_3_0;
    enq_bits[2].uop.srcLoadDependency_3_1 = io_enq_2_req_bits_uop_srcLoadDependency_3_1;
    enq_bits[2].uop.srcLoadDependency_3_2 = io_enq_2_req_bits_uop_srcLoadDependency_3_2;
    enq_bits[2].uop.srcLoadDependency_4_0 = io_enq_2_req_bits_uop_srcLoadDependency_4_0;
    enq_bits[2].uop.srcLoadDependency_4_1 = io_enq_2_req_bits_uop_srcLoadDependency_4_1;
    enq_bits[2].uop.srcLoadDependency_4_2 = io_enq_2_req_bits_uop_srcLoadDependency_4_2;
    enq_bits[2].uop.psrc_0 = io_enq_2_req_bits_uop_psrc_0;
    enq_bits[2].uop.psrc_1 = io_enq_2_req_bits_uop_psrc_1;
    enq_bits[2].uop.psrc_2 = io_enq_2_req_bits_uop_psrc_2;
    enq_bits[2].uop.psrc_3 = io_enq_2_req_bits_uop_psrc_3;
    enq_bits[2].uop.psrc_4 = io_enq_2_req_bits_uop_psrc_4;
    enq_bits[2].uop.pdest = io_enq_2_req_bits_uop_pdest;
    enq_bits[2].uop.useRegCache_0 = io_enq_2_req_bits_uop_useRegCache_0;
    enq_bits[2].uop.useRegCache_1 = io_enq_2_req_bits_uop_useRegCache_1;
    enq_bits[2].uop.regCacheIdx_0 = io_enq_2_req_bits_uop_regCacheIdx_0;
    enq_bits[2].uop.regCacheIdx_1 = io_enq_2_req_bits_uop_regCacheIdx_1;
    enq_bits[2].uop.robIdx_flag = io_enq_2_req_bits_uop_robIdx_flag;
    enq_bits[2].uop.robIdx_value = io_enq_2_req_bits_uop_robIdx_value;
    enq_bits[2].uop.instrSize = io_enq_2_req_bits_uop_instrSize;
    enq_bits[2].uop.dirtyFs = io_enq_2_req_bits_uop_dirtyFs;
    enq_bits[2].uop.dirtyVs = io_enq_2_req_bits_uop_dirtyVs;
    enq_bits[2].uop.traceBlockInPipe_itype = io_enq_2_req_bits_uop_traceBlockInPipe_itype;
    enq_bits[2].uop.traceBlockInPipe_iretire = io_enq_2_req_bits_uop_traceBlockInPipe_iretire;
    enq_bits[2].uop.traceBlockInPipe_ilastsize = io_enq_2_req_bits_uop_traceBlockInPipe_ilastsize;
    enq_bits[2].uop.eliminatedMove = io_enq_2_req_bits_uop_eliminatedMove;
    enq_bits[2].uop.snapshot = io_enq_2_req_bits_uop_snapshot;
    enq_bits[2].uop.debugInfo_eliminatedMove = io_enq_2_req_bits_uop_debugInfo_eliminatedMove;
    enq_bits[2].uop.debugInfo_renameTime = io_enq_2_req_bits_uop_debugInfo_renameTime;
    enq_bits[2].uop.debugInfo_dispatchTime = io_enq_2_req_bits_uop_debugInfo_dispatchTime;
    enq_bits[2].uop.debugInfo_enqRsTime = io_enq_2_req_bits_uop_debugInfo_enqRsTime;
    enq_bits[2].uop.debugInfo_selectTime = io_enq_2_req_bits_uop_debugInfo_selectTime;
    enq_bits[2].uop.debugInfo_issueTime = io_enq_2_req_bits_uop_debugInfo_issueTime;
    enq_bits[2].uop.debugInfo_writebackTime = io_enq_2_req_bits_uop_debugInfo_writebackTime;
    enq_bits[2].uop.debugInfo_runahead_checkpoint_id = io_enq_2_req_bits_uop_debugInfo_runahead_checkpoint_id;
    enq_bits[2].uop.debugInfo_tlbFirstReqTime = io_enq_2_req_bits_uop_debugInfo_tlbFirstReqTime;
    enq_bits[2].uop.debugInfo_tlbRespTime = io_enq_2_req_bits_uop_debugInfo_tlbRespTime;
    enq_bits[2].uop.debug_seqNum_seqNum = io_enq_2_req_bits_uop_debug_seqNum_seqNum;
    enq_bits[2].uop.debug_seqNum_uopIdx = io_enq_2_req_bits_uop_debug_seqNum_uopIdx;
    enq_bits[2].uop.storeSetHit = io_enq_2_req_bits_uop_storeSetHit;
    enq_bits[2].uop.waitForRobIdx_flag = io_enq_2_req_bits_uop_waitForRobIdx_flag;
    enq_bits[2].uop.waitForRobIdx_value = io_enq_2_req_bits_uop_waitForRobIdx_value;
    enq_bits[2].uop.loadWaitBit = io_enq_2_req_bits_uop_loadWaitBit;
    enq_bits[2].uop.loadWaitStrict = io_enq_2_req_bits_uop_loadWaitStrict;
    enq_bits[2].uop.ssid = io_enq_2_req_bits_uop_ssid;
    enq_bits[2].uop.lqIdx_flag = io_enq_2_req_bits_uop_lqIdx_flag;
    enq_bits[2].uop.lqIdx_value = io_enq_2_req_bits_uop_lqIdx_value;
    enq_bits[2].uop.sqIdx_flag = io_enq_2_req_bits_uop_sqIdx_flag;
    enq_bits[2].uop.sqIdx_value = io_enq_2_req_bits_uop_sqIdx_value;
    enq_bits[2].uop.singleStep = io_enq_2_req_bits_uop_singleStep;
    enq_bits[2].uop.replayInst = io_enq_2_req_bits_uop_replayInst;
    enq_bits[2].uop.debug_fuType = io_enq_2_req_bits_uop_debug_fuType;
    enq_bits[2].uop.debug_sim_trig = io_enq_2_req_bits_uop_debug_sim_trig;
    enq_bits[2].uop.numLsElem = io_enq_2_req_bits_uop_numLsElem;
    enq_bits[2].vaddr = io_enq_2_req_bits_vaddr;
    enq_bits[2].fullva = io_enq_2_req_bits_fullva;
    enq_bits[2].vaNeedExt = io_enq_2_req_bits_vaNeedExt;
    enq_bits[2].paddr = io_enq_2_req_bits_paddr;
    enq_bits[2].gpaddr = io_enq_2_req_bits_gpaddr;
    enq_bits[2].mask = io_enq_2_req_bits_mask;
    enq_bits[2].isForVSnonLeafPTE = io_enq_2_req_bits_isForVSnonLeafPTE;
    enq_bits[2].isvec = io_enq_2_req_bits_isvec;
    enq_bits[2].elemIdx = io_enq_2_req_bits_elemIdx;
    enq_bits[2].alignedType = io_enq_2_req_bits_alignedType;
    enq_bits[2].mbIndex = io_enq_2_req_bits_mbIndex;
    enq_bits[2].elemIdxInsideVd = io_enq_2_req_bits_elemIdxInsideVd;
    enq_bits[2].vecTriggerMask = io_enq_2_req_bits_vecTriggerMask;
  end
  always_comb begin
    split_resp = '0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0
    split_resp.uop.exceptionVec[3] = io_splitLoadResp_bits_uop_exceptionVec_3;
    split_resp.uop.exceptionVec[4] = io_splitLoadResp_bits_uop_exceptionVec_4;
    split_resp.uop.exceptionVec[5] = io_splitLoadResp_bits_uop_exceptionVec_5;
    split_resp.uop.exceptionVec[13] = io_splitLoadResp_bits_uop_exceptionVec_13;
    split_resp.uop.exceptionVec[19] = io_splitLoadResp_bits_uop_exceptionVec_19;
    split_resp.uop.exceptionVec[21] = io_splitLoadResp_bits_uop_exceptionVec_21;
    split_resp.uop.trigger = io_splitLoadResp_bits_uop_trigger;
    split_resp.uop.robIdx_flag = io_splitLoadResp_bits_uop_robIdx_flag;
    split_resp.uop.robIdx_value = io_splitLoadResp_bits_uop_robIdx_value;
    split_resp.vaddr = io_splitLoadResp_bits_vaddr;
    split_resp.fullva = io_splitLoadResp_bits_fullva;
    split_resp.vaNeedExt = io_splitLoadResp_bits_vaNeedExt;
    split_resp.paddr = io_splitLoadResp_bits_paddr;
    split_resp.gpaddr = io_splitLoadResp_bits_gpaddr;
    split_resp.data = io_splitLoadResp_bits_data;
    split_resp.nc = io_splitLoadResp_bits_nc;
    split_resp.mmio = io_splitLoadResp_bits_mmio;
    split_resp.memBackTypeMM = io_splitLoadResp_bits_memBackTypeMM;
    split_resp.isForVSnonLeafPTE = io_splitLoadResp_bits_isForVSnonLeafPTE;
    split_resp.vecActive = io_splitLoadResp_bits_vecActive;
    split_resp.misalignNeedWakeUp = io_splitLoadResp_bits_misalignNeedWakeUp;
    split_resp.rep_info_cause[0] = io_splitLoadResp_bits_rep_info_cause_0;
    split_resp.rep_info_cause[1] = io_splitLoadResp_bits_rep_info_cause_1;
    split_resp.rep_info_cause[2] = io_splitLoadResp_bits_rep_info_cause_2;
    split_resp.rep_info_cause[3] = io_splitLoadResp_bits_rep_info_cause_3;
    split_resp.rep_info_cause[4] = io_splitLoadResp_bits_rep_info_cause_4;
    split_resp.rep_info_cause[5] = io_splitLoadResp_bits_rep_info_cause_5;
    split_resp.rep_info_cause[6] = io_splitLoadResp_bits_rep_info_cause_6;
    split_resp.rep_info_cause[7] = io_splitLoadResp_bits_rep_info_cause_7;
    split_resp.rep_info_cause[8] = io_splitLoadResp_bits_rep_info_cause_8;
    split_resp.rep_info_cause[9] = io_splitLoadResp_bits_rep_info_cause_9;
    split_resp.rep_info_cause[10] = io_splitLoadResp_bits_rep_info_cause_10;
  end

  assign enq_valid[0] = io_enq_0_req_valid;
  assign enq_valid[1] = io_enq_1_req_valid;
  assign enq_valid[2] = io_enq_2_req_valid;
  assign io_enq_0_req_ready = enq_ready[0];
  assign io_enq_1_req_ready = enq_ready[1];
  assign io_enq_2_req_ready = enq_ready[2];

  assign io_splitLoadReq_bits_uop_instr = split_req.uop.instr;
  assign io_splitLoadReq_bits_uop_pc = split_req.uop.pc;
  assign io_splitLoadReq_bits_uop_foldpc = split_req.uop.foldpc;
  assign io_splitLoadReq_bits_uop_exceptionVec_0 = split_req.uop.exceptionVec[0];
  assign io_splitLoadReq_bits_uop_exceptionVec_1 = split_req.uop.exceptionVec[1];
  assign io_splitLoadReq_bits_uop_exceptionVec_2 = split_req.uop.exceptionVec[2];
  assign io_splitLoadReq_bits_uop_exceptionVec_3 = split_req.uop.exceptionVec[3];
  assign io_splitLoadReq_bits_uop_exceptionVec_4 = split_req.uop.exceptionVec[4];
  assign io_splitLoadReq_bits_uop_exceptionVec_5 = split_req.uop.exceptionVec[5];
  assign io_splitLoadReq_bits_uop_exceptionVec_6 = split_req.uop.exceptionVec[6];
  assign io_splitLoadReq_bits_uop_exceptionVec_7 = split_req.uop.exceptionVec[7];
  assign io_splitLoadReq_bits_uop_exceptionVec_8 = split_req.uop.exceptionVec[8];
  assign io_splitLoadReq_bits_uop_exceptionVec_9 = split_req.uop.exceptionVec[9];
  assign io_splitLoadReq_bits_uop_exceptionVec_10 = split_req.uop.exceptionVec[10];
  assign io_splitLoadReq_bits_uop_exceptionVec_11 = split_req.uop.exceptionVec[11];
  assign io_splitLoadReq_bits_uop_exceptionVec_12 = split_req.uop.exceptionVec[12];
  assign io_splitLoadReq_bits_uop_exceptionVec_13 = split_req.uop.exceptionVec[13];
  assign io_splitLoadReq_bits_uop_exceptionVec_14 = split_req.uop.exceptionVec[14];
  assign io_splitLoadReq_bits_uop_exceptionVec_15 = split_req.uop.exceptionVec[15];
  assign io_splitLoadReq_bits_uop_exceptionVec_16 = split_req.uop.exceptionVec[16];
  assign io_splitLoadReq_bits_uop_exceptionVec_17 = split_req.uop.exceptionVec[17];
  assign io_splitLoadReq_bits_uop_exceptionVec_18 = split_req.uop.exceptionVec[18];
  assign io_splitLoadReq_bits_uop_exceptionVec_19 = split_req.uop.exceptionVec[19];
  assign io_splitLoadReq_bits_uop_exceptionVec_20 = split_req.uop.exceptionVec[20];
  assign io_splitLoadReq_bits_uop_exceptionVec_21 = split_req.uop.exceptionVec[21];
  assign io_splitLoadReq_bits_uop_exceptionVec_22 = split_req.uop.exceptionVec[22];
  assign io_splitLoadReq_bits_uop_exceptionVec_23 = split_req.uop.exceptionVec[23];
  assign io_splitLoadReq_bits_uop_isFetchMalAddr = split_req.uop.isFetchMalAddr;
  assign io_splitLoadReq_bits_uop_hasException = split_req.uop.hasException;
  assign io_splitLoadReq_bits_uop_trigger = split_req.uop.trigger;
  assign io_splitLoadReq_bits_uop_preDecodeInfo_valid = split_req.uop.preDecodeInfo_valid;
  assign io_splitLoadReq_bits_uop_preDecodeInfo_isRVC = split_req.uop.preDecodeInfo_isRVC;
  assign io_splitLoadReq_bits_uop_preDecodeInfo_brType = split_req.uop.preDecodeInfo_brType;
  assign io_splitLoadReq_bits_uop_preDecodeInfo_isCall = split_req.uop.preDecodeInfo_isCall;
  assign io_splitLoadReq_bits_uop_preDecodeInfo_isRet = split_req.uop.preDecodeInfo_isRet;
  assign io_splitLoadReq_bits_uop_pred_taken = split_req.uop.pred_taken;
  assign io_splitLoadReq_bits_uop_crossPageIPFFix = split_req.uop.crossPageIPFFix;
  assign io_splitLoadReq_bits_uop_ftqPtr_flag = split_req.uop.ftqPtr_flag;
  assign io_splitLoadReq_bits_uop_ftqPtr_value = split_req.uop.ftqPtr_value;
  assign io_splitLoadReq_bits_uop_ftqOffset = split_req.uop.ftqOffset;
  assign io_splitLoadReq_bits_uop_satpFlushFirstFetchFault = split_req.uop.satpFlushFirstFetchFault;
  assign io_splitLoadReq_bits_uop_srcType_0 = split_req.uop.srcType_0;
  assign io_splitLoadReq_bits_uop_srcType_1 = split_req.uop.srcType_1;
  assign io_splitLoadReq_bits_uop_srcType_2 = split_req.uop.srcType_2;
  assign io_splitLoadReq_bits_uop_srcType_3 = split_req.uop.srcType_3;
  assign io_splitLoadReq_bits_uop_srcType_4 = split_req.uop.srcType_4;
  assign io_splitLoadReq_bits_uop_ldest = split_req.uop.ldest;
  assign io_splitLoadReq_bits_uop_fuType = split_req.uop.fuType;
  assign io_splitLoadReq_bits_uop_fuOpType = split_req.uop.fuOpType;
  assign io_splitLoadReq_bits_uop_rfWen = split_req.uop.rfWen;
  assign io_splitLoadReq_bits_uop_fpWen = split_req.uop.fpWen;
  assign io_splitLoadReq_bits_uop_vecWen = split_req.uop.vecWen;
  assign io_splitLoadReq_bits_uop_v0Wen = split_req.uop.v0Wen;
  assign io_splitLoadReq_bits_uop_vlWen = split_req.uop.vlWen;
  assign io_splitLoadReq_bits_uop_isXSTrap = split_req.uop.isXSTrap;
  assign io_splitLoadReq_bits_uop_waitForward = split_req.uop.waitForward;
  assign io_splitLoadReq_bits_uop_blockBackward = split_req.uop.blockBackward;
  assign io_splitLoadReq_bits_uop_flushPipe = split_req.uop.flushPipe;
  assign io_splitLoadReq_bits_uop_canRobCompress = split_req.uop.canRobCompress;
  assign io_splitLoadReq_bits_uop_selImm = split_req.uop.selImm;
  assign io_splitLoadReq_bits_uop_imm = split_req.uop.imm;
  assign io_splitLoadReq_bits_uop_fpu_typeTagOut = split_req.uop.fpu_typeTagOut;
  assign io_splitLoadReq_bits_uop_fpu_wflags = split_req.uop.fpu_wflags;
  assign io_splitLoadReq_bits_uop_fpu_typ = split_req.uop.fpu_typ;
  assign io_splitLoadReq_bits_uop_fpu_fmt = split_req.uop.fpu_fmt;
  assign io_splitLoadReq_bits_uop_fpu_rm = split_req.uop.fpu_rm;
  assign io_splitLoadReq_bits_uop_vpu_vill = split_req.uop.vpu_vill;
  assign io_splitLoadReq_bits_uop_vpu_vma = split_req.uop.vpu_vma;
  assign io_splitLoadReq_bits_uop_vpu_vta = split_req.uop.vpu_vta;
  assign io_splitLoadReq_bits_uop_vpu_vsew = split_req.uop.vpu_vsew;
  assign io_splitLoadReq_bits_uop_vpu_vlmul = split_req.uop.vpu_vlmul;
  assign io_splitLoadReq_bits_uop_vpu_specVill = split_req.uop.vpu_specVill;
  assign io_splitLoadReq_bits_uop_vpu_specVma = split_req.uop.vpu_specVma;
  assign io_splitLoadReq_bits_uop_vpu_specVta = split_req.uop.vpu_specVta;
  assign io_splitLoadReq_bits_uop_vpu_specVsew = split_req.uop.vpu_specVsew;
  assign io_splitLoadReq_bits_uop_vpu_specVlmul = split_req.uop.vpu_specVlmul;
  assign io_splitLoadReq_bits_uop_vpu_vm = split_req.uop.vpu_vm;
  assign io_splitLoadReq_bits_uop_vpu_vstart = split_req.uop.vpu_vstart;
  assign io_splitLoadReq_bits_uop_vpu_frm = split_req.uop.vpu_frm;
  assign io_splitLoadReq_bits_uop_vpu_fpu_isFpToVecInst = split_req.uop.vpu_fpu_isFpToVecInst;
  assign io_splitLoadReq_bits_uop_vpu_fpu_isFP32Instr = split_req.uop.vpu_fpu_isFP32Instr;
  assign io_splitLoadReq_bits_uop_vpu_fpu_isFP64Instr = split_req.uop.vpu_fpu_isFP64Instr;
  assign io_splitLoadReq_bits_uop_vpu_fpu_isReduction = split_req.uop.vpu_fpu_isReduction;
  assign io_splitLoadReq_bits_uop_vpu_fpu_isFoldTo1_2 = split_req.uop.vpu_fpu_isFoldTo1_2;
  assign io_splitLoadReq_bits_uop_vpu_fpu_isFoldTo1_4 = split_req.uop.vpu_fpu_isFoldTo1_4;
  assign io_splitLoadReq_bits_uop_vpu_fpu_isFoldTo1_8 = split_req.uop.vpu_fpu_isFoldTo1_8;
  assign io_splitLoadReq_bits_uop_vpu_vxrm = split_req.uop.vpu_vxrm;
  assign io_splitLoadReq_bits_uop_vpu_vuopIdx = split_req.uop.vpu_vuopIdx;
  assign io_splitLoadReq_bits_uop_vpu_lastUop = split_req.uop.vpu_lastUop;
  assign io_splitLoadReq_bits_uop_vpu_vmask = split_req.uop.vpu_vmask;
  assign io_splitLoadReq_bits_uop_vpu_vl = split_req.uop.vpu_vl;
  assign io_splitLoadReq_bits_uop_vpu_nf = split_req.uop.vpu_nf;
  assign io_splitLoadReq_bits_uop_vpu_veew = split_req.uop.vpu_veew;
  assign io_splitLoadReq_bits_uop_vpu_isReverse = split_req.uop.vpu_isReverse;
  assign io_splitLoadReq_bits_uop_vpu_isExt = split_req.uop.vpu_isExt;
  assign io_splitLoadReq_bits_uop_vpu_isNarrow = split_req.uop.vpu_isNarrow;
  assign io_splitLoadReq_bits_uop_vpu_isDstMask = split_req.uop.vpu_isDstMask;
  assign io_splitLoadReq_bits_uop_vpu_isOpMask = split_req.uop.vpu_isOpMask;
  assign io_splitLoadReq_bits_uop_vpu_isMove = split_req.uop.vpu_isMove;
  assign io_splitLoadReq_bits_uop_vpu_isDependOldVd = split_req.uop.vpu_isDependOldVd;
  assign io_splitLoadReq_bits_uop_vpu_isWritePartVd = split_req.uop.vpu_isWritePartVd;
  assign io_splitLoadReq_bits_uop_vpu_isVleff = split_req.uop.vpu_isVleff;
  assign io_splitLoadReq_bits_uop_vlsInstr = split_req.uop.vlsInstr;
  assign io_splitLoadReq_bits_uop_wfflags = split_req.uop.wfflags;
  assign io_splitLoadReq_bits_uop_isMove = split_req.uop.isMove;
  assign io_splitLoadReq_bits_uop_isDropAmocasSta = split_req.uop.isDropAmocasSta;
  assign io_splitLoadReq_bits_uop_uopIdx = split_req.uop.uopIdx;
  assign io_splitLoadReq_bits_uop_isVset = split_req.uop.isVset;
  assign io_splitLoadReq_bits_uop_firstUop = split_req.uop.firstUop;
  assign io_splitLoadReq_bits_uop_lastUop = split_req.uop.lastUop;
  assign io_splitLoadReq_bits_uop_numUops = split_req.uop.numUops;
  assign io_splitLoadReq_bits_uop_numWB = split_req.uop.numWB;
  assign io_splitLoadReq_bits_uop_commitType = split_req.uop.commitType;
  assign io_splitLoadReq_bits_uop_srcState_0 = split_req.uop.srcState_0;
  assign io_splitLoadReq_bits_uop_srcState_1 = split_req.uop.srcState_1;
  assign io_splitLoadReq_bits_uop_srcState_2 = split_req.uop.srcState_2;
  assign io_splitLoadReq_bits_uop_srcState_3 = split_req.uop.srcState_3;
  assign io_splitLoadReq_bits_uop_srcState_4 = split_req.uop.srcState_4;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_0_0 = split_req.uop.srcLoadDependency_0_0;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_0_1 = split_req.uop.srcLoadDependency_0_1;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_0_2 = split_req.uop.srcLoadDependency_0_2;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_1_0 = split_req.uop.srcLoadDependency_1_0;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_1_1 = split_req.uop.srcLoadDependency_1_1;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_1_2 = split_req.uop.srcLoadDependency_1_2;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_2_0 = split_req.uop.srcLoadDependency_2_0;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_2_1 = split_req.uop.srcLoadDependency_2_1;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_2_2 = split_req.uop.srcLoadDependency_2_2;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_3_0 = split_req.uop.srcLoadDependency_3_0;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_3_1 = split_req.uop.srcLoadDependency_3_1;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_3_2 = split_req.uop.srcLoadDependency_3_2;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_4_0 = split_req.uop.srcLoadDependency_4_0;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_4_1 = split_req.uop.srcLoadDependency_4_1;
  assign io_splitLoadReq_bits_uop_srcLoadDependency_4_2 = split_req.uop.srcLoadDependency_4_2;
  assign io_splitLoadReq_bits_uop_psrc_0 = split_req.uop.psrc_0;
  assign io_splitLoadReq_bits_uop_psrc_1 = split_req.uop.psrc_1;
  assign io_splitLoadReq_bits_uop_psrc_2 = split_req.uop.psrc_2;
  assign io_splitLoadReq_bits_uop_psrc_3 = split_req.uop.psrc_3;
  assign io_splitLoadReq_bits_uop_psrc_4 = split_req.uop.psrc_4;
  assign io_splitLoadReq_bits_uop_pdest = split_req.uop.pdest;
  assign io_splitLoadReq_bits_uop_useRegCache_0 = split_req.uop.useRegCache_0;
  assign io_splitLoadReq_bits_uop_useRegCache_1 = split_req.uop.useRegCache_1;
  assign io_splitLoadReq_bits_uop_regCacheIdx_0 = split_req.uop.regCacheIdx_0;
  assign io_splitLoadReq_bits_uop_regCacheIdx_1 = split_req.uop.regCacheIdx_1;
  assign io_splitLoadReq_bits_uop_robIdx_flag = split_req.uop.robIdx_flag;
  assign io_splitLoadReq_bits_uop_robIdx_value = split_req.uop.robIdx_value;
  assign io_splitLoadReq_bits_uop_instrSize = split_req.uop.instrSize;
  assign io_splitLoadReq_bits_uop_dirtyFs = split_req.uop.dirtyFs;
  assign io_splitLoadReq_bits_uop_dirtyVs = split_req.uop.dirtyVs;
  assign io_splitLoadReq_bits_uop_traceBlockInPipe_itype = split_req.uop.traceBlockInPipe_itype;
  assign io_splitLoadReq_bits_uop_traceBlockInPipe_iretire = split_req.uop.traceBlockInPipe_iretire;
  assign io_splitLoadReq_bits_uop_traceBlockInPipe_ilastsize = split_req.uop.traceBlockInPipe_ilastsize;
  assign io_splitLoadReq_bits_uop_eliminatedMove = split_req.uop.eliminatedMove;
  assign io_splitLoadReq_bits_uop_snapshot = split_req.uop.snapshot;
  assign io_splitLoadReq_bits_uop_debugInfo_eliminatedMove = split_req.uop.debugInfo_eliminatedMove;
  assign io_splitLoadReq_bits_uop_debugInfo_renameTime = split_req.uop.debugInfo_renameTime;
  assign io_splitLoadReq_bits_uop_debugInfo_dispatchTime = split_req.uop.debugInfo_dispatchTime;
  assign io_splitLoadReq_bits_uop_debugInfo_enqRsTime = split_req.uop.debugInfo_enqRsTime;
  assign io_splitLoadReq_bits_uop_debugInfo_selectTime = split_req.uop.debugInfo_selectTime;
  assign io_splitLoadReq_bits_uop_debugInfo_issueTime = split_req.uop.debugInfo_issueTime;
  assign io_splitLoadReq_bits_uop_debugInfo_writebackTime = split_req.uop.debugInfo_writebackTime;
  assign io_splitLoadReq_bits_uop_debugInfo_runahead_checkpoint_id = split_req.uop.debugInfo_runahead_checkpoint_id;
  assign io_splitLoadReq_bits_uop_debugInfo_tlbFirstReqTime = split_req.uop.debugInfo_tlbFirstReqTime;
  assign io_splitLoadReq_bits_uop_debugInfo_tlbRespTime = split_req.uop.debugInfo_tlbRespTime;
  assign io_splitLoadReq_bits_uop_debug_seqNum_seqNum = split_req.uop.debug_seqNum_seqNum;
  assign io_splitLoadReq_bits_uop_debug_seqNum_uopIdx = split_req.uop.debug_seqNum_uopIdx;
  assign io_splitLoadReq_bits_uop_storeSetHit = split_req.uop.storeSetHit;
  assign io_splitLoadReq_bits_uop_waitForRobIdx_flag = split_req.uop.waitForRobIdx_flag;
  assign io_splitLoadReq_bits_uop_waitForRobIdx_value = split_req.uop.waitForRobIdx_value;
  assign io_splitLoadReq_bits_uop_loadWaitBit = split_req.uop.loadWaitBit;
  assign io_splitLoadReq_bits_uop_loadWaitStrict = split_req.uop.loadWaitStrict;
  assign io_splitLoadReq_bits_uop_ssid = split_req.uop.ssid;
  assign io_splitLoadReq_bits_uop_lqIdx_flag = split_req.uop.lqIdx_flag;
  assign io_splitLoadReq_bits_uop_lqIdx_value = split_req.uop.lqIdx_value;
  assign io_splitLoadReq_bits_uop_sqIdx_flag = split_req.uop.sqIdx_flag;
  assign io_splitLoadReq_bits_uop_sqIdx_value = split_req.uop.sqIdx_value;
  assign io_splitLoadReq_bits_uop_singleStep = split_req.uop.singleStep;
  assign io_splitLoadReq_bits_uop_replayInst = split_req.uop.replayInst;
  assign io_splitLoadReq_bits_uop_debug_fuType = split_req.uop.debug_fuType;
  assign io_splitLoadReq_bits_uop_debug_sim_trig = split_req.uop.debug_sim_trig;
  assign io_splitLoadReq_bits_uop_numLsElem = split_req.uop.numLsElem;
  assign io_splitLoadReq_bits_vaddr = split_req.vaddr;
  assign io_splitLoadReq_bits_fullva = split_req.fullva;
  assign io_splitLoadReq_bits_vaNeedExt = split_req.vaNeedExt;
  assign io_splitLoadReq_bits_paddr = split_req.paddr;
  assign io_splitLoadReq_bits_gpaddr = split_req.gpaddr;
  assign io_splitLoadReq_bits_mask = split_req.mask;
  assign io_splitLoadReq_bits_nc = split_req.nc;
  assign io_splitLoadReq_bits_mmio = split_req.mmio;
  assign io_splitLoadReq_bits_memBackTypeMM = split_req.memBackTypeMM;
  assign io_splitLoadReq_bits_isForVSnonLeafPTE = split_req.isForVSnonLeafPTE;
  assign io_splitLoadReq_bits_isvec = split_req.isvec;
  assign io_splitLoadReq_bits_is128bit = split_req.is128bit;
  assign io_splitLoadReq_bits_vecActive = split_req.vecActive;
  assign io_splitLoadReq_bits_mshrid = split_req.mshrid;
  assign io_splitLoadReq_bits_schedIndex = split_req.schedIndex;
  assign io_splitLoadReq_bits_isFinalSplit = split_req.isFinalSplit;
  assign io_splitLoadReq_bits_misalignNeedWakeUp = split_req.misalignNeedWakeUp;
  assign io_writeBack_bits_uop_exceptionVec_3 = wb.uop.exceptionVec[3];
  assign io_writeBack_bits_uop_exceptionVec_4 = wb.uop.exceptionVec[4];
  assign io_writeBack_bits_uop_exceptionVec_5 = wb.uop.exceptionVec[5];
  assign io_writeBack_bits_uop_exceptionVec_13 = wb.uop.exceptionVec[13];
  assign io_writeBack_bits_uop_exceptionVec_19 = wb.uop.exceptionVec[19];
  assign io_writeBack_bits_uop_exceptionVec_21 = wb.uop.exceptionVec[21];
  assign io_writeBack_bits_uop_trigger = wb.uop.trigger;
  assign io_writeBack_bits_uop_preDecodeInfo_valid = wb.uop.preDecodeInfo_valid;
  assign io_writeBack_bits_uop_preDecodeInfo_isRVC = wb.uop.preDecodeInfo_isRVC;
  assign io_writeBack_bits_uop_preDecodeInfo_brType = wb.uop.preDecodeInfo_brType;
  assign io_writeBack_bits_uop_preDecodeInfo_isCall = wb.uop.preDecodeInfo_isCall;
  assign io_writeBack_bits_uop_preDecodeInfo_isRet = wb.uop.preDecodeInfo_isRet;
  assign io_writeBack_bits_uop_rfWen = wb.uop.rfWen;
  assign io_writeBack_bits_uop_fpWen = wb.uop.fpWen;
  assign io_writeBack_bits_uop_pdest = wb.uop.pdest;
  assign io_writeBack_bits_uop_robIdx_flag = wb.uop.robIdx_flag;
  assign io_writeBack_bits_uop_robIdx_value = wb.uop.robIdx_value;
  assign io_writeBack_bits_uop_debugInfo_eliminatedMove = wb.uop.debugInfo_eliminatedMove;
  assign io_writeBack_bits_uop_debugInfo_renameTime = wb.uop.debugInfo_renameTime;
  assign io_writeBack_bits_uop_debugInfo_dispatchTime = wb.uop.debugInfo_dispatchTime;
  assign io_writeBack_bits_uop_debugInfo_enqRsTime = wb.uop.debugInfo_enqRsTime;
  assign io_writeBack_bits_uop_debugInfo_selectTime = wb.uop.debugInfo_selectTime;
  assign io_writeBack_bits_uop_debugInfo_issueTime = wb.uop.debugInfo_issueTime;
  assign io_writeBack_bits_uop_debugInfo_writebackTime = wb.uop.debugInfo_writebackTime;
  assign io_writeBack_bits_uop_debugInfo_runahead_checkpoint_id = wb.uop.debugInfo_runahead_checkpoint_id;
  assign io_writeBack_bits_uop_debugInfo_tlbFirstReqTime = wb.uop.debugInfo_tlbFirstReqTime;
  assign io_writeBack_bits_uop_debugInfo_tlbRespTime = wb.uop.debugInfo_tlbRespTime;
  assign io_writeBack_bits_uop_debug_seqNum_seqNum = wb.uop.debug_seqNum_seqNum;
  assign io_writeBack_bits_uop_debug_seqNum_uopIdx = wb.uop.debug_seqNum_uopIdx;
  assign io_writeBack_bits_uop_lqIdx_flag = wb.uop.lqIdx_flag;
  assign io_writeBack_bits_uop_lqIdx_value = wb.uop.lqIdx_value;
  assign io_writeBack_bits_data = wb.data;
  assign io_writeBack_bits_debug_isMMIO = wb.debug_isMMIO;
  assign io_writeBack_bits_debug_isNCIO = wb.debug_isNCIO;
  assign io_writeBack_bits_debug_paddr = wb.debug_paddr;
  assign io_writeBack_bits_debug_vaddr = wb.debug_vaddr;
  assign io_vecWriteBack_bits_mBIndex = vec_wb.mBIndex;
  assign io_vecWriteBack_bits_exceptionVec_3 = vec_wb.exceptionVec[3];
  assign io_vecWriteBack_bits_exceptionVec_4 = vec_wb.exceptionVec[4];
  assign io_vecWriteBack_bits_exceptionVec_5 = vec_wb.exceptionVec[5];
  assign io_vecWriteBack_bits_exceptionVec_13 = vec_wb.exceptionVec[13];
  assign io_vecWriteBack_bits_exceptionVec_19 = vec_wb.exceptionVec[19];
  assign io_vecWriteBack_bits_exceptionVec_21 = vec_wb.exceptionVec[21];
  assign io_vecWriteBack_bits_hasException = vec_wb.hasException;
  assign io_vecWriteBack_bits_vaddr = vec_wb.vaddr;
  assign io_vecWriteBack_bits_vaNeedExt = vec_wb.vaNeedExt;
  assign io_vecWriteBack_bits_gpaddr = vec_wb.gpaddr;
  assign io_vecWriteBack_bits_isForVSnonLeafPTE = vec_wb.isForVSnonLeafPTE;
  assign io_vecWriteBack_bits_vstart = vec_wb.vstart;
  assign io_vecWriteBack_bits_vecTriggerMask = vec_wb.vecTriggerMask;
  assign io_vecWriteBack_bits_elemIdx = vec_wb.elemIdx;
  assign io_vecWriteBack_bits_mask = vec_wb.mask;
  assign io_vecWriteBack_bits_alignedType = vec_wb.alignedType;
  assign io_vecWriteBack_bits_elemIdxInsideVd = vec_wb.elemIdxInsideVd;
  assign io_vecWriteBack_bits_vecdata = vec_wb.vecdata;

  xs_LoadMisalignBuffer_core u_core (
    .clock (clock),
    .reset (reset),
    .redirect_valid (io_redirect_valid),
    .split_req_ready (io_splitLoadReq_ready),
    .split_req_valid (io_splitLoadReq_valid),
    .split_resp_valid (io_splitLoadResp_valid),
    .wb_ready (io_writeBack_ready),
    .wb_valid (io_writeBack_valid),
    .vec_wb_valid (io_vecWriteBack_valid),
    .load_out_valid (io_loadOutValid),
    .load_vec_out_valid (io_loadVecOutValid),
    .enq_valid (enq_valid),
    .enq_ready (enq_ready),
    .redirect (redirect),
    .enq_bits (enq_bits),
    .split_req (split_req),
    .split_resp (split_resp),
    .wb (wb),
    .vec_wb (vec_wb)
  );

endmodule
// END GENERATED(wrapper)
