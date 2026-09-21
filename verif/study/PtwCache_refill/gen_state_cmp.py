#!/usr/bin/env python3
"""gen_state_cmp.py —— 生成 tb.sv 里 `compare_state()` 这一段（纯机械的层次引用对照表）。

为什么要有这个生成器：PtwCache 的核内状态被 firtool 展平成了几百个标量寄存器
（l3_0_tag / l1asids_0_0 / state_vec_1_63 …），而重写核里它们是 struct 数组。
这张两侧路径对照表一根都不能错，但里面没有任何设计判断，手敲只会引入抄写错误。

★本文件不做任何等价性判断★：它抄的是两侧的层次路径，抄对了不等于状态对了。

用法:
    python3 gen_state_cmp.py            # 原地改写 tb.sv 的 GENERATED(state_cmp) 段
    python3 gen_state_cmp.py --check    # 只校验该段与重算结果逐字节一致
"""
import argparse
import os
import re
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
TB = HERE / 'tb.sv'
BEGIN = '  // BEGIN GENERATED(state_cmp)'
END = '  // END GENERATED(state_cmp)'
PBEGIN = '  // BEGIN GENERATED(port_cmp)'
PEND = '  // END GENERATED(port_cmp)'
GOLDEN = pathlib.Path(os.environ.get(
    'GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')) / 'PtwCache.sv'
PORT_FIRST, PORT_LAST = 88, 542     # 与 scripts/gen_ptwcache.py 同一段行号

G = 'dut_g.'
I = 'dut_i.u_core.'

L3_N = L2_N = SP_N = 16
L1_SETS, L1_WAYS = 4, 2
L0_SETS, L0_WAYS = 64, 4


def emit():
    o = [BEGIN,
         '  // 由 gen_state_cmp.py 生成（golden 展平标量 <-> 重写核 struct 数组的路径对照）。',
         '  // 手改这段会被下次生成覆盖；要改请改生成器。',
         '  task automatic compare_state();']

    def c(name, g, i):
        o.append('    chk("%s", %s%s, %s%s);' % (name, G, g, I, i))

    # 位向量：l0v/l0g 是 256 位，chk 只收 64 位，切成 4 段比。
    for nm in ('l3v', 'l2v', 'l1v', 'spv', 'l3g', 'l2g', 'l1g', 'spg'):
        c(nm, nm, nm)
    for nm in ('l0v', 'l0g'):
        for k in range(4):
            c('%s[%d]' % (nm, k), '%s[%d:%d]' % (nm, 64 * k + 63, 64 * k),
              '%s[%d:%d]' % (nm, 64 * k + 63, 64 * k))

    # 替换状态
    c('plru_l3', 'state_reg', 'plru_l3')
    c('plru_l2', 'state_reg_1', 'plru_l2')
    c('plru_sp', 'state_reg_4', 'plru_sp')
    for s in range(L1_SETS):
        c('plru_l1[%d]' % s, 'state_vec_%d' % s, 'plru_l1[%d]' % s)
    for s in range(L0_SETS):
        c('plru_l0[%d]' % s, 'state_vec_1_%d' % s, 'plru_l0[%d]' % s)

    # l3 / l2 / sp 表项与 h
    for i in range(L3_N):
        for f in ('tag', 'asid', 'vmid', 'ppn', 'prefetch'):
            c('l3[%d].%s' % (i, f), 'l3_%d_%s' % (i, f), 'l3_entry[%d].%s' % (i, f))
        c('l3h[%d]' % i, 'l3h_%d' % i, 'l3h[%d]' % i)
    for i in range(L2_N):
        for f in ('tag', 'asid', 'vmid', 'pbmt', 'ppn', 'prefetch'):
            c('l2[%d].%s' % (i, f), 'l2_%d_%s' % (i, f), 'l2_entry[%d].%s' % (i, f))
        c('l2h[%d]' % i, 'l2h_%d' % i, 'l2h[%d]' % i)
    for i in range(SP_N):
        for f in ('tag', 'asid', 'vmid', 'n', 'pbmt', 'ppn', 'level', 'prefetch', 'v'):
            c('sp[%d].%s' % (i, f), 'sp_%d_%s' % (i, f), 'sp_entry[%d].%s' % (i, f))
        for p in ('d', 'a', 'g', 'u', 'x', 'w', 'r'):
            c('sp[%d].perm.%s' % (i, p), 'sp_%d_perm_%s' % (i, p),
              'sp_entry[%d].perm.%s' % (i, p))
        c('sph[%d]' % i, 'sph_%d' % i, 'sph[%d]' % i)

    # l1 / l0 的影子元数据
    for s in range(L1_SETS):
        for w in range(L1_WAYS):
            c('l1h[%d][%d]' % (s, w), 'l1h_%d_%d' % (s, w), 'l1h[%d][%d]' % (s, w))
            c('l1asids[%d][%d]' % (s, w), 'l1asids_%d_%d' % (s, w), 'l1asids[%d][%d]' % (s, w))
            c('l1vmids[%d][%d]' % (s, w), 'l1vmids_%d_%d' % (s, w), 'l1vmids[%d][%d]' % (s, w))
    for s in range(L0_SETS):
        for w in range(L0_WAYS):
            c('l0h[%d][%d]' % (s, w), 'l0h_%d_%d' % (s, w), 'l0h[%d][%d]' % (s, w))
            c('l0asids[%d][%d]' % (s, w), 'l0asids_%d_%d' % (s, w), 'l0asids[%d][%d]' % (s, w))
            c('l0vmids[%d][%d]' % (s, w), 'l0vmids_%d_%d' % (s, w), 'l0vmids[%d][%d]' % (s, w))
            c('l0vpns[%d][%d]' % (s, w), 'l0vpns_%d_%d' % (s, w), 'l0vpns[%d][%d]' % (s, w))

    o.append('  endtask')
    o.append('')
    o.append('  // 命中侧（stageReq -> stageDelay -> stageCheck 三级）')
    o.append('  task automatic compare_hit();')

    # 流水载荷与两个 1 拍脉冲
    for gs, im in (('', 'delay_'), ('1_', 'check_'), ('2_', 'resp_')):
        c('%sreq_info_vpn' % im, 'data_%sreq_info_vpn' % gs, '%svpn' % im)
        c('%sreq_info_s2xlate' % im, 'data_%sreq_info_s2xlate' % gs, '%ss2x' % im)
        c('%sreq_info_source' % im, 'data_%sreq_info_source' % gs, '%ssrc' % im)
        c('%sisFirst' % im, 'data_%sisFirst' % gs, '%sisfirst' % im)
        c('%sisHptwReq' % im, 'data_%sisHptwReq' % gs, '%sishptw' % im)
        c('%shptwId' % im, 'data_%shptwId' % gs, '%shptwid' % im)
    c('stageDelay_valid_1cycle', 'stageDelay_valid_1cycle', 'stage_delay_valid_1cycle')
    c('stageCheck_valid_1cycle', 'stageCheck_valid_1cycle', 'stage_check_valid_1cycle')
    c('valid_delay', 'valid', 'valid_delay')
    c('valid_check', 'valid_1', 'valid_check')
    c('valid_resp', 'valid_2', 'valid_resp')

    # 三个寄存器阵列级的 hitVec
    for i in range(L3_N):
        c('l3_hitvec[%d]' % i, 'hitVec_%d' % i, 'l3_hitvec[%d]' % i)
    for i in range(L2_N):
        c('l2_hitvec[%d]' % i, 'hitVec_%d_1' % i, 'l2_hitvec[%d]' % i)
    for i in range(SP_N):
        c('sp_hitvec[%d]' % i, 'hitVec_%d_2' % i, 'sp_hitvec[%d]' % i)

    # l3 / l2 的 DataHoldBypass 保持寄存器与 stageCheck 对齐寄存器
    c('l3_hit_r', 'hit_r', 'l3_hit_r')
    c('l3_ppn_r', 'hitPPN_r', 'l3_ppn_r')
    c('l3_pre_r', 'hitPre_r', 'l3_pre_r')
    c('l2_hit_r', 'hit_r_1', 'l2_hit_r')
    c('l2_ppn_r', 'hitPPN_r_1', 'l2_ppn_r')
    c('l2_pbmt_r', 'hitPbmt_r_1', 'l2_pbmt_r')
    c('l2_pre_r', 'hitPre_r_1', 'l2_pre_r')
    c('l3_hit_ck', 'l3Hit_r', 'l3_hit_ck')
    c('l3_ppn_ck', 'l3HitPPN_r', 'l3_ppn_ck')
    c('l3_pre_ck', 'l3Pre_r', 'l3_pre_ck')
    c('l2_hit_ck', 'l2Hit', 'l2_hit_ck')
    c('l2_ppn_ck', 'l2HitPPN', 'l2_ppn_ck')
    c('l2_pbmt_ck', 'l2HitPbmt', 'l2_pbmt_ck')
    c('l2_pre_ck', 'l2Pre', 'l2_pre_ck')

    # sp
    c('sp_ishptw_delay', 'ishptw_1', 'sp_ishptw_delay')
    c('sp_s2x_delay', 's2x_info_1', 'sp_s2x_delay')
    c('sp_hit_ck', 'spHit', 'sp_hit_ck')
    c('sp_pre_ck', 'spPre', 'sp_pre_ck')
    c('sp_valid_ck', 'spValid', 'sp_valid_ck')
    c('sp_jmp_bitmap_ck', 'spJmpBitmapCheck', 'sp_jmp_bitmap_ck')
    for f in ('n', 'pbmt', 'ppn', 'level', 'v'):
        c('sp_hitdata_ck.%s' % f, 'spHitData_%s' % f, 'sp_hitdata_ck.%s' % f)
    for pm in ('d', 'a', 'g', 'u', 'x', 'w', 'r'):
        c('sp_hitdata_ck.perm.%s' % pm, 'spHitData_perm_%s' % pm,
          'sp_hitdata_ck.perm.%s' % pm)

    # l1 / l0 的取回向量与 SRAM 数据两级寄存器
    c('l1_vvec_delay', 'vVec_delay', 'l1_vvec_delay')
    c('l1_gvec_delay', 'gVec_delay', 'l1_gvec_delay')
    for w in range(L1_WAYS):
        c('l1_hvec_delay[%d]' % w, 'hVec_delay_%d' % w, 'l1_hvec_delay[%d]' % w)
        c('l1_hitvec[%d]' % w, 'l1_hitVec_%d' % w, 'l1_hitvec[%d]' % w)
    c('l0_vvec_delay', 'vVec_delay_1', 'l0_vvec_delay')
    for w in range(L0_WAYS):
        c('l0_hvec_delay[%d]' % w, 'hVec_delay_1_%d' % w, 'l0_hvec_delay[%d]' % w)
        c('l0_hitvec[%d]' % w, 'l0_hitVec_%d' % w, 'l0_hitvec[%d]' % w)

    # data_resp_r 留的是整行；ramDatas 只留下游用得到的字段（golden 就是这样，见 §16）
    for w in range(L1_WAYS):
        for f in ('tag', 'asid', 'vmid', 'prefetch'):
            c('l1_resp_r[%d].%s' % (w, f), 'data_resp_r_%d_entries_%s' % (w, f),
              'l1_resp_r[%d].%s' % (w, f))
        for k in range(8):
            for arr in ('pbmts', 'ppns', 'vs'):
                c('l1_resp_r[%d].%s[%d]' % (w, arr, k),
                  'data_resp_r_%d_entries_%s_%d' % (w, arr, k),
                  'l1_resp_r[%d].%s[%d]' % (w, arr, k))
        c('l1_ramdata[%d].prefetch' % w, 'l1_ramDatas_%d_entries_prefetch' % w,
          'l1_ramdata[%d].prefetch' % w)
        for k in range(8):
            for arr in ('pbmts', 'ppns'):
                c('l1_ramdata[%d].%s[%d]' % (w, arr, k),
                  'l1_ramDatas_%d_entries_%s_%d' % (w, arr, k),
                  'l1_ramdata[%d].%s[%d]' % (w, arr, k))
    for w in range(L0_WAYS):
        for f in ('tag', 'asid', 'vmid', 'prefetch'):
            c('l0_resp_r[%d].%s' % (w, f), 'data_resp_r_1_%d_entries_%s' % (w, f),
              'l0_resp_r[%d].%s' % (w, f))
        for k in range(8):
            for arr in ('pbmts', 'ppns', 'vs', 'onlypf'):
                c('l0_resp_r[%d].%s[%d]' % (w, arr, k),
                  'data_resp_r_1_%d_entries_%s_%d' % (w, arr, k),
                  'l0_resp_r[%d].%s[%d]' % (w, arr, k))
            for pm in ('d', 'a', 'g', 'u', 'x', 'w', 'r'):
                c('l0_resp_r[%d].perms[%d].%s' % (w, k, pm),
                  'data_resp_r_1_%d_entries_perms_%d_%s' % (w, k, pm),
                  'l0_resp_r[%d].perms[%d].%s' % (w, k, pm))
        c('l0_ramdata[%d].prefetch' % w, 'l0_ramDatas_%d_entries_prefetch' % w,
          'l0_ramdata[%d].prefetch' % w)
        for k in range(8):
            for arr in ('pbmts', 'ppns', 'onlypf'):
                c('l0_ramdata[%d].%s[%d]' % (w, arr, k),
                  'l0_ramDatas_%d_entries_%s_%d' % (w, arr, k),
                  'l0_ramdata[%d].%s[%d]' % (w, arr, k))
            for pm in ('d', 'a', 'g', 'u', 'x', 'w', 'r'):
                c('l0_ramdata[%d].perms[%d].%s' % (w, k, pm),
                  'l0_ramDatas_%d_entries_perms_%d_%s' % (w, k, pm),
                  'l0_ramdata[%d].perms[%d].%s' % (w, k, pm))

    # ---- §22 bitmap：l0BitmapReg 本体 + 两级流水副本 ----
    #  golden 把 64x4x8 展平成 2048 个标量。逐根 chk 会让本对照慢一个量级，
    #  所以按"每组 32 位"打包成一次比较（值仍然逐位比，只是少了函数调用）。
    o.append('    // §22 l0BitmapReg（每组 4 路 x 8 位打成 32 位比一次）')
    for s in range(L0_SETS):
        gg = ', '.join('%sl0BitmapReg_%d_%d_%d' % (G, s, w, k)
                       for w in range(L0_WAYS - 1, -1, -1) for k in range(7, -1, -1))
        ii = ', '.join('%sl0_bitmap[%d][%d]' % (I, s, w)
                       for w in range(L0_WAYS - 1, -1, -1))
        o.append('    chk("l0_bitmap[%d]", {%s}, {%s});' % (s, gg, ii))
    o.append('    // §22 bitmap 的两级流水副本（golden r_W_K / r_1_W_K）')
    gg = ', '.join('%sr_%d_%d' % (G, w, k)
                   for w in range(L0_WAYS - 1, -1, -1) for k in range(7, -1, -1))
    ii = ', '.join('%sl0_bitmap_delay[%d]' % (I, w) for w in range(L0_WAYS - 1, -1, -1))
    o.append('    chk("l0_bitmap_delay", {%s}, {%s});' % (gg, ii))
    gg = ', '.join('%sr_1_%d_%d' % (G, w, k)
                   for w in range(L0_WAYS - 1, -1, -1) for k in range(7, -1, -1))
    ii = ', '.join('%sl0_bitmap_ck[%d]' % (I, w) for w in range(L0_WAYS - 1, -1, -1))
    o.append('    chk("l0_bitmap_ck", {%s}, {%s});' % (gg, ii))
    # §22 wakeup 流水
    o.append('    // §22 wakeup 三拍流水')
    c('wakeup_delay_valid', 'wakeup_req_delay_valid', 'wakeup_delay_valid')
    c('wakeup_valid', 'wakeup_req_valid', 'wakeup_valid')
    for f, i2 in (('setIndex', 'wk_d_set'), ('tag', 'wk_d_tag'),
                  ('way_info', 'wk_d_way'), ('pte_index', 'wk_d_idx'),
                  ('check_success', 'wk_d_ok'), ('s2xlate', 'wk_d_s2x')):
        c(i2, 'wakeup_req_delay_%s' % f, i2)
    for f, i2 in (('setIndex', 'wk_set'), ('way_info', 'wk_way'),
                  ('pte_index', 'wk_idx'), ('check_success', 'wk_ok')):
        c(i2, 'wakeup_req_%s' % f, i2)
    for w in range(L0_WAYS):
        c('wakeup_hitvec[%d]' % w, 'wakeup_hitVec_%d' % w, 'wakeup_hitvec[%d]' % w)
        c('wakeup_vvec_delay[%d]' % w, 'wakeup_vVec_delay[%d]' % w,
          'wakeup_vvec_delay[%d]' % w)
        c('wakeup_hvec_delay[%d]' % w, 'wakeup_hVec_delay_%d' % w,
          'wakeup_hvec_delay[%d]' % w)
        for f in ('tag', 'asid', 'vmid'):
            c('wakeup_rdata_r[%d].%s' % (w, f),
              'wakeup_data_resp_r_%d_entries_%s' % (w, f),
              'wakeup_rdata_r[%d].%s' % (w, f))
        for k in range(8):
            c('wakeup_rdata_r[%d].vs[%d]' % (w, k),
              'wakeup_data_resp_r_%d_entries_vs_%d' % (w, k),
              'wakeup_rdata_r[%d].vs[%d]' % (w, k))
            c('wakeup_rdata_r[%d].g[%d]' % (w, k),
              'wakeup_data_resp_r_%d_entries_perms_%d_g' % (w, k),
              'wakeup_rdata_r[%d].g[%d]' % (w, k))
    o.append('  endtask')
    o.append(END)
    return '\n'.join(o) + '\n'


def splice(text):
    b = text.index(BEGIN)
    e = text.index(END) + len(END) + 1
    return text[:b] + emit() + text[e:]


def emit_ports():
    """compare_outputs()：golden 与重写核的**全部 236 个输出**逐拍逐位比。

    端口表直接从 golden PtwCache.sv 量，不手抄 —— 手抄的名单会漏，
    而漏掉的那一根在 UT 里就是"按构造测不到"。
    """
    o = [PBEGIN,
         '  // 由 gen_state_cmp.py 生成（golden 端口表逐根量出）。改这段请改生成器。',
         '  task automatic compare_outputs();']
    n = 0
    for ln in GOLDEN.read_text().split('\n')[PORT_FIRST - 1:PORT_LAST]:
        m = re.match(r'\s+(input|output)\s+(\[[^\]]*\]\s+)?(\w+),?\s*$', ln)
        if not m:
            raise SystemExit('端口行解析不了（fail-closed）: %r' % ln)
        if m.group(1) != 'output':
            continue
        p = m.group(3)
        o.append('    chk("%s", g_%s, i_%s);' % (p, p, p))
        n += 1
    if n != 236:
        raise SystemExit('输出端口数 %d != 236 —— golden 变了，先重新量行号' % n)
    o += ['  endtask', PEND]
    return o


def splice_ports(text):
    b = text.index(PBEGIN)
    e = text.index(PEND) + len(PEND) + 1
    return text[:b] + '\n'.join(emit_ports()) + '\n' + text[e:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    cur = TB.read_text()
    if BEGIN not in cur or END not in cur or PBEGIN not in cur or PEND not in cur:
        print('gen_state_cmp: tb.sv 里找不到 GENERATED 标记（fail-closed）')
        return 1
    new = splice_ports(splice(cur))
    if a.check:
        if new != cur:
            print('gen_state_cmp --check: DRIFT —— tb.sv 与重算结果不一致')
            return 1
        print('gen_state_cmp --check: 逐字节一致')
        return 0
    TB.write_text(new)
    print('gen_state_cmp: 已写回 tb.sv（%d 行对照）' % emit().count('chk('))
    return 0


if __name__ == '__main__':
    sys.exit(main())
