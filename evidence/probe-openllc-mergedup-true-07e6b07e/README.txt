# 本目录是**探针**证据，不是 signoff receipt（没有 run_proof.sh 的 RUN_CONTEXT，不得当证书用）。
# 配置: mode=signoff-strict(默认), FM_MERGE_DUP 未设(=true), impl commit 07e6b07eeb47f77ea2ed4810ae1784294deb2437
# 结论: Verification FAILED, 167323 passing / 20 failing / 7 unverified / 6(0) unmatched
# 失败点全在 io_rn_0_rx_snp_flit[27..46]; 见 failing.rpt 与 unmatched.rpt
# 复跑: (改回 FM_MERGE_DUP=true 并去掉 FM_MODE) make -C verif/ut/OpenLLC fm-OpenLLC
