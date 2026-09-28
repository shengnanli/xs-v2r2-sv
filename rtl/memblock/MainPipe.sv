// =====================================================================
// MainPipe.sv —— DCache 主流水线（store / AMO / probe / refill 的读-改-写）
// ---------------------------------------------------------------------
// 位置：L1 DCache 内部。load 走自己的 LoadPipe；凡是要**改** cache 内容的请求都走
//   这条 4 级主流水：
//     probe  —— L2 发来的 Probe（降权/回收），ProbeQueue 送进来；
//     refill —— MissQueue 从 L2 取回整行后，在这里写 tag/meta/data（并完成 AMO miss）；
//     store  —— Sbuffer 攒满的整行写；
//     atomic —— AtomicsUnit 的 AMO / LR / SC / AMOCAS。
//   四个源经 Arbiter4_MainPipeReq 固定优先级仲裁（probe > refill > store > atomic）。
//
// 流水级（每级一节，节首讲这一级做什么）：
//   s0  仲裁 + 读 tag/meta（与 s1/s2/s3 做同 set 冲突检查，冲突就不让进）
//   s1  拿到 4 路 tag/meta：ECC 检查、命中判定、权限判定、选替换路；读 data SRAM
//   s2  命中的 store/AMO 往下走，miss 的发给 MissQueue；refill 等 L2 数据；合并 store 数据
//   s3  拿到 data：做 AMO/LR/SC/CAS，写 data/meta/tag/标志位，需要时写回（Release/ProbeAck）
//
// 本配置（KunminghuV2）下 golden 里被 firtool 常量折叠掉的东西（这里写成具名常量，见 §0）：
//   meta/data/tag 写口的 ready 恒 1、refill 的 miss_dirty 恒 0、StoreWaitThreshold 恒 0
//   （store 永远可接收）、仲裁器输出的 replace 恒 0（没有 replace 请求源）。
//
// 子模块（白盒例化本仓已签核重写件）：Arbiter4_MainPipeReq（s0 仲裁）、AMOALU（s3 运算）。
// 文件结构：mainpipe_pkg → xs_MainPipe_core（手写）→ golden 同名 wrapper MainPipe
//   （由 verif/ut/MainPipe/gen_mainpipe.py 从 G1 golden 端口表生成）。
// =====================================================================
// 本文件导航（共 2801 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L37    位置：L1 DCache 内部
//   L62    规模参数
//   L76    常量：请求来源、内存命令、一致性状态、TileLink 权限参数
//   L129   IO bundle 类型
//   L132   BEGIN GENERATED(io_types)
//   L351   流水线内部的请求
//   L353   s0/s1：仲裁器输出的 20 个字段 + replace
//   L470   命令分类
//   L496   ClientMetadata 的三张状态表
//   L498   growStarter：本地状态够不够做这个操作？够 -> {1, 新状态}；不够 -> {0, Acquire 参数}
//   L548   tag 的 SECDED 校验
//   L591   FillInterleaved(8, m)：字节掩码 -> 位掩码
//   L615   xs_MainPipe_core —— DCache 主流水可读核
//   L713   §0 本配置下恒定的握手信号
//   L715   meta 阵列由寄存器实现、data/tag 写口在 s3 独占 -> 写口 ready 恒 1；
//   L733   §1 s0：四路仲裁 + 读 tag/meta
//   L735   仲裁器选出本拍的请求 s0_req，同时向 tag/meta 阵列发读
//   L860   §2 s1：tag/meta 回来了 —— ECC、命中、权限、替换路；发 data 整行读
//   L862   tag/meta/extra_meta 的 SRAM 输出只在 s0_fire 之后的**那一拍**有效；s1 若被
//   L1045  §3 s2：分流 —— 命中的走 s3，store/AMO miss 走 MissQueue，refill 等数据
//   L1047  s2 出口有三条：
//   L1253  §4 s3：拿到数据 —— 合并、AMO/LR/SC/CAS、写 data/meta/tag/标志位、写回
//   L1255  s3 的 data = s2 预合并的 store 数据盖在 SRAM 读出数据上
//   L1649  §5 给 MissQueue / 预取器 / SMS 的旁路信息
//   L1692  §6 status_dup：24 份 s1/s2/s3 占用状态
//   L1694  每份自己打自己的 set / replace / way_en 拍
//   L1727  §7 性能事件
//   L1749  §8 仿真期检查用的寄存器
//   L1751  Chisel 的 assert(RegNext(...)) / XSError 计数器在 golden 里是真寄存器，只有
//   L1829  golden 同名 wrapper —— 由 verif/ut/MainPipe/gen_mainpipe.py 生成，改请改生
//   L1831  BEGIN GENERATED(wrapper)
//
package mainpipe_pkg;

  // ---------------------------------------------------------------------
  // 规模参数（KunminghuV2 DCache：64KB / 4 路 / 256 组 / 64B 行 / 8 个 64 位 bank）
  // ---------------------------------------------------------------------
  localparam int unsigned N_WAYS    = 4;
  localparam int unsigned N_BANKS   = 8;
  localparam int unsigned BANK_W    = 64;
  localparam int unsigned IDX_W     = 8;     // set 下标 = vaddr[13:6]
  localparam int unsigned TAG_W     = 36;    // tag = paddr[47:12]
  localparam int unsigned TAG_SEC_W = 42;    // tag + 6 位 Hamming 校验
  localparam int unsigned ENC_TAG_W = 43;    // 再加 1 位全字奇偶 = SECDED
  localparam int unsigned VADDR_W   = 50;
  localparam int unsigned PADDR_W   = 48;
  localparam int unsigned N_DUP     = 24;    // status_dup 份数

  // ---------------------------------------------------------------------
  // 常量：请求来源、内存命令、一致性状态、TileLink 权限参数
  // ---------------------------------------------------------------------
  localparam logic [3:0] STORE_SOURCE = 4'd1;
  localparam logic [3:0] AMO_SOURCE   = 4'd2;

  localparam logic [4:0] M_XWR      = 5'h01;
  localparam logic [4:0] M_PFW      = 5'h03;
  localparam logic [4:0] M_XA_SWAP  = 5'h04;
  localparam logic [4:0] M_XLR      = 5'h06;
  localparam logic [4:0] M_XSC      = 5'h07;
  localparam logic [4:0] M_XA_ADD   = 5'h08;
  localparam logic [4:0] M_XA_XOR   = 5'h09;
  localparam logic [4:0] M_XA_OR    = 5'h0A;
  localparam logic [4:0] M_XA_AND   = 5'h0B;
  localparam logic [4:0] M_XA_MIN   = 5'h0C;
  localparam logic [4:0] M_XA_MAX   = 5'h0D;
  localparam logic [4:0] M_XA_MINU  = 5'h0E;
  localparam logic [4:0] M_XA_MAXU  = 5'h0F;
  localparam logic [4:0] M_PWR      = 5'h11;
  localparam logic [4:0] M_XA_CASQ  = 5'h18;
  localparam logic [4:0] M_XA_CASW  = 5'h1A;
  localparam logic [4:0] M_XA_CASD  = 5'h1B;

  // ClientStates（本地一致性状态）
  localparam logic [1:0] ST_NOTHING = 2'd0;
  localparam logic [1:0] ST_BRANCH  = 2'd1;
  localparam logic [1:0] ST_TRUNK   = 2'd2;
  localparam logic [1:0] ST_DIRTY   = 2'd3;

  // TLPermissions：cap（probe/grant 的目标权限）
  localparam logic [1:0] CAP_TOT = 2'd0;
  localparam logic [1:0] CAP_TOB = 2'd1;
  localparam logic [1:0] CAP_TON = 2'd2;
  // grow（Acquire 参数）
  localparam logic [1:0] GROW_NTOB = 2'd0;
  localparam logic [1:0] GROW_NTOT = 2'd1;
  localparam logic [1:0] GROW_BTOT = 2'd2;
  // shrink / report（Release、ProbeAck 参数）
  localparam logic [2:0] SHRINK_TTOB = 3'd0;
  localparam logic [2:0] SHRINK_TTON = 3'd1;
  localparam logic [2:0] SHRINK_BTON = 3'd2;
  localparam logic [2:0] REPORT_TTOT = 3'd3;
  localparam logic [2:0] REPORT_BTOB = 3'd4;
  localparam logic [2:0] REPORT_NTON = 3'd5;

  // L1 预取来源：> CLEAR 的才算"由 L1 预取器带进来"
  localparam logic [2:0] L1_PF_CLEAR = 3'd1;

  // LR/SC 保留窗口（LRSCCycles=64，LRSCBackOff=8）
  localparam logic [5:0] LRSC_CYCLES_M1 = 6'd63;
  localparam logic [5:0] LRSC_BACKOFF   = 6'd8;

  // ---------------------------------------------------------------------
  // IO bundle 类型（由 gen_mainpipe.py 生成：字段结构照 Chisel 的 IO Bundle，
  // 只保留 golden 端口表里还在的字段）
  // ---------------------------------------------------------------------
  // BEGIN GENERATED(io_types)
  typedef struct packed {
    logic tl_denied;                              // L2 拒绝访问（denied）
    logic tl_corrupt;                             // 数据损坏（corrupt）
  } tl_error_t;

  typedef struct packed {
    logic [1:0]  probe_param;                     // TileLink probe 目标权限 toT/toB/toN
    logic        probe_need_data;                 // probe 要不要把数据带回去
    logic [49:0] vaddr;                           // 取 set 下标用
    logic [47:0] addr;                            // 被 probe 的块物理地址
    logic [5:0]  id;                              // 请求 id
  } probe_req_bits_t;

  typedef struct packed {
    logic [3:0]   miss_id;                        // MissQueue 表项号
    logic [3:0]   occupy_way;                     // BtoT 升权失败时强制占用的路
    logic         miss_fail_cause_evict_btot;     // 置 1：替换路用 occupy_way
    logic [3:0]   source;                         // 原请求来源（store/amo/load）
    logic [4:0]   cmd;                            // 原请求命令
    logic [49:0]  vaddr;
    logic [47:0]  addr;
    logic [2:0]   word_idx;                       // AMO miss 回填时作用的字
    logic [127:0] amo_data;
    logic [15:0]  amo_mask;
    logic [127:0] amo_cmp;
    logic [2:0]   pf_source;                      // 预取来源（写进 prefetch 标志阵列）
    logic         access;                         // 是否被访问过（写进 access 标志阵列）
    logic [5:0]   id;
  } refill_req_bits_t;

  typedef struct packed {
    logic [49:0]  vaddr;
    logic [47:0]  addr;
    logic [511:0] data;                           // 整行 store 数据
    logic [63:0]  mask;                           // 字节掩码
    logic [5:0]   id;                             // Sbuffer 表项号
  } store_req_bits_t;

  typedef struct packed {
    logic [4:0]   cmd;                            // M_XLR/M_XSC/M_XA_*
    logic [49:0]  vaddr;
    logic [47:0]  addr;
    logic [2:0]   word_idx;                       // 作用的 64 位字
    logic [127:0] amo_data;
    logic [15:0]  amo_mask;
    logic [127:0] amo_cmp;                        // AMOCAS 比较值
  } atomic_req_bits_t;

  typedef struct packed {
    logic [3:0]   source;
    logic [4:0]   cmd;
    logic [47:0]  addr;
    logic [49:0]  vaddr;
    logic         full_overwrite;                 // store 整行覆盖（可免读 L2 数据）
    logic [2:0]   word_idx;
    logic [127:0] amo_data;
    logic [15:0]  amo_mask;
    logic [127:0] amo_cmp;
    logic [1:0]   req_coh_state;                  // 请求时本地的 coh 状态
    logic [5:0]   id;
    logic         isBtoT;                         // Branch->Trunk 升权请求
    logic [3:0]   occupy_way;                     // 升权时占用的那一路
    logic         cancel;                         // 升权失败（BtoT 路太多），MissQueue 丢弃
    logic [511:0] store_data;
    logic [63:0]  store_mask;
  } miss_req_bits_t;

  typedef struct packed {
    logic [3:0]   source;
    logic [127:0] data;                           // AMO 旧值 / SC 结果
    logic         miss;
    logic [3:0]   miss_id;
    logic         replay;                         // 要求 AtomicsUnit 重发
    tl_error_t    tl_error;
    logic         ack_miss_queue;                 // AMO miss 在主流水完成，通知 MissQueue
    logic [5:0]   id;                             // 借用：LR/SC 保留集是否还有效
  } atomic_resp_bits_t;

  typedef struct packed {
    logic       s2_valid;                         // s2 是 refill 请求
    logic [3:0] s2_miss_id;
    logic       s2_replay_to_mq;                  // s2 refill 没等到数据，回 MissQueue 重来
    logic       s2_evict_BtoT_way;                // s2 替换被 MissQueue 阻塞
    logic [3:0] s2_next_evict_way;                // 第一个非 BtoT 的路（独热）
    logic       s3_valid;
    logic [3:0] s3_miss_id;
    logic       s3_refill_resp;                   // 上一拍 refill 进了 s3
  } mainpipe_info_t;

  typedef struct packed {
    logic [511:0] store_data;
    logic [63:0]  store_mask;
    logic [1:0]   miss_param;                     // Grant 的权限 toT/toB
    tl_error_t    error;
  } refill_info_bits_t;

  typedef struct packed {
    logic [2:0]   param;                          // Release/ProbeAck 的 shrink 参数
    logic         voluntary;                      // 主动 Release（替换）而非 ProbeAck
    logic         hasData;
    logic         corrupt;
    logic         dirty;
    logic [47:0]  addr;
    logic [511:0] data;
  } wb_bits_t;

  typedef struct packed {
    logic [3:0]  way_en;
    logic [47:0] addr;
    logic [7:0]  rmask;                           // 要读的 bank
  } readline_bits_t;

  typedef struct packed {
    logic [63:0] raw_data;                        // 一个 bank 的 64 位数据
  } data_resp_t;

  typedef struct packed {
    logic [7:0]       wmask;                      // 要写的 bank
    logic [7:0][63:0] data;                       // 8 个 bank 的写数据
  } data_write_bits_t;

  typedef struct packed {
    logic [3:0]  way_en;
    logic [47:0] addr;
  } data_write_ctrl_t;

  typedef struct packed {
    logic             valid;
    data_write_ctrl_t bits;
  } data_write_dup_t;

  typedef struct packed {
    logic [1:0] coh_state;                        // Nothing/Branch/Trunk/Dirty
  } meta_t;

  typedef struct packed {
    logic [7:0] idx;
    logic [3:0] way_en;
    logic [1:0] meta_coh_state;
  } meta_write_bits_t;

  typedef struct packed {
    tl_error_t  error;
    logic [2:0] prefetch;                         // 该行由哪个预取器带进来
    logic       access;                           // 该行被 demand 访问过
  } extra_meta_t;

  typedef struct packed {
    logic [7:0] idx;
    logic [3:0] way_en;
    tl_error_t  error;
  } error_flag_write_bits_t;

  typedef struct packed {
    logic [7:0] idx;
    logic [3:0] way_en;
    logic [2:0] source;
  } prefetch_flag_write_bits_t;

  typedef struct packed {
    logic [7:0] idx;
    logic [3:0] way_en;
    logic       flag;
  } access_flag_write_bits_t;

  typedef struct packed {
    logic [7:0]  idx;
    logic [3:0]  way_en;
    logic [35:0] tag;
  } tag_write_bits_t;

  typedef struct packed {
    logic [7:0] set;
    logic [1:0] way;
  } replace_access_bits_t;

  typedef struct packed {
    logic [47:0] addr;
    logic [49:0] vaddr;
  } replace_req_bits_t;

  typedef struct packed {
    logic [7:0] set;
    logic [3:0] way_en;
  } status_bits_t;

  typedef struct packed {
    logic         valid;
    status_bits_t bits;
  } stage_status_t;

  typedef struct packed {
    stage_status_t s1;
    stage_status_t s2;
    stage_status_t s3;
  } status_dup_t;

  typedef struct packed {
    logic [47:0] paddr;
    logic        report_to_beu;                   // 报给总线错误单元（tag/data ECC 错）
  } error_bits_t;

  typedef struct packed {
    logic        valid;
    logic [11:0] bits_addr;                       // 块地址哈希
  } bloom_query_t;

  typedef struct packed {
    bloom_query_t set;                            // 被替换出去的预取行 -> 置位
    bloom_query_t clr;                            // 预取行被 demand 用到 -> 清除
  } bloom_filter_query_t;

  typedef struct packed {
    logic [5:0] value;
  } perf_event_t;
  // END GENERATED

  // ---------------------------------------------------------------------
  // 流水线内部的请求（MainPipeReq）—— 各级只留 golden 里真还在的字段
  // ---------------------------------------------------------------------
  // s0/s1：仲裁器输出的 20 个字段 + replace（恒 0，没有 replace 源，但 s1 照样有这个寄存器）
  typedef struct packed {
    logic         miss;                        // refill 请求
    logic [3:0]   miss_id;
    logic [3:0]   occupy_way;
    logic         miss_fail_cause_evict_btot;
    logic         probe;                       // probe 请求
    logic [1:0]   probe_param;
    logic         probe_need_data;
    logic [3:0]   source;                      // 1=store 2=amo（refill 带原请求的来源）
    logic [4:0]   cmd;
    logic [49:0]  vaddr;
    logic [47:0]  addr;
    logic [511:0] store_data;
    logic [63:0]  store_mask;
    logic [2:0]   word_idx;
    logic [127:0] amo_data;
    logic [15:0]  amo_mask;
    logic [127:0] amo_cmp;
    logic         replace;
    logic [2:0]   pf_source;
    logic         access;
    logic [5:0]   id;
  } s1_req_t;

  // s2：occupy_way / miss_fail_cause_evict_btot 过了 s1 就没人读了（替换路已在 s1 选定）
  typedef struct packed {
    logic         miss;
    logic [3:0]   miss_id;
    logic         probe;
    logic [1:0]   probe_param;
    logic         probe_need_data;
    logic [3:0]   source;
    logic [4:0]   cmd;
    logic [49:0]  vaddr;
    logic [47:0]  addr;
    logic [511:0] store_data;
    logic [63:0]  store_mask;
    logic [2:0]   word_idx;
    logic [127:0] amo_data;
    logic [15:0]  amo_mask;
    logic [127:0] amo_cmp;
    logic         replace;
    logic [2:0]   pf_source;
    logic         access;
    logic [5:0]   id;
  } s2_req_t;

  // s3：store_data/store_mask 已在 s2 合并进 s3_store_data_merged_without_cache，不再逐级传
  typedef struct packed {
    logic         miss;
    logic [3:0]   miss_id;
    logic         probe;
    logic [1:0]   probe_param;
    logic         probe_need_data;
    logic [3:0]   source;
    logic [4:0]   cmd;
    logic [49:0]  vaddr;
    logic [47:0]  addr;
    logic [2:0]   word_idx;
    logic [127:0] amo_data;
    logic [15:0]  amo_mask;
    logic [127:0] amo_cmp;
    logic         replace;
    logic [2:0]   pf_source;
    logic         access;
    logic [5:0]   id;
  } s3_req_t;

  // 级间传递：只拷下一级还在的字段
  function automatic s2_req_t to_s2_req(input s1_req_t r);
    s2_req_t o;
    o.miss            = r.miss;
    o.miss_id         = r.miss_id;
    o.probe           = r.probe;
    o.probe_param     = r.probe_param;
    o.probe_need_data = r.probe_need_data;
    o.source          = r.source;
    o.cmd             = r.cmd;
    o.vaddr           = r.vaddr;
    o.addr            = r.addr;
    o.store_data      = r.store_data;
    o.store_mask      = r.store_mask;
    o.word_idx        = r.word_idx;
    o.amo_data        = r.amo_data;
    o.amo_mask        = r.amo_mask;
    o.amo_cmp         = r.amo_cmp;
    o.replace         = r.replace;
    o.pf_source       = r.pf_source;
    o.access          = r.access;
    o.id              = r.id;
    return o;
  endfunction

  function automatic s3_req_t to_s3_req(input s2_req_t r);
    s3_req_t o;
    o.miss            = r.miss;
    o.miss_id         = r.miss_id;
    o.probe           = r.probe;
    o.probe_param     = r.probe_param;
    o.probe_need_data = r.probe_need_data;
    o.source          = r.source;
    o.cmd             = r.cmd;
    o.vaddr           = r.vaddr;
    o.addr            = r.addr;
    o.word_idx        = r.word_idx;
    o.amo_data        = r.amo_data;
    o.amo_mask        = r.amo_mask;
    o.amo_cmp         = r.amo_cmp;
    o.replace         = r.replace;
    o.pf_source       = r.pf_source;
    o.access          = r.access;
    o.id              = r.id;
    return o;
  endfunction

  // ---------------------------------------------------------------------
  // 命令分类（rocket-chip MemoryOpConstants / MemoryOpCategories）
  // ---------------------------------------------------------------------
  function automatic logic is_amocas(input logic [4:0] cmd);
    return cmd == M_XA_CASW || cmd == M_XA_CASD || cmd == M_XA_CASQ;
  endfunction

  function automatic logic is_amo(input logic [4:0] cmd);
    return cmd == M_XA_SWAP || cmd == M_XA_XOR || cmd == M_XA_OR || cmd == M_XA_AND ||
           cmd == M_XA_ADD || cmd == M_XA_MIN || cmd == M_XA_MAX || cmd == M_XA_MINU ||
           cmd == M_XA_MAXU || is_amocas(cmd);
  endfunction

  function automatic logic is_write(input logic [4:0] cmd);
    return cmd == M_XWR || cmd == M_PWR || cmd == M_XSC || is_amo(cmd);
  endfunction

  function automatic logic is_write_intent(input logic [4:0] cmd);
    return is_write(cmd) || cmd == M_PFW || cmd == M_XLR;
  endfunction

  // categorize：{真写, 有写意图}。rd=00 / wi=01 / wr=11（10 不会出现，但表里照样要有 default）
  function automatic logic [1:0] categorize(input logic [4:0] cmd);
    return {is_write(cmd), is_write_intent(cmd)};
  endfunction

  // ---------------------------------------------------------------------
  // ClientMetadata 的三张状态表（rocket-chip tilelink/Metadata.scala）
  // ---------------------------------------------------------------------
  // growStarter：本地状态够不够做这个操作？够 -> {1, 新状态}；不够 -> {0, Acquire 参数}
  function automatic logic [2:0] grow_starter(input logic [1:0] cat, input logic [1:0] state);
    case ({cat, state})
      {2'b00, ST_DIRTY}:   return {1'b1, ST_DIRTY};
      {2'b00, ST_TRUNK}:   return {1'b1, ST_TRUNK};
      {2'b00, ST_BRANCH}:  return {1'b1, ST_BRANCH};
      {2'b01, ST_DIRTY}:   return {1'b1, ST_DIRTY};
      {2'b01, ST_TRUNK}:   return {1'b1, ST_TRUNK};
      {2'b11, ST_DIRTY}:   return {1'b1, ST_DIRTY};
      {2'b11, ST_TRUNK}:   return {1'b1, ST_DIRTY};     // 写 Trunk 块 -> 变脏
      {2'b00, ST_NOTHING}: return {1'b0, GROW_NTOB};
      {2'b01, ST_BRANCH}:  return {1'b0, GROW_BTOT};
      {2'b01, ST_NOTHING}: return {1'b0, GROW_NTOT};
      {2'b11, ST_BRANCH}:  return {1'b0, GROW_BTOT};
      {2'b11, ST_NOTHING}: return {1'b0, GROW_NTOT};
      default:             return 3'b000;
    endcase
  endfunction

  // shrinkHelper：按目标权限 cap 降权 -> {回报参数 report/shrink, 新状态}
  function automatic logic [4:0] shrink_helper(input logic [1:0] cap, input logic [1:0] state);
    case ({cap, state})
      {CAP_TOT, ST_DIRTY}:   return {REPORT_TTOT, ST_TRUNK};
      {CAP_TOT, ST_TRUNK}:   return {REPORT_TTOT, ST_TRUNK};
      {CAP_TOT, ST_BRANCH}:  return {REPORT_BTOB, ST_BRANCH};
      {CAP_TOT, ST_NOTHING}: return {REPORT_NTON, ST_NOTHING};
      {CAP_TOB, ST_DIRTY}:   return {SHRINK_TTOB, ST_BRANCH};
      {CAP_TOB, ST_TRUNK}:   return {SHRINK_TTOB, ST_BRANCH};
      {CAP_TOB, ST_BRANCH}:  return {REPORT_BTOB, ST_BRANCH};
      {CAP_TOB, ST_NOTHING}: return {REPORT_NTON, ST_NOTHING};
      {CAP_TON, ST_DIRTY}:   return {SHRINK_TTON, ST_NOTHING};
      {CAP_TON, ST_TRUNK}:   return {SHRINK_TTON, ST_NOTHING};
      {CAP_TON, ST_BRANCH}:  return {SHRINK_BTON, ST_NOTHING};
      {CAP_TON, ST_NOTHING}: return {REPORT_NTON, ST_NOTHING};
      default:                return 5'b000_00;
    endcase
  endfunction

  // missCohGen：refill 完成后的新状态（由原请求类别 + Grant 权限决定；本配置 dirty 恒 0）
  function automatic logic [1:0] miss_coh_gen(input logic [1:0] cat, input logic [1:0] grant_cap);
    case ({cat, grant_cap})
      {2'b00, CAP_TOB}: return ST_BRANCH;
      {2'b00, CAP_TOT}: return ST_TRUNK;
      {2'b01, CAP_TOT}: return ST_TRUNK;
      {2'b11, CAP_TOT}: return ST_DIRTY;
      default:           return ST_NOTHING;
    endcase
  endfunction

  // ---------------------------------------------------------------------
  // tag 的 SECDED 校验（utility/ECC.scala 的 SECDEDCode，36 位数据）
  //   编码 = {全字奇偶 1 位, Hamming 校验 6 位, tag 36 位}（系统码：数据在低位）。
  //   Hamming 码天然按"位置号"排：位置 1,2,4,8,16,32 是校验位，其余依次放数据位；
  //   第 j 位校验子 = 所有"位置号第 j 位为 1"的码元异或。下面的函数把位置号换算回
  //   系统码下标，算出每一位校验子要覆盖哪些码元（elaborate 期常量）。
  //   译码判错（error = 可纠 | 不可纠）：全字奇偶为 1（单错），或奇偶为 0 但校验子非 0（双错）。
  // ---------------------------------------------------------------------
  function automatic logic [TAG_SEC_W-1:0] hamming_syndrome_mask(input int unsigned j);
    logic [TAG_SEC_W-1:0] mask;
    int unsigned          data_idx;
    int unsigned          sys_idx;
    mask     = '0;
    data_idx = 0;
    for (int unsigned pos = 1; pos <= TAG_SEC_W; pos++) begin
      if ((pos & (pos - 1)) == 0) begin
        sys_idx = TAG_W + $clog2(pos);   // 位置 2^m 上是第 m 个校验位
      end else begin
        sys_idx  = data_idx;             // 其余位置依次是数据位
        data_idx = data_idx + 1;
      end
      if (((pos >> j) & 1) != 0)
        mask[sys_idx] = 1'b1;
    end
    return mask;
  endfunction

  localparam logic [5:0][TAG_SEC_W-1:0] TAG_SYNDROME_MASK = {
    hamming_syndrome_mask(5), hamming_syndrome_mask(4), hamming_syndrome_mask(3),
    hamming_syndrome_mask(2), hamming_syndrome_mask(1), hamming_syndrome_mask(0)
  };

  function automatic logic tag_ecc_error(input logic [ENC_TAG_W-1:0] enc);
    logic [5:0] syndrome;
    logic       parity_odd;
    for (int j = 0; j < 6; j++)
      syndrome[j] = ^(enc[TAG_SEC_W-1:0] & TAG_SYNDROME_MASK[j]);
    parity_odd = ^enc;
    return parity_odd | (~parity_odd & (|syndrome));
  endfunction

  // ---------------------------------------------------------------------
  // 小工具
  // ---------------------------------------------------------------------
  // FillInterleaved(8, m)：字节掩码 -> 位掩码
  function automatic logic [63:0] byte_mask_to_bits(input logic [7:0] m);
    logic [63:0] bits;
    for (int b = 0; b < 8; b++)
      bits[b*8 +: 8] = {8{m[b]}};
    return bits;
  endfunction

  // mergePutData：按字节掩码把 new_data 盖到 old_data 上
  function automatic logic [63:0] merge_put_data(input logic [63:0] old_data,
                                                 input logic [63:0] new_data,
                                                 input logic [7:0]  wmask);
    logic [63:0] full;
    full = byte_mask_to_bits(wmask);
    return (~full & old_data) | (full & new_data);
  endfunction

  function automatic logic [2:0] popcount4(input logic [3:0] v);
    return 3'(v[0]) + 3'(v[1]) + 3'(v[2]) + 3'(v[3]);
  endfunction

endpackage

// =====================================================================
// xs_MainPipe_core —— DCache 主流水可读核
// =====================================================================
module xs_MainPipe_core
  import mainpipe_pkg::*;
(
  // BEGIN GENERATED(core_ports)
  input  logic clock,
  input  logic reset,
  input  logic probe_req_valid,                           // ProbeQueue 的 probe 请求
  output logic probe_req_ready,
  input  probe_req_bits_t probe_req_bits,
  input  logic refill_req_valid,                          // MissQueue 的回填请求
  output logic refill_req_ready,
  input  refill_req_bits_t refill_req_bits,
  input  logic store_req_valid,                           // Sbuffer 的整行写
  output logic store_req_ready,
  input  store_req_bits_t store_req_bits,
  input  logic atomic_req_valid,                          // AtomicsUnit 的 AMO/LR/SC
  output logic atomic_req_ready,
  input  atomic_req_bits_t atomic_req_bits,
  input  logic miss_req_ready,                            // -> MissQueue：store/AMO miss
  output logic miss_req_valid,
  output miss_req_bits_t miss_req_bits,
  output logic wbq_conflict_check_valid,                  // -> WritebackQueue 冲突检查
  output logic [47:0] wbq_conflict_check_bits,
  input  logic wbq_block_miss_req,
  output logic store_replay_resp_valid,                   // -> Sbuffer：store miss/升权失败，要重发
  output logic [5:0] store_replay_resp_bits_id,
  output logic store_hit_resp_valid,                      // -> Sbuffer：store 已写入
  output logic [5:0] store_hit_resp_bits_id,
  output logic atomic_resp_valid,                         // -> AtomicsUnit
  output atomic_resp_bits_t atomic_resp_bits,
  output mainpipe_info_t mainpipe_info,                   // -> MissQueue
  input  logic refill_info_valid,                         // MissQueue 回填数据
  input  refill_info_bits_t refill_info_bits,
  input  logic wb_ready,                                  // -> WritebackQueue：Release/ProbeAck
  output logic wb_valid,
  output wb_bits_t wb_bits,
  output logic data_read_intend,                          // data SRAM 读口：s1 读整行
  input  logic data_readline_ready,
  output logic data_readline_valid,
  output readline_bits_t data_readline_bits,
  output logic data_readline_can_go,
  output logic data_readline_stall,
  output logic data_readline_can_resp,
  input  data_resp_t [7:0] data_resp,                     // s3 拿到的读出数据（8 bank）
  input  logic readline_error_delayed,                    // data ECC 错（晚一拍报）
  output logic data_write_valid,                          // data SRAM 写口：s3 写回
  output data_write_bits_t data_write_bits,
  output data_write_dup_t [7:0] data_write_dup,
  output logic meta_read_valid,                           // coh meta 读口：s0
  output logic [7:0] meta_read_bits_idx,
  input  meta_t [3:0] meta_resp,                          // s1 拿到的 4 路 coh 状态
  output logic meta_write_valid,                          // coh meta 写口：s3
  output meta_write_bits_t meta_write_bits,
  input  extra_meta_t [3:0] extra_meta_resp,              // s1 拿到的 4 路标志位
  output logic error_flag_write_valid,
  output error_flag_write_bits_t error_flag_write_bits,
  output logic prefetch_flag_write_valid,
  output prefetch_flag_write_bits_t prefetch_flag_write_bits,
  output logic access_flag_write_valid,
  output access_flag_write_bits_t access_flag_write_bits,
  input  logic tag_read_ready,                            // tag SRAM 读口：s0
  output logic tag_read_valid,
  output logic [7:0] tag_read_bits_idx,
  input  logic [3:0][42:0] tag_resp,                      // s1 拿到的 4 路 tag（带 7 位 SECDED 校验）
  output logic tag_write_valid,                           // tag SRAM 写口：s3（只有 refill 写 tag）
  output tag_write_bits_t tag_write_bits,
  output logic tag_write_intend,
  output logic replace_access_valid,                      // 替换算法状态更新
  output replace_access_bits_t replace_access_bits,
  output logic [7:0] replace_way_set_bits,                // 替换算法查询：s1 的 set
  input  logic [1:0] replace_way_way,                     // 替换算法给出的受害路
  output logic [7:0] evict_set,                           // -> MissQueue：s2 的 set（查该 set 的 BtoT 路）
  input  logic [3:0] btot_ways_for_set,                   // 该 set 里哪些路正在 BtoT 升权
  output replace_req_bits_t replace_req_bits,             // -> MissQueue：要替换的块
  input  logic replace_block,                             // MissQueue 说这个替换要等
  output logic sms_agt_evict_req_valid,                   // -> SMS 预取器：有行被替换
  output logic [49:0] sms_agt_evict_req_bits_vaddr,
  output status_dup_t [23:0] status_dup,                  // 24 份 s1/s2/s3 状态（扇出复制）
  output logic lrsc_locked_block_valid,                   // LR 保留集（挡住 probe）
  output logic [47:0] lrsc_locked_block_bits,
  input  logic invalid_resv_set,                          // 该块被 release，保留集失效
  output logic update_resv_set,
  output logic block_lr,
  output logic error_valid,                               // ECC 错误上报
  output error_bits_t error_bits,
  input  logic pseudo_error_valid,                        // 错误注入（CtrlUnit）
  input  logic pseudo_error_bits_0_valid,
  input  logic [63:0] pseudo_error_bits_0_mask,
  output logic pseudo_tag_error_inj_done,
  output logic pseudo_data_error_inj_done,
  output bloom_filter_query_t bloom_filter_query,         // -> 预取布隆过滤器
  output perf_event_t [3:0] perf                          // 性能事件
  // END GENERATED
);

  // =====================================================================
  // §0 本配置下恒定的握手信号（golden 里已被 firtool 常量折叠，没有对应端口）
  // =====================================================================
  //   meta 阵列由寄存器实现、data/tag 写口在 s3 独占 -> 写口 ready 恒 1；
  //   MissQueue 回填时 miss_dirty 恒 0；StoreWaitThreshold（Constantin 初值 0）使
  //   "store 等太久"恒成立 -> store 永远可接收（storeWaitCycles 计数器因此整个被删）；
  //   仲裁器输出不含 replace（没有 replace 请求源）-> s0 的 replace 恒 0。
  localparam logic META_WRITE_READY = 1'b1;
  localparam logic DATA_WRITE_READY = 1'b1;
  localparam logic TAG_WRITE_READY  = 1'b1;
  localparam logic META_READ_READY  = 1'b1;
  localparam logic REFILL_MISS_DIRTY = 1'b0;

  // 跨级的前向声明
  logic s1_ready, s2_ready, s3_ready;
  logic s1_valid, s2_valid, s3_valid;
  logic s0_fire, s1_fire, s2_fire, s2_fire_to_s3, s3_fire;
  logic [IDX_W-1:0] s1_idx, s2_idx, s3_idx;
  logic s3_sc_fail;

  // =====================================================================
  // §1 s0：四路仲裁 + 读 tag/meta
  // ---------------------------------------------------------------------
  //   仲裁器选出本拍的请求 s0_req，同时向 tag/meta 阵列发读（index = vaddr[13:6]）。
  //   能进 s1 的条件：tag 读口 ready、s1 能腾出来、且与 s1/s2/s3 里的请求**不在同一个
  //   set**（同 set 的读-改-写必须串行，否则后一个会读到旧 meta/data）。
  //   store 的 ready 为时序单独算：与仲裁并行，用 store 自己的 set 去比冲突，并要求
  //   另外三个更高优先级的源本拍都没请求。
  // =====================================================================
  logic    arb_out_valid;
  s1_req_t s0_req;
  logic [IDX_W-1:0] s0_idx, store_idx;
  logic s0_set_conflict, store_set_conflict;
  logic s0_can_go;

  Arbiter4_MainPipeReq main_pipe_req_arb (
    .io_in_0_ready                          (probe_req_ready),
    .io_in_0_valid                          (probe_req_valid),
    .io_in_0_bits_probe_param               (probe_req_bits.probe_param),
    .io_in_0_bits_probe_need_data           (probe_req_bits.probe_need_data),
    .io_in_0_bits_vaddr                     (probe_req_bits.vaddr),
    .io_in_0_bits_addr                      (probe_req_bits.addr),
    .io_in_0_bits_id                        (probe_req_bits.id),
    .io_in_1_ready                          (refill_req_ready),
    .io_in_1_valid                          (refill_req_valid),
    .io_in_1_bits_miss_id                   (refill_req_bits.miss_id),
    .io_in_1_bits_occupy_way                (refill_req_bits.occupy_way),
    .io_in_1_bits_miss_fail_cause_evict_btot(refill_req_bits.miss_fail_cause_evict_btot),
    .io_in_1_bits_source                    (refill_req_bits.source),
    .io_in_1_bits_cmd                       (refill_req_bits.cmd),
    .io_in_1_bits_vaddr                     (refill_req_bits.vaddr),
    .io_in_1_bits_addr                      (refill_req_bits.addr),
    .io_in_1_bits_word_idx                  (refill_req_bits.word_idx),
    .io_in_1_bits_amo_data                  (refill_req_bits.amo_data),
    .io_in_1_bits_amo_mask                  (refill_req_bits.amo_mask),
    .io_in_1_bits_amo_cmp                   (refill_req_bits.amo_cmp),
    .io_in_1_bits_pf_source                 (refill_req_bits.pf_source),
    .io_in_1_bits_access                    (refill_req_bits.access),
    .io_in_1_bits_id                        (refill_req_bits.id),
    .io_in_2_valid                          (store_req_valid),     // storeCanAccept 恒 1
    .io_in_2_bits_vaddr                     (store_req_bits.vaddr),
    .io_in_2_bits_addr                      (store_req_bits.addr),
    .io_in_2_bits_store_data                (store_req_bits.data),
    .io_in_2_bits_store_mask                (store_req_bits.mask),
    .io_in_2_bits_id                        (store_req_bits.id),
    .io_in_3_ready                          (atomic_req_ready),
    .io_in_3_valid                          (atomic_req_valid),
    .io_in_3_bits_cmd                       (atomic_req_bits.cmd),
    .io_in_3_bits_vaddr                     (atomic_req_bits.vaddr),
    .io_in_3_bits_addr                      (atomic_req_bits.addr),
    .io_in_3_bits_word_idx                  (atomic_req_bits.word_idx),
    .io_in_3_bits_amo_data                  (atomic_req_bits.amo_data),
    .io_in_3_bits_amo_mask                  (atomic_req_bits.amo_mask),
    .io_in_3_bits_amo_cmp                   (atomic_req_bits.amo_cmp),
    .io_out_ready                           (s0_can_go),
    .io_out_valid                           (arb_out_valid),
    .io_out_bits_miss                       (s0_req.miss),
    .io_out_bits_miss_id                    (s0_req.miss_id),
    .io_out_bits_occupy_way                 (s0_req.occupy_way),
    .io_out_bits_miss_fail_cause_evict_btot (s0_req.miss_fail_cause_evict_btot),
    .io_out_bits_probe                      (s0_req.probe),
    .io_out_bits_probe_param                (s0_req.probe_param),
    .io_out_bits_probe_need_data            (s0_req.probe_need_data),
    .io_out_bits_source                     (s0_req.source),
    .io_out_bits_cmd                        (s0_req.cmd),
    .io_out_bits_vaddr                      (s0_req.vaddr),
    .io_out_bits_addr                       (s0_req.addr),
    .io_out_bits_store_data                 (s0_req.store_data),
    .io_out_bits_store_mask                 (s0_req.store_mask),
    .io_out_bits_word_idx                   (s0_req.word_idx),
    .io_out_bits_amo_data                   (s0_req.amo_data),
    .io_out_bits_amo_mask                   (s0_req.amo_mask),
    .io_out_bits_amo_cmp                    (s0_req.amo_cmp),
    .io_out_bits_pf_source                  (s0_req.pf_source),
    .io_out_bits_access                     (s0_req.access),
    .io_out_bits_id                         (s0_req.id)
  );
  assign s0_req.replace = 1'b0;

  assign s0_idx    = s0_req.vaddr[13:6];
  assign store_idx = store_req_bits.vaddr[13:6];

  // 同 set 冲突：s0 的请求与已在流水里的 s1/s2/s3 撞 set
  assign s0_set_conflict    = (s1_valid && s0_idx == s1_idx) || (s2_valid && s0_idx == s2_idx) ||
                              (s3_valid && s3_idx == s0_idx);
  assign store_set_conflict = (s1_valid && store_idx == s1_idx) || (s2_valid && store_idx == s2_idx) ||
                              (s3_valid && s3_idx == store_idx);

  assign s0_can_go = META_READ_READY && tag_read_ready && s1_ready && !s0_set_conflict;
  assign s0_fire   = arb_out_valid && s0_can_go;

  assign store_req_ready = META_READ_READY && tag_read_ready && s1_ready && !store_set_conflict &&
                           !probe_req_valid && !refill_req_valid && !atomic_req_valid;

  // 读 tag/meta
  assign meta_read_valid    = arb_out_valid;
  assign meta_read_bits_idx = s0_idx;
  assign tag_read_valid     = arb_out_valid && !s0_req.replace;
  assign tag_read_bits_idx  = s0_idx;

  // s0 预先算好 s1 要读哪些 data bank、s2 要写哪些 bank
  //   store：只读"部分写"的 bank（整 bank 覆盖的不用读）；probe/amo/refill 读整行。
  logic [N_BANKS-1:0] bank_write, bank_full_write, banked_store_rmask;
  logic store_need_data, probe_need_data, amo_need_data, miss_need_data, replace_need_data;
  logic banked_need_data;
  logic [N_BANKS-1:0] s0_banked_rmask;

  always_comb begin
    for (int b = 0; b < N_BANKS; b++) begin
      bank_write[b]      = |s0_req.store_mask[b*8 +: 8];
      bank_full_write[b] = &s0_req.store_mask[b*8 +: 8];
    end
  end
  assign banked_store_rmask = bank_write & ~bank_full_write;

  assign store_need_data   = !s0_req.probe && s0_req.source == STORE_SOURCE && |banked_store_rmask;
  assign probe_need_data   = s0_req.probe;
  assign amo_need_data     = !s0_req.probe && s0_req.source == AMO_SOURCE;
  assign miss_need_data    = s0_req.miss;
  assign replace_need_data = s0_req.replace;
  assign banked_need_data  = store_need_data || probe_need_data || amo_need_data ||
                             miss_need_data || replace_need_data;

  assign s0_banked_rmask = store_need_data ? banked_store_rmask :
                           (probe_need_data || amo_need_data || miss_need_data || replace_need_data) ?
                             {N_BANKS{1'b1}} : {N_BANKS{1'b0}};

  // =====================================================================
  // §2 s1：tag/meta 回来了 —— ECC、命中、权限、替换路；发 data 整行读
  // ---------------------------------------------------------------------
  //   tag/meta/extra_meta 的 SRAM 输出只在 s0_fire 之后的**那一拍**有效；s1 若被
  //   下游卡住，要用寄存器把它们保持住（DataHoldBypass：刚回来那拍用线上值，
  //   之后用副本）。四份保持各自配一个"上拍 s0_fire"寄存器（golden 就是四份）。
  //   命中 = tag 相等 且 该路 tag ECC 没错 且 该路 meta 有效；
  //   权限（growStarter）决定命中后能不能直接做、以及要不要升权；
  //   替换路：错误注入时优先选"真 tag 相等"的路，否则 BtoT 失败指定路，否则替换算法给的路。
  // =====================================================================
  s1_req_t            s1_req;
  logic               s1_need_data;
  logic [N_BANKS-1:0] s1_banked_rmask;
  logic [N_BANKS-1:0] s1_banked_store_wmask;
  logic               s1_need_tag;
  logic               s1_can_go;

  always_ff @(posedge clock) begin
    if (s0_fire) begin
      s1_req                <= s0_req;
      s1_need_data          <= banked_need_data;
      s1_banked_rmask       <= s0_banked_rmask;
      s1_banked_store_wmask <= bank_write;
      s1_need_tag           <= tag_read_valid;
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      s1_valid <= 1'b0;
    else if (s0_fire)
      s1_valid <= 1'b1;
    else if (s1_fire)
      s1_valid <= 1'b0;
  end

  assign s1_can_go = s2_ready && (data_readline_ready || !s1_need_data);
  assign s1_fire   = s1_valid && s1_can_go;
  assign s1_ready  = !s1_valid || s1_can_go;
  assign s1_idx    = s1_req.vaddr[13:6];

  // ---- SRAM 输出保持（四份"上拍 s0_fire"，golden 各自一个寄存器）----
  logic s0_fire_q_meta, s0_fire_q_tag, s0_fire_q_extra, s0_fire_q_repl;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s0_fire_q_meta  <= 1'b0;
      s0_fire_q_tag   <= 1'b0;
      s0_fire_q_extra <= 1'b0;
      s0_fire_q_repl  <= 1'b0;
    end else begin
      s0_fire_q_meta  <= s0_fire;
      s0_fire_q_tag   <= s0_fire;
      s0_fire_q_extra <= s0_fire;
      s0_fire_q_repl  <= s0_fire;
    end
  end

  // meta（4 路 coh 状态）
  logic [N_WAYS-1:0][1:0] s1_meta, s1_meta_hold;
  always_comb
    for (int w = 0; w < N_WAYS; w++)
      s1_meta[w] = s0_fire_q_meta ? meta_resp[w].coh_state : s1_meta_hold[w];
  always_ff @(posedge clock)
    if (s1_valid) s1_meta_hold <= s1_meta;

  // tag（带 SECDED 编码；错误注入时按掩码翻转 tag 部分，校验位不动）
  logic [TAG_W-1:0]                   pseudo_tag_toggle_mask;
  logic [N_WAYS-1:0][ENC_TAG_W-1:0]   pseudo_enc_tag_resp, enc_tag_resp, enc_tag_hold;
  assign pseudo_tag_toggle_mask = (pseudo_error_valid && pseudo_error_bits_0_valid) ?
                                  pseudo_error_bits_0_mask[TAG_W-1:0] : '0;
  always_comb
    for (int w = 0; w < N_WAYS; w++) begin
      pseudo_enc_tag_resp[w] = {tag_resp[w][ENC_TAG_W-1:TAG_W],
                                tag_resp[w][TAG_W-1:0] ^ pseudo_tag_toggle_mask};
      enc_tag_resp[w]        = s0_fire_q_tag ? pseudo_enc_tag_resp[w] : enc_tag_hold[w];
    end
  always_ff @(posedge clock)
    if (s1_valid) enc_tag_hold <= enc_tag_resp;

  // 各路：meta 有效 / tag ECC 错 / tag 相等 / 命中
  logic [TAG_W-1:0]  s1_req_tag;
  logic [N_WAYS-1:0] s1_meta_valids, s1_tag_errors, s1_tag_eq_way, s1_tag_ecc_match_way;
  logic [N_WAYS-1:0] s1_real_tag_eq_way, s1_real_tag_match_way;
  logic              s1_tag_match, s1_has_real_tag_eq_way;
  assign s1_req_tag = s1_req.addr[PADDR_W-1:12];
  always_comb
    for (int w = 0; w < N_WAYS; w++) begin
      s1_meta_valids[w]       = s1_meta[w] != ST_NOTHING;
      s1_tag_errors[w]        = s1_meta_valids[w] && tag_ecc_error(enc_tag_resp[w]);
      s1_tag_eq_way[w]        = enc_tag_resp[w][TAG_W-1:0] == s1_req_tag;
      s1_tag_ecc_match_way[w] = s1_tag_eq_way[w] && !s1_tag_errors[w] && s1_meta_valids[w];
      // "真" tag：不经错误注入翻转、也不经保持寄存器，直接看 SRAM 线上值
      s1_real_tag_eq_way[w]   = tag_resp[w][TAG_W-1:0] == s1_req_tag && s1_meta_valids[w];
    end
  assign s1_tag_match           = |s1_tag_ecc_match_way;
  assign s1_has_real_tag_eq_way = |s1_real_tag_eq_way;
  // PriorityEncoderOH：取最低位的那一路
  assign s1_real_tag_match_way  = s1_real_tag_eq_way & (~s1_real_tag_eq_way + 4'd1);

  // 命中路的 coh（ParallelMux = 按独热选择的与或）
  logic [1:0] s1_hit_coh;
  always_comb begin
    s1_hit_coh = '0;
    for (int w = 0; w < N_WAYS; w++)
      s1_hit_coh |= s1_tag_ecc_match_way[w] ? s1_meta[w] : 2'b00;
  end

  // extra meta（error/prefetch/access 标志），同样要保持
  logic [$bits(extra_meta_t)-1:0] s1_extra_meta_sel;
  extra_meta_t                    s1_extra_meta, s1_extra_meta_hold;
  always_comb begin
    s1_extra_meta_sel = '0;
    for (int w = 0; w < N_WAYS; w++)
      s1_extra_meta_sel |= s1_tag_ecc_match_way[w] ? extra_meta_resp[w] : '0;
  end
  assign s1_extra_meta = s0_fire_q_extra ? s1_extra_meta_sel : s1_extra_meta_hold;
  always_ff @(posedge clock)
    if (s1_valid) s1_extra_meta_hold <= s1_extra_meta;

  // 替换路（同样要保持：替换算法的回答只在 s0_fire 后那一拍有效）
  logic [N_WAYS-1:0] s1_repl_way_sel, s1_repl_way_en, s1_repl_way_hold;
  assign s1_repl_way_sel =
    (pseudo_error_valid && s1_has_real_tag_eq_way) ? s1_real_tag_match_way :
    s1_req.miss_fail_cause_evict_btot              ? s1_req.occupy_way :
                                                     (4'b0001 << replace_way_way);
  assign s1_repl_way_en = s0_fire_q_repl ? s1_repl_way_sel : s1_repl_way_hold;
  always_ff @(posedge clock)
    if (s1_valid) s1_repl_way_hold <= s1_repl_way_en;

  // 被替换路的 tag / coh / 预取来源 / 原始 tag（按替换路独热选）
  logic [TAG_W-1:0]     s1_repl_tag;
  logic [1:0]           s1_repl_coh;
  logic [2:0]           s1_repl_pf;
  logic [ENC_TAG_W-1:0] s1_real_tag;
  always_comb begin
    s1_repl_tag = '0;
    s1_repl_coh = '0;
    s1_repl_pf  = '0;
    s1_real_tag = '0;
    for (int w = 0; w < N_WAYS; w++) begin
      s1_repl_tag |= s1_repl_way_en[w] ? enc_tag_resp[w][TAG_W-1:0] : '0;
      s1_repl_coh |= s1_repl_way_en[w] ? s1_meta[w] : '0;
      s1_repl_pf  |= s1_repl_way_en[w] ? extra_meta_resp[w].prefetch : '0;
      s1_real_tag |= s1_repl_way_en[w] ? tag_resp[w] : '0;
    end
  end

  logic              s1_need_replacement, s1_need_eviction;
  logic [N_WAYS-1:0] s1_way_en;
  assign s1_need_replacement = s1_req.miss && !s1_tag_match;
  assign s1_need_eviction    = s1_req.miss && !s1_tag_match && s1_repl_coh != ST_NOTHING;
  // 本请求最终用哪一路：要替换（或错误注入）就用替换路，否则用命中路
  assign s1_way_en = (pseudo_error_valid || s1_need_replacement) ? s1_repl_way_en : s1_tag_ecc_match_way;

  // 权限：growStarter(categorize(cmd), 命中路状态)
  logic [2:0] s1_grow;
  logic       s1_has_permission;
  logic [1:0] s1_shrink_perm;       // 权限不够时 = Acquire 参数；够时 = 新状态
  logic [1:0] s1_new_hit_coh;
  logic       s1_hit, s1_is_store, s1_is_amo, s1_pregen_can_go_to_mq, s1_grow_perm;
  assign s1_grow           = grow_starter(categorize(s1_req.cmd), s1_hit_coh);
  assign s1_has_permission = s1_grow[2];
  assign s1_shrink_perm    = s1_grow[1:0];
  assign s1_new_hit_coh    = s1_grow[1:0];
  assign s1_hit            = s1_tag_match && s1_has_permission;
  // "纯"来自 Sbuffer/AtomicsUnit 的请求（不是 refill 带着原 source 回来的）
  assign s1_is_store = !s1_req.replace && !s1_req.probe && !s1_req.miss && s1_req.source == STORE_SOURCE;
  assign s1_is_amo   = !s1_req.replace && !s1_req.probe && !s1_req.miss && s1_req.source == AMO_SOURCE &&
                       s1_req.cmd != M_XSC;
  assign s1_pregen_can_go_to_mq = (s1_is_store || s1_is_amo) && !s1_hit;   // 提前一拍算好：s2 去 MissQueue
  assign s1_grow_perm = s1_shrink_perm == GROW_BTOT && !s1_has_permission;

  // 发 data 整行读
  assign data_read_intend         = s1_valid && s1_need_data;
  assign data_readline_valid      = s1_valid && s1_need_data;
  assign data_readline_bits.rmask  = s1_banked_rmask;
  assign data_readline_bits.way_en = s1_way_en;
  assign data_readline_bits.addr   = s1_req.vaddr[PADDR_W-1:0];

  // 错误注入完成：s1 读到了有效 tag
  assign pseudo_tag_error_inj_done = s1_fire && |s1_meta_valids;

  // 向替换算法要受害路（s0_fire 后一拍的 set）
  assign replace_way_set_bits = s1_idx;

  // =====================================================================
  // §3 s2：分流 —— 命中的走 s3，store/AMO miss 走 MissQueue，refill 等数据
  // ---------------------------------------------------------------------
  //   s2 出口有三条：
  //     去 s3：SC / probe / (refill 且数据到了且替换不被挡) / (store/AMO 且命中)，且 s3 空得出来；
  //     去 MissQueue：store/AMO 未命中（s1 预先算好的 s2_can_go_to_mq）；
  //     回 MissQueue 重来：refill 连续两拍没等到数据，或替换被 MissQueue 挡住（BtoT 冲突）。
  //   BtoT：本地是 Branch 却要写，需向 L2 升权；该 set 里 BtoT 的路太多（>2）就取消。
  //   同时把 store（或 refill 带回来的 store）数据按字节掩码先预合并，s3 再与读出数据合并。
  // =====================================================================
  s2_req_t            s2_req;
  logic [N_WAYS-1:0]  s2_tag_errors;
  logic               s2_tag_match;
  logic               s2_has_real_tag_eq_way;
  logic [N_WAYS-1:0]  s2_tag_ecc_match_way;
  logic [1:0]         s2_hit_coh;
  logic               s2_has_permission;
  logic [1:0]         s2_new_hit_coh;
  logic               s2_grow_perm_q;
  logic [TAG_W-1:0]   s2_repl_tag;
  logic [1:0]         s2_repl_coh;
  logic [2:0]         s2_repl_pf;
  logic [ENC_TAG_W-1:0] s2_real_tag;
  logic               s2_need_replacement, s2_need_eviction, s2_need_data, s2_need_tag;
  logic [N_WAYS-1:0]  s2_way_en;
  logic [TAG_W-1:0]   s2_hit_tag;
  logic [1:0]         s2_hit_coh_for_s3;
  logic [N_BANKS-1:0] s2_banked_store_wmask;
  tl_error_t          s2_flag_error;
  logic               s2_can_go_to_mq;
  logic               s2_is_store, s2_is_amo;
  logic               s2_has_pseudo_inj;

  always_ff @(posedge clock) begin
    if (s1_fire) begin
      s2_req                 <= to_s2_req(s1_req);
      s2_tag_errors          <= s1_tag_errors;
      s2_tag_match           <= s1_tag_match;
      s2_has_real_tag_eq_way <= s1_has_real_tag_eq_way;
      s2_tag_ecc_match_way   <= s1_tag_ecc_match_way;
      s2_hit_coh             <= s1_hit_coh;
      s2_has_permission      <= s1_has_permission;
      s2_new_hit_coh         <= s1_new_hit_coh;
      s2_grow_perm_q         <= s1_grow_perm;
      s2_repl_tag            <= s1_repl_tag;
      s2_repl_coh            <= s1_repl_coh;
      s2_repl_pf             <= s1_repl_pf;
      s2_real_tag            <= s1_real_tag;
      s2_need_replacement    <= s1_need_replacement;
      s2_need_eviction       <= s1_need_eviction;
      s2_need_data           <= s1_need_data;
      s2_need_tag            <= s1_need_tag;
      s2_way_en              <= s1_way_en;
      s2_hit_tag             <= s1_req_tag;
      s2_hit_coh_for_s3      <= s1_hit_coh;
      s2_banked_store_wmask  <= s1_banked_store_wmask;
      s2_flag_error          <= s1_extra_meta.error;
      s2_can_go_to_mq        <= s1_pregen_can_go_to_mq;
      s2_is_store            <= s1_is_store;
      s2_is_amo              <= s1_is_amo;
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      s2_has_pseudo_inj <= 1'b0;
    else if (s1_fire)
      s2_has_pseudo_inj <= pseudo_error_valid;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      s2_valid <= 1'b0;
    else if (s1_fire)
      s2_valid <= 1'b1;
    else if (s2_fire)
      s2_valid <= 1'b0;
  end

  assign s2_idx = s2_req.vaddr[13:6];

  logic s2_grow_perm;
  assign s2_grow_perm = s2_grow_perm_q && s2_tag_match;

  // 错误注入时：被替换路的"真 tag"（未翻转）其实就等于请求 tag，且其 ECC 无错 -> 视作命中
  logic s2_refill_tag_eq_way;
  assign s2_refill_tag_eq_way = s2_has_pseudo_inj && s2_has_real_tag_eq_way && !tag_ecc_error(s2_real_tag);

  // 要替换时，写回用被替换路的 tag/coh；否则用本请求的 tag / 命中路 coh
  logic [TAG_W-1:0] s2_tag;
  logic [1:0]       s2_coh;
  assign s2_tag = s2_need_replacement ? s2_repl_tag : s2_hit_tag;
  assign s2_coh = s2_need_replacement ? s2_repl_coh : s2_hit_coh_for_s3;

  // 错误汇总
  tl_error_t s2_l2_error;
  logic      s2_tag_error, s2_error, s2_may_report_data_error;
  assign s2_l2_error = refill_info_valid ? refill_info_bits.error : '0;

  logic s2_hit, s2_sc, s2_lr, s2_amo_hit, s2_store_hit, s2_should_not_report_ecc_error;
  assign s2_hit       = (s2_tag_match || s2_refill_tag_eq_way) && s2_has_permission;
  assign s2_sc        = s2_req.cmd == M_XSC;
  assign s2_lr        = s2_req.cmd == M_XLR;
  assign s2_amo_hit   = s2_hit && !s2_req.probe && !s2_req.miss && s2_req.source == AMO_SOURCE;
  assign s2_store_hit = s2_hit && !s2_req.probe && !s2_req.miss && s2_req.source == STORE_SOURCE;
  assign s2_should_not_report_ecc_error =
    !s2_req.miss && ((s2_req.source == AMO_SOURCE && !s2_lr) || s2_req.source == STORE_SOURCE);

  // tag ECC 错：probe/原子看"没命中但有路出错"，其余看"本请求那一路出错"
  logic s2_probe_or_atomic;
  assign s2_probe_or_atomic = (s2_req.probe || (s2_req.source == AMO_SOURCE && !s2_sc)) && !s2_req.miss;
  assign s2_tag_error = ((s2_probe_or_atomic && !s2_tag_match && |s2_tag_errors) ||
                         (!s2_probe_or_atomic && |(s2_tag_errors & s2_way_en))) && s2_need_tag;
  assign s2_error     = |{s2_flag_error} || s2_tag_error || |{s2_l2_error};
  assign s2_may_report_data_error = s2_need_data && s2_coh != ST_NOTHING;

  // BtoT 升权失败：该 set 里已经有 3 路以上在 BtoT
  logic s2_grow_perm_fail;
  assign s2_grow_perm_fail = popcount4(btot_ways_for_set) > 3'(N_WAYS - 2) && s2_grow_perm;

  // 出口判定
  logic s2_replace_req_valid, s2_replace_block;
  logic s2_req_miss_without_data, s2_miss_waited_q, s2_can_go_to_mq_no_data;
  logic s2_can_go_to_mq_replay, s2_can_go_to_s3, s2_can_go, s2_valid_to_s3;
  logic replay;

  assign s2_replace_req_valid = s2_valid && s2_need_eviction && !s2_refill_tag_eq_way;
  assign s2_replace_block     = replace_block && s2_replace_req_valid;
  assign s2_req_miss_without_data = s2_valid ? (s2_req.miss && !refill_info_valid) : 1'b0;
  // refill 在 s2 没等到数据：第一拍先等，连续第二拍还没有就回 MissQueue
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      s2_miss_waited_q <= 1'b0;
    else if (s2_valid)
      s2_miss_waited_q <= s2_req_miss_without_data && !s2_can_go_to_mq_no_data;
  end
  assign s2_can_go_to_mq_no_data = s2_req_miss_without_data && s2_miss_waited_q;
  assign s2_can_go_to_mq_replay  = s2_can_go_to_mq_no_data || s2_replace_block;
  assign s2_can_go_to_s3 = (s2_sc || s2_req.replace || s2_req.probe ||
                            (s2_req.miss ? (refill_info_valid && !s2_replace_block)
                                         : ((s2_req.source == STORE_SOURCE || s2_req.source == AMO_SOURCE) &&
                                            s2_hit))) && s3_ready;
  assign s2_can_go      = s2_can_go_to_s3 || s2_can_go_to_mq || s2_can_go_to_mq_replay;
  assign s2_fire        = s2_valid && s2_can_go;
  assign s2_fire_to_s3  = s2_valid && s2_can_go_to_s3;
  assign s2_ready       = !s2_valid || s2_can_go;
  assign s2_valid_to_s3 = s2_valid && s3_ready;
  assign replay         = !miss_req_ready || wbq_block_miss_req;

  // data SRAM 读流水的握手旁路信号
  logic s1_fire_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s1_fire_q <= 1'b0;
    else       s1_fire_q <= s1_fire;
  end
  assign data_readline_can_go   = s1_fire_q;
  assign data_readline_stall    = s2_valid;
  assign data_readline_can_resp = s2_fire_to_s3;

  // store 数据预合并：refill 用 MissQueue 带回的 store 数据，否则用本请求的；AMO 命中不合并
  logic [511:0]                   s2_new_data;
  logic [63:0]                    s2_new_mask;
  logic [N_BANKS-1:0][7:0]        s2_merge_mask;
  logic [N_BANKS-1:0][BANK_W-1:0] s2_store_data_merged_without_cache;
  assign s2_new_data = s2_req.miss ? refill_info_bits.store_data : s2_req.store_data;
  assign s2_new_mask = s2_req.miss ? refill_info_bits.store_mask : s2_req.store_mask;
  always_comb
    for (int b = 0; b < N_BANKS; b++) begin
      s2_merge_mask[b] = s2_amo_hit ? 8'h00 : s2_new_mask[b*8 +: 8];
      s2_store_data_merged_without_cache[b] =
        merge_put_data(64'h0, s2_new_data[b*BANK_W +: BANK_W], s2_merge_mask[b]);
    end

  assign pseudo_data_error_inj_done = s2_fire_to_s3 && (s2_tag_error || s2_hit) && s2_may_report_data_error;

  // -> MissQueue
  assign miss_req_valid                = s2_valid && s2_can_go_to_mq;
  assign miss_req_bits.source          = s2_req.source;
  assign miss_req_bits.cmd             = s2_req.cmd;
  assign miss_req_bits.addr            = s2_req.addr;
  assign miss_req_bits.vaddr           = s2_req.vaddr;
  assign miss_req_bits.full_overwrite  = s2_req.source == STORE_SOURCE && &s2_req.store_mask;
  assign miss_req_bits.word_idx        = s2_req.word_idx;
  assign miss_req_bits.amo_data        = s2_req.amo_data;
  assign miss_req_bits.amo_mask        = s2_req.amo_mask;
  assign miss_req_bits.amo_cmp         = s2_req.amo_cmp;
  assign miss_req_bits.req_coh_state   = s2_hit_coh;
  assign miss_req_bits.id              = s2_req.id;
  assign miss_req_bits.isBtoT          = s2_grow_perm;
  assign miss_req_bits.occupy_way      = s2_tag_ecc_match_way;
  assign miss_req_bits.cancel          = s2_grow_perm_fail;
  assign miss_req_bits.store_data      = s2_req.store_data;
  assign miss_req_bits.store_mask      = s2_req.store_mask;

  assign wbq_conflict_check_valid = s2_valid && s2_can_go_to_mq;
  assign wbq_conflict_check_bits  = s2_req.addr;

  // -> Sbuffer：store miss 被 MissQueue 拒（replay）或 BtoT 升权失败，要求重发
  //   注意用 s2_is_store（纯 Sbuffer 来的），不含 refill 带回的 store
  assign store_replay_resp_valid   = s2_valid && ((s2_can_go_to_mq && replay && s2_req.source == STORE_SOURCE) ||
                                                  (s2_grow_perm_fail && s2_is_store));
  assign store_replay_resp_bits_id = s2_req.id;

  // -> MissQueue：替换 / 下一个可逐出路 / refill 状态
  assign replace_req_bits.addr  = {s2_tag, s2_req.vaddr[11:6], 6'b0};
  assign replace_req_bits.vaddr = s2_req.vaddr;
  assign evict_set              = s2_req.vaddr[13:6];

  // =====================================================================
  // §4 s3：拿到数据 —— 合并、AMO/LR/SC/CAS、写 data/meta/tag/标志位、写回
  // ---------------------------------------------------------------------
  //   s3 的 data = s2 预合并的 store 数据盖在 SRAM 读出数据上（按字节）。
  //   AMO（非 LR/SC/CAS）要多等一拍：第一拍算 AMOALU 并把结果合并进寄存器
  //   （s3_s_amoalu 置 1），第二拍才能写。LR 设保留集（64 拍窗口，前 8 拍不算有效），
  //   SC 在保留集有效且地址匹配、且命中时成功。CAS 比较 amo_cmp 与旧值，相等才写。
  //   写回（Release/ProbeAck）：refill 需要替换掉一个有效行、probe、replace 三种情况。
  // =====================================================================
  s3_req_t                        s3_req;
  logic [1:0]                     s3_miss_param;
  logic [TAG_W-1:0]               s3_tag;
  logic                           s3_tag_match;
  logic [1:0]                     s3_coh;
  logic                           s3_hit, s3_amo_hit, s3_store_hit;
  logic [1:0]                     s3_hit_coh, s3_new_hit_coh;
  logic [N_WAYS-1:0]              s3_way_en;
  logic [N_BANKS-1:0]             s3_banked_store_wmask;
  logic [N_BANKS-1:0][BANK_W-1:0] s3_store_data_merged_without_cache;
  logic [N_BANKS-1:0][7:0]        s3_merge_mask;          // 取反后的掩码：1 = 用 SRAM 读出数据
  logic                           s3_need_replacement;
  logic                           s3_tag_error_wb, s3_data_error_wb_q;
  tl_error_t                      s3_l2_error_wb;
  logic                           s3_tag_error_beu, s3_data_error_beu_q;
  tl_error_t                      s3_flag_error_beu;
  logic [PADDR_W-1:0]             s3_error_paddr_beu_q;
  logic                           s3_error_beu_q;

  // s2 -> s3：请求本身在"s2 有效且 s3 空得出来"时就打拍（即使 s2 本拍去的是 MissQueue）
  always_ff @(posedge clock) begin
    if (s2_valid_to_s3) begin
      s3_req        <= to_s3_req(s2_req);
      s3_miss_param <= refill_info_bits.miss_param;
      s3_tag        <= s2_tag;
    end
  end

  // 其余状态只在真正进 s3 时打拍
  always_ff @(posedge clock) begin
    if (s2_fire_to_s3) begin
      s3_tag_match          <= s2_tag_match;
      s3_coh                <= s2_coh;
      s3_hit                <= s2_hit;
      s3_amo_hit            <= s2_amo_hit;
      s3_store_hit          <= s2_store_hit;
      s3_hit_coh            <= s2_hit_coh;
      s3_new_hit_coh        <= s2_new_hit_coh;
      s3_way_en             <= s2_way_en;
      s3_banked_store_wmask <= s2_banked_store_wmask;
      s3_idx                <= s2_idx;
      s3_store_data_merged_without_cache <= s2_store_data_merged_without_cache;
      for (int b = 0; b < N_BANKS; b++)
        s3_merge_mask[b] <= ~s2_merge_mask[b];
      s3_need_replacement   <= s2_need_replacement && !s2_refill_tag_eq_way;
      s3_tag_error_wb       <= s2_tag_error;
      s3_data_error_wb_q    <= s2_may_report_data_error;
      s3_l2_error_wb        <= s2_l2_error;
    end
  end

  // 报给总线错误单元（BEU）的那一套：只要 s2 fire（不论去哪）就打拍
  always_ff @(posedge clock) begin
    if (s2_fire) begin
      s3_tag_error_beu     <= s2_tag_error;
      s3_data_error_beu_q  <= s2_may_report_data_error;
      s3_flag_error_beu    <= s2_flag_error;
      s3_error_paddr_beu_q <= {s2_tag, s2_req.vaddr[11:0]};
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      s3_error_beu_q <= 1'b0;
    else if (s2_fire)
      s3_error_beu_q <= s2_error;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      s3_valid <= 1'b0;
    else if (s2_fire_to_s3)
      s3_valid <= 1'b1;
    else if (s3_fire)
      s3_valid <= 1'b0;
  end

  // ---- 数据合并：预合并的 store 数据盖在 SRAM 读出数据上 ----
  logic [N_BANKS-1:0][BANK_W-1:0] s3_data, s3_store_data_merged;
  always_comb
    for (int b = 0; b < N_BANKS; b++) begin
      s3_data[b]              = data_resp[b].raw_data;
      s3_store_data_merged[b] = merge_put_data(s3_store_data_merged_without_cache[b], s3_data[b],
                                               s3_merge_mask[b]);
    end

  // AMO 作用的 64 位字，以及 CAS.Q 用的 128 位"字对"（最后一个 bank 高半补 0）
  logic [BANK_W-1:0]         s3_data_word;
  logic [N_BANKS-1:0][127:0] s3_quad_candidates;
  logic [127:0]              s3_data_quad_word;
  assign s3_data_word = s3_store_data_merged[s3_req.word_idx];
  always_comb
    for (int b = 0; b < N_BANKS; b++)
      s3_quad_candidates[b] = (b == N_BANKS - 1) ? {64'h0, s3_store_data_merged[b]}
                                                 : {s3_store_data_merged[b + 1], s3_store_data_merged[b]};
  assign s3_data_quad_word = s3_quad_candidates[s3_req.word_idx];

  // ---- 请求分类 ----
  logic s3_is_store_src, s3_is_amo_src;
  logic s3_lr, s3_sc, s3_cas, amo_wait_amoalu;
  assign s3_is_store_src = s3_req.source == STORE_SOURCE;
  assign s3_is_amo_src   = s3_req.source == AMO_SOURCE;
  assign s3_lr  = !s3_req.probe && s3_is_amo_src && s3_req.cmd == M_XLR;
  assign s3_sc  = !s3_req.probe && s3_is_amo_src && s3_req.cmd == M_XSC;
  assign s3_cas = !s3_req.probe && s3_is_amo_src && is_amocas(s3_req.cmd);
  // 需要走 AMOALU（多等一拍）的：除 LR/SC/CAS 外的 AMO
  assign amo_wait_amoalu = s3_is_amo_src && s3_req.cmd != M_XLR && s3_req.cmd != M_XSC &&
                           !is_amocas(s3_req.cmd);

  // ---- LR/SC 保留集 ----
  logic [5:0]         lrsc_count;
  logic [PADDR_W-1:0] lrsc_addr;
  logic               lrsc_valid;
  logic [PADDR_W-1:0] s3_block_addr;
  logic               s3_lrsc_addr_match, s3_cas_fail;
  logic               s3_can_do_amo, s3_can_do_amo_write;
  assign lrsc_valid         = lrsc_count > LRSC_BACKOFF;
  assign s3_block_addr      = {s3_req.addr[PADDR_W-1:6], 6'b0};
  assign s3_lrsc_addr_match = lrsc_valid && lrsc_addr == s3_block_addr;
  assign s3_sc_fail         = s3_sc && (!s3_lrsc_addr_match || !s3_hit);
  assign s3_cas_fail        = s3_cas &&
                              (({byte_mask_to_bits(s3_req.amo_mask[15:8]), byte_mask_to_bits(s3_req.amo_mask[7:0])} &
                                (s3_req.amo_cmp ^ s3_data_quad_word)) != '0);
  // 能做 AMO：AMO miss 回填到了，或 AMO 命中
  assign s3_can_do_amo       = (s3_req.miss && !s3_req.probe && s3_is_amo_src) || s3_amo_hit;
  assign s3_can_do_amo_write = s3_can_do_amo && is_write(s3_req.cmd) && !s3_sc_fail && !s3_cas_fail;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      lrsc_count <= 6'd0;
    else if (s3_valid && (s3_lr || s3_sc))
      lrsc_count <= (s3_can_do_amo && s3_lr) ? LRSC_CYCLES_M1 : 6'd0;   // LR 打开窗口，SC 关掉
    else if (invalid_resv_set)
      lrsc_count <= 6'd0;                                                // 该块被 release
    else if (lrsc_count > 6'd0)
      lrsc_count <= lrsc_count - 6'd1;
  end

  always_ff @(posedge clock)
    if (s3_valid && (s3_lr || s3_sc) && s3_can_do_amo && s3_lr)
      lrsc_addr <= s3_block_addr;

  assign lrsc_locked_block_valid = lrsc_valid;
  assign lrsc_locked_block_bits  = lrsc_addr;
  assign update_resv_set         = s3_valid && s3_lr && s3_can_do_amo;

  logic lrsc_busy_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) lrsc_busy_q <= 1'b0;
    else       lrsc_busy_q <= lrsc_count > 6'd0;
  end
  assign block_lr = lrsc_busy_q;

  // ---- AMOALU（非 LR/SC/CAS 的 AMO）：第一拍算，结果合并进寄存器 ----
  logic                           s3_s_amoalu;         // 本 AMO 已算过 ALU
  logic                           do_amoalu;
  logic [BANK_W-1:0]              amoalu_out;
  logic [N_BANKS-1:0][BANK_W-1:0] s3_amo_data_merged, s3_amo_data_merged_q;
  logic [N_BANKS-1:0][BANK_W-1:0] s3_sc_data_merged, s3_cas_data_merged;

  assign do_amoalu = amo_wait_amoalu && s3_valid && !s3_s_amoalu;

  AMOALU amoalu (
    .io_mask(s3_req.amo_mask[7:0]),
    .io_cmd (s3_req.cmd),
    .io_lhs (s3_data_word),
    .io_rhs (s3_req.amo_data[63:0]),
    .io_out (amoalu_out)
  );

  logic [N_BANKS-1:0] cas_l_select, cas_h_select;
  always_comb
    for (int b = 0; b < N_BANKS; b++) begin
      // AMO：结果整字写到 word_idx 那个 bank
      s3_amo_data_merged[b] = merge_put_data(s3_store_data_merged[b], amoalu_out,
                                             (s3_req.word_idx == 3'(b)) ? 8'hFF : 8'h00);
      // SC：成功时把 amo_data 按 amo_mask 写进 word_idx 那个 bank
      s3_sc_data_merged[b]  = merge_put_data(s3_store_data_merged[b], s3_req.amo_data[63:0],
                                             (s3_req.word_idx == 3'(b) && !s3_sc_fail) ?
                                               s3_req.amo_mask[7:0] : 8'h00);
      // CAS：比较成功时写；CAS.Q 的高 64 位写到 word_idx+1（奇数 bank）
      cas_l_select[b] = !s3_cas_fail && s3_req.word_idx == 3'(b);
      cas_h_select[b] = !s3_cas_fail && s3_req.cmd == M_XA_CASQ && (b % 2 == 1) &&
                        s3_req.word_idx == 3'(b - 1);
      s3_cas_data_merged[b] = merge_put_data(s3_store_data_merged[b],
                                             cas_h_select[b] ? s3_req.amo_data[127:64] : s3_req.amo_data[63:0],
                                             cas_h_select[b] ? s3_req.amo_mask[15:8] :
                                             cas_l_select[b] ? s3_req.amo_mask[7:0] : 8'h00);
    end

  always_ff @(posedge clock)
    if (do_amoalu) s3_amo_data_merged_q <= s3_amo_data_merged;

  // ---- 写回（Release / ProbeAck）----
  logic [4:0] probe_shrink;      // {param, 新状态}
  logic [4:0] miss_shrink;
  logic [2:0] probe_shrink_param, miss_shrink_param;
  logic [1:0] probe_new_coh;
  assign probe_shrink       = shrink_helper(s3_req.probe_param, s3_coh);
  assign probe_shrink_param = probe_shrink[4:2];
  assign probe_new_coh      = probe_shrink[1:0];
  assign miss_shrink        = shrink_helper(CAP_TON, s3_coh);    // onCacheControl(M_FLUSH)：cap = toN
  assign miss_shrink_param  = miss_shrink[4:2];

  logic miss_wb, probe_wb, replace_wb, need_wb, writeback_data;
  logic [2:0] writeback_param;
  assign miss_wb    = s3_req.miss && s3_need_replacement && s3_coh != ST_NOTHING;
  assign probe_wb   = s3_req.probe;
  assign replace_wb = s3_req.replace;
  assign need_wb    = miss_wb || probe_wb || replace_wb;
  assign writeback_param = probe_wb ? probe_shrink_param : miss_shrink_param;
  // alwaysReleaseData=false：probe 要数据且命中，或本块是脏的，才带数据
  assign writeback_data  = (s3_tag_match && s3_req.probe && s3_req.probe_need_data) || s3_coh == ST_DIRTY;

  // ---- meta 更新 ----
  logic miss_update_meta, probe_update_meta, store_update_meta, amo_update_meta, update_meta;
  logic update_data;
  logic [1:0] miss_new_coh, new_coh;
  assign miss_update_meta  = s3_req.miss;
  assign probe_update_meta = s3_req.probe && s3_tag_match && s3_coh != probe_new_coh;
  assign store_update_meta = s3_is_store_src && !s3_req.probe && s3_hit_coh != s3_new_hit_coh;
  assign amo_update_meta   = s3_is_amo_src && !s3_req.probe && s3_hit_coh != s3_new_hit_coh && !s3_sc_fail;
  assign update_meta       = (miss_update_meta || probe_update_meta || store_update_meta || amo_update_meta) &&
                             !s3_req.replace;
  assign miss_new_coh      = REFILL_MISS_DIRTY ? ST_NOTHING : miss_coh_gen(categorize(s3_req.cmd), s3_miss_param);
  assign new_coh = miss_update_meta                     ? miss_new_coh :
                   probe_update_meta                    ? probe_new_coh :
                   (store_update_meta || amo_update_meta) ? s3_new_hit_coh :
                                                          ST_NOTHING;
  assign update_data = s3_req.miss || s3_store_hit || s3_can_do_amo_write;

  // ---- s3 各类请求能否完成 ----
  logic s3_probe_can_go, s3_store_can_go, s3_amo_can_go, s3_miss_can_go;
  logic s3_replace_nothing, s3_replace_can_go, s3_can_go, s3_update_data_cango;
  assign s3_probe_can_go = s3_req.probe && wb_ready && (META_WRITE_READY || !probe_update_meta);
  assign s3_store_can_go = s3_is_store_src && !s3_req.probe && (META_WRITE_READY || !store_update_meta) &&
                           (DATA_WRITE_READY || !update_data) && !s3_req.miss;
  assign s3_amo_can_go   = (s3_amo_hit && (META_WRITE_READY || !amo_update_meta) &&
                            (DATA_WRITE_READY || !update_data) && (s3_s_amoalu || !amo_wait_amoalu)) ||
                           s3_sc_fail;
  assign s3_miss_can_go  = s3_req.miss && (META_WRITE_READY || !amo_update_meta) &&
                           (DATA_WRITE_READY || !update_data) && (s3_s_amoalu || !amo_wait_amoalu) &&
                           TAG_WRITE_READY && wb_ready;
  assign s3_replace_nothing = s3_req.replace && s3_coh == ST_NOTHING;
  assign s3_replace_can_go  = s3_req.replace && (s3_replace_nothing || wb_ready);
  assign s3_can_go = s3_probe_can_go || s3_store_can_go || s3_amo_can_go || s3_miss_can_go || s3_replace_can_go;
  assign s3_update_data_cango = s3_store_can_go || s3_amo_can_go || s3_miss_can_go;
  assign s3_fire  = s3_valid && s3_can_go;
  assign s3_ready = !s3_valid || s3_can_go;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      s3_s_amoalu <= 1'b0;
    else if (s3_fire)
      s3_s_amoalu <= 1'b0;
    else if (do_amoalu)
      s3_s_amoalu <= 1'b1;
  end

  // ---- 写 data ----
  logic [N_BANKS-1:0] banked_wmask;
  assign banked_wmask =
    s3_req.miss         ? {N_BANKS{1'b1}} :
    s3_store_hit        ? s3_banked_store_wmask :
    s3_can_do_amo_write ? ((s3_req.cmd == M_XA_CASQ) ?
                             {{2{s3_req.word_idx[2:1] == 2'd3}}, {2{s3_req.word_idx[2:1] == 2'd2}},
                              {2{s3_req.word_idx[2:1] == 2'd1}}, {2{s3_req.word_idx[2:1] == 2'd0}}} :
                             (8'b1 << s3_req.word_idx)) :
                          {N_BANKS{1'b0}};

  assign data_write_valid      = s3_valid && s3_update_data_cango && update_data;
  assign data_write_bits.wmask = banked_wmask;
  for (genvar b = 0; b < N_BANKS; b++) begin : g_data_write
    assign data_write_bits.data[b] = amo_wait_amoalu ? s3_amo_data_merged_q[b] :
                                     s3_sc           ? s3_sc_data_merged[b] :
                                     s3_cas          ? s3_cas_data_merged[b] :
                                                       s3_store_data_merged[b];
    // 每个 bank 一份写控制（时序复制，内容相同）
    assign data_write_dup[b].valid       = s3_valid && s3_update_data_cango && update_data;
    assign data_write_dup[b].bits.way_en = s3_way_en;
    assign data_write_dup[b].bits.addr   = s3_req.vaddr[PADDR_W-1:0];
  end

  // ---- 写 meta / 标志位 / tag ----
  assign meta_write_valid               = s3_fire && update_meta;
  assign meta_write_bits.idx            = s3_idx;
  assign meta_write_bits.way_en         = s3_way_en;
  assign meta_write_bits.meta_coh_state = new_coh;

  assign error_flag_write_valid       = s3_fire && update_meta && (|{s3_l2_error_wb} || s3_req.miss);
  assign error_flag_write_bits.idx    = s3_idx;
  assign error_flag_write_bits.way_en = s3_way_en;
  assign error_flag_write_bits.error  = s3_l2_error_wb;

  assign prefetch_flag_write_valid       = s3_fire && s3_req.miss;
  assign prefetch_flag_write_bits.idx    = s3_idx;
  assign prefetch_flag_write_bits.way_en = s3_way_en;
  assign prefetch_flag_write_bits.source = s3_req.pf_source;

  // probe / replace 不算访问
  assign access_flag_write_valid       = s3_fire && !s3_req.probe && !s3_req.replace;
  assign access_flag_write_bits.idx    = s3_idx;
  assign access_flag_write_bits.way_en = s3_way_en;
  assign access_flag_write_bits.flag   = s3_req.miss ? s3_req.access : 1'b1;

  assign tag_write_valid       = s3_fire && s3_req.miss;
  assign tag_write_bits.idx    = s3_idx;
  assign tag_write_bits.way_en = s3_way_en;
  assign tag_write_bits.tag    = s3_req.addr[PADDR_W-1:12];
  assign tag_write_intend      = s3_req.miss && s3_valid;

  // ---- 写回队列 ----
  assign wb_valid = s3_valid && (
                      (s3_req.replace && !s3_replace_nothing) ||
                      (s3_req.probe && (META_WRITE_READY || !probe_update_meta)) ||
                      (s3_req.miss && (META_WRITE_READY || !amo_update_meta) &&
                       (DATA_WRITE_READY || !update_data) && (s3_s_amoalu || !amo_wait_amoalu) &&
                       TAG_WRITE_READY)
                    ) && need_wb;
  assign wb_bits.addr      = {s3_tag, s3_req.vaddr[11:6], 6'b0};
  assign wb_bits.param     = writeback_param;
  assign wb_bits.voluntary = s3_req.miss || s3_req.replace;
  assign wb_bits.hasData   = writeback_data && !s3_tag_error_wb;
  assign wb_bits.dirty     = s3_coh == ST_DIRTY;
  assign wb_bits.data      = s3_data;
  assign wb_bits.corrupt   = s3_tag_error_wb || (readline_error_delayed && s3_data_error_wb_q);

  // ---- 应答 ----
  assign store_hit_resp_valid   = s3_valid && (s3_store_can_go || (s3_miss_can_go && s3_is_store_src));
  assign store_hit_resp_bits_id = s3_req.id;

  // AtomicsUnit：s2 的 replay 应答优先于 s3 的完成应答（两者 DontCare 字段在 golden 里取 0）
  logic atomic_replay_resp_valid, atomic_hit_resp_valid;
  assign atomic_replay_resp_valid = s2_valid && ((s2_can_go_to_mq && replay) || s2_grow_perm_fail) &&
                                    s2_req.source == AMO_SOURCE;
  assign atomic_hit_resp_valid    = s3_valid && (s3_amo_can_go || (s3_miss_can_go && s3_is_amo_src));
  assign atomic_resp_valid = atomic_replay_resp_valid || atomic_hit_resp_valid;
  always_comb begin
    if (atomic_replay_resp_valid) begin
      atomic_resp_bits                = '0;
      atomic_resp_bits.source         = s2_req.source;
      atomic_resp_bits.miss           = 1'b1;
      atomic_resp_bits.replay         = 1'b1;
    end else begin
      atomic_resp_bits                = '0;
      atomic_resp_bits.source         = s3_req.source;
      atomic_resp_bits.data           = s3_sc ? 128'(s3_sc_fail) : s3_data_quad_word;
      atomic_resp_bits.miss_id        = s3_req.miss_id;
      atomic_resp_bits.tl_error.tl_denied  = s3_l2_error_wb.tl_denied | s3_flag_error_beu.tl_denied;
      atomic_resp_bits.tl_error.tl_corrupt = s3_l2_error_wb.tl_corrupt | s3_flag_error_beu.tl_corrupt;
      atomic_resp_bits.ack_miss_queue = s3_req.miss;
      atomic_resp_bits.id             = 6'(lrsc_valid);      // 借 id 字段回报保留集状态
    end
  end

  // ---- 替换算法状态更新（PLRU touch）----
  logic s2_fire_to_s3_q_repl;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s2_fire_to_s3_q_repl <= 1'b0;
    else       s2_fire_to_s3_q_repl <= s2_fire_to_s3;
  end
  assign replace_access_valid = s2_fire_to_s3_q_repl && !s3_req.probe &&
                                (s3_req.miss || ((s3_is_amo_src || s3_is_store_src) && s3_hit));
  assign replace_access_bits.set = s3_idx;
  assign replace_access_bits.way = {|s3_way_en[3:2], s3_way_en[3] | s3_way_en[1]};   // OHToUInt

  // ---- ECC 错误上报 ----
  logic s2_fire_to_s3_q_err, err_report_q, s2_fire_q;
  logic s3_data_error_beu, s3_error_beu;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_fire_to_s3_q_err <= 1'b0;
      err_report_q        <= 1'b0;
    end else begin
      s2_fire_to_s3_q_err <= s2_fire_to_s3;
      err_report_q        <= s2_fire && !s2_should_not_report_ecc_error;
    end
  end
  always_ff @(posedge clock)
    s2_fire_q <= s2_fire;
  // data ECC 错由 data 阵列晚一拍报来
  assign s3_data_error_beu = readline_error_delayed && s2_fire_to_s3_q_err && s3_data_error_beu_q;
  assign s3_error_beu      = s3_error_beu_q || s3_data_error_beu;
  assign error_valid              = s3_error_beu && err_report_q;
  assign error_bits.report_to_beu = (s3_tag_error_beu || s3_data_error_beu) && s2_fire_q;
  assign error_bits.paddr         = {s3_error_paddr_beu_q[PADDR_W-1:6], 6'b0};

  // =====================================================================
  // §5 给 MissQueue / 预取器 / SMS 的旁路信息
  // =====================================================================
  logic s3_refill_resp_q;
  always_ff @(posedge clock)
    s3_refill_resp_q <= s2_valid && s2_req.miss && s2_fire_to_s3;

  assign mainpipe_info.s2_valid          = s2_valid && s2_req.miss;
  assign mainpipe_info.s2_miss_id        = s2_req.miss_id;
  assign mainpipe_info.s2_replay_to_mq   = s2_can_go_to_mq_no_data;
  assign mainpipe_info.s2_evict_BtoT_way = s2_replace_block;
  assign mainpipe_info.s2_next_evict_way = ~btot_ways_for_set & (btot_ways_for_set + 4'd1);  // PriorityEncoderOH(~btot)
  assign mainpipe_info.s3_valid          = s3_valid;
  assign mainpipe_info.s3_miss_id        = s3_req.miss_id;
  assign mainpipe_info.s3_refill_resp    = s3_refill_resp_q;

  // 布隆过滤器：refill 替换掉一个"没被用过的 L1 预取行"时置位；预取行被 demand 用到时清除
  function automatic logic is_from_l1_prefetch(input logic [2:0] pf);
    return pf > L1_PF_CLEAR;
  endfunction
  logic [41:0] s2_evict_block, s3_req_block;
  assign s2_evict_block = {s2_repl_tag, s2_req.vaddr[11:6]};
  assign s3_req_block   = s3_req.addr[PADDR_W-1:6];
  assign bloom_filter_query.set.valid     = s2_fire_to_s3 && s2_req.miss && !is_from_l1_prefetch(s2_repl_pf) &&
                                            s2_repl_coh != ST_NOTHING && is_from_l1_prefetch(s2_req.pf_source);
  assign bloom_filter_query.set.bits_addr = s2_evict_block[11:0] ^ s2_evict_block[23:12];
  assign bloom_filter_query.clr.valid     = s3_fire && is_from_l1_prefetch(s3_req.pf_source);
  assign bloom_filter_query.clr.bits_addr = s3_req_block[11:0] ^ s3_req_block[23:12];

  // SMS：refill 在 s2 进 s3 时，把被替换行的地址告诉空间预取器（下一拍）
  logic                sms_agt_evict_valid, sms_evict_valid_q;
  logic [VADDR_W-1:0]  sms_evict_vaddr_q;
  assign sms_agt_evict_valid = s2_valid && s2_req.miss && s2_fire_to_s3;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) sms_evict_valid_q <= 1'b0;
    else       sms_evict_valid_q <= sms_agt_evict_valid;
  end
  always_ff @(posedge clock)
    if (sms_agt_evict_valid)
      sms_evict_vaddr_q <= {s2_repl_tag[TAG_W-1:2], s2_req.vaddr[13:12], 14'h0};
  assign sms_agt_evict_req_valid      = sms_evict_valid_q;
  assign sms_agt_evict_req_bits_vaddr = sms_evict_vaddr_q;

  // =====================================================================
  // §6 status_dup：24 份 s1/s2/s3 占用状态（给各 load 流水查冲突，扇出复制）
  // ---------------------------------------------------------------------
  //   每份自己打自己的 set / replace / way_en 拍（golden 就是 24 份独立寄存器，
  //   值恒等但一份不能少）；valid 与 s1/s2 的 way_en 直接复用主流水的。
  // =====================================================================
  logic [N_DUP-1:0][IDX_W-1:0]  dup_s1_set_q, dup_s2_set_q, dup_s3_set_q;
  logic [N_DUP-1:0]             dup_s2_replace_q, dup_s3_replace_q;
  logic [N_DUP-1:0][N_WAYS-1:0] dup_s3_way_en_q;

  for (genvar k = 0; k < N_DUP; k++) begin : g_status_dup
    always_ff @(posedge clock) begin
      if (s0_fire)
        dup_s1_set_q[k] <= s0_idx;
      if (s1_fire) begin
        dup_s2_replace_q[k] <= s1_req.replace;
        dup_s2_set_q[k]     <= s1_idx;
      end
      if (s2_fire_to_s3) begin
        dup_s3_replace_q[k] <= s2_req.replace;
        dup_s3_set_q[k]     <= s2_idx;
        dup_s3_way_en_q[k]  <= s2_way_en;
      end
    end
    assign status_dup[k].s1.valid       = s1_valid;
    assign status_dup[k].s1.bits.set    = dup_s1_set_q[k];
    assign status_dup[k].s1.bits.way_en = s1_way_en;
    assign status_dup[k].s2.valid       = s2_valid && !dup_s2_replace_q[k];
    assign status_dup[k].s2.bits.set    = dup_s2_set_q[k];
    assign status_dup[k].s2.bits.way_en = s2_way_en;
    assign status_dup[k].s3.valid       = s3_valid && !dup_s3_replace_q[k];
    assign status_dup[k].s3.bits.set    = dup_s3_set_q[k];
    assign status_dup[k].s3.bits.way_en = dup_s3_way_en_q[k];
  end

  // =====================================================================
  // §7 性能事件（两级打拍后输出）
  // =====================================================================
  logic       perf_write_access, perf_write_miss;
  logic [2:0] perf_busy_stages;
  assign perf_write_access = s2_fire && (s2_is_store || (s2_is_amo && is_write(s2_req.cmd)));
  assign perf_write_miss   = s2_fire && (s2_is_store || (s2_is_amo && is_write(s2_req.cmd) && !s2_hit));
  assign perf_busy_stages  = popcount4({s0_fire, s1_valid, s2_valid, s3_valid});

  logic       perf0_q1, perf0_q2, perf1_q1, perf1_q2, perf2_q1, perf2_q2;
  logic [2:0] perf3_q1, perf3_q2;
  always_ff @(posedge clock) begin
    perf0_q1 <= perf_write_access;  perf0_q2 <= perf0_q1;   // l1D_write_dcache_access
    perf1_q1 <= perf_write_miss;    perf1_q2 <= perf1_q1;   // l1D_write_dcache_miss
    perf2_q1 <= s0_fire;            perf2_q2 <= perf2_q1;   // dcache_mp_req
    perf3_q1 <= perf_busy_stages;   perf3_q2 <= perf3_q1;   // dcache_mp_total_penalty
  end
  assign perf[0].value = 6'(perf0_q2);
  assign perf[1].value = 6'(perf1_q2);
  assign perf[2].value = 6'(perf2_q2);
  assign perf[3].value = 6'(perf3_q2);

  // =====================================================================
  // §8 仿真期检查用的寄存器（golden 同样保留；综合口径下没有读者）
  // ---------------------------------------------------------------------
  //   Chisel 的 assert(RegNext(...)) / XSError 计数器在 golden 里是真寄存器，只有
  //   `ifndef SYNTHESIS` 段读它们。这里照样保留同一批寄存器，并给出同义的仿真断言。
  //   另有一个"替换算法查询 valid"（io.replace_way.set.valid）的打拍寄存器：端口被
  //   firtool 删了，寄存器留着（只被性能计数表达式引用）。
  // =====================================================================
  logic               chk_multi_way_q;       // RegNext(s1_fire && PopCount(s1_way_en) > 1)
  logic               chk_s2_exclusive_q;    // RegNext(!(s2 同时去 s3 / 去 MQ / 回 MQ))
  logic               chk_tag_write_q;       // RegNext(tag_write.valid && !tag_write_intend)
  logic               chk_tag_write_repl_q;  // RegNext(!tag_write.valid || !s3_req.replace)
  logic               chk_data_write_repl_q; // RegNext(!data_write.valid || !s3_req.replace)
  logic               s0_fire_q_replway;     // io.replace_way.set.valid（端口已删）
  logic [PADDR_W-1:0] debug_sc_fail_addr;
  logic [7:0]         debug_sc_addr_match_fail_cnt;

  always_ff @(posedge clock) begin
    chk_multi_way_q       <= s1_fire && popcount4(s1_way_en) > 3'd1;
    chk_s2_exclusive_q    <= !(s2_valid && s2_can_go_to_s3 && s2_can_go_to_mq && s2_can_go_to_mq_replay);
    chk_tag_write_q       <= tag_write_valid && !tag_write_intend;
    chk_tag_write_repl_q  <= !tag_write_valid || !s3_req.replace;
    chk_data_write_repl_q <= !data_write_valid || !s3_req.replace;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      s0_fire_q_replway <= 1'b0;
    else
      s0_fire_q_replway <= s0_fire;
  end

  // 连续 SC 失败计数（地址命中保留集却仍失败的情况），只用于调试报警
  //   （golden 里另一个"SC 连续失败"计数器 debug_sc_fail_cnt 只喂 XSWarn，已被整个删掉）
  logic debug_s3_sc_fail_addr_match;
  assign debug_s3_sc_fail_addr_match = s3_sc && lrsc_addr == s3_block_addr && !lrsc_valid;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      debug_sc_fail_addr           <= '0;
      debug_sc_addr_match_fail_cnt <= 8'd0;
    end else if (s3_valid) begin
      if (s3_req.addr == debug_sc_fail_addr) begin
        if (debug_s3_sc_fail_addr_match)
          debug_sc_addr_match_fail_cnt <= debug_sc_addr_match_fail_cnt + 8'd1;
        else if (s3_sc)
          debug_sc_addr_match_fail_cnt <= 8'd0;
      end else if (s3_sc_fail) begin
        debug_sc_fail_addr           <= s3_req.addr;
        debug_sc_addr_match_fail_cnt <= 8'd1;
      end
    end
  end

`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (!reset) begin
      if (chk_multi_way_q)
        $error("MainPipe: s1_way_en 不是独热");
      if (!chk_s2_exclusive_q)
        $error("MainPipe: s2 同时满足去 s3 / 去 MissQueue / 回 MissQueue");
      if (chk_tag_write_q)
        $error("MainPipe: tag_write.valid 但没有 tag_write_intend");
      if (!chk_tag_write_repl_q || !chk_data_write_repl_q)
        $error("MainPipe: replace 请求不该写 tag/data");
      if (s2_valid && s2_grow_perm && &btot_ways_for_set)
        $error("MainPipe: BtoT 升权但该 set 所有路都在 BtoT");
      if (s2_fire_to_s3 && s2_req.miss && !refill_info_valid)
        $error("MainPipe: refill 进 s3 却没有回填数据");
      if (debug_sc_addr_match_fail_cnt > 8'd100)
        $error("MainPipe: SC 连续失败过多（保留集地址一直匹配）");
      if (s3_valid && |banked_wmask && !update_data)
        $error("MainPipe: 有写掩码却不写数据");
      if (s2_valid && &s2_way_en)
        $error("MainPipe: s2_way_en 全 1");
    end
  end
`endif

endmodule

// =====================================================================
// golden 同名 wrapper —— 由 verif/ut/MainPipe/gen_mainpipe.py 生成，改请改生成器
// =====================================================================
// BEGIN GENERATED(wrapper)
// golden 同名 wrapper：端口与 G1 golden 逐位同名同序；函数上只做扁平端口 <-> struct
// 的接线（字段路径换算规则见 verif/ut/MainPipe/gen_mainpipe.py），逻辑全在核里。
module MainPipe
  import mainpipe_pkg::*;
(
  input          clock,
  input          reset,
  output         io_probe_req_ready,
  input          io_probe_req_valid,
  input  [1:0]   io_probe_req_bits_probe_param,
  input          io_probe_req_bits_probe_need_data,
  input  [49:0]  io_probe_req_bits_vaddr,
  input  [47:0]  io_probe_req_bits_addr,
  input  [5:0]   io_probe_req_bits_id,
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
  output         io_refill_req_ready,
  input          io_refill_req_valid,
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
  output         io_wbq_conflict_check_valid,
  output [47:0]  io_wbq_conflict_check_bits,
  input          io_wbq_block_miss_req,
  output         io_store_req_ready,
  input          io_store_req_valid,
  input  [49:0]  io_store_req_bits_vaddr,
  input  [47:0]  io_store_req_bits_addr,
  input  [511:0] io_store_req_bits_data,
  input  [63:0]  io_store_req_bits_mask,
  input  [5:0]   io_store_req_bits_id,
  output         io_store_replay_resp_valid,
  output [5:0]   io_store_replay_resp_bits_id,
  output         io_store_hit_resp_valid,
  output [5:0]   io_store_hit_resp_bits_id,
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
  output         io_atomic_resp_bits_tl_error_tl_denied,
  output         io_atomic_resp_bits_tl_error_tl_corrupt,
  output         io_atomic_resp_bits_ack_miss_queue,
  output [5:0]   io_atomic_resp_bits_id,
  output         io_mainpipe_info_s2_valid,
  output [3:0]   io_mainpipe_info_s2_miss_id,
  output         io_mainpipe_info_s2_replay_to_mq,
  output         io_mainpipe_info_s2_evict_BtoT_way,
  output [3:0]   io_mainpipe_info_s2_next_evict_way,
  output         io_mainpipe_info_s3_valid,
  output [3:0]   io_mainpipe_info_s3_miss_id,
  output         io_mainpipe_info_s3_refill_resp,
  input          io_refill_info_valid,
  input  [511:0] io_refill_info_bits_store_data,
  input  [63:0]  io_refill_info_bits_store_mask,
  input  [1:0]   io_refill_info_bits_miss_param,
  input          io_refill_info_bits_error_tl_denied,
  input          io_refill_info_bits_error_tl_corrupt,
  input          io_wb_ready,
  output         io_wb_valid,
  output [2:0]   io_wb_bits_param,
  output         io_wb_bits_voluntary,
  output         io_wb_bits_hasData,
  output         io_wb_bits_corrupt,
  output         io_wb_bits_dirty,
  output [47:0]  io_wb_bits_addr,
  output [511:0] io_wb_bits_data,
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
  input          io_readline_error_delayed,
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
  input          io_extra_meta_resp_0_error_tl_denied,
  input          io_extra_meta_resp_0_error_tl_corrupt,
  input  [2:0]   io_extra_meta_resp_0_prefetch,
  input          io_extra_meta_resp_0_access,
  input          io_extra_meta_resp_1_error_tl_denied,
  input          io_extra_meta_resp_1_error_tl_corrupt,
  input  [2:0]   io_extra_meta_resp_1_prefetch,
  input          io_extra_meta_resp_1_access,
  input          io_extra_meta_resp_2_error_tl_denied,
  input          io_extra_meta_resp_2_error_tl_corrupt,
  input  [2:0]   io_extra_meta_resp_2_prefetch,
  input          io_extra_meta_resp_2_access,
  input          io_extra_meta_resp_3_error_tl_denied,
  input          io_extra_meta_resp_3_error_tl_corrupt,
  input  [2:0]   io_extra_meta_resp_3_prefetch,
  input          io_extra_meta_resp_3_access,
  output         io_error_flag_write_valid,
  output [7:0]   io_error_flag_write_bits_idx,
  output [3:0]   io_error_flag_write_bits_way_en,
  output         io_error_flag_write_bits_error_tl_denied,
  output         io_error_flag_write_bits_error_tl_corrupt,
  output         io_prefetch_flag_write_valid,
  output [7:0]   io_prefetch_flag_write_bits_idx,
  output [3:0]   io_prefetch_flag_write_bits_way_en,
  output [2:0]   io_prefetch_flag_write_bits_source,
  output         io_access_flag_write_valid,
  output [7:0]   io_access_flag_write_bits_idx,
  output [3:0]   io_access_flag_write_bits_way_en,
  output         io_access_flag_write_bits_flag,
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
  output         io_replace_access_valid,
  output [7:0]   io_replace_access_bits_set,
  output [1:0]   io_replace_access_bits_way,
  output [7:0]   io_replace_way_set_bits,
  input  [1:0]   io_replace_way_way,
  output [7:0]   io_evict_set,
  input  [3:0]   io_btot_ways_for_set,
  output [47:0]  io_replace_req_bits_addr,
  output [49:0]  io_replace_req_bits_vaddr,
  input          io_replace_block,
  output         io_sms_agt_evict_req_valid,
  output [49:0]  io_sms_agt_evict_req_bits_vaddr,
  output         io_status_dup_0_s1_valid,
  output [7:0]   io_status_dup_0_s1_bits_set,
  output [3:0]   io_status_dup_0_s1_bits_way_en,
  output         io_status_dup_0_s2_valid,
  output [7:0]   io_status_dup_0_s2_bits_set,
  output [3:0]   io_status_dup_0_s2_bits_way_en,
  output         io_status_dup_0_s3_valid,
  output [7:0]   io_status_dup_0_s3_bits_set,
  output [3:0]   io_status_dup_0_s3_bits_way_en,
  output         io_status_dup_1_s1_valid,
  output [7:0]   io_status_dup_1_s1_bits_set,
  output [3:0]   io_status_dup_1_s1_bits_way_en,
  output         io_status_dup_1_s2_valid,
  output [7:0]   io_status_dup_1_s2_bits_set,
  output [3:0]   io_status_dup_1_s2_bits_way_en,
  output         io_status_dup_1_s3_valid,
  output [7:0]   io_status_dup_1_s3_bits_set,
  output [3:0]   io_status_dup_1_s3_bits_way_en,
  output         io_status_dup_2_s1_valid,
  output [7:0]   io_status_dup_2_s1_bits_set,
  output [3:0]   io_status_dup_2_s1_bits_way_en,
  output         io_status_dup_2_s2_valid,
  output [7:0]   io_status_dup_2_s2_bits_set,
  output [3:0]   io_status_dup_2_s2_bits_way_en,
  output         io_status_dup_2_s3_valid,
  output [7:0]   io_status_dup_2_s3_bits_set,
  output [3:0]   io_status_dup_2_s3_bits_way_en,
  output         io_status_dup_3_s1_valid,
  output [7:0]   io_status_dup_3_s1_bits_set,
  output [3:0]   io_status_dup_3_s1_bits_way_en,
  output         io_status_dup_3_s2_valid,
  output [7:0]   io_status_dup_3_s2_bits_set,
  output [3:0]   io_status_dup_3_s2_bits_way_en,
  output         io_status_dup_3_s3_valid,
  output [7:0]   io_status_dup_3_s3_bits_set,
  output [3:0]   io_status_dup_3_s3_bits_way_en,
  output         io_status_dup_4_s1_valid,
  output [7:0]   io_status_dup_4_s1_bits_set,
  output [3:0]   io_status_dup_4_s1_bits_way_en,
  output         io_status_dup_4_s2_valid,
  output [7:0]   io_status_dup_4_s2_bits_set,
  output [3:0]   io_status_dup_4_s2_bits_way_en,
  output         io_status_dup_4_s3_valid,
  output [7:0]   io_status_dup_4_s3_bits_set,
  output [3:0]   io_status_dup_4_s3_bits_way_en,
  output         io_status_dup_5_s1_valid,
  output [7:0]   io_status_dup_5_s1_bits_set,
  output [3:0]   io_status_dup_5_s1_bits_way_en,
  output         io_status_dup_5_s2_valid,
  output [7:0]   io_status_dup_5_s2_bits_set,
  output [3:0]   io_status_dup_5_s2_bits_way_en,
  output         io_status_dup_5_s3_valid,
  output [7:0]   io_status_dup_5_s3_bits_set,
  output [3:0]   io_status_dup_5_s3_bits_way_en,
  output         io_status_dup_6_s1_valid,
  output [7:0]   io_status_dup_6_s1_bits_set,
  output [3:0]   io_status_dup_6_s1_bits_way_en,
  output         io_status_dup_6_s2_valid,
  output [7:0]   io_status_dup_6_s2_bits_set,
  output [3:0]   io_status_dup_6_s2_bits_way_en,
  output         io_status_dup_6_s3_valid,
  output [7:0]   io_status_dup_6_s3_bits_set,
  output [3:0]   io_status_dup_6_s3_bits_way_en,
  output         io_status_dup_7_s1_valid,
  output [7:0]   io_status_dup_7_s1_bits_set,
  output [3:0]   io_status_dup_7_s1_bits_way_en,
  output         io_status_dup_7_s2_valid,
  output [7:0]   io_status_dup_7_s2_bits_set,
  output [3:0]   io_status_dup_7_s2_bits_way_en,
  output         io_status_dup_7_s3_valid,
  output [7:0]   io_status_dup_7_s3_bits_set,
  output [3:0]   io_status_dup_7_s3_bits_way_en,
  output         io_status_dup_8_s1_valid,
  output [7:0]   io_status_dup_8_s1_bits_set,
  output [3:0]   io_status_dup_8_s1_bits_way_en,
  output         io_status_dup_8_s2_valid,
  output [7:0]   io_status_dup_8_s2_bits_set,
  output [3:0]   io_status_dup_8_s2_bits_way_en,
  output         io_status_dup_8_s3_valid,
  output [7:0]   io_status_dup_8_s3_bits_set,
  output [3:0]   io_status_dup_8_s3_bits_way_en,
  output         io_status_dup_9_s1_valid,
  output [7:0]   io_status_dup_9_s1_bits_set,
  output [3:0]   io_status_dup_9_s1_bits_way_en,
  output         io_status_dup_9_s2_valid,
  output [7:0]   io_status_dup_9_s2_bits_set,
  output [3:0]   io_status_dup_9_s2_bits_way_en,
  output         io_status_dup_9_s3_valid,
  output [7:0]   io_status_dup_9_s3_bits_set,
  output [3:0]   io_status_dup_9_s3_bits_way_en,
  output         io_status_dup_10_s1_valid,
  output [7:0]   io_status_dup_10_s1_bits_set,
  output [3:0]   io_status_dup_10_s1_bits_way_en,
  output         io_status_dup_10_s2_valid,
  output [7:0]   io_status_dup_10_s2_bits_set,
  output [3:0]   io_status_dup_10_s2_bits_way_en,
  output         io_status_dup_10_s3_valid,
  output [7:0]   io_status_dup_10_s3_bits_set,
  output [3:0]   io_status_dup_10_s3_bits_way_en,
  output         io_status_dup_11_s1_valid,
  output [7:0]   io_status_dup_11_s1_bits_set,
  output [3:0]   io_status_dup_11_s1_bits_way_en,
  output         io_status_dup_11_s2_valid,
  output [7:0]   io_status_dup_11_s2_bits_set,
  output [3:0]   io_status_dup_11_s2_bits_way_en,
  output         io_status_dup_11_s3_valid,
  output [7:0]   io_status_dup_11_s3_bits_set,
  output [3:0]   io_status_dup_11_s3_bits_way_en,
  output         io_status_dup_12_s1_valid,
  output [7:0]   io_status_dup_12_s1_bits_set,
  output [3:0]   io_status_dup_12_s1_bits_way_en,
  output         io_status_dup_12_s2_valid,
  output [7:0]   io_status_dup_12_s2_bits_set,
  output [3:0]   io_status_dup_12_s2_bits_way_en,
  output         io_status_dup_12_s3_valid,
  output [7:0]   io_status_dup_12_s3_bits_set,
  output [3:0]   io_status_dup_12_s3_bits_way_en,
  output         io_status_dup_13_s1_valid,
  output [7:0]   io_status_dup_13_s1_bits_set,
  output [3:0]   io_status_dup_13_s1_bits_way_en,
  output         io_status_dup_13_s2_valid,
  output [7:0]   io_status_dup_13_s2_bits_set,
  output [3:0]   io_status_dup_13_s2_bits_way_en,
  output         io_status_dup_13_s3_valid,
  output [7:0]   io_status_dup_13_s3_bits_set,
  output [3:0]   io_status_dup_13_s3_bits_way_en,
  output         io_status_dup_14_s1_valid,
  output [7:0]   io_status_dup_14_s1_bits_set,
  output [3:0]   io_status_dup_14_s1_bits_way_en,
  output         io_status_dup_14_s2_valid,
  output [7:0]   io_status_dup_14_s2_bits_set,
  output [3:0]   io_status_dup_14_s2_bits_way_en,
  output         io_status_dup_14_s3_valid,
  output [7:0]   io_status_dup_14_s3_bits_set,
  output [3:0]   io_status_dup_14_s3_bits_way_en,
  output         io_status_dup_15_s1_valid,
  output [7:0]   io_status_dup_15_s1_bits_set,
  output [3:0]   io_status_dup_15_s1_bits_way_en,
  output         io_status_dup_15_s2_valid,
  output [7:0]   io_status_dup_15_s2_bits_set,
  output [3:0]   io_status_dup_15_s2_bits_way_en,
  output         io_status_dup_15_s3_valid,
  output [7:0]   io_status_dup_15_s3_bits_set,
  output [3:0]   io_status_dup_15_s3_bits_way_en,
  output         io_status_dup_16_s1_valid,
  output [7:0]   io_status_dup_16_s1_bits_set,
  output [3:0]   io_status_dup_16_s1_bits_way_en,
  output         io_status_dup_16_s2_valid,
  output [7:0]   io_status_dup_16_s2_bits_set,
  output [3:0]   io_status_dup_16_s2_bits_way_en,
  output         io_status_dup_16_s3_valid,
  output [7:0]   io_status_dup_16_s3_bits_set,
  output [3:0]   io_status_dup_16_s3_bits_way_en,
  output         io_status_dup_17_s1_valid,
  output [7:0]   io_status_dup_17_s1_bits_set,
  output [3:0]   io_status_dup_17_s1_bits_way_en,
  output         io_status_dup_17_s2_valid,
  output [7:0]   io_status_dup_17_s2_bits_set,
  output [3:0]   io_status_dup_17_s2_bits_way_en,
  output         io_status_dup_17_s3_valid,
  output [7:0]   io_status_dup_17_s3_bits_set,
  output [3:0]   io_status_dup_17_s3_bits_way_en,
  output         io_status_dup_18_s1_valid,
  output [7:0]   io_status_dup_18_s1_bits_set,
  output [3:0]   io_status_dup_18_s1_bits_way_en,
  output         io_status_dup_18_s2_valid,
  output [7:0]   io_status_dup_18_s2_bits_set,
  output [3:0]   io_status_dup_18_s2_bits_way_en,
  output         io_status_dup_18_s3_valid,
  output [7:0]   io_status_dup_18_s3_bits_set,
  output [3:0]   io_status_dup_18_s3_bits_way_en,
  output         io_status_dup_19_s1_valid,
  output [7:0]   io_status_dup_19_s1_bits_set,
  output [3:0]   io_status_dup_19_s1_bits_way_en,
  output         io_status_dup_19_s2_valid,
  output [7:0]   io_status_dup_19_s2_bits_set,
  output [3:0]   io_status_dup_19_s2_bits_way_en,
  output         io_status_dup_19_s3_valid,
  output [7:0]   io_status_dup_19_s3_bits_set,
  output [3:0]   io_status_dup_19_s3_bits_way_en,
  output         io_status_dup_20_s1_valid,
  output [7:0]   io_status_dup_20_s1_bits_set,
  output [3:0]   io_status_dup_20_s1_bits_way_en,
  output         io_status_dup_20_s2_valid,
  output [7:0]   io_status_dup_20_s2_bits_set,
  output [3:0]   io_status_dup_20_s2_bits_way_en,
  output         io_status_dup_20_s3_valid,
  output [7:0]   io_status_dup_20_s3_bits_set,
  output [3:0]   io_status_dup_20_s3_bits_way_en,
  output         io_status_dup_21_s1_valid,
  output [7:0]   io_status_dup_21_s1_bits_set,
  output [3:0]   io_status_dup_21_s1_bits_way_en,
  output         io_status_dup_21_s2_valid,
  output [7:0]   io_status_dup_21_s2_bits_set,
  output [3:0]   io_status_dup_21_s2_bits_way_en,
  output         io_status_dup_21_s3_valid,
  output [7:0]   io_status_dup_21_s3_bits_set,
  output [3:0]   io_status_dup_21_s3_bits_way_en,
  output         io_status_dup_22_s1_valid,
  output [7:0]   io_status_dup_22_s1_bits_set,
  output [3:0]   io_status_dup_22_s1_bits_way_en,
  output         io_status_dup_22_s2_valid,
  output [7:0]   io_status_dup_22_s2_bits_set,
  output [3:0]   io_status_dup_22_s2_bits_way_en,
  output         io_status_dup_22_s3_valid,
  output [7:0]   io_status_dup_22_s3_bits_set,
  output [3:0]   io_status_dup_22_s3_bits_way_en,
  output         io_status_dup_23_s1_valid,
  output [7:0]   io_status_dup_23_s1_bits_set,
  output [3:0]   io_status_dup_23_s1_bits_way_en,
  output         io_status_dup_23_s2_valid,
  output [7:0]   io_status_dup_23_s2_bits_set,
  output [3:0]   io_status_dup_23_s2_bits_way_en,
  output         io_status_dup_23_s3_valid,
  output [7:0]   io_status_dup_23_s3_bits_set,
  output [3:0]   io_status_dup_23_s3_bits_way_en,
  output         io_lrsc_locked_block_valid,
  output [47:0]  io_lrsc_locked_block_bits,
  input          io_invalid_resv_set,
  output         io_update_resv_set,
  output         io_block_lr,
  output         io_error_valid,
  output [47:0]  io_error_bits_paddr,
  output         io_error_bits_report_to_beu,
  input          io_pseudo_error_valid,
  input          io_pseudo_error_bits_0_valid,
  input  [63:0]  io_pseudo_error_bits_0_mask,
  output         io_pseudo_tag_error_inj_done,
  output         io_pseudo_data_error_inj_done,
  output         io_bloom_filter_query_set_valid,
  output [11:0]  io_bloom_filter_query_set_bits_addr,
  output         io_bloom_filter_query_clr_valid,
  output [11:0]  io_bloom_filter_query_clr_bits_addr,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [5:0]   io_perf_2_value,
  output [5:0]   io_perf_3_value
);

  probe_req_bits_t c_probe_req_bits;
  refill_req_bits_t c_refill_req_bits;
  store_req_bits_t c_store_req_bits;
  atomic_req_bits_t c_atomic_req_bits;
  miss_req_bits_t c_miss_req_bits;
  atomic_resp_bits_t c_atomic_resp_bits;
  mainpipe_info_t c_mainpipe_info;
  refill_info_bits_t c_refill_info_bits;
  wb_bits_t c_wb_bits;
  readline_bits_t c_data_readline_bits;
  data_resp_t [7:0] c_data_resp;
  data_write_bits_t c_data_write_bits;
  data_write_dup_t [7:0] c_data_write_dup;
  meta_t [3:0] c_meta_resp;
  meta_write_bits_t c_meta_write_bits;
  extra_meta_t [3:0] c_extra_meta_resp;
  error_flag_write_bits_t c_error_flag_write_bits;
  prefetch_flag_write_bits_t c_prefetch_flag_write_bits;
  access_flag_write_bits_t c_access_flag_write_bits;
  logic [3:0][42:0] c_tag_resp;
  tag_write_bits_t c_tag_write_bits;
  replace_access_bits_t c_replace_access_bits;
  replace_req_bits_t c_replace_req_bits;
  status_dup_t [23:0] c_status_dup;
  error_bits_t c_error_bits;
  bloom_filter_query_t c_bloom_filter_query;
  perf_event_t [3:0] c_perf;

  assign c_probe_req_bits.probe_param = io_probe_req_bits_probe_param;
  assign c_probe_req_bits.probe_need_data = io_probe_req_bits_probe_need_data;
  assign c_probe_req_bits.vaddr = io_probe_req_bits_vaddr;
  assign c_probe_req_bits.addr = io_probe_req_bits_addr;
  assign c_probe_req_bits.id = io_probe_req_bits_id;
  assign c_refill_req_bits.miss_id = io_refill_req_bits_miss_id;
  assign c_refill_req_bits.occupy_way = io_refill_req_bits_occupy_way;
  assign c_refill_req_bits.miss_fail_cause_evict_btot = io_refill_req_bits_miss_fail_cause_evict_btot;
  assign c_refill_req_bits.source = io_refill_req_bits_source;
  assign c_refill_req_bits.cmd = io_refill_req_bits_cmd;
  assign c_refill_req_bits.vaddr = io_refill_req_bits_vaddr;
  assign c_refill_req_bits.addr = io_refill_req_bits_addr;
  assign c_refill_req_bits.word_idx = io_refill_req_bits_word_idx;
  assign c_refill_req_bits.amo_data = io_refill_req_bits_amo_data;
  assign c_refill_req_bits.amo_mask = io_refill_req_bits_amo_mask;
  assign c_refill_req_bits.amo_cmp = io_refill_req_bits_amo_cmp;
  assign c_refill_req_bits.pf_source = io_refill_req_bits_pf_source;
  assign c_refill_req_bits.access = io_refill_req_bits_access;
  assign c_refill_req_bits.id = io_refill_req_bits_id;
  assign c_store_req_bits.vaddr = io_store_req_bits_vaddr;
  assign c_store_req_bits.addr = io_store_req_bits_addr;
  assign c_store_req_bits.data = io_store_req_bits_data;
  assign c_store_req_bits.mask = io_store_req_bits_mask;
  assign c_store_req_bits.id = io_store_req_bits_id;
  assign c_atomic_req_bits.cmd = io_atomic_req_bits_cmd;
  assign c_atomic_req_bits.vaddr = io_atomic_req_bits_vaddr;
  assign c_atomic_req_bits.addr = io_atomic_req_bits_addr;
  assign c_atomic_req_bits.word_idx = io_atomic_req_bits_word_idx;
  assign c_atomic_req_bits.amo_data = io_atomic_req_bits_amo_data;
  assign c_atomic_req_bits.amo_mask = io_atomic_req_bits_amo_mask;
  assign c_atomic_req_bits.amo_cmp = io_atomic_req_bits_amo_cmp;
  assign io_miss_req_bits_source = c_miss_req_bits.source;
  assign io_miss_req_bits_cmd = c_miss_req_bits.cmd;
  assign io_miss_req_bits_addr = c_miss_req_bits.addr;
  assign io_miss_req_bits_vaddr = c_miss_req_bits.vaddr;
  assign io_miss_req_bits_full_overwrite = c_miss_req_bits.full_overwrite;
  assign io_miss_req_bits_word_idx = c_miss_req_bits.word_idx;
  assign io_miss_req_bits_amo_data = c_miss_req_bits.amo_data;
  assign io_miss_req_bits_amo_mask = c_miss_req_bits.amo_mask;
  assign io_miss_req_bits_amo_cmp = c_miss_req_bits.amo_cmp;
  assign io_miss_req_bits_req_coh_state = c_miss_req_bits.req_coh_state;
  assign io_miss_req_bits_id = c_miss_req_bits.id;
  assign io_miss_req_bits_isBtoT = c_miss_req_bits.isBtoT;
  assign io_miss_req_bits_occupy_way = c_miss_req_bits.occupy_way;
  assign io_miss_req_bits_cancel = c_miss_req_bits.cancel;
  assign io_miss_req_bits_store_data = c_miss_req_bits.store_data;
  assign io_miss_req_bits_store_mask = c_miss_req_bits.store_mask;
  assign io_atomic_resp_bits_source = c_atomic_resp_bits.source;
  assign io_atomic_resp_bits_data = c_atomic_resp_bits.data;
  assign io_atomic_resp_bits_miss = c_atomic_resp_bits.miss;
  assign io_atomic_resp_bits_miss_id = c_atomic_resp_bits.miss_id;
  assign io_atomic_resp_bits_replay = c_atomic_resp_bits.replay;
  assign io_atomic_resp_bits_tl_error_tl_denied = c_atomic_resp_bits.tl_error.tl_denied;
  assign io_atomic_resp_bits_tl_error_tl_corrupt = c_atomic_resp_bits.tl_error.tl_corrupt;
  assign io_atomic_resp_bits_ack_miss_queue = c_atomic_resp_bits.ack_miss_queue;
  assign io_atomic_resp_bits_id = c_atomic_resp_bits.id;
  assign io_mainpipe_info_s2_valid = c_mainpipe_info.s2_valid;
  assign io_mainpipe_info_s2_miss_id = c_mainpipe_info.s2_miss_id;
  assign io_mainpipe_info_s2_replay_to_mq = c_mainpipe_info.s2_replay_to_mq;
  assign io_mainpipe_info_s2_evict_BtoT_way = c_mainpipe_info.s2_evict_BtoT_way;
  assign io_mainpipe_info_s2_next_evict_way = c_mainpipe_info.s2_next_evict_way;
  assign io_mainpipe_info_s3_valid = c_mainpipe_info.s3_valid;
  assign io_mainpipe_info_s3_miss_id = c_mainpipe_info.s3_miss_id;
  assign io_mainpipe_info_s3_refill_resp = c_mainpipe_info.s3_refill_resp;
  assign c_refill_info_bits.store_data = io_refill_info_bits_store_data;
  assign c_refill_info_bits.store_mask = io_refill_info_bits_store_mask;
  assign c_refill_info_bits.miss_param = io_refill_info_bits_miss_param;
  assign c_refill_info_bits.error.tl_denied = io_refill_info_bits_error_tl_denied;
  assign c_refill_info_bits.error.tl_corrupt = io_refill_info_bits_error_tl_corrupt;
  assign io_wb_bits_param = c_wb_bits.param;
  assign io_wb_bits_voluntary = c_wb_bits.voluntary;
  assign io_wb_bits_hasData = c_wb_bits.hasData;
  assign io_wb_bits_corrupt = c_wb_bits.corrupt;
  assign io_wb_bits_dirty = c_wb_bits.dirty;
  assign io_wb_bits_addr = c_wb_bits.addr;
  assign io_wb_bits_data = c_wb_bits.data;
  assign io_data_readline_bits_way_en = c_data_readline_bits.way_en;
  assign io_data_readline_bits_addr = c_data_readline_bits.addr;
  assign io_data_readline_bits_rmask = c_data_readline_bits.rmask;
  assign c_data_resp[0].raw_data = io_data_resp_0_raw_data;
  assign c_data_resp[1].raw_data = io_data_resp_1_raw_data;
  assign c_data_resp[2].raw_data = io_data_resp_2_raw_data;
  assign c_data_resp[3].raw_data = io_data_resp_3_raw_data;
  assign c_data_resp[4].raw_data = io_data_resp_4_raw_data;
  assign c_data_resp[5].raw_data = io_data_resp_5_raw_data;
  assign c_data_resp[6].raw_data = io_data_resp_6_raw_data;
  assign c_data_resp[7].raw_data = io_data_resp_7_raw_data;
  assign io_data_write_bits_wmask = c_data_write_bits.wmask;
  assign io_data_write_bits_data_0 = c_data_write_bits.data[0];
  assign io_data_write_bits_data_1 = c_data_write_bits.data[1];
  assign io_data_write_bits_data_2 = c_data_write_bits.data[2];
  assign io_data_write_bits_data_3 = c_data_write_bits.data[3];
  assign io_data_write_bits_data_4 = c_data_write_bits.data[4];
  assign io_data_write_bits_data_5 = c_data_write_bits.data[5];
  assign io_data_write_bits_data_6 = c_data_write_bits.data[6];
  assign io_data_write_bits_data_7 = c_data_write_bits.data[7];
  assign io_data_write_dup_0_valid = c_data_write_dup[0].valid;
  assign io_data_write_dup_0_bits_way_en = c_data_write_dup[0].bits.way_en;
  assign io_data_write_dup_0_bits_addr = c_data_write_dup[0].bits.addr;
  assign io_data_write_dup_1_valid = c_data_write_dup[1].valid;
  assign io_data_write_dup_1_bits_way_en = c_data_write_dup[1].bits.way_en;
  assign io_data_write_dup_1_bits_addr = c_data_write_dup[1].bits.addr;
  assign io_data_write_dup_2_valid = c_data_write_dup[2].valid;
  assign io_data_write_dup_2_bits_way_en = c_data_write_dup[2].bits.way_en;
  assign io_data_write_dup_2_bits_addr = c_data_write_dup[2].bits.addr;
  assign io_data_write_dup_3_valid = c_data_write_dup[3].valid;
  assign io_data_write_dup_3_bits_way_en = c_data_write_dup[3].bits.way_en;
  assign io_data_write_dup_3_bits_addr = c_data_write_dup[3].bits.addr;
  assign io_data_write_dup_4_valid = c_data_write_dup[4].valid;
  assign io_data_write_dup_4_bits_way_en = c_data_write_dup[4].bits.way_en;
  assign io_data_write_dup_4_bits_addr = c_data_write_dup[4].bits.addr;
  assign io_data_write_dup_5_valid = c_data_write_dup[5].valid;
  assign io_data_write_dup_5_bits_way_en = c_data_write_dup[5].bits.way_en;
  assign io_data_write_dup_5_bits_addr = c_data_write_dup[5].bits.addr;
  assign io_data_write_dup_6_valid = c_data_write_dup[6].valid;
  assign io_data_write_dup_6_bits_way_en = c_data_write_dup[6].bits.way_en;
  assign io_data_write_dup_6_bits_addr = c_data_write_dup[6].bits.addr;
  assign io_data_write_dup_7_valid = c_data_write_dup[7].valid;
  assign io_data_write_dup_7_bits_way_en = c_data_write_dup[7].bits.way_en;
  assign io_data_write_dup_7_bits_addr = c_data_write_dup[7].bits.addr;
  assign c_meta_resp[0].coh_state = io_meta_resp_0_coh_state;
  assign c_meta_resp[1].coh_state = io_meta_resp_1_coh_state;
  assign c_meta_resp[2].coh_state = io_meta_resp_2_coh_state;
  assign c_meta_resp[3].coh_state = io_meta_resp_3_coh_state;
  assign io_meta_write_bits_idx = c_meta_write_bits.idx;
  assign io_meta_write_bits_way_en = c_meta_write_bits.way_en;
  assign io_meta_write_bits_meta_coh_state = c_meta_write_bits.meta_coh_state;
  assign c_extra_meta_resp[0].error.tl_denied = io_extra_meta_resp_0_error_tl_denied;
  assign c_extra_meta_resp[0].error.tl_corrupt = io_extra_meta_resp_0_error_tl_corrupt;
  assign c_extra_meta_resp[0].prefetch = io_extra_meta_resp_0_prefetch;
  assign c_extra_meta_resp[0].access = io_extra_meta_resp_0_access;
  assign c_extra_meta_resp[1].error.tl_denied = io_extra_meta_resp_1_error_tl_denied;
  assign c_extra_meta_resp[1].error.tl_corrupt = io_extra_meta_resp_1_error_tl_corrupt;
  assign c_extra_meta_resp[1].prefetch = io_extra_meta_resp_1_prefetch;
  assign c_extra_meta_resp[1].access = io_extra_meta_resp_1_access;
  assign c_extra_meta_resp[2].error.tl_denied = io_extra_meta_resp_2_error_tl_denied;
  assign c_extra_meta_resp[2].error.tl_corrupt = io_extra_meta_resp_2_error_tl_corrupt;
  assign c_extra_meta_resp[2].prefetch = io_extra_meta_resp_2_prefetch;
  assign c_extra_meta_resp[2].access = io_extra_meta_resp_2_access;
  assign c_extra_meta_resp[3].error.tl_denied = io_extra_meta_resp_3_error_tl_denied;
  assign c_extra_meta_resp[3].error.tl_corrupt = io_extra_meta_resp_3_error_tl_corrupt;
  assign c_extra_meta_resp[3].prefetch = io_extra_meta_resp_3_prefetch;
  assign c_extra_meta_resp[3].access = io_extra_meta_resp_3_access;
  assign io_error_flag_write_bits_idx = c_error_flag_write_bits.idx;
  assign io_error_flag_write_bits_way_en = c_error_flag_write_bits.way_en;
  assign io_error_flag_write_bits_error_tl_denied = c_error_flag_write_bits.error.tl_denied;
  assign io_error_flag_write_bits_error_tl_corrupt = c_error_flag_write_bits.error.tl_corrupt;
  assign io_prefetch_flag_write_bits_idx = c_prefetch_flag_write_bits.idx;
  assign io_prefetch_flag_write_bits_way_en = c_prefetch_flag_write_bits.way_en;
  assign io_prefetch_flag_write_bits_source = c_prefetch_flag_write_bits.source;
  assign io_access_flag_write_bits_idx = c_access_flag_write_bits.idx;
  assign io_access_flag_write_bits_way_en = c_access_flag_write_bits.way_en;
  assign io_access_flag_write_bits_flag = c_access_flag_write_bits.flag;
  assign c_tag_resp[0] = io_tag_resp_0;
  assign c_tag_resp[1] = io_tag_resp_1;
  assign c_tag_resp[2] = io_tag_resp_2;
  assign c_tag_resp[3] = io_tag_resp_3;
  assign io_tag_write_bits_idx = c_tag_write_bits.idx;
  assign io_tag_write_bits_way_en = c_tag_write_bits.way_en;
  assign io_tag_write_bits_tag = c_tag_write_bits.tag;
  assign io_replace_access_bits_set = c_replace_access_bits.set;
  assign io_replace_access_bits_way = c_replace_access_bits.way;
  assign io_replace_req_bits_addr = c_replace_req_bits.addr;
  assign io_replace_req_bits_vaddr = c_replace_req_bits.vaddr;
  assign io_status_dup_0_s1_valid = c_status_dup[0].s1.valid;
  assign io_status_dup_0_s1_bits_set = c_status_dup[0].s1.bits.set;
  assign io_status_dup_0_s1_bits_way_en = c_status_dup[0].s1.bits.way_en;
  assign io_status_dup_0_s2_valid = c_status_dup[0].s2.valid;
  assign io_status_dup_0_s2_bits_set = c_status_dup[0].s2.bits.set;
  assign io_status_dup_0_s2_bits_way_en = c_status_dup[0].s2.bits.way_en;
  assign io_status_dup_0_s3_valid = c_status_dup[0].s3.valid;
  assign io_status_dup_0_s3_bits_set = c_status_dup[0].s3.bits.set;
  assign io_status_dup_0_s3_bits_way_en = c_status_dup[0].s3.bits.way_en;
  assign io_status_dup_1_s1_valid = c_status_dup[1].s1.valid;
  assign io_status_dup_1_s1_bits_set = c_status_dup[1].s1.bits.set;
  assign io_status_dup_1_s1_bits_way_en = c_status_dup[1].s1.bits.way_en;
  assign io_status_dup_1_s2_valid = c_status_dup[1].s2.valid;
  assign io_status_dup_1_s2_bits_set = c_status_dup[1].s2.bits.set;
  assign io_status_dup_1_s2_bits_way_en = c_status_dup[1].s2.bits.way_en;
  assign io_status_dup_1_s3_valid = c_status_dup[1].s3.valid;
  assign io_status_dup_1_s3_bits_set = c_status_dup[1].s3.bits.set;
  assign io_status_dup_1_s3_bits_way_en = c_status_dup[1].s3.bits.way_en;
  assign io_status_dup_2_s1_valid = c_status_dup[2].s1.valid;
  assign io_status_dup_2_s1_bits_set = c_status_dup[2].s1.bits.set;
  assign io_status_dup_2_s1_bits_way_en = c_status_dup[2].s1.bits.way_en;
  assign io_status_dup_2_s2_valid = c_status_dup[2].s2.valid;
  assign io_status_dup_2_s2_bits_set = c_status_dup[2].s2.bits.set;
  assign io_status_dup_2_s2_bits_way_en = c_status_dup[2].s2.bits.way_en;
  assign io_status_dup_2_s3_valid = c_status_dup[2].s3.valid;
  assign io_status_dup_2_s3_bits_set = c_status_dup[2].s3.bits.set;
  assign io_status_dup_2_s3_bits_way_en = c_status_dup[2].s3.bits.way_en;
  assign io_status_dup_3_s1_valid = c_status_dup[3].s1.valid;
  assign io_status_dup_3_s1_bits_set = c_status_dup[3].s1.bits.set;
  assign io_status_dup_3_s1_bits_way_en = c_status_dup[3].s1.bits.way_en;
  assign io_status_dup_3_s2_valid = c_status_dup[3].s2.valid;
  assign io_status_dup_3_s2_bits_set = c_status_dup[3].s2.bits.set;
  assign io_status_dup_3_s2_bits_way_en = c_status_dup[3].s2.bits.way_en;
  assign io_status_dup_3_s3_valid = c_status_dup[3].s3.valid;
  assign io_status_dup_3_s3_bits_set = c_status_dup[3].s3.bits.set;
  assign io_status_dup_3_s3_bits_way_en = c_status_dup[3].s3.bits.way_en;
  assign io_status_dup_4_s1_valid = c_status_dup[4].s1.valid;
  assign io_status_dup_4_s1_bits_set = c_status_dup[4].s1.bits.set;
  assign io_status_dup_4_s1_bits_way_en = c_status_dup[4].s1.bits.way_en;
  assign io_status_dup_4_s2_valid = c_status_dup[4].s2.valid;
  assign io_status_dup_4_s2_bits_set = c_status_dup[4].s2.bits.set;
  assign io_status_dup_4_s2_bits_way_en = c_status_dup[4].s2.bits.way_en;
  assign io_status_dup_4_s3_valid = c_status_dup[4].s3.valid;
  assign io_status_dup_4_s3_bits_set = c_status_dup[4].s3.bits.set;
  assign io_status_dup_4_s3_bits_way_en = c_status_dup[4].s3.bits.way_en;
  assign io_status_dup_5_s1_valid = c_status_dup[5].s1.valid;
  assign io_status_dup_5_s1_bits_set = c_status_dup[5].s1.bits.set;
  assign io_status_dup_5_s1_bits_way_en = c_status_dup[5].s1.bits.way_en;
  assign io_status_dup_5_s2_valid = c_status_dup[5].s2.valid;
  assign io_status_dup_5_s2_bits_set = c_status_dup[5].s2.bits.set;
  assign io_status_dup_5_s2_bits_way_en = c_status_dup[5].s2.bits.way_en;
  assign io_status_dup_5_s3_valid = c_status_dup[5].s3.valid;
  assign io_status_dup_5_s3_bits_set = c_status_dup[5].s3.bits.set;
  assign io_status_dup_5_s3_bits_way_en = c_status_dup[5].s3.bits.way_en;
  assign io_status_dup_6_s1_valid = c_status_dup[6].s1.valid;
  assign io_status_dup_6_s1_bits_set = c_status_dup[6].s1.bits.set;
  assign io_status_dup_6_s1_bits_way_en = c_status_dup[6].s1.bits.way_en;
  assign io_status_dup_6_s2_valid = c_status_dup[6].s2.valid;
  assign io_status_dup_6_s2_bits_set = c_status_dup[6].s2.bits.set;
  assign io_status_dup_6_s2_bits_way_en = c_status_dup[6].s2.bits.way_en;
  assign io_status_dup_6_s3_valid = c_status_dup[6].s3.valid;
  assign io_status_dup_6_s3_bits_set = c_status_dup[6].s3.bits.set;
  assign io_status_dup_6_s3_bits_way_en = c_status_dup[6].s3.bits.way_en;
  assign io_status_dup_7_s1_valid = c_status_dup[7].s1.valid;
  assign io_status_dup_7_s1_bits_set = c_status_dup[7].s1.bits.set;
  assign io_status_dup_7_s1_bits_way_en = c_status_dup[7].s1.bits.way_en;
  assign io_status_dup_7_s2_valid = c_status_dup[7].s2.valid;
  assign io_status_dup_7_s2_bits_set = c_status_dup[7].s2.bits.set;
  assign io_status_dup_7_s2_bits_way_en = c_status_dup[7].s2.bits.way_en;
  assign io_status_dup_7_s3_valid = c_status_dup[7].s3.valid;
  assign io_status_dup_7_s3_bits_set = c_status_dup[7].s3.bits.set;
  assign io_status_dup_7_s3_bits_way_en = c_status_dup[7].s3.bits.way_en;
  assign io_status_dup_8_s1_valid = c_status_dup[8].s1.valid;
  assign io_status_dup_8_s1_bits_set = c_status_dup[8].s1.bits.set;
  assign io_status_dup_8_s1_bits_way_en = c_status_dup[8].s1.bits.way_en;
  assign io_status_dup_8_s2_valid = c_status_dup[8].s2.valid;
  assign io_status_dup_8_s2_bits_set = c_status_dup[8].s2.bits.set;
  assign io_status_dup_8_s2_bits_way_en = c_status_dup[8].s2.bits.way_en;
  assign io_status_dup_8_s3_valid = c_status_dup[8].s3.valid;
  assign io_status_dup_8_s3_bits_set = c_status_dup[8].s3.bits.set;
  assign io_status_dup_8_s3_bits_way_en = c_status_dup[8].s3.bits.way_en;
  assign io_status_dup_9_s1_valid = c_status_dup[9].s1.valid;
  assign io_status_dup_9_s1_bits_set = c_status_dup[9].s1.bits.set;
  assign io_status_dup_9_s1_bits_way_en = c_status_dup[9].s1.bits.way_en;
  assign io_status_dup_9_s2_valid = c_status_dup[9].s2.valid;
  assign io_status_dup_9_s2_bits_set = c_status_dup[9].s2.bits.set;
  assign io_status_dup_9_s2_bits_way_en = c_status_dup[9].s2.bits.way_en;
  assign io_status_dup_9_s3_valid = c_status_dup[9].s3.valid;
  assign io_status_dup_9_s3_bits_set = c_status_dup[9].s3.bits.set;
  assign io_status_dup_9_s3_bits_way_en = c_status_dup[9].s3.bits.way_en;
  assign io_status_dup_10_s1_valid = c_status_dup[10].s1.valid;
  assign io_status_dup_10_s1_bits_set = c_status_dup[10].s1.bits.set;
  assign io_status_dup_10_s1_bits_way_en = c_status_dup[10].s1.bits.way_en;
  assign io_status_dup_10_s2_valid = c_status_dup[10].s2.valid;
  assign io_status_dup_10_s2_bits_set = c_status_dup[10].s2.bits.set;
  assign io_status_dup_10_s2_bits_way_en = c_status_dup[10].s2.bits.way_en;
  assign io_status_dup_10_s3_valid = c_status_dup[10].s3.valid;
  assign io_status_dup_10_s3_bits_set = c_status_dup[10].s3.bits.set;
  assign io_status_dup_10_s3_bits_way_en = c_status_dup[10].s3.bits.way_en;
  assign io_status_dup_11_s1_valid = c_status_dup[11].s1.valid;
  assign io_status_dup_11_s1_bits_set = c_status_dup[11].s1.bits.set;
  assign io_status_dup_11_s1_bits_way_en = c_status_dup[11].s1.bits.way_en;
  assign io_status_dup_11_s2_valid = c_status_dup[11].s2.valid;
  assign io_status_dup_11_s2_bits_set = c_status_dup[11].s2.bits.set;
  assign io_status_dup_11_s2_bits_way_en = c_status_dup[11].s2.bits.way_en;
  assign io_status_dup_11_s3_valid = c_status_dup[11].s3.valid;
  assign io_status_dup_11_s3_bits_set = c_status_dup[11].s3.bits.set;
  assign io_status_dup_11_s3_bits_way_en = c_status_dup[11].s3.bits.way_en;
  assign io_status_dup_12_s1_valid = c_status_dup[12].s1.valid;
  assign io_status_dup_12_s1_bits_set = c_status_dup[12].s1.bits.set;
  assign io_status_dup_12_s1_bits_way_en = c_status_dup[12].s1.bits.way_en;
  assign io_status_dup_12_s2_valid = c_status_dup[12].s2.valid;
  assign io_status_dup_12_s2_bits_set = c_status_dup[12].s2.bits.set;
  assign io_status_dup_12_s2_bits_way_en = c_status_dup[12].s2.bits.way_en;
  assign io_status_dup_12_s3_valid = c_status_dup[12].s3.valid;
  assign io_status_dup_12_s3_bits_set = c_status_dup[12].s3.bits.set;
  assign io_status_dup_12_s3_bits_way_en = c_status_dup[12].s3.bits.way_en;
  assign io_status_dup_13_s1_valid = c_status_dup[13].s1.valid;
  assign io_status_dup_13_s1_bits_set = c_status_dup[13].s1.bits.set;
  assign io_status_dup_13_s1_bits_way_en = c_status_dup[13].s1.bits.way_en;
  assign io_status_dup_13_s2_valid = c_status_dup[13].s2.valid;
  assign io_status_dup_13_s2_bits_set = c_status_dup[13].s2.bits.set;
  assign io_status_dup_13_s2_bits_way_en = c_status_dup[13].s2.bits.way_en;
  assign io_status_dup_13_s3_valid = c_status_dup[13].s3.valid;
  assign io_status_dup_13_s3_bits_set = c_status_dup[13].s3.bits.set;
  assign io_status_dup_13_s3_bits_way_en = c_status_dup[13].s3.bits.way_en;
  assign io_status_dup_14_s1_valid = c_status_dup[14].s1.valid;
  assign io_status_dup_14_s1_bits_set = c_status_dup[14].s1.bits.set;
  assign io_status_dup_14_s1_bits_way_en = c_status_dup[14].s1.bits.way_en;
  assign io_status_dup_14_s2_valid = c_status_dup[14].s2.valid;
  assign io_status_dup_14_s2_bits_set = c_status_dup[14].s2.bits.set;
  assign io_status_dup_14_s2_bits_way_en = c_status_dup[14].s2.bits.way_en;
  assign io_status_dup_14_s3_valid = c_status_dup[14].s3.valid;
  assign io_status_dup_14_s3_bits_set = c_status_dup[14].s3.bits.set;
  assign io_status_dup_14_s3_bits_way_en = c_status_dup[14].s3.bits.way_en;
  assign io_status_dup_15_s1_valid = c_status_dup[15].s1.valid;
  assign io_status_dup_15_s1_bits_set = c_status_dup[15].s1.bits.set;
  assign io_status_dup_15_s1_bits_way_en = c_status_dup[15].s1.bits.way_en;
  assign io_status_dup_15_s2_valid = c_status_dup[15].s2.valid;
  assign io_status_dup_15_s2_bits_set = c_status_dup[15].s2.bits.set;
  assign io_status_dup_15_s2_bits_way_en = c_status_dup[15].s2.bits.way_en;
  assign io_status_dup_15_s3_valid = c_status_dup[15].s3.valid;
  assign io_status_dup_15_s3_bits_set = c_status_dup[15].s3.bits.set;
  assign io_status_dup_15_s3_bits_way_en = c_status_dup[15].s3.bits.way_en;
  assign io_status_dup_16_s1_valid = c_status_dup[16].s1.valid;
  assign io_status_dup_16_s1_bits_set = c_status_dup[16].s1.bits.set;
  assign io_status_dup_16_s1_bits_way_en = c_status_dup[16].s1.bits.way_en;
  assign io_status_dup_16_s2_valid = c_status_dup[16].s2.valid;
  assign io_status_dup_16_s2_bits_set = c_status_dup[16].s2.bits.set;
  assign io_status_dup_16_s2_bits_way_en = c_status_dup[16].s2.bits.way_en;
  assign io_status_dup_16_s3_valid = c_status_dup[16].s3.valid;
  assign io_status_dup_16_s3_bits_set = c_status_dup[16].s3.bits.set;
  assign io_status_dup_16_s3_bits_way_en = c_status_dup[16].s3.bits.way_en;
  assign io_status_dup_17_s1_valid = c_status_dup[17].s1.valid;
  assign io_status_dup_17_s1_bits_set = c_status_dup[17].s1.bits.set;
  assign io_status_dup_17_s1_bits_way_en = c_status_dup[17].s1.bits.way_en;
  assign io_status_dup_17_s2_valid = c_status_dup[17].s2.valid;
  assign io_status_dup_17_s2_bits_set = c_status_dup[17].s2.bits.set;
  assign io_status_dup_17_s2_bits_way_en = c_status_dup[17].s2.bits.way_en;
  assign io_status_dup_17_s3_valid = c_status_dup[17].s3.valid;
  assign io_status_dup_17_s3_bits_set = c_status_dup[17].s3.bits.set;
  assign io_status_dup_17_s3_bits_way_en = c_status_dup[17].s3.bits.way_en;
  assign io_status_dup_18_s1_valid = c_status_dup[18].s1.valid;
  assign io_status_dup_18_s1_bits_set = c_status_dup[18].s1.bits.set;
  assign io_status_dup_18_s1_bits_way_en = c_status_dup[18].s1.bits.way_en;
  assign io_status_dup_18_s2_valid = c_status_dup[18].s2.valid;
  assign io_status_dup_18_s2_bits_set = c_status_dup[18].s2.bits.set;
  assign io_status_dup_18_s2_bits_way_en = c_status_dup[18].s2.bits.way_en;
  assign io_status_dup_18_s3_valid = c_status_dup[18].s3.valid;
  assign io_status_dup_18_s3_bits_set = c_status_dup[18].s3.bits.set;
  assign io_status_dup_18_s3_bits_way_en = c_status_dup[18].s3.bits.way_en;
  assign io_status_dup_19_s1_valid = c_status_dup[19].s1.valid;
  assign io_status_dup_19_s1_bits_set = c_status_dup[19].s1.bits.set;
  assign io_status_dup_19_s1_bits_way_en = c_status_dup[19].s1.bits.way_en;
  assign io_status_dup_19_s2_valid = c_status_dup[19].s2.valid;
  assign io_status_dup_19_s2_bits_set = c_status_dup[19].s2.bits.set;
  assign io_status_dup_19_s2_bits_way_en = c_status_dup[19].s2.bits.way_en;
  assign io_status_dup_19_s3_valid = c_status_dup[19].s3.valid;
  assign io_status_dup_19_s3_bits_set = c_status_dup[19].s3.bits.set;
  assign io_status_dup_19_s3_bits_way_en = c_status_dup[19].s3.bits.way_en;
  assign io_status_dup_20_s1_valid = c_status_dup[20].s1.valid;
  assign io_status_dup_20_s1_bits_set = c_status_dup[20].s1.bits.set;
  assign io_status_dup_20_s1_bits_way_en = c_status_dup[20].s1.bits.way_en;
  assign io_status_dup_20_s2_valid = c_status_dup[20].s2.valid;
  assign io_status_dup_20_s2_bits_set = c_status_dup[20].s2.bits.set;
  assign io_status_dup_20_s2_bits_way_en = c_status_dup[20].s2.bits.way_en;
  assign io_status_dup_20_s3_valid = c_status_dup[20].s3.valid;
  assign io_status_dup_20_s3_bits_set = c_status_dup[20].s3.bits.set;
  assign io_status_dup_20_s3_bits_way_en = c_status_dup[20].s3.bits.way_en;
  assign io_status_dup_21_s1_valid = c_status_dup[21].s1.valid;
  assign io_status_dup_21_s1_bits_set = c_status_dup[21].s1.bits.set;
  assign io_status_dup_21_s1_bits_way_en = c_status_dup[21].s1.bits.way_en;
  assign io_status_dup_21_s2_valid = c_status_dup[21].s2.valid;
  assign io_status_dup_21_s2_bits_set = c_status_dup[21].s2.bits.set;
  assign io_status_dup_21_s2_bits_way_en = c_status_dup[21].s2.bits.way_en;
  assign io_status_dup_21_s3_valid = c_status_dup[21].s3.valid;
  assign io_status_dup_21_s3_bits_set = c_status_dup[21].s3.bits.set;
  assign io_status_dup_21_s3_bits_way_en = c_status_dup[21].s3.bits.way_en;
  assign io_status_dup_22_s1_valid = c_status_dup[22].s1.valid;
  assign io_status_dup_22_s1_bits_set = c_status_dup[22].s1.bits.set;
  assign io_status_dup_22_s1_bits_way_en = c_status_dup[22].s1.bits.way_en;
  assign io_status_dup_22_s2_valid = c_status_dup[22].s2.valid;
  assign io_status_dup_22_s2_bits_set = c_status_dup[22].s2.bits.set;
  assign io_status_dup_22_s2_bits_way_en = c_status_dup[22].s2.bits.way_en;
  assign io_status_dup_22_s3_valid = c_status_dup[22].s3.valid;
  assign io_status_dup_22_s3_bits_set = c_status_dup[22].s3.bits.set;
  assign io_status_dup_22_s3_bits_way_en = c_status_dup[22].s3.bits.way_en;
  assign io_status_dup_23_s1_valid = c_status_dup[23].s1.valid;
  assign io_status_dup_23_s1_bits_set = c_status_dup[23].s1.bits.set;
  assign io_status_dup_23_s1_bits_way_en = c_status_dup[23].s1.bits.way_en;
  assign io_status_dup_23_s2_valid = c_status_dup[23].s2.valid;
  assign io_status_dup_23_s2_bits_set = c_status_dup[23].s2.bits.set;
  assign io_status_dup_23_s2_bits_way_en = c_status_dup[23].s2.bits.way_en;
  assign io_status_dup_23_s3_valid = c_status_dup[23].s3.valid;
  assign io_status_dup_23_s3_bits_set = c_status_dup[23].s3.bits.set;
  assign io_status_dup_23_s3_bits_way_en = c_status_dup[23].s3.bits.way_en;
  assign io_error_bits_paddr = c_error_bits.paddr;
  assign io_error_bits_report_to_beu = c_error_bits.report_to_beu;
  assign io_bloom_filter_query_set_valid = c_bloom_filter_query.set.valid;
  assign io_bloom_filter_query_set_bits_addr = c_bloom_filter_query.set.bits_addr;
  assign io_bloom_filter_query_clr_valid = c_bloom_filter_query.clr.valid;
  assign io_bloom_filter_query_clr_bits_addr = c_bloom_filter_query.clr.bits_addr;
  assign io_perf_0_value = c_perf[0].value;
  assign io_perf_1_value = c_perf[1].value;
  assign io_perf_2_value = c_perf[2].value;
  assign io_perf_3_value = c_perf[3].value;

  xs_MainPipe_core u_core (
    .clock(clock),
    .reset(reset),
    .probe_req_valid(io_probe_req_valid),
    .probe_req_ready(io_probe_req_ready),
    .probe_req_bits(c_probe_req_bits),
    .refill_req_valid(io_refill_req_valid),
    .refill_req_ready(io_refill_req_ready),
    .refill_req_bits(c_refill_req_bits),
    .store_req_valid(io_store_req_valid),
    .store_req_ready(io_store_req_ready),
    .store_req_bits(c_store_req_bits),
    .atomic_req_valid(io_atomic_req_valid),
    .atomic_req_ready(io_atomic_req_ready),
    .atomic_req_bits(c_atomic_req_bits),
    .miss_req_ready(io_miss_req_ready),
    .miss_req_valid(io_miss_req_valid),
    .miss_req_bits(c_miss_req_bits),
    .wbq_conflict_check_valid(io_wbq_conflict_check_valid),
    .wbq_conflict_check_bits(io_wbq_conflict_check_bits),
    .wbq_block_miss_req(io_wbq_block_miss_req),
    .store_replay_resp_valid(io_store_replay_resp_valid),
    .store_replay_resp_bits_id(io_store_replay_resp_bits_id),
    .store_hit_resp_valid(io_store_hit_resp_valid),
    .store_hit_resp_bits_id(io_store_hit_resp_bits_id),
    .atomic_resp_valid(io_atomic_resp_valid),
    .atomic_resp_bits(c_atomic_resp_bits),
    .mainpipe_info(c_mainpipe_info),
    .refill_info_valid(io_refill_info_valid),
    .refill_info_bits(c_refill_info_bits),
    .wb_ready(io_wb_ready),
    .wb_valid(io_wb_valid),
    .wb_bits(c_wb_bits),
    .data_read_intend(io_data_read_intend),
    .data_readline_ready(io_data_readline_ready),
    .data_readline_valid(io_data_readline_valid),
    .data_readline_bits(c_data_readline_bits),
    .data_readline_can_go(io_data_readline_can_go),
    .data_readline_stall(io_data_readline_stall),
    .data_readline_can_resp(io_data_readline_can_resp),
    .data_resp(c_data_resp),
    .readline_error_delayed(io_readline_error_delayed),
    .data_write_valid(io_data_write_valid),
    .data_write_bits(c_data_write_bits),
    .data_write_dup(c_data_write_dup),
    .meta_read_valid(io_meta_read_valid),
    .meta_read_bits_idx(io_meta_read_bits_idx),
    .meta_resp(c_meta_resp),
    .meta_write_valid(io_meta_write_valid),
    .meta_write_bits(c_meta_write_bits),
    .extra_meta_resp(c_extra_meta_resp),
    .error_flag_write_valid(io_error_flag_write_valid),
    .error_flag_write_bits(c_error_flag_write_bits),
    .prefetch_flag_write_valid(io_prefetch_flag_write_valid),
    .prefetch_flag_write_bits(c_prefetch_flag_write_bits),
    .access_flag_write_valid(io_access_flag_write_valid),
    .access_flag_write_bits(c_access_flag_write_bits),
    .tag_read_ready(io_tag_read_ready),
    .tag_read_valid(io_tag_read_valid),
    .tag_read_bits_idx(io_tag_read_bits_idx),
    .tag_resp(c_tag_resp),
    .tag_write_valid(io_tag_write_valid),
    .tag_write_bits(c_tag_write_bits),
    .tag_write_intend(io_tag_write_intend),
    .replace_access_valid(io_replace_access_valid),
    .replace_access_bits(c_replace_access_bits),
    .replace_way_set_bits(io_replace_way_set_bits),
    .replace_way_way(io_replace_way_way),
    .evict_set(io_evict_set),
    .btot_ways_for_set(io_btot_ways_for_set),
    .replace_req_bits(c_replace_req_bits),
    .replace_block(io_replace_block),
    .sms_agt_evict_req_valid(io_sms_agt_evict_req_valid),
    .sms_agt_evict_req_bits_vaddr(io_sms_agt_evict_req_bits_vaddr),
    .status_dup(c_status_dup),
    .lrsc_locked_block_valid(io_lrsc_locked_block_valid),
    .lrsc_locked_block_bits(io_lrsc_locked_block_bits),
    .invalid_resv_set(io_invalid_resv_set),
    .update_resv_set(io_update_resv_set),
    .block_lr(io_block_lr),
    .error_valid(io_error_valid),
    .error_bits(c_error_bits),
    .pseudo_error_valid(io_pseudo_error_valid),
    .pseudo_error_bits_0_valid(io_pseudo_error_bits_0_valid),
    .pseudo_error_bits_0_mask(io_pseudo_error_bits_0_mask),
    .pseudo_tag_error_inj_done(io_pseudo_tag_error_inj_done),
    .pseudo_data_error_inj_done(io_pseudo_data_error_inj_done),
    .bloom_filter_query(c_bloom_filter_query),
    .perf(c_perf)
  );

endmodule
// END GENERATED
