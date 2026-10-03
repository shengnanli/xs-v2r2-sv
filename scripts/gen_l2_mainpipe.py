#!/usr/bin/env python3
"""gen_l2_mainpipe.py —— MainPipe_1（L2 tl2chi 主流水）的机械部分：TaskBundle 结构体与 golden 同名 wrapper。

可读核 xs_MainPipe_1_core 在 rtl/uncore/MainPipe_1.sv 里手写，本脚本**不碰**；它只原地替换同一文件的
GENERATED(task_t) / GENERATED(wrapper) 两个区：

  task_t   io_taskFromArb_s2_bits_* 的 94 个字段（顺序、位宽逐字取自 golden），并核对 io_toSourceD_bits_task_* /
           io_toTXDAT_bits_task_* 与 child Arbiter3_TaskWithData 的字段表与之完全相同。第一个字段放最高位；alias 写成 alias_。
  wrapper  端口按 golden；四个出口仲裁器（toSourceD/TXREQ/TXRSP/TXDAT_arb）与 customL1Hint 按 golden 实例名例化；
           io_toMSHRCtl_mshr_alloc_s3_bits_task_* 只取 golden 端口上留下的那些字段。

用法：python3 scripts/gen_l2_mainpipe.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
RTL = os.path.join(REPO, 'rtl', 'uncore', 'MainPipe_1.sv')
MOD = 'MainPipe_1'
SV_KEYWORDS = {'alias'}
META_F = ['dirty', 'state', 'clients', 'alias', 'prefetch', 'prefetchSrc', 'accessed', 'tagErr', 'dataErr']
FSM_F = ['s_acquire', 's_rprobe', 's_pprobe', 's_release', 's_probeack', 's_refill', 's_cmoresp',
         'w_rprobeackfirst', 'w_rprobeacklast', 'w_pprobeackfirst', 'w_pprobeacklast',
         'w_grantfirst', 'w_grantlast', 'w_grant', 'w_releaseack', 'w_replResp', 's_rcompack', 's_dct']
CHIREQ_F = ['tgtID', 'srcID', 'txnID', 'opcode', 'addr', 'likelyshared', 'allowRetry', 'pCrdType',
            'memAttr_allocate', 'memAttr_cacheable', 'memAttr_device', 'memAttr_ewa', 'expCompAck']
STAGE = {0: 's5', 1: 's4', 2: 's3'}


def ports(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('module %s(' % mod)
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if m:
            out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out


def fname(f):
    return f + '_' if f in SV_KEYWORDS else f


def fields(P, prefix):
    return [(n[len(prefix):], w) for _, w, n in P if n.startswith(prefix)]


def build():
    P = ports(MOD)
    T = fields(P, 'io_taskFromArb_s2_bits_')
    assert len(T) == 94, len(T)
    for pre in ('io_toSourceD_bits_task_', 'io_toTXDAT_bits_task_'):
        assert fields(P, pre) == T, pre
    AP = ports('Arbiter3_TaskWithData')
    for k in range(3):
        assert fields(AP, 'io_in_%d_bits_task_' % k) == T
    RP = ports('Arbiter3_TaskBundle')
    rsp = [f for f, _ in fields(RP, 'io_out_bits_')]
    assert [f for f, _ in fields(P, 'io_toTXRSP_bits_')] == rsp
    assert [f for f, _ in fields(ports('Arbiter3_CHIREQ'), 'io_out_bits_')] == CHIREQ_F
    alloc = [f for f, _ in fields(P, 'io_toMSHRCtl_mshr_alloc_s3_bits_task_')]
    assert set(alloc) <= {f for f, _ in T}
    assert [f for f, _ in fields(P, 'io_toMSHRCtl_mshr_alloc_s3_bits_state_')] == FSM_F
    return P, T, rsp, alloc


def emit_struct(T):
    L = ['  // TaskBundle（%d 个字段，%d 位）：字段顺序与位宽逐字取自 golden 端口 io_taskFromArb_s2_bits_*' % (len(T), sum(w for _, w in T)),
         '  typedef struct packed {']
    for f, w in T:
        L.append('    logic %s%s;' % ('' if w == 1 else '[%d:0] ' % (w - 1), fname(f)))
    L.append('  } task_t;')
    return '\n'.join(L)


def emit_wrapper(P, T, rsp, alloc):
    L = []
    W = L.append
    W('module %s' % MOD)
    W('  import l2mainpipe_pkg::*;')
    W('(')
    W(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P))
    W(');')
    W('')
    decl = [('task_t', 's2_task'), ('meta_t', 'dir_meta'), ('meta_t', 'alloc_dir_meta'), ('fsm_state_t', 'alloc_state'),
            ('task_t', 'alloc_task'), ('meta_t', 'metaW_meta'), ('logic', 'hint_s3_valid'), ('task_t', 'hint_s3_task'),
            ('logic', 'hint_s3_need_mshr'), ('logic [30:0]', 'pft_tag'), ('logic', 'perf [13]'),
            ('logic', 'statusD_valid [3]'), ('logic [2:0]', 'statusD_channel [3]'),
            ('logic', 'statusTX_valid [3]'), ('logic [2:0]', 'statusTX_channel [3]'),
            ('logic [2:0]', 'statusTX_txChannel [3]'), ('logic', 'statusTX_mshrTask [3]')]
    for ch in ('d', 'txrsp', 'txdat'):
        decl += [('logic', '%s_valid [3]' % ch), ('task_t', '%s_task [3]' % ch), ('logic', '%s_ready [3]' % ch)]
    decl += [('logic [511:0]', 'd_data [3]'), ('logic [511:0]', 'txdat_data [3]'),
             ('logic', 'txreq_valid [3]'), ('chireq_t', 'txreq_bits [3]'), ('logic', 'txreq_ready [3]')]
    for ty, n in decl:
        W('  %-12s %s;' % (ty, n))
    W('')
    W('  // golden 端口 -> 结构体')
    for f, _ in T:
        W('  assign s2_task.%s = io_taskFromArb_s2_bits_%s;' % (fname(f), f))
    for f in META_F:
        W('  assign dir_meta.%s = io_dirResp_s3_bits_meta_%s;' % (fname(f), f))
    W('')
    conns = [('clock', 'clock'), ('reset', 'reset'),
             ('s1_b_tag', 'io_fromReqArb_status_s1_tags_1'),
             ('s1_c_set', 'io_fromReqArb_status_s1_sets_0'), ('s1_b_set', 'io_fromReqArb_status_s1_sets_1'),
             ('s1_a_set', 'io_fromReqArb_status_s1_sets_2'), ('s1_g_set', 'io_fromReqArb_status_s1_sets_3'),
             ('s2_valid', 'io_taskFromArb_s2_valid'), ('s2_task', 's2_task'),
             ('dir_valid', 'io_dirResp_s3_valid'), ('dir_hit', 'io_dirResp_s3_bits_hit'),
             ('dir_tag', 'io_dirResp_s3_bits_tag'), ('dir_set', 'io_dirResp_s3_bits_set'),
             ('dir_way', 'io_dirResp_s3_bits_way'), ('dir_meta', 'dir_meta'), ('dir_error', 'io_dirResp_s3_bits_error'),
             ('repl_valid', 'io_replResp_valid'), ('repl_way', 'io_replResp_bits_way'),
             ('repl_state', 'io_replResp_bits_meta_state'), ('repl_retry', 'io_replResp_bits_retry'),
             ('mshr_alloc_ptr', 'io_fromMSHRCtl_mshr_alloc_ptr'),
             ('c_releaseData', '{io_bufResp_data_1, io_bufResp_data_0}'),
             ('refillBuf_data', 'io_refillBufResp_s3_bits_data'),
             ('releaseBuf_valid', 'io_releaseBufResp_s3_valid'), ('releaseBuf_data', 'io_releaseBufResp_s3_bits_data'),
             ('ds_rdata_s5', 'io_toDS_rdata_s5_data'), ('ds_error_s5', 'io_toDS_error_s5'),
             ('blockG_s1', 'io_toReqArb_blockG_s1'), ('blockB_s1', 'io_toReqArb_blockB_s1'),
             ('blockC_s1', 'io_toReqArb_blockC_s1'), ('toReqBuf_0', 'io_toReqBuf_0'), ('toReqBuf_1', 'io_toReqBuf_1'),
             ('statusD_valid', 'statusD_valid'), ('statusD_channel', 'statusD_channel'),
             ('statusTX_valid', 'statusTX_valid'), ('statusTX_channel', 'statusTX_channel'),
             ('statusTX_txChannel', 'statusTX_txChannel'), ('statusTX_mshrTask', 'statusTX_mshrTask'),
             ('alloc_valid', 'io_toMSHRCtl_mshr_alloc_s3_valid'),
             ('alloc_dir_hit', 'io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit'),
             ('alloc_dir_tag', 'io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag'),
             ('alloc_dir_set', 'io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set'),
             ('alloc_dir_way', 'io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way'),
             ('alloc_dir_meta', 'alloc_dir_meta'),
             ('alloc_dir_error', 'io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error'),
             ('alloc_state', 'alloc_state'), ('alloc_task', 'alloc_task'),
             ('ds_en_s3', 'io_toDS_en_s3'), ('ds_req_valid', 'io_toDS_req_s3_valid'),
             ('ds_req_way', 'io_toDS_req_s3_bits_way'), ('ds_req_set', 'io_toDS_req_s3_bits_set'),
             ('ds_req_wen', 'io_toDS_req_s3_bits_wen'), ('ds_wdata', 'io_toDS_wdata_s3_data')]
    for ch in ('d', 'txreq', 'txrsp', 'txdat'):
        body = 'bits' if ch == 'txreq' else 'task'
        conns += [('%s_valid' % ch, '%s_valid' % ch), ('%s_%s' % (ch, body), '%s_%s' % (ch, body))]
        if ch in ('d', 'txdat'):
            conns.append(('%s_data' % ch, '%s_data' % ch))
        conns.append(('%s_ready' % ch, '%s_ready' % ch))
    conns += [('metaW_valid', 'io_metaWReq_valid'), ('metaW_set', 'io_metaWReq_bits_set'),
              ('metaW_wayOH', 'io_metaWReq_bits_wayOH'), ('metaW_meta', 'metaW_meta'),
              ('tagW_valid', 'io_tagWReq_valid'), ('tagW_set', 'io_tagWReq_bits_set'),
              ('tagW_way', 'io_tagWReq_bits_way'), ('tagW_tag', 'io_tagWReq_bits_wtag'),
              ('releaseBufW_valid', 'io_releaseBufWrite_valid'), ('s5_mshrId', 'io_releaseBufWrite_bits_id'),
              ('nwb_set', 'io_nestedwb_set'), ('nwb_tag', 'io_nestedwb_tag'),
              ('nwb_c_set_dirty', 'io_nestedwb_c_set_dirty'), ('nwb_c_set_tip', 'io_nestedwb_c_set_tip'),
              ('nwb_b_inv_dirty', 'io_nestedwb_b_inv_dirty'), ('nwb_b_toB', 'io_nestedwb_b_toB'),
              ('nwb_b_toN', 'io_nestedwb_b_toN'), ('nwb_b_toClean', 'io_nestedwb_b_toClean'),
              ('nwb_denied', 'io_nestedwb_denied'), ('nwb_corrupt', 'io_nestedwb_corrupt'),
              ('hint_s3_valid', 'hint_s3_valid'), ('hint_s3_task', 'hint_s3_task'),
              ('hint_s3_need_mshr', 'hint_s3_need_mshr'),
              ('pft_valid', 'io_prefetchTrain_valid'), ('pft_tag', 'pft_tag'), ('pft_set', 'io_prefetchTrain_bits_set'),
              ('pft_needT', 'io_prefetchTrain_bits_needT'), ('pft_source', 'io_prefetchTrain_bits_source'),
              ('pft_vaddr', 'io_prefetchTrain_bits_vaddr'), ('pft_hit', 'io_prefetchTrain_bits_hit'),
              ('pft_prefetched', 'io_prefetchTrain_bits_prefetched'),
              ('pft_pfsource', 'io_prefetchTrain_bits_pfsource'), ('pft_reqsource', 'io_prefetchTrain_bits_reqsource'),
              ('err_valid', 'io_error_valid'), ('err_bits_valid', 'io_error_bits_valid'),
              ('err_address', 'io_error_bits_address'), ('perf', 'perf')]
    W('  xs_MainPipe_1_core u_core (')
    W(',\n'.join('    .%-18s (%s)' % c for c in conns))
    W('  );')
    W('')
    # 直接输出
    for i in range(3):
        W('  assign io_status_vec_toD_%d_valid = statusD_valid[%d];' % (i, i))
        W('  assign io_status_vec_toD_%d_bits_channel = statusD_channel[%d];' % (i, i))
    for i in range(3):
        for f in ('valid', 'bits_channel', 'bits_txChannel', 'bits_mshrTask'):
            src = {'valid': 'statusTX_valid', 'bits_channel': 'statusTX_channel',
                   'bits_txChannel': 'statusTX_txChannel', 'bits_mshrTask': 'statusTX_mshrTask'}[f]
            W('  assign io_status_vec_toTX_%d_%s = %s[%d];' % (i, f, src, i))
    for f in META_F:
        W('  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_%s = alloc_dir_meta.%s;' % (f, fname(f)))
    for f in FSM_F:
        W('  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_%s = alloc_state.%s;' % (f, f))
    for f in alloc:
        W('  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_%s = alloc_task.%s;' % (f, fname(f)))
    for f in META_F:
        W('  assign io_metaWReq_bits_wmeta_%s = metaW_meta.%s;' % (f, fname(f)))
    W('  assign io_releaseBufWrite_bits_data_data = io_toDS_rdata_s5_data;')
    W('  assign io_dsResp_valid = io_releaseBufWrite_valid;')
    W('  assign io_dsResp_bits_mshrId = io_releaseBufWrite_bits_id;')
    W('  assign io_dsResp_bits_dataError = io_toDS_error_s5;')
    W('  assign io_nestedwbData_data = {io_bufResp_data_1, io_bufResp_data_0};')
    W("  assign io_prefetchTrain_bits_tag = {2'b00, pft_tag};   // PrefetchTrain.tag 比 L2 tag 宽 2 位")
    for i in range(13):
        W("  assign io_perf_%d_value = {5'd0, perf[%d]};" % (i, i))
    W('')
    # CustomL1Hint
    W('  CustomL1Hint customL1Hint (')
    hc = [('clock', 'clock'), ('reset', 'reset')]
    for f in ('valid', 'bits_channel', 'bits_isKeyword', 'bits_opcode', 'bits_sourceId', 'bits_mshrTask', 'bits_mergeA',
              'bits_aMergeTask_isKeyword', 'bits_aMergeTask_opcode', 'bits_aMergeTask_sourceId'):
        hc.append(('io_s1_%s' % f, 'io_taskInfo_s1_%s' % f))
    hc.append(('io_s3_task_valid', 'hint_s3_valid'))
    for f in ('channel', 'isKeyword', 'opcode', 'sourceId', 'mshrTask'):
        hc.append(('io_s3_task_bits_%s' % f, 'hint_s3_task.%s' % f))
    hc += [('io_s3_need_mshr', 'hint_s3_need_mshr'), ('io_l1Hint_ready', 'io_l1Hint_ready'),
           ('io_l1Hint_valid', 'io_l1Hint_valid'), ('io_l1Hint_bits_sourceId', 'io_l1Hint_bits_sourceId'),
           ('io_l1Hint_bits_isKeyword', 'io_l1Hint_bits_isKeyword')]
    W(',\n'.join('    .%-32s (%s)' % c for c in hc))
    W('  );')
    W('')
    W('  // 四个出口仲裁器：第 k 路 = 核的 [k]（0=s5 1=s4 2=s3，s5 优先级最高）')
    # toSourceD / toTXDAT：TaskWithData
    for inst, ch, outp, has_ready in (('toSourceD_arb', 'd', 'io_toSourceD', False),
                                      ('toTXDAT_arb', 'txdat', 'io_toTXDAT', True)):
        W('  Arbiter3_TaskWithData %s (' % inst)
        c = []
        for k in range(3):
            c += [('io_in_%d_ready' % k, '%s_ready[%d]' % (ch, k)), ('io_in_%d_valid' % k, '%s_valid[%d]' % (ch, k))]
            c += [('io_in_%d_bits_task_%s' % (k, f), '%s_task[%d].%s' % (ch, k, fname(f))) for f, _ in T]
            c.append(('io_in_%d_bits_data_data' % k, '%s_data[%d]' % (ch, k)))
        c += [('io_out_ready', 'io_toTXDAT_ready' if has_ready else "1'b1"), ('io_out_valid', '%s_valid' % outp)]
        c += [('io_out_bits_task_%s' % f, '%s_bits_task_%s' % (outp, f)) for f, _ in T]
        c.append(('io_out_bits_data_data', '%s_bits_data_data' % outp))
        W(',\n'.join('    .%-40s (%s)' % x for x in c))
        W('  );')
    # toTXREQ：CHIREQ（无 in_0_ready）
    W("  assign txreq_ready[0] = 1'b1;   // out.ready 恒 1 => 第 0 路永远 ready（golden 删了这根）")
    W('  Arbiter3_CHIREQ toTXREQ_arb (')
    c = []
    for k in range(3):
        if k:
            c.append(('io_in_%d_ready' % k, 'txreq_ready[%d]' % k))
        c.append(('io_in_%d_valid' % k, 'txreq_valid[%d]' % k))
        c += [('io_in_%d_bits_%s' % (k, f), 'txreq_bits[%d].%s' % (k, f)) for f in CHIREQ_F]
    c.append(('io_out_valid', 'io_toTXREQ_valid'))
    c += [('io_out_bits_%s' % f, 'io_toTXREQ_bits_%s' % f) for f in CHIREQ_F]
    W(',\n'.join('    .%-30s (%s)' % x for x in c))
    W('  );')
    W("  assign txrsp_ready[0] = 1'b1;")
    W('  Arbiter3_TaskBundle toTXRSP_arb (')
    c = []
    for k in range(3):
        if k:
            c.append(('io_in_%d_ready' % k, 'txrsp_ready[%d]' % k))
        c.append(('io_in_%d_valid' % k, 'txrsp_valid[%d]' % k))
        c += [('io_in_%d_bits_%s' % (k, f), 'txrsp_task[%d].%s' % (k, fname(f))) for f in rsp]
    c.append(('io_out_valid', 'io_toTXRSP_valid'))
    c += [('io_out_bits_%s' % f, 'io_toTXRSP_bits_%s' % f) for f in rsp]
    W(',\n'.join('    .%-24s (%s)' % x for x in c))
    W('  );')
    W('')
    W('endmodule')
    return '\n'.join(L)


def replace_region(txt, tag, body):
    b = re.search(r'(// BEGIN GENERATED\(%s\)[^\n]*\n)(.*?)(// END GENERATED\(%s\))' % (tag, tag), txt, re.S)
    assert b, '找不到 GENERATED(%s) 区' % tag
    indent = re.match(r'\s*', txt[txt.rfind('\n', 0, b.start()) + 1:]).group(0)
    return txt[:b.start()] + b.group(1) + body + '\n' + indent + b.group(3) + txt[b.end():]


def with_nav(txt):
    if txt.count('\n') + 1 <= 1500:
        return txt
    import tempfile
    import pathlib
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import gen_file_nav
    with tempfile.TemporaryDirectory() as d:
        tmp = pathlib.Path(d) / 'MainPipe_1.sv'
        tmp.write_text(txt)
        gen_file_nav.apply(tmp)
        return tmp.read_text()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    P, T, rsp, alloc = build()
    cur = open(RTL).read()
    new = replace_region(cur, 'task_t', emit_struct(T))
    new = replace_region(new, 'wrapper', emit_wrapper(P, T, rsp, alloc))
    new = with_nav(new)
    if a.check:
        if cur != new:
            print('DRIFT: %s' % RTL)
            return 1
        return 0
    if cur != new:
        open(RTL, 'w').write(new)
    print('MainPipe_1: task_t %d 字段 / %d 位；alloc 字段 %d；TXRSP 字段 %d' % (len(T), sum(w for _, w in T), len(alloc), len(rsp)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
