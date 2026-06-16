// =============================================================================
//  mainpipe_pkg —— L1 DCache MainPipe（主流水）类型/常量/纯函数包
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/cache/dcache/mainpipe/MainPipe.scala
//                + rocket-chip tilelink Metadata.scala / Bundles.scala（一致性协议）
//                + rocket-chip rocket/Consts.scala（M_* 访存命令编码）
//
//  本包集中表达 MainPipe 的「微架构词汇表」：
//    * 请求来源/命令/一致性状态的 enum；
//    * 本配置（昆明湖 V2R2）固化的几何参数（4 way / 8 bank / 256 set …）；
//    * MESI 一致性状态机的纯函数（onAccess / onProbe / missCohGen）；
//    * store/AMO 数据逐字节合并、bank mask、tag ECC 纠检错等纯函数。
//
//  MainPipe 是 L1 DCache 的「写侧主流水」：store / probe / atomic(AMO/LR/SC) /
//  refill / replace 这五类请求都从这里流过 s0~s3 四级，读写 Meta/Tag/Data 三大阵列，
//  做命中判定与一致性状态转换，触发写回（WritebackQueue）与补块（MissQueue）。
//  load 走单独的 LoadPipe，不经过这里（只通过 io.data_read 抢占 data SRAM 端口）。
// =============================================================================
package mainpipe_pkg;

  // ---------------------------------------------------------------------------
  // 1. 几何参数（本顶层配置固化值，golden firtool 已按此展平）
  // ---------------------------------------------------------------------------
  localparam int N_WAYS        = 4;    // 组相联路数 nWays
  localparam int WAY_BITS      = 2;    // log2(N_WAYS)
  localparam int IDX_BITS      = 8;    // set index 位宽（256 组），vaddr[13:6]
  localparam int N_BANKS       = 8;    // DCacheBanks：一个 cacheline 切 8 个 bank
  localparam int BANK_BITS     = 3;    // log2(N_BANKS)，= word_idx 位宽
  localparam int ROW_BITS      = 64;   // DCacheSRAMRowBits：每 bank 一拍数据宽度
  localparam int ROW_BYTES     = 8;    // DCacheSRAMRowBytes
  localparam int WORD_BITS     = 64;   // wordBits / DataBits：AMO 字宽
  localparam int WORD_BYTES    = 8;
  localparam int BLOCK_BITS    = 512;  // cfg.blockBytes*8：整 cacheline 数据宽
  localparam int BLOCK_BYTES   = 64;
  localparam int QUAD_BITS     = 128;  // QuadWordBits：AMOCAS.Q 用 128 位
  localparam int QUAD_BYTES    = 16;
  localparam int VADDR_BITS    = 50;   // VAddrBits
  localparam int PADDR_BITS    = 48;   // PAddrBits
  localparam int TAG_BITS      = 36;   // tagBits = PAddrBits - untagBits(=12)
  localparam int ENC_TAG_BITS  = 43;   // encTagBits = 36 + 7 (SECDED ECC)
  localparam int N_MISS_ENTRY  = 16;   // cfg.nMissEntries
  localparam int MISS_ID_BITS  = 4;    // log2Up(nMissEntries)
  localparam int REQ_ID_BITS   = 6;    // reqIdWidth
  localparam int PF_SRC_BITS   = 3;    // L1PfSourceBits
  localparam int N_DUP_STATUS  = 24;   // nDupStatus：s1/s2/s3 状态信息的扇出复制份数
  localparam int LRSC_CYCLES   = 64;   // LRSCCycles：LR 保留锁的存活拍数
  localparam int LRSC_BACKOFF  = 3;    // LRSCBackOff
  localparam int LRSC_CNT_BITS = 6;    // log2Ceil(LRSCCycles)
  localparam int BLOOM_ADDR_BITS = 12; // BloomQuery 地址宽

  // ---------------------------------------------------------------------------
  // 2. 请求来源 source（4 bit 字段，对应 DCacheWrapper 的 *_SOURCE）
  //    probe 不看 source（用 req.probe 标志）；store/AMO/refill 用 source 区分。
  // ---------------------------------------------------------------------------
  typedef enum logic [3:0] {
    SRC_LOAD     = 4'd0,
    SRC_STORE    = 4'd1,
    SRC_AMO      = 4'd2,
    SRC_PREFETCH = 4'd3
  } src_e;

  // ---------------------------------------------------------------------------
  // 3. 一致性状态 ClientStates（MESI 在 TileLink 客户端侧的 2bit 编码）
  //    Nothing=Invalid，Branch=Shared(只读)，Trunk=Exclusive(可写未脏)，Dirty=Modified
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    COH_NOTHING = 2'd0,
    COH_BRANCH  = 2'd1,
    COH_TRUNK   = 2'd2,
    COH_DIRTY   = 2'd3
  } coh_e;

  // TLPermissions：Cap（probe 想把权限降到）、Grow（acquire 想把权限升到）、
  // Report/Shrink（probe 应答里报告的降级类型）。bdWidth=2。
  localparam logic [1:0] PERM_toT = 2'd0;
  localparam logic [1:0] PERM_toB = 2'd1;
  localparam logic [1:0] PERM_toN = 2'd2;
  localparam logic [1:0] PERM_NtoB = 2'd0; // grow
  localparam logic [1:0] PERM_NtoT = 2'd1;
  localparam logic [1:0] PERM_BtoT = 2'd2;
  localparam logic [2:0] PERM_TtoB = 3'd0; // shrink/report (cWidth=3)
  localparam logic [2:0] PERM_TtoN = 3'd1;
  localparam logic [2:0] PERM_BtoN = 3'd2;
  localparam logic [2:0] PERM_TtoT = 3'd3;
  localparam logic [2:0] PERM_BtoB = 3'd4;
  localparam logic [2:0] PERM_NtoN = 3'd5;

  // ---------------------------------------------------------------------------
  // 4. 访存命令 M_*（rocket Consts.scala，M_SZ=5 位）
  // ---------------------------------------------------------------------------
  localparam logic [4:0] M_XRD     = 5'b00000;
  localparam logic [4:0] M_XWR     = 5'b00001;
  localparam logic [4:0] M_PFR     = 5'b00010;
  localparam logic [4:0] M_PFW     = 5'b00011;
  localparam logic [4:0] M_XA_SWAP = 5'b00100;
  localparam logic [4:0] M_XLR     = 5'b00110;
  localparam logic [4:0] M_XSC     = 5'b00111;
  localparam logic [4:0] M_XA_ADD  = 5'b01000;
  localparam logic [4:0] M_XA_XOR  = 5'b01001;
  localparam logic [4:0] M_XA_OR   = 5'b01010;
  localparam logic [4:0] M_XA_AND  = 5'b01011;
  localparam logic [4:0] M_XA_MIN  = 5'b01100;
  localparam logic [4:0] M_XA_MAX  = 5'b01101;
  localparam logic [4:0] M_XA_MINU = 5'b01110;
  localparam logic [4:0] M_XA_MAXU = 5'b01111;
  localparam logic [4:0] M_FLUSH   = 5'b10000;
  localparam logic [4:0] M_PWR     = 5'b10001;
  localparam logic [4:0] M_PRODUCE = 5'b10010;
  localparam logic [4:0] M_CLEAN   = 5'b10011;
  localparam logic [4:0] M_XA_CASQ = 5'b11000;
  localparam logic [4:0] M_XA_CASW = 5'b11010;
  localparam logic [4:0] M_XA_CASD = 5'b11011;

  // 命令类别判定（rocket Consts.scala）
  function automatic logic is_amo_logical(input logic [4:0] cmd);
    return cmd == M_XA_SWAP || cmd == M_XA_XOR || cmd == M_XA_OR || cmd == M_XA_AND;
  endfunction
  function automatic logic is_amo_arith(input logic [4:0] cmd);
    return cmd == M_XA_ADD  || cmd == M_XA_MIN || cmd == M_XA_MAX
        || cmd == M_XA_MINU || cmd == M_XA_MAXU;
  endfunction
  function automatic logic is_amo_cas(input logic [4:0] cmd);
    return cmd == M_XA_CASW || cmd == M_XA_CASD || cmd == M_XA_CASQ;
  endfunction
  function automatic logic is_amo_cas_q(input logic [4:0] cmd);
    return cmd == M_XA_CASQ;
  endfunction
  function automatic logic is_amo(input logic [4:0] cmd);
    return is_amo_logical(cmd) || is_amo_arith(cmd) || is_amo_cas(cmd);
  endfunction
  function automatic logic is_write(input logic [4:0] cmd);
    return cmd == M_XWR || cmd == M_PWR || cmd == M_XSC || is_amo(cmd);
  endfunction
  function automatic logic is_write_intent(input logic [4:0] cmd);
    return is_write(cmd) || cmd == M_PFW || cmd == M_XLR;
  endfunction
  // categorize：{isWrite, isWriteIntent}（rd=00 / wi=01 / wr=11）
  function automatic logic [1:0] categorize(input logic [4:0] cmd);
    return {is_write(cmd), is_write_intent(cmd)};
  endfunction

  // ---------------------------------------------------------------------------
  // 5. 一致性状态机纯函数（对应 ClientMetadata 的 growStarter / shrinkHelper）
  // ---------------------------------------------------------------------------
  // onAccess.growStarter：当前 coh 下执行 cmd 是否命中(has_permission)、未命中时
  // 升权 param、命中时新状态。返回 {has_perm, grow_param[1:0], new_coh[1:0]}。
  // grow_param 仅在 miss 路径有意义；s1 据此判 BtoT（写 Branch 行需升 Trunk）。
  function automatic logic [4:0] grow_starter(input logic [1:0] cmd_cat,
                                              input coh_e state);
    logic has_perm; logic [1:0] grow; coh_e next_coh;
    has_perm  = 1'b0; grow = PERM_NtoB; next_coh = COH_NOTHING;
    case ({cmd_cat, state})
      {2'b00, COH_DIRTY}  : begin has_perm=1; next_coh=COH_DIRTY;  end // rd
      {2'b00, COH_TRUNK}  : begin has_perm=1; next_coh=COH_TRUNK;  end
      {2'b00, COH_BRANCH} : begin has_perm=1; next_coh=COH_BRANCH; end
      {2'b01, COH_DIRTY}  : begin has_perm=1; next_coh=COH_DIRTY;  end // wi
      {2'b01, COH_TRUNK}  : begin has_perm=1; next_coh=COH_TRUNK;  end
      {2'b11, COH_DIRTY}  : begin has_perm=1; next_coh=COH_DIRTY;  end // wr
      {2'b11, COH_TRUNK}  : begin has_perm=1; next_coh=COH_DIRTY;  end
      {2'b00, COH_NOTHING}: begin has_perm=0; grow=PERM_NtoB; end
      {2'b01, COH_BRANCH} : begin has_perm=0; grow=PERM_BtoT; end
      {2'b01, COH_NOTHING}: begin has_perm=0; grow=PERM_NtoT; end
      {2'b11, COH_BRANCH} : begin has_perm=0; grow=PERM_BtoT; end
      {2'b11, COH_NOTHING}: begin has_perm=0; grow=PERM_NtoT; end
      default             : ;
    endcase
    return {has_perm, grow, next_coh};
  endfunction

  // shrinkHelper：probe/降权请求 wanted（toT/toB/toN）作用于当前 state，
  // 返回 {has_dirty_data, shrink_param[2:0], next_coh[1:0]}。
  // 用于 probe 应答（probe_param 直接是 wanted）与 cache control flush（M_FLUSH→toN）。
  function automatic logic [5:0] shrink_helper(input logic [1:0] wanted,
                                               input coh_e state);
    logic dirty; logic [2:0] param; coh_e next_coh;
    // 默认对齐 golden MuxLookup 缺省值 (false, 0, 0)：param=TtoB(0)、next=Nothing。
    // 注意 probe_param 取值可能落在 {toT,toB,toN} 之外（如 3），此时取此缺省。
    dirty = 1'b0; param = PERM_TtoB; next_coh = COH_NOTHING;
    case ({wanted, state})
      {PERM_toT, COH_DIRTY}  : begin dirty=1; param=PERM_TtoT; next_coh=COH_TRUNK;   end
      {PERM_toT, COH_TRUNK}  : begin dirty=0; param=PERM_TtoT; next_coh=COH_TRUNK;   end
      {PERM_toT, COH_BRANCH} : begin dirty=0; param=PERM_BtoB; next_coh=COH_BRANCH;  end
      {PERM_toT, COH_NOTHING}: begin dirty=0; param=PERM_NtoN; next_coh=COH_NOTHING; end
      {PERM_toB, COH_DIRTY}  : begin dirty=1; param=PERM_TtoB; next_coh=COH_BRANCH;  end
      {PERM_toB, COH_TRUNK}  : begin dirty=0; param=PERM_TtoB; next_coh=COH_BRANCH;  end
      {PERM_toB, COH_BRANCH} : begin dirty=0; param=PERM_BtoB; next_coh=COH_BRANCH;  end
      {PERM_toB, COH_NOTHING}: begin dirty=0; param=PERM_NtoN; next_coh=COH_NOTHING; end
      {PERM_toN, COH_DIRTY}  : begin dirty=1; param=PERM_TtoN; next_coh=COH_NOTHING; end
      {PERM_toN, COH_TRUNK}  : begin dirty=0; param=PERM_TtoN; next_coh=COH_NOTHING; end
      {PERM_toN, COH_BRANCH} : begin dirty=0; param=PERM_BtoN; next_coh=COH_NOTHING; end
      {PERM_toN, COH_NOTHING}: begin dirty=0; param=PERM_NtoN; next_coh=COH_NOTHING; end
      default                : ;
    endcase
    return {dirty, param, next_coh};
  endfunction

  // missCohGen：miss refill 完成时，依据 cmd 类别 + grant param + miss_dirty
  // 推出新一致性状态（对应 Scala 的 missCohGen MuxLookup）。
  function automatic coh_e miss_coh_gen(input logic [1:0] cmd_cat,
                                        input logic [1:0] param,
                                        input logic dirty);
    case ({cmd_cat, param, dirty})
      {2'b00, PERM_toB, 1'b0}: return COH_BRANCH; // rd,toB
      {2'b00, PERM_toB, 1'b1}: return COH_BRANCH;
      {2'b00, PERM_toT, 1'b0}: return COH_TRUNK;  // rd,toT
      {2'b00, PERM_toT, 1'b1}: return COH_DIRTY;
      {2'b01, PERM_toT, 1'b0}: return COH_TRUNK;  // wi,toT
      {2'b01, PERM_toT, 1'b1}: return COH_DIRTY;
      {2'b11, PERM_toT, 1'b0}: return COH_DIRTY;  // wr,toT
      {2'b11, PERM_toT, 1'b1}: return COH_DIRTY;
      default                : return COH_NOTHING;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // 6. 数据 / mask 纯函数
  // ---------------------------------------------------------------------------
  // 逐字节写合并：wmask 每 bit 控制一个字节，1 取 new、0 保留 old。
  function automatic logic [ROW_BITS-1:0] merge_put(input logic [ROW_BITS-1:0] old_data,
                                                    input logic [ROW_BITS-1:0] new_data,
                                                    input logic [ROW_BYTES-1:0] wmask);
    logic [ROW_BITS-1:0] full;
    for (int b = 0; b < ROW_BYTES; b++) full[b*8 +: 8] = {8{wmask[b]}};
    return (~full & old_data) | (full & new_data);
  endfunction

  // 取第 i 个 bank 的 64 位数据 / 8 位 mask（block 按 bank 顺序切片）。
  function automatic logic [ROW_BITS-1:0] data_of_bank(input int i,
                                                       input logic [BLOCK_BITS-1:0] blk);
    return blk[i*ROW_BITS +: ROW_BITS];
  endfunction
  function automatic logic [ROW_BYTES-1:0] mask_of_bank(input int i,
                                                        input logic [BLOCK_BYTES-1:0] m);
    return m[i*ROW_BYTES +: ROW_BYTES];
  endfunction

  // ---------------------------------------------------------------------------
  // 7. 地址切分（vaddr/addr → idx/tag）
  // ---------------------------------------------------------------------------
  // get_idx：set index 取 vaddr[13:6]（6=blockOffsetBits，8=idxBits）。
  function automatic logic [IDX_BITS-1:0] get_idx(input logic [VADDR_BITS-1:0] vaddr);
    return vaddr[6 +: IDX_BITS];
  endfunction
  // get_tag：物理 tag 取 addr[47:12]（12=untagBits）。
  function automatic logic [TAG_BITS-1:0] get_tag(input logic [PADDR_BITS-1:0] addr);
    return addr[12 +: TAG_BITS];
  endfunction
  // 直接映射 way（pseudo error 注入用），= vaddr[set 之上的 2 位]。
  function automatic logic [WAY_BITS-1:0] direct_map_way(input logic [VADDR_BITS-1:0] vaddr);
    return vaddr[14 +: WAY_BITS];
  endfunction

  // ---------------------------------------------------------------------------
  // 8. tag SECDED ECC 纠检错（EnableTagEcc=true）
  //    encTag = {ecc[6:0], tag[35:0]}，共 43 位。decode().error 当：
  //    syndrome 非全 0（单/双比特错）。本配置 tagCode 为固定 SECDED 矩阵，
  //    error = (整体奇偶 != 0) || (整体偶 && 任一校验子非 0)。常量矩阵照搬 golden。
  // ---------------------------------------------------------------------------
  function automatic logic tag_ecc_error(input logic [ENC_TAG_BITS-1:0] enc);
    logic overall_parity;
    logic [5:0] synd;
    overall_parity = ^enc;
    synd[0] = ^({enc[41:26] & 16'h83FF, 26'h0});
    synd[1] = ^({enc[40:11] & 30'h20007FFF, 11'h0});
    synd[2] = ^({enc[39:4]  & 36'h8E03FC07F, 4'h0});
    synd[3] = ^({enc[38:1]  & 38'h20F1E1E3C7, 1'h0});
    synd[4] = ^(enc[37:0]   & 38'h299B33366D);
    synd[5] = ^(enc[36:0]   & 37'h1556AAAD5B);
    return overall_parity | (~overall_parity & (|synd));
  endfunction

  // ---------------------------------------------------------------------------
  // 9. one-hot / 优先级编码辅助
  // ---------------------------------------------------------------------------
  // 4-way one-hot → way 编号（用于 replace_access.way = OHToUInt(way_en)）。
  function automatic logic [WAY_BITS-1:0] oh_to_way(input logic [N_WAYS-1:0] oh);
    logic [WAY_BITS-1:0] r;
    r = '0;
    for (int w = 0; w < N_WAYS; w++) if (oh[w]) r = w[WAY_BITS-1:0];
    return r;
  endfunction
  // 最低位优先的 one-hot（PriorityEncoderOH）。
  function automatic logic [N_WAYS-1:0] priority_oh(input logic [N_WAYS-1:0] v);
    logic [N_WAYS-1:0] r;
    r = '0;
    for (int w = 0; w < N_WAYS; w++)
      if (v[w] && r == '0) r = (1 << w);
    return r;
  endfunction

  // ---------------------------------------------------------------------------
  // 10. MainPipeReq —— 仲裁后进入 s0 的统一请求 payload
  //     （probe / refill / store / atomic 四源经 Arbiter4 合并成此结构）
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic                     miss;                        // 仅 AMO miss 会在主流水补块
    logic [MISS_ID_BITS-1:0]  miss_id;
    logic [1:0]               miss_param;                  // refill grant param
    logic                     miss_dirty;
    logic [N_WAYS-1:0]        occupy_way;
    logic                     miss_fail_cause_evict_btot;
    logic                     probe;
    logic [1:0]               probe_param;
    logic                     probe_need_data;
    src_e                     source;
    logic [4:0]               cmd;
    logic [VADDR_BITS-1:0]    vaddr;
    logic [PADDR_BITS-1:0]    addr;
    logic [BLOCK_BITS-1:0]    store_data;
    logic [BLOCK_BYTES-1:0]   store_mask;
    logic [BANK_BITS-1:0]     word_idx;
    logic [QUAD_BITS-1:0]     amo_data;
    logic [QUAD_BYTES-1:0]    amo_mask;
    logic [QUAD_BITS-1:0]     amo_cmp;
    logic                     error;
    logic                     replace;
    logic [PF_SRC_BITS-1:0]   pf_source;
    logic                     access;
    logic [REQ_ID_BITS-1:0]   id;
  } mainpipe_req_t;

  function automatic logic req_is_store(input mainpipe_req_t r);
    return r.source == SRC_STORE;
  endfunction
  function automatic logic req_is_amo(input mainpipe_req_t r);
    return r.source == SRC_AMO;
  endfunction
  // quad_word_idx = word_idx >> 1（AMOCAS.Q 选 128 位双字）。
  function automatic logic [BANK_BITS-2:0] quad_word_idx(input mainpipe_req_t r);
    return r.word_idx[BANK_BITS-1:1];
  endfunction

  // L1_HW_PREFETCH_NULL：miss_req.pf_source 恒发的常量（本流水不发预取 miss）。
  localparam logic [PF_SRC_BITS-1:0] L1_HW_PREFETCH_NULL = 3'd0;
  // isFromL1Prefetch：pf_source[2:1] 非 0 即来自 L1 预取（golden: |s[2:1]）。
  function automatic logic is_from_l1_prefetch(input logic [PF_SRC_BITS-1:0] s);
    return |s[2:1];
  endfunction

endpackage
