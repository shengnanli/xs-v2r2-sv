#!/usr/bin/env python3
"""test_reset_domain_gate.py —— reset_domain_check.py 的**双向**负测。

CONVENTIONS「闸的负测必须是双向的」：一个恒报警的闸能通过「该报警时报了警」这一半。
所以这里两个方向都造：

  该报警的三个样本（必须报）：
    N1 给 slaveId 在无复位块里加一个复位（golden 不复位）
    N2 从复位分支里删掉 corrupt 的复位（golden 有）
    N3 另开一个 posedge reset 的 always 块（判据 B：复位块只许有一个）
  不该报警的三个对照（必须不报）：
    P0 原核原样
    P1 改一根与复位域无关的组合逻辑（uncache.req.mask 的选择位）
    P2 改一个 payload 字段的锁存源（仍在同一个无复位块里）

用法: python3 test_reset_domain_gate.py     退出码 0 = 六个样本行为都正确
"""
import pathlib
import re
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
CORE = HERE.parent.parent.parent / 'rtl' / 'memblock' / 'xs_UncacheEntry_core.sv'
GATE = HERE / 'reset_domain_check.py'

MUT = [
    # (名字, 期望是否报警, old, new)
    ('P0 原核原样', False, None, None),
    ('P1 改 mask 选择位（与复位域无关）', False,
     "req_paddr[3] ? req_mask[15:8]", "req_paddr[2] ? req_mask[15:8]"),
    ('P2 改 payload 锁存源（仍在无复位块里）', False,
     "      req_vaddr <= io_req_bits_vaddr;", "      req_vaddr <= io_req_bits_fullva[49:0];"),
    ('N1 给 slaveId 在无复位块里加复位', True,
     "    if (~(flush | io_req_valid) & slave_ack)",
     "    if (reset) slave_id <= 4'h0;\n    else if (~(flush | io_req_valid) & slave_ack)"),
    ('N2 删掉 corrupt 的复位', True,
     "      corrupt             <= 1'b0;\n", ""),
    ('N3 另开一个 posedge reset 的 always 块', True,
     "endmodule",
     "  always_ff @(posedge clock or posedge reset) begin\n"
     "    if (reset) resp_data <= 64'h0;\n  end\n\nendmodule"),
]


def run_gate(text):
    with tempfile.TemporaryDirectory(prefix='uncentry-gatetest-') as d:
        p = pathlib.Path(d) / 'core.sv'
        p.write_text(text)
        # python3.6 的 subprocess.run 还没有 capture_output，用 PIPE 显式接。
        r = subprocess.run([sys.executable, str(GATE)],
                           env={**__import__('os').environ,
                                'XSSV_UNCENTRY_CORE': str(p)},
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out = (r.stdout + r.stderr).decode()
        return r.returncode != 0, out.strip()


def main():
    base = CORE.read_text()
    bad = 0
    for name, want_fire, old, new in MUT:
        text = base
        if old is not None:
            if base.count(old) != 1:
                print(f'[{name}] 锚点不唯一或不存在（{base.count(old)} 处）—— 先修锚点',
                      file=sys.stderr)
                bad += 1
                continue
            text = base.replace(old, new)
            assert text != base, f'{name}: 样本与原核逐字相同，等于没造样本'
        fired, msg = run_gate(text)
        ok = (fired == want_fire)
        verdict = 'OK' if ok else '★错★'
        print(f'[{verdict}] {name}: 期望{"报警" if want_fire else "不报警"}，'
              f'实际{"报警" if fired else "不报警"}')
        if not ok:
            print('    闸的输出: ' + msg.replace('\n', '\n    '), file=sys.stderr)
            bad += 1
    print('-' * 50)
    print(f'双向负测 {len(MUT)} 个样本：{len(MUT) - bad} 正确，{bad} 错')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
