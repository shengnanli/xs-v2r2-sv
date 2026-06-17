// =============================================================================
// xs_CompressUnit_core —— 香山 V2R2(昆明湖) ROB 压缩单元核(可读重写)
// -----------------------------------------------------------------------------
// 对应 Scala 源:xiangshan.backend.rename.CompressUnit。纯组合叶子。
//
// 输入:每拍 RENAME_WIDTH(=6) 条候选指令的若干属性(见 compress_in_t)。
// 输出:canCompressVec / needRobFlags / instrSizes / masks(语义见 pkg 头注)。
//
// 【算法(直接来自 Scala 设计意图)】
//   1) 先算每条 lane 的"可压缩"位 canCompress[i]:
//        valid 且 非 fusion 且 是末 uop(lastUop) 且 无异常/非调试触发 且 canRobCompress。
//   2) 把 canCompress 当作 6 位 key,**两端各补一个 0** 成 8 位 padded key(下标 1..6
//      对应 lane 0..5,下标 0 与 7 是哨兵 0)。这样"游程"统计无需特判边界。
//   3) 对每条 lane i(padded 下标 1..6):
//        - cntL(i): 从 i 向左数连续 1 的个数(含自身),遇 0 停。
//        - cntR(i): 从 i 向右数连续 1 的个数(含自身),遇 0 停。
//        - needRob[i] = ~(key[i] & key[i+1]):若右邻也是 1 则本条并入右边(不需 ROB);
//                       否则本条是"组末"或"不可压缩",需独占 ROB 表项。
//        - size[i]   = key[i] ? cntL(i)+cntR(i)-1 : 1  (所在游程长度;不可压则 1)。
//        - mask[i]   = key[i] ? 游程区间[i-cntL+1 .. i+cntR-1] 全 1 : 仅自身位。
//   Scala 把这一函数对 2^6=64 种 key 预计算成 DecodeLogic 真值表;此处用逐 lane
//   的组合游程统计**等价重建**,可读且无需查找表。
// =============================================================================
import compressunit_pkg::*;

module xs_CompressUnit_core (
  input  compress_in_t [RENAME_WIDTH-1:0] in,
  output logic         [RENAME_WIDTH-1:0]              can_compress_vec,
  output logic         [RENAME_WIDTH-1:0]              need_rob_flags,
  output logic         [RENAME_WIDTH-1:0][SIZE_W-1:0]  instr_sizes,
  output logic         [RENAME_WIDTH-1:0][MASK_W-1:0]  masks
);

  // ---------------------------------------------------------------------------
  // 1. 逐 lane 的"可压缩"判定。
  //    noExc:无任何异常 且 触发动作不是 DebugMode(进调试不能压)。
  // ---------------------------------------------------------------------------
  logic [RENAME_WIDTH-1:0] can_compress;

  always_comb begin
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      automatic logic no_exc = (in[i].exceptionVec == '0)
                             && (in[i].trigger != TRIGGER_DEBUG_MODE);
      automatic logic not_fused = ~in[i].commitType[2]; // CommitType.isFused = bit2
      can_compress[i] = in[i].valid
                      & not_fused
                      & in[i].lastUop
                      & no_exc
                      & in[i].canRobCompress;
    end
  end

  // ---------------------------------------------------------------------------
  // 2. 两端补 0 的 padded key(8 位):key[0]=key[7]=0 哨兵,key[1..6]=can_compress[0..5]。
  //    用 padded 下标 (lane+1) 访问。
  // ---------------------------------------------------------------------------
  logic [RENAME_WIDTH+1:0] key; // [7:0]
  always_comb begin
    key            = '0;
    key[RENAME_WIDTH:1] = can_compress; // 下标 1..6
  end

  // ---------------------------------------------------------------------------
  // 3. 游程统计函数(在 padded key 上,含自身):
  //    cnt_left(p)  : 从 p 向左(下标递减)数连续 1 的个数,遇 0 即停。
  //    cnt_right(p) : 从 p 向右(下标递增)数连续 1 的个数,遇 0 即停。
  //    若 key[p]==0 则两者均为 0。
  // ---------------------------------------------------------------------------
  function automatic int cnt_left(input logic [RENAME_WIDTH+1:0] k, input int p);
    int n;
    n = 0;
    for (int j = p; j >= 0; j--) begin
      if (k[j]) n++;
      else      break;
    end
    return n;
  endfunction

  function automatic int cnt_right(input logic [RENAME_WIDTH+1:0] k, input int p);
    int n;
    n = 0;
    for (int j = p; j <= RENAME_WIDTH+1; j++) begin
      if (k[j]) n++;
      else      break;
    end
    return n;
  endfunction

  // ---------------------------------------------------------------------------
  // 4. 逐 lane 产出 needRob / size / mask。
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      automatic int p  = i + 1;            // padded 下标
      automatic int cl = cnt_left (key, p);
      automatic int cr = cnt_right(key, p);

      // needRob:右邻也是 1 → 并入右边(0);否则本条需独占 ROB(1)。
      need_rob_flags[i] = ~(key[p] & key[p+1]);

      if (!key[p]) begin
        // 不可压缩:独占 1 个表项,mask 仅自身。
        instr_sizes[i] = SIZE_W'(1);
        masks[i]       = MASK_W'(1) << i;
      end else begin
        // 可压缩:组大小 = 所在游程长度;mask = 游程覆盖的全部 lane。
        automatic int run_len = cl + cr - 1;          // 含自身只算一次
        automatic int lo      = i - (cl - 1);         // 游程最左 lane(0-based)
        automatic int hi      = i + (cr - 1);         // 游程最右 lane(0-based)
        automatic logic [MASK_W-1:0] m = '0;
        instr_sizes[i] = SIZE_W'(run_len);
        // 固定上界遍历所有 lane,落在 [lo,hi] 区间的置 1(便于 Formality 静态展开)。
        for (int b = 0; b < RENAME_WIDTH; b++)
          if (b >= lo && b <= hi) m[b] = 1'b1;
        masks[i] = m;
      end
    end
  end

  assign can_compress_vec = can_compress;

endmodule
