// =============================================================================
//  mshr_pkg —— coupledL2 (tl2chi) L2 缓存 MSHR 状态机的常量 / 编码 / 类型定义
// -----------------------------------------------------------------------------
//  本包给 xs_MSHR_core 提供「可读名字」的协议常量, 全部对照 Scala 设计意图:
//    - coupledL2/Consts.scala            (MetaData: cache 行一致性状态 I/B/T/Tip)
//    - rocket-chip TLPermissions          (Probe/Acquire/Release 的 cap/grow/shrink)
//    - coupledL2/tl2chi/chi/Opcode.scala  (CHI REQ/RSP/DAT/SNP opcode)
//    - coupledL2/tl2chi/chi (CHICohStates: I/SC/UC/UD/...)
//
//  参数取自 firtool 单态化后的 MSHR.sv (KunmingHu V2R2 配置):
//    mshrBits=8, stateBits=2, clientBits=1, beatSize=2(beatCnt 1bit),
//    NODEID_WIDTH=11, TXNID_WIDTH=12, OPCODE_WIDTH=7, PCRDTYPE_WIDTH=4,
//    afterIssueC=true, afterIssueEb=true, enableNS=false。
// =============================================================================
package mshr_pkg;

  // ---------------- 位宽参数 ----------------
  localparam int MSHR_BITS      = 8;   // io_id 宽度
  localparam int STATE_BITS     = 2;   // cache 行一致性状态
  localparam int SET_BITS       = 9;
  localparam int TAG_BITS       = 31;
  localparam int OFF_BITS       = 6;
  localparam int ALIAS_BITS     = 2;
  localparam int SOURCEID_BITS  = 7;
  localparam int REQSRC_BITS    = 5;
  localparam int NODEID_WIDTH   = 11;  // CHI SrcID/TgtID
  localparam int TXNID_WIDTH    = 12;  // CHI TxnID/DBID
  localparam int OPCODE_WIDTH   = 7;   // CHI opcode
  localparam int PCRDTYPE_WIDTH = 4;
  localparam int PFSRC_BITS     = 3;

  // ---------------- MetaData: cache 行一致性状态 (Consts.scala) ----------------
  //  INVALID: 空; BRANCH: 共享(只读); TRUNK: 内层 master 独占; TIP: 本级独占顶端
  localparam logic [STATE_BITS-1:0] INVALID = 2'd0;
  localparam logic [STATE_BITS-1:0] BRANCH  = 2'd1;
  localparam logic [STATE_BITS-1:0] TRUNK   = 2'd2;
  localparam logic [STATE_BITS-1:0] TIP     = 2'd3;

  // isT(state) = state[1] : TRUNK/TIP 都属于"独占"(T) 系
  function automatic logic isT(input logic [STATE_BITS-1:0] s);
    return s[1];
  endfunction

  // ---------------- TL Permissions (rocket-chip Bundles.scala) ----------------
  // cap (Probe.param 给上层的目标态)
  localparam logic [1:0] toT = 2'd0;
  localparam logic [1:0] toB = 2'd1;
  localparam logic [1:0] toN = 2'd2;
  // grow (Acquire.param: 从->到)
  localparam logic [2:0] NtoB = 3'd0;
  localparam logic [2:0] NtoT = 3'd1;
  localparam logic [2:0] BtoT = 3'd2;
  // report/prune (Release/ProbeAck.param)
  localparam logic [2:0] TtoB = 3'd0;
  localparam logic [2:0] TtoN = 3'd1;
  localparam logic [2:0] BtoN = 3'd2;
  localparam logic [2:0] TtoT = 3'd3;
  localparam logic [2:0] BtoB = 3'd4;
  localparam logic [2:0] NtoN = 3'd5;

  // C 通道 (ProbeAck) param 判定: 来自 sinkC, 3bit
  // isToN: 目标 N -> param ∈ {TtoN=1, NtoN=5}? 实际 golden: param ∈ {0,4} 走 "保持/降 TIP"
  //   注意 golden 把语义压平: 详见核内注释。这里给纯函数。
  function automatic logic c_isToN(input logic [2:0] p);  // 收缩到 N
    return p == TtoN || p == BtoN || p == NtoN;
  endfunction
  function automatic logic c_isToB(input logic [2:0] p);  // 收缩到 B
    return p == TtoB || p == BtoB;
  endfunction
  function automatic logic c_isParamFromT(input logic [2:0] p); // 原态是 T (TtoB/TtoN/TtoT)
    return p == TtoB || p == TtoN || p == TtoT;
  endfunction

  // ---------------- TL A/C opcode (本级用到的几个) ----------------
  localparam logic [3:0] Get          = 4'd4;
  localparam logic [3:0] AcquireBlock = 4'd6;
  localparam logic [3:0] AcquirePerm  = 4'd7;
  localparam logic [3:0] Hint         = 4'd5;  // 预取
  localparam logic [3:0] CBOClean     = 4'hC;  // golden: req_opcode==4'hC
  localparam logic [3:0] CBOFlush     = 4'hD;  // golden: req_opcode==4'hD
  localparam logic [3:0] CBOInval     = 4'hE;  // golden: req_opcode==4'hE
  // ProbeAck / ProbeAckData (sinkC opcode, 3bit)
  localparam logic [2:0] ProbeAck     = 3'd4;
  localparam logic [2:0] ProbeAckData = 3'd5;
  // odOpGen: A.opcode -> D.opcode (Grant/MainPipe 回包 opcode), 完全对照 golden _GEN[] 查表
  //   0->0,1->0,2->1,3->1,4(Get)->1(AccessAckData),5(Hint)->2(HintAck),
  //   6(AcquireBlock)->5(GrantData),7(AcquirePerm)->4(Grant),8..11->0,
  //   12/13/14(CBO Clean/Flush/Inval)->8(CBOAck),15->0
  function automatic logic [3:0] odOpGen(input logic [3:0] a);
    unique case (a)
      4'h2,4'h3,4'h4: return 4'h1;  // AccessAckData
      4'h5:           return 4'h2;  // HintAck
      4'h6:           return 4'h5;  // GrantData
      4'h7:           return 4'h4;  // Grant
      4'hC,4'hD,4'hE: return 4'h8;  // CBOAck
      default:        return 4'h0;
    endcase
  endfunction
  localparam logic [3:0] CBOAck = 4'h8;  // mp_grant.opcode==CBOAck -> s_cmoresp:=1

  // ---------------- CHI 一致性态 (CHICohStates) ----------------
  localparam logic [2:0] CHI_I     = 3'd0;
  localparam logic [2:0] CHI_SC    = 3'd1;  // Shared Clean
  localparam logic [2:0] CHI_UC    = 3'd2;  // Unique Clean
  localparam logic [2:0] CHI_UD    = 3'd6;  // Unique Dirty  (= UC|PassDirty)
  localparam logic [2:0] CHI_UC_PD = 3'd6;  // rxdat resp==UC_PD
  localparam logic       PASS_DIRTY_BIT = 1'b1; // setPD: bit[2]

  // setPD(state, passDirty): CHI resp 把 passDirty 放最高位
  function automatic logic [2:0] setPD(input logic [2:0] st, input logic pd);
    return {pd, st[1:0]};
  endfunction

  // ---------------- CHI REQ opcode (Opcode.scala, 单态化后的具体值) ----------------
  localparam logic [6:0] ReadNotSharedDirty = 7'h26;
  localparam logic [6:0] ReadUnique         = 7'h7;
  localparam logic [6:0] MakeUnique         = 7'hC;
  localparam logic [6:0] CleanShared        = 7'h8;  // (req_cboClean 走 WriteCleanFull? 见 txreq opcode)
  localparam logic [6:0] CleanInvalid       = 7'h9;
  localparam logic [6:0] MakeInvalid        = 7'hA;
  localparam logic [6:0] Evict_CHI          = 7'hD;
  localparam logic [6:0] WriteBackFull      = 7'h1B;
  localparam logic [6:0] WriteCleanFull     = 7'h17;
  localparam logic [6:0] WriteEvictFull     = 7'h15;
  localparam logic [6:0] WriteEvictOrEvict  = 7'h42;

  // ---------------- CHI RSP/DAT opcode (response 通道) ----------------
  localparam logic [6:0] CompData      = 7'h4;   // rxdat
  localparam logic [6:0] DataSepResp   = 7'hB;   // rxdat (afterIssueC)
  localparam logic [6:0] Comp          = 7'h4;   // rxrsp
  localparam logic [6:0] CompDBIDResp  = 7'h5;   // rxrsp
  localparam logic [6:0] RetryAck      = 7'h3;   // rxrsp
  localparam logic [6:0] RespSepData   = 7'hB;   // rxrsp (afterIssueC)
  localparam logic [6:0] PCrdGrant     = 7'h7;   // rxrsp
  localparam logic [6:0] CompAck       = 7'h0;   // txrsp opcode (恒)
  localparam logic [6:0] CopyBackWrData= 7'h2;   // mp_cbwrdata chiOpcode (DAT 通道)
  localparam logic [6:0] CompData_DAT  = 7'h4;   // mp_dct chiOpcode (= CompData)
  // mp_probeack chiOpcode: SnpResp(1)/SnpRespFwded(6)/SnpRespData(1,DAT)/SnpRespDataFwded(6,DAT)
  //   golden 用 {doFwd, doRespData} 2bit 查表, 编码见核内
  localparam logic [6:0] SnpResp_RSP       = 7'h1;
  localparam logic [6:0] SnpRespFwded_RSP  = 7'h9;
  localparam logic [6:0] SnpRespData_DAT   = 7'h1;
  localparam logic [6:0] SnpRespDataFwded_DAT = 7'h6;

  // ---------------- CHI SNP opcode 与 SnpTo* 分类 (req.chiOpcode, 7bit) ----------------
  //  golden 已把以下判定压平为具体常量比较, 这里给可读分类函数。
  localparam logic [6:0] SnpOnce            = 7'h3;
  localparam logic [6:0] SnpOnceFwd         = 7'h13;
  localparam logic [6:0] SnpClean           = 7'h2;
  localparam logic [6:0] SnpCleanFwd        = 7'h12;
  localparam logic [6:0] SnpNotSharedDirty  = 7'h4;
  localparam logic [6:0] SnpNotSharedDirtyFwd = 7'h14;
  localparam logic [6:0] SnpShared          = 7'h1;
  localparam logic [6:0] SnpSharedFwd       = 7'h11;
  localparam logic [6:0] SnpUnique          = 7'h7;
  localparam logic [6:0] SnpUniqueFwd       = 7'h17;
  localparam logic [6:0] SnpUniqueStash     = 7'h5;
  localparam logic [6:0] SnpCleanShared     = 7'h8;
  localparam logic [6:0] SnpCleanInvalid    = 7'h9;
  localparam logic [6:0] SnpMakeInvalid     = 7'hA;
  localparam logic [6:0] SnpMakeInvalidStash= 7'h6;
  localparam logic [6:0] SnpStashUnique     = 7'hB;
  localparam logic [6:0] SnpStashShared     = 7'hC;

  // snpToN: 让被探测块走向 I 的 snoop
  //   = isSnpUniqueX | SnpCleanInvalid | isSnpMakeInvalidX
  //   = SnpUnique(7)/Fwd(17)/Stash(5) + SnpCleanInvalid(9) + SnpMakeInvalid(A)/Stash(6)
  function automatic logic isSnpToN(input logic [6:0] o);
    return o == SnpUnique || o == SnpUniqueFwd || o == SnpUniqueStash
        || o == SnpCleanInvalid || o == SnpMakeInvalid || o == SnpMakeInvalidStash;
  endfunction
  // snpToB: 让被探测块走向 SC 的 snoop
  function automatic logic isSnpToB(input logic [6:0] o);
    return o == SnpClean || o == SnpCleanFwd || o == SnpShared || o == SnpSharedFwd
        || o == SnpNotSharedDirty || o == SnpNotSharedDirtyFwd;
  endfunction
  function automatic logic isSnpToBFwd(input logic [6:0] o);
    return o == SnpCleanFwd || o == SnpSharedFwd || o == SnpNotSharedDirtyFwd;
  endfunction
  function automatic logic isSnpToNFwd(input logic [6:0] o);
    return o == SnpUniqueFwd;
  endfunction
  function automatic logic isSnpXFwd(input logic [6:0] o);
    return o == SnpOnceFwd || o == SnpCleanFwd || o == SnpNotSharedDirtyFwd
        || o == SnpSharedFwd || o == SnpUniqueFwd;
  endfunction
  function automatic logic isSnpToBNonFwd(input logic [6:0] o);
    return o == SnpClean || o == SnpShared || o == SnpNotSharedDirty;
  endfunction
  function automatic logic isSnpToNNonFwd(input logic [6:0] o);  // SnpUnique | SnpUniqueStash
    return o == SnpUnique || o == SnpUniqueStash;
  endfunction
  function automatic logic isSnpOnce(input logic [6:0] o);
    return o == SnpOnce;
  endfunction
  function automatic logic isSnpOnceFwd(input logic [6:0] o);
    return o == SnpOnceFwd;
  endfunction
  function automatic logic isSnpOnceX(input logic [6:0] o);   // SnpOnce 或 SnpOnceFwd
    return o == SnpOnce || o == SnpOnceFwd;
  endfunction
  function automatic logic isSnpStashX(input logic [6:0] o);  // SnpStashUnique | SnpStashShared
    return o == SnpStashUnique || o == SnpStashShared;
  endfunction
  function automatic logic isSnpQuery(input logic [6:0] o);
    return 1'b0; // 本配置未启用 SnpQuery
  endfunction
  function automatic logic isSnpCleanShared(input logic [6:0] o);
    return o == SnpCleanShared;
  endfunction

  // ---------------- CHI resp 错误编码 (RespErrEncodings) ----------------
  localparam logic [1:0] RESP_OK   = 2'd0;
  localparam logic [1:0] RESP_NDERR= 2'd3;  // golden: &respErr == NDERR
  localparam logic [1:0] RESP_DERR = 2'd2;

  // ---------------- 重试 backoff 参数 ----------------
  localparam int BACKOFF_THRESHOLD = 3;
  localparam int BACKOFF_CYCLES    = 20;

endpackage : mshr_pkg
