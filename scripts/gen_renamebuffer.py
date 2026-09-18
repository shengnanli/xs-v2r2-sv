#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_renamebuffer.py —— 生成 rtl/backend/RenameBuffer.sv 里的**机械派生区**。

RenameBuffer 的 golden 有 153 个端口（69 输入 / 84 输出），全是 firtool 把
Vec/Bundle 展平出来的一根一根的线。wrapper 的端口表、到可读核的打包/拆包、
以及内嵌 SnapshotGenerator 的 21 根连线，加起来三百多行纯机械文本：
手抄一次必错，而且**错了四道闸都不一定响**（端口契约闸只比端口本身，不比内部接线；
UT 若两侧都从同一份错误映射生成，错误会对称抵消）。所以这三段一律从
**G1 golden 的端口表**直接生成，手写区只有可读核。

生成区在 rtl/backend/RenameBuffer.sv 里由
    // BEGIN GENERATED(renamebuffer-wrapper)
    // END GENERATED
包住，区外一个字符都不碰。

用法:
    python3 scripts/gen_renamebuffer.py            # 写入
    python3 scripts/gen_renamebuffer.py --check    # 只比对，有漂移则非零退出
"""
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
TARGET = REPO / 'rtl' / 'backend' / 'RenameBuffer.sv'
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/RenameBuffer.sv')

BEGIN = '// BEGIN GENERATED(renamebuffer-wrapper)'
END = '// END GENERATED'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)\s*,?\s*$')

RENAME_W = 6
COMMIT_W = 6
SNPT_NUM = 4
# rab_info_t 的字段顺序 = golden 的 renameBuffer_N_info_* 声明顺序
INFO_FIELDS = ['ldest', 'pdest', 'rfWen', 'fpWen', 'vecWen', 'v0Wen', 'vlWen', 'isMove']


def parse_ports():
    txt = GOLDEN.read_text().split('\n')
    start = next(i for i, l in enumerate(txt) if l.startswith('module RenameBuffer('))
    ports, i = [], start + 1
    while txt[i].rstrip() != ');':
        m = PORT_RE.match(txt[i])
        if not m:
            raise SystemExit('端口行解析失败: %r' % txt[i])
        ports.append((m.group(1), m.group(2) or '', m.group(3)))
        i += 1
    if len(ports) != 153:
        raise SystemExit('解析到 %d 个端口，与实测的 153 不符，拒绝生成' % len(ports))
    return ports


def build():
    ports = parse_ports()
    w = max(len(p[1]) for p in ports)
    L = []
    a = L.append

    a(BEGIN)
    a('// 本区由 scripts/gen_renamebuffer.py 从 G1 golden 的端口表生成，请勿手改。')
    a('// -----------------------------------------------------------------------------')
    a('// golden 同名 wrapper：端口逐位与 G1 golden 同名同序；内部只做')
    a('//   (1) 展平信号 ↔ 可读核 struct 的打包/拆包；')
    a('//   (2) 例化子模块 SnapshotGenerator（实例名与 golden 一致）。')
    a('// -----------------------------------------------------------------------------')
    a('module RenameBuffer (')
    for k, (d, rng, n) in enumerate(ports):
        comma = '' if k == len(ports) - 1 else ','
        a('  %-6s %-*s %s%s' % (d, w, rng, n, comma))
    a(');')
    a('')
    a('  import renamebuffer_pkg::*;')
    a('')
    a('  // ---- 可读核侧的结构化信号 ----')
    a('  rab_req_t  core_req          [RENAME_W];')
    a('  rab_info_t core_commits_info [COMMIT_W];')
    a('  logic [COMMIT_W-1:0] core_commit_valid;')
    a('  logic [COMMIT_W-1:0] core_walk_valid;')
    a('  logic                    core_vec_excp_valid [COMMIT_W];')
    a('  logic [LDEST_W-1:0]      core_vec_excp_lreg  [COMMIT_W];')
    a('  logic [VEXCP_PREG_W-1:0] core_vec_excp_preg  [COMMIT_W];')
    a('  rab_ptr_t  core_snapshot_enq_data;')
    a('  rab_ptr_t  core_snapshots [SNPT_NUM];')
    a('  logic               snapshot_flag  [SNPT_NUM];')
    a('  logic [PTR_W-1:0]   snapshot_value [SNPT_NUM];')
    a('')
    a('  // ---- rename 请求：展平信号 → struct ----')
    for i in range(RENAME_W):
        a('  assign core_req[%d].valid       = io_req_%d_valid;' % (i, i))
        for f in INFO_FIELDS:
            a('  assign core_req[%d].info.%-6s = io_req_%d_bits_%s;' % (i, f, i, f))
    a('')
    a('  // ---- 子模块：4 槽快照队列（实例名与 golden 一致，便于 FM 对层次）----')
    a('  SnapshotGenerator walkPtrSnapshots_snapshotGen (')
    a('    .clock                (clock),')
    a('    .reset                (reset),')
    a('    .io_enq               (io_snpt_snptEnq),')
    a('    .io_enqData_flag      (core_snapshot_enq_data.flag),')
    a('    .io_enqData_value     (core_snapshot_enq_data.value),')
    a('    .io_deq               (io_snpt_snptDeq),')
    a('    .io_redirect          (io_redirect_valid),')
    for i in range(SNPT_NUM):
        a('    .io_flushVec_%d        (io_snpt_flushVec_%d),' % (i, i))
    for i in range(SNPT_NUM):
        a('    .io_snapshots_%d_flag  (snapshot_flag[%d]),' % (i, i))
        tail = '' if i == SNPT_NUM - 1 else ','
        a('    .io_snapshots_%d_value (snapshot_value[%d])%s' % (i, i, tail))
    a('  );')
    a('')
    a('  always_comb')
    a('    for (int i = 0; i < SNPT_NUM; i++)')
    a("      core_snapshots[i] = '{flag: snapshot_flag[i], value: snapshot_value[i]};")
    a('')
    a('  // ---- 可读核 ----')
    a('  xs_RenameBuffer_core u_core (')
    a('    .clock                   (clock),')
    a('    .reset                   (reset),')
    a('    .redirect_valid          (io_redirect_valid),')
    a('    .req                     (core_req),')
    a('    .rob_commit_size         (io_fromRob_commitSize),')
    a('    .rob_walk_size           (io_fromRob_walkSize),')
    a('    .rob_walk_end            (io_fromRob_walkEnd),')
    a('    .rob_vec_load_excp_valid (io_fromRob_vecLoadExcp_valid),')
    a('    .snpt_enq                (io_snpt_snptEnq),')
    a('    .snpt_deq                (io_snpt_snptDeq),')
    a('    .snpt_use                (io_snpt_useSnpt),')
    a('    .snpt_select             (io_snpt_snptSelect),')
    a('    .snpt_flush_vec          ({io_snpt_flushVec_3, io_snpt_flushVec_2,')
    a('                               io_snpt_flushVec_1, io_snpt_flushVec_0}),')
    a('    .can_enq                 (io_canEnq),')
    a('    .can_enq_for_dispatch    (io_canEnqForDispatch),')
    a('    .commits_is_commit       (io_commits_isCommit),')
    a('    .commits_commit_valid    (core_commit_valid),')
    a('    .commits_is_walk         (io_commits_isWalk),')
    a('    .commits_walk_valid      (core_walk_valid),')
    a('    .commits_info            (core_commits_info),')
    a('    .status_walk_end         (io_status_walkEnd),')
    a('    .status_commit_end       (io_status_commitEnd),')
    a('    .vec_excp_valid          (core_vec_excp_valid),')
    a('    .vec_excp_lreg           (core_vec_excp_lreg),')
    a('    .vec_excp_preg           (core_vec_excp_preg),')
    a('    .snapshot_enq_data       (core_snapshot_enq_data),')
    a('    .snapshots               (core_snapshots)')
    a('  );')
    a('')
    a('  // ---- 输出：struct → 展平信号 ----')
    for i in range(COMMIT_W):
        a('  assign io_commits_commitValid_%d = core_commit_valid[%d];' % (i, i))
    for i in range(COMMIT_W):
        a('  assign io_commits_walkValid_%d   = core_walk_valid[%d];' % (i, i))
    for i in range(COMMIT_W):
        for f in INFO_FIELDS:
            a('  assign io_commits_info_%d_%-6s = core_commits_info[%d].%s;' % (i, f, i, f))
    for i in range(COMMIT_W):
        a('  assign io_toVecExcpMod_logicPhyRegMap_%d_valid     = core_vec_excp_valid[%d];'
          % (i, i))
        a('  assign io_toVecExcpMod_logicPhyRegMap_%d_bits_lreg = core_vec_excp_lreg[%d];'
          % (i, i))
        a('  assign io_toVecExcpMod_logicPhyRegMap_%d_bits_preg = core_vec_excp_preg[%d];'
          % (i, i))
    a('')
    a('endmodule')
    a(END)
    return '\n'.join(L) + '\n'


def main():
    check = '--check' in sys.argv[1:]
    new = build()
    old = TARGET.read_text()
    if BEGIN not in old or END not in old:
        raise SystemExit('%s 里找不到生成区标记' % TARGET)
    head = old.split(BEGIN)[0]
    tail = old.split(END, 1)[1]
    out = head + new + tail.lstrip('\n')
    if check:
        if out != old:
            print('DRIFT: %s 的生成区与 gen_renamebuffer.py 现在会生成的内容不一致' % TARGET)
            return 1
        print('gen_renamebuffer: 生成区与生成器一致')
        return 0
    TARGET.write_text(out)
    print('gen_renamebuffer: 已刷新 %s 的生成区' % TARGET)
    return 0


if __name__ == '__main__':
    sys.exit(main())
