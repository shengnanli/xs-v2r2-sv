#!/usr/bin/env python3
"""test_ext_registry_negative.py —— 合成 `_ext` 负例：证明 registry gate 真的会拒。

**为什么要有这个文件**（codex 0154）：
vendor_boundary.tsv 逐条绑定签名之后，我们报告过一句诚实的话——"在当前 golden 上，
按后缀扫和逐条批结果相同"（26 个 `*_ext` 恰好全部经过审定），所以本轮**实际拦截数
为 0**，价值是前瞻性的。codex 的裁定是：前瞻价值也必须被机器实证，不能只停在设计
意图。办法就是造一个**名字形似存储宏、内含功能逻辑**的假 `_ext`，看闸是否真的拒。

做这件事时实测到一个真缺陷并已修：`--reconcile-ledger` 当时**只打印 NOT_APPROVED
而不置 ok=False**，注入假宏后 rc 仍是 0 —— 以退出码为准的流水线会放它过去。同函数
内 ext_dup / unparsed / 守恒三处都 fail-closed，唯独这条漏了。

夹具用**符号链接农场**：把 G1 golden 的 2056 个文件 symlink 到临时目录，再往里加注入
文件或用真文件覆盖某个链接。golden 只读，全程不写。

每条负例都配一条**对照**。原因是本轮亲身踩过：第一次跑端到端时参数写错，负例和对照
**都返回 rc=2**，若无对照就会把"脚本用法错"当成"闸抓住了"。
"""
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
GOLDEN = pathlib.Path(os.environ.get('GOLDEN_RTL',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))
CLOSURE = HERE / 'check_closure_symmetry.py'
DECLARE = HERE / 'declare_allow.py'

PASS, FAIL = [], []

# 名字形似厂商 SRAM 宏，内容是四态 FSM + 仲裁 —— 绝不可被当作存储黑盒放行。
FAKE_EXT = '''\
module array_23_ext(
  input RW0_clk, input [7:0] RW0_addr, input RW0_en, input RW0_wmode,
  input [65:0] RW0_wdata, output reg [65:0] RW0_rdata
);
  localparam IDLE=2'd0, LOOKUP=2'd1, EVICT=2'd2, FILL=2'd3;
  reg [1:0] state;
  reg [65:0] ram [255:0];
  reg [7:0]  victim;
  always @(posedge RW0_clk) begin
    case (state)
      IDLE:   if (RW0_en) state <= LOOKUP;
      LOOKUP: state <= RW0_wmode ? EVICT : IDLE;
      EVICT:  begin victim <= victim + 8'd1; state <= FILL; end
      FILL:   begin ram[victim] <= RW0_wdata ^ {66{1'b1}}; state <= IDLE; end
    endcase
    RW0_rdata <= ram[RW0_addr];
  end
endmodule
'''
SNEAKY_FSM = """
  reg [1:0] sneaky_state;
  always @(posedge RW0_clk)
    case (sneaky_state)
      2'd0: sneaky_state <= RW0_en ? 2'd1 : 2'd0;
      default: sneaky_state <= 2'd0;
    endcase
"""


def run(*args):
    p = subprocess.run([sys.executable] + [str(a) for a in args],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                       universal_newlines=True, cwd=str(REPO))
    return p.returncode, p.stdout


def check(name, rc, out, want_rc, want_kw):
    why = []
    if rc != want_rc:
        why.append(f'退出码 期望{want_rc} 实得{rc}')
    if want_kw and want_kw not in out:
        why.append(f'输出缺关键字 {want_kw!r}')
    if 'Traceback' in out:
        why.append('输出含 Traceback（脚本自身异常，不是检查结论）')
    if why:
        FAIL.append(f'{name}: ' + '; '.join(why) + f'\n    ---- 输出 ----\n{out[:900]}')
        print(f'  FAIL  {name}: {"; ".join(why)}')
    else:
        PASS.append(name)
        print(f'  ok    {name}  (rc={rc})')


class Farm:
    """golden 的 symlink 农场；可注入新文件或用真文件覆盖某个链接。golden 只读。"""

    def __enter__(self):
        self.d = pathlib.Path(tempfile.mkdtemp(prefix='extfarm.'))
        n = 0
        for f in list(GOLDEN.glob('*.v')) + list(GOLDEN.glob('*.sv')):
            (self.d / f.name).symlink_to(f)
            n += 1
        assert n > 1000, f'农场只建了 {n} 个链接，golden 路径可疑：{GOLDEN}'
        self.n = n
        return self

    def add(self, name, text):
        (self.d / name).write_text(text)

    def override(self, name, text):
        """用真文件替换一条链接（模拟 golden 侧被改）。"""
        (self.d / name).unlink()
        (self.d / name).write_text(text)

    def __exit__(self, *a):
        shutil.rmtree(self.d, ignore_errors=True)


def n_ext(d):
    """农场里 `*_ext` 模块定义数 —— 用来证明注入确实被解析到（检测器非空转）。"""
    import re
    names = set()
    for p in list(d.glob('*.v')) + list(d.glob('*.sv')):
        names |= set(re.findall(r'^module\s+([A-Za-z_]\w*_ext)\b',
                                p.read_text(errors='replace'), re.M))
    return names


print('=== A. 对照：symlink 农场本身必须与真 golden 等价（否则下面的 FAIL 都不算数）===')
with Farm() as farm:
    base = n_ext(farm.d)
    rc, out = run(CLOSURE, '--reconcile-ledger', '--golden-rtl', farm.d)
    check('A1 纯农场 -> 通过', rc, out, 0, '按后缀会扫进来但**不在表内** = 0 个')
    if len(base) != 26:
        FAIL.append(f'A2: 农场 `*_ext` 数 = {len(base)}，期望 26（golden 变了就要重审本测试）')
        print(f'  FAIL  A2: `*_ext` = {len(base)} != 26')
    else:
        PASS.append('A2')
        print(f'  ok    A2  农场 `*_ext` = 26')

print('=== B. 新增表外 `_ext`（带 FSM）必须被对账闸拒 ===')
with Farm() as farm:
    farm.add('array_23_ext.v', FAKE_EXT)
    got = n_ext(farm.d)
    # 元测试：先证明注入确实被解析成了一个 `_ext` 定义，否则"闸拒了"可能是别的原因
    if 'array_23_ext' not in got or len(got) != 27:
        FAIL.append(f'B0: 注入未被解析为 `_ext`（{len(got)} 个），后面的判定无意义')
        print('  FAIL  B0: 注入未被解析')
    else:
        PASS.append('B0')
        print('  ok    B0  注入被解析：26 -> 27')
    rc, out = run(CLOSURE, '--reconcile-ledger', '--golden-rtl', farm.d)
    check('B1 表外 `_ext` -> 拒（fail-closed，不是只打印）', rc, out, 1,
          'NOT_APPROVED  array_23_ext')

print('=== C. 已批准 `_ext` 被改（加功能逻辑 / 改端口）必须被签名闸拒 ===')
with Farm() as farm:
    rc, out = run(CLOSURE, '--check-registry', '--golden-rtl', farm.d)
    check('C0 对照：未改动 -> 通过', rc, out, 0, '')
src0 = (GOLDEN / 'array_0_ext.v').read_text()
with Farm() as farm:
    farm.override('array_0_ext.v', src0.replace('endmodule', SNEAKY_FSM + 'endmodule', 1))
    rc, out = run(CLOSURE, '--check-registry', '--golden-rtl', farm.d)
    check('C1 已批准宏被塞进 FSM -> 拒（body hash 不符）', rc, out, 1,
          'array_0_ext: registry_mismatch:leaf_sha256')
with Farm() as farm:
    farm.override('array_0_ext.v',
                  src0.replace('input RW0_wmode,', 'input RW0_wmode, input RW0_sneaky,'))
    rc, out = run(CLOSURE, '--check-registry', '--golden-rtl', farm.d)
    check('C2 已批准宏端口变化 -> 拒（端口签名不符）', rc, out, 1,
          'array_0_ext: registry_mismatch:port_count')

print('=== D. 端到端：假 `_ext` 进 allow 生成必须被拒（真放行点）===')
SAMPLE = REPO / 'evidence' / '2c433ec3ef07' / 'FoldedSRAMTemplate' / 'black_boxes.rpt'
if not SAMPLE.is_file():
    FAIL.append(f'D: 样本黑盒报告不存在 {SAMPLE}（测试无法执行，不当作通过）')
    print(f'  FAIL  D: 缺样本 {SAMPLE}')
else:
    rpt = SAMPLE.read_text()
    with tempfile.TemporaryDirectory() as td:
        td = pathlib.Path(td)
        # 用一次性 top 名，避免写坏仓库里已提交的 verif/allow/<top>.json
        TOP = 'ZZZ_EXT_NEGTEST'
        produced = REPO / 'verif' / 'allow' / f'{TOP}.json'
        assert not produced.exists(), f'{produced} 已存在，测试拒绝覆盖'
        ctrl = td / 'ctrl.rpt'
        ctrl.write_text(rpt.replace('FoldedSRAMTemplate', TOP))
        rc, out = run(DECLARE, '--report', ctrl, TOP)
        check('D0 对照：表内 array_2_ext -> 接受', rc, out, 0, '声明')
        fake = td / 'fake.rpt'
        fake.write_text(rpt.replace('FoldedSRAMTemplate', TOP)
                           .replace('array_2_ext', 'array_23_ext'))
        rc, out = run(DECLARE, '--report', fake, TOP)
        check('D1 表外 array_23_ext -> 拒并要求逐条分类', rc, out, 1,
              'ERROR: array_23_ext 不在已审定的厂商边界名单')
        if produced.exists():
            produced.unlink()
        # 残留断言：D0 会写文件，必须清干净；D1 不得写出任何东西
        if produced.exists():
            FAIL.append('D2: 测试产物未清理')
            print('  FAIL  D2: 残留 ' + str(produced))
        else:
            PASS.append('D2')
            print('  ok    D2  无残留')

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
if FAIL:
    print('\n'.join('FAILED: ' + x for x in FAIL))
    sys.exit(1)
print('ALL EXT-REGISTRY NEGATIVE TESTS PASSED')
