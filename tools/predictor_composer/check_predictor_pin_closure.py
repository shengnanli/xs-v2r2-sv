#!/usr/bin/env python3
"""check_predictor_pin_closure.py —— 把 Predictor 一次 FM 实跑里**每一个**未配点
归类，并核对"钉点能收掉哪些、收不掉哪些"这笔账对得上。

为什么需要这道核对
------------------
verif/ut/Predictor/fm_pins_pre.tcl 自带 fail-closed，但它只管"我生成的 2497 对
在两侧都存在、且互不重复"。它答不了另外两个问题：
  1. 这 2497 对**够不够**？—— 卡住证明的未配点是不是都落在这七族里？
  2. 剩下的收不掉的到底是什么？—— 是漏钉，还是结构上就没有对家？
这两个问题只能拿 FM 实跑的 receipt.json 来回答。本脚本就做这件事。

判据（任一不成立即退出码 1）
----------------------------
  A. 每一个未配点（比较点 + 未读点，ref/impl 两侧）都能被归进一个**已知类**；
     出现无法归类的点 = 有一族被漏掉了，直接失败。
  B. "可读核独有死位"的每一位都必须落在**声明过的结构类**里（见下），
     而不是"凡是 golden 侧找不到的都算独有"——那等于 fail-open。
  C. 去掉可读核独有死位之后，两侧未配点数**相等**。不相等说明还有非对称的
     东西没认出来，此时任何"钉满了"的说法都不成立。

可读核独有死位的四个声明类（都是"可读性 vs firtool DCE"的结构性差异，
不是 bug，也不是钉点能解决的）
----------------------------------------------------------------------
  folded_hist   可读核 fh_word_t 定宽 FH_MAX_W(11) 位，golden 按每条 hist 自己的
                FH_CLEN[h] 开宽 -> 高位 b >= FH_CLEN[h] 可读核独有。
                ★FH_CLEN 从 rtl/frontend/Predictor.sv **现场解析**，不抄进本脚本★：
                抄一份常数就等于埋一颗"RTL 改了而核对脚本没改"的哑弹。
  afhob         golden 的 afhob 组 4 只有 bits_0..2，可读核 afhob_word_t 是 4 位。
  prev_s2       golden 侧 firtool 把 jalr_target 的 dup1-3、offsets、
                fall_through_err、multi_hit 整片 DCE 掉了，可读核保留完整结构。
  td_q          golden 只留 reasons 1..9 与 12，可读核保留全部 13 个槽位。
  do_redirect   golden 的 level 是 1 位、ssp 是 4 位，可读核按结构声明更宽。

跑法
----
  python3 tools/predictor_composer/check_predictor_pin_closure.py \\
      --receipt <evidence>/Predictor/receipt.json \\
      --rtl rtl/frontend/Predictor.sv
"""
import argparse, json, re, sys, collections

def parse_fh_clen(rtl_path):
    """从可读核 RTL 里解析 FH_CLEN[1:17]（不抄常数）。"""
    src = open(rtl_path, encoding='utf-8').read()
    m = re.search(r'localparam\s+int\s+unsigned\s+FH_CLEN\s*\[1:NUM_FH\]\s*=\s*\'\{(.*?)\}\s*;',
                  src, re.S)
    if not m:
        sys.exit('FATAL: 在 %s 里找不到 FH_CLEN 声明' % rtl_path)
    body = re.sub(r'//[^\n]*', '', m.group(1))
    vals = [int(x) for x in re.findall(r'\d+', body)]
    if len(vals) != 17:
        sys.exit('FATAL: FH_CLEN 解析出 %d 个元素，应为 17' % len(vals))
    return {h + 1: v for h, v in enumerate(vals)}

def parse_fh_max_w(rtl_path):
    src = open(rtl_path, encoding='utf-8').read()
    m = re.search(r'localparam\s+int\s+unsigned\s+FH_MAX_W\s*=\s*(\d+)', src)
    if not m:
        sys.exit('FATAL: 找不到 FH_MAX_W')
    return int(m.group(1))

# ---- 七族：钉点覆盖的（ref 侧形状 / impl 侧形状）------------------------------
PINNED_REF = [
    r'^ghv_\d+_reg$',
    r'^s\d_last_br_num_oh(_reg)?_dup_\d+_reg\[\d+\]$',
    r'^io_bpu_to_ftq_resp_bits_s[123]_full_pred_[0-3]_predCycle_c_reg\[\d+\]$',
    r'^s\d_folded_gh(_reg)?_dup_\d+_hist_\d+_folded_hist_reg\[\d+\]$',
    r'^s\d_ahead_fh_oldest_bits(_reg)?_dup_\d+_afhob_\d+_bits_\d+_reg$',
    r'^s\d_ghist_ptr(_reg)?_dup_\d+_(flag_reg|value_reg\[\d+\])$',
    r'^powerOnResetState_reg$',
]
PINNED_IMPL = [
    r'^ghv_q_reg\[\d+\]$',
    r'^s\d_brnum(_reg)?_reg\[\d+\]\[\d+\]$',
    r'^pred_cycle_q_reg\[\d+\]\[\d+\]\[\d+\]$',
    r'^s\d_folded_gh(_reg)?_reg\[\d+\]\[\d+\]\[\d+\]$',
    r'^s\d_afhob(_reg)?_reg\[\d+\]\[\d+\]\[\d+\]$',
    r'^s\d_ghist_ptr(_reg)?_reg\[\d+\]\[(flag|value)\](\[\d+\])?$',
    r'^power_on_reset_state_reg$',
]

def impl_only_class(leaf, clen, fh_max_w):
    """可读核独有死位：命中返回类名，否则 None。★只认声明过的结构类★"""
    m = re.match(r'^s\d_folded_gh(?:_reg)?_reg\[\d+\]\[(\d+)\]\[(\d+)\]$', leaf)
    if m:
        h, b = int(m.group(1)), int(m.group(2))
        if h in clen and clen[h] <= b < fh_max_w:
            return 'folded_hist 高位 (b >= FH_CLEN[h])'
        return None
    m = re.match(r'^s\d_afhob(?:_reg)?_reg\[\d+\]\[(\d+)\]\[(\d+)\]$', leaf)
    if m and (int(m.group(1)), int(m.group(2))) == (4, 3):
        return 'afhob 组4 bits_3 (golden 只有 bits_0..2)'
    m = re.match(r'^prev_s2_reg\[(\d)\]\[jalr_target\]\[\d+\]$', leaf)
    if m and m.group(1) != '0':
        return 'prev_s2 jalr_target dup1-3 (golden 已 DCE)'
    if re.match(r'^prev_s2_reg\[\d\]\[offsets\]\[\d+\]\[\d+\]$', leaf):
        return 'prev_s2 offsets (golden 已 DCE)'
    if re.match(r'^prev_s2_reg\[\d\]\[(fall_through_err|multi_hit)\]$', leaf):
        return 'prev_s2 fall_through_err/multi_hit (golden 已 DCE)'
    m = re.match(r'^td_q_reg\[\d\]\[(\d+)\]$', leaf)
    if m and int(m.group(1)) in (0, 10, 11):
        return 'td_q reasons 0/10/11 (golden 只留 1..9,12)'
    if leaf in ('do_redirect_bits_reg[level][1]', 'do_redirect_bits_reg[ssp][4]'):
        return 'do_redirect level[1]/ssp[4] (golden 位宽更窄)'
    return None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--receipt', required=True)
    ap.add_argument('--rtl', required=True)
    a = ap.parse_args()

    clen = parse_fh_clen(a.rtl)
    fh_max_w = parse_fh_max_w(a.rtl)
    obj = json.load(open(a.receipt))['native_facts']['objects']

    def leaves(key, pfx):
        out = []
        for p in obj[key]:
            p = p.replace('\\', '')                      # FM 转义标识符的字面反斜杠
            assert p.startswith(pfx), p
            out.append(p[len(pfx):])
        return out

    ref = leaves('unmatched_ref', 'r:/WORK/Predictor/') + \
          leaves('unmatched_unread_ref', 'r:/WORK/Predictor/')
    imp = leaves('unmatched_impl', 'i:/WORK/Predictor/u_core/') + \
          leaves('unmatched_unread_impl', 'i:/WORK/Predictor/u_core/')

    # --- A/B：逐点归类 ---
    bad = []
    n_ref_pinned = 0
    for leaf in ref:
        if any(re.match(rx, leaf) for rx in PINNED_REF):
            n_ref_pinned += 1
        else:
            bad.append(('ref 未归类', leaf))

    n_imp_pinned = 0
    implonly = collections.Counter()
    for leaf in imp:
        cls = impl_only_class(leaf, clen, fh_max_w)
        if cls:
            implonly[cls] += 1
        elif any(re.match(rx, leaf) for rx in PINNED_IMPL):
            n_imp_pinned += 1
        else:
            bad.append(('impl 未归类', leaf))

    tot_only = sum(implonly.values())
    print('FH_CLEN(解析自 %s) = %s' % (a.rtl, [clen[h] for h in range(1, 18)]))
    print('FH_MAX_W = %d' % fh_max_w)
    print()
    print('ref  侧未配点合计 : %d  (比较 %d + 未读 %d)'
          % (len(ref), len(obj['unmatched_ref']), len(obj['unmatched_unread_ref'])))
    print('impl 侧未配点合计 : %d  (比较 %d + 未读 %d)'
          % (len(imp), len(obj['unmatched_impl']), len(obj['unmatched_unread_impl'])))
    print()
    print('可读核独有死位（钉点无能为力，须 reviewer 裁定）合计 %d：' % tot_only)
    for k, v in sorted(implonly.items(), key=lambda kv: -kv[1]):
        print('    %5d  %s' % (v, k))
    print()
    print('落在钉点七族里的未配点 : ref %d / impl %d' % (n_ref_pinned, n_imp_pinned))
    print('两侧对账              : ref %d  vs  impl %d - 独有 %d = %d'
          % (len(ref), len(imp), tot_only, len(imp) - tot_only))

    rc = 0
    if bad:
        print('\n判据 A/B 失败：%d 个点无法归进已知类（前 20）：' % len(bad))
        for t, l in bad[:20]:
            print('    [%s] %s' % (t, l))
        rc = 1
    if len(ref) != len(imp) - tot_only:
        print('\n判据 C 失败：去掉可读核独有死位后两侧未配点数不相等')
        rc = 1
    print('\n%s' % ('CLOSURE_OK' if rc == 0 else 'CLOSURE_FAIL'))
    return rc

if __name__ == '__main__':
    sys.exit(main())
