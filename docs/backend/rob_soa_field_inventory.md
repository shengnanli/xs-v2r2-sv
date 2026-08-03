# Rob SoA full-migration — FROZEN field inventory (codex 0104, Rob-SoA-integrator)

Integrator: `Rob-SoA-integrator` (codex 0104 阶段2). Base: agent/soa-canary-fix@a63efe4.
Integration worktree: /tmp/rob-soa-integ, branch agent/rob-soa-integ.

## Provenance (root hashes)
- golden Rob.sv       : `/home/eda/xs-env/G0-canonical/golden-rtl/Rob.sv`
  sha256 `c3f1aa603afb25d5b40472a52c8a1fd50f420ffe0273faf1abe1f9ac89c89428`
- impl Rob.sv (base)  : rtl/backend/Rob.sv
  sha256 `74173c8d8b256416929b07c5096e058fda31acdddbca1925f11b776891e4f867`
- rob_pkg.sv (base)   : rtl/backend/rob_pkg.sv
  sha256 `e43da2e5b9bb475b93f79a3464b2daefdc168c568af4f80ddf7a7ead11afcfe6`
- **field_inventory_root_sha256** :
  `a07cd2f3652b1560132f1267f01e4307638c268e21eef8ce952f329c4d67a9a9`
  (sha256 of sorted `field|width` over the 25 impl-stored fields)
- field_inventory_group_root_sha256 :
  `5faeb6d4793571a76473cdc4db609ed053dabccc76c45207aa08e682e574e83f`
  (sha256 of sorted `field|width|group`)

Regenerate: `python3 /tmp/rob-soa-integ-evidence/build_field_inventory.py`

## Field totals (machine-parsed from golden reg decls, entry 0 canonical)
- golden reg fields per entry (all)        : **27**
- golden-only DPI sinks (impl 不存)         : **2** = debug_ldest(6b) + debug_pdest(8b) = 14b
- **impl-stored fields**                    : **25** = **59 bits/entry** = **9440 reg-bits** ×160
- golden bits/entry (all 27)                : 73  (= 59 impl-stored + 14 golden-only)

debug_ldest/debug_pdest are declared `reg` in golden but only fed to DiffTest DPI sinks
(DiffExtInstrCommit / debug commit), cone-dead in impl → impl does NOT store them (SoA
does not create arrays for them). They remain golden-only; do NOT pin.

## 4-group partition (25 impl-stored fields — audited: NO dup, NO gap)
partition_ok = **true**. 12 + 3 + 7 + 3 = **25**.

### G1 lifecycle/control/status (12) — owner SoA-group-1 (canary already did 3★)
| golden field    | impl struct field | width |
|-----------------|-------------------|-------|
| valid ★         | valid             | 1 |
| stdWritebacked ★| std_writebacked   | 1 |
| uopNum ★        | uop_num           | 7 |
| needFlush       | need_flush        | 1 |
| interrupt_safe  | interrupt_safe    | 1 |
| mmio            | mmio              | 1 |
| isRVC           | is_rvc            | 1 |
| isVset          | is_vset           | 1 |
| isHls           | is_hls            | 1 |
| realDestSize    | real_dest_size    | 7 |
| instrSize       | instr_size        | 3 |
| commitType      | commit_type       | 3 |
★ = already migrated to SoA by canary (rob_valid/rob_uop_num/rob_std_wb). G1 patch adds
the remaining 9 (needFlush/interrupt_safe/mmio/isRVC/isVset/isHls/realDestSize/instrSize/commitType).

### G2 pointers/indices (3) — owner SoA-group-2
| golden field  | impl struct field | width |
|---------------|-------------------|-------|
| ftqIdx_flag   | ftq_idx_flag      | 1 |
| ftqIdx_value  | ftq_idx_value     | 6 |
| ftqOffset     | ftq_offset        | 4 |

### G3 exception/vector (7) — owner SoA-group-3
| golden field | impl struct field | width |
|--------------|-------------------|-------|
| vls          | vls               | 1 |
| vxsat        | vxsat             | 1 |
| dirtyVs      | dirty_vs          | 1 |
| wflags       | wflags            | 1 |
| fflags       | fflags            | 5 |
| rfWen        | rf_wen            | 1 |
| fpWen        | fp_wen            | 1 |

### G4 trace/perf/deep (3) — owner SoA-group-4
| golden field                | impl struct field | golden w | impl struct w | NOTE |
|-----------------------------|-------------------|----------|---------------|------|
| traceBlockInPipe_itype      | itype             | 4 | 4 | ok |
| traceBlockInPipe_iretire    | iretire           | 4 | 4 | ok |
| traceBlockInPipe_ilastsize  | ilastsize         | **1** | **2** | ★WIDTH★ |

## ★MANDATORY field-map constraint (ilastsize)★
golden `robEntries_N_traceBlockInPipe_ilastsize` is **1-bit** (`reg` no range). impl
struct declares `logic [1:0] ilastsize` (2-bit). The impl bit[1] is **cone-dead**:
- source port `io_enq_req_*_bits_traceBlockInPipe_ilastsize` is 1-bit (zero-extended into [1:0]).
- output port `io_trace_*_ilastsize` is 1-bit (only bit[0] read).
∴ The G4 SoA array `rob_ilastsize` MUST be declared **1-bit** (`logic rob_ilastsize [ROB_SIZE]`)
so it bijection-matches golden 1-bit per-field, eliminating the impl-only dead bit[1].
Its reconstruction into `rob_entries[i].ilastsize` ([1:0]) zero-extends: `{1'b0, rob_ilastsize[i]}`
(or the [1:0] view assigns bit[0] and leaves bit[1] driven-0). This keeps `rob_entries` view
functionally identical (bit[1] already 0-valued everywhere).

All other 24 fields: golden width == impl struct width (exact bijection). See namemap.json.

## Storage model (established by canary, all groups follow)
Per field family, replace the packed `rob_entries_nf.<field>` storage with a semantically
named unpacked array `rob_<field> [ROB_SIZE]`:
- decl:      `logic [W-1:0] rob_<field> [ROB_SIZE];`
- reconstr:  `rob_entries[i].<struct_field> = rob_<field>[i];` (0 flip-flop combinational view)
- next-state: `rob_<field>_next[i] = rob_entries_next[i].<struct_field>;` (always_comb)
- reset:     `rob_<field>[i] <= '0;` (matching golden reset)
- update:    `rob_<field>[i] <= rob_<field>_next[i];` (in the same always_ff)
- remove:    the corresponding `rob_entries_nf[i].<struct_field>` decl + reset + update lines.
DONE gate: NO field stored both in `rob_entries_nf` AND a SoA array (no double-store);
`rob_entries_nf` fully deleted after all 4 groups absorbed (all 25 fields SoA).

Golden per-field name-driven FM pin (per canary, Cell↔Cell _reg form):
- 1-bit: ref `robEntries_N_<gfield>_reg` ↔ impl `rob_<field>_reg[N]`
- multi-bit: per-bit `robEntries_N_<gfield>_reg[b]` ↔ `rob_<field>_reg[N][b]`
