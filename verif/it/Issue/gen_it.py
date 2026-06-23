#!/usr/bin/env python3
# =============================================================================
# gen_it.py —— Issue(Int Scheduler)簇 IT 装配生成器
#
# 目的: 把 rtl/backend 下「已重写」的 Int Scheduler + 3 个 IssueQueue + 3 个 Entries
#       + 3 个 IqEntry 链, 机械地复制成 *_it 命名的副本(只重命名 6 个与 golden 撞名的
#       算法模块: IssueQueue{Acfd,Ambb,Abjivvi} / Entries{同}), 使其能与 golden 顶层
#       在同一次 VCS 编译里共存(u_g=golden, u_i=全重写 _it 链)。
#
#  不重命名:
#   - xs_*_core / xs_iq_entry_* : 这些可读核名字本来就唯一(golden 没有), 直接共享。
#   - 共享结构/存储原语叶子: AgeDetector(_1) / NewAgeDetector / FuBusyTableRead* /
#     FuBusyTableWrite* / MultiWakeupQueue* / EnqPolicy / UIntCompressor* —— 两侧
#     例化同一份 golden 模块(memory/结构原语, 非算法), 不重命名。
#
#  重命名的 6 个算法模块(声明 + 例化引用都改):
#     IssueQueueAluCsrFenceDiv,  IssueQueueAluMulBkuBrhJmp,
#     IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v,
#     EntriesAluCsrFenceDiv,     EntriesAluMulBkuBrhJmp,
#     EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v
#  → 各加 `_it` 后缀。
#
#  Scheduler 核(golden 同名 module Scheduler)在 IT 里改名 Scheduler_it, 它 include
#  scheduler_int_iq_connect.svh —— 该 svh 把 IQ 例化为撞名模块, 故生成 _it 版 svh,
#  把 4 个 IQ 例化的「模块名」替换为 _it。IQ 核 include 各自 connect svh, 其中 Entries
#  例化的模块名也替换为 _it。
# =============================================================================
import re, os, shutil

RTL = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../rtl/backend"))
OUT = os.path.dirname(os.path.abspath(__file__))

# 6 个与 golden 撞名、需加 _it 的算法模块
RENAME = [
    "IssueQueueAluCsrFenceDiv",
    "IssueQueueAluMulBkuBrhJmp",
    "IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v",
    "EntriesAluCsrFenceDiv",
    "EntriesAluMulBkuBrhJmp",
    "EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v",
]

def apply_rename(text):
    # 只替换「整词」出现的撞名模块, 避免误伤 xs_IssueQueueAluCsrFenceDiv_core 之类。
    # 词边界: 前面不是字母/数字/下划线, 后面不是字母/数字/下划线。
    for name in RENAME:
        text = re.sub(r'(?<![A-Za-z0-9_])' + re.escape(name) + r'(?![A-Za-z0-9_])',
                      name + "_it", text)
    return text

def copy_rename(src_name, dst_name=None):
    dst_name = dst_name or src_name.replace(".sv", "_it.sv").replace(".svh", "_it.svh")
    with open(os.path.join(RTL, src_name)) as f:
        t = f.read()
    t = apply_rename(t)
    with open(os.path.join(OUT, dst_name), "w") as f:
        f.write(t)
    return dst_name

# --- IQ 核 + 其 golden 同名 wrapper(撞名 → _it) ---
# 这些文件里 module IssueQueue* 改名, 内部 Entries* 例化也改名;
# include 的 connect/ports svh 引用名不在文件里(svh 单独处理), 但 include 路径名
# 也要指向 _it 版 svh。
iq_files = {
    "IssueQueueAluCsrFenceDiv.sv":              ("issuequeue_acfd_ports.svh", "issuequeue_acfd_connect.svh"),
    "IssueQueueAluMulBkuBrhJmp.sv":             ("issuequeue_ambb_ports.svh", "issuequeue_ambb_connect.svh"),
    "IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv": ("issuequeue_abjivvi_ports.svh", "issuequeue_abjivvi_connect.svh"),
}

def copy_iq(src):
    # IQ 文件含 xs_*_core(内联例化 Entries*, 需 _it) + golden 同名 wrapper(撞名 → _it)。
    # wrapper include 的 issuequeue_*_connect.svh 只例化 xs_*_core(无撞名), 保持原 include,
    # 经 +incdir 复用 rtl 原 svh, 不另生成 _it 副本。
    with open(os.path.join(RTL, src)) as f:
        t = f.read()
    t = apply_rename(t)
    out = src.replace(".sv", "_it.sv")
    with open(os.path.join(OUT, out), "w") as f:
        f.write(t)
    return out

# --- Entries wrapper(golden 同名 → _it), Entries 核(xs_*, 不改名但内部 IqEntry 已是 xs_) ---
# Entries wrapper 文件: module EntriesAluCsrFenceDiv → _it; 内部例化 xs_*_core 不变。
# Entries 核文件 (xs_Entries*_core): 名字唯一不改; 内部例化 xs_iq_entry_* 不变。

generated = []

for src in iq_files:
    generated.append(copy_iq(src))

# issuequeue_*_connect.svh / *_ports.svh : 只例化 xs_*_core, 无撞名 → 复用 rtl 原文件,
# 经 +incdir 找到, 不生成 _it 副本。

# Entries wrapper(撞名 → _it)
for w in ["EntriesAluCsrFenceDiv_wrapper.sv", "EntriesAluMulBkuBrhJmp_wrapper.sv",
          "EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v_wrapper.sv"]:
    generated.append(copy_rename(w))

# Entries 核 (xs_*_core, 不撞名; 直接复用 rtl 原文件, 不生成副本)
# IqEntry 核 (xs_iq_entry_*, 不撞名; 直接复用 rtl 原文件, 不生成副本)

# --- Scheduler 核 → Scheduler_it ---
with open(os.path.join(RTL, "Scheduler.sv")) as f:
    sched = f.read()
sched = sched.replace("module Scheduler import scheduler_int_pkg::*;",
                      "module Scheduler_it import scheduler_int_pkg::*;")
# include _it 版连接(其中 IQ 例化模块名 → _it)
sched = sched.replace('`include "scheduler_int_iq_connect.svh"',
                      '`include "scheduler_int_iq_connect_it.svh"')
with open(os.path.join(OUT, "Scheduler_it.sv"), "w") as f:
    f.write(sched)
generated.append("Scheduler_it.sv")

# scheduler_int_iq_connect svh: IQ 例化模块名 → _it
generated.append(copy_rename("scheduler_int_iq_connect.svh"))

print("generated:")
for g in sorted(generated):
    print("  ", g)
