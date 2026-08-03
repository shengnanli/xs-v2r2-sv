// =============================================================================
// xs_VTypeBuffer_core —— Rob 的 vtype 缓冲(VTypeBuffer)可读核。
//
// 忠实复刻 golden VTypeBuffer 的 glue(walk/enq/deq 指针 FSM + commit/walk/spclWalk
// 计数 + snapshot 管理 + vtype 写回)。3 个子模块保持按名例化, FM 侧两侧同名对称黑盒:
//   - SyncDataModuleTemplate__64entry_3 vtypeBuffer   (已 AUX PASS)
//   - SnapshotGenerator_1 walkPtrSnapshots_snapshotGen (walkPtr 快照, AUX)
//   - SnapshotGenerator_2 walkVTypeSnapshots_snapshotGen (specVtype 快照, AUX)
//
// 本核证明的是 VTypeBuffer 自身的 glue(52 寄存器 FSM + 组合网), 非子模块内部。
// glue 逻辑逐字保留 golden 语义(bug-for-bug); 仅剔除 cone-dead 的 dontTouch `_probe`
// 观测网(无读者)和 SYNTHESIS 下裁剪的断言块 —— 二者对等价性无影响。
// =============================================================================
module xs_VTypeBuffer_core(
  input        clock,
  input        reset,
  input        io_redirect_valid,
  input        io_req_0_valid,
  input  [8:0] io_req_0_bits_fuOpType,
  input        io_req_0_bits_vpu_vill,
  input        io_req_0_bits_vpu_vma,
  input        io_req_0_bits_vpu_vta,
  input  [1:0] io_req_0_bits_vpu_vsew,
  input  [2:0] io_req_0_bits_vpu_vlmul,
  input        io_req_0_bits_vpu_specVill,
  input        io_req_0_bits_vpu_specVma,
  input        io_req_0_bits_vpu_specVta,
  input  [1:0] io_req_0_bits_vpu_specVsew,
  input  [2:0] io_req_0_bits_vpu_specVlmul,
  input        io_req_0_bits_isVset,
  input        io_req_0_bits_lastUop,
  input        io_req_1_valid,
  input  [8:0] io_req_1_bits_fuOpType,
  input        io_req_1_bits_vpu_vill,
  input        io_req_1_bits_vpu_vma,
  input        io_req_1_bits_vpu_vta,
  input  [1:0] io_req_1_bits_vpu_vsew,
  input  [2:0] io_req_1_bits_vpu_vlmul,
  input        io_req_1_bits_vpu_specVill,
  input        io_req_1_bits_vpu_specVma,
  input        io_req_1_bits_vpu_specVta,
  input  [1:0] io_req_1_bits_vpu_specVsew,
  input  [2:0] io_req_1_bits_vpu_specVlmul,
  input        io_req_1_bits_isVset,
  input        io_req_1_bits_lastUop,
  input        io_req_2_valid,
  input  [8:0] io_req_2_bits_fuOpType,
  input        io_req_2_bits_vpu_vill,
  input        io_req_2_bits_vpu_vma,
  input        io_req_2_bits_vpu_vta,
  input  [1:0] io_req_2_bits_vpu_vsew,
  input  [2:0] io_req_2_bits_vpu_vlmul,
  input        io_req_2_bits_vpu_specVill,
  input        io_req_2_bits_vpu_specVma,
  input        io_req_2_bits_vpu_specVta,
  input  [1:0] io_req_2_bits_vpu_specVsew,
  input  [2:0] io_req_2_bits_vpu_specVlmul,
  input        io_req_2_bits_isVset,
  input        io_req_2_bits_lastUop,
  input        io_req_3_valid,
  input  [8:0] io_req_3_bits_fuOpType,
  input        io_req_3_bits_vpu_vill,
  input        io_req_3_bits_vpu_vma,
  input        io_req_3_bits_vpu_vta,
  input  [1:0] io_req_3_bits_vpu_vsew,
  input  [2:0] io_req_3_bits_vpu_vlmul,
  input        io_req_3_bits_vpu_specVill,
  input        io_req_3_bits_vpu_specVma,
  input        io_req_3_bits_vpu_specVta,
  input  [1:0] io_req_3_bits_vpu_specVsew,
  input  [2:0] io_req_3_bits_vpu_specVlmul,
  input        io_req_3_bits_isVset,
  input        io_req_3_bits_lastUop,
  input        io_req_4_valid,
  input  [8:0] io_req_4_bits_fuOpType,
  input        io_req_4_bits_vpu_vill,
  input        io_req_4_bits_vpu_vma,
  input        io_req_4_bits_vpu_vta,
  input  [1:0] io_req_4_bits_vpu_vsew,
  input  [2:0] io_req_4_bits_vpu_vlmul,
  input        io_req_4_bits_vpu_specVill,
  input        io_req_4_bits_vpu_specVma,
  input        io_req_4_bits_vpu_specVta,
  input  [1:0] io_req_4_bits_vpu_specVsew,
  input  [2:0] io_req_4_bits_vpu_specVlmul,
  input        io_req_4_bits_isVset,
  input        io_req_4_bits_lastUop,
  input        io_req_5_valid,
  input  [8:0] io_req_5_bits_fuOpType,
  input        io_req_5_bits_vpu_vill,
  input        io_req_5_bits_vpu_vma,
  input        io_req_5_bits_vpu_vta,
  input  [1:0] io_req_5_bits_vpu_vsew,
  input  [2:0] io_req_5_bits_vpu_vlmul,
  input        io_req_5_bits_vpu_specVill,
  input        io_req_5_bits_vpu_specVma,
  input        io_req_5_bits_vpu_specVta,
  input  [1:0] io_req_5_bits_vpu_specVsew,
  input  [2:0] io_req_5_bits_vpu_specVlmul,
  input        io_req_5_bits_isVset,
  input        io_req_5_bits_lastUop,
  input  [5:0] io_fromRob_walkSize,
  input        io_fromRob_walkEnd,
  input  [5:0] io_fromRob_commitSize,
  input        io_snpt_snptEnq,
  input        io_snpt_snptDeq,
  input        io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input        io_snpt_flushVec_0,
  input        io_snpt_flushVec_1,
  input        io_snpt_flushVec_2,
  input        io_snpt_flushVec_3,
  output       io_canEnq,
  output       io_canEnqForDispatch,
  output       io_toDecode_isResumeVType,
  output       io_toDecode_walkToArchVType,
  output       io_toDecode_walkVType_valid,
  output       io_toDecode_walkVType_bits_illegal,
  output       io_toDecode_walkVType_bits_vma,
  output       io_toDecode_walkVType_bits_vta,
  output [1:0] io_toDecode_walkVType_bits_vsew,
  output [2:0] io_toDecode_walkVType_bits_vlmul,
  output       io_toDecode_commitVType_vtype_valid,
  output       io_toDecode_commitVType_vtype_bits_illegal,
  output       io_toDecode_commitVType_vtype_bits_vma,
  output       io_toDecode_commitVType_vtype_bits_vta,
  output [1:0] io_toDecode_commitVType_vtype_bits_vsew,
  output [2:0] io_toDecode_commitVType_vtype_bits_vlmul,
  output       io_toDecode_commitVType_hasVsetvl,
  output       io_status_walkEnd
);

  wire [1:0]        stateNext;
  wire [5:0]        _deqPtrVecNext_0_new_ptr_T_3;
  wire [5:0]        walkPtrNext_value;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_0_illegal;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_0_vma;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_0_vta;
  wire [1:0]        _walkVTypeSnapshots_snapshotGen_io_snapshots_0_vsew;
  wire [2:0]        _walkVTypeSnapshots_snapshotGen_io_snapshots_0_vlmul;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_1_illegal;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_1_vma;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_1_vta;
  wire [1:0]        _walkVTypeSnapshots_snapshotGen_io_snapshots_1_vsew;
  wire [2:0]        _walkVTypeSnapshots_snapshotGen_io_snapshots_1_vlmul;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_2_illegal;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_2_vma;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_2_vta;
  wire [1:0]        _walkVTypeSnapshots_snapshotGen_io_snapshots_2_vsew;
  wire [2:0]        _walkVTypeSnapshots_snapshotGen_io_snapshots_2_vlmul;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_3_illegal;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_3_vma;
  wire              _walkVTypeSnapshots_snapshotGen_io_snapshots_3_vta;
  wire [1:0]        _walkVTypeSnapshots_snapshotGen_io_snapshots_3_vsew;
  wire [2:0]        _walkVTypeSnapshots_snapshotGen_io_snapshots_3_vlmul;
  wire              _walkPtrSnapshots_snapshotGen_io_snapshots_0_flag;
  wire [5:0]        _walkPtrSnapshots_snapshotGen_io_snapshots_0_value;
  wire              _walkPtrSnapshots_snapshotGen_io_snapshots_1_flag;
  wire [5:0]        _walkPtrSnapshots_snapshotGen_io_snapshots_1_value;
  wire              _walkPtrSnapshots_snapshotGen_io_snapshots_2_flag;
  wire [5:0]        _walkPtrSnapshots_snapshotGen_io_snapshots_2_value;
  wire              _walkPtrSnapshots_snapshotGen_io_snapshots_3_flag;
  wire [5:0]        _walkPtrSnapshots_snapshotGen_io_snapshots_3_value;
  wire              _vtypeBuffer_io_rdata_0_isVsetvl;
  wire              _vtypeBuffer_io_rdata_1_isVsetvl;
  wire              _vtypeBuffer_io_rdata_2_isVsetvl;
  wire              _vtypeBuffer_io_rdata_3_isVsetvl;
  wire              _vtypeBuffer_io_rdata_4_isVsetvl;
  wire              _vtypeBuffer_io_rdata_5_isVsetvl;
  wire              _vtypeBuffer_io_rdata_6_isVsetvl;
  wire              _vtypeBuffer_io_rdata_7_isVsetvl;
  reg  [1:0]        state;
  reg  [1:0]        stateLastCycle;
  reg               enqPtrVec_0_flag;
  reg  [5:0]        enqPtrVec_0_value;
  reg               enqPtrVec_1_flag;
  reg  [5:0]        enqPtrVec_1_value;
  reg               enqPtrVec_2_flag;
  reg  [5:0]        enqPtrVec_2_value;
  reg               enqPtrVec_3_flag;
  reg  [5:0]        enqPtrVec_3_value;
  reg               enqPtrVec_4_flag;
  reg  [5:0]        enqPtrVec_4_value;
  reg               enqPtrVec_5_flag;
  reg  [5:0]        enqPtrVec_5_value;
  reg               deqPtrVec_0_flag;
  reg  [5:0]        shiftAmount;
  reg               deqPtrVec_1_flag;
  reg  [5:0]        deqPtrVec_1_value;
  reg               deqPtrVec_2_flag;
  reg  [5:0]        deqPtrVec_2_value;
  reg               deqPtrVec_3_flag;
  reg  [5:0]        deqPtrVec_3_value;
  reg               deqPtrVec_4_flag;
  reg  [5:0]        deqPtrVec_4_value;
  reg               deqPtrVec_5_flag;
  reg  [5:0]        deqPtrVec_5_value;
  reg               deqPtrVec_6_flag;
  reg  [5:0]        deqPtrVec_6_value;
  reg               deqPtrVec_7_flag;
  reg  [5:0]        deqPtrVec_7_value;
  reg  [63:0]       deqPtrOH;
  wire              _GEN = 64'h1 << shiftAmount != deqPtrOH;
  reg               walkPtr_flag;
  reg  [5:0]        walkPtr_value;
  reg               robWalkEndReg;
  wire              needAllocVec_0 =
    io_req_0_valid & io_req_0_bits_isVset & io_req_0_bits_lastUop;
  wire              needAllocVec_1 =
    io_req_1_valid & io_req_1_bits_isVset & io_req_1_bits_lastUop;
  wire              needAllocVec_2 =
    io_req_2_valid & io_req_2_bits_isVset & io_req_2_bits_lastUop;
  wire              needAllocVec_3 =
    io_req_3_valid & io_req_3_bits_isVset & io_req_3_bits_lastUop;
  wire              needAllocVec_4 =
    io_req_4_valid & io_req_4_bits_isVset & io_req_4_bits_lastUop;
  wire              needAllocVec_5 =
    io_req_5_valid & io_req_5_bits_isVset & io_req_5_bits_lastUop;
  wire [1:0]        _GEN_0 = {1'h0, needAllocVec_1};
  wire [1:0]        _GEN_1 = {1'h0, needAllocVec_2};
  wire [1:0]        _allocPtrVec_T_3 = 2'(_GEN_0 + _GEN_1);
  wire [1:0]        _GEN_2 = {1'h0, needAllocVec_0};
  wire [1:0]        _GEN_3 = {1'h0, needAllocVec_4};
  wire [1:0]        _GEN_4 = {1'h0, needAllocVec_3};
  reg  [5:0]        commitSize;
  reg  [5:0]        walkSize;
  reg  [5:0]        spclWalkSize;
  wire [2:0]        commitSizeNext;
  wire [2:0]        newSpclWalkSize =
    io_redirect_valid & ~io_snpt_useSnpt ? commitSizeNext : 3'h0;
  wire [2:0]        commitCount;
  assign commitSizeNext =
    3'(3'(commitSize[2:0] + io_fromRob_commitSize[2:0]) - commitCount);
  wire [2:0]        walkCount;
  wire [2:0]        walkSizeNext =
    3'(3'(walkSize[2:0] + io_fromRob_walkSize[2:0]) - walkCount);
  wire [2:0]        spclWalkCount;
  wire [2:0]        spclWalkSizeNext =
    3'(3'(spclWalkSize[2:0] + newSpclWalkSize) - spclWalkCount);
  wire              _vtypeBufferReadPtrVecNext_T_1 = stateNext == 2'h2;
  wire              _walkPtrNext_T_2 = ~(|state) & _vtypeBufferReadPtrVecNext_T_1;
  wire              _spclWalkCount_T = state == 2'h1;
  wire              _walkPtrNext_T_5 = _spclWalkCount_T & _vtypeBufferReadPtrVecNext_T_1;
  wire              _walkCount_T = state == 2'h2;
  wire              _walkPtrNext_T_8 = _walkCount_T & io_snpt_useSnpt & io_redirect_valid;
  wire [6:0]        _walkPtrNext_new_ptr_T_1 =
    7'({walkPtr_flag, walkPtr_value} + {4'h0, walkCount});
  wire [3:0]        _GEN_5 =
    {{_walkPtrSnapshots_snapshotGen_io_snapshots_3_flag},
     {_walkPtrSnapshots_snapshotGen_io_snapshots_2_flag},
     {_walkPtrSnapshots_snapshotGen_io_snapshots_1_flag},
     {_walkPtrSnapshots_snapshotGen_io_snapshots_0_flag}};
  wire [3:0][5:0]   _GEN_6 =
    {{_walkPtrSnapshots_snapshotGen_io_snapshots_3_value},
     {_walkPtrSnapshots_snapshotGen_io_snapshots_2_value},
     {_walkPtrSnapshots_snapshotGen_io_snapshots_1_value},
     {_walkPtrSnapshots_snapshotGen_io_snapshots_0_value}};
  assign walkPtrNext_value =
    _walkPtrNext_T_2
      ? _GEN_6[io_snpt_snptSelect]
      : _walkPtrNext_T_5
          ? _deqPtrVecNext_0_new_ptr_T_3
          : _walkPtrNext_T_8
              ? _GEN_6[io_snpt_snptSelect]
              : _walkCount_T ? _walkPtrNext_new_ptr_T_1[5:0] : walkPtr_value;
  reg               useSnapshot;
  reg               snapshotVType_illegal;
  reg               snapshotVType_vma;
  reg               snapshotVType_vta;
  reg  [1:0]        snapshotVType_vsew;
  reg  [2:0]        snapshotVType_vlmul;
  wire              _vtypeBufferReadPtrVecNext_T = stateNext == 2'h0;
  wire [2:0]        deqPtrSteps =
    ((|state) ? 3'h0 : commitCount) | (_spclWalkCount_T ? spclWalkCount : 3'h0);
  wire [6:0]        _deqPtrNext_new_ptr_T_1 =
    7'({deqPtrVec_0_flag, shiftAmount} + {4'h0, deqPtrSteps});
  assign _deqPtrVecNext_0_new_ptr_T_3 = _deqPtrNext_new_ptr_T_1[5:0];
  wire [6:0]        _deqPtrVecNext_1_new_ptr_T_1 = 7'(_deqPtrNext_new_ptr_T_1 + 7'h1);
  wire [6:0]        _deqPtrVecNext_2_new_ptr_T_1 = 7'(_deqPtrNext_new_ptr_T_1 + 7'h2);
  wire [6:0]        _deqPtrVecNext_3_new_ptr_T_1 = 7'(_deqPtrNext_new_ptr_T_1 + 7'h3);
  wire [6:0]        _deqPtrVecNext_4_new_ptr_T_1 = 7'(_deqPtrNext_new_ptr_T_1 + 7'h4);
  wire [6:0]        _deqPtrVecNext_5_new_ptr_T_1 = 7'(_deqPtrNext_new_ptr_T_1 + 7'h5);
  wire [6:0]        _deqPtrVecNext_6_new_ptr_T_1 = 7'(_deqPtrNext_new_ptr_T_1 + 7'h6);
  wire [6:0]        _deqPtrVecNext_7_new_ptr_T_1 = 7'(_deqPtrNext_new_ptr_T_1 + 7'h7);
  wire [2:0]        _GEN_7 = {1'h0, 2'(_GEN_2 + _GEN_0)};
  wire [7:0][5:0]   _GEN_8 =
    {{enqPtrVec_0_value},
     {enqPtrVec_0_value},
     {enqPtrVec_5_value},
     {enqPtrVec_4_value},
     {enqPtrVec_3_value},
     {enqPtrVec_2_value},
     {enqPtrVec_1_value},
     {enqPtrVec_0_value}};
  wire              _vtypeBufferReadPtrVecNext_T_2 = stateNext == 2'h1;
  wire              commitValidVec_0 =
    ~(|state) & (|commitSize) | _spclWalkCount_T & (|spclWalkSize);
  wire              walkValidVec_0 =
    _walkCount_T & (|walkSize) | _spclWalkCount_T & (|spclWalkSize);
  wire              commitValidVec_1 =
    ~(|state) & (|(commitSize[5:1])) | _spclWalkCount_T & (|(spclWalkSize[5:1]));
  wire              walkValidVec_1 =
    _walkCount_T & (|(walkSize[5:1])) | _spclWalkCount_T & (|(spclWalkSize[5:1]));
  wire              _walkValidVec_2_T_4 = spclWalkSize > 6'h2;
  wire              commitValidVec_2 =
    ~(|state) & commitSize > 6'h2 | _spclWalkCount_T & _walkValidVec_2_T_4;
  wire              walkValidVec_2 =
    _walkCount_T & walkSize > 6'h2 | _spclWalkCount_T & _walkValidVec_2_T_4;
  wire              commitValidVec_3 =
    ~(|state) & (|(commitSize[5:2])) | _spclWalkCount_T & (|(spclWalkSize[5:2]));
  wire              walkValidVec_3 =
    _walkCount_T & (|(walkSize[5:2])) | _spclWalkCount_T & (|(spclWalkSize[5:2]));
  wire              _walkValidVec_4_T_4 = spclWalkSize > 6'h4;
  wire              commitValidVec_4 =
    ~(|state) & commitSize > 6'h4 | _spclWalkCount_T & _walkValidVec_4_T_4;
  wire              walkValidVec_4 =
    _walkCount_T & walkSize > 6'h4 | _spclWalkCount_T & _walkValidVec_4_T_4;
  wire              _walkValidVec_5_T_4 = spclWalkSize > 6'h5;
  wire              commitValidVec_5 =
    ~(|state) & commitSize > 6'h5 | _spclWalkCount_T & _walkValidVec_5_T_4;
  wire              walkValidVec_5 =
    _walkCount_T & walkSize > 6'h5 | _spclWalkCount_T & _walkValidVec_5_T_4;
  wire              _walkValidVec_6_T_4 = spclWalkSize > 6'h6;
  wire              commitValidVec_6 =
    ~(|state) & commitSize > 6'h6 | _spclWalkCount_T & _walkValidVec_6_T_4;
  wire              walkValidVec_6 =
    _walkCount_T & walkSize > 6'h6 | _spclWalkCount_T & _walkValidVec_6_T_4;
  wire              commitValidVec_7 =
    ~(|state) & (|(commitSize[5:3])) | _spclWalkCount_T & (|(spclWalkSize[5:3]));
  wire              walkValidVec_7 =
    _walkCount_T & (|(walkSize[5:3])) | _spclWalkCount_T & (|(spclWalkSize[5:3]));
  assign commitCount =
    (|state)
      ? 3'h0
      : 3'(3'({1'h0, 2'({1'h0, commitValidVec_0} + {1'h0, commitValidVec_1})}
              + {1'h0, 2'({1'h0, commitValidVec_2} + {1'h0, commitValidVec_3})})
           + 3'({1'h0, 2'({1'h0, commitValidVec_4} + {1'h0, commitValidVec_5})}
                + {1'h0, 2'({1'h0, commitValidVec_6} + {1'h0, commitValidVec_7})}));
  wire [2:0]        _GEN_9 = {1'h0, 2'({1'h0, walkValidVec_0} + {1'h0, walkValidVec_1})};
  wire [2:0]        _GEN_10 = {1'h0, 2'({1'h0, walkValidVec_2} + {1'h0, walkValidVec_3})};
  wire [2:0]        _GEN_11 = {1'h0, 2'({1'h0, walkValidVec_4} + {1'h0, walkValidVec_5})};
  wire [2:0]        _GEN_12 = {1'h0, 2'({1'h0, walkValidVec_6} + {1'h0, walkValidVec_7})};
  assign walkCount =
    _walkCount_T ? 3'(3'(_GEN_9 + _GEN_10) + 3'(_GEN_11 + _GEN_12)) : 3'h0;
  assign spclWalkCount =
    _spclWalkCount_T ? 3'(3'(_GEN_9 + _GEN_10) + 3'(_GEN_11 + _GEN_12)) : 3'h0;
  wire              walkEndNext = walkSizeNext == 3'h0;
  wire              spclWalkEndNext = spclWalkSizeNext == 3'h0;
  wire [1:0]        _GEN_13 = io_snpt_useSnpt ? 2'h2 : 2'h1;
  wire              _GEN_14 = state == 2'h1;
  wire              _GEN_15 =
    state == 2'h2 & (io_fromRob_walkEnd | robWalkEndReg) & walkEndNext;
  assign stateNext =
    io_redirect_valid
      ? _GEN_13
      : (|state)
          ? (_GEN_14 ? (spclWalkEndNext ? 2'h2 : state) : _GEN_15 ? 2'h0 : state)
          : 2'h0;
  wire [6:0]        numValidEntries =
    enqPtrVec_0_flag == deqPtrVec_0_flag
      ? {1'h0, 6'(enqPtrVec_0_value - shiftAmount)}
      : 7'(7'({1'h0, enqPtrVec_0_value} - 7'h40) - {1'h0, shiftAmount});
  reg               allowEnqueue_last_REG;
  reg               allowEnqueueForDispatch_last_REG;
  reg               decodeResumeVType_valid;
  reg               decodeResumeVType_bits_illegal;
  reg               decodeResumeVType_bits_vma;
  reg               decodeResumeVType_bits_vta;
  reg  [1:0]        decodeResumeVType_bits_vsew;
  reg  [2:0]        decodeResumeVType_bits_vlmul;
  wire              infoVec_0_illegal;
  wire              infoVec_1_illegal;
  wire              infoVec_0_vma;
  wire              infoVec_1_vma;
  wire              infoVec_0_vta;
  wire              infoVec_1_vta;
  wire [1:0]        infoVec_0_vsew;
  wire [1:0]        infoVec_1_vsew;
  wire [2:0]        infoVec_0_vlmul;
  wire [2:0]        infoVec_1_vlmul;
  wire              infoVec_2_illegal;
  wire              infoVec_2_vma;
  wire              infoVec_2_vta;
  wire [1:0]        infoVec_2_vsew;
  wire [2:0]        infoVec_2_vlmul;
  wire              infoVec_3_illegal;
  wire              infoVec_3_vma;
  wire              infoVec_3_vta;
  wire [1:0]        infoVec_3_vsew;
  wire [2:0]        infoVec_3_vlmul;
  wire              infoVec_4_illegal;
  wire              infoVec_4_vma;
  wire              infoVec_4_vta;
  wire [1:0]        infoVec_4_vsew;
  wire [2:0]        infoVec_4_vlmul;
  wire              infoVec_5_illegal;
  wire              infoVec_5_vma;
  wire              infoVec_5_vta;
  wire [1:0]        infoVec_5_vsew;
  wire [2:0]        infoVec_5_vlmul;
  wire              infoVec_6_illegal;
  wire              infoVec_6_vma;
  wire              infoVec_6_vta;
  wire [1:0]        infoVec_6_vsew;
  wire [2:0]        infoVec_6_vlmul;
  wire              infoVec_7_illegal;
  wire              newestArchVType_illegal =
    commitValidVec_7
      ? infoVec_7_illegal
      : commitValidVec_6
          ? infoVec_6_illegal
          : commitValidVec_5
              ? infoVec_5_illegal
              : commitValidVec_4
                  ? infoVec_4_illegal
                  : commitValidVec_3
                      ? infoVec_3_illegal
                      : commitValidVec_2
                          ? infoVec_2_illegal
                          : commitValidVec_1 ? infoVec_1_illegal : infoVec_0_illegal;
  wire              infoVec_7_vma;
  wire              newestArchVType_vma =
    commitValidVec_7
      ? infoVec_7_vma
      : commitValidVec_6
          ? infoVec_6_vma
          : commitValidVec_5
              ? infoVec_5_vma
              : commitValidVec_4
                  ? infoVec_4_vma
                  : commitValidVec_3
                      ? infoVec_3_vma
                      : commitValidVec_2
                          ? infoVec_2_vma
                          : commitValidVec_1 ? infoVec_1_vma : infoVec_0_vma;
  wire              infoVec_7_vta;
  wire              newestArchVType_vta =
    commitValidVec_7
      ? infoVec_7_vta
      : commitValidVec_6
          ? infoVec_6_vta
          : commitValidVec_5
              ? infoVec_5_vta
              : commitValidVec_4
                  ? infoVec_4_vta
                  : commitValidVec_3
                      ? infoVec_3_vta
                      : commitValidVec_2
                          ? infoVec_2_vta
                          : commitValidVec_1 ? infoVec_1_vta : infoVec_0_vta;
  wire [1:0]        infoVec_7_vsew;
  wire [1:0]        newestArchVType_vsew =
    commitValidVec_7
      ? infoVec_7_vsew
      : commitValidVec_6
          ? infoVec_6_vsew
          : commitValidVec_5
              ? infoVec_5_vsew
              : commitValidVec_4
                  ? infoVec_4_vsew
                  : commitValidVec_3
                      ? infoVec_3_vsew
                      : commitValidVec_2
                          ? infoVec_2_vsew
                          : commitValidVec_1 ? infoVec_1_vsew : infoVec_0_vsew;
  wire [2:0]        infoVec_7_vlmul;
  wire [2:0]        newestArchVType_vlmul =
    commitValidVec_7
      ? infoVec_7_vlmul
      : commitValidVec_6
          ? infoVec_6_vlmul
          : commitValidVec_5
              ? infoVec_5_vlmul
              : commitValidVec_4
                  ? infoVec_4_vlmul
                  : commitValidVec_3
                      ? infoVec_3_vlmul
                      : commitValidVec_2
                          ? infoVec_2_vlmul
                          : commitValidVec_1 ? infoVec_1_vlmul : infoVec_0_vlmul;
  wire [7:0]        _commitVTypeValid_T =
    {commitValidVec_7,
     commitValidVec_6,
     commitValidVec_5,
     commitValidVec_4,
     commitValidVec_3,
     commitValidVec_2,
     commitValidVec_1,
     commitValidVec_0};
  reg               walkToArchVType;
  wire              _GEN_16 =
    (enqPtrVec_0_flag ^ deqPtrVec_0_flag ^ enqPtrVec_0_value < shiftAmount)
    & ~(enqPtrVec_0_flag != deqPtrVec_0_flag & enqPtrVec_0_value == shiftAmount);
  wire              _GEN_17 = numValidEntries == 7'h40;
  wire              _GEN_18 = ~(|state) & _vtypeBufferReadPtrVecNext_T;
  wire              _GEN_19 = ~(|state) & _vtypeBufferReadPtrVecNext_T_2;
  wire              _GEN_20 = ~(|state) & _vtypeBufferReadPtrVecNext_T_1;
  wire              _GEN_21 = _spclWalkCount_T & _vtypeBufferReadPtrVecNext_T;
  wire              _GEN_22 = _spclWalkCount_T & _vtypeBufferReadPtrVecNext_T_2;
  wire              _GEN_23 = _spclWalkCount_T & _vtypeBufferReadPtrVecNext_T_1;
  wire              _GEN_24 = _walkCount_T & _vtypeBufferReadPtrVecNext_T;
  wire              _GEN_25 = _walkCount_T & _vtypeBufferReadPtrVecNext_T_2;
  wire              _GEN_26 = _walkCount_T & _vtypeBufferReadPtrVecNext_T_1;
  wire              walkPtrNext_flag =
    _walkPtrNext_T_2
      ? _GEN_5[io_snpt_snptSelect]
      : _walkPtrNext_T_5
          ? _deqPtrNext_new_ptr_T_1[6]
          : _walkPtrNext_T_8
              ? _GEN_5[io_snpt_snptSelect]
              : _walkCount_T ? _walkPtrNext_new_ptr_T_1[6] : walkPtr_flag;
  wire              _enqPtrNext_T_2 = _walkCount_T & _vtypeBufferReadPtrVecNext_T;
  wire [6:0]        _GEN_27 =
    {4'h0,
     3'({1'h0, 2'(_GEN_2 + _allocPtrVec_T_3)}
        + {1'h0, 2'(_GEN_4 + 2'(_GEN_3 + {1'h0, needAllocVec_5}))})};
  wire [6:0]        _enqPtrNext_new_ptr_T_1 =
    7'({enqPtrVec_0_flag, enqPtrVec_0_value} + _GEN_27);
  wire [6:0]        _GEN_28 =
    {_enqPtrNext_T_2 ? walkPtrNext_flag : _enqPtrNext_new_ptr_T_1[6],
     _enqPtrNext_T_2 ? walkPtrNext_value : _enqPtrNext_new_ptr_T_1[5:0]};
  wire [6:0]        _enqPtrVecNext_1_new_ptr_T_1 = 7'(_GEN_28 + 7'h1);
  wire [6:0]        _enqPtrVecNext_2_new_ptr_T_1 = 7'(_GEN_28 + 7'h2);
  wire [6:0]        _enqPtrVecNext_3_new_ptr_T_1 = 7'(_GEN_28 + 7'h3);
  wire [6:0]        _enqPtrVecNext_4_new_ptr_T_1 = 7'(_GEN_28 + 7'h4);
  wire [6:0]        _enqPtrVecNext_5_new_ptr_T_1 = 7'(_GEN_28 + 7'h5);
  wire [6:0]        _allowEnqueueForDispatch_T = 7'(numValidEntries + _GEN_27);
  wire              _GEN_29 = _walkCount_T & (|walkCount);
  wire [15:0][63:0] _GEN_30 =
    {{deqPtrOH},
     {deqPtrOH},
     {deqPtrOH},
     {deqPtrOH},
     {deqPtrOH},
     {deqPtrOH},
     {deqPtrOH},
     {{deqPtrOH[55:0], deqPtrOH[63:56]}},
     {{deqPtrOH[56:0], deqPtrOH[63:57]}},
     {{deqPtrOH[57:0], deqPtrOH[63:58]}},
     {{deqPtrOH[58:0], deqPtrOH[63:59]}},
     {{deqPtrOH[59:0], deqPtrOH[63:60]}},
     {{deqPtrOH[60:0], deqPtrOH[63:61]}},
     {{deqPtrOH[61:0], deqPtrOH[63:62]}},
     {{deqPtrOH[62:0], deqPtrOH[63]}},
     {deqPtrOH}};
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      state <= 2'h0;
      enqPtrVec_0_flag <= 1'h0;
      enqPtrVec_0_value <= 6'h0;
      enqPtrVec_1_flag <= 1'h0;
      enqPtrVec_1_value <= 6'h1;
      enqPtrVec_2_flag <= 1'h0;
      enqPtrVec_2_value <= 6'h2;
      enqPtrVec_3_flag <= 1'h0;
      enqPtrVec_3_value <= 6'h3;
      enqPtrVec_4_flag <= 1'h0;
      enqPtrVec_4_value <= 6'h4;
      enqPtrVec_5_flag <= 1'h0;
      enqPtrVec_5_value <= 6'h5;
      deqPtrVec_0_flag <= 1'h0;
      shiftAmount <= 6'h0;
      deqPtrVec_1_flag <= 1'h0;
      deqPtrVec_1_value <= 6'h1;
      deqPtrVec_2_flag <= 1'h0;
      deqPtrVec_2_value <= 6'h2;
      deqPtrVec_3_flag <= 1'h0;
      deqPtrVec_3_value <= 6'h3;
      deqPtrVec_4_flag <= 1'h0;
      deqPtrVec_4_value <= 6'h4;
      deqPtrVec_5_flag <= 1'h0;
      deqPtrVec_5_value <= 6'h5;
      deqPtrVec_6_flag <= 1'h0;
      deqPtrVec_6_value <= 6'h6;
      deqPtrVec_7_flag <= 1'h0;
      deqPtrVec_7_value <= 6'h7;
      deqPtrOH <= 64'h1;
      robWalkEndReg <= 1'h0;
      commitSize <= 6'h0;
      walkSize <= 6'h0;
      spclWalkSize <= 6'h0;
      allowEnqueue_last_REG <= 1'h1;
      allowEnqueueForDispatch_last_REG <= 1'h1;
      decodeResumeVType_valid <= 1'h0;
      decodeResumeVType_bits_illegal <= 1'h0;
      decodeResumeVType_bits_vma <= 1'h0;
      decodeResumeVType_bits_vta <= 1'h0;
      decodeResumeVType_bits_vsew <= 2'h0;
      decodeResumeVType_bits_vlmul <= 3'h0;
      walkToArchVType <= 1'h0;
    end
    else begin
      if (io_redirect_valid)
        state <= _GEN_13;
      else if (|state) begin
        if (_GEN_14) begin
          if (spclWalkEndNext)
            state <= 2'h2;
        end
        else if (_GEN_15)
          state <= 2'h0;
      end
      else
        state <= 2'h0;
      if (_enqPtrNext_T_2) begin
        enqPtrVec_0_flag <= walkPtrNext_flag;
        enqPtrVec_0_value <= walkPtrNext_value;
      end
      else begin
        enqPtrVec_0_flag <= _enqPtrNext_new_ptr_T_1[6];
        enqPtrVec_0_value <= _enqPtrNext_new_ptr_T_1[5:0];
      end
      enqPtrVec_1_flag <= _enqPtrVecNext_1_new_ptr_T_1[6];
      enqPtrVec_1_value <= _enqPtrVecNext_1_new_ptr_T_1[5:0];
      enqPtrVec_2_flag <= _enqPtrVecNext_2_new_ptr_T_1[6];
      enqPtrVec_2_value <= _enqPtrVecNext_2_new_ptr_T_1[5:0];
      enqPtrVec_3_flag <= _enqPtrVecNext_3_new_ptr_T_1[6];
      enqPtrVec_3_value <= _enqPtrVecNext_3_new_ptr_T_1[5:0];
      enqPtrVec_4_flag <= _enqPtrVecNext_4_new_ptr_T_1[6];
      enqPtrVec_4_value <= _enqPtrVecNext_4_new_ptr_T_1[5:0];
      enqPtrVec_5_flag <= _enqPtrVecNext_5_new_ptr_T_1[6];
      enqPtrVec_5_value <= _enqPtrVecNext_5_new_ptr_T_1[5:0];
      deqPtrVec_0_flag <= _deqPtrNext_new_ptr_T_1[6];
      shiftAmount <= _deqPtrVecNext_0_new_ptr_T_3;
      deqPtrVec_1_flag <= _deqPtrVecNext_1_new_ptr_T_1[6];
      deqPtrVec_1_value <= _deqPtrVecNext_1_new_ptr_T_1[5:0];
      deqPtrVec_2_flag <= _deqPtrVecNext_2_new_ptr_T_1[6];
      deqPtrVec_2_value <= _deqPtrVecNext_2_new_ptr_T_1[5:0];
      deqPtrVec_3_flag <= _deqPtrVecNext_3_new_ptr_T_1[6];
      deqPtrVec_3_value <= _deqPtrVecNext_3_new_ptr_T_1[5:0];
      deqPtrVec_4_flag <= _deqPtrVecNext_4_new_ptr_T_1[6];
      deqPtrVec_4_value <= _deqPtrVecNext_4_new_ptr_T_1[5:0];
      deqPtrVec_5_flag <= _deqPtrVecNext_5_new_ptr_T_1[6];
      deqPtrVec_5_value <= _deqPtrVecNext_5_new_ptr_T_1[5:0];
      deqPtrVec_6_flag <= _deqPtrVecNext_6_new_ptr_T_1[6];
      deqPtrVec_6_value <= _deqPtrVecNext_6_new_ptr_T_1[5:0];
      deqPtrVec_7_flag <= _deqPtrVecNext_7_new_ptr_T_1[6];
      deqPtrVec_7_value <= _deqPtrVecNext_7_new_ptr_T_1[5:0];
      deqPtrOH <= _GEN_30[{1'h0, deqPtrSteps}];
      robWalkEndReg <= ~io_redirect_valid & (io_fromRob_walkEnd | robWalkEndReg);
      commitSize <= {3'h0, io_redirect_valid & ~io_snpt_useSnpt ? 3'h0 : commitSizeNext};
      walkSize <= {3'h0, io_redirect_valid ? 3'h0 : walkSizeNext};
      spclWalkSize <= {3'h0, spclWalkSizeNext};
      allowEnqueue_last_REG <= _allowEnqueueForDispatch_T < 7'h3B;
      allowEnqueueForDispatch_last_REG <= _allowEnqueueForDispatch_T < 7'h35;
      decodeResumeVType_valid <=
        _spclWalkCount_T ? (|_commitVTypeValid_T) : useSnapshot | _GEN_29;
      if (_spclWalkCount_T) begin
        decodeResumeVType_bits_illegal <= newestArchVType_illegal;
        decodeResumeVType_bits_vma <= newestArchVType_vma;
        decodeResumeVType_bits_vta <= newestArchVType_vta;
        decodeResumeVType_bits_vsew <= newestArchVType_vsew;
        decodeResumeVType_bits_vlmul <= newestArchVType_vlmul;
      end
      else if (useSnapshot) begin
        decodeResumeVType_bits_illegal <= snapshotVType_illegal;
        decodeResumeVType_bits_vma <= snapshotVType_vma;
        decodeResumeVType_bits_vta <= snapshotVType_vta;
        decodeResumeVType_bits_vsew <= snapshotVType_vsew;
        decodeResumeVType_bits_vlmul <= snapshotVType_vlmul;
      end
      else if (_GEN_29) begin
        decodeResumeVType_bits_illegal <=
          walkValidVec_7
            ? infoVec_7_illegal
            : walkValidVec_6
                ? infoVec_6_illegal
                : walkValidVec_5
                    ? infoVec_5_illegal
                    : walkValidVec_4
                        ? infoVec_4_illegal
                        : walkValidVec_3
                            ? infoVec_3_illegal
                            : walkValidVec_2
                                ? infoVec_2_illegal
                                : walkValidVec_1 ? infoVec_1_illegal : infoVec_0_illegal;
        decodeResumeVType_bits_vma <=
          walkValidVec_7
            ? infoVec_7_vma
            : walkValidVec_6
                ? infoVec_6_vma
                : walkValidVec_5
                    ? infoVec_5_vma
                    : walkValidVec_4
                        ? infoVec_4_vma
                        : walkValidVec_3
                            ? infoVec_3_vma
                            : walkValidVec_2
                                ? infoVec_2_vma
                                : walkValidVec_1 ? infoVec_1_vma : infoVec_0_vma;
        decodeResumeVType_bits_vta <=
          walkValidVec_7
            ? infoVec_7_vta
            : walkValidVec_6
                ? infoVec_6_vta
                : walkValidVec_5
                    ? infoVec_5_vta
                    : walkValidVec_4
                        ? infoVec_4_vta
                        : walkValidVec_3
                            ? infoVec_3_vta
                            : walkValidVec_2
                                ? infoVec_2_vta
                                : walkValidVec_1 ? infoVec_1_vta : infoVec_0_vta;
        decodeResumeVType_bits_vsew <=
          walkValidVec_7
            ? infoVec_7_vsew
            : walkValidVec_6
                ? infoVec_6_vsew
                : walkValidVec_5
                    ? infoVec_5_vsew
                    : walkValidVec_4
                        ? infoVec_4_vsew
                        : walkValidVec_3
                            ? infoVec_3_vsew
                            : walkValidVec_2
                                ? infoVec_2_vsew
                                : walkValidVec_1 ? infoVec_1_vsew : infoVec_0_vsew;
        decodeResumeVType_bits_vlmul <=
          walkValidVec_7
            ? infoVec_7_vlmul
            : walkValidVec_6
                ? infoVec_6_vlmul
                : walkValidVec_5
                    ? infoVec_5_vlmul
                    : walkValidVec_4
                        ? infoVec_4_vlmul
                        : walkValidVec_3
                            ? infoVec_3_vlmul
                            : walkValidVec_2
                                ? infoVec_2_vlmul
                                : walkValidVec_1 ? infoVec_1_vlmul : infoVec_0_vlmul;
      end
      walkToArchVType <=
        ~(_spclWalkCount_T | useSnapshot | _GEN_29) & _walkCount_T
        & stateLastCycle != 2'h2;
    end
  end // always @(posedge, posedge)
  wire [3:0]        _GEN_31 =
    {{_walkVTypeSnapshots_snapshotGen_io_snapshots_3_illegal},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_2_illegal},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_1_illegal},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_0_illegal}};
  wire [3:0]        _GEN_32 =
    {{_walkVTypeSnapshots_snapshotGen_io_snapshots_3_vma},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_2_vma},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_1_vma},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_0_vma}};
  wire [3:0]        _GEN_33 =
    {{_walkVTypeSnapshots_snapshotGen_io_snapshots_3_vta},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_2_vta},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_1_vta},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_0_vta}};
  wire [3:0][1:0]   _GEN_34 =
    {{_walkVTypeSnapshots_snapshotGen_io_snapshots_3_vsew},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_2_vsew},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_1_vsew},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_0_vsew}};
  wire [3:0][2:0]   _GEN_35 =
    {{_walkVTypeSnapshots_snapshotGen_io_snapshots_3_vlmul},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_2_vlmul},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_1_vlmul},
     {_walkVTypeSnapshots_snapshotGen_io_snapshots_0_vlmul}};
  wire              useSnapshotNext =
    ~(|state) & _vtypeBufferReadPtrVecNext_T_1 | _walkCount_T & io_snpt_useSnpt
    & io_redirect_valid;
  always @(posedge clock) begin
    stateLastCycle <= state;
    if (_walkPtrNext_T_2) begin
      walkPtr_flag <= _GEN_5[io_snpt_snptSelect];
      walkPtr_value <= _GEN_6[io_snpt_snptSelect];
    end
    else if (_walkPtrNext_T_5) begin
      walkPtr_flag <= _deqPtrNext_new_ptr_T_1[6];
      walkPtr_value <= _deqPtrVecNext_0_new_ptr_T_3;
    end
    else if (_walkPtrNext_T_8) begin
      walkPtr_flag <= _GEN_5[io_snpt_snptSelect];
      walkPtr_value <= _GEN_6[io_snpt_snptSelect];
    end
    else if (_walkCount_T) begin
      walkPtr_flag <= _walkPtrNext_new_ptr_T_1[6];
      walkPtr_value <= _walkPtrNext_new_ptr_T_1[5:0];
    end
    useSnapshot <= useSnapshotNext;
    if (useSnapshotNext) begin
      snapshotVType_illegal <= _GEN_31[io_snpt_snptSelect];
      snapshotVType_vma <= _GEN_32[io_snpt_snptSelect];
      snapshotVType_vta <= _GEN_33[io_snpt_snptSelect];
      snapshotVType_vsew <= _GEN_34[io_snpt_snptSelect];
      snapshotVType_vlmul <= _GEN_35[io_snpt_snptSelect];
    end
  end // always @(posedge)
  `ifdef ENABLE_INITIAL_REG_
    `ifdef FIRRTL_BEFORE_INITIAL
      `FIRRTL_BEFORE_INITIAL
    `endif // FIRRTL_BEFORE_INITIAL
    logic [31:0] _RANDOM[0:10];
    initial begin
      `ifdef INIT_RANDOM_PROLOG_
        `INIT_RANDOM_PROLOG_
      `endif // INIT_RANDOM_PROLOG_
      `ifdef RANDOMIZE_REG_INIT
        for (logic [3:0] i = 4'h0; i < 4'hB; i += 4'h1) begin
          _RANDOM[i] = `RANDOM;
        end
        state = _RANDOM[4'h0][1:0];
        stateLastCycle = _RANDOM[4'h0][5:4];
        enqPtrVec_0_flag = _RANDOM[4'h0][6];
        enqPtrVec_0_value = _RANDOM[4'h0][12:7];
        enqPtrVec_1_flag = _RANDOM[4'h0][13];
        enqPtrVec_1_value = _RANDOM[4'h0][19:14];
        enqPtrVec_2_flag = _RANDOM[4'h0][20];
        enqPtrVec_2_value = _RANDOM[4'h0][26:21];
        enqPtrVec_3_flag = _RANDOM[4'h0][27];
        enqPtrVec_3_value = {_RANDOM[4'h0][31:28], _RANDOM[4'h1][1:0]};
        enqPtrVec_4_flag = _RANDOM[4'h1][2];
        enqPtrVec_4_value = _RANDOM[4'h1][8:3];
        enqPtrVec_5_flag = _RANDOM[4'h1][9];
        enqPtrVec_5_value = _RANDOM[4'h1][15:10];
        deqPtrVec_0_flag = _RANDOM[4'h3][16];
        shiftAmount = _RANDOM[4'h3][22:17];
        deqPtrVec_1_flag = _RANDOM[4'h3][23];
        deqPtrVec_1_value = _RANDOM[4'h3][29:24];
        deqPtrVec_2_flag = _RANDOM[4'h3][30];
        deqPtrVec_2_value = {_RANDOM[4'h3][31], _RANDOM[4'h4][4:0]};
        deqPtrVec_3_flag = _RANDOM[4'h4][5];
        deqPtrVec_3_value = _RANDOM[4'h4][11:6];
        deqPtrVec_4_flag = _RANDOM[4'h4][12];
        deqPtrVec_4_value = _RANDOM[4'h4][18:13];
        deqPtrVec_5_flag = _RANDOM[4'h4][19];
        deqPtrVec_5_value = _RANDOM[4'h4][25:20];
        deqPtrVec_6_flag = _RANDOM[4'h4][26];
        deqPtrVec_6_value = {_RANDOM[4'h4][31:27], _RANDOM[4'h5][0]};
        deqPtrVec_7_flag = _RANDOM[4'h5][1];
        deqPtrVec_7_value = _RANDOM[4'h5][7:2];
        deqPtrOH = {_RANDOM[4'h5][31:8], _RANDOM[4'h6], _RANDOM[4'h7][7:0]};
        walkPtr_flag = _RANDOM[4'h9][0];
        walkPtr_value = _RANDOM[4'h9][6:1];
        robWalkEndReg = _RANDOM[4'h9][7];
        commitSize = _RANDOM[4'h9][13:8];
        walkSize = _RANDOM[4'h9][19:14];
        spclWalkSize = _RANDOM[4'h9][25:20];
        useSnapshot = _RANDOM[4'h9][26];
        snapshotVType_illegal = _RANDOM[4'h9][27];
        snapshotVType_vma = _RANDOM[4'h9][28];
        snapshotVType_vta = _RANDOM[4'h9][29];
        snapshotVType_vsew = _RANDOM[4'h9][31:30];
        snapshotVType_vlmul = _RANDOM[4'hA][2:0];
        allowEnqueue_last_REG = _RANDOM[4'hA][3];
        allowEnqueueForDispatch_last_REG = _RANDOM[4'hA][4];
        decodeResumeVType_valid = _RANDOM[4'hA][5];
        decodeResumeVType_bits_illegal = _RANDOM[4'hA][6];
        decodeResumeVType_bits_vma = _RANDOM[4'hA][7];
        decodeResumeVType_bits_vta = _RANDOM[4'hA][8];
        decodeResumeVType_bits_vsew = _RANDOM[4'hA][10:9];
        decodeResumeVType_bits_vlmul = _RANDOM[4'hA][13:11];
        walkToArchVType = _RANDOM[4'hA][14];
      `endif // RANDOMIZE_REG_INIT
      if (reset) begin
        state = 2'h0;
        enqPtrVec_0_flag = 1'h0;
        enqPtrVec_0_value = 6'h0;
        enqPtrVec_1_flag = 1'h0;
        enqPtrVec_1_value = 6'h1;
        enqPtrVec_2_flag = 1'h0;
        enqPtrVec_2_value = 6'h2;
        enqPtrVec_3_flag = 1'h0;
        enqPtrVec_3_value = 6'h3;
        enqPtrVec_4_flag = 1'h0;
        enqPtrVec_4_value = 6'h4;
        enqPtrVec_5_flag = 1'h0;
        enqPtrVec_5_value = 6'h5;
        deqPtrVec_0_flag = 1'h0;
        shiftAmount = 6'h0;
        deqPtrVec_1_flag = 1'h0;
        deqPtrVec_1_value = 6'h1;
        deqPtrVec_2_flag = 1'h0;
        deqPtrVec_2_value = 6'h2;
        deqPtrVec_3_flag = 1'h0;
        deqPtrVec_3_value = 6'h3;
        deqPtrVec_4_flag = 1'h0;
        deqPtrVec_4_value = 6'h4;
        deqPtrVec_5_flag = 1'h0;
        deqPtrVec_5_value = 6'h5;
        deqPtrVec_6_flag = 1'h0;
        deqPtrVec_6_value = 6'h6;
        deqPtrVec_7_flag = 1'h0;
        deqPtrVec_7_value = 6'h7;
        deqPtrOH = 64'h1;
        robWalkEndReg = 1'h0;
        commitSize = 6'h0;
        walkSize = 6'h0;
        spclWalkSize = 6'h0;
        allowEnqueue_last_REG = 1'h1;
        allowEnqueueForDispatch_last_REG = 1'h1;
        decodeResumeVType_valid = 1'h0;
        decodeResumeVType_bits_illegal = 1'h0;
        decodeResumeVType_bits_vma = 1'h0;
        decodeResumeVType_bits_vta = 1'h0;
        decodeResumeVType_bits_vsew = 2'h0;
        decodeResumeVType_bits_vlmul = 3'h0;
        walkToArchVType = 1'h0;
      end
    end // initial
    `ifdef FIRRTL_AFTER_INITIAL
      `FIRRTL_AFTER_INITIAL
    `endif // FIRRTL_AFTER_INITIAL
  `endif // ENABLE_INITIAL_REG_
  SyncDataModuleTemplate__64entry_3 vtypeBuffer (
    .clock                    (clock),
    .reset                    (reset),
    .io_raddr_0
      ((_vtypeBufferReadPtrVecNext_T ? _deqPtrVecNext_0_new_ptr_T_3 : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_1 ? walkPtrNext_value : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_2 ? _deqPtrVecNext_0_new_ptr_T_3 : 6'h0)),
    .io_raddr_1
      ((_vtypeBufferReadPtrVecNext_T ? _deqPtrVecNext_1_new_ptr_T_1[5:0] : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_1 ? 6'(walkPtrNext_value + 6'h1) : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_2 ? _deqPtrVecNext_1_new_ptr_T_1[5:0] : 6'h0)),
    .io_raddr_2
      ((_vtypeBufferReadPtrVecNext_T ? _deqPtrVecNext_2_new_ptr_T_1[5:0] : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_1 ? 6'(walkPtrNext_value + 6'h2) : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_2 ? _deqPtrVecNext_2_new_ptr_T_1[5:0] : 6'h0)),
    .io_raddr_3
      ((_vtypeBufferReadPtrVecNext_T ? _deqPtrVecNext_3_new_ptr_T_1[5:0] : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_1 ? 6'(walkPtrNext_value + 6'h3) : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_2 ? _deqPtrVecNext_3_new_ptr_T_1[5:0] : 6'h0)),
    .io_raddr_4
      ((_vtypeBufferReadPtrVecNext_T ? _deqPtrVecNext_4_new_ptr_T_1[5:0] : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_1 ? 6'(walkPtrNext_value + 6'h4) : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_2 ? _deqPtrVecNext_4_new_ptr_T_1[5:0] : 6'h0)),
    .io_raddr_5
      ((_vtypeBufferReadPtrVecNext_T ? _deqPtrVecNext_5_new_ptr_T_1[5:0] : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_1 ? 6'(walkPtrNext_value + 6'h5) : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_2 ? _deqPtrVecNext_5_new_ptr_T_1[5:0] : 6'h0)),
    .io_raddr_6
      ((_vtypeBufferReadPtrVecNext_T ? _deqPtrVecNext_6_new_ptr_T_1[5:0] : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_1 ? 6'(walkPtrNext_value + 6'h6) : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_2 ? _deqPtrVecNext_6_new_ptr_T_1[5:0] : 6'h0)),
    .io_raddr_7
      ((_vtypeBufferReadPtrVecNext_T ? _deqPtrVecNext_7_new_ptr_T_1[5:0] : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_1 ? 6'(walkPtrNext_value + 6'h7) : 6'h0)
       | (_vtypeBufferReadPtrVecNext_T_2 ? _deqPtrVecNext_7_new_ptr_T_1[5:0] : 6'h0)),
    .io_rdata_0_vtype_illegal (infoVec_0_illegal),
    .io_rdata_0_vtype_vma     (infoVec_0_vma),
    .io_rdata_0_vtype_vta     (infoVec_0_vta),
    .io_rdata_0_vtype_vsew    (infoVec_0_vsew),
    .io_rdata_0_vtype_vlmul   (infoVec_0_vlmul),
    .io_rdata_0_isVsetvl      (_vtypeBuffer_io_rdata_0_isVsetvl),
    .io_rdata_1_vtype_illegal (infoVec_1_illegal),
    .io_rdata_1_vtype_vma     (infoVec_1_vma),
    .io_rdata_1_vtype_vta     (infoVec_1_vta),
    .io_rdata_1_vtype_vsew    (infoVec_1_vsew),
    .io_rdata_1_vtype_vlmul   (infoVec_1_vlmul),
    .io_rdata_1_isVsetvl      (_vtypeBuffer_io_rdata_1_isVsetvl),
    .io_rdata_2_vtype_illegal (infoVec_2_illegal),
    .io_rdata_2_vtype_vma     (infoVec_2_vma),
    .io_rdata_2_vtype_vta     (infoVec_2_vta),
    .io_rdata_2_vtype_vsew    (infoVec_2_vsew),
    .io_rdata_2_vtype_vlmul   (infoVec_2_vlmul),
    .io_rdata_2_isVsetvl      (_vtypeBuffer_io_rdata_2_isVsetvl),
    .io_rdata_3_vtype_illegal (infoVec_3_illegal),
    .io_rdata_3_vtype_vma     (infoVec_3_vma),
    .io_rdata_3_vtype_vta     (infoVec_3_vta),
    .io_rdata_3_vtype_vsew    (infoVec_3_vsew),
    .io_rdata_3_vtype_vlmul   (infoVec_3_vlmul),
    .io_rdata_3_isVsetvl      (_vtypeBuffer_io_rdata_3_isVsetvl),
    .io_rdata_4_vtype_illegal (infoVec_4_illegal),
    .io_rdata_4_vtype_vma     (infoVec_4_vma),
    .io_rdata_4_vtype_vta     (infoVec_4_vta),
    .io_rdata_4_vtype_vsew    (infoVec_4_vsew),
    .io_rdata_4_vtype_vlmul   (infoVec_4_vlmul),
    .io_rdata_4_isVsetvl      (_vtypeBuffer_io_rdata_4_isVsetvl),
    .io_rdata_5_vtype_illegal (infoVec_5_illegal),
    .io_rdata_5_vtype_vma     (infoVec_5_vma),
    .io_rdata_5_vtype_vta     (infoVec_5_vta),
    .io_rdata_5_vtype_vsew    (infoVec_5_vsew),
    .io_rdata_5_vtype_vlmul   (infoVec_5_vlmul),
    .io_rdata_5_isVsetvl      (_vtypeBuffer_io_rdata_5_isVsetvl),
    .io_rdata_6_vtype_illegal (infoVec_6_illegal),
    .io_rdata_6_vtype_vma     (infoVec_6_vma),
    .io_rdata_6_vtype_vta     (infoVec_6_vta),
    .io_rdata_6_vtype_vsew    (infoVec_6_vsew),
    .io_rdata_6_vtype_vlmul   (infoVec_6_vlmul),
    .io_rdata_6_isVsetvl      (_vtypeBuffer_io_rdata_6_isVsetvl),
    .io_rdata_7_vtype_illegal (infoVec_7_illegal),
    .io_rdata_7_vtype_vma     (infoVec_7_vma),
    .io_rdata_7_vtype_vta     (infoVec_7_vta),
    .io_rdata_7_vtype_vsew    (infoVec_7_vsew),
    .io_rdata_7_vtype_vlmul   (infoVec_7_vlmul),
    .io_rdata_7_isVsetvl      (_vtypeBuffer_io_rdata_7_isVsetvl),
    .io_wen_0                 (needAllocVec_0),
    .io_wen_1                 (needAllocVec_1),
    .io_wen_2                 (needAllocVec_2),
    .io_wen_3                 (needAllocVec_3),
    .io_wen_4                 (needAllocVec_4),
    .io_wen_5                 (needAllocVec_5),
    .io_waddr_0               (enqPtrVec_0_value),
    .io_waddr_1               (_GEN_8[{2'h0, needAllocVec_0}]),
    .io_waddr_2               (_GEN_8[_GEN_7]),
    .io_waddr_3               (_GEN_8[{1'h0, 2'(_GEN_2 + _allocPtrVec_T_3)}]),
    .io_waddr_4               (_GEN_8[3'(_GEN_7 + {1'h0, 2'(_GEN_1 + _GEN_4)})]),
    .io_waddr_5
      (_GEN_8[3'(_GEN_7 + {1'h0, 2'(_GEN_1 + 2'(_GEN_4 + _GEN_3))})]),
    .io_wdata_0_vtype_illegal (io_req_0_bits_vpu_vill),
    .io_wdata_0_vtype_vma     (io_req_0_bits_vpu_vma),
    .io_wdata_0_vtype_vta     (io_req_0_bits_vpu_vta),
    .io_wdata_0_vtype_vsew    (io_req_0_bits_vpu_vsew),
    .io_wdata_0_vtype_vlmul   (io_req_0_bits_vpu_vlmul),
    .io_wdata_0_isVsetvl      (io_req_0_bits_fuOpType[6]),
    .io_wdata_1_vtype_illegal (io_req_1_bits_vpu_vill),
    .io_wdata_1_vtype_vma     (io_req_1_bits_vpu_vma),
    .io_wdata_1_vtype_vta     (io_req_1_bits_vpu_vta),
    .io_wdata_1_vtype_vsew    (io_req_1_bits_vpu_vsew),
    .io_wdata_1_vtype_vlmul   (io_req_1_bits_vpu_vlmul),
    .io_wdata_1_isVsetvl      (io_req_1_bits_fuOpType[6]),
    .io_wdata_2_vtype_illegal (io_req_2_bits_vpu_vill),
    .io_wdata_2_vtype_vma     (io_req_2_bits_vpu_vma),
    .io_wdata_2_vtype_vta     (io_req_2_bits_vpu_vta),
    .io_wdata_2_vtype_vsew    (io_req_2_bits_vpu_vsew),
    .io_wdata_2_vtype_vlmul   (io_req_2_bits_vpu_vlmul),
    .io_wdata_2_isVsetvl      (io_req_2_bits_fuOpType[6]),
    .io_wdata_3_vtype_illegal (io_req_3_bits_vpu_vill),
    .io_wdata_3_vtype_vma     (io_req_3_bits_vpu_vma),
    .io_wdata_3_vtype_vta     (io_req_3_bits_vpu_vta),
    .io_wdata_3_vtype_vsew    (io_req_3_bits_vpu_vsew),
    .io_wdata_3_vtype_vlmul   (io_req_3_bits_vpu_vlmul),
    .io_wdata_3_isVsetvl      (io_req_3_bits_fuOpType[6]),
    .io_wdata_4_vtype_illegal (io_req_4_bits_vpu_vill),
    .io_wdata_4_vtype_vma     (io_req_4_bits_vpu_vma),
    .io_wdata_4_vtype_vta     (io_req_4_bits_vpu_vta),
    .io_wdata_4_vtype_vsew    (io_req_4_bits_vpu_vsew),
    .io_wdata_4_vtype_vlmul   (io_req_4_bits_vpu_vlmul),
    .io_wdata_4_isVsetvl      (io_req_4_bits_fuOpType[6]),
    .io_wdata_5_vtype_illegal (io_req_5_bits_vpu_vill),
    .io_wdata_5_vtype_vma     (io_req_5_bits_vpu_vma),
    .io_wdata_5_vtype_vta     (io_req_5_bits_vpu_vta),
    .io_wdata_5_vtype_vsew    (io_req_5_bits_vpu_vsew),
    .io_wdata_5_vtype_vlmul   (io_req_5_bits_vpu_vlmul),
    .io_wdata_5_isVsetvl      (io_req_5_bits_fuOpType[6])
  );
  SnapshotGenerator_1 walkPtrSnapshots_snapshotGen (
    .clock                (clock),
    .reset                (reset),
    .io_enq               (io_snpt_snptEnq),
    .io_enqData_flag      (enqPtrVec_0_flag),
    .io_enqData_value     (enqPtrVec_0_value),
    .io_deq               (io_snpt_snptDeq),
    .io_redirect          (io_redirect_valid),
    .io_flushVec_0        (io_snpt_flushVec_0),
    .io_flushVec_1        (io_snpt_flushVec_1),
    .io_flushVec_2        (io_snpt_flushVec_2),
    .io_flushVec_3        (io_snpt_flushVec_3),
    .io_snapshots_0_flag  (_walkPtrSnapshots_snapshotGen_io_snapshots_0_flag),
    .io_snapshots_0_value (_walkPtrSnapshots_snapshotGen_io_snapshots_0_value),
    .io_snapshots_1_flag  (_walkPtrSnapshots_snapshotGen_io_snapshots_1_flag),
    .io_snapshots_1_value (_walkPtrSnapshots_snapshotGen_io_snapshots_1_value),
    .io_snapshots_2_flag  (_walkPtrSnapshots_snapshotGen_io_snapshots_2_flag),
    .io_snapshots_2_value (_walkPtrSnapshots_snapshotGen_io_snapshots_2_value),
    .io_snapshots_3_flag  (_walkPtrSnapshots_snapshotGen_io_snapshots_3_flag),
    .io_snapshots_3_value (_walkPtrSnapshots_snapshotGen_io_snapshots_3_value)
  );
  SnapshotGenerator_2 walkVTypeSnapshots_snapshotGen (
    .clock                  (clock),
    .reset                  (reset),
    .io_enq                 (io_snpt_snptEnq),
    .io_enqData_illegal
      (io_req_0_valid
         ? io_req_0_bits_vpu_specVill
         : io_req_1_valid
             ? io_req_1_bits_vpu_specVill
             : io_req_2_valid
                 ? io_req_2_bits_vpu_specVill
                 : io_req_3_valid
                     ? io_req_3_bits_vpu_specVill
                     : io_req_4_valid
                         ? io_req_4_bits_vpu_specVill
                         : io_req_5_bits_vpu_specVill),
    .io_enqData_vma
      (io_req_0_valid
         ? io_req_0_bits_vpu_specVma
         : io_req_1_valid
             ? io_req_1_bits_vpu_specVma
             : io_req_2_valid
                 ? io_req_2_bits_vpu_specVma
                 : io_req_3_valid
                     ? io_req_3_bits_vpu_specVma
                     : io_req_4_valid
                         ? io_req_4_bits_vpu_specVma
                         : io_req_5_bits_vpu_specVma),
    .io_enqData_vta
      (io_req_0_valid
         ? io_req_0_bits_vpu_specVta
         : io_req_1_valid
             ? io_req_1_bits_vpu_specVta
             : io_req_2_valid
                 ? io_req_2_bits_vpu_specVta
                 : io_req_3_valid
                     ? io_req_3_bits_vpu_specVta
                     : io_req_4_valid
                         ? io_req_4_bits_vpu_specVta
                         : io_req_5_bits_vpu_specVta),
    .io_enqData_vsew
      (io_req_0_valid
         ? io_req_0_bits_vpu_specVsew
         : io_req_1_valid
             ? io_req_1_bits_vpu_specVsew
             : io_req_2_valid
                 ? io_req_2_bits_vpu_specVsew
                 : io_req_3_valid
                     ? io_req_3_bits_vpu_specVsew
                     : io_req_4_valid
                         ? io_req_4_bits_vpu_specVsew
                         : io_req_5_bits_vpu_specVsew),
    .io_enqData_vlmul
      (io_req_0_valid
         ? io_req_0_bits_vpu_specVlmul
         : io_req_1_valid
             ? io_req_1_bits_vpu_specVlmul
             : io_req_2_valid
                 ? io_req_2_bits_vpu_specVlmul
                 : io_req_3_valid
                     ? io_req_3_bits_vpu_specVlmul
                     : io_req_4_valid
                         ? io_req_4_bits_vpu_specVlmul
                         : io_req_5_bits_vpu_specVlmul),
    .io_deq                 (io_snpt_snptDeq),
    .io_redirect            (io_redirect_valid),
    .io_flushVec_0          (io_snpt_flushVec_0),
    .io_flushVec_1          (io_snpt_flushVec_1),
    .io_flushVec_2          (io_snpt_flushVec_2),
    .io_flushVec_3          (io_snpt_flushVec_3),
    .io_snapshots_0_illegal (_walkVTypeSnapshots_snapshotGen_io_snapshots_0_illegal),
    .io_snapshots_0_vma     (_walkVTypeSnapshots_snapshotGen_io_snapshots_0_vma),
    .io_snapshots_0_vta     (_walkVTypeSnapshots_snapshotGen_io_snapshots_0_vta),
    .io_snapshots_0_vsew    (_walkVTypeSnapshots_snapshotGen_io_snapshots_0_vsew),
    .io_snapshots_0_vlmul   (_walkVTypeSnapshots_snapshotGen_io_snapshots_0_vlmul),
    .io_snapshots_1_illegal (_walkVTypeSnapshots_snapshotGen_io_snapshots_1_illegal),
    .io_snapshots_1_vma     (_walkVTypeSnapshots_snapshotGen_io_snapshots_1_vma),
    .io_snapshots_1_vta     (_walkVTypeSnapshots_snapshotGen_io_snapshots_1_vta),
    .io_snapshots_1_vsew    (_walkVTypeSnapshots_snapshotGen_io_snapshots_1_vsew),
    .io_snapshots_1_vlmul   (_walkVTypeSnapshots_snapshotGen_io_snapshots_1_vlmul),
    .io_snapshots_2_illegal (_walkVTypeSnapshots_snapshotGen_io_snapshots_2_illegal),
    .io_snapshots_2_vma     (_walkVTypeSnapshots_snapshotGen_io_snapshots_2_vma),
    .io_snapshots_2_vta     (_walkVTypeSnapshots_snapshotGen_io_snapshots_2_vta),
    .io_snapshots_2_vsew    (_walkVTypeSnapshots_snapshotGen_io_snapshots_2_vsew),
    .io_snapshots_2_vlmul   (_walkVTypeSnapshots_snapshotGen_io_snapshots_2_vlmul),
    .io_snapshots_3_illegal (_walkVTypeSnapshots_snapshotGen_io_snapshots_3_illegal),
    .io_snapshots_3_vma     (_walkVTypeSnapshots_snapshotGen_io_snapshots_3_vma),
    .io_snapshots_3_vta     (_walkVTypeSnapshots_snapshotGen_io_snapshots_3_vta),
    .io_snapshots_3_vsew    (_walkVTypeSnapshots_snapshotGen_io_snapshots_3_vsew),
    .io_snapshots_3_vlmul   (_walkVTypeSnapshots_snapshotGen_io_snapshots_3_vlmul)
  );
  assign io_canEnq = allowEnqueue_last_REG & ~(|state);
  assign io_canEnqForDispatch = allowEnqueueForDispatch_last_REG & ~(|state);
  assign io_toDecode_isResumeVType = (|state) | decodeResumeVType_valid;
  assign io_toDecode_walkToArchVType = walkToArchVType;
  assign io_toDecode_walkVType_valid = decodeResumeVType_valid;
  assign io_toDecode_walkVType_bits_illegal =
    decodeResumeVType_valid & decodeResumeVType_bits_illegal;
  assign io_toDecode_walkVType_bits_vma =
    decodeResumeVType_valid & decodeResumeVType_bits_vma;
  assign io_toDecode_walkVType_bits_vta =
    decodeResumeVType_valid & decodeResumeVType_bits_vta;
  assign io_toDecode_walkVType_bits_vsew =
    decodeResumeVType_valid ? decodeResumeVType_bits_vsew : 2'h0;
  assign io_toDecode_walkVType_bits_vlmul =
    decodeResumeVType_valid ? decodeResumeVType_bits_vlmul : 3'h0;
  assign io_toDecode_commitVType_vtype_valid = |_commitVTypeValid_T;
  assign io_toDecode_commitVType_vtype_bits_illegal = newestArchVType_illegal;
  assign io_toDecode_commitVType_vtype_bits_vma = newestArchVType_vma;
  assign io_toDecode_commitVType_vtype_bits_vta = newestArchVType_vta;
  assign io_toDecode_commitVType_vtype_bits_vsew = newestArchVType_vsew;
  assign io_toDecode_commitVType_vtype_bits_vlmul = newestArchVType_vlmul;
  assign io_toDecode_commitVType_hasVsetvl =
    commitValidVec_0 & _vtypeBuffer_io_rdata_0_isVsetvl | commitValidVec_1
    & _vtypeBuffer_io_rdata_1_isVsetvl | commitValidVec_2
    & _vtypeBuffer_io_rdata_2_isVsetvl | commitValidVec_3
    & _vtypeBuffer_io_rdata_3_isVsetvl | commitValidVec_4
    & _vtypeBuffer_io_rdata_4_isVsetvl | commitValidVec_5
    & _vtypeBuffer_io_rdata_5_isVsetvl | commitValidVec_6
    & _vtypeBuffer_io_rdata_6_isVsetvl | commitValidVec_7
    & _vtypeBuffer_io_rdata_7_isVsetvl;
  assign io_status_walkEnd = walkEndNext;
endmodule


