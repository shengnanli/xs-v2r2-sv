// =====================================================================
// vlsu_pkg.sv —— 向量访存单元（VLSU：拆分 VSplit 家族 + segment 单元）的公共包：常量、小函数、接口 struct
// ---------------------------------------------------------------------
// 使用者：xs_VSplitPipeline_core（拆分流水，VLSplitPipelineImp.sv）、xs_VSplitBuffer_core（拆分缓冲，
//   VLSplitBufferImp.sv）、它们的 load / store 变体 wrapper、装配壳 VLSplitImp / VSSplitImp，
//   以及 segment 访存单元 xs_VSegmentUnit_core（VSegmentUnit.sv）。
// 内容：
//   · 规模常量、特殊 unit-stride 操作码、异常掩码、stop-and-wait 状态编码；
//   · 拆分流水用的小函数（uop 下标、掩码生成、步长乘法）与拆分缓冲用的小函数
//     （访问掩码、index 元素提取、store 数据提取）；
//   · GENERATED(types)：uop_t / vls_t（一条"读懂了的向量 uop"，Chisel 的 VLSBundle）等拆分家族的接口
//     struct，成员 = 各模块 golden 端口表与寄存器表的并集（scripts/gen_vsplit.py 生成）；
//     某个模块 / 变体没有的成员由它的 wrapper 补 0 或不接。segment 单元的接口 struct 在 vsegment_pkg.sv。
// 为什么单独成文件：这个包被多个模块文件共用，按 CONVENTIONS 不能藏在某个兄弟模块文件里
//   （scripts/check_pkg_scope.py 判据 B：包名与文件名相同的独立文件是合法落点）。
// =====================================================================

package vlsu_pkg;

  localparam int VLEN  = 128;
  localparam int VLENB = 16;      // VLEN/8：一个向量寄存器的字节数，也是一条 uop 最多的元素数
  localparam int XLEN  = 64;

  // 环形指针"是否该被这次 redirect 冲掉"（RobPtr.needFlush）：
  //   redirect 有效，且（level=1 表示连 redirect 指令自己也冲，此时相等也算）或本指令比它年轻。
  //   年轻判定 isAfter：flag 不同则 value 小者年轻，flag 相同则 value 大者年轻 → 三项异或。
  function automatic logic rob_need_flush(
      input logic       flag,
      input logic [7:0] value,
      input logic       rd_valid,
      input logic       rd_level,
      input logic       rd_flag,
      input logic [7:0] rd_value);
    return rd_valid & (rd_level & ({flag, value} == {rd_flag, rd_value})
                       | (flag ^ rd_flag ^ (value > rd_value)));
  endfunction

  // ------------------------------------------------------------------
  // 拆分流水（VSplitPipeline）用
  // ------------------------------------------------------------------

  // ---- 特殊 unit-stride 操作码（VlduType / VstuType）----
  localparam logic [8:0] VLDU_VLR   = 9'h088;   // vl<nf>re<eew>.v  整寄存器 load
  localparam logic [8:0] VLDU_VLM   = 9'h08B;   // vlm.v            mask load
  localparam logic [8:0] VLDU_VLEFF = 9'h090;   // vle<eew>ff.v     fault-only-first
  localparam logic [8:0] VSTU_VSR   = 9'h108;   // vs<nf>r.v        整寄存器 store
  localparam logic [8:0] VSTU_VSM   = 9'h10B;   // vsm.v            mask store

  // ---- mop（fuOpType[6:5]）= instType[1:0]；instType[2] = segment ----
  localparam logic [1:0] MOP_UNIT_STRIDE = 2'b00;
  localparam logic [1:0] MOP_STRIDED     = 2'b10;
  localparam logic [1:0] MOP_ORDER_INDEX = 2'b11;   // 01 = 无序 indexed；bit0=1 即 indexed

  // 倍数（emul / lmul，3 位有符号：-3..3 表示 1/8..8）里"一个 field 占几个 uop"对应的 uopIdx 低位：
  // mul=1/2/3（2/4/8 个寄存器）取 uopIdx 的低 1/2/3 位，其余（<=1 个寄存器）为 0。
  function automatic logic [2:0] uop_idx_in_field(input logic [2:0] mul, input logic [6:0] uopIdx);
    case (mul)
      3'b001:  return {2'b0, uopIdx[0]};
      3'b010:  return {1'b0, uopIdx[1:0]};
      3'b011:  return uopIdx[2:0];
      default: return 3'b0;
    endcase
  endfunction

  // 负的倍数（分数 LMUL）原样保留，非负的当 0：算"一条 uop 里有几个元素"的 log2 时用
  function automatic logic [2:0] mul_frac_only(input logic [2:0] mul);
    return ($signed(mul) >= 0) ? 3'b0 : mul;
  endfunction

  // UIntToMask(n)：低 n 位为 1 的 128 位掩码（n >= 128 时全 1）
  function automatic logic [VLEN-1:0] low_ones(input logic [10:0] n);
    logic [2047:0] one_hot;
    one_hot = 2048'h1 << n;
    return one_hot[VLEN-1:0] - 128'h1;
  endfunction

  // FillInterleaved(2^alignedType, flowMask) 的低 16 位：每个元素的 mask 位展开成它占的字节数
  function automatic logic [VLENB-1:0] flow_to_byte_mask(input logic [VLENB-1:0] flowMask,
                                                         input logic [1:0]       alignedType);
    logic [VLENB-1:0] m;
    for (int b = 0; b < VLENB; b++) begin
      case (alignedType)
        2'd0:    m[b] = flowMask[b];
        2'd1:    m[b] = flowMask[b / 2];
        2'd2:    m[b] = flowMask[b / 4];
        default: m[b] = flowMask[b / 8];
      endcase
    end
    return m;
  endfunction

  // strided 指令：第 k 条 uop 的地址偏移 = k * stride（k = 0..7，查表式的移位加；k > 7 得 0）。
  // 结果只用低 64 位。
  function automatic logic [XLEN-1:0] stride_times(input logic [6:0] k, input logic [XLEN-1:0] s);
    case (k)
      7'd1:    return s;
      7'd2:    return s << 1;
      7'd3:    return (s << 1) + s;
      7'd4:    return s << 2;
      7'd5:    return (s << 2) + s;
      7'd6:    return (s << 2) + (s << 1);
      7'd7:    return (s << 2) + ((s << 1) + s);
      default: return '0;
    endcase
  endfunction

  // ------------------------------------------------------------------
  // 拆分缓冲（VSplitBuffer）用
  // ------------------------------------------------------------------

  localparam int SQ_SIZE = 56;     // StoreQueueSize
  localparam int LQ_SIZE = 72;     // VirtualLoadQueueSize

  // 本功能单元能报的异常（ExceptionNO.selectByFu）
  //   load : breakPoint(3) loadAddrMisaligned(4) loadAccessFault(5) loadPageFault(13)
  //          hardwareError(19) loadGuestPageFault(21)
  //   store: breakPoint(3) storeAddrMisaligned(6) storeAccessFault(7) storePageFault(15)
  //          hardwareError(19) storeGuestPageFault(23)
  localparam logic [23:0] VLDU_EXC_MASK = 24'h28_2038;
  localparam logic [23:0] VSTU_EXC_MASK = 24'h88_80C8;
  localparam int EXC_LD_ADDR_MISALIGN = 4;
  localparam int EXC_ST_ADDR_MISALIGN = 6;

  // 有序 indexed load 的 stop-and-wait 状态
  localparam logic [1:0] SW_IDLE = 2'd0;   // 普通指令恒在此
  localparam logic [1:0] SW_SEND = 2'd1;   // 上一个元素已写回，可以发下一个
  localparam logic [1:0] SW_STOP = 2'd2;   // 已发一个元素，等它写回

  // 访问宽度对应的字节掩码，左移到 16B 窗口里的起始位置（genVWmask128）。
  // sizeEncode：0..3 = 1/2/4/8 字节，4（和 7）= 16 字节，5/6 无定义 → 0。
  function automatic logic [VLENB-1:0] access_mask128(input logic [3:0] addr_low, input logic [2:0] size);
    logic [VLENB-1:0] base;
    case (size)
      3'd0:    base = 16'h0001;
      3'd1:    base = 16'h0003;
      3'd2:    base = 16'h000F;
      3'd3:    base = 16'h00FF;
      3'd4:    base = 16'hFFFF;
      3'd7:    base = 16'hFFFF;
      default: base = 16'h0000;
    endcase
    return base << addr_low;
  endfunction

  // indexed 指令：从 128 位 index 向量里取第 idx 个下标（宽度 eew），零扩展到 64 位（IndexAddr）。
  // idx 超出一个寄存器能放的个数时得 0。
  function automatic logic [XLEN-1:0] index_elem(input logic [VLEN-1:0] vec, input logic [7:0] idx,
                                                 input logic [1:0] eew);
    logic [XLEN-1:0] r;
    r = '0;
    case (eew)
      2'd0:    for (int i = 0; i < 16; i++) if (idx == 8'(i)) r = XLEN'(vec[i*8  +: 8]);
      2'd1:    for (int i = 0; i < 8;  i++) if (idx == 8'(i)) r = XLEN'(vec[i*16 +: 16]);
      2'd2:    for (int i = 0; i < 4;  i++) if (idx == 8'(i)) r = XLEN'(vec[i*32 +: 32]);
      default: for (int i = 0; i < 2;  i++) if (idx == 8'(i)) r = vec[i*64 +: 64];
    endcase
    return r;
  endfunction

  // store 数据：从 128 位 vs3 里取第 elemIdx 个元素（genVSData），再复制铺满 128 位（genVWdata）。
  // alignedType：0..3 = 1/2/4/8 字节元素，4 = 整个 128 位；5..7 无定义 → 0。
  function automatic logic [VLEN-1:0] store_elem_data(input logic [VLEN-1:0] data, input logic [4:0] elemIdx,
                                                      input logic [2:0] alignedType);
    logic [VLEN-1:0] r;
    r = '0;
    case (alignedType)
      3'd0:    for (int i = 0; i < 16; i++) if (elemIdx[3:0] == 4'(i)) r = {16{data[i*8  +: 8]}};
      3'd1:    for (int i = 0; i < 8;  i++) if (elemIdx[2:0] == 3'(i)) r = {8{data[i*16 +: 16]}};
      3'd2:    for (int i = 0; i < 4;  i++) if (elemIdx[1:0] == 2'(i)) r = {4{data[i*32 +: 32]}};
      3'd3:    for (int i = 0; i < 2;  i++) if (elemIdx[0]   == 1'(i)) r = {2{data[i*64 +: 64]}};
      3'd4:    r = data;
      default: r = '0;
    endcase
    return r;
  endfunction

  // BEGIN GENERATED(types) —— scripts/gen_vsplit.py 生成，勿手改
  // 微操作信息（DynInst 在拆分流水 / 拆分缓冲各接口与寄存器里留下的字段并集）
  typedef struct packed {
    logic [49:0]   pc;
    logic          ftqPtr_flag;
    logic [5:0]    ftqPtr_value;
    logic [3:0]    ftqOffset;
    logic [34:0]   fuType;
    logic [8:0]    fuOpType;
    logic          vecWen;
    logic          v0Wen;
    logic          vlWen;
    logic          vpu_vill;
    logic          vpu_vma;
    logic          vpu_vta;
    logic [1:0]    vpu_vsew;
    logic [2:0]    vpu_vlmul;
    logic          vpu_specVill;
    logic          vpu_specVma;
    logic          vpu_specVta;
    logic [1:0]    vpu_specVsew;
    logic [2:0]    vpu_specVlmul;
    logic          vpu_vm;
    logic [7:0]    vpu_vstart;
    logic [2:0]    vpu_frm;
    logic          vpu_fpu_isFpToVecInst;
    logic          vpu_fpu_isFP32Instr;
    logic          vpu_fpu_isFP64Instr;
    logic          vpu_fpu_isReduction;
    logic          vpu_fpu_isFoldTo1_2;
    logic          vpu_fpu_isFoldTo1_4;
    logic          vpu_fpu_isFoldTo1_8;
    logic [1:0]    vpu_vxrm;
    logic [6:0]    vpu_vuopIdx;
    logic          vpu_lastUop;
    logic [127:0]  vpu_vmask;
    logic [2:0]    vpu_nf;
    logic [1:0]    vpu_veew;
    logic          vpu_isReverse;
    logic          vpu_isExt;
    logic          vpu_isNarrow;
    logic          vpu_isDstMask;
    logic          vpu_isOpMask;
    logic          vpu_isMove;
    logic          vpu_isDependOldVd;
    logic          vpu_isWritePartVd;
    logic          vpu_isVleff;
    logic [7:0]    pdest;
    logic          robIdx_flag;
    logic [7:0]    robIdx_value;
    logic          debugInfo_eliminatedMove;
    logic [63:0]   debugInfo_renameTime;
    logic [63:0]   debugInfo_dispatchTime;
    logic [63:0]   debugInfo_enqRsTime;
    logic [63:0]   debugInfo_selectTime;
    logic [63:0]   debugInfo_issueTime;
    logic [63:0]   debugInfo_writebackTime;
    logic [63:0]   debugInfo_runahead_checkpoint_id;
    logic [63:0]   debugInfo_tlbFirstReqTime;
    logic [63:0]   debugInfo_tlbRespTime;
    logic [55:0]   debug_seqNum_seqNum;
    logic [7:0]    debug_seqNum_uopIdx;
    logic          lqIdx_flag;
    logic [6:0]    lqIdx_value;
    logic          sqIdx_flag;
    logic [5:0]    sqIdx_value;
    logic [4:0]    numLsElem;
    logic [7:0]    vpu_vl;
    logic [6:0]    uopIdx;
    logic          lastUop;
    logic [6:0]    numUops;
    logic [31:0]   instr;
    logic [9:0]    foldpc;
    logic [23:0]   exceptionVec;
    logic          isFetchMalAddr;
    logic          hasException;
    logic [3:0]    trigger;
    logic          preDecodeInfo_valid;
    logic          preDecodeInfo_isRVC;
    logic [1:0]    preDecodeInfo_brType;
    logic          preDecodeInfo_isCall;
    logic          preDecodeInfo_isRet;
    logic          pred_taken;
    logic          crossPageIPFFix;
    logic          satpFlushFirstFetchFault;
    logic [3:0]    srcType_0;
    logic [3:0]    srcType_1;
    logic [3:0]    srcType_2;
    logic [3:0]    srcType_3;
    logic [3:0]    srcType_4;
    logic [5:0]    ldest;
    logic          rfWen;
    logic          fpWen;
    logic          isXSTrap;
    logic          waitForward;
    logic          blockBackward;
    logic          canRobCompress;
    logic [3:0]    selImm;
    logic [1:0]    fpu_typeTagOut;
    logic          fpu_wflags;
    logic [1:0]    fpu_typ;
    logic [1:0]    fpu_fmt;
    logic [2:0]    fpu_rm;
    logic          vlsInstr;
    logic          wfflags;
    logic          isMove;
    logic          isDropAmocasSta;
    logic          isVset;
    logic          firstUop;
    logic [6:0]    numWB;
    logic [2:0]    commitType;
    logic          srcState_0;
    logic          srcState_1;
    logic          srcState_2;
    logic          srcState_3;
    logic          srcState_4;
    logic [1:0]    srcLoadDependency_0_0;
    logic [1:0]    srcLoadDependency_0_1;
    logic [1:0]    srcLoadDependency_0_2;
    logic [1:0]    srcLoadDependency_1_0;
    logic [1:0]    srcLoadDependency_1_1;
    logic [1:0]    srcLoadDependency_1_2;
    logic [1:0]    srcLoadDependency_2_0;
    logic [1:0]    srcLoadDependency_2_1;
    logic [1:0]    srcLoadDependency_2_2;
    logic [1:0]    srcLoadDependency_3_0;
    logic [1:0]    srcLoadDependency_3_1;
    logic [1:0]    srcLoadDependency_3_2;
    logic [1:0]    srcLoadDependency_4_0;
    logic [1:0]    srcLoadDependency_4_1;
    logic [1:0]    srcLoadDependency_4_2;
    logic [7:0]    psrc_0;
    logic [7:0]    psrc_1;
    logic [7:0]    psrc_2;
    logic [7:0]    psrc_3;
    logic [7:0]    psrc_4;
    logic          useRegCache_0;
    logic          useRegCache_1;
    logic [4:0]    regCacheIdx_0;
    logic [4:0]    regCacheIdx_1;
    logic [2:0]    instrSize;
    logic          dirtyFs;
    logic          dirtyVs;
    logic [3:0]    traceBlockInPipe_itype;
    logic [3:0]    traceBlockInPipe_iretire;
    logic          traceBlockInPipe_ilastsize;
    logic          eliminatedMove;
    logic          snapshot;
    logic          storeSetHit;
    logic          waitForRobIdx_flag;
    logic [7:0]    waitForRobIdx_value;
    logic          loadWaitBit;
    logic          loadWaitStrict;
    logic [4:0]    ssid;
    logic          singleStep;
    logic          replayInst;
    logic [34:0]   debug_fuType;
    logic          debug_sim_trig;
  } uop_t;

  // 发射队列来的向量访存 uop（src_0=基址 rs1，src_1=stride / index 向量，src_2=store 数据，src_3=v0 mask，src_4=vl）
  typedef struct packed {
    uop_t          uop;
    logic [127:0]  src_0;
    logic [127:0]  src_1;
    logic [127:0]  src_2;
    logic [127:0]  src_3;
    logic [127:0]  src_4;
    logic [4:0]    flowNum;
    logic          isVecPartReplay;
    logic [15:0]   vecReplayMask;
    logic [3:0]    vecReplayMbIdx;
  } split_in_t;

  // 一条"读懂了的"向量访存 uop（VLSBundle）：拆分流水 s1 → skid → 拆分缓冲
  typedef struct packed {
    uop_t          uop;
    logic [15:0]   flowMask;
    logic [127:0]  data;
    logic [63:0]   baseAddr;
    logic [63:0]   uopAddr;
    logic [127:0]  stride;
    logic [4:0]    flowNum;
    logic [1:0]    eew;
    logic [2:0]    sew;
    logic [2:0]    emul;
    logic [2:0]    lmul;
    logic [2:0]    instType;
    logic [4:0]    indexedSplitOffset;
    logic          preIsSplit;
    logic [3:0]    mBIndex;
    logic [2:0]    alignedType;
    logic [7:0]    indexVlMaxInVd;
    logic [3:0]    usLowBitsAddr;
    logic          usAligned128;
    logic [31:0]   usMask;
    logic          isVecPartReplay;
    logic [15:0]   vecReplayFlowMask;
    logic [15:0]   byteMask;
    logic [3:0]    nfields;
    logic [7:0]    vlmax;
    logic [2:0]    rawNf;
    logic [15:0]   indexedSrcMask;
    logic          fof;
    logic [2:0]    vdIdxInField;
    logic [3:0]    vecReplayMbIdx;
  } vls_t;

  // 向合并缓冲申请条目（FromSplitIO.req）
  typedef struct packed {
    uop_t          uop;
    logic [15:0]   mask;
    logic [49:0]   vaddr;
    logic [4:0]    flowNum;
    logic [127:0]  data;
    logic [2:0]    vdIdx;
    logic          fof;
    logic [7:0]    vlmax;
  } merge_req_t;

  // 发给标量访存流水的一个访问（VecPipeBundle）
  typedef struct packed {
    uop_t          uop;
    logic [63:0]   vaddr;
    logic [49:0]   basevaddr;
    logic [15:0]   mask;
    logic [3:0]    reg_offset;
    logic [2:0]    alignedType;
    logic          vecActive;
    logic          vecIsFirstActiveElement;
    logic [3:0]    mBIndex;
    logic [7:0]    elemIdx;
    logic [7:0]    elemIdxInsideVd;
    logic [4:0]    splitIndex;
  } vec_pipe_t;

  // 送 store queue 的元素数据（只有 store）
  typedef struct packed {
    uop_t          uop;
    logic [127:0]  data;
    logic [5:0]    vecDebug_offset;
  } vstd_t;
  // END GENERATED(types)

endpackage
