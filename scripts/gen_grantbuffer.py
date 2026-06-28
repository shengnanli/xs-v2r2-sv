#!/usr/bin/env python3
"""生成 coupledL2 (tl2chi) GrantBuffer (D 通道 Grant 缓冲/重排) 的核 / pkg / wrapper / 变体 / UT。

GrantBuffer 是 L2 slice 的 "授权(D)/确认(E) 路径" 单元:
  1. 从 MainPipe 收 d_task(TaskWithData), 入 grantQueue(FIFO, 16 深) + 两路 beat 数据 FIFO;
  2. 出队组 TLBundleD 经 io.d 发往上层 L1(GrantData 两拍, grantBuf 暂存第二拍);
  3. inflightGrant[16] 记录已发 Grant 未收 GrantAck 的地址, 供 SourceB 阻塞同址 Probe(grantStatus),
     收到 io.e(GrantAck, sink=条目号) 时清除;
  4. 依据流水级占用 + 队列计数做容量反压(toReqArb.block*), 防 GrantBuf 溢出;
  5. mergeA(把 A 请求合并进 release Grant) 时用 aMergeTask 字段重组入队 task;
  6. 预取响应队列 pftRespQueue(10 深) 回 Prefetcher。

黑盒(在 golden 同名 wrapper 内例化, 两侧一致):
  - Queue16_GrantQueueTask  grantQueue      : 存 {TaskBundle, grantid}
  - Queue16_GrantQueueData  grantQueueData0/1: 各存一个 256bit beat
  - Queue10_GrantBuffer_Anon pftRespQueue    : 预取响应 FIFO

可读核 xs_GrantBuffer_core 做除以上 FIFO 外的全部逻辑(入队组装/出队拍流水/inflight FSM/反压)。

单态化(firtool): entries=mshrsAll=16, grantBufInflightSize=16, beatSize=2, TaskBundle 见 l2_task_pkg。
perf 计数器(timers/REG/enable_REG, 仅喂 XSPerf/assert)不驱动任何输出, 故核中省略(X 无关、FM 不读)。

样板: scripts/gen_sourceb.py (同套 黑盒+核 方法)。
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "GrantBuffer"

# ---------------------------------------------------------------------------
# TaskBundle 字段表 (name, width)  —— 与 golden io_d_task_bits_task_* 完全一致
# 同样用于 RequestArb (sinkA/B/C/mshrTask 皆为此 TaskBundle)
# ---------------------------------------------------------------------------
FIELDS = [
    ("channel", 3), ("txChannel", 3), ("set", 9), ("tag", 31), ("off", 6),
    ("alias", 2), ("vaddr", 44), ("isKeyword", 1), ("opcode", 4), ("param", 3),
    ("size", 3), ("sourceId", 7), ("bufIdx", 2), ("needProbeAckData", 1),
    ("denied", 1), ("corrupt", 1), ("mshrTask", 1), ("mshrId", 8),
    ("aliasTask", 1), ("useProbeData", 1), ("mshrRetry", 1),
    ("readProbeDataDown", 1), ("fromL2pft", 1), ("needHint", 1), ("dirty", 1),
    ("way", 3), ("meta_dirty", 1), ("meta_state", 2), ("meta_clients", 1),
    ("meta_alias", 2), ("meta_prefetch", 1), ("meta_prefetchSrc", 3),
    ("meta_accessed", 1), ("meta_tagErr", 1), ("meta_dataErr", 1),
    ("metaWen", 1), ("tagWen", 1), ("dsWen", 1), ("wayMask", 8),
    ("replTask", 1), ("cmoTask", 1), ("cmoAll", 1), ("reqSource", 5),
    ("mergeA", 1), ("aMergeTask_off", 6), ("aMergeTask_alias", 2),
    ("aMergeTask_vaddr", 44), ("aMergeTask_isKeyword", 1),
    ("aMergeTask_opcode", 3), ("aMergeTask_param", 3),
    ("aMergeTask_sourceId", 7), ("aMergeTask_meta_dirty", 1),
    ("aMergeTask_meta_state", 2), ("aMergeTask_meta_clients", 1),
    ("aMergeTask_meta_alias", 2), ("aMergeTask_meta_prefetch", 1),
    ("aMergeTask_meta_prefetchSrc", 3), ("aMergeTask_meta_accessed", 1),
    ("aMergeTask_meta_tagErr", 1), ("aMergeTask_meta_dataErr", 1),
    ("snpHitRelease", 1), ("snpHitReleaseToInval", 1),
    ("snpHitReleaseToClean", 1), ("snpHitReleaseWithData", 1),
    ("snpHitReleaseIdx", 8), ("snpHitReleaseMeta_dirty", 1),
    ("snpHitReleaseMeta_state", 2), ("snpHitReleaseMeta_clients", 1),
    ("snpHitReleaseMeta_alias", 2), ("snpHitReleaseMeta_prefetch", 1),
    ("snpHitReleaseMeta_prefetchSrc", 3), ("snpHitReleaseMeta_accessed", 1),
    ("snpHitReleaseMeta_tagErr", 1), ("snpHitReleaseMeta_dataErr", 1),
    ("tgtID", 11), ("srcID", 11), ("txnID", 12), ("homeNID", 11),
    ("dbID", 12), ("fwdNID", 11), ("fwdTxnID", 12), ("chiOpcode", 7),
    ("resp", 3), ("fwdState", 3), ("pCrdType", 4), ("retToSrc", 1),
    ("likelyshared", 1), ("expCompAck", 1), ("allowRetry", 1),
    ("memAttr_allocate", 1), ("memAttr_cacheable", 1), ("memAttr_device", 1),
    ("memAttr_ewa", 1), ("traceTag", 1), ("dataCheckErr", 1),
]
FW = {n: w for n, w in FIELDS}


def sv(n):
    """结构体成员名规避 SV 关键字(扁平端口名不受影响, 仅含 alias 子串)。"""
    return "alias_" if n == "alias" else n

# mergeAtask 非零成员: name -> 取值表达式(以 dtask 成员命名)。其余成员默认 0。
# 对照 GrantBuffer.scala:124-157 (mergeAtask := WireInit(0); 逐项覆盖)
MERGEA = {
    "channel": "dtask.channel", "txChannel": "dtask.txChannel",
    "off": "dtask.aMergeTask_off", "alias": "dtask.aMergeTask_alias",
    "opcode": "{1'b0, dtask.aMergeTask_opcode}", "param": "dtask.aMergeTask_param",
    "sourceId": "dtask.aMergeTask_sourceId",
    "meta_dirty": "dtask.aMergeTask_meta_dirty",
    "meta_state": "dtask.aMergeTask_meta_state",
    "meta_clients": "dtask.aMergeTask_meta_clients",
    "meta_alias": "dtask.aMergeTask_meta_alias",
    "meta_prefetch": "dtask.aMergeTask_meta_prefetch",
    "meta_prefetchSrc": "dtask.aMergeTask_meta_prefetchSrc",
    "meta_accessed": "dtask.aMergeTask_meta_accessed",
    "meta_tagErr": "dtask.aMergeTask_meta_tagErr",
    "meta_dataErr": "dtask.aMergeTask_meta_dataErr",
    "set": "dtask.set", "tag": "dtask.tag", "vaddr": "dtask.vaddr",
    "isKeyword": "dtask.aMergeTask_isKeyword", "size": "dtask.size",
    "bufIdx": "dtask.bufIdx", "needProbeAckData": "dtask.needProbeAckData",
    "denied": "dtask.denied", "corrupt": "dtask.corrupt | dtask.denied",
    "mshrTask": "dtask.mshrTask", "mshrId": "dtask.mshrId",
    "aliasTask": "dtask.aliasTask", "dirty": "dtask.dirty", "way": "dtask.way",
    "metaWen": "dtask.metaWen", "tagWen": "dtask.tagWen", "dsWen": "dtask.dsWen",
    "wayMask": "dtask.wayMask", "replTask": "dtask.replTask",
    "reqSource": "dtask.reqSource",
}

NINFL = 16   # grantBufInflightSize = mshrsAll


def decl(width):
    return "" if width == 1 else f"[{width-1}:0] "


# ===========================================================================
#  l2_task_pkg.sv : TaskBundle 结构体 (GrantBuffer 与 RequestArb 共用)
# ===========================================================================
def gen_pkg():
    L = ["// 自动生成 scripts/gen_grantbuffer.py —— 勿手改",
         "// coupledL2 (tl2chi) L2 slice 公共 TaskBundle 结构体, GrantBuffer/RequestArb 共用。",
         "// 字段顺序/位宽与 firtool 展平的 io_*_bits_task_* 完全一致。",
         "`ifndef L2_TASK_PKG_SV", "`define L2_TASK_PKG_SV",
         "package l2_task_pkg;", "",
         "  // L2 slice 主流水 TaskBundle (单态化: tl2chi, 95 字段)",
         "  typedef struct packed {"]
    for n, w in FIELDS:
        L.append(f"    logic {decl(w):<10}{sv(n)};")
    L.append("  } task_bundle_t;")
    L.append("")
    L.append("endpackage")
    L.append("`endif")
    L.append("")
    return "\n".join(L)


# ===========================================================================
#  核 xs_GrantBuffer_core
# ===========================================================================
def core_ports():
    """核端口: 扁平模块 IO(供 wrapper 直通) + 与 4 个 FIFO 黑盒对接的边界。"""
    P = []
    P.append("  input  logic        clock,")
    P.append("  input  logic        reset,")
    P.append("  // ---- io.d_task (Flipped Decoupled TaskWithData; data 直接进数据 FIFO, 不入核) ----")
    P.append("  input  logic        io_d_task_valid,")
    for n, w in FIELDS:
        P.append(f"  input  logic {decl(w):<7}io_d_task_bits_task_{n},")
    P.append("  // ---- io.d (Decoupled TLBundleD 发往 L1) ----")
    P.append("  input  logic        io_d_ready,")
    P.append("  output logic        io_d_valid,")
    P.append("  output logic [3:0]  io_d_bits_opcode,")
    P.append("  output logic [1:0]  io_d_bits_param,")
    P.append("  output logic [6:0]  io_d_bits_source,")
    P.append("  output logic [7:0]  io_d_bits_sink,")
    P.append("  output logic        io_d_bits_denied,")
    P.append("  output logic        io_d_bits_echo_isKeyword,")
    P.append("  output logic [255:0] io_d_bits_data,")
    P.append("  output logic        io_d_bits_corrupt,")
    P.append("  // ---- io.e (Flipped Decoupled TLBundleE, GrantAck) ----")
    P.append("  input  logic        io_e_valid,")
    P.append("  input  logic [7:0]  io_e_bits_sink,")
    P.append("  // ---- 反压所需: ReqArb s1 状态 + 流水级占用 ----")
    P.append("  input  logic [30:0] io_fromReqArb_status_s1_tags_1,")
    P.append("  input  logic [8:0]  io_fromReqArb_status_s1_sets_1,")
    for k in range(1, 5):
        P.append(f"  input  logic        io_pipeStatusVec_{k}_valid,")
        P.append(f"  input  logic [2:0]  io_pipeStatusVec_{k}_bits_channel,")
    P.append("  output logic        io_toReqArb_blockSinkReqEntrance_blockA_s1,")
    P.append("  output logic        io_toReqArb_blockSinkReqEntrance_blockB_s1,")
    P.append("  output logic        io_toReqArb_blockSinkReqEntrance_blockC_s1,")
    P.append("  output logic        io_toReqArb_blockMSHRReqEntrance,")
    # grantStatus 输出 (= inflightGrant)
    P.append("  // ---- io.grantStatus[16] (=inflightGrant, 供 SourceB 阻塞同址 Probe) ----")
    for k in range(NINFL):
        P.append(f"  output logic        io_grantStatus_{k}_valid,")
        P.append(f"  output logic [8:0]  io_grantStatus_{k}_set,")
        P.append(f"  output logic [30:0] io_grantStatus_{k}_tag,")
    # 与 grantQueue 黑盒对接
    P.append("  // ---- 与 grantQueue(Queue16_GrantQueueTask) 黑盒对接 ----")
    P.append("  output l2_task_pkg::task_bundle_t gq_enq_task,  // 入队 task(已做 mergeA 重组)")
    P.append("  output logic        gq_enq_valid,")
    P.append("  output logic [7:0]  gq_enq_grantid,")
    P.append("  output logic        gq_deq_ready,")
    P.append("  input  logic        gq_deq_valid,")
    P.append("  input  logic        gq_deq_isKeyword,")
    P.append("  input  logic [3:0]  gq_deq_opcode,")
    P.append("  input  logic [2:0]  gq_deq_param,")
    P.append("  input  logic [6:0]  gq_deq_sourceId,")
    P.append("  input  logic        gq_deq_denied,")
    P.append("  input  logic        gq_deq_corrupt,")
    P.append("  input  logic [7:0]  gq_deq_grantid,")
    P.append("  input  logic [4:0]  gq_count,")
    P.append("  // ---- 与 grantQueueData0/1(Queue16_GrantQueueData) 黑盒对接 ----")
    P.append("  input  logic [255:0] gd0_deq_data,")
    P.append("  input  logic [255:0] gd1_deq_data,")
    P.append("  // ---- 与 pftRespQueue(Queue10) 黑盒对接(仅取计数做反压) ----")
    P.append("  input  logic [3:0]  pft_count")
    return "\n".join(P)


def gen_core():
    L = []
    L.append("// 自动生成 scripts/gen_grantbuffer.py —— 勿手改")
    L.append("// =============================================================================")
    L.append("//  GrantBuffer —— coupledL2 (tl2chi) L2 slice D/E(授权/确认) 路径 可读重写核")
    L.append("//          (xs_GrantBuffer_core)")
    L.append("// -----------------------------------------------------------------------------")
    L.append("//  对照 Scala: coupledL2/src/main/scala/coupledL2/GrantBuffer.scala")
    L.append("//  4 个 FIFO(grantQueue/grantQueueData0/1/pftRespQueue) 为黑盒, 在 golden 同名")
    L.append("//  wrapper 内例化; 本核做入队组装、出队组 TLBundleD、inflightGrant FSM、容量反压。")
    L.append("//  ===== X 铁律 =====")
    L.append("//    inflightGrant[16]/grantBuf 异步复位清 0 门控所有读出; e.sink/insertIdx 恒在 [0,15]。")
    L.append("// =============================================================================")
    L.append("module xs_GrantBuffer_core")
    L.append("  import l2_task_pkg::*;")
    L.append("(")
    L.append(core_ports())
    L.append(");")
    L.append("")
    # ---- 打包 d_task 输入为结构体 ----
    L.append("  // ===== 打包扁平 d_task 输入为 TaskBundle 结构体(便于按字段重组) =====")
    L.append("  task_bundle_t dtask;")
    L.append("  always_comb begin")
    for n, w in FIELDS:
        L.append(f"    dtask.{sv(n)} = io_d_task_bits_task_{n};")
    L.append("  end")
    L.append("")
    # ---- mergeAtask + enqTask ----
    L.append("  // ===== mergeA 入队重组: mergeAtask 取 aMergeTask 字段, 其余清 0; 非 mergeA 走原 task =====")
    L.append("  // 对照 Scala mergeAtask := WireInit(0.U.asTypeOf(TaskBundle)); 逐项覆盖, 再 Mux(mergeA,...)")
    L.append("  task_bundle_t mergeAtask;")
    L.append("  always_comb begin")
    L.append("    mergeAtask = '0;")
    for n in [f[0] for f in FIELDS]:
        if n in MERGEA:
            L.append(f"    mergeAtask.{sv(n)} = {MERGEA[n]};")
    L.append("  end")
    L.append("  assign gq_enq_task = io_d_task_bits_task_mergeA ? mergeAtask : dtask;")
    L.append("")
    # ---- inflight insert idx ----
    L.append("  // ===== inflightGrant 表(16): 已发 Grant 未收 GrantAck 的地址 =====")
    L.append(f"  logic        inflightGrant_valid [{NINFL}];")
    L.append(f"  logic [8:0]  inflightGrant_set   [{NINFL}];")
    L.append(f"  logic [30:0] inflightGrant_tag   [{NINFL}];")
    L.append("")
    L.append("  // insertIdx = 第一个空表项(PriorityEncoder(~valid)); 全满(0..14 valid)时取 15")
    L.append("  logic [3:0] insert_idx;")
    L.append("  always_comb begin")
    L.append("    insert_idx = 4'd15;")
    L.append("    for (int k = 14; k >= 0; k--)")
    L.append("      if (!inflightGrant_valid[k]) insert_idx = k[3:0];")
    L.append("  end")
    L.append("")
    # ---- grantBuf (2nd beat holding reg) : 声明在前(被握手引用) ----
    L.append("  // ===== grantBuf: 暂存 GrantData 未发出的第二拍 =====")
    L.append("  logic         grantBufValid;")
    L.append("  logic         grantBuf_task_isKeyword;")
    L.append("  logic [3:0]   grantBuf_task_opcode;")
    L.append("  logic [2:0]   grantBuf_task_param;")
    L.append("  logic [6:0]   grantBuf_task_sourceId;")
    L.append("  logic         grantBuf_task_denied;")
    L.append("  logic         grantBuf_task_corrupt;")
    L.append("  logic [255:0] grantBuf_data_data;")
    L.append("  logic [7:0]   grantBuf_grantid;")
    L.append("")
    # ---- enqueue / dequeue handshakes ----
    L.append("  // ===== 入队/出队握手 =====")
    L.append("  // 入队: d_task 有效且(非 HintAck 或 mergeA); HintAck(预取响应,opcode==2)单独走 pftRespQueue")
    L.append("  assign gq_enq_valid = io_d_task_valid &")
    L.append("                        (io_d_task_bits_task_opcode != 4'h2 | io_d_task_bits_task_mergeA);")
    L.append("  assign gq_enq_grantid = {4'h0, insert_idx};")
    L.append("  // 出队就绪: io.d 就绪且 grantBuf 不占用(grantBuf 占用时第二拍优先)")
    L.append("  assign gq_deq_ready = io_d_ready & ~grantBufValid;")
    L.append("")
    L.append("  // deqTask.opcode(0)=1(奇数 opcode=带数据): 首拍直发, 余拍存 grantBuf")
    L.append("  wire deq_fire   = gq_deq_valid & io_d_ready;")
    L.append("  wire load_grantBuf = deq_fire & ~grantBufValid & gq_deq_opcode[0];")
    L.append("")
    # ---- inflight alloc/free ----
    L.append("  // 分配 inflight: d_task.fire 且为 Grant/GrantData/mergeA (io.d_task.ready 恒 1, fire==valid)")
    L.append("  wire inflight_alloc = io_d_task_valid &")
    L.append("       (io_d_task_bits_task_opcode == 4'h4 | io_d_task_bits_task_opcode == 4'h5 |")
    L.append("        io_d_task_bits_task_mergeA);")
    L.append("")
    L.append("  // ===== 时序: inflightGrant + grantBuf =====")
    L.append("  always_ff @(posedge clock or posedge reset) begin")
    L.append("    if (reset) begin")
    L.append(f"      for (int k = 0; k < {NINFL}; k++) begin")
    L.append("        inflightGrant_valid[k] <= 1'b0;")
    L.append("        inflightGrant_set[k]   <= 9'h0;")
    L.append("        inflightGrant_tag[k]   <= 31'h0;")
    L.append("      end")
    L.append("      grantBufValid           <= 1'b0;")
    L.append("      grantBuf_task_isKeyword <= 1'b0;")
    L.append("      grantBuf_task_opcode    <= 4'h0;")
    L.append("      grantBuf_task_param     <= 3'h0;")
    L.append("      grantBuf_task_sourceId  <= 7'h0;")
    L.append("      grantBuf_task_denied    <= 1'b0;")
    L.append("      grantBuf_task_corrupt   <= 1'b0;")
    L.append("      grantBuf_data_data      <= 256'h0;")
    L.append("      grantBuf_grantid        <= 8'h0;")
    L.append("    end else begin")
    L.append(f"      for (int k = 0; k < {NINFL}; k++) begin")
    L.append("        automatic logic alloc_k = inflight_alloc & (insert_idx == k[3:0]);")
    L.append("        automatic logic free_k  = io_e_valid & (io_e_bits_sink[3:0] == k[3:0]);")
    L.append("        // 收到 GrantAck(free) 清 valid; 否则分配置位; 否则保持")
    L.append("        inflightGrant_valid[k] <= ~free_k & (alloc_k | inflightGrant_valid[k]);")
    L.append("        if (alloc_k) begin")
    L.append("          inflightGrant_set[k] <= io_d_task_bits_task_set;")
    L.append("          inflightGrant_tag[k] <= io_d_task_bits_task_tag;")
    L.append("        end")
    L.append("      end")
    L.append("      // grantBuf: 装第二拍 / 发出后清空")
    L.append("      grantBufValid <= ~(grantBufValid & io_d_ready) & (load_grantBuf | grantBufValid);")
    L.append("      if (load_grantBuf) begin")
    L.append("        grantBuf_task_isKeyword <= gq_deq_isKeyword;")
    L.append("        grantBuf_task_opcode    <= gq_deq_opcode;")
    L.append("        grantBuf_task_param     <= gq_deq_param;")
    L.append("        grantBuf_task_sourceId  <= gq_deq_sourceId;")
    L.append("        grantBuf_task_denied    <= gq_deq_denied;")
    L.append("        grantBuf_task_corrupt   <= gq_deq_corrupt;")
    L.append("        // 装入 grantBuf 的是 \"另一拍\": isKeyword 时取 beat0 否则 beat1")
    L.append("        grantBuf_data_data      <= gq_deq_isKeyword ? gd0_deq_data : gd1_deq_data;")
    L.append("        grantBuf_grantid        <= gq_deq_grantid;")
    L.append("      end")
    L.append("    end")
    L.append("  end")
    L.append("")
    # ---- io.d output ----
    L.append("  // ===== 组 TLBundleD 发往 L1: grantBuf 占用时发第二拍, 否则发出队首拍 =====")
    L.append("  assign io_d_valid              = grantBufValid | gq_deq_valid;")
    L.append("  assign io_d_bits_opcode        = grantBufValid ? grantBuf_task_opcode      : gq_deq_opcode;")
    L.append("  assign io_d_bits_param         = grantBufValid ? grantBuf_task_param[1:0]  : gq_deq_param[1:0];")
    L.append("  assign io_d_bits_source        = grantBufValid ? grantBuf_task_sourceId    : gq_deq_sourceId;")
    L.append("  assign io_d_bits_sink          = grantBufValid ? grantBuf_grantid          : gq_deq_grantid;")
    L.append("  assign io_d_bits_denied        = grantBufValid ? grantBuf_task_denied      : gq_deq_denied;")
    L.append("  assign io_d_bits_echo_isKeyword= grantBufValid ? grantBuf_task_isKeyword   : gq_deq_isKeyword;")
    L.append("  // 首拍数据: isKeyword 时取 beat1 否则 beat0 (与装 grantBuf 的取拍相反 = keyword 重排)")
    L.append("  assign io_d_bits_data          = grantBufValid ? grantBuf_data_data :")
    L.append("                                   (gq_deq_isKeyword ? gd1_deq_data : gd0_deq_data);")
    L.append("  assign io_d_bits_corrupt       = grantBufValid ? (grantBuf_task_corrupt | grantBuf_task_denied)")
    L.append("                                                 : (gq_deq_corrupt | gq_deq_denied);")
    L.append("")
    # ---- grantStatus ----
    L.append("  // ===== grantStatus = inflightGrant(供 SourceB) =====")
    for k in range(NINFL):
        L.append(f"  assign io_grantStatus_{k}_valid = inflightGrant_valid[{k}];")
        L.append(f"  assign io_grantStatus_{k}_set   = inflightGrant_set[{k}];")
        L.append(f"  assign io_grantStatus_{k}_tag   = inflightGrant_tag[{k}];")
    L.append("")
    # ---- blocking / back pressure ----
    L.append("  // ===== 容量反压: 统计流水级占用 + 队列计数, 防 GrantBuf/inflight/pft 溢出 =====")
    L.append("  // 流水级 1..4 中 fromA(channel[0]) / fromC(channel[2]) 计数(可能占 GrantBuf)")
    L.append("  logic [2:0] cnt_ac, cnt_a;")
    L.append("  always_comb begin")
    L.append("    cnt_ac = 3'h0; cnt_a = 3'h0;")
    pipe = []
    for k in range(1, 5):
        pipe.append((f"io_pipeStatusVec_{k}_valid", f"io_pipeStatusVec_{k}_bits_channel"))
    for v, c in pipe:
        L.append(f"    if ({v} & ({c}[0] | {c}[2])) cnt_ac = cnt_ac + 3'h1;")
    for v, c in pipe:
        L.append(f"    if ({v} & {c}[0])             cnt_a  = cnt_a  + 3'h1;")
    L.append("  end")
    L.append("  // inflightGrant 占用计数")
    L.append("  logic [4:0] cnt_inflight;")
    L.append("  always_comb begin")
    L.append("    cnt_inflight = 5'h0;")
    L.append(f"    for (int k = 0; k < {NINFL}; k++)")
    L.append("      if (inflightGrant_valid[k]) cnt_inflight = cnt_inflight + 5'h1;")
    L.append("  end")
    L.append("")
    L.append("  // mshrsAll=16: SinkReq 阈值 16, MSHRReq 阈值 15(留一拍 s1 余量); pftQueueLen=10。")
    L.append("  // 位宽严格对齐 golden(队列计数被 FM 视为自由 cut-point, 取值可超 16, 必须按原截断)：")
    L.append("  //   sum_grant/sum_infl 截断到 5bit; sum_pft 截断到 4bit。")
    L.append("  wire [4:0] sum_grant = {2'h0, cnt_ac} + gq_count;          // +grantQueue, 5bit 截断")
    L.append("  wire [4:0] sum_infl  = {2'h0, cnt_a}  + cnt_inflight;      // +inflight(待 GrantAck)")
    L.append("  wire [3:0] sum_pft   = {1'h0, cnt_a}  + pft_count;         // +pftRespQueue, 4bit 截断")
    L.append("  // bit4 = sum>=16 (mshrsAll); >5'hE = sum>=15 (mshrsAll-1); pft 阈值 10/9 (pftQueueLen-0/1)")
    L.append("  assign io_toReqArb_blockSinkReqEntrance_blockC_s1 = sum_grant[4];")
    L.append("  assign io_toReqArb_blockSinkReqEntrance_blockA_s1 =")
    L.append("           sum_grant[4] | sum_infl[4] | (sum_pft > 4'h9);")
    L.append("  assign io_toReqArb_blockMSHRReqEntrance =")
    L.append("           (sum_grant > 5'hE) | (sum_infl > 5'hE) | (sum_pft > 4'h8);")
    L.append("  // blockB: 上层 B(Probe) 入口阻塞 —— 同址(set&tag)有在途 Grant 未确认")
    L.append("  logic blockB;")
    L.append("  always_comb begin")
    L.append("    blockB = 1'b0;")
    L.append(f"    for (int k = 0; k < {NINFL}; k++)")
    L.append("      if (inflightGrant_valid[k] &")
    L.append("          (inflightGrant_set[k] == io_fromReqArb_status_s1_sets_1) &")
    L.append("          (inflightGrant_tag[k] == io_fromReqArb_status_s1_tags_1)) blockB = 1'b1;")
    L.append("  end")
    L.append("  assign io_toReqArb_blockSinkReqEntrance_blockB_s1 = blockB;")
    L.append("")
    L.append("endmodule")
    L.append("")
    return "\n".join(L)


# ===========================================================================
#  wrapper / 变体: module GrantBuffer(_xs) = 核 + 4 个 FIFO 黑盒
# ===========================================================================
def gold_ports():
    """解析 golden GrantBuffer 端口 (顺序保持), 返回 [(dir,width,name)]。"""
    import re
    text = (GOLDEN / "GrantBuffer.sv").read_text()
    m = re.search(r"module\s+GrantBuffer\s*\((.*?)\n\);", text, re.S)
    ports = []
    for raw in m.group(1).splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        mm = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        d, w, n = mm.groups()
        ports.append((d, w or "", n))
    return ports


def gen_wrapper(top):
    P = gold_ports()
    L = []
    L.append("// 自动生成 scripts/gen_grantbuffer.py —— 勿手改")
    L.append(f"// {top}: golden 同名装配壳 = 可读核 xs_GrantBuffer_core + 4 个 FIFO 黑盒。")
    L.append("// 黑盒(两侧一致): grantQueue / grantQueueData0 / grantQueueData1 / pftRespQueue。")
    L.append(f"module {top}")
    L.append("  import l2_task_pkg::*;")
    L.append("(")
    body = ",\n".join(f"  {d} {w}{' ' if w else ''}{n}" for d, w, n in P)
    L.append(body)
    L.append(");")
    L.append("")
    # boundary wires
    L.append("  // ---- 核 <-> FIFO 边界 ----")
    L.append("  task_bundle_t gq_enq_task;")
    L.append("  wire        gq_enq_valid, gq_deq_ready, gq_deq_valid;")
    L.append("  wire        gq_deq_isKeyword, gq_deq_denied, gq_deq_corrupt;")
    L.append("  wire [3:0]  gq_deq_opcode;")
    L.append("  wire [2:0]  gq_deq_param;")
    L.append("  wire [6:0]  gq_deq_sourceId;")
    L.append("  wire [7:0]  gq_enq_grantid, gq_deq_grantid;")
    L.append("  wire [4:0]  gq_count;")
    L.append("  wire [255:0] gd0_deq_data, gd1_deq_data;")
    L.append("  wire [3:0]  pft_count;")
    L.append("  wire        gq_enq_ready;   // 队列满标志, 仅 golden assert 用; 此处接线以对齐黑盒引脚")
    L.append("  wire        pft_enq_ready;  // 同上")
    L.append("")
    # core instance
    L.append("  // ===== 可读核 =====")
    L.append("  xs_GrantBuffer_core u_core (")
    cc = ["    .clock(clock),", "    .reset(reset),", "    .io_d_task_valid(io_d_task_valid),"]
    for n, w in FIELDS:
        cc.append(f"    .io_d_task_bits_task_{n}(io_d_task_bits_task_{n}),")
    for sig in ["io_d_ready", "io_d_valid", "io_d_bits_opcode", "io_d_bits_param",
                "io_d_bits_source", "io_d_bits_sink", "io_d_bits_denied",
                "io_d_bits_echo_isKeyword", "io_d_bits_data", "io_d_bits_corrupt",
                "io_e_valid", "io_e_bits_sink", "io_fromReqArb_status_s1_tags_1",
                "io_fromReqArb_status_s1_sets_1"]:
        cc.append(f"    .{sig}({sig}),")
    for k in range(1, 5):
        cc.append(f"    .io_pipeStatusVec_{k}_valid(io_pipeStatusVec_{k}_valid),")
        cc.append(f"    .io_pipeStatusVec_{k}_bits_channel(io_pipeStatusVec_{k}_bits_channel),")
    for sig in ["io_toReqArb_blockSinkReqEntrance_blockA_s1",
                "io_toReqArb_blockSinkReqEntrance_blockB_s1",
                "io_toReqArb_blockSinkReqEntrance_blockC_s1",
                "io_toReqArb_blockMSHRReqEntrance"]:
        cc.append(f"    .{sig}({sig}),")
    for k in range(NINFL):
        cc.append(f"    .io_grantStatus_{k}_valid(io_grantStatus_{k}_valid),")
        cc.append(f"    .io_grantStatus_{k}_set(io_grantStatus_{k}_set),")
        cc.append(f"    .io_grantStatus_{k}_tag(io_grantStatus_{k}_tag),")
    for sig in ["gq_enq_task", "gq_enq_valid", "gq_enq_grantid", "gq_deq_ready",
                "gq_deq_valid", "gq_deq_isKeyword", "gq_deq_opcode", "gq_deq_param",
                "gq_deq_sourceId", "gq_deq_denied", "gq_deq_corrupt", "gq_deq_grantid",
                "gq_count", "gd0_deq_data", "gd1_deq_data"]:
        cc.append(f"    .{sig}({sig}),")
    cc.append("    .pft_count(pft_count)")
    cc.append("  );")
    L += cc
    L.append("")
    # grantQueue blackbox
    L.append("  // ===== grantQueue: TaskBundle+grantid FIFO(16 深) =====")
    L.append("  Queue16_GrantQueueTask grantQueue (")
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .io_enq_ready(gq_enq_ready),")
    L.append("    .io_enq_valid(gq_enq_valid),")
    for n, w in FIELDS:
        L.append(f"    .io_enq_bits_task_{n}(gq_enq_task.{sv(n)}),")
    L.append("    .io_enq_bits_grantid(gq_enq_grantid),")
    L.append("    .io_deq_ready(gq_deq_ready),")
    L.append("    .io_deq_valid(gq_deq_valid),")
    L.append("    .io_deq_bits_task_isKeyword(gq_deq_isKeyword),")
    L.append("    .io_deq_bits_task_opcode(gq_deq_opcode),")
    L.append("    .io_deq_bits_task_param(gq_deq_param),")
    L.append("    .io_deq_bits_task_sourceId(gq_deq_sourceId),")
    L.append("    .io_deq_bits_task_denied(gq_deq_denied),")
    L.append("    .io_deq_bits_task_corrupt(gq_deq_corrupt),")
    L.append("    .io_deq_bits_grantid(gq_deq_grantid),")
    L.append("    .io_count(gq_count)")
    L.append("  );")
    L.append("")
    # data queues
    L.append("  // ===== grantQueueData0/1: 两路 256bit beat FIFO; enq 直取 d_task.data 高/低半 =====")
    L.append("  Queue16_GrantQueueData grantQueueData0 (")
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .io_enq_valid(gq_enq_valid),")
    L.append("    .io_enq_bits_data_data(io_d_task_bits_data_data[255:0]),")
    L.append("    .io_deq_ready(gq_deq_ready),")
    L.append("    .io_deq_bits_data_data(gd0_deq_data)")
    L.append("  );")
    L.append("  Queue16_GrantQueueData grantQueueData1 (")
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .io_enq_valid(gq_enq_valid),")
    L.append("    .io_enq_bits_data_data(io_d_task_bits_data_data[511:256]),")
    L.append("    .io_deq_ready(gq_deq_ready),")
    L.append("    .io_deq_bits_data_data(gd1_deq_data)")
    L.append("  );")
    L.append("")
    # pft queue: enq from d_task, deq -> prefetchResp
    L.append("  // ===== pftRespQueue: 预取响应 FIFO(10 深); enq 取 HintAck, deq 回 Prefetcher =====")
    L.append("  wire [30:0] pft_deq_tag;")
    L.append("  Queue10_GrantBuffer_Anon pftRespQueue (")
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .io_enq_ready(pft_enq_ready),")
    L.append("    .io_enq_valid(io_d_task_valid & io_d_task_bits_task_opcode == 4'h2 &")
    L.append("                  io_d_task_bits_task_fromL2pft),")
    L.append("    .io_enq_bits_tag(io_d_task_bits_task_tag),")
    L.append("    .io_enq_bits_set(io_d_task_bits_task_set),")
    L.append("    .io_enq_bits_vaddr(io_d_task_bits_task_vaddr),")
    L.append("    .io_enq_bits_pfSource(io_d_task_bits_task_reqSource),")
    L.append("    .io_deq_ready(io_prefetchResp_ready),")
    L.append("    .io_deq_valid(io_prefetchResp_valid),")
    L.append("    .io_deq_bits_tag(pft_deq_tag),")
    L.append("    .io_deq_bits_set(io_prefetchResp_bits_set),")
    L.append("    .io_deq_bits_vaddr(io_prefetchResp_bits_vaddr),")
    L.append("    .io_deq_bits_pfSource(io_prefetchResp_bits_pfSource),")
    L.append("    .io_count(pft_count)")
    L.append("  );")
    L.append("  assign io_prefetchResp_bits_tag = {2'h0, pft_deq_tag};")
    L.append("")
    L.append("endmodule")
    L.append("")
    return "\n".join(L)


# ===========================================================================
#  testbench
# ===========================================================================
def gen_tb():
    P = gold_ports()
    ins = [p for p in P if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in P if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_grantbuffer.py —— 勿手改")
    L.append("// GrantBuffer 双例化逐拍比对: golden GrantBuffer vs 可读重写 GrantBuffer_xs。")
    L.append("// 偏置 opcode∈{Grant=4,GrantData=5,Hint=2}, 小 set/tag/sink, 覆盖 inflight 冲突/反压/出队两拍。")
    L.append("`timescale 1ns/1ps")
    L.append("`define CHK(SIG) begin \\")
    L.append("  if (!$isunknown(g_``SIG)) begin \\")
    L.append("    checks++; \\")
    L.append("    if (g_``SIG !== i_``SIG) begin \\")
    L.append("      errors++; \\")
    L.append("      if (errors <= 30) $display(\"[%0t] MISMATCH %s g=%0h i=%0h\", $time, `\"SIG`\", g_``SIG, i_``SIG); \\")
    L.append("    end \\")
    L.append("  end \\")
    L.append("end")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  bit clock = 0; bit reset; int errors = 0; int checks = 0;")
    L.append("  always #5 clock = ~clock;")
    for _, w, n in ins:
        L.append(f"  logic {w}{' ' if w else ''}{n};")
    for _, w, n in outs:
        L.append(f"  wire {w}{' ' if w else ''}g_{n};")
        L.append(f"  wire {w}{' ' if w else ''}i_{n};")
    L.append("")
    for instname, pfx in (("GrantBuffer", "g_"), ("GrantBuffer_xs", "i_")):
        L.append(f"  {instname} u_{pfx[0]} (")
        for i, (d, _, n) in enumerate(P):
            c = "," if i + 1 < len(P) else ""
            sig = n if (n in ("clock", "reset") or d == "input") else f"{pfx}{n}"
            L.append(f"    .{n}({sig}){c}")
        L.append("  );")
    L.append("")
    L.append("  task automatic drive_random();")
    for _, w, n in ins:
        nb = 1
        if w:
            import re
            mm = re.match(r"\[(\d+):(\d+)\]", w)
            nb = abs(int(mm.group(1)) - int(mm.group(2))) + 1
        if n == "io_d_task_bits_task_opcode":
            L.append(f"    {n} = $urandom_range(0,5);")
        elif n == "io_d_task_bits_task_set":
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n == "io_d_task_bits_task_tag":
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n == "io_d_task_bits_task_mergeA":
            L.append(f"    {n} = ($urandom_range(0,3) == 0);")
        elif n == "io_d_task_bits_task_fromL2pft":
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_e_bits_sink":
            L.append(f"    {n} = $urandom_range(0,15);")
        elif n in ("io_fromReqArb_status_s1_sets_1",):
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n in ("io_fromReqArb_status_s1_tags_1",):
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n.endswith("_bits_channel"):
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n == "io_d_task_valid":
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_d_ready":
            L.append(f"    {n} = ($urandom_range(0,2) != 0);")
        elif n == "io_e_valid":
            L.append(f"    {n} = ($urandom_range(0,2) == 0);")
        elif n == "io_prefetchResp_ready":
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n.endswith("_valid"):
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif nb <= 32:
            L.append(f"    {n} = $urandom;")
        else:
            words = (nb + 31) // 32
            cat = ", ".join(["$urandom"] * words)
            L.append(f"    {n} = {{{cat}}};")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic check_outputs();")
    for _, _, n in outs:
        L.append(f"    `CHK({n})")
    L.append("  endtask")
    L.append("")
    # internal probes: golden flat vs core arrays
    L.append("  int ierr = 0;")
    L.append("  `define IP(GP, IP) begin \\")
    L.append("    if (!$isunknown(u_g.GP)) begin \\")
    L.append("      if (u_g.GP !== u_i.u_core.IP) begin \\")
    L.append("        ierr++; \\")
    L.append("        if (ierr <= 40) $display(\"[%0t] IPROBE-DIFF %s g=%0h i=%0h\", $time, `\"GP`\", u_g.GP, u_i.u_core.IP); \\")
    L.append("      end \\")
    L.append("    end \\")
    L.append("  end")
    L.append("  task automatic check_internal();")
    for k in range(NINFL):
        L.append(f"    `IP(inflightGrant_{k}_valid,    inflightGrant_valid[{k}])")
        L.append(f"    `IP(inflightGrant_{k}_bits_set, inflightGrant_set[{k}])")
        L.append(f"    `IP(inflightGrant_{k}_bits_tag, inflightGrant_tag[{k}])")
    L.append("    `IP(grantBufValid,           grantBufValid)")
    L.append("    `IP(grantBuf_task_opcode,    grantBuf_task_opcode)")
    L.append("    `IP(grantBuf_task_param,     grantBuf_task_param)")
    L.append("    `IP(grantBuf_task_sourceId,  grantBuf_task_sourceId)")
    L.append("    `IP(grantBuf_task_isKeyword, grantBuf_task_isKeyword)")
    L.append("    `IP(grantBuf_task_denied,    grantBuf_task_denied)")
    L.append("    `IP(grantBuf_task_corrupt,   grantBuf_task_corrupt)")
    L.append("    `IP(grantBuf_grantid,        grantBuf_grantid)")
    L.append("    `IP(grantBuf_data_data,      grantBuf_data_data)")
    L.append("  endtask")
    L.append("")
    L.append("  initial begin")
    L.append("    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end")
    L.append("    reset = 1'b1;")
    for _, _, n in ins:
        L.append(f"    {n} = '0;")
    L.append("    repeat (5) @(posedge clock);")
    L.append("    reset = 1'b0;")
    L.append("    repeat (NCYCLES) begin")
    L.append("      @(negedge clock);")
    L.append("      drive_random();")
    L.append("      #1 check_outputs();")
    L.append("      check_internal();")
    L.append("      @(posedge clock);")
    L.append("    end")
    L.append("    $display(\"GrantBuffer checks=%0d errors=%0d ierr=%0d\", checks, errors, ierr);")
    L.append("    if (errors == 0 && ierr == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("`undef IP")
    L.append("")
    return "\n".join(L)


MAKEFILE = """MODULE = GrantBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/l2_task_pkg.sv $(RTL_DIR)/uncore/GrantBuffer.sv
# FIFO 叶: UT 用真叶(含行为 ram); FM 用真 Queue 但 ram_* 行为模型不进 FM(其越界
# 索引告警会被 Formality 升级为链接错误), ram 在两侧自动当黑盒。Queue 用真叶可消除
# unread 黑盒输出引脚(io_enq_ready 仅喂被裁剪的 assert)导致的 FM 比对点失配。
QUEUES = $(GOLDEN_RTL)/Queue16_GrantQueueTask.sv \\
         $(GOLDEN_RTL)/Queue16_GrantQueueData.sv \\
         $(GOLDEN_RTL)/Queue10_GrantBuffer_Anon.sv
RAMS   = $(GOLDEN_RTL)/ram_16x25.sv \\
         $(GOLDEN_RTL)/ram_data_16x256.sv \\
         $(GOLDEN_RTL)/ram_10x89.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/GrantBuffer_wrapper.sv $(QUEUES)

GOLDEN_SRCS = $(GOLDEN_RTL)/GrantBuffer.sv $(QUEUES) $(RAMS)
TB_SRCS = variants_xs.sv tb.sv

# FM: ref = golden GrantBuffer + 真 Queue 叶; ram_* 厂商宏两侧自动黑盒(不显式加载)
FM_VARIANTS = GrantBuffer
FM_REF_DEPS_GrantBuffer = Queue16_GrantQueueTask.sv Queue16_GrantQueueData.sv \\
    Queue10_GrantBuffer_Anon.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    (RTL / "l2_task_pkg.sv").write_text(gen_pkg())
    (RTL / "GrantBuffer.sv").write_text(gen_core())
    (RTL / "GrantBuffer_wrapper.sv").write_text(gen_wrapper("GrantBuffer"))
    (UT / "variants_xs.sv").write_text(gen_wrapper("GrantBuffer_xs"))
    (UT / "tb.sv").write_text(gen_tb())
    (UT / "Makefile").write_text(MAKEFILE)
    print("generated GrantBuffer: pkg/core/wrapper/variant/tb/Makefile;", len(FIELDS), "task fields")


if __name__ == "__main__":
    main()
