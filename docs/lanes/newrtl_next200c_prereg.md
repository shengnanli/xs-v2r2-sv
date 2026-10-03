# agent/newrtl-next200c lane — 预登记：200 个可读叶目标（consolidation 后）

基线：`agent/core-consolidation` @ `da120910`；独立 worktree `/home/eda/xs-env/wt-newrtl-next200c`。

## 所有权与共享核核对

- 冻结 coverage 逐名为 `in_universe=yes`、`MISSING/UNPROVEN`；bridge 与 ACTIVE lane 全量 `rg -wF` 排除。
- 已排除 Kimi k3next30 及前五批 100 个目标；本批 200 个均为 childless leaf。
- `depends_on_commit=da120910`；本批新增路径独占，`shared_cores_used=none`、`shared_cores_owned=none`，发现既有 core 必须复用，不得复制或改后缀。

## target_modules / files_to_add / files_to_modify / shared_cores_used / shared_cores_owned / depends_on_commit

| # | target_modules | golden lines | family | child deps | expected parent | files_to_add | files_to_modify | shared_cores_used | shared_cores_owned | depends_on_commit |
|---:|---|---:|---|---|---|---|---|---|---|---|
| 1 | `Arbiter16_TLBundleD` | 450 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Arbiter16_TLBundleD.sv` | none | none | none | `da120910` |
| 2 | `Arbiter3_PfGenReq` | 132 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Arbiter3_PfGenReq.sv` | none | none | none | `da120910` |
| 3 | `Arbiter4_L2ToL1Hint` | 132 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Arbiter4_L2ToL1Hint.sv` | none | none | none | `da120910` |
| 4 | `Arbiter4_PrefetchReq` | 143 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Arbiter4_PrefetchReq.sv` | none | none | none | `da120910` |
| 5 | `BusErrorUnit` | 346 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/BusErrorUnit.sv` | none | none | none | `da120910` |
| 6 | `CSA4to2_15` | 146 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/CSA4to2_15.sv` | none | none | none | `da120910` |
| 7 | `Dispatcher` | 233 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher.sv` | none | none | none | `da120910` |
| 8 | `Dispatcher_1` | 279 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_1.sv` | none | none | none | `da120910` |
| 9 | `Dispatcher_10` | 208 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_10.sv` | none | none | none | `da120910` |
| 10 | `Dispatcher_13` | 314 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_13.sv` | none | none | none | `da120910` |
| 11 | `Dispatcher_14` | 329 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_14.sv` | none | none | none | `da120910` |
| 12 | `Dispatcher_15` | 223 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_15.sv` | none | none | none | `da120910` |
| 13 | `Dispatcher_16` | 176 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_16.sv` | none | none | none | `da120910` |
| 14 | `Dispatcher_17` | 269 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_17.sv` | none | none | none | `da120910` |
| 15 | `Dispatcher_4` | 155 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_4.sv` | none | none | none | `da120910` |
| 16 | `Dispatcher_5` | 466 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_5.sv` | none | none | none | `da120910` |
| 17 | `Dispatcher_7` | 291 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_7.sv` | none | none | none | `da120910` |
| 18 | `Dispatcher_8` | 300 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_8.sv` | none | none | none | `da120910` |
| 19 | `Dispatcher_9` | 176 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Dispatcher_9.sv` | none | none | none | `da120910` |
| 20 | `DpcModule` | 132 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/DpcModule.sv` | none | none | none | `da120910` |
| 21 | `DretEventModule` | 262 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/DretEventModule.sv` | none | none | none | `da120910` |
| 22 | `FastArbiter_27` | 359 | arithmetic/vector | none | reachability parent (ledger) | `rtl/<subsys>/FastArbiter_27.sv` | none | none | none | `da120910` |
| 23 | `FliDTable` | 195 | arithmetic/vector | none | reachability parent (ledger) | `rtl/<subsys>/FliDTable.sv` | none | none | none | `da120910` |
| 24 | `FliHTable` | 145 | arithmetic/vector | none | reachability parent (ledger) | `rtl/<subsys>/FliHTable.sv` | none | none | none | `da120910` |
| 25 | `FliSTable` | 174 | arithmetic/vector | none | reachability parent (ledger) | `rtl/<subsys>/FliSTable.sv` | none | none | none | `da120910` |
| 26 | `HPerfCounter` | 290 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/HPerfCounter.sv` | none | none | none | `da120910` |
| 27 | `HPerfCounter_13` | 399 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/HPerfCounter_13.sv` | none | none | none | `da120910` |
| 28 | `HPerfCounter_8` | 370 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/HPerfCounter_8.sv` | none | none | none | `da120910` |
| 29 | `HcounterenModule` | 150 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/HcounterenModule.sv` | none | none | none | `da120910` |
| 30 | `HedelegModule` | 238 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/HedelegModule.sv` | none | none | none | `da120910` |
| 31 | `HenvcfgModule` | 195 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/HenvcfgModule.sv` | none | none | none | `da120910` |
| 32 | `HgatpModule` | 149 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/HgatpModule.sv` | none | none | none | `da120910` |
| 33 | `HidelegModule` | 171 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/HidelegModule.sv` | none | none | none | `da120910` |
| 34 | `Hpmcounter11Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter11Module.sv` | none | none | none | `da120910` |
| 35 | `Hpmcounter12Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter12Module.sv` | none | none | none | `da120910` |
| 36 | `Hpmcounter13Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter13Module.sv` | none | none | none | `da120910` |
| 37 | `Hpmcounter14Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter14Module.sv` | none | none | none | `da120910` |
| 38 | `Hpmcounter15Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter15Module.sv` | none | none | none | `da120910` |
| 39 | `Hpmcounter16Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter16Module.sv` | none | none | none | `da120910` |
| 40 | `Hpmcounter17Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter17Module.sv` | none | none | none | `da120910` |
| 41 | `Hpmcounter18Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter18Module.sv` | none | none | none | `da120910` |
| 42 | `Hpmcounter19Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter19Module.sv` | none | none | none | `da120910` |
| 43 | `Hpmcounter20Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter20Module.sv` | none | none | none | `da120910` |
| 44 | `Hpmcounter21Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter21Module.sv` | none | none | none | `da120910` |
| 45 | `Hpmcounter22Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter22Module.sv` | none | none | none | `da120910` |
| 46 | `Hpmcounter23Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter23Module.sv` | none | none | none | `da120910` |
| 47 | `Hpmcounter24Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter24Module.sv` | none | none | none | `da120910` |
| 48 | `Hpmcounter25Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter25Module.sv` | none | none | none | `da120910` |
| 49 | `Hpmcounter26Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter26Module.sv` | none | none | none | `da120910` |
| 50 | `Hpmcounter27Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter27Module.sv` | none | none | none | `da120910` |
| 51 | `Hpmcounter28Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter28Module.sv` | none | none | none | `da120910` |
| 52 | `Hpmcounter29Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter29Module.sv` | none | none | none | `da120910` |
| 53 | `Hpmcounter30Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter30Module.sv` | none | none | none | `da120910` |
| 54 | `Hpmcounter31Module` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hpmcounter31Module.sv` | none | none | none | `da120910` |
| 55 | `Hstateen0Module` | 205 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hstateen0Module.sv` | none | none | none | `da120910` |
| 56 | `Hstateen1Module` | 124 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hstateen1Module.sv` | none | none | none | `da120910` |
| 57 | `Hstateen2Module` | 124 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hstateen2Module.sv` | none | none | none | `da120910` |
| 58 | `Hstateen3Module` | 124 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hstateen3Module.sv` | none | none | none | `da120910` |
| 59 | `HstatusModule` | 215 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/HstatusModule.sv` | none | none | none | `da120910` |
| 60 | `HtimedeltaModule` | 128 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/HtimedeltaModule.sv` | none | none | none | `da120910` |
| 61 | `HtinstModule` | 132 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/HtinstModule.sv` | none | none | none | `da120910` |
| 62 | `HtvalModule` | 132 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/HtvalModule.sv` | none | none | none | `da120910` |
| 63 | `HvictlModule` | 157 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/HvictlModule.sv` | none | none | none | `da120910` |
| 64 | `Hviprio1Module` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hviprio1Module.sv` | none | none | none | `da120910` |
| 65 | `Hviprio2Module` | 128 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Hviprio2Module.sv` | none | none | none | `da120910` |
| 66 | `IndirectCSRPermitModule` | 153 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/IndirectCSRPermitModule.sv` | none | none | none | `da120910` |
| 67 | `IntBuffer_1` | 134 | arithmetic/vector | none | reachability parent (ledger) | `rtl/<subsys>/IntBuffer_1.sv` | none | none | none | `da120910` |
| 68 | `IntBuffer_2` | 134 | arithmetic/vector | none | reachability parent (ledger) | `rtl/<subsys>/IntBuffer_2.sv` | none | none | none | `da120910` |
| 69 | `Iprio0Module` | 162 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Iprio0Module.sv` | none | none | none | `da120910` |
| 70 | `Iprio0Module_1` | 215 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Iprio0Module_1.sv` | none | none | none | `da120910` |
| 71 | `Iprio10Module_1` | 191 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Iprio10Module_1.sv` | none | none | none | `da120910` |
| 72 | `Iprio12Module_1` | 191 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Iprio12Module_1.sv` | none | none | none | `da120910` |
| 73 | `Iprio14Module_1` | 191 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Iprio14Module_1.sv` | none | none | none | `da120910` |
| 74 | `Iprio2Module` | 155 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Iprio2Module.sv` | none | none | none | `da120910` |
| 75 | `Iprio2Module_1` | 223 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Iprio2Module_1.sv` | none | none | none | `da120910` |
| 76 | `Iprio4Module_1` | 191 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Iprio4Module_1.sv` | none | none | none | `da120910` |
| 77 | `Iprio6Module_1` | 191 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Iprio6Module_1.sv` | none | none | none | `da120910` |
| 78 | `Iprio8Module_1` | 191 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Iprio8Module_1.sv` | none | none | none | `da120910` |
| 79 | `MLevelPermitModule` | 182 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MLevelPermitModule.sv` | none | none | none | `da120910` |
| 80 | `MNretEventModule` | 230 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MNretEventModule.sv` | none | none | none | `da120910` |
| 81 | `MbistIntfFrontend` | 124 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/MbistIntfFrontend.sv` | none | none | none | `da120910` |
| 82 | `MbistIntfMemBlk` | 124 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/MbistIntfMemBlk.sv` | none | none | none | `da120910` |
| 83 | `MbmcModule` | 163 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MbmcModule.sv` | none | none | none | `da120910` |
| 84 | `McontextModule` | 132 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/McontextModule.sv` | none | none | none | `da120910` |
| 85 | `McorepwrModule` | 136 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/McorepwrModule.sv` | none | none | none | `da120910` |
| 86 | `McounterenModule` | 150 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/McounterenModule.sv` | none | none | none | `da120910` |
| 87 | `McountinhibitModule` | 143 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/McountinhibitModule.sv` | none | none | none | `da120910` |
| 88 | `MedelegModule` | 286 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MedelegModule.sv` | none | none | none | `da120910` |
| 89 | `MenvcfgModule` | 186 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MenvcfgModule.sv` | none | none | none | `da120910` |
| 90 | `MflushpwrModule` | 129 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MflushpwrModule.sv` | none | none | none | `da120910` |
| 91 | `Mgtu` | 223 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Mgtu.sv` | none | none | none | `da120910` |
| 92 | `Mhpmcounter10Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter10Module.sv` | none | none | none | `da120910` |
| 93 | `Mhpmcounter11Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter11Module.sv` | none | none | none | `da120910` |
| 94 | `Mhpmcounter12Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter12Module.sv` | none | none | none | `da120910` |
| 95 | `Mhpmcounter13Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter13Module.sv` | none | none | none | `da120910` |
| 96 | `Mhpmcounter14Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter14Module.sv` | none | none | none | `da120910` |
| 97 | `Mhpmcounter15Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter15Module.sv` | none | none | none | `da120910` |
| 98 | `Mhpmcounter16Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter16Module.sv` | none | none | none | `da120910` |
| 99 | `Mhpmcounter17Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter17Module.sv` | none | none | none | `da120910` |
| 100 | `Mhpmcounter18Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter18Module.sv` | none | none | none | `da120910` |
| 101 | `Mhpmcounter19Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter19Module.sv` | none | none | none | `da120910` |
| 102 | `Mhpmcounter20Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter20Module.sv` | none | none | none | `da120910` |
| 103 | `Mhpmcounter21Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter21Module.sv` | none | none | none | `da120910` |
| 104 | `Mhpmcounter22Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter22Module.sv` | none | none | none | `da120910` |
| 105 | `Mhpmcounter23Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter23Module.sv` | none | none | none | `da120910` |
| 106 | `Mhpmcounter24Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter24Module.sv` | none | none | none | `da120910` |
| 107 | `Mhpmcounter25Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter25Module.sv` | none | none | none | `da120910` |
| 108 | `Mhpmcounter26Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter26Module.sv` | none | none | none | `da120910` |
| 109 | `Mhpmcounter27Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter27Module.sv` | none | none | none | `da120910` |
| 110 | `Mhpmcounter28Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter28Module.sv` | none | none | none | `da120910` |
| 111 | `Mhpmcounter29Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter29Module.sv` | none | none | none | `da120910` |
| 112 | `Mhpmcounter30Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter30Module.sv` | none | none | none | `da120910` |
| 113 | `Mhpmcounter31Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter31Module.sv` | none | none | none | `da120910` |
| 114 | `Mhpmcounter3Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter3Module.sv` | none | none | none | `da120910` |
| 115 | `Mhpmcounter4Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter4Module.sv` | none | none | none | `da120910` |
| 116 | `Mhpmcounter5Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter5Module.sv` | none | none | none | `da120910` |
| 117 | `Mhpmcounter6Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter6Module.sv` | none | none | none | `da120910` |
| 118 | `Mhpmcounter7Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter7Module.sv` | none | none | none | `da120910` |
| 119 | `Mhpmcounter8Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter8Module.sv` | none | none | none | `da120910` |
| 120 | `Mhpmcounter9Module` | 139 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mhpmcounter9Module.sv` | none | none | none | `da120910` |
| 121 | `MhpmeventModule` | 243 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MhpmeventModule.sv` | none | none | none | `da120910` |
| 122 | `MidelegModule` | 150 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MidelegModule.sv` | none | none | none | `da120910` |
| 123 | `MipModule` | 257 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MipModule.sv` | none | none | none | `da120910` |
| 124 | `MiselectModule` | 128 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MiselectModule.sv` | none | none | none | `da120910` |
| 125 | `MnstatusModule` | 161 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MnstatusModule.sv` | none | none | none | `da120910` |
| 126 | `MretEventModule` | 220 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MretEventModule.sv` | none | none | none | `da120910` |
| 127 | `MseccfgModule` | 127 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MseccfgModule.sv` | none | none | none | `da120910` |
| 128 | `Mstateen0Module` | 180 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mstateen0Module.sv` | none | none | none | `da120910` |
| 129 | `Mstateen1Module` | 126 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mstateen1Module.sv` | none | none | none | `da120910` |
| 130 | `Mstateen2Module` | 126 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mstateen2Module.sv` | none | none | none | `da120910` |
| 131 | `Mstateen3Module` | 126 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Mstateen3Module.sv` | none | none | none | `da120910` |
| 132 | `MtinstModule` | 132 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/MtinstModule.sv` | none | none | none | `da120910` |
| 133 | `NfMappedElemIdx` | 177 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/NfMappedElemIdx.sv` | none | none | none | `da120910` |
| 134 | `OverrideableQueue` | 271 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/OverrideableQueue.sv` | none | none | none | `da120910` |
| 135 | `OverrideableQueue_1` | 338 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/OverrideableQueue_1.sv` | none | none | none | `da120910` |
| 136 | `PipelineRegModule_6` | 172 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/PipelineRegModule_6.sv` | none | none | none | `da120910` |
| 137 | `Pma16cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma16cfgModule.sv` | none | none | none | `da120910` |
| 138 | `Pma17cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma17cfgModule.sv` | none | none | none | `da120910` |
| 139 | `Pma18cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma18cfgModule.sv` | none | none | none | `da120910` |
| 140 | `Pma19cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma19cfgModule.sv` | none | none | none | `da120910` |
| 141 | `Pma20cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma20cfgModule.sv` | none | none | none | `da120910` |
| 142 | `Pma21cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma21cfgModule.sv` | none | none | none | `da120910` |
| 143 | `Pma22cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma22cfgModule.sv` | none | none | none | `da120910` |
| 144 | `Pma23cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma23cfgModule.sv` | none | none | none | `da120910` |
| 145 | `Pma24cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma24cfgModule.sv` | none | none | none | `da120910` |
| 146 | `Pma25cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma25cfgModule.sv` | none | none | none | `da120910` |
| 147 | `Pma26cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma26cfgModule.sv` | none | none | none | `da120910` |
| 148 | `Pma27cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma27cfgModule.sv` | none | none | none | `da120910` |
| 149 | `Pma28cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma28cfgModule.sv` | none | none | none | `da120910` |
| 150 | `Pma29cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma29cfgModule.sv` | none | none | none | `da120910` |
| 151 | `Pma30cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma30cfgModule.sv` | none | none | none | `da120910` |
| 152 | `Pma31cfgModule` | 176 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pma31cfgModule.sv` | none | none | none | `da120910` |
| 153 | `Pmp21cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp21cfgModule.sv` | none | none | none | `da120910` |
| 154 | `Pmp22cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp22cfgModule.sv` | none | none | none | `da120910` |
| 155 | `Pmp23cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp23cfgModule.sv` | none | none | none | `da120910` |
| 156 | `Pmp24cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp24cfgModule.sv` | none | none | none | `da120910` |
| 157 | `Pmp25cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp25cfgModule.sv` | none | none | none | `da120910` |
| 158 | `Pmp26cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp26cfgModule.sv` | none | none | none | `da120910` |
| 159 | `Pmp27cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp27cfgModule.sv` | none | none | none | `da120910` |
| 160 | `Pmp28cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp28cfgModule.sv` | none | none | none | `da120910` |
| 161 | `Pmp29cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp29cfgModule.sv` | none | none | none | `da120910` |
| 162 | `Pmp30cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp30cfgModule.sv` | none | none | none | `da120910` |
| 163 | `Pmp31cfgModule` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Pmp31cfgModule.sv` | none | none | none | `da120910` |
| 164 | `Queue1_CHIDAT` | 239 | queue/interface | none | reachability parent (ledger) | `rtl/<subsys>/Queue1_CHIDAT.sv` | none | none | none | `da120910` |
| 165 | `Queue1_CHIRSP` | 189 | queue/interface | none | reachability parent (ledger) | `rtl/<subsys>/Queue1_CHIRSP.sv` | none | none | none | `da120910` |
| 166 | `Rec7Table` | 396 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/Rec7Table.sv` | none | none | none | `da120910` |
| 167 | `Rsqrt7Table` | 344 | arithmetic/vector | none | reachability parent (ledger) | `rtl/<subsys>/Rsqrt7Table.sv` | none | none | none | `da120910` |
| 168 | `SatpFlushMod` | 139 | pipeline/control | none | reachability parent (ledger) | `rtl/<subsys>/SatpFlushMod.sv` | none | none | none | `da120910` |

| 169 | `SatpModule` | 147 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/SatpModule.sv` | none | none | none | `da120910` |
| 170 | `SbpctlModule` | 179 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/SbpctlModule.sv` | none | none | none | `da120910` |
| 171 | `ScounterenModule` | 150 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/ScounterenModule.sv` | none | none | none | `da120910` |
| 172 | `SenvcfgModule` | 154 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/SenvcfgModule.sv` | none | none | none | `da120910` |
| 173 | `SiselectModule` | 128 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/SiselectModule.sv` | none | none | none | `da120910` |
| 174 | `SlvpredctlModule` | 163 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/SlvpredctlModule.sv` | none | none | none | `da120910` |
| 175 | `SmblockctlModule` | 187 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/SmblockctlModule.sv` | none | none | none | `da120910` |
| 176 | `SpfctlModule` | 243 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/SpfctlModule.sv` | none | none | none | `da120910` |
| 177 | `SpillRegister_7` | 435 | logging/control | none | reachability parent (ledger) | `rtl/<subsys>/SpillRegister_7.sv` | none | none | none | `da120910` |
| 178 | `SretEventModule` | 255 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/SretEventModule.sv` | none | none | none | `da120910` |
| 179 | `SrnctlModule` | 136 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/SrnctlModule.sv` | none | none | none | `da120910` |
| 180 | `Sstateen0Module` | 152 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Sstateen0Module.sv` | none | none | none | `da120910` |
| 181 | `SstcInterruptGen` | 148 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/SstcInterruptGen.sv` | none | none | none | `da120910` |
| 182 | `StimecmpModule` | 128 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/StimecmpModule.sv` | none | none | none | `da120910` |
| 183 | `TLLogger_1` | 160 | logging/control | none | reachability parent (ledger) | `rtl/<subsys>/TLLogger_1.sv` | none | none | none | `da120910` |
| 184 | `TLLogger_2` | 154 | logging/control | none | reachability parent (ledger) | `rtl/<subsys>/TLLogger_2.sv` | none | none | none | `da120910` |
| 185 | `TrapEntryDEventModule` | 210 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/TrapEntryDEventModule.sv` | none | none | none | `da120910` |
| 186 | `TrapEntryHSEventModule` | 361 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/TrapEntryHSEventModule.sv` | none | none | none | `da120910` |
| 187 | `TrapEntryMEventModule` | 335 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/TrapEntryMEventModule.sv` | none | none | none | `da120910` |
| 188 | `TrapEntryMNEventModule` | 168 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/TrapEntryMNEventModule.sv` | none | none | none | `da120910` |
| 189 | `TrapEntryVSEventModule` | 286 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/TrapEntryVSEventModule.sv` | none | none | none | `da120910` |
| 190 | `TrapInstMod` | 244 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/TrapInstMod.sv` | none | none | none | `da120910` |
| 191 | `TrapTvalMod` | 188 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/TrapTvalMod.sv` | none | none | none | `da120910` |
| 192 | `Trigger0_Tdata1Module` | 161 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Trigger0_Tdata1Module.sv` | none | none | none | `da120910` |
| 193 | `Trigger0_Tdata2Module` | 121 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Trigger0_Tdata2Module.sv` | none | none | none | `da120910` |
| 194 | `Trigger1_Tdata1Module` | 161 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Trigger1_Tdata1Module.sv` | none | none | none | `da120910` |
| 195 | `Trigger1_Tdata2Module` | 121 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Trigger1_Tdata2Module.sv` | none | none | none | `da120910` |
| 196 | `Trigger2_Tdata1Module` | 161 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Trigger2_Tdata1Module.sv` | none | none | none | `da120910` |
| 197 | `Trigger2_Tdata2Module` | 121 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Trigger2_Tdata2Module.sv` | none | none | none | `da120910` |
| 198 | `Trigger3_Tdata1Module` | 160 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Trigger3_Tdata1Module.sv` | none | none | none | `da120910` |
| 199 | `Trigger3_Tdata2Module` | 121 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/Trigger3_Tdata2Module.sv` | none | none | none | `da120910` |
| 200 | `VSatpModule` | 158 | CSR/control | none | reachability parent (ledger) | `rtl/<subsys>/VSatpModule.sv` | none | none | none | `da120910` |
## 验收计划

- 多个互不重叠 family lane；每 lane 独占 wrapper/generator/UT 路径。
- generator --check、portlint、6 seeds × 200000、readability A–G、official signoff-strict Formality。
- prereg、实现/UT、evidence 分离提交；目标不得静默替换；最终 clean worktree。

## 接管节（agent/next200c-takeover，2026-10-03，Claude；原 agent 额度用尽）

基线：main + 已合入 `agent/newrtl-next200c@5094100f` + 认领 commit `8c0238a1d`（认领清单 `docs/lanes/next200c-takeover_claim.md`）。
冲突核查：codex outbox 最新 0207 不涉及下列任何名字；全部 worktree 的 `*_claim.md`/`*_prereg.md` 里这些名字只出现在
本文件与 vectorcvt-tree 的 prereg（后者只把 Rec7Table/Rsqrt7Table 列为 golden child，不改它们）。

### A. 20 个目标的审读结论（原 RTL 不假定正确，逐个对 Scala/golden 读）

| 目标 | 原 RTL 审读发现 | 本节处置 |
|---|---|---|
| PipelineRegModule_6 | ★真 bug★：载荷寄存器写在带 `posedge reset` 的 always 块里——复位期间 in.fire 时 golden（载荷在无复位的 always @(posedge clock)）会更新载荷，原 RTL 不会；原 UT 不在运行中复位，看不见 | 重写；载荷改进无复位 always_ff |
| OverrideableQueue / _1 | ★同类真 bug★：表项数据写在异步复位块里；另外两份各自平铺一遍同一逻辑 | 抽出共享核 `rtl/common/xs_OverrideableQueue_core.sv`（Scala 原样：写赢读清、Mux1H=按 rd_ptr 选），两个 wrapper 只拼载荷 |
| NfMappedElemIdx | 可读性不合格：golden `_GEN_*` 改名照抄（`element_stride_*`/`ranges_nf*` 且命名与语义不符：数组下标其实是 nf、名字里的 nf 其实是 vd 号） | 按 Scala 重写：vrgIdx = vd/(nf+1)，区间 [16*vrg,16*(vrg+1)) 按 eewOH Mux1H 右移 |
| Arbiter3_PfGenReq / Arbiter4_L2ToL1Hint / Arbiter4_PrefetchReq / Arbiter16_TLBundleD | 功能看来对，但各自手写三元链/循环，与仓里已签核的 `xs_FixedPriorityArbiter_core` 重复；头注释一句英文，不讲被删端口与常量字段的来历 | 改成该共享核的 wrapper（Arbiter3_CHIREQ 先例：被删的 ready 记进端口数恒等式）；头注释写清每个常量字段的 Scala 来源 |
| FastArbiter_27 | 已用共享核 xs_FastArbiter_core，正确；但 UT Makefile 把**重写核**放进 RTL_GOLDEN_DEPS（两侧共用、不派生），语义不对 | 头注释补全；Makefile 把核挪进 RTL_SRCS |
| IntBuffer_1 / _2 | 头注释写成"integer datapath"——其实是中断线缓冲；端口多个一行 | 重写成与 agent/k3-returned 的 IntBuffer 同风格（不依赖其未合入的文件，不定义同名核） |
| FliD/H/S Table、Rec7Table、Rsqrt7Table | 128/32 行 case 表，`default: 'x`；表值未对 Scala 逐项核过 | 从 Scala 源机械抽取成 localparam 表（行布局与 Scala 一致，Fli 表逐项带 Scala 注释），`out = TABLE[src]` |
| CSA4to2_15 | 逻辑等价但写法与 Scala 的"两级全加器+奇偶交错"对不上 | 按 Scala 逐位重写，头注释写清交错规则 |
| MbistIntfFrontend / MemBlk、SatpFlushMod | 纯连线/快照，正确；头注释一句英文、端口多个一行 | 补头注释（Scala 位置、pipelineNum=1 时 Mux1H 退化、satp 快照用途），端口一行一个 |

UT（两个目录 `verif/ut/Pipeline200c`、`verif/ut/Arithmetic200c`）改动：initreg 三档可选（0 / random / `<seed>017`）；
Pipeline 加暖机（非复位寄存器两侧先写满再比）、运行中随机复位脉冲（复位期间输入照常翻转）、Arbiter16 稀疏 valid、
13 个覆盖计数器（任一为 0 判失败）；Arithmetic 加随机复位脉冲与 5 个覆盖计数器。`FM_MERGE_DUP = false`（加强：比较点 = 寄存器位 + 输出位，模型精确适用）。

### A. 跑前登记（`python3 scripts/fm_predict.py model/register <T>`，merge_dup=false，signoff-strict）

| 目标 | UT | 模型 expected（regs + outs） | 预期 native passing | 预期偏差来源 |
|---|---|---:|---:|---|
| Arbiter16_TLBundleD | Pipeline200c | 94 (0+94) | 94 | — |
| Arbiter3_PfGenReq | Pipeline200c | 72 (0+72) | 72 | — |
| Arbiter4_L2ToL1Hint | Pipeline200c | 40 (0+40) | 40 | — |
| Arbiter4_PrefetchReq | Pipeline200c | 102 (0+102) | 102 | — |
| CSA4to2_15 | Pipeline200c | 32 (0+32) | 32 | out_car[0] 恒 0 仍是输出比较点 |
| MbistIntfFrontend | Pipeline200c | 260 (0+260) | 260 | — |
| MbistIntfMemBlk | Pipeline200c | 328 (0+328) | 328 | — |
| NfMappedElemIdx | Pipeline200c | 128 (0+128) | 128 | out_idxRangeVec_0_from 恒 0 仍是输出比较点 |
| OverrideableQueue | Pipeline200c | 519 (416+103) | 519 | — |
| OverrideableQueue_1 | Pipeline200c | 314 (252+62) | 314 | — |
| PipelineRegModule_6 | Pipeline200c | 147 (73+74) | 147 | — |
| SatpFlushMod | Pipeline200c | 22 (11+11) | 22 | — |
| FastArbiter_27 | Arithmetic200c | 427 (10+417) | 426 | rrGrantMask[0] 恒 0（constant_reg 1）；pendingMask[0] 对称死位走 vmucp（`verif/fm_target_config/FastArbiter_27.tcl`，FastArbiter_2..7/28 先例），开后计入 passing |
| FliDTable / FliHTable / FliSTable | Arithmetic200c | 16 / 16 / 16 | 16 / 16 / 16 | — |
| IntBuffer_1 / IntBuffer_2 | Arithmetic200c | 4 / 4 (2+2) | 4 / 4 | — |
| Rec7Table / Rsqrt7Table | Arithmetic200c | 7 / 7 | 7 / 7 | — |

预期全部 native SUCCEEDED、failing 0、unverified 0、unmatched 0、unread 0（FastArbiter_27 vmucp 后）、无黑盒、无 dont_verify。

### B. 16 个 STALE 重证（`rtl/backend/xs_Pmacfg_core.sv` 改了复位值表达式）

`Pma0cfgModule`..`Pma15cfgModule`（UT `PmaCfgLeaves8` / `PmaCfgLeaves8b`）。核的改动只影响 PMA_INDEX ≥ 19 的复位值，
0..15 的复位值表达式求值仍全 0，行为不变；重证只为让 receipt 的 impl_closure 与当前字节一致。
预测：每个 native passing = 24（8 regs + 16 outs，与旧 receipt 523b6100 的 24 相同；merge_dup 维持该 UT 原设定 true，
fm_predict 判 MODEL_NA，以旧实测为预测），failing/unverified/unread/unmatched 全 0。
两个 UT Makefile 只把运行期 initreg 改成可选（`INITREG ?= 0`，默认行为不变），以便跑 9 档回归。

### Rec7Table / Rsqrt7Table 签完后的下游重证（vectorcvt-tree 的 10 个 receipt）

Estimate7、CVT64_1、VCVT、CVT32、VCVT_1、CVT16、VCVT_2、VectorCvt、VectorCvtTop、VCVT_8 的 UT Makefile 里
这两张表从 RTL_GOLDEN_DEPS 挪进 RTL_SRCS（impl 侧用重写表、ref 侧用 golden 表），先跑 `check_shared_impl_impact`，再逐个重证；
预测 passing 与各自现有 receipt 相同（表在两侧都是纯组合、被吸收进上层锥，不产生新比较点）。

### 接管节：UT 与变异自检（证明之前的读数）

- `make run SEED={1,7,42} INITREG={0,random,<seed>017}`（各 200k 拍，每拍比两次 = checks 400000）：
  Pipeline200c 9/9 errors=0，Arithmetic200c 9/9 errors=0；PmaCfgLeaves8 / 8b 各 9/9 errors=0（checks 1600008）。
- 覆盖计数（seed 1/7/42）：Pipeline 复位脉冲 387~400、复位期间 PipelineReg in.fire 359~411、OQ 满覆盖 ~12.3k、
  OQ 同槽读写 ~5.4k、Arbiter16 第 15 路胜出 ~600、无人请求 ~17.8k；Arithmetic FastArbiter 轮转压过固定优先级 ~26.6k、第 4 路胜出 ~11k。
- 变异 17 个（seed 7、initreg 7017、50k 拍）：16 个首轮即抓到，含原 agent 的 PipelineRegModule_6 / OverrideableQueue 原版
  （复位块里写载荷）；M17（IntBuffer_1 异步复位改同步）首轮漏，原因是 tb 只在 posedge 后比较——加"negedge 输入变化后再比一次"后抓到。
