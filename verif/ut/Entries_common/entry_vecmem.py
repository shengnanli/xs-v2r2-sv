#!/usr/bin/env python3
"""单条目（EnqEntryVecMem* / OthersEntryVecMem*）的访存向量状态组 —— 两族生成器共用的接线表。

## 这一组是什么

访存向量 IQ（isVecMemIQ：VlduVstu / VlduVstuVseglduVsegstu 两个变体）的条目比普通条目
多存四样状态（核 xs_iq_entries_core.sv §2.6c，HAS_VEC_MEM=1）：

  status.vecMem       = {numLsElem, lqIdx{flag,value}, sqIdx{flag,value}}  入队装载、之后原样保持
  isVecPartReplay     发射响应落在 issueTimer==3 那一拍时记下响应带回的值
  vecReplayMask/MbIdx 响应的 isVecPartReplay 位置起那一拍记下响应带回的值
  blocked             真次态：vleff 的 uop 在自己的 lqIdx 还不是 LSQ 的 lqDeqPtr 时不许发射

核在阵列层（EntriesVlduVstu*，已签核）里已经用过这组参数；条目单独成模块时，
golden 把这四样连同 LSQ 的 lqDeqPtr、响应里的三样都摆成了端口，本文件只负责把这些
端口按核的打包顺序接上去 —— **不写新逻辑**。

## 打包顺序（★与 Entries_common/gen_fm_pins.py 的 vm_layout 是同一张表★）

  r_vm = {numLsElem, lqIdx_flag, lqIdx_value, sqIdx_flag, sqIdx_value}   （高位在前）

entries_gen.py 给阵列接 `.enq_vm` 用的就是这个顺序；改这里必须同改那两处。

## 宽度从哪来

逐个从**本模块自己的**端口表量，再与父级 Entries 变体（entries_gen.Variant）量的那份
逐项对照；不一致当场失败，不悄悄挑一个。
"""

VM_FIELDS = ('numLsElem', 'lqIdx_flag', 'lqIdx_value', 'sqIdx_flag', 'sqIdx_value')


def widths(ov):
    """本模块端口表量出的 (VM_SQ_W, VM_LQ_W, VM_NLSE_W, VR_MASK_W, VR_MBIDX_W)，并与父级对照。"""
    v = ov.v

    def w_of(n):
        assert ov.has(n), f'{ov.mod}: 访存向量条目缺端口 {n}'
        return ov.pmap[n][1]

    got = (1 + w_of('io_commonIn_enq_bits_status_vecMem_sqIdx_value'),
           1 + w_of('io_commonIn_enq_bits_status_vecMem_lqIdx_value'),
           w_of('io_commonIn_enq_bits_status_vecMem_numLsElem'),
           w_of('io_commonIn_issueResp_bits_vecReplayMask'),
           w_of('io_commonIn_issueResp_bits_vecReplayMbIdx'))
    want = (v.vm_sq_w, v.vm_lq_w, v.vm_nlse_w, v.vr_mask_w, v.vr_mbidx_w)
    assert got == want, (f'{ov.mod}: 访存向量宽度 {got} 与父级 {v.top} 量的 {want} 不同')
    assert w_of('io_commonIn_fromLsq_lqDeqPtr_value') + 1 == v.vm_lq_w, \
        f'{ov.mod}: lqDeqPtr 宽度与 lqIdx 不同'
    return got


def vm_cat(pfx):
    """status.vecMem 的五个字段按核 r_vm 的布局拼起来（高位在前）。"""
    return '{' + ', '.join(pfx + f for f in VM_FIELDS) + '}'


def params(ov):
    """xs_iq_entry 的访存向量参数行（不带结尾逗号）。"""
    sq, lq, ne, mk, mb = widths(ov)
    return (f'    .HAS_VEC_MEM(1), .VM_SQ_W({sq}), .VM_LQ_W({lq}), .VM_NLSE_W({ne}),\n'
            f'    .VR_MASK_W({mk}), .VR_MBIDX_W({mb}), .PLB_IS_VLEFF({ov.v.plb_is_vleff})')


def conns(ov, is_enq, has_trans):
    """xs_iq_entry 的访存向量连接（列表，每项一条，不带逗号）。

    is_enq    : enq 条目装载时把 isVecPartReplay/vecReplayMask/MbIdx 清 0（核 §2.6c），
                golden EnqEntryVecMem* 也因此没有那三个 enq.status 输入。
    has_trans : 有没有 transEntry 出口（enq / simp 有，comp 没有）。
    """
    c = []
    ein = 'io_commonIn_enq_bits_status_'
    c.append('  // ---- 访存向量状态组（核 §2.6c）：vecMem 打包 = {numLsElem, lqIdx, sqIdx} ----')
    c.append(f'.enq_vm({vm_cat(ein + "vecMem_")})')
    if is_enq:
        for f in ('isVecPartReplay', 'vecReplayMask', 'vecReplayMbIdx'):
            assert not ov.has(ein + f), f'{ov.mod}: enq 条目竟有 enq.status.{f} 输入'
        c.append('  // enq 条目装载时这三样由核清 0，golden 也没有对应输入')
        c.append(".enq_vpr('0), .enq_vr_mask('0), .enq_vr_mbidx('0)")
    else:
        c.append(f'.enq_vpr({ein}isVecPartReplay)')
        c.append(f'.enq_vr_mask({ein}vecReplayMask)')
        c.append(f'.enq_vr_mbidx({ein}vecReplayMbIdx)')
    c.append('.lq_deq_ptr({io_commonIn_fromLsq_lqDeqPtr_flag, io_commonIn_fromLsq_lqDeqPtr_value})')
    c.append('.resp_vpr(io_commonIn_issueResp_bits_isVecPartReplay)')
    c.append('.resp_vr_mask(io_commonIn_issueResp_bits_vecReplayMask)')
    c.append('.resp_vr_mbidx(io_commonIn_issueResp_bits_vecReplayMbIdx)')
    eo = 'io_commonOut_entry_bits_status_'
    c.append(f'.o_ety_vm({vm_cat(eo + "vecMem_")})')
    c.append(f'.o_ety_vpr({eo}isVecPartReplay)')
    c.append(f'.o_ety_vr_mask({eo}vecReplayMask)')
    c.append(f'.o_ety_vr_mbidx({eo}vecReplayMbIdx)')
    if has_trans:
        to = 'io_commonOut_transEntry_bits_status_'
        c.append(f'.o_trans_vm({vm_cat(to + "vecMem_")})')
        c.append(f'.o_trans_vpr({to}isVecPartReplay)')
        c.append(f'.o_trans_vr_mask({to}vecReplayMask)')
        c.append(f'.o_trans_vr_mbidx({to}vecReplayMbIdx)')
    else:
        c.append('  // comp 不产出 transEntry：这组出口接悬空线')
        c.append('.o_trans_vm(unused_trans_vm), .o_trans_vpr(unused_trans_vpr)')
        c.append('.o_trans_vr_mask(unused_trans_vr_mask), .o_trans_vr_mbidx(unused_trans_vr_mbidx)')
    return c


def unused_decls(ov):
    """comp 条目悬空出口的线声明。"""
    sq, lq, ne, mk, mb = widths(ov)
    return [f'  logic [{sq + lq + ne - 1}:0] unused_trans_vm;',
            '  logic unused_trans_vpr;',
            f'  logic [{mk - 1}:0] unused_trans_vr_mask;',
            f'  logic [{mb - 1}:0] unused_trans_vr_mbidx;']


def tb_drive(ov, is_enq):
    """tb 的每拍激励（负沿非阻塞）。lqIdx 与 lqDeqPtr 共用小池，blocked 的两个方向才都打得到。"""
    sq, lq, ne, mk, mb = widths(ov)
    L = ['    // 访存向量状态组：lqIdx 与 lqDeqPtr 共用 4 值小池（否则 lqIdx != lqDeqPtr 恒成立，',
         '    //   blocked 只测到一个方向）；isVleff 加权 40%，blocked 才有真次态可测']
    ein = 'io_commonIn_enq_bits_status_'
    if ov.has(ein + 'blocked'):
        L.append(f'    {ein}blocked <= ($urandom_range(0, 99) < 10);')
    L.append(f'    {ein}vecMem_sqIdx_flag  <= ($urandom_range(0, 99) < 20);')
    L.append(f"    {ein}vecMem_sqIdx_value <= {sq - 1}'($urandom_range(0, 3));")
    L.append(f'    {ein}vecMem_lqIdx_flag  <= ($urandom_range(0, 99) < 20);')
    L.append(f"    {ein}vecMem_lqIdx_value <= {lq - 1}'($urandom_range(0, 3));")
    L.append(f"    {ein}vecMem_numLsElem   <= {ne}'($urandom);")
    if not is_enq:
        L.append(f'    {ein}isVecPartReplay <= ($urandom_range(0, 99) < 25);')
        L.append(f"    {ein}vecReplayMask   <= {mk}'($urandom);")
        L.append(f"    {ein}vecReplayMbIdx  <= {mb}'($urandom);")
    L.append('    io_commonIn_fromLsq_lqDeqPtr_flag  <= ($urandom_range(0, 99) < 20);')
    L.append(f"    io_commonIn_fromLsq_lqDeqPtr_value <= {lq - 1}'($urandom_range(0, 3));")
    L.append('    io_commonIn_issueResp_bits_isVecPartReplay <= ($urandom_range(0, 99) < 25);')
    L.append(f"    io_commonIn_issueResp_bits_vecReplayMask   <= {mk}'($urandom);")
    L.append(f"    io_commonIn_issueResp_bits_vecReplayMbIdx  <= {mb}'($urandom);")
    return L


def payload_bias(n):
    """负载里 blocked 判据要读的 isVleff 单独加权（返回 None = 不加权）。"""
    return 40 if n == 'vpu_isVleff' else None


# 覆盖桶（只对访存向量条目追加）：探 golden 的寄存器与出口，阈值见各生成器的 COV_MIN_200K。
COV_NAMES = ['vec_blocked', 'vec_unblocked_vleff', 'vec_part_replay', 'vec_replay_mask_upd']


def tb_cov(g):
    """覆盖采样语句。g(n) -> golden 出口名；golden 实例名固定为 u_g。"""
    return [
        '    // 访存向量：blocked 真的挡过 / vleff 的 uop 真的等到了 lqDeqPtr（两个方向）',
        "    if (u_g.validReg_last_REG === 1'b1 && u_g.entryReg_status_blocked === 1'b1)"
        ' cov_vec_blocked++;',
        "    if (u_g.validReg_last_REG === 1'b1 && u_g.entryReg_status_blocked === 1'b0 &&"
        f" {g('entry_bits_payload_vpu_isVleff')} === 1'b1) cov_vec_unblocked_vleff++;",
        '    // isVecPartReplay 状态位真的被置过、replay mask 真的被响应改写过',
        f"    if ({g('valid')} === 1'b1 && {g('entry_bits_status_isVecPartReplay')} === 1'b1)"
        ' cov_vec_part_replay++;',
        f"    if ({g('valid')} === 1'b1 && io_commonIn_issueResp_bits_isVecPartReplay === 1'b1)"
        ' cov_vec_replay_mask_upd++;',
    ]


def pins(ov, regs, ref_bits):
    """golden 逐字段寄存器 <-> 核 r_vm 向量 + 三个寄存器（布局同 Entries_common/gen_fm_pins.vm_layout）。"""
    sq, lq, ne, mk, mb = widths(ov)
    pre = 'entryReg_status_vecMem_'
    layout = {pre + 'sqIdx_value': (0, sq - 1),
              pre + 'sqIdx_flag':  (sq - 1, 1),
              pre + 'lqIdx_value': (sq, lq - 1),
              pre + 'lqIdx_flag':  (sq + lq - 1, 1),
              pre + 'numLsElem':   (sq + lq, ne)}
    out = []
    for gname, (lsb, w) in layout.items():
        assert gname in regs, f'{ov.mod} 缺访存向量寄存器 {gname}'
        assert regs[gname] == w, f'{ov.mod}.{gname} 位宽 {regs[gname]} != {w}'
        for leaf, b in ref_bits(gname, w):
            out.append((leaf, f'r_vm_reg[{lsb + b}]'))
    for gname, iname in (('entryReg_status_isVecPartReplay', 'r_vpr_reg'),
                         ('entryReg_status_vecReplayMask', 'r_vr_mask_reg'),
                         ('entryReg_status_vecReplayMbIdx', 'r_vr_mbidx_reg')):
        assert gname in regs, f'{ov.mod} 缺访存向量寄存器 {gname}'
        w = regs[gname]
        if w == 1:
            out.append((gname + '_reg', iname))
        else:
            for leaf, b in ref_bits(gname, w):
                out.append((leaf, f'{iname}[{b}]'))
    return out
