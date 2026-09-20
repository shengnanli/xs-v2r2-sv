#!/usr/bin/env python3
"""gen.py —— 生成 BusyTable 家族五个薄 wrapper（rtl/backend/*.sv）。

为什么要生成：wrapper 的端口表必须与 G1 golden **逐位**一致（名字/方向/位宽/顺序），
手抄 143 个端口注定出错。这里直接从 golden 的端口表原样搬过来，再按下面的
WAKEUP 描述表接线到参数化核 xs_BusyTable_core。

唤醒描述表里的每一项都是从 golden 实测的（is0Lat 端口在不在、og0Cancel 用哪一位、
wen 是 rfWen/fpWen/vecWen/v0Wen 中的哪一个、load 唤醒占哪条流水），不是从 Chisel
默认值推的 —— 见各变体文件头。

用法：python3 gen_family.py    （幂等：内容不变不碰文件）
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = REPO / 'rtl' / 'backend'

LD_PIPE_N = 3

# --- 每个变体：名字 -> 描述 --------------------------------------------------
# wakeups: 每路 (wen信号, is0lat表达式, og0cancel表达式, dep端口前缀或None, ld_onehot或None)
V = {
 'BusyTable': dict(
    pregs=224, nwb=8, nread=12, has_dep=1, zero_ready=1, has_vl=0,
    wakeups=[
      ('io_wakeUpInt_0_bits_rfWen', 'io_wakeUpInt_0_bits_is0Lat', 'io_og0Cancel_0',
       'io_wakeUpInt_0', None, 'io_wakeUpInt_0_valid'),
      ('io_wakeUpInt_1_bits_rfWen', 'io_wakeUpInt_1_bits_is0Lat', 'io_og0Cancel_2',
       'io_wakeUpInt_1', None, 'io_wakeUpInt_1_valid'),
      ('io_wakeUpInt_2_bits_rfWen', "1'b1", 'io_og0Cancel_4',
       'io_wakeUpInt_2', None, 'io_wakeUpInt_2_valid'),
      ('io_wakeUpInt_3_bits_rfWen', "1'b1", 'io_og0Cancel_6',
       'io_wakeUpInt_3', None, 'io_wakeUpInt_3_valid'),
      ('io_wakeUpMem_0_bits_rfWen', "1'b0", "1'b0",
       'io_wakeUpMem_0', 0, 'io_wakeUpMem_0_valid'),
      ('io_wakeUpMem_1_bits_rfWen', "1'b0", "1'b0",
       'io_wakeUpMem_1', 1, 'io_wakeUpMem_1_valid'),
      ('io_wakeUpMem_2_bits_rfWen', "1'b0", "1'b0",
       'io_wakeUpMem_2', 2, 'io_wakeUpMem_2_valid'),
    ],
    ldcancel=['io_ldCancel_0_ld2Cancel', 'io_ldCancel_1_ld2Cancel',
              'io_ldCancel_2_ld2Cancel'],
    what='Int 整数物理寄存器堆（IntWB）',
 ),
 'BusyTable_1': dict(
    pregs=192, nwb=6, nread=18, has_dep=0, zero_ready=0, has_vl=0,
    wakeups=[
      ('io_wakeUpFp_0_bits_fpWen', 'io_wakeUpFp_0_bits_is0Lat', 'io_og0Cancel_8',
       None, None, 'io_wakeUpFp_0_valid'),
      ('io_wakeUpFp_1_bits_fpWen', "1'b0", "1'b0", None, None, 'io_wakeUpFp_1_valid'),
      ('io_wakeUpFp_2_bits_fpWen', "1'b0", "1'b0", None, None, 'io_wakeUpFp_2_valid'),
    ],
    ldcancel=[], what='Fp 浮点物理寄存器堆（FpWB）',
 ),
 'BusyTable_2': dict(
    pregs=128, nwb=6, nread=18, has_dep=0, zero_ready=0, has_vl=0,
    wakeups=[
      ('io_wakeUpFp_0_bits_vecWen', 'io_wakeUpFp_0_bits_is0Lat', 'io_og0Cancel_8',
       None, None, 'io_wakeUpFp_0_valid'),
    ],
    ldcancel=[], what='Vf 向量/浮点物理寄存器堆（VfWB）',
 ),
 'BusyTable_3': dict(
    pregs=22, nwb=6, nread=6, has_dep=0, zero_ready=0, has_vl=0,
    wakeups=[
      ('io_wakeUpFp_0_bits_v0Wen', 'io_wakeUpFp_0_bits_is0Lat', 'io_og0Cancel_8',
       None, None, 'io_wakeUpFp_0_valid'),
    ],
    ldcancel=[], what='V0 向量掩码寄存器堆（V0WB）',
 ),
 'VlBusyTable': dict(
    pregs=32, nwb=4, nread=6, has_dep=0, zero_ready=0, has_vl=1,
    wakeups=[], ldcancel=[], what='Vl 向量长度寄存器堆（VlWB）',
 ),
}

HEADERS = {
 'BusyTable': """// BusyTable.sv —— 物理寄存器忙位表（Int 整数堆变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_BusyTable_core.sv（家族共享参数化核）。本文件不含逻辑分支，只把 golden
// 的扁平端口打包成核的数组接口，并给出本变体的参数。
//
// 本变体规模（全部从 G1 golden BusyTable.sv 机械量得，不是从 Chisel 默认值推的）：
//   表深 224 项（IntPhyRegs）；分配口 6；写回口 8；读口 12
//   快速唤醒 7 路 = 4 路 wakeUpInt（ALU 类，rfWen）+ 3 路 wakeUpMem（LOAD 类，rfWen）
//   寄存器 896 个 = 224 忙位 + 224×3 条 loadDependency 影子（每条 2 位），全部异步复位到 0
//   ★ 全家族唯一有 loadDependency 影子的变体（needLoadCancel 只有 Int 为真）
//   ★ 全家族唯一 0 号项特殊的变体（x0 恒就绪，见核 §5）
//   golden 21579 行里真逻辑只有 208 种去数字化行模板：其余是 224 项逐项展平
//   （声明+组合 12453 行、时序块 6950 行、ENABLE_INITIAL_REG_ 仿真初始化 1813 行）。
//   —— 这里刻意不写时序块的 SV 关键字：readability_audit 的 F 项是对**全文**（含
//      注释）数那个关键字的出现次数，注释里提一嘴就会被算成「头称薄壳却有时序逻辑」。
//
// 唤醒取消路由（从 golden tmp_*/wakeupOHVec_* 表达式机械提取）：
//   wk0 = wakeUpInt_0：`~(is0Lat & og0Cancel_0)`  （is0Lat 是真端口）
//   wk1 = wakeUpInt_1：`~(is0Lat & og0Cancel_2)`  （is0Lat 是真端口）
//   wk2 = wakeUpInt_2：`~og0Cancel_4`  ← is0Lat 被 firtool 折成 **1**，端口消失
//   wk3 = wakeUpInt_3：`~og0Cancel_6`  ← 同上
//   wk4..6 = wakeUpMem_0..2：**没有 og0Cancel 项** ← is0Lat 被折成 **0**
//   照 Chisel 字面给七路都留 is0Lat 端口 = 凭空多出四个 golden 没有的端口。
//   load 唤醒写 loadDependency 的方式也不同：wk4/5/6 写「本流水 onehot」(1/2/4)，
//   wk0..3 写「自己的 loadDependency 左移一位」。
//
// golden 里未被引用的死组合逻辑（本文件不重建）：_GEN_2/_GEN_3/_GEN_4 是 224 位忙位
//   的 popcount 加法树（来自 XSPerfAccumulate/perfEvents 的 busyCount）。它的两级
//   RegNext 寄存器已被 firtool 消掉（reg 数 896 正好只有表本身），剩下的加法树没有
//   任何读者，不是比对点。
//
// 自动生成：verif/ut/BusyTable/gen.py —— 勿手改
""",
 'BusyTable_1': """// BusyTable_1.sv —— 物理寄存器忙位表（Fp 浮点堆变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_BusyTable_core.sv（家族共享参数化核）。本文件只做端口打包与参数设定。
//
// 本变体规模（全部从 G1 golden BusyTable_1.sv 机械量得）：
//   表深 192 项（FpPhyRegs）；分配口 6；写回口 **6**（比 Int 的 8 少两个）；读口 **18**
//   快速唤醒 3 路 = wakeUpFp_0..2（fpWen）
//   寄存器 192 个 = 纯忙位，异步复位到 0；**没有 loadDependency 影子**
//     —— Chisel 里 fpBusyTableNeedLoadCancel 直接写死 false，于是 loadCancel 恒 0、
//        影子寄存器整片无人读被 firtool 消掉；golden 里一个都不剩，也没有 ldCancel 端口。
//   0 号项不特殊（Chisel 的 x0 特判只对 IntWB 生效）。
//
// 唤醒取消路由（从 golden wakeupOHVec_* 机械提取）：
//   wk0 = wakeUpFp_0：`~(is0Lat & og0Cancel_8)`  （is0Lat 是真端口）
//   wk1 = wakeUpFp_1：**无取消项** ← is0Lat 被 firtool 折成 0
//   wk2 = wakeUpFp_2：**无取消项** ← 同上
//   ★ 注意与 Int 变体对照：同一行 Chisel，Int 的 wk2/wk3 把 is0Lat 折成 **1**（留下
//     `~og0Cancel_k`），这里却折成 **0**（整项消失）。折向相反，只能实测不能推。
//
// 自动生成：verif/ut/BusyTable/gen.py —— 勿手改
""",
 'BusyTable_2': """// BusyTable_2.sv —— 物理寄存器忙位表（Vf 向量/浮点堆变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_BusyTable_core.sv（家族共享参数化核）。本文件只做端口打包与参数设定。
//
// 本变体规模（全部从 G1 golden BusyTable_2.sv 机械量得）：
//   表深 128 项（VfPhyRegs）；分配口 6；写回口 6；读口 18
//   快速唤醒 **1 路**：wakeUpFp_0，但门控位是 **vecWen** 不是 fpWen
//     （Chisel 把 wakeUpInt++wakeUpFp++wakeUpVec++wakeUpMem 拼起来再按 writeVfRf 过滤，
//       活下来的那一路恰好挂在 io.wakeUpFp 这个 IO 束上，所以端口名叫 io_wakeUpFp_0_*
//       而门控位是 vecWen —— 名字与语义对不上是 golden 的事实，照抄。）
//   寄存器 128 个 = 纯忙位，异步复位到 0；无 loadDependency 影子、无 ldCancel 端口。
//   唤醒路数为 1 时 firtool 把 `|wakeupOHVec` 直接折成那一位本身（golden 里连
//   wakeupOHVec_* 这个名字都没有），功能不变。
//
// 唤醒取消路由：wk0 = `~(is0Lat & og0Cancel_8)`（is0Lat 是真端口）。
//
// 自动生成：verif/ut/BusyTable/gen.py —— 勿手改
""",
 'BusyTable_3': """// BusyTable_3.sv —— 物理寄存器忙位表（V0 向量掩码堆变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_BusyTable_core.sv（家族共享参数化核）。本文件只做端口打包与参数设定。
//
// 本变体规模（全部从 G1 golden BusyTable_3.sv 机械量得）：
//   表深 **22** 项（V0PhyRegs）—— 全家族最小；分配口 6；写回口 6；读口 6
//   快速唤醒 1 路：wakeUpFp_0，门控位 **v0Wen**
//   寄存器 22 个 = 纯忙位，异步复位到 0；无 loadDependency 影子、无 ldCancel 端口。
//
// ★ 越界是这个变体的常态：preg 索引端口仍是 8 位（全后端共用 PhyRegIdxWidth），
//   而表只有 22 项，随便一个 22..255 的索引就落在表外。golden 用 `table >> req`
//   得到 0（读成「就绪」）—— 核 §6 照这个语义写。
//
// 唤醒取消路由：wk0 = `~(is0Lat & og0Cancel_8)`（is0Lat 是真端口）。
//
// 自动生成：verif/ut/BusyTable/gen.py —— 勿手改
""",
 'VlBusyTable': """// VlBusyTable.sv —— 向量长度(vl)寄存器忙位表 + 两张 vl 谓词表，薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_BusyTable_core.sv（家族共享参数化核，HAS_VL=1 打开本变体专属的两张表）。
//
// 本变体规模（全部从 G1 golden VlBusyTable.sv 机械量得）：
//   表深 32 项（VlPhyRegs）；分配口 6；写回口 **4**；读口 6
//   快速唤醒 **0 路** —— Chisel 显式 `allWakeUp.filter(x => false)`，
//     源码注释给了原因：ldCancel 没接到 vl 表，接快速唤醒会让 vsetvli 出错。
//     于是 golden 里连 og0Cancel / ldCancel / wakeUp 端口都没有。
//   寄存器 96 个 = 32 × 3 张表（忙位 / nonzeroTable / vlmaxTable），全部异步复位到 0。
//
// 两张附加表（VlBusyTable extends BusyTable 加出来的）：
//   vl 是写回时才知道的值，后级只关心两个谓词「vl≠0」「vl=vlmax」。
//   写回口语义按端口号分（golden 实测 intSchdVlWbPort=0、vfSchdVlWbPort=1）：
//     wbPregs[0] → 用 vlFromInt{IsZero,IsVlmax} 填表
//     wbPregs[1] → 用 vlFromVf{IsZero,IsVlmax} 填表
//     wbPregs[2..3] → 不知道 vl 是多少，只能置「未知 = 忙」
//   vlmaxTable 存的是取反值（golden 写 `~vlFromIntIsVlmax`），读口再取反一次。
//   这两张表的读口**没有**分配旁路（忙位读口有）—— golden 就是这样，照抄。
//
// 自动生成：verif/ut/BusyTable/gen.py —— 勿手改
""",
}


def golden_ports(mod):
    lines = (GOLDEN / f'{mod}.sv').read_text().split('\n')
    ms = next(i for i, l in enumerate(lines) if l.startswith('module '))
    pe = next(i for i in range(ms, len(lines)) if lines[i].strip() == ');')
    return lines[ms:pe + 1]


def rev_concat(items):
    """SV 打包数组的 {高..低} 写法：items[0] 是 index 0，必须放在最右。"""
    if len(items) == 1:
        return items[0]
    return '{' + ', '.join(reversed(items)) + '}'


def emit(mod):
    d = V[mod]
    ports = golden_ports(mod)
    nwk = len(d['wakeups'])
    slots = max(nwk, 1)
    out = [HEADERS[mod].rstrip('\n'),
           '// ' + '=' * 76]
    out += ports
    out.append('')
    # --- 输出中转线
    out.append(f"  logic [{d['nread']}-1:0] core_read_resp;")
    if d['has_dep']:
        out.append(f"  logic [{d['nread']}-1:0][{LD_PIPE_N}-1:0][1:0] core_read_load_dep;")
    if d['has_vl']:
        out.append(f"  logic [{d['nread']}-1:0] core_vl_is_nonzero, core_vl_is_vlmax;")
    out.append('')

    # --- 参数
    from_load = 0
    ld_onehot = []
    for i in range(8):
        if i < nwk and d['wakeups'][i][4] is not None:
            from_load |= 1 << i
            ld_onehot.append(1 << d['wakeups'][i][4])
        else:
            ld_onehot.append(0)
    oh_lit = "{" + ", ".join(f"3'd{v}" for v in reversed(ld_onehot)) + "}"

    out.append('  xs_BusyTable_core #(')
    out.append(f"    .NUM_PREGS        ({d['pregs']}),")
    out.append('    .NUM_ALLOC        (6),')
    out.append(f"    .NUM_WB           ({d['nwb']}),")
    out.append(f"    .NUM_READ         ({d['nread']}),")
    out.append(f"    .NUM_WAKEUP       ({nwk}),")
    out.append(f"    .HAS_LOAD_DEP     ({d['has_dep']}),")
    out.append(f"    .ZERO_ALWAYS_READY({d['zero_ready']}),")
    out.append(f"    .HAS_VL           ({d['has_vl']}),")
    out.append(f"    .WK_FROM_LOAD     (8'b{from_load:08b}),")
    out.append(f"    .WK_LD_ONEHOT     ({oh_lit})")
    out.append('  ) u_core (')
    out.append('    .clock (clock),')
    out.append('    .reset (reset),')
    out.append('    .alloc_valid(' + rev_concat([f'io_allocPregs_{a}_valid' for a in range(6)]) + '),')
    out.append('    .alloc_preg (' + rev_concat([f'io_allocPregs_{a}_bits' for a in range(6)]) + '),')
    out.append('    .wb_valid   (' + rev_concat([f'io_wbPregs_{w}_valid' for w in range(d['nwb'])]) + '),')
    out.append('    .wb_preg    (' + rev_concat([f'io_wbPregs_{w}_bits' for w in range(d['nwb'])]) + '),')

    if nwk:
        out.append('    .wk_valid    (' + rev_concat([w[5] for w in d['wakeups']]) + '),')
        out.append('    .wk_wen      (' + rev_concat([w[0] for w in d['wakeups']]) + '),')
        out.append('    .wk_pdest    (' + rev_concat([w[5].replace('_valid', '_bits_pdest') for w in d['wakeups']]) + '),')
        out.append('    .wk_is0lat   (' + rev_concat([w[1] for w in d['wakeups']]) + '),')
        out.append('    .wk_og0cancel(' + rev_concat([w[2] for w in d['wakeups']]) + '),')
        deps = []
        for w in d['wakeups']:
            if w[3] is None:
                deps.append(f"{{{LD_PIPE_N * 2}{{1'b0}}}}")
            else:
                deps.append(rev_concat([f'{w[3]}_bits_loadDependency_{j}' for j in range(LD_PIPE_N)]))
        out.append('    .wk_load_dep (' + rev_concat(deps) + '),')
    else:
        out.append(f"    .wk_valid    (1'b0),")
        out.append(f"    .wk_wen      (1'b0),")
        out.append(f"    .wk_pdest    (8'b0),")
        out.append(f"    .wk_is0lat   (1'b0),")
        out.append(f"    .wk_og0cancel(1'b0),")
        out.append(f"    .wk_load_dep ({{{LD_PIPE_N * 2}{{1'b0}}}}),")

    if d['ldcancel']:
        out.append('    .ld_cancel  (' + rev_concat(d['ldcancel']) + '),')
    else:
        out.append(f"    .ld_cancel  ({{{LD_PIPE_N}{{1'b0}}}}),")

    out.append('    .read_req      (' + rev_concat([f'io_read_{r}_req' for r in range(d['nread'])]) + '),')
    out.append('    .read_resp     (core_read_resp),')
    out.append('    .read_load_dep (' + ('core_read_load_dep' if d['has_dep'] else '/* unused */') + '),')
    if d['has_vl']:
        out.append('    .vl_from_int_is_zero (io_vl_Wb_vlWriteBackInfo_vlFromIntIsZero),')
        out.append('    .vl_from_int_is_vlmax(io_vl_Wb_vlWriteBackInfo_vlFromIntIsVlmax),')
        out.append('    .vl_from_vf_is_zero  (io_vl_Wb_vlWriteBackInfo_vlFromVfIsZero),')
        out.append('    .vl_from_vf_is_vlmax (io_vl_Wb_vlWriteBackInfo_vlFromVfIsVlmax),')
        out.append('    .vl_is_nonzero       (core_vl_is_nonzero),')
        out.append('    .vl_is_vlmax         (core_vl_is_vlmax)')
    else:
        out.append("    .vl_from_int_is_zero (1'b0),")
        out.append("    .vl_from_int_is_vlmax(1'b0),")
        out.append("    .vl_from_vf_is_zero  (1'b0),")
        out.append("    .vl_from_vf_is_vlmax (1'b0),")
        out.append('    .vl_is_nonzero       (/* unused */),')
        out.append('    .vl_is_vlmax         (/* unused */)')
    out.append('  );')
    out.append('')
    for r in range(d['nread']):
        out.append(f'  assign io_read_{r}_resp = core_read_resp[{r}];')
        if d['has_dep']:
            for j in range(LD_PIPE_N):
                out.append(f'  assign io_read_{r}_loadDependency_{j} = core_read_load_dep[{r}][{j}];')
        if d['has_vl']:
            out.append(f'  assign io_vl_read_vlReadInfo_{r}_is_nonzero = core_vl_is_nonzero[{r}];')
            out.append(f'  assign io_vl_read_vlReadInfo_{r}_is_vlmax = core_vl_is_vlmax[{r}];')
    out.append('')
    out.append(f'endmodule')
    return '\n'.join(out) + '\n'




# =============================================================================
# tb.sv 生成 —— 五个变体各一对（golden vs 重写）双例化随机比对
# =============================================================================
TB_HEAD = r'''// =============================================================================
// BusyTable 家族 UT：五个 KunminghuV2 单态化变体各一对 DUT（golden <M> 对重写
// <M>_xs），共享时钟/复位，各自独立随机激励，逐拍比对**全部**输出端口。
//
// ★ 激励为什么不是「每个输入独立均匀随机」★
// 忙位表的判别力全在「同一个 preg 上多个事件撞车」：分配与写回同拍撞、快速唤醒被
// og0Cancel 打掉、load 唤醒两拍后被 ld2Cancel 撤销、读口撞上本拍的分配旁路。
// preg 索引 8 位、表深最大 224 —— 六路分配 × 八路写回全均匀随机的话，两路撞同一项
// 的概率低到 200k 拍也凑不出几次，那样的 errors=0 什么都没验到。
// 所以 preg 取值按三段分布（rand_preg）：
//   60% 落在 0..7 的密集池   → 制造撞车（含 Int 表的 0 号项特判）
//   25% 落在 0..NUM_PREGS-1  → 覆盖整张表
//   15% 全 8 位随机          → 制造**越界**读（BusyTable_3 只有 22 项，越界是常态）
// loadDependency 激励同理偏置：一半给 0，另一半偏向最高位置起（正好落在取消窗口）。
//
// ★ 覆盖证据 ★
// tb 统计若干「有判别力的事件」计数（见 $display 的 COVERAGE 段），任何一项为 0
// 都说明对应机制根本没被激励到，这一轮 errors=0 不作数。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  logic rst;
  int errors = 0;
  longint checks = 0;

  always #5 clk = ~clk;

  // 三段分布的 preg 取值：密集池制造撞车，全 8 位随机制造越界。
  function automatic logic [7:0] rand_preg(input int unsigned num_pregs);
    int unsigned r = $urandom_range(0, 99);
    if (r < 60)      return 8'($urandom_range(0, 7));
    else if (r < 85) return 8'($urandom_range(0, num_pregs - 1));
    else             return 8'($urandom);
  endfunction

  // loadDependency 激励：一半 0，其余偏向最高位置起（= 正处在 ld2Cancel 窗口里）。
  function automatic logic [1:0] rand_dep();
    int unsigned r = $urandom_range(0, 99);
    if (r < 50) return 2'b00;
    else if (r < 80) return 2'b10;
    else return 2'($urandom);
  endfunction

  // 覆盖计数（每个都是「没有它这一轮就等于没验」的事件）
  longint cov_alloc_wb_clash = 0;   // 同拍同 preg 既分配又写回（清忙必须压过置忙）
  longint cov_wake_wb_clash  = 0;   // 同拍同 preg 既唤醒又分配
  longint cov_og0_kill       = 0;   // 快速唤醒被 is0Lat&og0Cancel 打掉
  longint cov_ldcancel_set   = 0;   // ldCancel 把已清的项重新置忙（Int 表专属）
  longint cov_read_oob       = 0;   // 读口索引越界
  longint cov_oob_dep_nz     = 0;   // 越界读 loadDependency 时第 0 项非零（★坑 4 的判别点）
  longint cov_entry0_alloc   = 0;   // 分配命中 0 号项（★Int 表 0 号项特判的判别点）
  longint cov_alloc_bypass   = 0;   // 读口撞上本拍分配（resp 旁路）
  longint cov_vl_int_wb      = 0;   // vl 表被 int 写回口填
  longint cov_vl_vf_wb       = 0;   // vl 表被 vf  写回口填
  longint cov_vl_other_wb    = 0;   // vl 表被其它写回口置「未知」
'''

TB_TAIL = r'''
  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1'b1;
    repeat (4) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    // 中途再来一次异步复位，验证复位域（全家族都是 posedge reset 异步复位）
    repeat (NCYCLES / 2) @(posedge clk);
    @(negedge clk) rst = 1'b1;
    repeat (3) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    repeat (NCYCLES / 2) @(posedge clk);

    $display("--- COVERAGE (每项必须 > 0，否则该机制没被激励到) ---");
    $display("  alloc&wb 同项撞车      : %0d", cov_alloc_wb_clash);
    $display("  wake&alloc 同项撞车    : %0d", cov_wake_wb_clash);
    $display("  og0Cancel 打掉唤醒     : %0d", cov_og0_kill);
    $display("  ldCancel 重新置忙      : %0d", cov_ldcancel_set);
    $display("  读口越界               : %0d", cov_read_oob);
    $display("  越界读 dep 且第0项非零 : %0d", cov_oob_dep_nz);
    $display("  分配命中 0 号项        : %0d", cov_entry0_alloc);
    $display("  读口撞本拍分配(旁路)   : %0d", cov_alloc_bypass);
    $display("  vl int 写回口          : %0d", cov_vl_int_wb);
    $display("  vl vf  写回口          : %0d", cov_vl_vf_wb);
    $display("  vl 其它写回口          : %0d", cov_vl_other_wb);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 &&
        cov_alloc_wb_clash > 0 && cov_wake_wb_clash > 0 && cov_og0_kill > 0 &&
        cov_ldcancel_set > 0 && cov_read_oob > 0 && cov_oob_dep_nz > 0 &&
        cov_entry0_alloc > 0 && cov_alloc_bypass > 0 &&
        cov_vl_int_wb > 0 && cov_vl_vf_wb > 0 && cov_vl_other_wb > 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED (errors=%0d 或覆盖项为 0)", errors);
    $finish;
  end

endmodule
'''


def parse_golden_io(mod):
    """从 golden 端口表抽 (方向, 位宽, 名字)。"""
    out = []
    for l in golden_ports(mod):
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)', l)
        if m:
            out.append((m.group(1), int(m.group(2) or 0) + 1, m.group(3)))
    return out


def drive_expr(mod, name, d):
    """按端口名决定激励表达式（在 negedge 用非阻塞赋值）。"""
    if name.endswith('_valid') and 'allocPregs' in name:
        return "($urandom_range(0, 9) < 5)"
    if name.endswith('_valid') and 'wbPregs' in name:
        return "($urandom_range(0, 9) < 5)"
    if name.endswith('_valid'):                      # wakeUp*_k_valid
        return "($urandom_range(0, 9) < 7)"
    if name.endswith('_bits') or name.endswith('_pdest') or name.endswith('_req'):
        return f"rand_preg({d['pregs']})"
    if re.search(r'_bits_loadDependency_\d$', name):
        return "rand_dep()"
    if name.endswith(('_rfWen', '_fpWen', '_vecWen', '_v0Wen')):
        return "($urandom_range(0, 9) < 8)"
    if name.endswith('_is0Lat'):
        return "($urandom_range(0, 9) < 5)"
    if name.startswith('io_og0Cancel'):
        return "($urandom_range(0, 9) < 3)"
    if name.endswith('_ld2Cancel'):
        return "($urandom_range(0, 9) < 3)"
    if name.startswith('io_vl_Wb_'):
        return "($urandom_range(0, 9) < 5)"
    raise RuntimeError(f'{mod}: 不知道怎么激励端口 {name}')


def emit_tb():
    body = [TB_HEAD]
    for mod, d in V.items():
        io = parse_golden_io(mod)
        ins = [(w, n) for dr, w, n in io if dr == 'input' and n not in ('clock', 'reset')]
        outs = [(w, n) for dr, w, n in io if dr == 'output']
        P = mod + '_'
        body.append(f'\n  // ==========================================================================')
        body.append(f'  // {mod} —— {d["what"]}，表深 {d["pregs"]}，写回口 {d["nwb"]}，读口 {d["nread"]}，唤醒 {len(d["wakeups"])} 路')
        body.append(f'  // ==========================================================================')
        for w, n in ins:
            body.append(f'  logic {f"[{w-1}:0] " if w > 1 else ""}{P}{n};')
        for w, n in outs:
            body.append(f'  wire  {f"[{w-1}:0] " if w > 1 else ""}{P}g_{n}, {P}i_{n};')
        for tag, inst in (('g', mod), ('i', mod + '_xs')):
            conns = ['.clock(clk)', '.reset(rst)']
            conns += [f'.{n}({P}{n})' for _, n in ins]
            conns += [f'.{n}({P}{tag}_{n})' for _, n in outs]
            body.append(f'  {inst} u_{tag}_{mod} (')
            body.append('    ' + ',\n    '.join(conns))
            body.append('  );')
        # 激励
        body.append(f'  always @(negedge clk) begin')
        body.append(f'    if (rst) begin')
        for _, n in ins:
            if n.endswith('_valid'):
                body.append(f"      {P}{n} <= 1'b0;")
        body.append(f'    end else begin')
        for w, n in ins:
            body.append(f'      {P}{n} <= {drive_expr(mod, n, d)};')
        body.append(f'    end')
        body.append(f'  end')
        # 比对
        body.append(f'  always @(negedge clk) if (!rst) begin')
        body.append(f'    #4;')
        for w, n in outs:
            body.append(f'    checks++;')
            body.append(f'    if ({P}g_{n} !== {P}i_{n}) begin errors++;')
            body.append(f'      if (errors < 40) $display("[%0t] {mod}.{n} mismatch: g=%h i=%h", $time, {P}g_{n}, {P}i_{n}); end')
        body.append(f'  end')
        body.append(emit_cov(mod, d))
    body.append(TB_TAIL)
    return '\n'.join(body)


def emit_cov(mod, d):
    """覆盖计数：只看 tb 可见的输入与 golden 输出，以及少量 golden 内部层次探针。"""
    P = mod + '_'

    def q(e):
        """把 golden 端口名加上本变体前缀；常数表达式原样返回。"""
        return (P + e) if e.startswith('io_') else e

    L = ['  // ---- 覆盖事件统计（只读 golden 侧，不看重写侧，免得自证）----',
         '  always @(negedge clk) if (!rst) begin', '    #4;']
    # alloc & wb 同项
    L.append('    for (int a = 0; a < 6; a++) begin')
    L.append('      logic v; logic [7:0] b;')
    L.append('      case (a)')
    for a in range(6):
        L.append(f'        {a}: begin v = {P}io_allocPregs_{a}_valid; b = {P}io_allocPregs_{a}_bits; end')
    L.append('        default: begin v = 1\'b0; b = 8\'h0; end')
    L.append('      endcase')
    L.append(f'      if (v && b < {d["pregs"]}) begin')
    if d['zero_ready']:
        L.append('        if (b == 8\'h0) cov_entry0_alloc++;')
    L.append('        for (int w = 0; w < %d; w++) begin' % d['nwb'])
    L.append('          logic wv; logic [7:0] wb;')
    L.append('          case (w)')
    for w in range(d['nwb']):
        L.append(f'            {w}: begin wv = {P}io_wbPregs_{w}_valid; wb = {P}io_wbPregs_{w}_bits; end')
    L.append('            default: begin wv = 1\'b0; wb = 8\'h0; end')
    L.append('          endcase')
    L.append('          if (wv && wb == b) cov_alloc_wb_clash++;')
    L.append('        end')
    if d['wakeups']:
        L.append('        for (int k = 0; k < %d; k++) begin' % len(d['wakeups']))
        L.append('          logic kv; logic [7:0] kp;')
        L.append('          case (k)')
        for k, wk in enumerate(d['wakeups']):
            L.append(f'            {k}: begin kv = {q(wk[5])} && {q(wk[0])}; kp = {P}{wk[5].replace("_valid","_bits_pdest")}; end')
        L.append('            default: begin kv = 1\'b0; kp = 8\'h0; end')
        L.append('          endcase')
        L.append('          if (kv && kp == b) cov_wake_wb_clash++;')
        L.append('        end')
    L.append('      end')
    L.append('    end')
    # og0 kill
    for k, wk in enumerate(d['wakeups']):
        if wk[1] != "1'b0" and wk[2] != "1'b0":
            L.append(f'    if ({q(wk[5])} && {q(wk[0])} && ({q(wk[1])}) && ({q(wk[2])})) cov_og0_kill++;')
    # 读口越界 / 旁路
    L.append(f'    for (int r = 0; r < {d["nread"]}; r++) begin')
    L.append('      logic [7:0] q;')
    L.append('      case (r)')
    for r in range(d['nread']):
        L.append(f'        {r}: q = {P}io_read_{r}_req;')
    L.append('        default: q = 8\'h0;')
    L.append('      endcase')
    L.append(f'      if (q >= {d["pregs"]}) cov_read_oob++;')
    L.append('      for (int a = 0; a < 6; a++) begin')
    L.append('        logic v; logic [7:0] b;')
    L.append('        case (a)')
    for a in range(6):
        L.append(f'          {a}: begin v = {P}io_allocPregs_{a}_valid; b = {P}io_allocPregs_{a}_bits; end')
    L.append('          default: begin v = 1\'b0; b = 8\'h0; end')
    L.append('        endcase')
    L.append('        if (v && b == q) cov_alloc_bypass++;')
    L.append('      end')
    L.append('    end')
    if d['has_dep']:
        # ★坑 4 的判别点：越界读 + 第 0 项 loadDependency 非零
        L.append(f'    for (int r = 0; r < {d["nread"]}; r++) begin')
        L.append('      logic [7:0] q;')
        L.append('      case (r)')
        for r in range(d['nread']):
            L.append(f'        {r}: q = {P}io_read_{r}_req;')
        L.append('        default: q = 8\'h0;')
        L.append('      endcase')
        L.append(f'      if (q >= {d["pregs"]} &&')
        L.append(f'          (u_g_{mod}.loadDependency_0_0 != 0 || u_g_{mod}.loadDependency_0_1 != 0 ||')
        L.append(f'           u_g_{mod}.loadDependency_0_2 != 0)) cov_oob_dep_nz++;')
        L.append('    end')
        # ldCancel 重新置忙：直接探 golden 的 ldCancelMask_ld2Cancel_* 线（0..7 号项）
        L.append('    if (' + ' || '.join(
            [f'u_g_{mod}.ldCancelMask_ld2Cancel'] +
            [f'u_g_{mod}.ldCancelMask_ld2Cancel_{i}' for i in range(1, 8)]) + ') cov_ldcancel_set++;')
    if d['has_vl']:
        L.append(f'    if ({P}io_wbPregs_0_valid && {P}io_wbPregs_0_bits < {d["pregs"]}) cov_vl_int_wb++;')
        L.append(f'    if ({P}io_wbPregs_1_valid && {P}io_wbPregs_1_bits < {d["pregs"]}) cov_vl_vf_wb++;')
        L.append(f'    if (({P}io_wbPregs_2_valid && {P}io_wbPregs_2_bits < {d["pregs"]}) ||')
        L.append(f'        ({P}io_wbPregs_3_valid && {P}io_wbPregs_3_bits < {d["pregs"]})) cov_vl_other_wb++;')
    L.append('  end')
    return '\n'.join(L)


def main():
    outs = [(OUT / f'{m}.sv', emit(m)) for m in V]
    outs.append((HERE / 'tb.sv', emit_tb()))
    for path, txt in outs:
        if path.exists() and path.read_text() == txt:
            print(f'  unchanged {path}')
            continue
        path.write_text(txt)
        print(f'  wrote     {path}  ({len(txt.splitlines())} lines)')


if __name__ == '__main__':
    main()
