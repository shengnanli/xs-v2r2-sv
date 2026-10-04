#!/usr/bin/env python3
"""gen_tl2chi.py —— 生成 rtl/uncore/TL2CHICoupledL2.sv 的 golden 同名 wrapper 区（手写核 xs_TL2CHICoupledL2_core 一个字节都不动）。

TL2CHICoupledL2（coupledL2 tl2chi/TL2CHICoupledL2.scala + CoupledL2.scala）= 32 个已签核 child + 少量胶合逻辑。
胶合逻辑全在手写核里；本脚本只生成 GENERATED(tl2chi-wrapper) 区（下列规则的实现在 scripts/parent_wrapper_lib.py，与 gen_l2top.py 共用）：
  * wrapper 端口 = golden 端口（逐行同名同宽同序）；
  * 32 个 child 按 golden 的实例名 / 模块名 / 顺序例化；每个 child 输出接一根线 <实例名>_<端口名>
    （golden 直接接到顶层输出口的，照接顶层口）；
  * 每个 child 输入的来源从 golden 连线表现读，必须恰好落在下面一类：
      - golden 连的是顶层输入口 / 另一个 child 的输出（可带位选） → 照接（child 输出换成本文件的线名）；
      - golden 连的是字面常量 → 照抄常量；
      - 其余（golden 在那里写了表达式 / 本层寄存器）→ 必须在 CORE_DRIVES 里有一条，接到核的某个输出（元素）；
    两类都不命中、或一个端口命中两类 → 生成失败；
  * 每个顶层输出必须恰好有一个驱动者（child 输出 / golden assign 的 child 线 / CORE_TOP_DRIVES 里的核输出），否则失败；
  * 核的端口表从手写核现读，每个核输入必须在 CORE_GATHER 里有来源（逐元素），每个核输出至少被用一次，否则失败；
  * CORE_DRIVES / CORE_TOP_DRIVES 里每一条都必须被用到（防陈旧规则）。

用法：python3 scripts/gen_tl2chi.py [--check]
  --check：不写文件，只比较生成结果与库里文件是否逐字相同（漂移 → rc=1）。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parent_wrapper_lib as lib  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, 'rtl', 'uncore', 'TL2CHICoupledL2.sv')
TOP = 'TL2CHICoupledL2'
CORE = 'xs_TL2CHICoupledL2_core'
TAG = 'tl2chi-wrapper'
NS = 4            # slice 数
PERF = 17         # 每 slice 的 perf 事件数（第 2 号在 golden 里已消掉，接常 0）
NPCRD = 80        # P-Credit 查询口：MMIO 16 + 4 × 16
PARAMS = {'NUM_SLICES': NS, 'PERF_PER_SLICE': PERF, 'NUM_PCRD': NPCRD}

SLICE = ['slices_%d' % i for i in range(NS)]
TRAIN = ['train_pipeline' + ('' if i == 0 else '_%d' % i) for i in range(NS)]


# ---------------------------------------------------------------------------
# 核的输入来源（CORE_GATHER）：核端口 -> 标量的线名，或 [(下标文本, 线名)]（逐元素赋值）
# 线名里的 <inst>.<port> 记号表示"该 child 输出的线"，由 net() 换成真实线名。
# ---------------------------------------------------------------------------
def per_slice(fmt):
    return [('[%d]' % i, fmt.format(s=SLICE[i], i=i, t=TRAIN[i])) for i in range(NS)]


def slice_perf():
    out = []
    for i in range(NS):
        for k in range(PERF):
            out.append(('[%d][%d]' % (i, k), "6'h0" if k == 2 else '%s.io_perf_%d_value' % (SLICE[i], k)))
    return out


def pcrd(field):
    out = []
    for k in range(NPCRD):
        if k < 16:
            out.append(('[%d]' % k, 'mmioBridge.io_pCrd_%d_query_%s' % (k, field)))
        else:
            out.append(('[%d]' % k, '%s.io_pCrd_%d_query_%s' % (SLICE[(k - 16) // 16], (k - 16) % 16, field)))
    return out


CORE_GATHER = {
    'clock': 'clock', 'reset': 'reset',
    # §1
    'hintArb_valid': 'l1HintArb.io_out_valid',
    'hintArb_sourceId': 'l1HintArb.io_out_bits_sourceId',
    'hintArb_chosen': 'l1HintArb.io_chosen',
    'slice_dValid': per_slice('{s}.io_in_d_valid'),
    'slice_dOpcode': per_slice('{s}.io_in_d_bits_opcode'),
    'in_dReady': per_slice('auto_in_{i}_d_ready'),
    # §2
    'pf_reqValid': 'prefetcher.io_req_valid',
    'pf_reqSet': 'prefetcher.io_req_bits_set',
    'slice_pfReqReady': per_slice('{s}.io_prefetch_req_ready'),
    'train_tag': per_slice('{t}.io_out_bits_tag'),
    'train_set': per_slice('{t}.io_out_bits_set'),
    # §3
    'slice_bAddr': per_slice('{s}.io_in_b_bits_address'),
    'slice_errAddr': per_slice('{s}.io_error_bits_address'),
    'eccArb_outValid': 'l2ECCArb.io_out_valid',
    'eccArb_outBitsValid': 'l2ECCArb.io_out_bits_valid',
    # §4
    'slice_perf': slice_perf(),
    'slice_l2Miss': per_slice('{s}.io_l2Miss'),
    # §5
    'txReqArb_outValid': 'txreq_arb.io_out_valid',
    'txReqArb_chosen': 'txreq_arb.io_chosen',
    'txReqArb_outTxnID': 'txreq_arb.io_out_bits_txnID',
    'txReqArb_mmioReady': 'txreq_arb.io_in_4_ready',
    'mmio_txReqValid': 'mmioBridge.io_tx_req_valid',
    'lm_txReqReady': 'linkMonitor.io_in_tx_req_ready',
    'lm_syscoreq': 'linkMonitor.io_out_syscoreq',
    'chi_syscoack': 'io_chi_syscoack',
    # §6
    'rxSnp_valid': 'linkMonitor.io_in_rx_snp_valid',
    'rxSnp_bank': 'linkMonitor.io_in_rx_snp_bits_addr[4:3]',
    'slice_rxSnpReady': per_slice('{s}.io_out_rx_snp_ready'),
    # §7（Slice 的 RXRSP / RXDAT 恒可收：golden Slice 没有这两个 ready 口）
    'rxRsp_valid': 'rxrspPipe_pipeline.io_out_valid',
    'rxRsp_opcode': 'rxrspPipe_pipeline.io_out_bits_opcode',
    'rxRsp_txnID': 'rxrspPipe_pipeline.io_out_bits_txnID',
    'slice_rxRspReady': [('[%d]' % i, "1'b1") for i in range(NS)],
    'mmio_rxRspReady': 'mmioBridge.io_rx_rsp_ready',
    'rxDat_valid': 'rxdatPipe_pipeline.io_out_valid',
    'rxDat_txnID': 'rxdatPipe_pipeline.io_out_bits_txnID',
    'slice_rxDatReady': [('[%d]' % i, "1'b1") for i in range(NS)],
    'mmio_rxDatReady': 'mmioBridge.io_rx_dat_ready',
    # §8
    'rxRsp_pCrdType': 'rxrspPipe_pipeline.io_out_bits_pCrdType',
    'rxRsp_srcID': 'rxrspPipe_pipeline.io_out_bits_srcID',
    'pcrdHead_valid': 'pCrdQueue_s3.io_deq_valid',
    'pcrdHead_pCrdType': 'pCrdQueue_s3.io_deq_bits_pCrdType',
    'pcrdHead_srcID': 'pCrdQueue_s3.io_deq_bits_srcID',
    'pcrdQuery_valid': pcrd('valid'),
    'pcrdQuery_pCrdType': pcrd('bits_pCrdType'),
    'pcrdQuery_srcID': pcrd('bits_srcID'),
    'pcrdArb_outValid': 'pcrdgrant_arb.io_out_valid',
}

# ---------------------------------------------------------------------------
# golden 在 child 输入上写了表达式的地方 → 核输出（元素）
# ---------------------------------------------------------------------------
CORE_DRIVES = {
    ('mmioBridge', 'io_rx_rsp_valid'): 'mmio_rxRspValid',
    ('mmioBridge', 'io_rx_rsp_bits_txnID'): 'rxRsp_innerTxnID',
    ('mmioBridge', 'io_rx_dat_valid'): 'mmio_rxDatValid',
    ('mmioBridge', 'io_rx_dat_bits_txnID'): 'rxDat_innerTxnID',
    ('prefetcher', 'io_req_ready'): 'pf_reqReady',
    ('l1HintArb', 'io_out_ready'): 'hintArb_ready',
    ('hintPipe2', 'io_in_valid'): 'hintFire',
    ('hintPipe1', 'io_in_valid'): 'hintFire',
    ('txreq_arb', 'io_out_ready'): 'txReqArb_outReady',
    ('pCrdQueue_s2', 'io_enq_valid'): 'pcrdEnq_valid',
    ('pCrdQueue_s2', 'io_enq_bits_pCrdType'): 'pcrdEnq_pCrdType',
    ('pCrdQueue_s2', 'io_enq_bits_srcID'): 'pcrdEnq_srcID',
    ('linkMonitor', 'io_in_tx_req_valid'): 'lm_txReqValid',
    ('linkMonitor', 'io_in_tx_req_bits_txnID'): 'lm_txReqTxnID',
    ('linkMonitor', 'io_in_rx_snp_ready'): 'rxSnp_ready',
    ('rxdatPipe_pipeline', 'io_out_ready'): 'rxDat_ready',
    ('rxrspPipe_pipeline', 'io_out_ready'): 'rxRsp_ready',
}
for _i in range(NS):
    CORE_DRIVES[('prefetch_train_arb', 'io_in_%d_bits_tag' % _i)] = 'trainArb_tag[%d]' % _i
    CORE_DRIVES[('prefetch_train_arb', 'io_in_%d_bits_set' % _i)] = 'trainArb_set[%d]' % _i
    CORE_DRIVES[(SLICE[_i], 'io_in_d_ready')] = 'slice_dReady[%d]' % _i
    CORE_DRIVES[(SLICE[_i], 'io_prefetch_req_valid')] = 'slice_pfReqValid[%d]' % _i
    CORE_DRIVES[(SLICE[_i], 'io_out_rx_rsp_valid')] = 'slice_rxRspValid[%d]' % _i
    CORE_DRIVES[(SLICE[_i], 'io_out_rx_rsp_bits_txnID')] = 'rxRsp_innerTxnID'
    CORE_DRIVES[(SLICE[_i], 'io_out_rx_dat_valid')] = 'slice_rxDatValid[%d]' % _i
    CORE_DRIVES[(SLICE[_i], 'io_out_rx_dat_bits_txnID')] = 'rxDat_innerTxnID'
    CORE_DRIVES[(SLICE[_i], 'io_out_rx_snp_valid')] = 'slice_rxSnpValid[%d]' % _i
    CORE_DRIVES[('l2ECCArb', 'io_in_%d_bits_address' % _i)] = 'eccArb_addr[%d]' % _i
for _k in range(NPCRD):
    CORE_DRIVES[('pcrdgrant_arb', 'io_in_%d_valid' % _k)] = 'pcrdHit[%d]' % _k

# 顶层输出里 golden 写了表达式 / 接本层寄存器的 → 核输出
CORE_TOP_DRIVES = {
    'io_l2_hint_valid': 'hintFire',
    'io_l2Miss': 'l2Miss',
    'io_error_valid': 'errorValid',
}
for _i in range(NS):
    CORE_TOP_DRIVES['auto_in_%d_b_bits_address' % _i] = 'in_bAddr[%d]' % _i
    CORE_TOP_DRIVES['auto_in_%d_d_valid' % _i] = 'in_dValid[%d]' % _i
for _k in range(1, NS * PERF + 1):
    CORE_TOP_DRIVES['io_perf_%d_value' % _k] = 'perf[%d]' % (_k - 1)


SPEC = lib.Spec(top=TOP, core=CORE, out=OUT, tag=TAG, params=PARAMS, gather=CORE_GATHER,
                drives=CORE_DRIVES, top_drives=CORE_TOP_DRIVES, name='gen_tl2chi')

if __name__ == '__main__':
    sys.exit(lib.main(SPEC, sys.argv[1:]))
