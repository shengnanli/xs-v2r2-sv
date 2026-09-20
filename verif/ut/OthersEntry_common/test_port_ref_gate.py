#!/usr/bin/env python3
"""check_port_refs 的负测：闸必须真的拦得住，而不是恰好没触发。

判据：把一个 golden 里不存在的端口名塞进 wrapper 文本，闸必须抛 AssertionError。
不抛 = 闸是摆设，退出码非零。
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from othersentry_gen import OthersVariant, gen_rtl, gen_rtl_body, check_port_refs

ov = OthersVariant('OthersEntry_88')       # FP simp：正是当初栽跟头的那个
L, ctx = gen_rtl(ov)
rtl = gen_rtl_body(ov, L, ctx)

# 正例：真产物必须过
check_port_refs(ov, rtl)

# 反例 1：FP 族没有的 IQ loadDependency（当初真实的 bug 形态）
bad1 = rtl.replace(".iq_ld_dep('0)",
                   '.iq_ld_dep(io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0)')
assert bad1 != rtl, '反例 1 没改到东西，测试本身失效'
# 反例 2：随手打错一个字母
bad2 = rtl.replace('io_commonIn_enq_valid', 'io_commonIn_enq_vaild')
assert bad2 != rtl, '反例 2 没改到东西，测试本身失效'

fails = 0
for name, txt in (('IQ loadDependency（真实 bug 形态）', bad1),
                  ('端口名打错一个字母', bad2)):
    try:
        check_port_refs(ov, txt)
        print(f'FAIL: 闸没拦住「{name}」')
        fails += 1
    except AssertionError as e:
        print(f'OK  : 闸拦住了「{name}」 -> {str(e)[:90]}…')
print('负测通过' if not fails else '负测失败')
sys.exit(1 if fails else 0)
