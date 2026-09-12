#!/usr/bin/env python3
"""gen_g1_manifest.py —— G1-canonical 全文件 SHA-256 manifest + canonical ID。

codex 0139 §3.1：禁止只靠 PROVENANCE.md 文字，须机器可复算。
产出 /home/eda/xs-env/G1-canonical/MANIFEST.tsv（每行 sha256<TAB>size<TAB>相对路径）
与 CANONICAL_ID.txt（对 manifest 正文再取 sha256，作为 G1 canonical ID）。
同时抓取工具链与源码状态写入 TOOLCHAIN.tsv：firtool/Chisel 版本从 RTL 头部与
build 日志取，JDK/mill 从工具链目录取，XiangShan commit + submodule gitlink 从 git 取。

复算方式（任何人可独立验证）：
  cd /home/eda/xs-env/G1-canonical/golden-rtl && find . -type f | sort |
  xargs sha256sum   # 与 MANIFEST.tsv 逐行一致
  sha256sum MANIFEST.tsv  # 与 CANONICAL_ID.txt 一致
"""
import hashlib
import pathlib
import re
import subprocess
import sys

G1 = pathlib.Path('/home/eda/xs-env/G1-canonical')
RTL = G1 / 'golden-rtl'
XS = pathlib.Path('/home/eda/xs-env/XiangShan')


def sh(cmd, cwd=None):
    p = subprocess.run(cmd, shell=True, cwd=str(cwd) if cwd else None,
                       stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                       universal_newlines=True)
    return p.stdout.strip()


def main():
    rows = []
    for p in sorted(RTL.rglob('*')):
        if not p.is_file():
            continue
        b = p.read_bytes()
        rows.append((hashlib.sha256(b).hexdigest(), str(len(b)),
                     str(p.relative_to(RTL))))
    body = ''.join('\t'.join(r) + '\n' for r in rows)
    (G1 / 'MANIFEST.tsv').write_text(body)
    cid = hashlib.sha256(body.encode()).hexdigest()
    (G1 / 'CANONICAL_ID.txt').write_text(f'G1-{cid}\n')

    # 工具链与源码状态
    sample = next(RTL.glob('SRAMTemplate.sv'), None) or rows and (RTL / rows[0][2])
    firtool = ''
    if sample:
        m = re.search(r'firtool-([\d.]+)', sample.read_text()[:400])
        firtool = m.group(1) if m else ''
    tc = [
        ('canonical_id', f'G1-{cid}'),
        ('files', str(len(rows))),
        ('source_repo', 'https://github.com/OpenXiangShan/XiangShan.git'),
        ('source_branch', sh('git rev-parse --abbrev-ref HEAD', XS)),
        ('source_commit', sh('git rev-parse HEAD', XS)),
        ('source_commit_date', sh('git log -1 --format=%cI', XS)),
        ('gen_command',
         'make sim-verilog CONFIG=KunminghuV2Config  (NUM_CORES=1 ISSUE=E.b, '
         'SimTop + --enable-difftest, firtool -O=release --split-verilog)'),
        ('firtool', firtool),
        ('jdk', sh('/home/eda/xs-env/toolchain/jdk-17.0.13+11/bin/java -version 2>&1 | head -1')),
        ('mill', 'mill 0.12.3 (/home/eda/xs-env/toolchain/mill; cache /home/eda/.cache/mill/download/0.12.3)'),
        ('chisel_deps', sh('grep -oE "ivy\\\\\\"[^\\\\\\"]+\\\\\\"" build.sc | head -5 | tr "\\n" " "', XS)),
    ]
    subs = sh('git submodule status', XS)
    lines = ['# G1-canonical 工具链与源码状态（gen_g1_manifest.py 自动抓取）']
    lines += [f'{k}\t{v}' for k, v in tc]
    lines += [f'submodule\t{l.strip()}' for l in subs.splitlines() if l.strip()]
    (G1 / 'TOOLCHAIN.tsv').write_text('\n'.join(lines) + '\n')

    print(f'MANIFEST.tsv: {len(rows)} 文件')
    print(f'CANONICAL_ID: G1-{cid}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
