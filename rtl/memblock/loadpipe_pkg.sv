// =============================================================================
//  loadpipe_pkg —— LoadPipe(DCache load 访问流水) 可读核的类型/参数包
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/cache/dcache/loadpipe/LoadPipe.scala
//  本包把 golden 展平的标量/位段聚合为有物理含义的参数与 struct，供 xs_LoadPipe_core
//  使用。命名贴合香山 DCache 微架构词汇（way/set/bank/coh/tag/miss/btot/prefetch）。
// =============================================================================
package loadpipe_pkg;

  // ---- DCache 几何参数（本顶层配置：4 路、256 组、8 bank、512b 行）--------------
  localparam int N_WAYS      = 4;             // 组相联路数 nWays
  localparam int IDX_BITS    = 8;             // set 索引位宽 (256 sets) => vaddr[13:6]
  localparam int TAG_BITS    = 36;            // 物理 tag 位宽 => paddr[47:12]
  localparam int ENC_TAG_BITS= 43;            // 含 ECC 校验位的 tag 位宽 (36+7)
  localparam int PADDR_BITS  = 48;            // 物理地址位宽
  localparam int VADDR_BITS  = 50;            // 虚拟地址位宽(req 侧, 含高位)
  localparam int BANK_OH_W   = 9;             // bank one-hot 宽(8 bank, 128b 需要进位到 bit8)
  localparam int DATA_W      = 128;           // 一次最多回 128b(两个 64b bank 拼接)

  // 地址切片(与 golden 完全一致, 见 get_idx/get_tag/get_block_addr/addr_to_dcache_bank)
  //   set 索引 idx  = vaddr[13:6]            (IDX_BITS)
  //   物理 tag      = paddr[47:12]           (TAG_BITS)
  //   bank 选择     = vaddr[5:3]             (8 bank)
  //   行基址        = paddr[47:6] << 6

  // ---- cmd 编码(MemoryOpConstants, 取自 LoadPipe 用到的部分)---------------------
  localparam logic [4:0] M_XRD = 5'h0;  // load
  localparam logic [4:0] M_PFR = 5'h2;  // soft prefetch read
  localparam logic [4:0] M_PFW = 5'h3;  // soft prefetch write

  // instrtype: 硬件预取来源编码(DCACHE_PREFETCH_SOURCE)
  localparam logic [3:0] PREFETCH_SOURCE = 4'h3;

  // ---- TileLink ClientStates(2 位 coh 状态)------------------------------------
  //   一致性状态枚举(编码与 golden 寄存器逐位一致, 保证 FM 签名匹配)：
  //     Nothing=0(无副本) Branch=1(共享只读) Trunk=2(独占可写) Dirty=3(独占已改)
  typedef enum logic [1:0] {
    COH_NOTHING = 2'h0,
    COH_BRANCH  = 2'h1,
    COH_TRUNK   = 2'h2,
    COH_DIRTY   = 2'h3
  } coh_e;

  // ---- meta / extra_meta 单路条目(从 golden io_meta_resp_i_*/io_extra_meta_resp_i_*) ----
  typedef struct packed {
    logic [1:0] coh_state;   // 该路当前一致性状态
  } meta_t;

  typedef struct packed {
    logic       error;       // 该路 L2 标记的延迟错误
    logic [2:0] prefetch;    // 该路 prefetch source(bit2:1 区分硬件预取来源)
    logic       access;      // 该路曾被访问过
  } extra_meta_t;

  // ---- 流水级寄存器 -----------------------------------------------------------
  // s1：tag 比对 + 命中判定级寄存的请求上下文
  typedef struct packed {
    logic [4:0]            cmd;          // 访问命令(load / soft pf)
    logic [VADDR_BITS-1:0] vaddr;        // 对齐后的虚拟地址(128b 时低 4 位清零)
    logic [VADDR_BITS-1:0] vaddr_dup;    // 复制的 vaddr(data array 地址用)
    logic [3:0]            instrtype;    // 来源类型(==PREFETCH_SOURCE 表示硬件预取)
    logic                  is_first_issue;
    logic                  lq_flag;      // lqIdx.flag
    logic [6:0]            lq_value;     // lqIdx.value
    logic                  load128;      // 128 位 load 请求
  } s1_req_t;

  // s2：命中/miss/权限判定级寄存的请求与命中信息
  typedef struct packed {
    logic [4:0]  cmd;
    logic [3:0]  instrtype;
    logic        is_first_issue;
    logic        load128;
  } s2_req_t;

  // ===========================================================================
  //  TileLink onAccess 权限模型(可读重写, 等价于 ClientMetadata.onAccess)
  // ---------------------------------------------------------------------------
  //  s1 用命中路的 coh 状态 + 本次 cmd 判断:
  //    has_permission : 当前状态对本次访问是否已具备权限(无需向 L2 申请)
  //    new_hit_coh    : 访问后该行应处的状态(growPermissions 目标)
  //  命中 = tag 匹配 && has_permission && coh 未改变(new==old, 即不需要 BtoT 升级)
  //
  //  下面把 cmd 归约为 {is_write, is_read_or_write} 两位, 再与 2 位 coh 拼成 4 位
  //  索引 grow_idx, 查表得 new_hit_coh —— 这正是 firtool 展平的 _r_T / _GEN_17。
  // ===========================================================================

  // 写类访问(需要独占): A/T/atomic/PFW 等
  function automatic logic cmd_is_write(input logic [4:0] cmd);
    return (cmd == 5'h1)  || (cmd == 5'h11) || (cmd == 5'h7)  || (cmd == 5'h4)  ||
           (cmd == 5'h9)  || (cmd == 5'hA)  || (cmd == 5'hB)  || (cmd == 5'h8)  ||
           (cmd == 5'hC)  || (cmd == 5'hD)  || (cmd == 5'hE)  || (cmd == 5'hF)  ||
           (cmd == 5'h1A) || (cmd == 5'h1B) || (cmd == 5'h18);
  endfunction

  // 读类(含写类): 上面所有 + 普通 read / PFR
  function automatic logic cmd_is_read_or_write(input logic [4:0] cmd);
    return cmd_is_write(cmd) || (cmd == 5'h3) || (cmd == 5'h6);
  endfunction

  // 4 位 grow 索引: {is_write, is_read_or_write, coh[1:0]}
  function automatic logic [3:0] grow_index(input logic [4:0] cmd, input logic [1:0] coh);
    return {cmd_is_write(cmd), cmd_is_read_or_write(cmd), coh};
  endfunction

  // growPermissions 查表(逐字段对应 golden _GEN_17[_r_T]): 给定 grow_idx 返回访问后
  // 的目标 coh 状态。grow_idx 高 2 位是 {is_write, is_rd_or_wr}, 低 2 位是当前 coh。
  //   idx 0..3 (读且非写, isWrite=0 isRW=0): 目标 = 当前 coh(读不改变状态)
  //   idx 4..7 (isWrite=0 isRW=1, 普通读): 目标=1/0/0/1 -> 见下(只有满 coh 保持)
  //   idx 8..B (isWrite=1 isRW=0, 不可达组合, 置 0)
  //   idx C..F (isWrite=1 isRW=1, 写访问): 当前 Nothing->需升 Trunk(idx C=>2),
  //            Branch->Trunk(BtoT, 但 _GEN_17[C..E] 实为 0/0/...), 见精确表。
  // 精确表(_GEN_17, 索引即 _r_T):
  //   _GEN_17 (索引 8..12 为 _r_T_27 = (idx==C)?1:0, 故 8/9/A/B=0, C=1):
  //     idx: 0 1 2 3 | 4 5 6 7 | 8 9 A B | C D E F
  //     val: 0 1 2 3 | 1 2 2 3 | 0 0 0 0 | 1 2 3 3
  //   语义: 低半区(读)目标=保持当前 coh; 高半区(写)目标=升级到独占系状态。
  function automatic logic [1:0] grow_new_coh(input logic [3:0] idx);
    unique case (idx)
      4'h0:    grow_new_coh = 2'h0;
      4'h1:    grow_new_coh = 2'h1;
      4'h2:    grow_new_coh = 2'h2;
      4'h3:    grow_new_coh = 2'h3;
      4'h4:    grow_new_coh = 2'h1;
      4'h5:    grow_new_coh = 2'h2;
      4'h6:    grow_new_coh = 2'h2;
      4'h7:    grow_new_coh = 2'h3;
      4'h8:    grow_new_coh = 2'h0;  // _r_T_27
      4'h9:    grow_new_coh = 2'h0;  // _r_T_27
      4'hA:    grow_new_coh = 2'h0;  // _r_T_27
      4'hB:    grow_new_coh = 2'h0;  // _r_T_27
      4'hC:    grow_new_coh = 2'h1;  // _r_T_27 = (idx==C)?1:0 = 1
      4'hD:    grow_new_coh = 2'h2;
      4'hE:    grow_new_coh = 2'h3;
      4'hF:    grow_new_coh = 2'h3;
      default: grow_new_coh = 2'h0;
    endcase
  endfunction

  // has_permission(等价 s1_has_permission): 这些 grow_idx 表示当前状态已满足访问。
  function automatic logic has_permission(input logic [3:0] idx);
    return (idx == 4'h3) || (idx == 4'h2) || (idx == 4'h1) || (idx == 4'h7) ||
           (idx == 4'h6) || (idx == 4'hF) || (idx == 4'hE);
  endfunction

endpackage
