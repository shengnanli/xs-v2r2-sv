#!/usr/bin/env python3
"""生成 coupledL2 (tl2chi) RequestArb (s0/s1/s2 请求仲裁流水) 的核 / wrapper / 变体 / UT。

RequestArb 是 L2 slice 的 "请求入口仲裁" 单元(3 级流水, 无子模块):
  - s0: 收 MSHR 重发任务 mshrTask, 经 ready 反压锁存进 mshr_task_s1;
  - s1: 在 sinkA/sinkB/sinkC(上层 A/探测 B/释放 C) 与 mshr_task_s1 之间按优先级
        (C>B>A, 且 mshr 优先于通道) 选出 task_s1, 同拍发 Directory 读(dirRead_s1);
  - s2: task_s1 打一拍成 task_s2 送 MainPipe(taskToPipe_s2), 并据其类型发起
        refillBuf/releaseBuf 读请求。
  另产出: 各级 set/tag 状态(status_s1/status_vec[_toTX]) 供 MSHR/TX 做同址阻塞;
          s1Entrance 阻塞同 set 的 A 请求; 复位期 512 拍 resetIdx 计数门控通道入口。

无黑盒: 整体是纯流水仲裁 + 控制逻辑。可读核 xs_RequestArb_core 用 TaskBundle 结构体
(l2_task_pkg::task_bundle_t)做通道选择/逐级流水, 把 golden 中 ~90 字段逐项 Mux 收敛为
单条结构体 Mux。寄存器(mshr_task_s1 / task_s2)保持 golden 扁平命名以便 FM 逐 DFF 配对。
perf 计数(_GEN_*)不驱动输出, 省略。io_msInfo(dontTouch 保留但逻辑未用)为死输入, 核不收。

单态化(firtool): ways=8, sets=512(resetIdx 9bit), TaskBundle 见 l2_task_pkg。
样板: scripts/gen_grantbuffer.py (同套 TaskBundle 结构体 + 扁平寄存器方法)。
"""

import re
from pathlib import Path
from gen_grantbuffer import FIELDS, FW, sv, decl  # 复用 TaskBundle 字段表与工具

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "RequestArb"

NAMES = [n for n, _ in FIELDS]

# 非 task 的控制输入端口 (dir, width, name)
CTRL_IN = [
    ("input", "[30:0]", "io_ATag"), ("input", "[8:0]", "io_ASet"),
    ("input", "", "io_dirRead_s1_ready"),
    ("input", "", "io_fromMSHRCtl_blockG_s1"), ("input", "", "io_fromMSHRCtl_blockA_s1"),
    ("input", "", "io_fromMSHRCtl_blockB_s1"), ("input", "", "io_fromMSHRCtl_blockC_s1"),
    ("input", "", "io_fromMainPipe_blockG_s1"), ("input", "", "io_fromMainPipe_blockA_s1"),
    ("input", "", "io_fromMainPipe_blockB_s1"), ("input", "", "io_fromMainPipe_blockC_s1"),
    ("input", "", "io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1"),
    ("input", "", "io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1"),
    ("input", "", "io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1"),
    ("input", "", "io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1"),
    ("input", "", "io_fromGrantBuffer_blockMSHRReqEntrance"),
    ("input", "", "io_fromTXDAT_blockMSHRReqEntrance"),
    ("input", "", "io_fromTXDAT_blockSinkBReqEntrance"),
    ("input", "", "io_fromTXRSP_blockMSHRReqEntrance"),
    ("input", "", "io_fromTXRSP_blockSinkBReqEntrance"),
    ("input", "", "io_fromTXREQ_blockMSHRReqEntrance"),
]

# 输出端口 (dir, width, name)  —— dirRead / status / refill / release / s1Entrance / ready
CTRL_OUT = [
    ("output", "", "io_sinkA_ready"), ("output", "", "io_sinkB_ready"),
    ("output", "", "io_sinkC_ready"), ("output", "", "io_mshrTask_ready"),
    ("output", "", "io_s1Entrance_valid"), ("output", "[8:0]", "io_s1Entrance_bits_set"),
    ("output", "", "io_dirRead_s1_valid"), ("output", "[30:0]", "io_dirRead_s1_bits_tag"),
    ("output", "[8:0]", "io_dirRead_s1_bits_set"), ("output", "[7:0]", "io_dirRead_s1_bits_wayMask"),
    ("output", "[2:0]", "io_dirRead_s1_bits_replacerInfo_channel"),
    ("output", "[2:0]", "io_dirRead_s1_bits_replacerInfo_opcode"),
    ("output", "[4:0]", "io_dirRead_s1_bits_replacerInfo_reqSource"),
    ("output", "", "io_dirRead_s1_bits_replacerInfo_refill_prefetch"),
    ("output", "", "io_dirRead_s1_bits_refill"), ("output", "[7:0]", "io_dirRead_s1_bits_mshrId"),
    ("output", "", "io_dirRead_s1_bits_cmoAll"), ("output", "[2:0]", "io_dirRead_s1_bits_cmoWay"),
    ("output", "", "io_refillBufRead_s2_valid"), ("output", "[7:0]", "io_refillBufRead_s2_bits_id"),
    ("output", "", "io_releaseBufRead_s2_valid"), ("output", "[7:0]", "io_releaseBufRead_s2_bits_id"),
    ("output", "[30:0]", "io_status_s1_tags_0"), ("output", "[30:0]", "io_status_s1_tags_1"),
    ("output", "[30:0]", "io_status_s1_tags_2"), ("output", "[30:0]", "io_status_s1_tags_3"),
    ("output", "[8:0]", "io_status_s1_sets_0"), ("output", "[8:0]", "io_status_s1_sets_1"),
    ("output", "[8:0]", "io_status_s1_sets_2"), ("output", "[8:0]", "io_status_s1_sets_3"),
    ("output", "", "io_status_vec_0_valid"), ("output", "[2:0]", "io_status_vec_0_bits_channel"),
    ("output", "", "io_status_vec_1_valid"), ("output", "[2:0]", "io_status_vec_1_bits_channel"),
    ("output", "", "io_status_vec_toTX_0_valid"),
    ("output", "[2:0]", "io_status_vec_toTX_0_bits_channel"),
    ("output", "[2:0]", "io_status_vec_toTX_0_bits_txChannel"),
    ("output", "", "io_status_vec_toTX_0_bits_mshrTask"),
    ("output", "", "io_status_vec_toTX_1_valid"),
    ("output", "[2:0]", "io_status_vec_toTX_1_bits_channel"),
    ("output", "[2:0]", "io_status_vec_toTX_1_bits_txChannel"),
    ("output", "", "io_status_vec_toTX_1_bits_mshrTask"),
]


def core_ports():
    P = ["  input  logic        clock,", "  input  logic        reset,"]
    for src in ("sinkA", "sinkB", "sinkC", "mshrTask"):
        P.append(f"  // ---- io.{src} (Flipped Decoupled TaskBundle) ----")
        P.append(f"  output logic        io_{src}_ready," if src != "mshrTask"
                 else f"  output logic        io_{src}_ready,  // (在输出段集中赋值, 此处占位声明顺序)")
        P.append(f"  input  logic        io_{src}_valid,")
        for n, w in FIELDS:
            P.append(f"  input  logic {decl(w):<7}io_{src}_bits_{n},")
    P.append("  // ---- 其余控制输入 ----")
    for d, w, n in CTRL_IN:
        P.append(f"  input  logic {decl(width_bits(w)):<7}{n},")
    P.append("  // ---- 输出 ----")
    outs = [o for o in CTRL_OUT if not o[2].endswith("_ready")]  # ready 已在上面声明
    last_idx = len(outs) - 1
    # taskToPipe_s2 / taskInfo_s1 全字段输出
    body = []
    for d, w, n in outs:
        body.append(f"  output logic {decl(width_bits(w)):<7}{n},")
    body.append("  // taskToPipe_s2 (= task_s2 全字段)")
    body.append("  output logic        io_taskToPipe_s2_valid,")
    for n, w in FIELDS:
        body.append(f"  output logic {decl(w):<7}io_taskToPipe_s2_bits_{n},")
    body.append("  // taskInfo_s1 (= task_s1 全字段)")
    body.append("  output logic        io_taskInfo_s1_valid,")
    for i, (n, w) in enumerate(FIELDS):
        comma = "," if i + 1 < len(FIELDS) else ""
        body.append(f"  output logic {decl(w):<7}io_taskInfo_s1_bits_{n}{comma}")
    P += body
    return "\n".join(P)


def width_bits(w):
    if not w:
        return 1
    mm = re.match(r"\[(\d+):(\d+)\]", w)
    return abs(int(mm.group(1)) - int(mm.group(2))) + 1


def pack_block(src, dst):
    """把扁平 io_<src>_bits_<f> 打包进结构体 dst。"""
    L = [f"  task_bundle_t {dst};", "  always_comb begin"]
    for n, _ in FIELDS:
        L.append(f"    {dst}.{sv(n):<22} = io_{src}_bits_{n};")
    L.append("  end")
    return "\n".join(L)


def gen_core():
    L = []
    L.append("// 自动生成 scripts/gen_requestarb.py —— 勿手改")
    L.append("// =============================================================================")
    L.append("//  RequestArb —— coupledL2 (tl2chi) L2 slice s0/s1/s2 请求仲裁流水 可读重写核")
    L.append("//          (xs_RequestArb_core)")
    L.append("// -----------------------------------------------------------------------------")
    L.append("//  对照 Scala: coupledL2/src/main/scala/coupledL2/RequestArb.scala")
    L.append("//  无子模块, 纯流水仲裁。通道选择/逐级流水用 TaskBundle 结构体收敛逐字段 Mux。")
    L.append("//  ===== X 铁律 =====")
    L.append("//    resetFinish/resetIdx/mshr_task_s1_valid/task_s2_valid 异步复位; resetIdx=511")
    L.append("//    倒数 512 拍门控通道入口; ds_mcp2_stall 为无复位 RegNext(initreg+0 起 0)。")
    L.append("// =============================================================================")
    L.append("module xs_RequestArb_core")
    L.append("  import l2_task_pkg::*;")
    L.append("(")
    L.append(core_ports())
    L.append(");")
    L.append("")
    # 打包 4 个任务源
    L.append("  // ===== 打包扁平通道/MSHR 输入为 TaskBundle 结构体 =====")
    L.append(pack_block("sinkA", "A_task"))
    L.append(pack_block("sinkB", "B_task"))
    L.append(pack_block("sinkC", "C_task"))
    L.append(pack_block("mshrTask", "mshrTask_in"))
    L.append("")
    # 寄存器声明 (扁平, golden 命名, 便于 FM 逐 DFF 配对)
    L.append("  // ===== 流水寄存器(扁平 golden 命名, FM 逐 DFF 配对) =====")
    L.append("  logic        resetFinish;")
    L.append("  logic [8:0]  resetIdx;")
    L.append("  logic        ds_mcp2_stall;   // 无复位 RegNext: 上一拍非 AHint 的 s1_fire(防连续 DS 访问)")
    L.append("  logic        mshr_task_s1_valid;")
    for n, w in FIELDS:
        L.append(f"  logic {decl(w):<7}mshr_task_s1_bits_{n};")
    L.append("  logic        task_s2_valid;")
    for n, w in FIELDS:
        L.append(f"  logic {decl(w):<7}task_s2_bits_{n};")
    L.append("")
    # mshr_task_s1 结构体视图 (供通道 Mux)
    L.append("  // mshr_task_s1 扁平寄存器的结构体视图(供 task_s1 选择)")
    L.append("  task_bundle_t mshr_task_s1;")
    L.append("  always_comb begin")
    for n, _ in FIELDS:
        L.append(f"    mshr_task_s1.{sv(n):<22} = mshr_task_s1_bits_{n};")
    L.append("  end")
    L.append("")
    # 控制逻辑
    L.append("  // ===== s1: 是否为需读替换路的 MSHR refill 任务(Grant/GrantData/AccessAckData/HintAck) =====")
    L.append("  wire opcode_is_hintAck = mshr_task_s1_bits_opcode == 4'h2;")
    L.append("  wire s1_needs_replRead =")
    L.append("    mshr_task_s1_valid & mshr_task_s1.channel[0] & mshr_task_s1_bits_replTask &")
    L.append("    (mshr_task_s1_bits_opcode == 4'h4 | mshr_task_s1_bits_opcode == 4'h5 |")
    L.append("     mshr_task_s1_bits_opcode == 4'h1 | opcode_is_hintAck);")
    L.append("  // replRead 需等 dirRead.ready 且 MainPipe 不阻塞 G, 期间 stall")
    L.append("  wire mshr_replRead_stall =")
    L.append("    mshr_task_s1_valid & s1_needs_replRead &")
    L.append("    (~io_dirRead_s1_ready | io_fromMainPipe_blockG_s1);")
    L.append("")
    L.append("  // ===== s0: mshrTask 入口 ready / fire =====")
    L.append("  wire io_mshrTask_ready_0 =")
    L.append("    ~io_fromGrantBuffer_blockMSHRReqEntrance & ~s1_needs_replRead &")
    L.append("    ~(mshr_task_s1_valid & ds_mcp2_stall) & ~io_fromTXDAT_blockMSHRReqEntrance &")
    L.append("    ~io_fromTXRSP_blockMSHRReqEntrance & ~io_fromTXREQ_blockMSHRReqEntrance;")
    L.append("  wire s0_fire = io_mshrTask_valid & io_mshrTask_ready_0;")
    L.append("")
    L.append("  // ===== s1: 通道阻塞 + 优先级(C>B>A) =====")
    L.append("  wire block_A = io_fromMSHRCtl_blockA_s1 | io_fromMainPipe_blockA_s1 |")
    L.append("                 io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1;")
    L.append("  wire block_B = io_fromMSHRCtl_blockB_s1 | io_fromMainPipe_blockB_s1 |")
    L.append("                 io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1 |")
    L.append("                 io_fromTXDAT_blockSinkBReqEntrance | io_fromTXRSP_blockSinkBReqEntrance;")
    L.append("  wire block_C = io_fromMSHRCtl_blockC_s1 | io_fromMainPipe_blockC_s1 |")
    L.append("                 io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1;")
    L.append("  wire selC = io_sinkC_valid & ~block_C;   // C 最高")
    L.append("  wire selB = io_sinkB_valid & ~block_B;")
    L.append("  wire selA = io_sinkA_valid & ~block_A;")
    L.append("  // 基本就绪: dir 可读 & 复位完成 & 无在途 mshr_s1 & 无 DS 连访 stall")
    L.append("  wire sink_ready_basic =")
    L.append("    io_dirRead_s1_ready & resetFinish & ~mshr_task_s1_valid & ~ds_mcp2_stall;")
    L.append("  wire io_sinkA_ready_0 = sink_ready_basic & ~block_A & ~selB & ~selC;")
    L.append("  wire io_sinkB_ready_0 = sink_ready_basic & ~block_B & ~selC;")
    L.append("  wire io_sinkC_ready_0 = sink_ready_basic & ~block_C;")
    L.append("  wire chnl_task_s1_valid = io_dirRead_s1_ready & (selA | selB | selC) & resetFinish;")
    L.append("")
    L.append("  // ===== 通道优先选择 + mshr 优先 → task_s1 (结构体 Mux 收敛逐字段) =====")
    L.append("  task_bundle_t chnl_task_s1, task_s1;")
    L.append("  assign chnl_task_s1 = selC ? C_task : (selB ? B_task : A_task);")
    L.append("  assign task_s1      = mshr_task_s1_valid ? mshr_task_s1 : chnl_task_s1;")
    L.append("  wire task_s1_valid  = mshr_task_s1_valid ? 1'b1 : chnl_task_s1_valid;")
    L.append("")
    L.append("  // ===== s1_fire / s2_ready =====")
    L.append("  wire s1_fire = task_s1_valid & ~mshr_replRead_stall & ~ds_mcp2_stall;")
    L.append("  // sinkA Hint(opcode==5) fire 不引发 DS 连访 stall")
    L.append("  wire sinkA_fire = io_sinkA_ready_0 & io_sinkA_valid;")
    L.append("  wire sinkB_fire = io_sinkB_ready_0 & io_sinkB_valid;")
    L.append("  wire sinkC_fire = io_sinkC_ready_0 & io_sinkC_valid;")
    L.append("")
    # 时序
    L.append("  // ===== 时序: 复位计数 / mshr_task_s1 锁存 / task_s2 锁存 =====")
    L.append("  always_ff @(posedge clock or posedge reset) begin")
    L.append("    if (reset) begin")
    L.append("      resetFinish        <= 1'b0;")
    L.append("      resetIdx           <= 9'h1FF;")
    L.append("      mshr_task_s1_valid <= 1'b0;")
    for n, w in FIELDS:
        L.append(f"      mshr_task_s1_bits_{n} <= '0;")
    L.append("      task_s2_valid      <= 1'b0;")
    for n, w in FIELDS:
        L.append(f"      task_s2_bits_{n} <= '0;")
    L.append("    end else begin")
    L.append("      resetFinish <= (resetIdx == 9'h0) | resetFinish;")
    L.append("      if (~resetFinish) resetIdx <= resetIdx - 9'h1;")
    L.append("      // mshr_task_s1: s1_fire 清(除非同拍 s0 再入), s0_fire 装载")
    L.append("      mshr_task_s1_valid <= (mshr_task_s1_valid & ~s1_fire) | s0_fire;")
    L.append("      if (s0_fire) begin")
    for n, w in FIELDS:
        L.append(f"        mshr_task_s1_bits_{n} <= io_mshrTask_bits_{n};")
    L.append("      end")
    L.append("      // task_s2: s1_fire 时锁存 task_s1")
    L.append("      task_s2_valid <= s1_fire;")
    L.append("      if (s1_fire) begin")
    for n, w in FIELDS:
        L.append(f"        task_s2_bits_{n} <= task_s1.{sv(n)};")
    L.append("      end")
    L.append("    end")
    L.append("  end")
    L.append("  // ds_mcp2_stall 为无复位 RegNext (Chisel RegNext 无初值)")
    L.append("  always_ff @(posedge clock)")
    L.append("    ds_mcp2_stall <= s1_fire & ~(sinkA_fire & io_sinkA_bits_opcode == 4'h5);")
    L.append("")
    # 输出
    L.append("  // ===== s2 类型译码: 是否读 refillBuf/releaseBuf =====")
    L.append("  wire mshrTask_s2 = task_s2_valid & task_s2_bits_mshrTask;")
    L.append("  // a_upwards: 上行 A 响应(GrantData / Grant&dsWen / AccessAckData / HintAck&dsWen)")
    L.append("  wire mshrTask_s2_a_upwards =")
    L.append("    task_s2_bits_channel[0] &")
    L.append("    (task_s2_bits_opcode == 4'h5 | (task_s2_bits_opcode == 4'h4 & task_s2_bits_dsWen) |")
    L.append("     task_s2_bits_opcode == 4'h1 | (task_s2_bits_opcode == 4'h2 & task_s2_bits_dsWen));")
    L.append("")
    L.append("  // ===== 输出: 握手 ready =====")
    L.append("  assign io_sinkA_ready   = io_sinkA_ready_0;")
    L.append("  assign io_sinkB_ready   = io_sinkB_ready_0;")
    L.append("  assign io_sinkC_ready   = io_sinkC_ready_0;")
    L.append("  assign io_mshrTask_ready = io_mshrTask_ready_0;")
    L.append("")
    L.append("  // ===== 输出: s1Entrance(阻塞同 set 的后续 A) =====")
    L.append("  assign io_s1Entrance_valid =")
    L.append("    (mshr_task_s1_valid & ~ds_mcp2_stall & mshr_task_s1_bits_metaWen) |")
    L.append("    sinkC_fire | sinkB_fire;")
    L.append("  assign io_s1Entrance_bits_set =")
    L.append("    (mshr_task_s1_valid & mshr_task_s1_bits_metaWen) ? mshr_task_s1_bits_set :")
    L.append("    (sinkC_fire ? io_sinkC_bits_set : io_sinkB_bits_set);")
    L.append("")
    L.append("  // ===== 输出: Directory 读请求 dirRead_s1 =====")
    L.append("  assign io_dirRead_s1_valid =")
    L.append("    ~ds_mcp2_stall & ((chnl_task_s1_valid & ~mshr_task_s1_valid) |")
    L.append("                      (s1_needs_replRead & ~io_fromMainPipe_blockG_s1));")
    L.append("  assign io_dirRead_s1_bits_tag = task_s1.tag;")
    L.append("  assign io_dirRead_s1_bits_set = task_s1.set;")
    L.append("  // wayMask: mshrRetry 时屏蔽冲突 way (~(1<<way)), 否则全 1")
    L.append("  wire [14:0] wayMask_oh = 15'h1 << mshr_task_s1_bits_way;")
    L.append("  assign io_dirRead_s1_bits_wayMask =")
    L.append("    ~({8{mshr_task_s1_valid & mshr_task_s1_bits_mshrRetry}} & wayMask_oh[7:0]);")
    L.append("  assign io_dirRead_s1_bits_replacerInfo_channel  = task_s1.channel;")
    L.append("  assign io_dirRead_s1_bits_replacerInfo_opcode   = task_s1.opcode[2:0];")
    L.append("  assign io_dirRead_s1_bits_replacerInfo_reqSource = task_s1.reqSource;")
    L.append("  assign io_dirRead_s1_bits_replacerInfo_refill_prefetch =")
    L.append("    s1_needs_replRead & opcode_is_hintAck & mshr_task_s1_bits_dsWen;")
    L.append("  assign io_dirRead_s1_bits_refill = s1_needs_replRead;")
    L.append("  assign io_dirRead_s1_bits_mshrId = task_s1.mshrId;")
    L.append("  assign io_dirRead_s1_bits_cmoAll = task_s1.cmoAll;")
    L.append("  assign io_dirRead_s1_bits_cmoWay = task_s1.way;")
    L.append("")
    L.append("  // ===== 输出: taskToPipe_s2 (= task_s2 全字段) =====")
    L.append("  assign io_taskToPipe_s2_valid = task_s2_valid;")
    for n, _ in FIELDS:
        L.append(f"  assign io_taskToPipe_s2_bits_{n} = task_s2_bits_{n};")
    L.append("")
    L.append("  // ===== 输出: taskInfo_s1 (= task_s1 全字段, 给 MainPipe 提前 hint) =====")
    L.append("  assign io_taskInfo_s1_valid = s1_fire;")
    for n, _ in FIELDS:
        L.append(f"  assign io_taskInfo_s1_bits_{n} = task_s1.{sv(n)};")
    L.append("")
    L.append("  // ===== 输出: refillBuf / releaseBuf 读 =====")
    L.append("  // refillBuf: replTask 回 TX(txChannel[0]) 的写回族(WriteBackFull/WriteEvict*/Evict)")
    L.append("  //            或上行 A 响应且非用 ProbeData")
    L.append("  assign io_refillBufRead_s2_valid =")
    L.append("    mshrTask_s2 &")
    L.append("    ((task_s2_bits_replTask & task_s2_bits_txChannel[0] &")
    L.append("      (task_s2_bits_chiOpcode == 7'h1B | task_s2_bits_chiOpcode == 7'h15 |")
    L.append("       task_s2_bits_chiOpcode == 7'h42 | task_s2_bits_chiOpcode == 7'hD)) |")
    L.append("     (mshrTask_s2_a_upwards & ~task_s2_bits_useProbeData));")
    L.append("  assign io_refillBufRead_s2_bits_id = task_s2_bits_mshrId;")
    L.append("  // releaseBuf: mshr 任务读 ProbeData 下行/上行用 ProbeData; 或非 mshr 的 B 探测命中带数据释放")
    L.append("  assign io_releaseBufRead_s2_valid =")
    L.append("    task_s2_valid &")
    L.append("    (mshrTask_s2 ? (task_s2_bits_readProbeDataDown |")
    L.append("                    (mshrTask_s2_a_upwards & task_s2_bits_useProbeData)) :")
    L.append("                   (~mshrTask_s2 & task_s2_bits_channel[1] &")
    L.append("                    task_s2_bits_snpHitReleaseWithData));")
    L.append("  assign io_releaseBufRead_s2_bits_id =")
    L.append("    task_s2_bits_snpHitRelease ? task_s2_bits_snpHitReleaseIdx : task_s2_bits_mshrId;")
    L.append("")
    L.append("  // ===== 输出: 各级 set/tag 状态(给 MSHR/TX 同址阻塞) =====")
    L.append("  assign io_status_s1_tags_0 = io_sinkC_bits_tag;")
    L.append("  assign io_status_s1_tags_1 = io_sinkB_bits_tag;")
    L.append("  assign io_status_s1_tags_2 = io_ATag;")
    L.append("  assign io_status_s1_tags_3 = mshr_task_s1_bits_tag;")
    L.append("  assign io_status_s1_sets_0 = io_sinkC_bits_set;")
    L.append("  assign io_status_s1_sets_1 = io_sinkB_bits_set;")
    L.append("  assign io_status_s1_sets_2 = io_ASet;")
    L.append("  assign io_status_s1_sets_3 = mshr_task_s1_bits_set;")
    L.append("  assign io_status_vec_0_valid        = task_s1_valid;")
    L.append("  assign io_status_vec_0_bits_channel = task_s1.channel;")
    L.append("  assign io_status_vec_1_valid        = task_s2_valid;")
    L.append("  assign io_status_vec_1_bits_channel = task_s2_bits_channel;")
    L.append("  assign io_status_vec_toTX_0_valid         = task_s1_valid;")
    L.append("  assign io_status_vec_toTX_0_bits_channel  = task_s1.channel;")
    L.append("  assign io_status_vec_toTX_0_bits_txChannel = task_s1.txChannel;")
    L.append("  assign io_status_vec_toTX_0_bits_mshrTask  = task_s1.mshrTask;")
    L.append("  assign io_status_vec_toTX_1_valid         = task_s2_valid;")
    L.append("  assign io_status_vec_toTX_1_bits_channel  = task_s2_bits_channel;")
    L.append("  assign io_status_vec_toTX_1_bits_txChannel = task_s2_bits_txChannel;")
    L.append("  assign io_status_vec_toTX_1_bits_mshrTask  = task_s2_bits_mshrTask;")
    L.append("")
    L.append("endmodule")
    L.append("")
    return "\n".join(L)


def gold_ports():
    text = (GOLDEN / "RequestArb.sv").read_text()
    m = re.search(r"module\s+RequestArb\s*\((.*?)\n\);", text, re.S)
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
    # 核端口名集合: 除 io_msInfo* 外全部
    core_in = [p for p in P if p[0] == "input" and not p[2].startswith("io_msInfo")
               and p[2] not in ("clock", "reset")]
    core_out = [p for p in P if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_requestarb.py —— 勿手改")
    L.append(f"// {top}: golden 同名壳 = 可读核 xs_RequestArb_core 直例化(无子模块)。")
    L.append("// io_msInfo*(dontTouch 保留、逻辑未用)为死输入, 核不收, 此处悬空。")
    L.append(f"module {top}(")
    L.append(",\n".join(f"  {d} {w}{' ' if w else ''}{n}" for d, w, n in P))
    L.append(");")
    L.append("")
    L.append("  xs_RequestArb_core u_core (")
    conns = [".clock(clock)", ".reset(reset)"]
    for d, w, n in core_in:
        conns.append(f".{n}({n})")
    for d, w, n in core_out:
        conns.append(f".{n}({n})")
    for i, c in enumerate(conns):
        L.append(f"    {c}{',' if i + 1 < len(conns) else ''}")
    L.append("  );")
    L.append("endmodule")
    L.append("")
    return "\n".join(L)


def gen_tb():
    P = gold_ports()
    ins = [p for p in P if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in P if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_requestarb.py —— 勿手改")
    L.append("// RequestArb 双例化逐拍比对: golden RequestArb vs 可读重写 RequestArb_xs。")
    L.append("// 偏置 opcode/set/tag 偏小, 通道/MSHR/block 随机, 覆盖优先级仲裁/replRead stall/mcp2。")
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
    for instname, pfx in (("RequestArb", "g_"), ("RequestArb_xs", "i_")):
        L.append(f"  {instname} u_{pfx[0]} (")
        for i, (d, _, n) in enumerate(P):
            c = "," if i + 1 < len(P) else ""
            sig = n if (n in ("clock", "reset") or d == "input") else f"{pfx}{n}"
            L.append(f"    .{n}({sig}){c}")
        L.append("  );")
    L.append("")
    L.append("  task automatic drive_random();")
    for _, w, n in ins:
        nb = width_bits(w)
        if n.endswith("_bits_opcode") and "aMergeTask" not in n:
            L.append(f"    {n} = $urandom_range(0,5);")
        elif n.endswith("_bits_set") and "aMergeTask" not in n:
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n.endswith("_bits_tag"):
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n in ("io_ATag", "io_ASet"):
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n.endswith("_bits_way"):
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n.endswith("_valid"):
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_dirRead_s1_ready":
            L.append(f"    {n} = ($urandom_range(0,2) != 0);")
        elif n.startswith("io_from"):
            L.append(f"    {n} = ($urandom_range(0,3) == 0);")
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
    # internal probes: golden flat == core flat (same names under u_core)
    L.append("  int ierr = 0;")
    L.append("  `define IP(SIG) begin \\")
    L.append("    if (!$isunknown(u_g.SIG)) begin \\")
    L.append("      if (u_g.SIG !== u_i.u_core.SIG) begin \\")
    L.append("        ierr++; \\")
    L.append("        if (ierr <= 40) $display(\"[%0t] IPROBE-DIFF %s g=%0h i=%0h\", $time, `\"SIG`\", u_g.SIG, u_i.u_core.SIG); \\")
    L.append("      end \\")
    L.append("    end \\")
    L.append("  end")
    L.append("  task automatic check_internal();")
    for s in ["resetFinish", "resetIdx", "ds_mcp2_stall", "mshr_task_s1_valid", "task_s2_valid"]:
        L.append(f"    `IP({s})")
    for n, _ in FIELDS:
        L.append(f"    `IP(mshr_task_s1_bits_{n})")
        L.append(f"    `IP(task_s2_bits_{n})")
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
    L.append("    $display(\"RequestArb checks=%0d errors=%0d ierr=%0d\", checks, errors, ierr);")
    L.append("    if (errors == 0 && ierr == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("`undef IP")
    L.append("")
    return "\n".join(L)


MAKEFILE = """MODULE = RequestArb

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/l2_task_pkg.sv $(RTL_DIR)/uncore/RequestArb.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/RequestArb_wrapper.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RequestArb.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: 无子模块, ref = golden RequestArb 本体
FM_VARIANTS = RequestArb
FM_REF_DEPS_RequestArb =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    (RTL / "RequestArb.sv").write_text(gen_core())
    (RTL / "RequestArb_wrapper.sv").write_text(gen_wrapper("RequestArb"))
    (UT / "variants_xs.sv").write_text(gen_wrapper("RequestArb_xs"))
    (UT / "tb.sv").write_text(gen_tb())
    (UT / "Makefile").write_text(MAKEFILE)
    print("generated RequestArb: core/wrapper/variant/tb/Makefile")


if __name__ == "__main__":
    main()
