#!/usr/bin/env python3
"""FM sidecar validator 负向测试(2026-07-19 六审 v6, 累计)。
observed-facts 模型: native 只装 FM 真返回的事实(matched pairs / 两侧独立集合);
id/waiver-pair 属 expectation policy。新增: 双射违规/跨类别 id 冲突/计数覆盖/禁抽象 top/FIFO。"""
import sys, os, json, hashlib, tempfile, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fm_sidecar_verdict import verdict, strict_load, Bad

BID = "G0-89fe69e83a4f2ea81065ecf9d5d9ab46b0b5a29911fd4f6aa2fefd54dcc13456"
H = lambda c: c * 64
TOP = "Bku"
R0, R1 = f"r:/WORK/{TOP}/inner_a", f"r:/WORK/{TOP}/inner_b"
I0, I1 = f"i:/WORK/{TOP}/u_core/a", f"i:/WORK/{TOP}/u_core/b"

def M(i, r, m):  # expectation 映射
    return {"id": i, "ref_path": r, "impl_path": m}

def P(r, m):     # observed matched pair(无 id)
    return {"ref_path": r, "impl_path": m}

def AV0():  # 九审+十审+十一审: 必须键 = unread 六元组 + 结构三键; 值 = 冻结执行语义
    return {"verification_verify_unread_compare_points": "false",
            "verification_verify_matched_unread_compare_points": "false",
            "verification_verify_unread_bbox_inputs": "false",
            "verification_verify_matched_unread_bbox_inputs": "true",
            "verification_verify_unread_tech_cell_pins": "true",
            "verification_verify_unread_tech_cell_pg_pins": "true",
            "hdlin_unresolved_modules": "black_box",
            "hdlin_interface_only": "",
            "verification_merge_duplicated_registers": "true"}

def expect(**over):
    e = {"run_id": "RID-1", "target": TOP, "top": TOP, "variant": TOP,
         "proof_mode": "signoff-strict", "canonical_baseline_id": BID,
         "ref_digest": H("a"), "impl_digest": H("b"), "script_digest": H("c"),
         "tool_digest": H("d"), "entry_appvars": AV0(),
         "allow": {"unresolved_blackbox": [], "interface_only": [],
                   "empty_blackbox": [], "unmatched": []}}
    for k, v in over.items():
        if k == "allow" and isinstance(v, dict):
            e["allow"] = {**e["allow"], **v}
        else:
            e[k] = v
    return e

def OBJ0():
    return {"matched_blackbox_pairs": [], "matched_unread_notcompared_pairs": [],
            "matched_dont_verify_pairs": [],
            "interface_only_ref": [], "interface_only_impl": [],
            "unresolved_blackbox_ref": [], "unresolved_blackbox_impl": [],
            "empty_blackbox_ref": [], "empty_blackbox_impl": [],
            "unlinked_blackbox_ref": [], "unlinked_blackbox_impl": [],
            "unmatched_ref": [], "unmatched_impl": [],
            "unmatched_unread_ref": [], "unmatched_unread_impl": [],
            "unmatched_dont_verify_ref": [], "unmatched_dont_verify_impl": [],
            "unmatched_bbox_output_ref": [], "unmatched_bbox_output_impl": [],
            "unmatched_bbox_input_ref": [], "unmatched_bbox_input_impl": [],
            "unmatched_primary_input_ref": [], "unmatched_primary_input_impl": []}

def facts(**over):
    f = {"native_verdict": "SUCCEEDED",
         "stats": {"passing": 2055, "failing": 0, "unverified": 0, "aborted": 0, "unread_notcompared": 0},
         "unmatched": {"compare_ref": 0, "compare_impl": 0, "unread_ref": 0, "unread_impl": 0,
                       "bbout_ref": 0, "bbout_impl": 0},
         "objects": OBJ0(), "entry_appvars": AV0(),
         "qualifications": {"dont_verify_objects": [], "elab147": [], "relaxed_appvars": []}}
    for k, v in over.items():
        if "." in k:
            a, b = k.split("."); f[a] = dict(f[a]); f[a][b] = v
        else:
            f[k] = v
    return f

def build(fact_over=None, env_over=None, native_diverge=None, run_id="RID-1", top=TOP,
          raw_env=None, native_fifo=False):
    d = tempfile.mkdtemp()
    fx = facts(**(fact_over or {}))
    nat = {"schema": "fm-sidecar-native-v1", "run_id": run_id, "top": top, **fx}
    np = os.path.join(d, "native_facts.json")
    json.dump(nat, open(np, "w"))
    nat_sha = hashlib.sha256(open(np, "rb").read()).hexdigest()
    if native_fifo:
        os.unlink(np); os.mkfifo(np)
    env_fx = facts(**(fact_over or {}))
    for k, v in (native_diverge or {}).items():
        if "." in k:
            a, b = k.split("."); env_fx[a] = dict(env_fx[a]); env_fx[a][b] = v
        else:
            env_fx[k] = v
    env = {"schema": "fm-sidecar-envelope-v1", "run_id": run_id, "target": TOP, "top": top,
           "variant": TOP, "proof_mode": "signoff-strict", "canonical_baseline_id": BID,
           "inputs_sha256": {"ref_srcs_digest": H("a"), "impl_srcs_digest": H("b")},
           "script_sha256": H("c"), "tool": {"fm_shell_digest": H("d")},
           "fm_shell_rc": 0, "native_facts_sha256": nat_sha, **env_fx}
    for k, v in (env_over or {}).items():
        if "." in k:
            a, b = k.split("."); env[a] = dict(env[a]); env[a][b] = v
        else:
            env[k] = v
    ep = os.path.join(d, "verdict.sidecar.json")
    if raw_env is not None:
        open(ep, "w").write(raw_env)
    else:
        json.dump(env, open(ep, "w"))
    return d, ep, np

def run(fact_over=None, env_over=None, native_diverge=None, exp=None, actual_rc=0,
        run_id="RID-1", top=TOP, drop_native=False, corrupt_native_sha=False,
        raw_env=None, symlink_env=False, native_fifo=False):
    d, ep, np = build(fact_over, env_over, native_diverge, run_id, top, raw_env, native_fifo)
    if corrupt_native_sha:
        open(np, "a").write(" ")
    if drop_native:
        os.unlink(np)
    path = ep
    if symlink_env:
        lp = ep + ".lnk"; os.symlink(ep, lp); path = lp
    try:
        v, q = verdict(path, exp if exp is not None else expect(), actual_rc, np)
    finally:
        shutil.rmtree(d, ignore_errors=True)
    return v, q.get("reason")

CASES = []
def C(name, want, **kw):
    CASES.append((name, want, kw))

# ================= 正样本 =================
C("strict_clean_success", "SUCCEEDED")
# assembly observed==policy 投影
AS_FACTS = dict(fact_over={
    "unmatched.compare_ref": 2, "unmatched.compare_impl": 2,
    "objects.unmatched_ref": [R0, R1], "objects.unmatched_impl": [I0, I1],
    "objects.interface_only_ref": [R0], "objects.interface_only_impl": [I0],
    "objects.matched_blackbox_pairs": [P(R0, I0)]},   # v8: iface 实例必产 matched pair
    env_over={"proof_mode": "assembly"})
AEXP = expect(proof_mode="assembly",
              allow={"unmatched": [M("A", R0, I0), M("B", R1, I1)],
                     "interface_only": [M("A", R0, I0)]})
C("asm_observed_matches_policy", "SUCCEEDED", **AS_FACTS, exp=AEXP)

# ================= 六审 6 新对抗 =================
# 1. one-to-many / many-to-one: ref 重复(双射违规)
C("policy_one_to_many", "ERROR", **AS_FACTS,
  exp=expect(proof_mode="assembly",
             allow={"unmatched": [M("A", R0, I0), M("B", R0, I1)],
                    "interface_only": [M("A", R0, I0)]}))
# 2. 同一物理 pair 两个不同 ID(ref/impl 重复)
C("policy_dup_pair_two_ids", "ERROR", **AS_FACTS,
  exp=expect(proof_mode="assembly",
             allow={"unmatched": [M("A", R0, I0), M("B", R0, I0)],
                    "interface_only": [M("A", R0, I0)]}))
# 3. 同一 ID 跨类别映射不同 pair
C("policy_id_conflict_across_cat", "ERROR", **AS_FACTS,
  exp=expect(proof_mode="assembly",
             allow={"unmatched": [M("A", R0, I0), M("B", R1, I1)],
                    "interface_only": [M("A", R1, I1)]}))
# 4. 2 个 unmatched 对象、compare count 仅 1(计数未覆盖对象数)
C("count_below_objects", "ERROR",
  fact_over={"unmatched.compare_ref": 1, "unmatched.compare_impl": 1,
             "objects.unmatched_ref": [R0, R1], "objects.unmatched_impl": [I0, I1],
             "objects.interface_only_ref": [R0], "objects.interface_only_impl": [I0]},
  env_over={"proof_mode": "assembly"}, exp=AEXP)
# 5. top 自身作为 blackbox(抽象 top, 路径=r:/WORK/<top> 不严格在其下)
C("top_itself_as_blackbox", "ERROR",
  fact_over={"objects.unresolved_blackbox_ref": [f"r:/WORK/{TOP}"],
             "objects.unresolved_blackbox_impl": [f"i:/WORK/{TOP}"],
             "unmatched.bbout_ref": 1, "unmatched.bbout_impl": 1},
  env_over={"proof_mode": "assembly"}, exp=AEXP)
# 6. native facts 是 FIFO(fail-fast, 不挂死)
C("native_fifo_failfast", "ERROR", native_fifo=True)

# ================= 七审新对抗 =================
# 1a. 跨类别: 同 ref 对应两个 impl(blackbox r0→i0 + unmatched r0→i1)
C("cross_cat_ref_two_impls", "ERROR", **AS_FACTS,
  exp=expect(proof_mode="assembly",
             allow={"unresolved_blackbox": [M("B", R0, I0)],
                    "unmatched": [M("U", R0, I1), M("B2", R1, I1)],
                    "interface_only": [M("A", R1, I1)]}))
# 1b. 跨类别: 同一 pair 两个 id
C("cross_cat_same_pair_two_ids", "ERROR", **AS_FACTS,
  exp=expect(proof_mode="assembly",
             allow={"unresolved_blackbox": [M("B", R0, I0)],
                    "unmatched": [M("U", R0, I0), M("B2", R1, I1)],
                    "interface_only": [M("A", R1, I1)]}))
# 2. matched-blackbox 空列表绕过: allow.unresolved_blackbox 非空+observed unresolved 匹配+matched=[]
C("matched_empty_bypass", "PARTIAL",
  fact_over={"objects.unresolved_blackbox_ref": [R0], "objects.unresolved_blackbox_impl": [I0],
             "objects.matched_blackbox_pairs": []},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly", allow={"unresolved_blackbox": [M("A", R0, I0)]}))
# 3. 计数/列表单位对齐: compare=3 列表2项(两方向)
C("count_gt_list", "ERROR",
  fact_over={"unmatched.compare_ref": 3, "unmatched.compare_impl": 3,
             "objects.unmatched_ref": [R0, R1], "objects.unmatched_impl": [I0, I1],
             "objects.interface_only_ref": [R0], "objects.interface_only_impl": [I0]},
  env_over={"proof_mode": "assembly"}, exp=AEXP)

# ================= v8(3A.1 审定: 决定2 pair 分类 + 决定3 bbout zero-only) =================
# 审查点名假绿A: interface-only 实例正确但 matched pair 为空 → 不得 SUCCEEDED
C("iface_pairs_empty_fake_green", "PARTIAL",
  fact_over={"unmatched.compare_ref": 2, "unmatched.compare_impl": 2,
             "objects.unmatched_ref": [R0, R1], "objects.unmatched_impl": [I0, I1],
             "objects.interface_only_ref": [R0], "objects.interface_only_impl": [I0],
             "objects.matched_blackbox_pairs": []},
  env_over={"proof_mode": "assembly"}, exp=AEXP)
# 审查点名假绿B(决定3): bbout 两侧对称非零 → 不得 SUCCEEDED(zero-only)
# (十审适配: 计数=列表llength派生, fixture 改计数-列表一致的真实形态, 意图不变)
C("bbout_symmetric_nonzero", "PARTIAL",
  fact_over={"unmatched.bbout_ref": 2, "unmatched.bbout_impl": 2,
             "objects.unmatched_bbox_output_ref": [R0, R1],
             "objects.unmatched_bbox_output_impl": [I0, I1]},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
# pair 端点不在任何实例集合(未知类) → ERROR
C("pair_unknown_class", "ERROR",
  fact_over={"objects.matched_blackbox_pairs": [P(R1, I1)]},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
# pair 混类(ref∈iface, impl∈unresolved) → ERROR(先于 policy 比对)
C("pair_mixed_class", "ERROR",
  fact_over={"objects.interface_only_ref": [R0], "objects.unresolved_blackbox_impl": [I0],
             "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
# pair 仅一端命中(ref∈iface, impl 无归属) → ERROR
C("pair_one_end_only", "ERROR",
  fact_over={"objects.interface_only_ref": [R0], "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
# 实例集合类别重叠(同 ref 同时 iface+unresolved) → ERROR
C("bb_category_overlap", "ERROR",
  fact_over={"objects.interface_only_ref": [R0], "objects.interface_only_impl": [I0],
             "objects.unresolved_blackbox_ref": [R0], "objects.unresolved_blackbox_impl": [I1],
             "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
# 正样本: unresolved 实例+pair+policy 三方一致 → SUCCEEDED
C("unresolved_pairs_ok", "SUCCEEDED",
  fact_over={"objects.unresolved_blackbox_ref": [R0], "objects.unresolved_blackbox_impl": [I0],
             "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly", allow={"unresolved_blackbox": [M("B", R0, I0)]}))
# 负样本: pair 归 unresolved 类但 policy 写在 interface_only 类 → PARTIAL(类别不可互换)
C("pair_wrong_policy_category", "PARTIAL",
  fact_over={"objects.unresolved_blackbox_ref": [R0], "objects.unresolved_blackbox_impl": [I0],
             "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly", allow={"interface_only": [M("B", R0, I0)]}))

# ================= v9(3A.2 审定四补丁) =================
# 补丁1: BBIN/PI zero-only(不被 generic allow.unmatched 吸收; 对称也 PARTIAL)
C("bbin_nonzero_zero_only", "PARTIAL",
  fact_over={"objects.unmatched_bbox_input_ref": [R0], "objects.unmatched_bbox_input_impl": [I0]},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
C("pi_nonzero_zero_only", "PARTIAL",
  fact_over={"objects.unmatched_primary_input_impl": [I0]},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
C("bbout_list_nonzero_zero_only", "PARTIAL",
  fact_over={"unmatched.bbout_ref": 1, "unmatched.bbout_impl": 1,
             "objects.unmatched_bbox_output_ref": [R0], "objects.unmatched_bbox_output_impl": [I0]},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
# 补丁1: empty 类与 iface/unresolved 同权分类
C("empty_pairs_ok", "SUCCEEDED",
  fact_over={"objects.empty_blackbox_ref": [R0], "objects.empty_blackbox_impl": [I0],
             "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly", allow={"empty_blackbox": [M("E", R0, I0)]}))
C("empty_pairs_missing_fake_green", "PARTIAL",
  fact_over={"objects.empty_blackbox_ref": [R0], "objects.empty_blackbox_impl": [I0],
             "objects.matched_blackbox_pairs": []},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly", allow={"empty_blackbox": [M("E", R0, I0)]}))
C("empty_iface_category_overlap", "ERROR",
  fact_over={"objects.empty_blackbox_ref": [R0], "objects.empty_blackbox_impl": [I0],
             "objects.interface_only_ref": [R0], "objects.interface_only_impl": [I1],
             "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
# 补丁2: 计数=列表 llength 派生, 三处单位绑定
C("unread_count_list_mismatch", "ERROR",
  fact_over={"unmatched.unread_ref": 1},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
C("notcompared_count_pairs_mismatch", "ERROR",
  fact_over={"stats.unread_notcompared": 2,
             "objects.matched_unread_notcompared_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"}, exp=expect(proof_mode="assembly"))
# 补丁2: strict 契约不变——unread 非空仍 PARTIAL(Bku 仍非 clean strict success)
C("strict_unread_lists_still_partial", "PARTIAL",
  fact_over={"unmatched.unread_ref": 1, "unmatched.unread_impl": 1,
             "objects.unmatched_unread_ref": [R0], "objects.unmatched_unread_impl": [I0]})
# 补丁3: entry appvars 绑定
C("appvar_missing_key", "ERROR",
  fact_over={"entry_appvars": {"verification_verify_unread_compare_points": "false"}})
C("appvar_unread_true_frozen", "ERROR",
  fact_over={"entry_appvars": {**AV0(), "verification_verify_unread_compare_points": "true"}},
  exp=expect(entry_appvars={**AV0(), "verification_verify_unread_compare_points": "true"}))
C("appvar_strict_iface_nonempty", "ERROR",
  fact_over={"entry_appvars": {**AV0(), "hdlin_interface_only": "DCache"}},
  exp=expect(entry_appvars={**AV0(), "hdlin_interface_only": "DCache"}))
C("appvar_env_expect_mismatch", "ERROR",
  fact_over={"entry_appvars": {**AV0(), "verification_merge_duplicated_registers": "false"}})
C("appvar_asm_iface_nonempty_ok", "SUCCEEDED",
  fact_over={"entry_appvars": {**AV0(), "hdlin_interface_only": "RVCExpander"},
             "objects.interface_only_ref": [R0], "objects.interface_only_impl": [I0],
             "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly",
             entry_appvars={**AV0(), "hdlin_interface_only": "RVCExpander"},
             allow={"interface_only": [M("A", R0, I0)]}))
# 补丁4: native FAILED 最高优先级——policy 全覆盖也不得升级(WAIVED 不进 sidecar)
C("native_failed_waiver_cannot_upgrade", "FAILED",
  fact_over={"native_verdict": "FAILED", "stats.failing": 20,
             "objects.empty_blackbox_ref": [R0], "objects.empty_blackbox_impl": [I0],
             "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly", allow={"empty_blackbox": [M("E", R0, I0)]}))

# ================= v10(十审三阻塞) =================
# 阻塞2: appvar 注册表
C("appvar_unknown_key", "ERROR",
  fact_over={"entry_appvars": {**AV0(), "verification_timeout_limit": "3600"}},
  exp=expect(entry_appvars={**AV0(), "verification_timeout_limit": "3600"}))
C("appvar_diag_only_in_strict", "ERROR",
  fact_over={"entry_appvars": {**AV0(), "verification_failing_point_limit": "20"}},
  exp=expect(entry_appvars={**AV0(), "verification_failing_point_limit": "20"}))
C("appvar_diag_only_in_diag_ok", "DIAGNOSTIC",
  fact_over={"entry_appvars": {**AV0(), "verification_failing_point_limit": "20"}},
  env_over={"proof_mode": "diagnostic-full"},
  exp=expect(proof_mode="diagnostic-full",
             entry_appvars={**AV0(), "verification_failing_point_limit": "20"}))
C("appvar_registry_optional_ok", "SUCCEEDED",
  fact_over={"entry_appvars": {**AV0(), "verification_assume_reg_init": "Auto"}},
  exp=expect(entry_appvars={**AV0(), "verification_assume_reg_init": "Auto"}))
C("appvar_missing_unread_sixtuple", "ERROR",
  fact_over={"entry_appvars": {k: v for k, v in AV0().items()
                               if k != "verification_verify_unread_bbox_inputs"}})
# 阻塞3: count/list 自相矛盾=损坏 sidecar, shadow/diagnostic 也 ERROR(不豁免)
C("shadow_count_list_mismatch", "ERROR",
  fact_over={"unmatched.compare_ref": 1},
  env_over={"proof_mode": "shadow"}, exp=expect(proof_mode="shadow"))
C("diag_count_list_mismatch", "ERROR",
  fact_over={"stats.unread_notcompared": 3},
  env_over={"proof_mode": "diagnostic-full"}, exp=expect(proof_mode="diagnostic-full"))
# 阻塞3: zero-only 是证明政策——shadow/diagnostic 保持各自非签核分类, 观察事实完整保留
C("shadow_zero_only_preserved", "SHADOW_CHECK",
  fact_over={"unmatched.bbout_ref": 1, "unmatched.bbout_impl": 1,
             "objects.unmatched_bbox_output_ref": [R0], "objects.unmatched_bbox_output_impl": [I0]},
  env_over={"proof_mode": "shadow"}, exp=expect(proof_mode="shadow"))
C("diag_zero_only_preserved", "DIAGNOSTIC",
  fact_over={"objects.unmatched_bbox_input_impl": [I0]},
  env_over={"proof_mode": "diagnostic-full"}, exp=expect(proof_mode="diagnostic-full"))
# 阻塞3: 损坏检查先于 native FAILED(FAILED+corrupt → ERROR 非 FAILED)
C("corrupt_beats_native_failed", "ERROR",
  fact_over={"native_verdict": "FAILED", "stats.failing": 5, "unmatched.unread_ref": 2})

# ================= v11(十一审: APPVAR_SPEC 值域闭环) =================
# 审查独立复现的三个 banana(三方一致的任意串此前可 SUCCEEDED/DIAGNOSTIC)
C("appvar_banana_matched_unread", "ERROR",
  fact_over={"entry_appvars": {**AV0(),
             "verification_verify_matched_unread_compare_points": "banana"}},
  exp=expect(entry_appvars={**AV0(),
             "verification_verify_matched_unread_compare_points": "banana"}))
C("appvar_banana_assume_reg_init", "ERROR",
  fact_over={"entry_appvars": {**AV0(), "verification_assume_reg_init": "banana"}},
  exp=expect(entry_appvars={**AV0(), "verification_assume_reg_init": "banana"}))
C("appvar_banana_failing_limit_diag", "ERROR",
  fact_over={"entry_appvars": {**AV0(), "verification_failing_point_limit": "banana"}},
  env_over={"proof_mode": "diagnostic-full"},
  exp=expect(proof_mode="diagnostic-full",
             entry_appvars={**AV0(), "verification_failing_point_limit": "banana"}))
# 冻结六元组: 值域合法但违反冻结语义(matched_unread_bbox_inputs 冻结为 true)
C("appvar_frozen_sixtuple_violation", "ERROR",
  fact_over={"entry_appvars": {**AV0(),
             "verification_verify_matched_unread_bbox_inputs": "false"}},
  exp=expect(entry_appvars={**AV0(),
             "verification_verify_matched_unread_bbox_inputs": "false"}))
# 放宽值未声明进 relaxed_appvars → ERROR; 声明后 strict 判 PARTIAL(不能升级 clean)
RELAX_AV = {**AV0(), "verification_propagate_const_reg_x": "true"}
C("appvar_relax_undeclared", "ERROR",
  fact_over={"entry_appvars": RELAX_AV}, exp=expect(entry_appvars=RELAX_AV))
C("appvar_relax_declared_strict_partial", "PARTIAL",
  fact_over={"entry_appvars": RELAX_AV,
             "qualifications.relaxed_appvars": ["verification_propagate_const_reg_x"]},
  exp=expect(entry_appvars=RELAX_AV))
# 停用值(X/Z 自 S-2021.06 停用, 不入域)
C("appvar_undriven_discontinued_Z", "ERROR",
  fact_over={"entry_appvars": {**AV0(), "verification_set_undriven_signals": "Z"}},
  exp=expect(entry_appvars={**AV0(), "verification_set_undriven_signals": "Z"}))
# assembly 的 interface_only 必须规范化 Tcl module list(裸标识符单空格分隔)
C("appvar_iface_not_normalized_asm", "ERROR",
  fact_over={"entry_appvars": {**AV0(), "hdlin_interface_only": "{A} {B}"}},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly",
             entry_appvars={**AV0(), "hdlin_interface_only": "{A} {B}"}))
# failing limit 非规范化十进制(前导零)
C("appvar_failing_limit_noncanonical", "ERROR",
  fact_over={"entry_appvars": {**AV0(), "verification_failing_point_limit": "020"}},
  env_over={"proof_mode": "diagnostic-full"},
  exp=expect(proof_mode="diagnostic-full",
             entry_appvars={**AV0(), "verification_failing_point_limit": "020"}))

# ================= v12(combo-flag: unlinked 修饰符 observed fact) =================
# unlinked 集非空 → strict PARTIAL(有 objects; 保留不丢)
C("unlinked_strict_partial", "PARTIAL",
  fact_over={"objects.empty_blackbox_ref": [R0], "objects.empty_blackbox_impl": [I0],
             "objects.unlinked_blackbox_ref": [R0], "objects.unlinked_blackbox_impl": [I0],
             "objects.matched_blackbox_pairs": []})
# unlinked 路径非法(不在 top 下)→ ERROR
C("unlinked_bad_path", "ERROR",
  fact_over={"objects.unlinked_blackbox_ref": ["r:/WORK/EVIL/x"]})
# assembly: e* 实例在 empty 类 + unlinked 记录, pair 分类正常 → SUCCEEDED
C("unlinked_assembly_ok", "SUCCEEDED",
  fact_over={"objects.empty_blackbox_ref": [R0], "objects.empty_blackbox_impl": [I0],
             "objects.unlinked_blackbox_ref": [R0], "objects.unlinked_blackbox_impl": [I0],
             "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly", allow={"empty_blackbox": [M("E", R0, I0)]}))

# ================= v5 回归(适配 observed 模型) =================
C("iface_wrong_impl_observed", "PARTIAL",
  fact_over={"unmatched.compare_ref": 2, "unmatched.compare_impl": 2,
             "objects.unmatched_ref": [R0, R1], "objects.unmatched_impl": [I0, I1],
             "objects.interface_only_ref": [R0], "objects.interface_only_impl": [I1]},
  env_over={"proof_mode": "assembly"}, exp=AEXP)
C("namespace_swap", "ERROR",
  fact_over={"objects.unmatched_ref": [I0], "objects.unmatched_impl": [R0],
             "unmatched.compare_ref": 1, "unmatched.compare_impl": 1},
  env_over={"proof_mode": "assembly"}, exp=AEXP)
C("unicode_zwsp_path", "ERROR",
  fact_over={"objects.unmatched_ref": [R0 + "​"], "objects.unmatched_impl": [I0],
             "unmatched.compare_ref": 1, "unmatched.compare_impl": 1},
  env_over={"proof_mode": "assembly"}, exp=AEXP)
C("symlink_envelope", "ERROR", symlink_env=True)

# ================= v4 回归 =================
C("token_trailing_newline", "ERROR", env_over={"target": "Bku\n"}, exp=expect(target="Bku\n"))
C("native_env_mismatch_verdict", "ERROR",
  fact_over={"native_verdict": "FAILED", "stats.failing": 20},
  native_diverge={"native_verdict": "SUCCEEDED", "stats.failing": 0})
C("native_env_mismatch_stats", "ERROR", native_diverge={"stats.passing": 9999})
C("native_sha_mismatch", "ERROR", corrupt_native_sha=True)
C("native_missing", "ERROR", drop_native=True)
C("inputs_null", "ERROR", env_over={"inputs_sha256": None})
C("stats_null", "ERROR", env_over={"stats": None})
C("toplevel_list_env", "ERROR", raw_env='[1,2]')

# ================= v3 回归 =================
# (十审适配: 真实计数不对称 = 列表不对称, 计数与各自列表一致)
C("asm_count_asym_compare", "PARTIAL",
  fact_over={"unmatched.compare_ref": 2, "unmatched.compare_impl": 0,
             "objects.unmatched_ref": [R0, R1], "objects.unmatched_impl": [],
             "objects.interface_only_ref": [R0], "objects.interface_only_impl": [I0],
             "objects.matched_blackbox_pairs": [P(R0, I0)]},
  env_over={"proof_mode": "assembly"}, exp=AEXP)
C("asm_count_asym_bbout", "ERROR",
  fact_over={"unmatched.bbout_ref": 5, "unmatched.bbout_impl": 0,
             "objects.unresolved_blackbox_ref": [R0], "objects.unresolved_blackbox_impl": [I0]},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly", allow={"unresolved_blackbox": [M("A", R0, I0)]}))
C("both_empty_target", "ERROR", env_over={"target": ""}, exp=expect(target=""))
C("both_traversal_variant", "ERROR", env_over={"variant": "../../evil"},
  exp=expect(variant="../../evil"))
C("both_int_runid", "ERROR", env_over={"run_id": 5}, exp=expect(run_id=5))
C("strict_expect_with_allowlist", "ERROR",
  exp=expect(allow={"unresolved_blackbox": [M("A", R0, I0)]}))
C("asm_count_only_no_objects", "ERROR",
  fact_over={"unmatched.compare_ref": 5, "unmatched.compare_impl": 5},
  env_over={"proof_mode": "assembly"}, exp=AEXP)

# ================= v2 回归 =================
C("fake_baseline", "ERROR", env_over={"canonical_baseline_id": "G0-FAKE"})
C("bool_as_int", "ERROR", env_over={"fm_shell_rc": False, "stats.passing": True})
C("wrong_run_id", "ERROR", env_over={"run_id": "OLD"})
C("wrong_variant", "ERROR", env_over={"variant": "Xxx"})
C("ref_digest_mismatch", "ERROR", env_over={"inputs_sha256.ref_srcs_digest": H("f")})
C("script_digest_mismatch", "ERROR", env_over={"script_sha256": H("f")})
C("tool_digest_mismatch", "ERROR", env_over={"tool.fm_shell_digest": H("f")})
C("mode_mismatch", "ERROR", env_over={"proof_mode": "assembly"})
C("actual_rc_nonzero", "ERROR", actual_rc=134)
C("selfreport_rc_nonzero", "ERROR", env_over={"fm_shell_rc": 137}, actual_rc=137)
C("rc_disagree", "ERROR", env_over={"fm_shell_rc": 0}, actual_rc=1)
C("empty_proof", "ERROR", fact_over={"stats.passing": 0})
C("success_but_failing", "FAILED", fact_over={"stats.failing": 20})
C("bad_schema", "ERROR", env_over={"schema": "wrong"})
C("native_failed", "FAILED", fact_over={"native_verdict": "FAILED", "stats.failing": 5})
C("native_notrun", "UNRUN", fact_over={"native_verdict": "NOT_RUN"})
C("dup_keys_env", "ERROR", raw_env='{"schema":"fm-sidecar-envelope-v1","schema":"x"}')
C("nan_env", "ERROR", raw_env='{"schema":"fm-sidecar-envelope-v1","x":NaN}')
C("neg_count", "ERROR", fact_over={"stats.passing": -5})
C("uppercase_hash", "ERROR", env_over={"script_sha256": "A" * 64})
C("short_hash", "ERROR", env_over={"script_sha256": "a" * 63})
C("qual_unsorted", "ERROR", fact_over={"qualifications.dont_verify_objects": ["z", "a"]})
C("qual_dup", "ERROR", fact_over={"qualifications.dont_verify_objects": ["a", "a"]})
C("qual_empty_str", "ERROR", fact_over={"qualifications.dont_verify_objects": [""]})
C("elab147_bool", "ERROR", fact_over={"qualifications.elab147": True})
C("obj_unsorted", "ERROR", fact_over={"objects.unmatched_ref": [R1, R0]})

# ================= strict qualification 回归 =================
# (十审适配: 计数-列表一致形态)
C("strict_unread_nc", "PARTIAL",
  fact_over={"stats.unread_notcompared": 1,
             "objects.matched_unread_notcompared_pairs": [P(R0, I0)]})
C("strict_unread_um", "PARTIAL",
  fact_over={"unmatched.unread_impl": 1, "objects.unmatched_unread_impl": [I0]})
C("strict_bb_obj", "PARTIAL", fact_over={"objects.unresolved_blackbox_impl": [I0]})
C("strict_matched_pair", "PARTIAL", fact_over={"objects.matched_blackbox_pairs": [P(R0, I0)]})
C("strict_dontverify", "PARTIAL", fact_over={"qualifications.dont_verify_objects": ["io_x"]})
C("strict_elab147", "PARTIAL", fact_over={"qualifications.elab147": ["ram_40x47"]})
C("strict_relaxed_appvar", "PARTIAL", fact_over={"qualifications.relaxed_appvars": ["verify_unread"]})
C("strict_interface_only", "PARTIAL", fact_over={"objects.interface_only_ref": [R0]})

# ================= shadow / diagnostic =================
C("shadow_only", "SHADOW_CHECK", env_over={"proof_mode": "shadow"}, exp=expect(proof_mode="shadow"))
C("diagnostic_never", "DIAGNOSTIC", env_over={"proof_mode": "diagnostic-full"},
  exp=expect(proof_mode="diagnostic-full"))

def main():
    npass = 0; total = 0
    for name, want, kw in CASES:
        try:
            got, reason = run(**kw)
        except Exception as e:
            got, reason = f"EXC:{type(e).__name__}", None
        ok = got == want
        npass += ok; total += 1
        print(f"{'PASS' if ok else 'FAIL'}  {name:34s} want={want:12s} got={got}"
              + ("" if ok else f"  reason={reason}"))
    # 缺字段(删 stats)
    d, ep, np = build()
    env = json.load(open(ep)); del env["stats"]; json.dump(env, open(ep, "w"))
    try:
        v, q = verdict(ep, expect(), 0, np); got = v
    except Exception as e:
        got = f"EXC:{type(e).__name__}"
    shutil.rmtree(d, ignore_errors=True)
    ok = got == "ERROR"; npass += ok; total += 1
    print(f"{'PASS' if ok else 'FAIL'}  missing_field_stats                want=ERROR        got={got}")
    # expectation dup-key
    fd, p = tempfile.mkstemp(); os.close(fd)
    open(p, "w").write('{"a":1,"a":2}')
    try:
        strict_load(p); dup_ok = False
    except Bad:
        dup_ok = True
    except Exception:
        dup_ok = False
    os.unlink(p)
    npass += dup_ok; total += 1
    print(f"{'PASS' if dup_ok else 'FAIL'}  expectation_dup_keys               want=Bad got={'Bad' if dup_ok else 'accepted'}")
    # 非 SUCCEEDED 全带非 None reason
    for want_v, kw in (("FAILED", dict(fact_over={"stats.failing": 20})),
                       ("UNRUN", dict(fact_over={"native_verdict": "NOT_RUN"})),
                       ("SHADOW_CHECK", dict(env_over={"proof_mode": "shadow"}, exp=expect(proof_mode="shadow"))),
                       ("DIAGNOSTIC", dict(env_over={"proof_mode": "diagnostic-full"}, exp=expect(proof_mode="diagnostic-full")))):
        got_v, reason = run(**kw)
        ok = got_v == want_v and reason is not None
        npass += ok; total += 1
        print(f"{'PASS' if ok else 'FAIL'}  reason_not_none_{want_v:14s} got={got_v} reason={reason}")
    print(f"\n{npass}/{total} passed")
    sys.exit(0 if npass == total else 1)

if __name__ == "__main__":
    main()
