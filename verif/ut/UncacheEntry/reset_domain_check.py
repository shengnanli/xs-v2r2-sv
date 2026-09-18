#!/usr/bin/env python3
"""reset_domain_check.py —— 复位域结构闸（UncacheEntry 家族）。

为什么需要它（CONVENTIONS「UT 与 FM 的分工」）：本模块 golden 一条 entry 约 1500 位
寄存器里**只有 12 位在复位域**，其余（190 个 payload 字段 / slaveId / uncacheData /
flushPipe / replayInst）一个都不复位。UT 暖机之后这些寄存器都已被写成确定值，
"多加一个复位 / 少一个复位"在模块边界上**按构造可能观测不到**；而 Formality 把
寄存器当自由变量，当场 failing。所以复位域要有一道**结构**闸，不能只靠仿真。

判据（两侧都从文件里读，不从记忆写死）：
  A. golden 的异步复位块（always @(posedge clock or posedge reset)）里被复位的
     寄存器集合，与重写核同一块里被复位的集合，在 NAME_MAP 下**逐个一一对应**；
  B. 重写核里**只有一个** `posedge reset` 敏感的 always 块（多一个就说明有寄存器
     被偷偷加了复位）；
  C. golden 的无复位块（always @(posedge clock)）里出现的寄存器，在重写核里也必须
     出现在无复位块里 —— 只核对控制寄存器与两个衰减位，190 个 payload 字段按整段
     计（它们同在一个 if (enq) 里）。

用法: python3 reset_domain_check.py            # 退出码 0 = 复位域与 golden 一致
      XSSV_UNCENTRY_CORE=<path> python3 ...    # 指定被检查的核（变异测试用）
退出码非零 = 复位域与 golden 不一致。
"""
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path(os.environ.get(
    'XSSV_GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl'))
CORE = pathlib.Path(os.environ.get(
    'XSSV_UNCENTRY_CORE', str(REPO / 'rtl' / 'memblock' / 'xs_UncacheEntry_core.sv')))

# golden 名 -> 重写核名。payload 的 req_* 两侧同名，不在表里。
NAME_MAP = {
    'req_valid': 'req_valid',
    'slaveAccept': 'slave_accept',
    'uncacheState': 'state',
    'denied': 'denied',
    'corrupt': 'corrupt',
    'needFlushReg': 'need_flush_q',
    'pendingld_last_REG': 'pending_mmio_ld_q',
    'pendingPtr_next_r_flag': 'pending_ptr_flag_q',
    'pendingPtr_next_r_value': 'pending_ptr_value_q',
    'slaveId': 'slave_id',
    'uncacheData': 'resp_data',
}

ASYNC_HDR = re.compile(r'always(?:_ff)?\s*@\s*\(\s*posedge\s+clock\s+or\s+posedge\s+reset\s*\)')
SYNC_HDR = re.compile(r'always(?:_ff)?\s*@\s*\(\s*posedge\s+clock\s*\)')


def blocks(text, hdr_re):
    """返回每个匹配 always 块的块体文本（按 begin/end 配平截取）。"""
    out = []
    for m in hdr_re.finditer(text):
        i = text.index('begin', m.end())
        depth, j = 0, i
        tok = re.compile(r'\b(begin|end)\b')
        for t in tok.finditer(text, i):
            if t.group(1) == 'begin':
                depth += 1
            else:
                depth -= 1
                if depth == 0:
                    j = t.end()
                    break
        out.append(text[i:j])
    return out


def reset_assigned(block):
    """块里 if (reset) ... 那一支内被赋值的寄存器名集合。"""
    m = re.search(r'if\s*\(\s*reset\s*\)\s*begin(.*?)\n(\s*)end\b', block, re.S)
    if not m:
        m = re.search(r'if\s*\(\s*reset\s*\)\s*([A-Za-z_]\w*)\s*<=', block)
        return {m.group(1)} if m else set()
    return set(re.findall(r'^\s*([A-Za-z_]\w*)\s*<=', m.group(1), re.M))


def golden_reg_census(gtext, async_block):
    """现场清点 golden 的寄存器规模与复位域规模（不许从注释/记忆抄数）。

    返回 (寄存器个数, 总位数, 复位域寄存器个数, 复位域位数)。
    Makefile 与 tb 头注释里引用的三个数就是它打印的那一行。
    """
    body = gtext[gtext.index('module UncacheEntry('):]
    regs = re.findall(r'^  reg\s+(\[[^\]]*\]\s*)?(\w+);', body, re.M)

    def width(decl):
        if not decl:
            return 1
        hi, lo = decl.strip()[1:-1].split(':')
        return int(hi) - int(lo) + 1

    wmap = {n: width(d) for d, n in regs}
    rst = reset_assigned(async_block)
    return len(regs), sum(wmap.values()), len(rst), sum(wmap[n] for n in rst)


def main():
    gtext = (GOLDEN / 'UncacheEntry.sv').read_text()
    ctext = CORE.read_text()

    errs = []

    gblk = blocks(gtext, ASYNC_HDR)
    cblk = blocks(ctext, ASYNC_HDR)
    if len(gblk) != 1:
        errs.append(f'golden 异步复位块数 {len(gblk)}，期望 1')
    # 判据 B
    if len(cblk) != 1:
        errs.append(f'重写核异步复位块数 {len(cblk)}，期望 1'
                    f'（多一个就说明有寄存器被偷偷加了复位）')

    if gblk and cblk:
        g = reset_assigned(gblk[0])
        c = reset_assigned(cblk[0])
        want = {NAME_MAP.get(x, x) for x in g}
        # 判据 A
        if c != want:
            errs.append(f'复位域不一致：\n  golden(映射后) = {sorted(want)}\n'
                        f'  重写核         = {sorted(c)}\n'
                        f'  多复位 = {sorted(c - want)}  少复位 = {sorted(want - c)}')

    # 判据 C：golden 无复位块里的控制寄存器，重写核也必须在无复位块里
    gsync = blocks(gtext, SYNC_HDR)
    csync = blocks(ctext, SYNC_HDR)
    gsync = [b for b in gsync if 'req_uop_flushPipe' in b]
    csync = [b for b in csync if 'req_uop_flushPipe' in b]
    if not gsync or not csync:
        errs.append('找不到 golden 或重写核的无复位 always 块')
    else:
        for gname in ('slaveId', 'uncacheData', 'req_uop_flushPipe', 'req_uop_replayInst'):
            cname = NAME_MAP.get(gname, gname)
            if gname not in gsync[0]:
                errs.append(f'golden 无复位块里找不到 {gname}（golden 变了？）')
            if cname not in csync[0]:
                errs.append(f'重写核无复位块里找不到 {cname}'
                            f'（它被挪进复位域了？golden 里它不复位）')
        # 同时确认重写核的无复位块里没有 reset
        if 'reset' in csync[0]:
            errs.append('重写核的无复位块里出现了 reset —— golden 这一块不复位')

    if errs:
        print('RESET-DOMAIN CHECK FAILED:', file=sys.stderr)
        for e in errs:
            print('  ' + e, file=sys.stderr)
        return 1
    tot_n, tot_b, rst_n, rst_b = golden_reg_census(gtext, gblk[0])
    print(f'reset-domain: OK —— 复位域 {len(reset_assigned(cblk[0]))} 项与 golden 一一对应，'
          f'slaveId / uncacheData / flushPipe / replayInst 两侧同为无复位')
    print(f'  golden 现场清点：寄存器 {tot_n} 个 / {tot_b} 位；'
          f'复位域 {rst_n} 个 / {rst_b} 位；不复位 {tot_b - rst_b} 位')
    return 0


if __name__ == '__main__':
    sys.exit(main())
