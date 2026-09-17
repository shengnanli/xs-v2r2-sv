#!/usr/bin/env python3
"""gen.py —— 生成 NCBTransactionQueue 家族的两个薄 wrapper 与 UT testbench。

为什么必须生成：两个 golden 变体的端口表分别是 **2268 / 1212** 个标量端口
（strobe 是逐槽展平的），手抄必错；tb 还要把每个端口各连两遍（golden / 重写）。
这里直接从 G1 golden 的端口表原样搬过来，再按下面的 VARIANTS 表接到参数化核
xs_NCBTransactionQueue_core 上。

VARIANTS 表里的每一项都是**实测**的：
  * N / HAS_ORDER / HAS_DEVICE / HAS_AR_READY_BARRIER 由 golden 端口表与寄存器
    清单反推，并与 XiangShan src/main/scala/top/Top.scala 里两处 NCBParameters
    对上（outstandingDepth / axiMasterOrder / acceptMemAttrDevice /
    readReceiptAfterAcception）。
  * ★立项时的猜测「两个变体是同一设计的纯尺寸单态化」被实测推翻★：除 64/32 之外
    还有三处**特性**差异，见两个 wrapper 的文件头。

用法：python3 gen.py        （幂等：内容不变不碰文件）
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = REPO / 'rtl' / 'uncore'

sys.path.insert(0, str(REPO / 'scripts'))
import gen_file_nav  # noqa: E402  —— wrapper 超过 1500 行，必须带「本文件导航」

# ---------------------------------------------------------------------------
# 变体表
# ---------------------------------------------------------------------------
VARIANTS = {
    'NCBTransactionQueue': dict(
        n=64, has_order=1, has_device=0, has_ar_barrier=0,
        role='CHI→AXI 的 **LLC 桥**（Top.scala chi_llcBridge_opt）',
        params=('outstandingDepth=64, axiMasterOrder=WriteAddress, '
                'acceptMemAttrDevice=false, readReceiptAfterAcception=false'),
    ),
    'NCBTransactionQueue_1': dict(
        n=32, has_order=0, has_device=1, has_ar_barrier=1,
        role='CHI→AXI 的 **MMIO 桥**（Top.scala chi_mmioBridge_opt，每核一份）',
        params=('outstandingDepth=32, axiMasterOrder=None, '
                'acceptMemAttrDevice=true, readReceiptAfterAcception=true'),
    ),
}

# 逐槽展平的向量端口组：golden 名前缀 -> 核侧信号名
IN_VEC = {
    'io_allocate_strb':                      'alloc_strb',
    'io_upstreamRxDat_query_strb':            'rxdat_query_strb',
    'io_upstreamRxDat_cancel_strb':           'rxdat_cancel_strb',
    'io_upstreamRxDat_writeData_strb':        'rxdat_write_data_strb',
    'io_upstreamTxRsp_opRead_strb':           'txrsp_op_read_strb',
    'io_upstreamTxRsp_opDone_strb':           'txrsp_op_done_strb',
    'io_upstreamTxRsp_infoRead_strb':         'txrsp_info_read_strb',
    'io_upstreamTxDat_opRead_strb':           'txdat_op_read_strb',
    'io_upstreamTxDat_opDone_strb':           'txdat_op_done_strb',
    'io_upstreamTxDat_infoRead_strb':         'txdat_info_read_strb',
    'io_upstreamTxDat_operandRead_strb':      'txdat_operand_read_strb',
    'io_upstreamTxDat_operandWrite_strb':     'txdat_operand_write_strb',
    'io_downstreamAw_opPoNR_strb':            'aw_op_ponr_strb',
    'io_downstreamAw_infoRead_strb':          'aw_info_read_strb',
    'io_downstreamAw_operandRead_strb':       'aw_operand_read_strb',
    'io_downstreamW_opPoNR_strb':             'w_op_ponr_strb',
    'io_downstreamW_operandRead_strb':        'w_operand_read_strb',
    'io_downstreamW_operandWrite_strb':       'w_operand_write_strb',
    'io_downstreamB_opDone_strb':             'b_op_done_strb',
    'io_downstreamAr_opPoNR_strb':            'ar_op_ponr_strb',
    'io_downstreamAr_opDone_strb':            'ar_op_done_strb',
    'io_downstreamAr_infoRead_strb':          'ar_info_read_strb',
    'io_downstreamAr_operandRead_strb':       'ar_operand_read_strb',
    'io_downstreamR_opDone_strb':             'r_op_done_strb',
    'io_downstreamR_operandRead_strb':        'r_operand_read_strb',
    'io_downstreamR_operandAXIWrite_strb':    'r_operand_axi_write_strb',
}
OUT_VEC = {
    'io_free_strb':                    'free_strb',
    'io_upstreamTxRsp_opValid_valid':  'txrsp_op_valid',
    'io_upstreamTxDat_opValid_valid':  'txdat_op_valid',
    'io_downstreamAw_opValid_valid':   'aw_op_valid',
    'io_downstreamAr_opValid_valid':   'ar_op_valid',
    'debug_DoubleAllocation':          'dbg_double_allocation',
    'debug_DanglingAXIWriteResponse':  'dbg_dangling_axi_write_response',
}
# 二维：io_upstreamTxDat_opValid_bits_Critical_<槽>_<拍>
OUT_MAT_PREFIX = 'io_upstreamTxDat_opValid_bits_Critical_'

# 标量端口 -> 核侧表达式（None = 该端口在核侧无对应，见注释）
SCALAR = {
    'io_allocate_en': 'alloc_en',
    'io_allocate_bits_op_chi_Comp_valid': 'alloc_op_chi_comp_valid',
    'io_allocate_bits_op_chi_Comp_barrier_CHICancelOrAXIBresp': 'alloc_op_chi_comp_barrier',
    'io_allocate_bits_op_chi_DBIDResp_valid': 'alloc_op_chi_dbidresp_valid',
    'io_allocate_bits_op_chi_CompDBIDResp_valid': 'alloc_op_chi_compdbidresp_valid',
    'io_allocate_bits_op_chi_ReadReceipt_valid': 'alloc_op_chi_readreceipt_valid',
    'io_allocate_bits_op_chi_CompData_valid': 'alloc_op_chi_compdata_valid',
    'io_allocate_bits_op_chi_CompData_sep': 'alloc_op_chi_compdata_sep',
    'io_allocate_bits_op_axi_WriteAddress_valid': 'alloc_op_axi_wa_valid',
    'io_allocate_bits_op_axi_WriteAddress_barrier_CHIWriteBackData': 'alloc_op_axi_wa_barrier',
    'io_allocate_bits_op_axi_WriteData_valid': 'alloc_op_axi_wd_valid',
    'io_allocate_bits_op_axi_WriteResponse_valid': 'alloc_op_axi_wresp_valid',
    'io_allocate_bits_op_axi_ReadAddress_valid': 'alloc_op_axi_ra_valid',
    'io_allocate_bits_op_axi_ReadData_valid': 'alloc_op_axi_rd_valid',
    'io_allocate_bits_info_QoS': 'alloc_info_qos',
    'io_allocate_bits_info_TgtID': 'alloc_info_tgt_id',
    'io_allocate_bits_info_SrcID': 'alloc_info_src_id',
    'io_allocate_bits_info_TxnID': 'alloc_info_txn_id',
    'io_allocate_bits_info_ReturnNID': 'alloc_info_return_nid',
    'io_allocate_bits_info_ReturnTxnID': 'alloc_info_return_txn_id',
    'io_allocate_bits_operand_chi_Addr': 'alloc_chi_addr',
    'io_allocate_bits_operand_chi_WriteFull': 'alloc_chi_write_full',
    'io_allocate_bits_operand_chi_WritePtl': 'alloc_chi_write_ptl',
    'io_allocate_bits_operand_chi_Critical_0': 'alloc_chi_critical[0]',
    'io_allocate_bits_operand_chi_Critical_1': 'alloc_chi_critical[1]',
    'io_allocate_bits_operand_chi_Count': 'alloc_chi_count',
    'io_allocate_bits_operand_axi_Addr': 'alloc_axi_addr',
    'io_allocate_bits_operand_axi_Size': 'alloc_axi_size',
    'io_allocate_bits_operand_axi_Len': 'alloc_axi_len',
    'io_allocate_bits_operand_axi_Device': 'alloc_axi_device',
    'io_allocate_bits_operand_axi_Critical_0': 'alloc_axi_critical[0]',
    'io_allocate_bits_operand_axi_Critical_1': 'alloc_axi_critical[1]',
    'io_allocate_bits_operand_axi_Count': 'alloc_axi_count',
    'io_allocate_bits_order_valid': 'alloc_order_valid',
    'io_allocate_bits_order_index': 'alloc_order_index',

    'io_upstreamRxDat_query_en': 'rxdat_query_en',
    'io_upstreamRxDat_query_result_valid': 'rxdat_query_valid',
    'io_upstreamRxDat_query_result_WriteFull': 'rxdat_query_write_full',
    'io_upstreamRxDat_query_result_WritePtl': 'rxdat_query_write_ptl',
    'io_upstreamRxDat_cancel_en': 'rxdat_cancel_en',
    'io_upstreamRxDat_writeData_en': 'rxdat_write_data_en',

    'io_upstreamTxRsp_opRead_bits_Comp': 'txrsp_op_read_comp',
    'io_upstreamTxRsp_opRead_bits_DBIDResp': 'txrsp_op_read_dbidresp',
    'io_upstreamTxRsp_opRead_bits_CompDBIDResp': 'txrsp_op_read_compdbidresp',
    'io_upstreamTxRsp_opRead_bits_ReadReceipt': 'txrsp_op_read_readreceipt',
    'io_upstreamTxRsp_opDone_bits_Comp': 'txrsp_op_done_comp',
    'io_upstreamTxRsp_opDone_bits_DBIDResp': 'txrsp_op_done_dbidresp',
    'io_upstreamTxRsp_opDone_bits_CompDBIDResp': 'txrsp_op_done_compdbidresp',
    'io_upstreamTxRsp_opDone_bits_ReadReceipt': 'txrsp_op_done_readreceipt',
    'io_upstreamTxRsp_infoRead_bits_QoS': 'txrsp_info_read_bits[37:34]',
    'io_upstreamTxRsp_infoRead_bits_TgtID': 'txrsp_info_read_bits[33:23]',
    'io_upstreamTxRsp_infoRead_bits_SrcID': 'txrsp_info_read_bits[22:12]',
    'io_upstreamTxRsp_infoRead_bits_TxnID': 'txrsp_info_read_bits[11:0]',
    'io_upstreamTxRsp_operandRead_bits_WriteRespErr': 'txrsp_operand_write_resp_err',

    'io_upstreamTxDat_opRead_bits_CompData_valid': 'txdat_op_read_compdata_valid',
    'io_upstreamTxDat_opRead_bits_CompData_sep': 'txdat_op_read_compdata_sep',
    'io_upstreamTxDat_opDone_bits_CompData': 'txdat_op_done_compdata',
    'io_upstreamTxDat_infoRead_bits_QoS': 'txdat_info_read_bits[37:34]',
    'io_upstreamTxDat_infoRead_bits_TgtID': 'txdat_info_read_bits[33:23]',
    'io_upstreamTxDat_infoRead_bits_SrcID': 'txdat_info_read_bits[22:12]',
    'io_upstreamTxDat_infoRead_bits_TxnID': 'txdat_info_read_bits[11:0]',
    'io_upstreamTxDat_operandRead_bits_Addr': 'txdat_operand_read_addr',
    'io_upstreamTxDat_operandRead_bits_ReadRespErr': 'txdat_operand_read_read_resp_err',
    'io_upstreamTxDat_operandRead_bits_Critical_0': 'txdat_operand_read_critical[0]',
    'io_upstreamTxDat_operandRead_bits_Critical_1': 'txdat_operand_read_critical[1]',
    'io_upstreamTxDat_operandRead_bits_Count': 'txdat_operand_read_count',
    'io_upstreamTxDat_operandWrite_bits_Critical_0': 'txdat_operand_write_critical[0]',
    'io_upstreamTxDat_operandWrite_bits_Critical_1': 'txdat_operand_write_critical[1]',
    'io_upstreamTxDat_operandWrite_bits_Count': 'txdat_operand_write_count',

    'io_downstreamAw_infoRead_bits_QoS': 'aw_info_read_qos',
    'io_downstreamAw_operandRead_bits_Addr': 'aw_operand_read_addr',
    'io_downstreamAw_operandRead_bits_Burst': 'aw_operand_read_burst',
    'io_downstreamAw_operandRead_bits_Size': 'aw_operand_read_size',
    'io_downstreamAw_operandRead_bits_Len': 'aw_operand_read_len',

    'io_downstreamW_operandRead_bits_Critical_0': 'w_operand_read_critical[0]',
    'io_downstreamW_operandRead_bits_Critical_1': 'w_operand_read_critical[1]',
    'io_downstreamW_operandRead_bits_Count': 'w_operand_read_count',
    'io_downstreamW_operandWrite_bits_Critical_0': 'w_operand_write_critical[0]',
    'io_downstreamW_operandWrite_bits_Critical_1': 'w_operand_write_critical[1]',
    'io_downstreamW_operandWrite_bits_Count': 'w_operand_write_count',

    'io_downstreamAr_infoRead_bits_QoS': 'ar_info_read_qos',
    'io_downstreamAr_operandRead_bits_Addr': 'ar_operand_read_addr',
    'io_downstreamAr_operandRead_bits_Burst': 'ar_operand_read_burst',
    'io_downstreamAr_operandRead_bits_Size': 'ar_operand_read_size',
    'io_downstreamAr_operandRead_bits_Len': 'ar_operand_read_len',
    'io_downstreamAr_operandRead_bits_Device': 'ar_operand_read_device',

    'io_downstreamR_operandRead_bits_Critical_0': 'r_operand_read_critical[0]',
    'io_downstreamR_operandRead_bits_Critical_1': 'r_operand_read_critical[1]',
    'io_downstreamR_operandRead_bits_Count': 'r_operand_read_count',
    'io_downstreamR_operandAXIWrite_bits_Critical_0': 'r_operand_axi_write_critical[0]',
    'io_downstreamR_operandAXIWrite_bits_Critical_1': 'r_operand_axi_write_critical[1]',
    'io_downstreamR_operandAXIWrite_bits_Count': 'r_operand_axi_write_count',
}

PORT_RE = re.compile(r'^\s*(input|output)\s*(\[\s*\d+\s*:\s*0\s*\])?\s*(\w+)\s*,?\s*$')


def golden_ports(mod):
    """从 golden 的端口表原样读出 (方向, 位宽声明, 名字) 三元组，保持顺序。"""
    txt = (GOLDEN / f'{mod}.sv').read_text().splitlines()
    i = next(k for k, l in enumerate(txt) if l.startswith(f'module {mod}('))
    out = []
    for l in txt[i + 1:]:
        if l.startswith(');'):
            break
        m = PORT_RE.match(l)
        assert m, f'{mod}: 端口表里有没认出来的行: {l!r}'
        out.append((m.group(1), (m.group(2) or '').strip(), m.group(3)))
    return out


def width_of(decl):
    return 1 if not decl else int(decl[1:-1].split(':')[0]) + 1


def split_index(name, n):
    """把逐槽展平的端口名拆成 (组前缀, 槽号) —— 只认 0..n-1 的后缀。"""
    m = re.match(r'^(.*)_(\d+)$', name)
    if not m:
        return None
    idx = int(m.group(2))
    return (m.group(1), idx) if idx < n else None


# ---------------------------------------------------------------------------
# wrapper
# ---------------------------------------------------------------------------
CORE_SIGS = """\
  // 核侧信号（名字与 xs_NCBTransactionQueue_core 的端口一一对应）
  logic [N-1:0]  free_strb;
  logic          alloc_en;
  logic [N-1:0]  alloc_strb;
  // ★位宽写字面值而不是引用核文件里的包★：跨文件共享 package 会制造文件顺序依赖
  // （VCS 报 SV-LCM-PND），本仓 scripts/check_pkg_scope.py 直接判违规。所以
  // ncb_txnq_pkg 只服务核文件自己，wrapper 这边全用字面位宽，并在注释里标出出处。
  logic [12:0]   alloc_op_bits;     // ncb_op_t：13 个 op 位，字段顺序见核文件 §1
  logic [60:0]   alloc_info_bits;   // ncb_info_t：QoS4+TgtID11+SrcID11+TxnID12
                                    //             +ReturnNID11+ReturnTxnID12
  logic [47:0]   alloc_chi_addr;
  logic          alloc_chi_write_full, alloc_chi_write_ptl;
  logic [1:0] alloc_chi_critical;
  logic [0:0]  alloc_chi_count;
  logic [48:0] alloc_axi_addr;
  logic [2:0] alloc_axi_size;
  logic [7:0]  alloc_axi_len;
  logic          alloc_axi_device;
  logic [1:0] alloc_axi_critical;
  logic [0:0]  alloc_axi_count;
  logic          alloc_order_valid;
  logic [IDX_W-1:0] alloc_order_index;

  logic          rxdat_query_en, rxdat_query_valid;
  logic          rxdat_query_write_full, rxdat_query_write_ptl;
  logic [1:0] rxdat_query_read_resp_err, rxdat_query_write_resp_err;
  logic [N-1:0]  rxdat_query_strb, rxdat_cancel_strb, rxdat_write_data_strb;
  logic          rxdat_cancel_en, rxdat_write_data_en;

  logic [N-1:0]  txrsp_op_valid, txrsp_op_read_strb, txrsp_op_done_strb;
  logic [N-1:0]  txrsp_info_read_strb;
  logic          txrsp_op_read_comp, txrsp_op_read_dbidresp;
  logic          txrsp_op_read_compdbidresp, txrsp_op_read_readreceipt;
  logic          txrsp_op_done_comp, txrsp_op_done_dbidresp;
  logic          txrsp_op_done_compdbidresp, txrsp_op_done_readreceipt;
  logic [37:0] txrsp_info_read_bits;
  logic [1:0] txrsp_operand_write_resp_err;

  logic [N-1:0]  txdat_op_valid, txdat_op_read_strb, txdat_op_done_strb;
  logic [N-1:0]  txdat_info_read_strb, txdat_operand_read_strb, txdat_operand_write_strb;
  logic [N-1:0][1:0] txdat_op_valid_critical;
  logic          txdat_op_read_compdata_valid, txdat_op_read_compdata_sep;
  logic          txdat_op_done_compdata;
  logic [37:0] txdat_info_read_bits;
  logic [47:0] txdat_operand_read_addr;
  logic [1:0]  txdat_operand_read_read_resp_err;
  logic [1:0] txdat_operand_read_critical, txdat_operand_write_critical;
  logic [0:0]  txdat_operand_read_count, txdat_operand_write_count;

  logic [N-1:0]  aw_op_valid, aw_op_ponr_strb, aw_info_read_strb, aw_operand_read_strb;
  logic [3:0] aw_info_read_qos;
  logic [48:0]  aw_operand_read_addr;
  logic [1:0] aw_operand_read_burst;
  logic [2:0]  aw_operand_read_size;
  logic [7:0]   aw_operand_read_len;

  logic [N-1:0]  w_op_ponr_strb, w_operand_read_strb, w_operand_write_strb;
  logic [1:0] w_operand_read_critical, w_operand_write_critical;
  logic [0:0]  w_operand_read_count, w_operand_write_count;

  logic [N-1:0]  b_op_done_strb;

  logic [N-1:0]  ar_op_valid, ar_op_ponr_strb, ar_op_done_strb;
  logic [N-1:0]  ar_info_read_strb, ar_operand_read_strb;
  logic [3:0] ar_info_read_qos;
  logic [48:0]  ar_operand_read_addr;
  logic [1:0] ar_operand_read_burst;
  logic [2:0]  ar_operand_read_size;
  logic [7:0]   ar_operand_read_len;
  logic                   ar_operand_read_device;

  logic [N-1:0]  r_op_done_strb, r_operand_read_strb, r_operand_axi_write_strb;
  logic [1:0] r_operand_read_critical, r_operand_axi_write_critical;
  logic [0:0]  r_operand_read_count, r_operand_axi_write_count;

  logic [N-1:0]  dbg_double_allocation, dbg_dangling_axi_write_response;
"""

CORE_INST_PORTS = [
    'clock', 'reset', 'free_strb', 'alloc_en', 'alloc_strb', 'alloc_op_bits', 'alloc_info_bits',
    'alloc_chi_addr', 'alloc_chi_write_full', 'alloc_chi_write_ptl', 'alloc_chi_critical',
    'alloc_chi_count', 'alloc_axi_addr', 'alloc_axi_size', 'alloc_axi_len',
    'alloc_axi_device', 'alloc_axi_critical', 'alloc_axi_count', 'alloc_order_valid',
    'alloc_order_index', 'rxdat_query_en', 'rxdat_query_strb', 'rxdat_query_valid',
    'rxdat_query_write_full', 'rxdat_query_write_ptl', 'rxdat_query_read_resp_err',
    'rxdat_query_write_resp_err', 'rxdat_cancel_en', 'rxdat_cancel_strb',
    'rxdat_write_data_en', 'rxdat_write_data_strb', 'txrsp_op_valid',
    'txrsp_op_read_strb', 'txrsp_op_read_comp', 'txrsp_op_read_dbidresp',
    'txrsp_op_read_compdbidresp', 'txrsp_op_read_readreceipt', 'txrsp_op_done_strb',
    'txrsp_op_done_comp', 'txrsp_op_done_dbidresp', 'txrsp_op_done_compdbidresp',
    'txrsp_op_done_readreceipt', 'txrsp_info_read_strb', 'txrsp_info_read_bits',
    'txrsp_operand_write_resp_err', 'txdat_op_valid', 'txdat_op_valid_critical',
    'txdat_op_read_strb', 'txdat_op_read_compdata_valid', 'txdat_op_read_compdata_sep',
    'txdat_op_done_strb', 'txdat_op_done_compdata', 'txdat_info_read_strb',
    'txdat_info_read_bits', 'txdat_operand_read_strb', 'txdat_operand_read_addr',
    'txdat_operand_read_read_resp_err', 'txdat_operand_read_critical',
    'txdat_operand_read_count', 'txdat_operand_write_strb',
    'txdat_operand_write_critical', 'txdat_operand_write_count', 'aw_op_valid',
    'aw_op_ponr_strb', 'aw_info_read_strb', 'aw_info_read_qos', 'aw_operand_read_strb',
    'aw_operand_read_addr', 'aw_operand_read_burst', 'aw_operand_read_size',
    'aw_operand_read_len', 'w_op_ponr_strb', 'w_operand_read_strb',
    'w_operand_read_critical', 'w_operand_read_count', 'w_operand_write_strb',
    'w_operand_write_critical', 'w_operand_write_count', 'b_op_done_strb',
    'ar_op_valid', 'ar_op_ponr_strb', 'ar_op_done_strb', 'ar_info_read_strb',
    'ar_info_read_qos', 'ar_operand_read_strb', 'ar_operand_read_addr',
    'ar_operand_read_burst', 'ar_operand_read_size', 'ar_operand_read_len',
    'ar_operand_read_device', 'r_op_done_strb', 'r_operand_read_strb',
    'r_operand_read_critical', 'r_operand_read_count', 'r_operand_axi_write_strb',
    'r_operand_axi_write_critical', 'r_operand_axi_write_count',
    'dbg_double_allocation', 'dbg_dangling_axi_write_response',
]


def emit_wrapper(mod):
    d = VARIANTS[mod]
    n = d['n']
    ports = golden_ports(mod)
    names = {p[2] for p in ports}
    L = []
    A = L.append
    A(f'// {mod}.sv —— OpenNCB 事务队列（{d["role"]}）薄包装层')
    A('// ' + '-' * 75)
    A('// 核体见 xs_NCBTransactionQueue_core.sv（家族共享参数化核）。本文件只做端口')
    A('// 打包与参数设定：把 golden 逐槽展平的 %d 个标量端口收成 N 位向量接给核。' % len(ports))
    A('//')
    A('// 本变体参数（对应 XiangShan src/main/scala/top/Top.scala 的 NCBParameters）：')
    A(f'//   {d["params"]}')
    A('// 于是核参数为：')
    A(f'//   N = {n}，HAS_ORDER = {d["has_order"]}，HAS_DEVICE = {d["has_device"]}，'
      f'HAS_AR_READY_BARRIER = {d["has_ar_barrier"]}')
    A('//')
    A('// ★两个变体不是「纯尺寸单态化」★（立项时的猜测被实测推翻）。除 64 项/32 项外，')
    A('// 归一化后的 golden 端口表还差这几项（逐条量得，见 verif/ut/NCBTransactionQueue/gen.py）：')
    if d['has_order']:
        A('//   本变体**有** io_allocate_bits_order_{valid,index} 与整片 N×N 前序依赖阵列')
        A('//   （axiMasterOrder=WriteAddress）；_1 变体那两个端口与两个 order 寄存器')
        A('//   被 firtool 整片消掉（axiMasterOrder=None 让上游把 order.valid 钉成常数 0）。')
        A('//   本变体**没有** operand.axi.Device（acceptMemAttrDevice=false → 恒 0 被折掉），')
        A('//   也**没有** io_downstreamAr_opDone_strb（readReceiptAfterAcception=false →')
        A('//   ReadReceipt 的 AXIARready 屏障恒 0，连寄存器带端口一起消失）。')
    else:
        A('//   本变体**没有** io_allocate_bits_order_{valid,index}，也没有 order 寄存器')
        A('//   （axiMasterOrder=None → 上游把 order.valid 钉成常数 0，整片 32×32 依赖')
        A('//   阵列被 firtool 折没；这正是它只有 11k 行而 64 项变体有 30k 行的主因之一）。')
        A('//   本变体**多出** io_allocate_bits_operand_axi_Device 与')
        A('//   io_downstreamAr_operandRead_bits_Device（acceptMemAttrDevice=true），')
        A('//   以及 io_downstreamAr_opDone_strb_*（readReceiptAfterAcception=true 时')
        A('//   ReadReceipt 要等 AXI ARREADY，于是每槽多一位屏障寄存器）。')
    A('//')
    A(f'// 规模：golden {mod}.sv 共 %d 行、%d 个端口、每槽 34 个寄存器（%d 槽 = %d 个）。'
      % (len((GOLDEN / f'{mod}.sv').read_text().splitlines()), len(ports), n, 34 * n))
    A('//')
    A('// 自动生成：verif/ut/NCBTransactionQueue/gen.py —— 勿手改')
    A('// ' + '=' * 75)
    A(f'module {mod}')
    A('(')
    for k, (dr, w, nm) in enumerate(ports):
        comma = ',' if k + 1 < len(ports) else ''
        pad = f'{w:<7}' if w else ' ' * 7
        A(f'  {dr:<6} {pad} {nm}{comma}')
    A(');')
    A('')
    A('  // ' + '-' * 73)
    A('  // 本变体参数')
    A('  // ' + '-' * 73)
    A(f'  localparam int N          = {n};')
    A(f'  localparam bit HAS_ORDER  = 1\'b{d["has_order"]};')
    A(f'  localparam bit HAS_DEVICE = 1\'b{d["has_device"]};')
    A(f'  localparam bit HAS_AR_BAR = 1\'b{d["has_ar_barrier"]};')
    A(f'  localparam int IDX_W      = {max(1, (n - 1).bit_length())};')
    A('')
    A('  // ' + '-' * 73)
    A('  // 核侧信号声明')
    A('  // ' + '-' * 73)
    A('')
    A(CORE_SIGS.rstrip('\n'))
    A('')
    A('  // ' + '-' * 73)
    A('  // 输入：逐槽展平的 golden 端口收成 N 位向量')
    A('  // ' + '-' * 73)
    for pre, sig in IN_VEC.items():
        if f'{pre}_0' not in names:
            continue
        items = ',\n'.join(f'      {pre}_{i}' for i in range(n - 1, -1, -1))
        A(f'  assign {sig} = {{\n{items}}};')
    for pre, sig in IN_VEC.items():
        if f'{pre}_0' in names:
            continue
        A(f'  // golden 本变体没有 {pre}_* —— 该通路整片被 firtool 消掉，核侧钉 0。')
        A(f'  assign {sig} = \'0;')
    A('')
    A('  // ' + '-' * 73)
    A('  // 输入：标量端口')
    A('  // ' + '-' * 73)
    A('')
    op_fields = [
        ('chi_comp_valid', 'io_allocate_bits_op_chi_Comp_valid'),
        ('chi_comp_barrier_cancel_or_bresp',
         'io_allocate_bits_op_chi_Comp_barrier_CHICancelOrAXIBresp'),
        ('chi_dbidresp_valid', 'io_allocate_bits_op_chi_DBIDResp_valid'),
        ('chi_compdbidresp_valid', 'io_allocate_bits_op_chi_CompDBIDResp_valid'),
        ('chi_readreceipt_valid', 'io_allocate_bits_op_chi_ReadReceipt_valid'),
        ('chi_compdata_valid', 'io_allocate_bits_op_chi_CompData_valid'),
        ('chi_compdata_sep', 'io_allocate_bits_op_chi_CompData_sep'),
        ('axi_wa_valid', 'io_allocate_bits_op_axi_WriteAddress_valid'),
        ('axi_wa_barrier_wbdata',
         'io_allocate_bits_op_axi_WriteAddress_barrier_CHIWriteBackData'),
        ('axi_wd_valid', 'io_allocate_bits_op_axi_WriteData_valid'),
        ('axi_wresp_valid', 'io_allocate_bits_op_axi_WriteResponse_valid'),
        ('axi_ra_valid', 'io_allocate_bits_op_axi_ReadAddress_valid'),
        ('axi_rd_valid', 'io_allocate_bits_op_axi_ReadData_valid'),
    ]
    A('  // ncb_op_t 的字段顺序（核文件 §1，先声明的在高位）：')
    A('  assign alloc_op_bits = {')
    for k, (f, g) in enumerate(op_fields):
        A(f'      {g}{"," if k + 1 < len(op_fields) else ""}   // [{len(op_fields) - 1 - k}] {f}')
    A('  };')
    info_fields = [('qos', 'QoS'), ('tgt_id', 'TgtID'), ('src_id', 'SrcID'),
                   ('txn_id', 'TxnID'), ('return_nid', 'ReturnNID'),
                   ('return_txn_id', 'ReturnTxnID')]
    A('  // ★return_nid / return_txn_id 存进去就没有读者★ —— golden 的四个 infoRead')
    A('  //   读口只输出 38 位 {QoS,TgtID,SrcID,TxnID}。照抄结构，不删也不合并。')
    A('  assign alloc_info_bits = {')
    for k, (f, g) in enumerate(info_fields):
        A(f'      io_allocate_bits_info_{g}'
          f'{"," if k + 1 < len(info_fields) else ""}   // {f}')
    A('  };')
    simple_in = [
        ('alloc_en', 'io_allocate_en'),
        ('alloc_chi_addr', 'io_allocate_bits_operand_chi_Addr'),
        ('alloc_chi_write_full', 'io_allocate_bits_operand_chi_WriteFull'),
        ('alloc_chi_write_ptl', 'io_allocate_bits_operand_chi_WritePtl'),
        ('alloc_chi_critical', '{io_allocate_bits_operand_chi_Critical_1, '
                               'io_allocate_bits_operand_chi_Critical_0}'),
        ('alloc_chi_count', 'io_allocate_bits_operand_chi_Count'),
        ('alloc_axi_addr', 'io_allocate_bits_operand_axi_Addr'),
        ('alloc_axi_size', 'io_allocate_bits_operand_axi_Size'),
        ('alloc_axi_len', 'io_allocate_bits_operand_axi_Len'),
        ('alloc_axi_critical', '{io_allocate_bits_operand_axi_Critical_1, '
                               'io_allocate_bits_operand_axi_Critical_0}'),
        ('alloc_axi_count', 'io_allocate_bits_operand_axi_Count'),
        ('rxdat_query_en', 'io_upstreamRxDat_query_en'),
        ('rxdat_cancel_en', 'io_upstreamRxDat_cancel_en'),
        ('rxdat_write_data_en', 'io_upstreamRxDat_writeData_en'),
        ('txrsp_op_done_comp', 'io_upstreamTxRsp_opDone_bits_Comp'),
        ('txrsp_op_done_dbidresp', 'io_upstreamTxRsp_opDone_bits_DBIDResp'),
        ('txrsp_op_done_compdbidresp', 'io_upstreamTxRsp_opDone_bits_CompDBIDResp'),
        ('txrsp_op_done_readreceipt', 'io_upstreamTxRsp_opDone_bits_ReadReceipt'),
        ('txdat_op_done_compdata', 'io_upstreamTxDat_opDone_bits_CompData'),
        ('txdat_operand_write_critical',
         '{io_upstreamTxDat_operandWrite_bits_Critical_1, '
         'io_upstreamTxDat_operandWrite_bits_Critical_0}'),
        ('txdat_operand_write_count', 'io_upstreamTxDat_operandWrite_bits_Count'),
        ('w_operand_write_critical', '{io_downstreamW_operandWrite_bits_Critical_1, '
                                     'io_downstreamW_operandWrite_bits_Critical_0}'),
        ('w_operand_write_count', 'io_downstreamW_operandWrite_bits_Count'),
        ('r_operand_axi_write_critical',
         '{io_downstreamR_operandAXIWrite_bits_Critical_1, '
         'io_downstreamR_operandAXIWrite_bits_Critical_0}'),
        ('r_operand_axi_write_count', 'io_downstreamR_operandAXIWrite_bits_Count'),
    ]
    for sig, expr in simple_in:
        A(f'  assign {sig} = {expr};')
    if 'io_allocate_bits_operand_axi_Device' in names:
        A('  assign alloc_axi_device = io_allocate_bits_operand_axi_Device;')
    else:
        A('  // acceptMemAttrDevice=false：Device 恒 0，golden 连输入端口都没有。')
        A('  assign alloc_axi_device = 1\'b0;')
    if 'io_allocate_bits_order_valid' in names:
        A('  assign alloc_order_valid = io_allocate_bits_order_valid;')
        A('  assign alloc_order_index = io_allocate_bits_order_index;')
    else:
        A('  // axiMasterOrder=None：上游把 order.valid 钉成常数 0，两个端口都不存在。')
        A('  assign alloc_order_valid = 1\'b0;')
        A('  assign alloc_order_index = \'0;')
    A('')
    A('  // ' + '-' * 73)
    A('  // 参数化核例化（固定实例名 u_core）')
    A('  // ' + '-' * 73)
    A('  xs_NCBTransactionQueue_core #(')
    A('      .N                    (N),')
    A('      .HAS_ORDER            (HAS_ORDER),')
    A('      .HAS_DEVICE           (HAS_DEVICE),')
    A('      .HAS_AR_READY_BARRIER (HAS_AR_BAR)')
    A('  ) u_core (')
    for k, p in enumerate(CORE_INST_PORTS):
        comma = ',' if k + 1 < len(CORE_INST_PORTS) else ''
        A(f'      .{p:<34}({p}){comma}')
    A('  );')
    A('')
    A('  // ' + '-' * 73)
    A('  // 输出：核侧向量散回 golden 的逐槽标量端口')
    A('  // ' + '-' * 73)
    for pre, sig in OUT_VEC.items():
        if f'{pre}_0' not in names:
            continue
        for i in range(n):
            A(f'  assign {pre}_{i} = {sig}[{i}];')
    A(f'  // 每一槽的 CHI Critical 全都拉出去（{n}×2 根线），给 TXDAT 挑关键字优先的那一拍。')
    for i in range(n):
        for b in range(2):
            A(f'  assign {OUT_MAT_PREFIX}{i}_{b} = txdat_op_valid_critical[{i}][{b}];')
    A('  // 标量输出')
    for dr, w, nm in ports:
        if dr != 'output':
            continue
        if nm in SCALAR:
            A(f'  assign {nm} = {SCALAR[nm]};')
    A('')
    A(f'endmodule : {mod}')
    txt = '\n'.join(L) + '\n'
    # 自检：golden 的每个端口都必须在本文件里被接过（漏一个 = 悬空端口）
    body = txt.split(');', 1)[1]
    for dr, w, nm in ports:
        if nm in ('clock', 'reset'):
            continue
        assert nm in body, f'{mod}: 端口 {nm} 没有接线'
    return txt


# ---------------------------------------------------------------------------
# testbench
# ---------------------------------------------------------------------------
PFX = {'NCBTransactionQueue': 'q64', 'NCBTransactionQueue_1': 'q32'}


def vec_member(mod, name):
    """只有真属于 IN_VEC / OUT_VEC 这两张表的前缀才算「逐槽展平的向量成员」。
    ★这里曾经只判「结尾是不是 0..N-1」，于是 ..._Critical_0/_1 这种**节拍**下标
      被误判成槽号，tb 里连声明都没生成，VCS 报 IBLHS-NT（隐式网络不能做左值）。★"""
    n = VARIANTS[mod]['n']
    si = split_index(name, n)
    if si and (si[0] in IN_VEC or si[0] in OUT_VEC):
        return si
    return None


def tb_expr(mod, name, side):
    """golden 端口名 -> tb 侧信号表达式。side 为 '' (输入) / 'g_' / 'x_' (输出)。"""
    n = VARIANTS[mod]['n']
    p = PFX[mod]
    if name.startswith(OUT_MAT_PREFIX):
        i, b = name[len(OUT_MAT_PREFIX):].split('_')
        return f'{side}{p}_txdat_crit[{i}][{b}]'
    si = vec_member(mod, name)
    if si:
        pre, i = si
        if pre in IN_VEC:
            return f'{p}_{IN_VEC[pre]}[{i}]'
        return f'{side}{p}_{OUT_VEC[pre]}[{i}]'
    return f'{side}{p}_{name}'


def emit_tb():
    L = []
    A = L.append
    A('// ' + '=' * 75)
    A('// NCBTransactionQueue 家族 UT：两个单态化变体各一对 DUT（golden <M> 对重写')
    A('// <M>_xs），共享时钟/复位，各自独立随机激励，逐拍比对**全部**输出端口。')
    A('//')
    A('// ★激励为什么不是「每个输入独立均匀随机」★')
    A('// 本模块的判别力全在「同一个槽上多个事件撞车」：分配撞释放、分配撞 opDone、')
    A('// WriteDataCancel 撞 BRESP、R/W/allocate 三方抢同一份 axi Critical、前序依赖')
    A('// 指向的槽正好本拍释放。槽号 64/32 路、每个 strobe 各自独立均匀随机的话，')
    A('// 两路撞同一槽的概率低到 200k 拍也凑不出几次 —— 那样的 errors=0 什么都没验到。')
    A('// （上一轮 StoreQueue 的教训：604 个输入每拍独立均匀随机，3 seed × 200k 全绿，')
    A('//   实际什么都没验。）')
    A('// 所以每拍先掷一个**焦点槽号** focus（65% 落在 0..3 的小池子），再让各路 strobe')
    A('// 以 45% 的概率一热地打在 focus 上 —— 撞车因此是常态而不是巧合。')
    A('// strobe 掩码还按 12% 给全零、10% 给多热、8% 给随机掩码，专打 ParallelMux')
    A('// (OR-of-AND 一热多路) 在非一热输入下的行为：全零读出 0、多热读出按位或。')
    A('//')
    A('// ★暖机（本模块必须有）★')
    A('// golden 每槽 34 个寄存器里**只有 14/15 个在复位域**，另外 20 个（info / 两个')
    A('// 地址 / Size / Len / Device / 两组 Critical+Count / order）一个都不复位。')
    A('// +vcs+initreg 给两个 DUT 的这些寄存器**各掷各的随机值**，不暖机的话第一拍就')
    A('// 会因为初值不同而报错。所以复位撤销后先用 2 拍「alloc_en=1 + strb 全 1、其余')
    A('// strobe 全 0」把每个槽的每个不复位寄存器都写成确定值，之后才打开比较。')
    A('// ★暖机之后必须复核变异仍能被抓到★ —— 见 mutants.py，每个变异体的 errors 数')
    A('// 都记在那里。')
    A('//')
    A('// ★覆盖证据★')
    A('// tb 统计若干「有判别力的事件」计数（见 COVERAGE 段），任何一项为 0 都说明对应')
    A('// 机制根本没被激励到，这一轮 errors=0 不作数。计数用到少量对 golden 内部寄存器')
    A('// 的层次引用（tb 里允许，且只用于计数，不参与判决）。')
    A('//')
    A('// 自动生成：verif/ut/NCBTransactionQueue/gen.py —— 勿手改')
    A('// ' + '=' * 75)
    A('`timescale 1ns/1ps')
    A('')
    A('module tb;')
    A('')
    A('  int unsigned NCYCLES = 200000;')
    A('  bit   clk = 0;')
    A('  logic rst;')
    A('  logic cmp_en = 1\'b0;   // 暖机结束前不比较（见文件头）')
    A('  int errors = 0;')
    A('  longint checks = 0;')
    A('  int unsigned warm = 0;')
    A('  // 中途异步复位的次数（见 initial 块）。')
    A('  localparam int RESET_PULSES = 20;')
    A('  longint cov_reset_pulses = 0;')
    A('')
    A('  always #5 clk = ~clk;')
    A('')
    A('  // strobe 取值：45% 一热打在焦点槽、25% 一热随机、12% 全零、10% 多热、8% 随机掩码。')
    A('  function automatic logic [63:0] strb_pick(input int unsigned n,')
    A('                                            input int unsigned focus);')
    A('    logic [63:0] m;')
    A('    logic [63:0] lim;')
    A('    int unsigned r;')
    A('    r = $urandom_range(0, 99);')
    A('    lim = (n >= 64) ? 64\'hFFFF_FFFF_FFFF_FFFF : ((64\'d1 << n) - 64\'d1);')
    A('    if (r < 45)      m = 64\'d1 << focus;')
    A('    else if (r < 70) m = 64\'d1 << $urandom_range(0, n - 1);')
    A('    else if (r < 82) m = 64\'d0;')
    A('    else if (r < 92) m = (64\'d1 << focus) | (64\'d1 << $urandom_range(0, n - 1));')
    A('    else             m = {$urandom(), $urandom()};')
    A('    return m & lim;')
    A('  endfunction')
    A('')
    A('  // op 位偏稀疏：全 0 的分配会让槽在下一拍立刻释放，这正是要打的边界。')
    A('  function automatic logic op_bit();')
    A('    return ($urandom_range(0, 99) < 30);')
    A('  endfunction')
    A('')
    for mod in VARIANTS:
        L.extend(tb_variant(mod))
    A('')
    A('  // ' + '-' * 73)
    A('  // 复位 / 暖机 / 收尾')
    A('  // ' + '-' * 73)
    A('  initial begin')
    A('    if ($value$plusargs("ncycles=%d", NCYCLES)) ;')
    A('    rst = 1\'b1;')
    A('    repeat (4) @(posedge clk);')
    A('    @(negedge clk) rst = 1\'b0;')
    A('    // 暖机：复位撤销后再给两拍「全槽分配」，把 20 个不复位寄存器写成确定值。')
    A('    // warm 在 posedge 上改，激励块在 negedge 上读，避开同沿竞争。')
    A('    repeat (2) @(posedge clk);')
    A('    warm = 2;')
    A('    repeat (2) @(posedge clk);')
    A('    @(negedge clk) cmp_en = 1\'b1;')
    A('    // ★中途反复打异步复位★：这是复位域的唯一把关手段。')
    A('    // 暖机之后两轮 initreg 必然都绿（不复位的 20 个寄存器都已写成确定值），')
    A('    // 所以「复位域对不对」只能靠复位事件本身来测：复位后 valid 与 op 位必须归 0、')
    A('    // 而 info/operand/order 必须**保持不变** —— 任何一侧多复位或少复位都会当场失配。')
    A('    // 只打一次的话余量太薄：实测「去掉 op_comp_valid 的复位」这个变异在单次复位下')
    A('    // 只报 16 个 errors，换个 seed 就可能漏。这里打 RESET_PULSES 次。')
    A('    for (int k = 0; k < RESET_PULSES; k++) begin')
    A('      repeat (NCYCLES / RESET_PULSES) @(posedge clk);')
    A('      @(negedge clk) begin rst = 1\'b1; cmp_en = 1\'b0; end')
    A('      repeat (1 + (k % 3)) @(posedge clk);')
    A('      @(negedge clk) rst = 1\'b0;')
    A('      repeat (2) @(posedge clk);')
    A('      @(negedge clk) cmp_en = 1\'b1;')
    A('      cov_reset_pulses++;')
    A('    end')
    A('')
    A('    $display("--- COVERAGE (每项必须 > 0，否则该机制没被激励到) ---");')
    covs = [('cov_reset_pulses', '中途异步复位次数（复位域的唯一把关手段）')]
    for mod in VARIANTS:
        covs.extend(cov_list(mod))
    for name, desc in covs:
        A(f'    $display("  %-34s: %0d", "{desc}", {name});')
    A('    $display("checks=%0d errors=%0d", checks, errors);')
    cond = ' &&\n        '.join(f'{n} > 0' for n, _ in covs)
    A('    if (errors == 0 &&')
    A(f'        {cond})')
    A('      $display("TEST PASSED");')
    A('    else')
    A('      $display("TEST FAILED (errors=%0d 或覆盖项为 0)", errors);')
    A('    $finish;')
    A('  end')
    A('')
    A('endmodule')
    return '\n'.join(L) + '\n'


def cov_list(mod):
    p = PFX[mod]
    d = VARIANTS[mod]
    c = [(f'cov_{p}_alloc_beats_free',   f'[{p}] 分配压过释放(同槽同拍)'),
         (f'cov_{p}_double_alloc',       f'[{p}] 占用中的槽又被分配'),
         (f'cov_{p}_clear_beats_alloc',  f'[{p}] 清除压过分配(同槽同拍)'),
         (f'cov_{p}_cancel_and_bresp',   f'[{p}] Cancel 与 BRESP 同槽同拍'),
         (f'cov_{p}_axi_r_w_clash',      f'[{p}] R/W 抢同一份 axi Critical'),
         (f'cov_{p}_axi_w_alloc_clash',  f'[{p}] W/allocate 抢 axi Critical'),
         (f'cov_{p}_chi_w_alloc_clash',  f'[{p}] TXDAT/allocate 抢 chi Critical'),
         (f'cov_{p}_compdata_cnt0',      f'[{p}] CompData done 且 Count=0(真清除)'),
         (f'cov_{p}_compdata_cnt1',      f'[{p}] CompData done 但 Count!=0(不清除)'),
         (f'cov_{p}_queue_full',         f'[{p}] 队列全满'),
         (f'cov_{p}_queue_empty',        f'[{p}] 队列全空'),
         (f'cov_{p}_read_multihot',      f'[{p}] 读口多热(OR 多路)'),
         (f'cov_{p}_read_zero',          f'[{p}] 读口全零'),
         (f'cov_{p}_dangling_bresp',     f'[{p}] 悬空 BRESP 断言条件'),
         (f'cov_{p}_ponr_and_alloc',     f'[{p}] PoNR 与分配同槽同拍')]
    if d['has_order']:
        c += [(f'cov_{p}_order_alloc_kill', f'[{p}] 新依赖一出生就被释放作废'),
              (f'cov_{p}_order_free_clear', f'[{p}] 已存依赖被释放解除'),
              (f'cov_{p}_order_blocks',     f'[{p}] 依赖挡住了冒泡')]
    if d['has_ar_barrier']:
        c += [(f'cov_{p}_ar_barrier_clear', f'[{p}] ARREADY 解除 ReadReceipt 屏障'),
              (f'cov_{p}_ar_barrier_set',   f'[{p}] ReadReceipt 屏障挂起中')]
    if d['has_device']:
        c += [(f'cov_{p}_device_read', f'[{p}] AR 读口读出 Device=1')]
    return c


def tb_variant(mod):
    d = VARIANTS[mod]
    n = d['n']
    p = PFX[mod]
    ports = golden_ports(mod)
    names = {x[2] for x in ports}
    L = []
    A = L.append
    A('  // ' + '=' * 73)
    A(f'  // {mod} —— {d["role"]}；{n} 槽，'
      f'HAS_ORDER={d["has_order"]} HAS_DEVICE={d["has_device"]} '
      f'HAS_AR_READY_BARRIER={d["has_ar_barrier"]}')
    A('  // ' + '=' * 73)
    A(f'  localparam int {p.upper()}_N = {n};')
    # --- 声明 ---
    for pre, sig in IN_VEC.items():
        if f'{pre}_0' in names:
            A(f'  logic [{n - 1}:0] {p}_{sig};')
    for pre, sig in OUT_VEC.items():
        if f'{pre}_0' in names:
            A(f'  logic [{n - 1}:0] g_{p}_{sig}, x_{p}_{sig};')
    A(f'  logic [{n - 1}:0][1:0] g_{p}_txdat_crit, x_{p}_txdat_crit;')
    for dr, w, nm in ports:
        if nm in ('clock', 'reset'):
            continue
        if vec_member(mod, nm) or nm.startswith(OUT_MAT_PREFIX):
            continue
        decl = f'[{width_of(w) - 1}:0] ' if width_of(w) > 1 else ''
        if dr == 'input':
            A(f'  logic {decl}{p}_{nm};')
        else:
            A(f'  logic {decl}g_{p}_{nm}, x_{p}_{nm};')
    A('')
    # --- 例化 ---
    for inst, side in ((f'{mod}', 'g_'), (f'{mod}_xs', 'x_')):
        A(f'  {inst} u_{side}{p} (')
        A('      .clock (clk),')
        A('      .reset (rst),')
        body = []
        for dr, w, nm in ports:
            if nm in ('clock', 'reset'):
                continue
            body.append(f'      .{nm} ({tb_expr(mod, nm, side if dr == "output" else "")})')
        A(',\n'.join(body))
        A('  );')
        A('')
    # --- golden 内部探针（只用于覆盖计数）---
    A('  // golden 内部探针（只用于覆盖计数，不参与判决）')
    A(f'  logic [{n - 1}:0] g_{p}_entry_valid;')
    A(f'  logic [{n - 1}:0] g_{p}_chi_count;')
    for i in range(n):
        A(f'  assign g_{p}_entry_valid[{i}] = u_g_{p}.regQueue_{i}_valid;')
    for i in range(n):
        A(f'  assign g_{p}_chi_count[{i}] = u_g_{p}.regQueue_{i}_bits_operand_chi_Count;')
    if d['has_order']:
        idxw = max(1, (n - 1).bit_length())
        A(f'  logic [{n - 1}:0] g_{p}_order_valid;')
        A(f'  logic [{n - 1}:0][{idxw - 1}:0] g_{p}_order_index;')
        for i in range(n):
            A(f'  assign g_{p}_order_valid[{i}] = u_g_{p}.regQueue_{i}_bits_order_valid;')
        for i in range(n):
            A(f'  assign g_{p}_order_index[{i}] = u_g_{p}.regQueue_{i}_bits_order_index;')
    if d['has_ar_barrier']:
        A(f'  logic [{n - 1}:0] g_{p}_rr_barrier;')
        for i in range(n):
            A(f'  assign g_{p}_rr_barrier[{i}] = '
              f'u_g_{p}.regQueue_{i}_bits_op_chi_ReadReceipt_barrier_AXIARready;')
    A('')
    # --- 激励 ---
    A(f'  int unsigned {p}_focus;')
    A(f'  int unsigned {p}_drain = 0;   // 排空突发剩余拍数')
    A(f'  logic [{n - 1}:0] {p}_alloc_hit;')
    A(f'  assign {p}_alloc_hit = {{{n}{{{p}_io_allocate_en}}}} & {p}_alloc_strb;')
    A('')
    A('  always @(negedge clk) begin')
    A(f'    {p}_focus = ($urandom_range(0, 99) < 65) ? $urandom_range(0, 3)')
    A(f'                                             : $urandom_range(0, {n} - 1);')
    A('    if (warm < 2) begin')
    A('      // 暖机：一拍把每个槽都分配一遍，把 20 个不复位寄存器写成确定值；')
    A('      // 其余 strobe / en 全 0，免得 op 位的次态去读还是 X 的 Count。')
    A(f'      {p}_io_allocate_en  <= 1\'b1;')
    A(f'      {p}_alloc_strb      <= {{{n}{{1\'b1}}}};')
    for pre, sig in IN_VEC.items():
        if f'{pre}_0' in names and sig != 'alloc_strb':
            A(f'      {p}_{sig} <= \'0;')
    for nm in ('io_upstreamRxDat_query_en', 'io_upstreamRxDat_cancel_en',
               'io_upstreamRxDat_writeData_en'):
        A(f'      {p}_{nm} <= 1\'b0;')
    A(f'    end else if ({p}_drain == 3) begin')
    A('      // 排空第 1 拍：把所有槽的 chi Count 写成 0 —— CompData 的清除只在')
    A('      // Count==0 时发生，不先压平就永远排不空。')
    A(f'      {p}_io_allocate_en <= 1\'b0;')
    A(f'      {p}_alloc_strb <= \'0;')
    A(f'      {p}_txdat_operand_write_strb <= {{{n}{{1\'b1}}}};')
    for pre, sig in IN_VEC.items():
        if f'{pre}_0' in names and sig not in ('alloc_strb', 'txdat_operand_write_strb'):
            A(f'      {p}_{sig} <= \'0;')
    for nm in ('io_upstreamRxDat_query_en', 'io_upstreamRxDat_cancel_en',
               'io_upstreamRxDat_writeData_en'):
        A(f'      {p}_{nm} <= 1\'b0;')
    A(f'      {p}_drain <= {p}_drain - 1;')
    A(f'    end else if ({p}_drain != 0) begin')
    A('      // 排空第 2/3 拍：所有清除 strobe 全 1、所有 done 位全 1、Cancel 也拉起，')
    A('      // 两拍后 op 位全清、free_strb 全 1，再一拍 valid 全清 —— 队列见底。')
    A('      // 这也是**多热 strobe** 的重灾区，正好顺带打 ParallelMux 的非一热行为。')
    A(f'      {p}_io_allocate_en <= 1\'b0;')
    A(f'      {p}_alloc_strb <= \'0;')
    for pre, sig in IN_VEC.items():
        if f'{pre}_0' in names and sig != 'alloc_strb':
            A(f'      {p}_{sig} <= {{{n}{{1\'b1}}}};')
    for nm in ('io_upstreamRxDat_query_en', 'io_upstreamRxDat_cancel_en',
               'io_upstreamRxDat_writeData_en'):
        A(f'      {p}_{nm} <= 1\'b1;')
    A(f'      {p}_drain <= {p}_drain - 1;')
    A('    end else begin')
    A(f'      {p}_io_allocate_en <= ($urandom_range(0, 99) < 55);')
    for pre, sig in IN_VEC.items():
        if f'{pre}_0' in names:
            A(f'      {p}_{sig} <= strb_pick({n}, {p}_focus);')
    for nm in ('io_upstreamRxDat_query_en', 'io_upstreamRxDat_cancel_en',
               'io_upstreamRxDat_writeData_en'):
        A(f'      {p}_{nm} <= ($urandom_range(0, 99) < 50);')
    A('      // 每 ~125 拍来一次三拍排空突发：没有它，被暖机填满的 64 个槽里')
    A('      // 焦点池之外的那些永远等不到 done，队列全空/见底这类边界一次也打不到。')
    A(f'      if ($urandom_range(0, 999) < 8) {p}_drain <= 3;')
    A('    end')
    A('    // 载荷与 op 位每拍都换（暖机/排空拍也换，两个 DUT 共用同一份输入）')
    for nm, expr in tb_payload_drive(mod, names, n):
        A(f'    {p}_{nm} <= {expr};')
    A(f'    if ({p}_drain != 0) begin')
    A('      // 排空期间把两组 Count 与所有 done 位钉死，免得随机值把排空打断')
    A(f'      {p}_io_upstreamTxDat_operandWrite_bits_Count <= 1\'b0;')
    A(f'      {p}_io_upstreamTxRsp_opDone_bits_Comp <= 1\'b1;')
    A(f'      {p}_io_upstreamTxRsp_opDone_bits_DBIDResp <= 1\'b1;')
    A(f'      {p}_io_upstreamTxRsp_opDone_bits_CompDBIDResp <= 1\'b1;')
    A(f'      {p}_io_upstreamTxRsp_opDone_bits_ReadReceipt <= 1\'b1;')
    A(f'      {p}_io_upstreamTxDat_opDone_bits_CompData <= 1\'b1;')
    A('    end')
    A('  end')
    A('')
    # --- 比较 ---
    A('  always @(negedge clk) if (cmp_en && !rst) begin')
    cmps = []
    for pre, sig in OUT_VEC.items():
        if f'{pre}_0' in names:
            cmps.append((f'g_{p}_{sig}', f'x_{p}_{sig}', sig))
    cmps.append((f'g_{p}_txdat_crit', f'x_{p}_txdat_crit', 'txdat_opValid_Critical'))
    for dr, w, nm in ports:
        if dr == 'output' and not vec_member(mod, nm) \
                and not nm.startswith(OUT_MAT_PREFIX):
            cmps.append((f'g_{p}_{nm}', f'x_{p}_{nm}', nm))
    for g, x, what in cmps:
        A('    checks++;')
        A(f'    if ({g} !== {x}) begin errors++;')
        A(f'      if (errors < 20) $display("MISMATCH %0t {p}.{what} g=%0h x=%0h",')
        A(f'                                $time, {g}, {x}); end')
    A('  end')
    A('')
    # --- 覆盖 ---
    L.extend(tb_coverage(mod, names, n))
    return L


def tb_payload_drive(mod, names, n):
    """每拍随机重掷的载荷/op 输入（不含 strobe 与 en）。"""
    d = VARIANTS[mod]
    out = [
        ('io_allocate_bits_op_chi_Comp_valid', 'op_bit()'),
        ('io_allocate_bits_op_chi_Comp_barrier_CHICancelOrAXIBresp', 'op_bit()'),
        ('io_allocate_bits_op_chi_DBIDResp_valid', 'op_bit()'),
        ('io_allocate_bits_op_chi_CompDBIDResp_valid', 'op_bit()'),
        ('io_allocate_bits_op_chi_ReadReceipt_valid', 'op_bit()'),
        ('io_allocate_bits_op_chi_CompData_valid', 'op_bit()'),
        ('io_allocate_bits_op_chi_CompData_sep', 'op_bit()'),
        ('io_allocate_bits_op_axi_WriteAddress_valid', 'op_bit()'),
        ('io_allocate_bits_op_axi_WriteAddress_barrier_CHIWriteBackData', 'op_bit()'),
        ('io_allocate_bits_op_axi_WriteData_valid', 'op_bit()'),
        ('io_allocate_bits_op_axi_WriteResponse_valid', 'op_bit()'),
        ('io_allocate_bits_op_axi_ReadAddress_valid', 'op_bit()'),
        ('io_allocate_bits_op_axi_ReadData_valid', 'op_bit()'),
        ('io_allocate_bits_info_QoS', "4'($urandom())"),
        ('io_allocate_bits_info_TgtID', "11'($urandom())"),
        ('io_allocate_bits_info_SrcID', "11'($urandom())"),
        ('io_allocate_bits_info_TxnID', "12'($urandom())"),
        ('io_allocate_bits_info_ReturnNID', "11'($urandom())"),
        ('io_allocate_bits_info_ReturnTxnID', "12'($urandom())"),
        ('io_allocate_bits_operand_chi_Addr', "48'($urandom())"),
        ('io_allocate_bits_operand_chi_WriteFull', 'op_bit()'),
        ('io_allocate_bits_operand_chi_WritePtl', 'op_bit()'),
        ('io_allocate_bits_operand_chi_Critical_0', "1'($urandom())"),
        ('io_allocate_bits_operand_chi_Critical_1', "1'($urandom())"),
        # Count 一半给 0：CompData 的清除只在 Count==0 时发生，这是判别点
        ('io_allocate_bits_operand_chi_Count', "($urandom_range(0,1) == 0) ? 1'b0 : 1'b1"),
        ('io_allocate_bits_operand_axi_Addr', "49'($urandom())"),
        ('io_allocate_bits_operand_axi_Size', "3'($urandom())"),
        ('io_allocate_bits_operand_axi_Len', "8'($urandom())"),
        ('io_allocate_bits_operand_axi_Critical_0', "1'($urandom())"),
        ('io_allocate_bits_operand_axi_Critical_1', "1'($urandom())"),
        ('io_allocate_bits_operand_axi_Count', "1'($urandom())"),
        ('io_upstreamTxRsp_opDone_bits_Comp', "($urandom_range(0,99) < 60)"),
        ('io_upstreamTxRsp_opDone_bits_DBIDResp', "($urandom_range(0,99) < 60)"),
        ('io_upstreamTxRsp_opDone_bits_CompDBIDResp', "($urandom_range(0,99) < 60)"),
        ('io_upstreamTxRsp_opDone_bits_ReadReceipt', "($urandom_range(0,99) < 60)"),
        ('io_upstreamTxDat_opDone_bits_CompData', "($urandom_range(0,99) < 60)"),
        ('io_upstreamTxDat_operandWrite_bits_Critical_0', "1'($urandom())"),
        ('io_upstreamTxDat_operandWrite_bits_Critical_1', "1'($urandom())"),
        ('io_upstreamTxDat_operandWrite_bits_Count',
         "($urandom_range(0,1) == 0) ? 1'b0 : 1'b1"),
        ('io_downstreamW_operandWrite_bits_Critical_0', "1'($urandom())"),
        ('io_downstreamW_operandWrite_bits_Critical_1', "1'($urandom())"),
        ('io_downstreamW_operandWrite_bits_Count', "1'($urandom())"),
        ('io_downstreamR_operandAXIWrite_bits_Critical_0', "1'($urandom())"),
        ('io_downstreamR_operandAXIWrite_bits_Critical_1', "1'($urandom())"),
        ('io_downstreamR_operandAXIWrite_bits_Count', "1'($urandom())"),
    ]
    if d['has_device']:
        out.append(('io_allocate_bits_operand_axi_Device', "1'($urandom())"))
    if d['has_order']:
        # 前序 index 也偏向焦点小池：只有指向**同一批槽**才可能撞上释放
        p = PFX[mod]
        idxw = max(1, (n - 1).bit_length())
        out.append(('io_allocate_bits_order_valid', "($urandom_range(0,99) < 45)"))
        out.append(('io_allocate_bits_order_index',
                    f"($urandom_range(0,99) < 65) ? {idxw}'($urandom_range(0,3))"
                    f" : {idxw}'($urandom_range(0, {n} - 1))"))
    return [(nm, e) for nm, e in out if nm in names]


def tb_coverage(mod, names, n):
    d = VARIANTS[mod]
    p = PFX[mod]
    L = []
    A = L.append
    for name, _ in cov_list(mod):
        A(f'  longint {name} = 0;')
    # ★覆盖计数必须在 posedge 上取样★：negedge 上读到的 g_* 探针已经是**更新后**的
    # 状态，而 strobe 还是这一拍的输入 —— 于是「ar_done 打在还挂着的屏障上」这种
    # 「事件 + 事件发生前的状态」的计数永远是 0（实测第一版就是这样，19999 拍一次没中）。
    # posedge 的 always 块读到的是 NBA 更新前的旧值，正好是 DUT 本拍看到的那一组。
    A('  always @(posedge clk) if (cmp_en && !rst) begin')
    A(f'    if (|({p}_alloc_hit & g_{p}_free_strb)) cov_{p}_alloc_beats_free++;')
    A(f'    if (|g_{p}_dbg_double_allocation) cov_{p}_double_alloc++;')
    clears = [f'({p}_txrsp_op_done_strb & {{{n}{{{p}_io_upstreamTxRsp_opDone_bits_Comp'
              f' | {p}_io_upstreamTxRsp_opDone_bits_DBIDResp'
              f' | {p}_io_upstreamTxRsp_opDone_bits_CompDBIDResp'
              f' | {p}_io_upstreamTxRsp_opDone_bits_ReadReceipt}}}})',
              f'{p}_aw_op_ponr_strb', f'{p}_w_op_ponr_strb', f'{p}_ar_op_ponr_strb',
              f'{p}_b_op_done_strb', f'{p}_r_op_done_strb',
              f'({{{n}{{{p}_io_upstreamRxDat_cancel_en}}}} & {p}_rxdat_cancel_strb)']
    A(f'    if (|({p}_alloc_hit & (' + '\n                          | '.join(clears)
      + '))) cov_%s_clear_beats_alloc++;' % p)
    A(f'    if (|(({{{n}{{{p}_io_upstreamRxDat_cancel_en}}}} & {p}_rxdat_cancel_strb)')
    A(f'          & {p}_b_op_done_strb)) cov_{p}_cancel_and_bresp++;')
    A(f'    if (|({p}_r_operand_axi_write_strb & {p}_w_operand_write_strb))')
    A(f'      cov_{p}_axi_r_w_clash++;')
    A(f'    if (|({p}_w_operand_write_strb & {p}_alloc_hit)) cov_{p}_axi_w_alloc_clash++;')
    A(f'    if (|({p}_txdat_operand_write_strb & {p}_alloc_hit))')
    A(f'      cov_{p}_chi_w_alloc_clash++;')
    A(f'    if ({p}_io_upstreamTxDat_opDone_bits_CompData) begin')
    A(f'      if (|({p}_txdat_op_done_strb & ~g_{p}_chi_count)) cov_{p}_compdata_cnt0++;')
    A(f'      if (|({p}_txdat_op_done_strb &  g_{p}_chi_count)) cov_{p}_compdata_cnt1++;')
    A('    end')
    A(f'    if (&g_{p}_entry_valid) cov_{p}_queue_full++;')
    A(f'    if (~|g_{p}_entry_valid) cov_{p}_queue_empty++;')
    A(f'    if ($countones({p}_txdat_operand_read_strb) > 1) cov_{p}_read_multihot++;')
    A(f'    if ({p}_txdat_operand_read_strb == \'0) cov_{p}_read_zero++;')
    A(f'    if (|g_{p}_dbg_dangling_axi_write_response) cov_{p}_dangling_bresp++;')
    A(f'    if (|(({p}_aw_op_ponr_strb | {p}_w_op_ponr_strb | {p}_ar_op_ponr_strb)')
    A(f'          & {p}_alloc_hit)) cov_{p}_ponr_and_alloc++;')
    if d['has_order']:
        idxw = max(1, (n - 1).bit_length())
        A(f'    if ({p}_io_allocate_en && {p}_io_allocate_bits_order_valid) begin')
        A('      for (int j = 0; j < %d; j++)' % n)
        A(f'        if (g_{p}_free_strb[j]'
          f' && {p}_io_allocate_bits_order_index == {idxw}\'(j)')
        A(f'            && |({p}_alloc_strb & ~({n}\'d1 << j)))')
        A(f'          cov_{p}_order_alloc_kill++;')
        A('    end')
        A('    for (int i = 0; i < %d; i++)' % n)
        A('      for (int j = 0; j < %d; j++)' % n)
        A(f'        if (i != j && g_{p}_order_valid[i] && g_{p}_free_strb[j]')
        A(f'            && g_{p}_order_index[i] == {idxw}\'(j))')
        A(f'          cov_{p}_order_free_clear++;')
        A(f'    if (|g_{p}_order_valid) cov_{p}_order_blocks++;')
    if d['has_ar_barrier']:
        A(f'    if (|({p}_ar_op_done_strb & g_{p}_rr_barrier)) cov_{p}_ar_barrier_clear++;')
        A(f'    if (|g_{p}_rr_barrier) cov_{p}_ar_barrier_set++;')
    if d['has_device']:
        A(f'    if (g_{p}_io_downstreamAr_operandRead_bits_Device) cov_{p}_device_read++;')
    A('  end')
    A('')
    return L


def main():
    outs = []
    for mod in VARIANTS:
        outs.append((OUT / f'{mod}.sv', emit_wrapper(mod)))
    outs.append((HERE / 'tb.sv', emit_tb()))
    for path, txt in outs:
        if path.exists() and path.read_text() == txt:
            print(f'  unchanged {path}')
        else:
            path.write_text(txt)
            print(f'  wrote     {path}  ({len(txt.splitlines())} lines)')
    for mod in VARIANTS:
        p = OUT / f'{mod}.sv'
        before = p.read_text()
        gen_file_nav.apply(p)
        if p.read_text() != before:
            print(f'  nav       {p}')


if __name__ == '__main__':
    main()
