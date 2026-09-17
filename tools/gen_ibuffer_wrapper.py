#!/usr/bin/env python3
"""gen_ibuffer_wrapper.py —— 生成 rtl/frontend/IBuffer.sv 里的 golden 同名 wrapper。

IBuffer 有 441 个端口(16 条入队 lane × 16 字段 + 6 条出队 lane × 24 字段 +
38 位 topdown + 9 路 perf)。端口表与「扁平 io_* 名 ↔ 核的数组端口」之间的换名
是纯机械的，手抄一次就会抄错一根线，而且这类错误 UT 可能测不出来（只要 tb 也照
同一份错抄）。所以这一段由本脚本从 **G1 golden 的端口表**直接生成：
端口名/方向/位宽/顺序全部取自 golden，port_contract_lint 因此按构造就是通过的。

生成区在 IBuffer.sv 里用 `// BEGIN GENERATED(wrapper)` / `// END GENERATED`
标记，脚本只替换这一段，手写区（package + xs_IBuffer_core）绝不触碰。

用法: python3 tools/gen_ibuffer_wrapper.py [--check]
      --check 只比对不写入（幂等闸用）。
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/IBuffer.sv')
TARGET = REPO / 'rtl' / 'frontend' / 'IBuffer.sv'

BEGIN = '// BEGIN GENERATED(wrapper)'
END = '// END GENERATED'

PREDICT_W = 16
DECODE_W = 6
NREASON = 38


def golden_port_lines():
    """取 golden 的端口表原文（module IBuffer( 之后到 ); 之前），原样复用。"""
    txt = GOLDEN.read_text().split('\n')
    start = next(i for i, l in enumerate(txt) if l.startswith('module IBuffer('))
    out = []
    i = start + 1
    while txt[i].rstrip() != ');':
        out.append(txt[i].rstrip())
        i += 1
    if not out:
        raise SystemExit('golden 端口表为空 —— 解析失败，拒绝生成')
    return out


def cat(name_fmt, n, extra=None):
    """把 io_..._0 .. io_..._{n-1} 打包成 {高位 .. 低位} 的拼接串。"""
    items = [name_fmt.format(i) for i in range(n)]
    if extra is not None:
        items = [extra if x is None else x for x in items]
    return '{' + ',\n     '.join(reversed(items)) + '}'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()

    L = []
    L.append(BEGIN)
    L.append('// 本段由 tools/gen_ibuffer_wrapper.py 从 G1 golden 端口表生成，勿手改。')
    L.append('module IBuffer (')
    L.extend(golden_port_lines())
    L.append(');')
    L.append('')
    L.append('  // ---- 入队侧：16 条 lane 的扁平端口打包成数组 ----')

    packs = [
        ('wire [15:0][31:0] core_in_instr', 'io_in_bits_instrs_{}', PREDICT_W, None),
        ('wire [15:0][49:0] core_in_pc', 'io_in_bits_pc_{}', PREDICT_W, None),
        ('wire [15:0][9:0]  core_in_foldpc', 'io_in_bits_foldpc_{}', PREDICT_W, None),
        ('wire [15:0]       core_in_pd_isRVC', 'io_in_bits_pd_{}_isRVC', PREDICT_W, None),
        ('wire [15:0][1:0]  core_in_pd_brType', 'io_in_bits_pd_{}_brType', PREDICT_W, None),
        ('wire [15:0]       core_in_pd_isCall', 'io_in_bits_pd_{}_isCall', PREDICT_W, None),
        ('wire [15:0]       core_in_pd_isRet', 'io_in_bits_pd_{}_isRet', PREDICT_W, None),
        ('wire [15:0]       core_in_ftqOff_v', 'io_in_bits_ftqOffset_{}_valid', PREDICT_W, None),
        ('wire [15:0][1:0]  core_in_excp_type', 'io_in_bits_exceptionType_{}', PREDICT_W, None),
        ('wire [15:0]       core_in_crosspage', 'io_in_bits_crossPageIPFFix_{}', PREDICT_W, None),
        ('wire [15:0]       core_in_illegal', 'io_in_bits_illegalInstr_{}', PREDICT_W, None),
        ('wire [15:0][3:0]  core_in_triggered', 'io_in_bits_triggered_{}', PREDICT_W, None),
        ('wire [15:0]       core_in_lastftq', 'io_in_bits_isLastInFtqEntry_{}', PREDICT_W, None),
        ('wire [37:0]       core_in_topdown',
         'io_in_bits_topdown_info_reasons_{}', NREASON, None),
    ]
    for decl, fmt, n, _ in packs:
        items = [fmt.format(i) for i in reversed(range(n))]
        L.append('  %s =' % decl)
        L.append('      {' + (',\n       '.join(items)) + '};')
    # ★ 三组「Chisel 是 16 路、golden 只剩 1 路」的端口 ★
    # firtool 是**整电路**优化器（--split-verilog 只影响输出切分），父模块
    # 把这些位驱成常数后，常数被传播进 IBuffer、对应端口被删掉。照 Chisel 字面
    # 写成 16 路端口，portlint 当场红；但更危险的是反过来——若把折掉的那 15 路
    # 当成"随便接什么都行"，UT 会因为 tb 也照同一份错误接线而全绿。
    #   pd_N_valid              : 只缺 lane0（PreDecodeInfo 第 0 槽 valid 恒 1）
    #   backendException_N      : 只剩 lane0，lane1..15 恒 0
    #   satpFlushFirstFetchFault: 只剩 lane0，lane1..15 恒 0
    # 实测出处：golden 的 ibuf_5_backendException 写的是
    #   `validOH_0_11 & io_in_bits_backendException_0` —— 只有 lane0 那一项活着。
    items = ['io_in_bits_pd_%d_valid' % i for i in range(1, PREDICT_W)]
    L.append('  // ★ lane0 的 pd.valid 在 golden 里被折成常数 1，端口表里没有这根线 ★')
    L.append('  wire [15:0]       core_in_pd_valid =')
    L.append('      {' + ',\n       '.join(reversed(items))
             + ',\n       1\'b1};')
    L.append('  // ★ backendException / satpFlushFirstFetchFault 只有 lane0 有端口，'
             '其余 15 路 golden 恒 0 ★')
    L.append("  wire [15:0]       core_in_backexcp  = "
             "{15'h0, io_in_bits_backendException_0};")
    L.append("  wire [15:0]       core_in_satpflush = "
             "{15'h0, io_in_bits_satpFlushFirstFetchFault_0};")

    L.append('')
    L.append('  // ---- 出队侧：核的数组输出 ----')
    L.append('  wire [5:0]              core_out_valid;')
    L.append('  ibuffer_pkg::ibuf_entry_t [5:0] core_out_bits;')
    L.append('  wire [5:0]              core_out_af, core_out_ii, core_out_pf,')
    L.append('                          core_out_gpf, core_out_crosspage;')
    L.append('  wire [5:0][55:0]        core_out_seqnum;')
    L.append('  wire [5:0][7:0]         core_out_uopidx;')
    L.append('  wire [5:0][5:0]         core_stall_reason;')
    L.append('  wire [8:0][5:0]         core_perf;')
    L.append('')
    L.append('  xs_IBuffer_core u_core (')
    conns = [
        ('clock', 'clock'), ('reset', 'reset'),
        ('flush', 'io_flush'),
        ('ctrl_redirect', 'io_ControlRedirect'),
        ('ctrl_btb_miss', 'io_ControlBTBMissBubble'),
        ('tage_miss', 'io_TAGEMissBubble'),
        ('sc_miss', 'io_SCMissBubble'),
        ('ittage_miss', 'io_ITTAGEMissBubble'),
        ('ras_miss', 'io_RASMissBubble'),
        ('memvio_redirect', 'io_MemVioRedirect'),
        ('in_ready', 'io_in_ready'),
        ('in_valid', 'io_in_valid'),
        ('in_instr_valid', 'io_in_bits_valid'),
        ('in_enq_enable', 'io_in_bits_enqEnable'),
        ('in_instr', 'core_in_instr'),
        ('in_pc', 'core_in_pc'),
        ('in_foldpc', 'core_in_foldpc'),
        ('in_pd_valid', 'core_in_pd_valid'),
        ('in_pd_isRVC', 'core_in_pd_isRVC'),
        ('in_pd_brType', 'core_in_pd_brType'),
        ('in_pd_isCall', 'core_in_pd_isCall'),
        ('in_pd_isRet', 'core_in_pd_isRet'),
        ('in_ftqOffset_valid', 'core_in_ftqOff_v'),
        ('in_ftqPtr_flag', 'io_in_bits_ftqPtr_flag'),
        ('in_ftqPtr_value', 'io_in_bits_ftqPtr_value'),
        ('in_excp_type', 'core_in_excp_type'),
        ('in_crosspage', 'core_in_crosspage'),
        ('in_illegal_instr', 'core_in_illegal'),
        ('in_backend_excp', 'core_in_backexcp'),
        ('in_satp_flush_first', 'core_in_satpflush'),
        ('in_triggered', 'core_in_triggered'),
        ('in_last_in_ftq', 'core_in_lastftq'),
        ('in_topdown_reasons', 'core_in_topdown'),
        ('decode_can_accept', 'io_decodeCanAccept'),
        ('out_valid', 'core_out_valid'),
        ('out_bits', 'core_out_bits'),
        ('out_excp_af', 'core_out_af'),
        ('out_excp_ii', 'core_out_ii'),
        ('out_excp_pf', 'core_out_pf'),
        ('out_excp_gpf', 'core_out_gpf'),
        ('out_crosspage', 'core_out_crosspage'),
        ('out_seqnum', 'core_out_seqnum'),
        ('out_uopidx', 'core_out_uopidx'),
        ('stall_reason', 'core_stall_reason'),
        ('back_reason_valid', 'io_stallReason_backReason_valid'),
        ('back_reason_bits', 'io_stallReason_backReason_bits'),
        ('perf_value', 'core_perf'),
    ]
    w = max(len(a) for a, _ in conns)
    for k, (a, b) in enumerate(conns):
        L.append('    .%-*s (%s)%s' % (w, a, b, ',' if k != len(conns) - 1 else ''))
    L.append('  );')
    L.append('')
    L.append('  // ---- 出队侧：数组拆回扁平 io_out_* ----')
    fields = [
        ('valid', 'core_out_valid[{i}]'),
        ('bits_instr', 'core_out_bits[{i}].inst'),
        ('bits_pc', 'core_out_bits[{i}].pc'),
        ('bits_foldpc', 'core_out_bits[{i}].foldpc'),
        ('bits_exceptionVec_1', 'core_out_af[{i}]'),
        ('bits_exceptionVec_2', 'core_out_ii[{i}]'),
        ('bits_exceptionVec_12', 'core_out_pf[{i}]'),
        ('bits_exceptionVec_20', 'core_out_gpf[{i}]'),
        ('bits_backendException', 'core_out_bits[{i}].backendException'),
        ('bits_satpFlushFirstFetchFault',
         'core_out_bits[{i}].satpFlushFirstFetchFault'),
        ('bits_trigger', 'core_out_bits[{i}].triggered'),
        ('bits_pd_valid', 'core_out_bits[{i}].pd_valid'),
        ('bits_pd_isRVC', 'core_out_bits[{i}].pd_isRVC'),
        ('bits_pd_brType', 'core_out_bits[{i}].pd_brType'),
        ('bits_pd_isCall', 'core_out_bits[{i}].pd_isCall'),
        ('bits_pd_isRet', 'core_out_bits[{i}].pd_isRet'),
        ('bits_pred_taken', 'core_out_bits[{i}].pred_taken'),
        ('bits_crossPageIPFFix', 'core_out_crosspage[{i}]'),
        ('bits_ftqPtr_flag', 'core_out_bits[{i}].ftqPtr_flag'),
        ('bits_ftqPtr_value', 'core_out_bits[{i}].ftqPtr_value'),
        ('bits_ftqOffset', 'core_out_bits[{i}].ftqOffset'),
        ('bits_isLastInFtqEntry', 'core_out_bits[{i}].isLastInFtqEntry'),
        ('bits_debug_seqNum_seqNum', 'core_out_seqnum[{i}]'),
        ('bits_debug_seqNum_uopIdx', 'core_out_uopidx[{i}]'),
    ]
    for i in range(DECODE_W):
        for suf, src in fields:
            L.append('  assign io_out_%d_%s = %s;' % (i, suf, src.format(i=i)))
    for i in range(DECODE_W):
        L.append('  assign io_stallReason_reason_%d = core_stall_reason[%d];' % (i, i))
    for i in range(9):
        L.append('  assign io_perf_%d_value = core_perf[%d];' % (i, i))
    L.append('')
    L.append('endmodule : IBuffer')
    L.append(END)

    gen = '\n'.join(L) + '\n'

    txt = TARGET.read_text()
    if BEGIN in txt:
        pre = txt.split(BEGIN)[0]
        post = txt.split(END, 1)[1]
        new = pre + gen + post
    else:
        new = txt.rstrip('\n') + '\n\n' + gen

    if args.check:
        if new != txt:
            print('gen_ibuffer_wrapper: 生成区与源文件不一致（请重跑不带 --check）')
            return 1
        print('gen_ibuffer_wrapper: OK（生成区与源文件一致）')
        return 0
    TARGET.write_text(new)
    print('gen_ibuffer_wrapper: 写入 %s（生成区 %d 行）' % (TARGET, len(L)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
