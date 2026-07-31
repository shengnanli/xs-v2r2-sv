#!/usr/bin/env python3
"""Build the authoritative observable-surface spec for G0-StorePipe-observable-v1.
Widths are taken from the FIRRTL bundle type (line 4 of the extracted module),
which is the ground truth; the flattened .sv continuation lines share a width
prefix that a naive line parser drops.
"""
import json, sys

# (leaf_name, width) -- from the FIRRTL bundle type in SimTop.fir line 7084339.
INPUTS = [
    ("clock", 1), ("reset", 1),
    ("io_lsu_s1_paddr", 48), ("io_lsu_s1_kill", 1), ("io_lsu_s2_kill", 1),
    ("io_lsu_s2_pc", 50), ("io_lsu_req_valid", 1), ("io_lsu_req_bits_cmd", 5),
    ("io_lsu_req_bits_vaddr", 50), ("io_lsu_req_bits_instrtype", 4),
    ("io_lsu_resp_ready", 1), ("io_meta_read_ready", 1),
    ("io_meta_resp_0_coh_state", 2), ("io_meta_resp_1_coh_state", 2),
    ("io_meta_resp_2_coh_state", 2), ("io_meta_resp_3_coh_state", 2),
    ("io_tag_read_ready", 1),
    ("io_tag_resp_0", 43), ("io_tag_resp_1", 43), ("io_tag_resp_2", 43),
    ("io_tag_resp_3", 43), ("io_miss_req_ready", 1), ("io_replace_way_way", 2),
]

# 36 defined output leaves: source explicitly `connect`s a value (comb, reg, or
# a source-declared constant). Verified from the FIRRTL `connect io.*` set.
DEFINED_OUTPUTS = [
    ("io_lsu_req_ready", 1),
    ("io_lsu_resp_valid", 1), ("io_lsu_resp_bits_miss", 1),
    ("io_lsu_resp_bits_replay", 1), ("io_lsu_resp_bits_tag_error", 1),
    ("io_meta_read_valid", 1), ("io_meta_read_bits_idx", 8),
    ("io_meta_read_bits_way_en", 4),
    ("io_tag_read_valid", 1), ("io_tag_read_bits_idx", 8),
    ("io_tag_read_bits_way_en", 4),
    ("io_miss_req_valid", 1), ("io_miss_req_bits_source", 4),
    ("io_miss_req_bits_pf_source", 3), ("io_miss_req_bits_cmd", 5),
    ("io_miss_req_bits_addr", 48), ("io_miss_req_bits_vaddr", 50),
    ("io_miss_req_bits_pc", 50), ("io_miss_req_bits_req_coh_state", 2),
    ("io_miss_req_bits_cancel", 1),
    ("io_replace_access_valid", 1),
    ("io_replace_way_set_valid", 1), ("io_replace_way_set_bits", 8),
    ("io_replace_way_dmWay", 2),
    ("io_error_valid", 1), ("io_error_bits_source_tag", 1),
    ("io_error_bits_source_data", 1), ("io_error_bits_source_l2", 1),
    ("io_error_bits_opType_fetch", 1), ("io_error_bits_opType_load", 1),
    ("io_error_bits_opType_store", 1), ("io_error_bits_opType_probe", 1),
    ("io_error_bits_opType_release", 1), ("io_error_bits_opType_atom", 1),
    ("io_error_bits_paddr", 48), ("io_error_bits_report_to_beu", 1),
]

# 14 UNSPECIFIED_BY_SOURCE leaves: FIRRTL only `invalidate`s them and NEVER
# `connect`s a value afterward (last-connect-wins). firtool lowers each to an
# ARBITRARY constant (0) as a DontCare pick -- NOT a source-defined value.
# Excluded from the harness surface. NOT concretized to 0. NOT dont_verify.
UNSPECIFIED = [
    ("io_miss_req_bits_store_mask", 64), ("io_miss_req_bits_store_data", 512),
    ("io_miss_req_bits_occupy_way", 4), ("io_miss_req_bits_isBtoT", 1),
    ("io_miss_req_bits_id", 6), ("io_miss_req_bits_amo_cmp", 128),
    ("io_miss_req_bits_amo_mask", 16), ("io_miss_req_bits_amo_data", 128),
    ("io_miss_req_bits_word_idx", 3), ("io_miss_req_bits_full_overwrite", 1),
    ("io_miss_req_bits_lqIdx_value", 7), ("io_miss_req_bits_lqIdx_flag", 1),
    ("io_replace_access_bits_way", 2), ("io_replace_access_bits_set", 8),
]

# 6 perfCnt_bore probes: firtool lowers Probe<UInt<1>> to XMR `define macros,
# not ordinary ports. Perf-event nodes, no datapath equivalence bearing.
PERF_PROBES = [
    ("perfCnt_bore",   "_GEN",   "s0_valid_not_ready"),
    ("perfCnt_bore_1", "_GEN_0", "store_fire"),
    ("perfCnt_bore_2", "_GEN_1", "sta_hit"),
    ("perfCnt_bore_3", "_GEN_2", "sta_miss"),
    ("perfCnt_bore_4", "_GEN_3", "store_miss_prefetch_fire"),
    ("perfCnt_bore_5", "_GEN_4", "store_miss_prefetch_not_fire"),
]

assert len(DEFINED_OUTPUTS) == 36, len(DEFINED_OUTPUTS)
assert len(UNSPECIFIED) == 14, len(UNSPECIFIED)
assert len(PERF_PROBES) == 6

spec = {
    "schema": "storepipe-observable-surface-v1",
    "derivative_id": "G0-StorePipe-observable-v1",
    "source_baseline_id": "G0-89fe69e83a4f2ea81065ecf9d5d9ab46b0b5a29911fd4f6aa2fefd54dcc13456",
    "classification_rule": (
        "FIRRTL last-connect-wins over the StorePipe module body. A leaf whose "
        "final driver in source is a `connect` -> defined_output. A leaf whose "
        "only driver is `invalidate` (never reconnected) -> UNSPECIFIED_BY_SOURCE. "
        "Probe<> outputs -> perf_probe (XMR macros)."),
    "counts": {"inputs": len(INPUTS), "defined_outputs": 36,
               "perf_probes": 6, "unspecified_by_source": 14,
               "harness_surface_outputs": 36},
    "inputs": [{"leaf": n, "width": w} for n, w in INPUTS],
    "defined_outputs": [{"leaf": n, "width": w} for n, w in DEFINED_OUTPUTS],
    "perf_probes": [{"probe": p, "gen_wire": g, "event": ev}
                    for p, g, ev in PERF_PROBES],
    "unspecified_by_source": [
        {"leaf": n, "width": w, "disposition": "EXCLUDE_FROM_HARNESS_SURFACE",
         "not_concretized_to_zero": True, "not_dont_verify": True}
        for n, w in UNSPECIFIED],
}
json.dump(spec, open(sys.argv[1], "w"), indent=1, ensure_ascii=False)
print("wrote", sys.argv[1])
print("inputs=%d defined_outputs=%d perf_probes=%d unspecified=%d" %
      (len(INPUTS), 36, 6, 14))
