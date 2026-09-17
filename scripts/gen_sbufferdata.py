#!/usr/bin/env python3
"""gen_sbufferdata.py —— 生成 rtl/memblock/SbufferData.sv 里的机械派生区。

SbufferData 的 golden 端口表有 2064 个端口，其中 1024 个 io_dataOut_<行>_<vword>_<字节>
与 1024 个 io_maskOut_<同> 是同一个存储阵列的扁平展开，必须与 golden **逐位同名同序**
（否则 port_contract_lint 不过、FM 也对不上），手写没有意义也容易出错。

本脚本只改 rtl/memblock/SbufferData.sv 里两段 `// BEGIN GENERATED(<tag>)` /
`// END GENERATED` 之间的内容，手写区一个字都不碰；幂等（内容不变就不写文件）。

  bulk_ports   —— wrapper 端口表里 1024 dataOut + 1024 maskOut 两段
  bulk_assigns —— wrapper 把可读核的多维数组连回这 2048 个扁平端口

UT 侧的 verif/ut/SbufferData/sbd_bridge.sv 同样是 4096 条连线（golden 与重写件
各 2048 个输出端口），也由本脚本生成：`--bridge` 重写该文件。

用法: python3 scripts/gen_sbufferdata.py [--check] [--bridge]
      --check 只校验文件已是最新（用于闸），不写入。
"""
import argparse
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
TARGET = REPO / 'rtl' / 'memblock' / 'SbufferData.sv'
BRIDGE = REPO / 'verif' / 'ut' / 'SbufferData' / 'sbd_bridge.sv'

NLINE, NVWORD, NBYTE = 16, 4, 16   # StoreBufferSize / CacheLineVWords / VDataBytes


def gen_ports():
    out = []
    for l in range(NLINE):
        for w in range(NVWORD):
            for b in range(NBYTE):
                out.append(f'  output [7:0]   io_dataOut_{l}_{w}_{b},')
    for l in range(NLINE):
        for w in range(NVWORD):
            for b in range(NBYTE):
                last = (l, w, b) == (NLINE - 1, NVWORD - 1, NBYTE - 1)
                out.append(f'  output         io_maskOut_{l}_{w}_{b}' + ('' if last else ','))
    return out


def gen_assigns():
    out = []
    for l in range(NLINE):
        for w in range(NVWORD):
            for b in range(NBYTE):
                out.append(f'  assign io_dataOut_{l}_{w}_{b} = core_data[{l}][{w}][{b}];')
    for l in range(NLINE):
        for w in range(NVWORD):
            for b in range(NBYTE):
                out.append(f'  assign io_maskOut_{l}_{w}_{b} = core_mask[{l}][{w}][{b}];')
    return out



def gen_bridge():
    """UT 桥接件：把两个 DUT 的 2048 个扁平输出各自聚成一根向量，tb 只比两根向量。
    下标约定 idx = line*64 + vword*16 + byte（与 golden 端口名的三段索引一致）。"""
    h = []
    h.append('// =============================================================================')
    h.append('// sbd_bridge —— SbufferData UT 的机械桥接件（由 scripts/gen_sbufferdata.py 生成，')
    h.append('//   勿手改）。golden SbufferData 与重写件 SbufferData_xs 各有 1024 个 io_dataOut_*')
    h.append('//   与 1024 个 io_maskOut_*；本模块把同一份激励送进两侧，再把两侧的 2048 个扁平')
    h.append('//   输出各自打包成 g_data/g_mask 与 i_data/i_mask 四根向量，tb 逐拍只需比两次。')
    h.append('//   下标 idx = line*64 + vword*16 + byte。')
    h.append('// =============================================================================')
    h.append('`timescale 1ns/1ps')
    h.append('module sbd_bridge(')
    h.append('  input  logic        clk,')
    h.append('  input  logic        rst,')
    h.append('  input  logic [1:0]        wvalid,')
    h.append('  input  logic [1:0][15:0]  wvec,')
    h.append('  input  logic [1:0][15:0]  wmask,')
    h.append('  input  logic [1:0][127:0] wdata,')
    h.append('  input  logic [1:0][43:0]  wvwoff,')
    h.append('  input  logic [1:0]        wline,')
    h.append('  input  logic              fvalid,')
    h.append('  input  logic [15:0]       fvec,')
    h.append('  output logic [1023:0][7:0] g_data,')
    h.append('  output logic [1023:0]      g_mask,')
    h.append('  output logic [1023:0][7:0] i_data,')
    h.append('  output logic [1023:0]      i_mask')
    h.append(');')
    for mod, inst, pre in (('SbufferData', 'u_g', 'g'), ('SbufferData_xs', 'u_i', 'i')):
        h.append(f'  {mod} {inst} (')
        h.append('    .clock (clk),')
        h.append('    .reset (rst),')
        for p in range(2):
            h.append(f'    .io_writeReq_{p}_valid            (wvalid[{p}]),')
            h.append(f'    .io_writeReq_{p}_bits_wvec        (wvec[{p}]),')
            h.append(f'    .io_writeReq_{p}_bits_mask        (wmask[{p}]),')
            h.append(f'    .io_writeReq_{p}_bits_data        (wdata[{p}]),')
            h.append(f'    .io_writeReq_{p}_bits_vwordOffset (wvwoff[{p}]),')
            h.append(f'    .io_writeReq_{p}_bits_wline       (wline[{p}]),')
        h.append('    .io_maskFlushReq_0_valid      (fvalid),')
        h.append('    .io_maskFlushReq_0_bits_wvec  (fvec),')
        conns = []
        for l in range(NLINE):
            for w in range(NVWORD):
                for b in range(NBYTE):
                    conns.append(f'    .io_dataOut_{l}_{w}_{b} ({pre}_data[{l*64 + w*16 + b}])')
        for l in range(NLINE):
            for w in range(NVWORD):
                for b in range(NBYTE):
                    conns.append(f'    .io_maskOut_{l}_{w}_{b} ({pre}_mask[{l*64 + w*16 + b}])')
        h.extend(c + ',' for c in conns[:-1])
        h.append(conns[-1])
        h.append('  );')
    h.append('endmodule')
    return h


def splice(text, tag, lines):
    pat = re.compile(r'(  // BEGIN GENERATED\(' + tag + r'\)\n).*?(  // END GENERATED\n)',
                     re.S)
    if not pat.search(text):
        sys.exit(f'gen_sbufferdata: 找不到标记 BEGIN GENERATED({tag})')
    body = ''.join(l + '\n' for l in lines)
    return pat.sub(lambda m: m.group(1) + body + m.group(2), text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--bridge', action='store_true',
                    help='同时重写 UT 桥接件 verif/ut/SbufferData/sbd_bridge.sv')
    args = ap.parse_args()

    # 桥接件与 RTL 派生区一样要防腐：--check 同时校验它。
    # （本仓的反复教训是"生成物进了版本库却没有闸看着它"，改一次源就静默腐烂。）
    if args.bridge or (args.check and BRIDGE.exists()):
        btext = ''.join(l + chr(10) for l in gen_bridge())
        stale = (not BRIDGE.exists()) or BRIDGE.read_text() != btext
        if args.check:
            if stale:
                print(f'gen_sbufferdata: {BRIDGE.relative_to(REPO)} 已过期，'
                      f'请重跑 python3 scripts/gen_sbufferdata.py --bridge')
                return 1
            print('gen_sbufferdata: 桥接件逐字节一致')
        elif stale:
            BRIDGE.parent.mkdir(parents=True, exist_ok=True)
            BRIDGE.write_text(btext)
            print(f'gen_sbufferdata: 已更新 {BRIDGE.relative_to(REPO)}')
        else:
            print('gen_sbufferdata: 桥接件已是最新')

    text = TARGET.read_text()
    new = splice(text, 'bulk_ports', gen_ports())
    new = splice(new, 'bulk_assigns', gen_assigns())
    if new == text:
        print('gen_sbufferdata: 已是最新')
        return 0
    if args.check:
        print('gen_sbufferdata: 派生区已过期，请重跑 python3 scripts/gen_sbufferdata.py')
        return 1
    TARGET.write_text(new)
    print(f'gen_sbufferdata: 已更新 {TARGET.relative_to(REPO)}'
          f'（{2 * NLINE * NVWORD * NBYTE} 个扁平端口 + 同数量连线）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
