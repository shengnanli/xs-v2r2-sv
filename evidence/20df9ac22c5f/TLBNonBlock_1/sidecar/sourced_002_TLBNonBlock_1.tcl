# vmucp 白名单条目：TLBNonBlock_1
#
# 本文件 = TLBNonBlock_1 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   TLBNonBlock / TLBNonBlock_1 / TLBNonBlock_2(2026-09-18 加): 未读点两族，两侧同死。
#          (a) 子模块里的对称死位，**两侧是同一份 golden 文件**(DelayN_7/_9 与
#              TlbStorageWrapper_N/TLBFA_N 两侧同源 elaborate，不做黑盒)，
#              所以逐位同构、FM 自己按名字配上：
#                csr_delay/REG{,_1}_priv_debug        (DelayN_7 的 priv.debug 打拍，
#                                                      TLB 本层不读 debug)
#                sfence_delay/REG{,_1}_bits_addr[0:11] + _bits_flushPipe
#                                                     (DelayN_9；TLB 只读 addr[49:12]
#                                                      与 rs1/rs2/hv/hg，低 12 位与
#                                                      flushPipe 无读者)
#                entries/.../reqVpn{,_1}_reg[27..37]  (TLBFA 自己的死位，与 TLBFA
#                                                      那一条同因: genPPN 只取 vpn[26:0])
#          (b) 本层自己的两族，**FM 配不上**(词干不同)，由
#              verif/ut/TLBNonBlock/fm_pins.tcl 按结构 1:1 钉死，钉不上即 exit 3：
#                ref r{,_<n>}_reg            <-> impl u_core/first_issue_r{,2}_reg[n/2]
#                   golden 的匿名 RegNext(debug_isFirstIssue)，每 lane 两个、值恒等，
#                   唯一去处是被 firtool 消掉的 XSPerfAccumulate -> 两侧同为死位。
#                ref result_ok_last_REG_reg  <-> impl u_core/result_ok_last_reg[0]
#                   `_REG_<n>` 与 `[n]` 同号 FM 自己能配，**只有无后缀的 0 号配不上**。
#          ★为什么不能"把这些死寄存器删掉图干净"★：删了它们就从"两侧对称死位"
#          变成 golden-only 死位，连双射都没有 —— 与 TLBFA 那条"不要收窄 reqVpn"、
#          RenameBuffer 那条"不要只留 head"是同一个结论。
#          ★复核判据★(全部实测, 2026-09-18)
#            不加强(vmucp=false, 已钉点前): TLBNonBlock_2 passing 10346 /
#              matched_unread 51 / unmatched unread 3(ref) 3(impl)。
#            加强后(钉点 + vmucp=true): TLBNonBlock_2 passing **10400**(正好 +54
#              = 51 个 matched_nc + 3 个钉上的), failing 0, unread 0, unmatched 六项全零。
#              passing 不增而 unread 归 0 = 点被吞掉, 不算过。
#            另外两个变体同一套配置的终值: TLBNonBlock **13390** / TLBNonBlock_1 **11138**,
#              failing 0 / unread 0 / unmatched 六项全零, 钉点 8 对与 4 对(双射自检通过)。
#            这三个数在跑之前就被预登记过, 模型是
#              passing = golden 闭包的触发器**位数** + 顶层 output 端口**位数**;
#              该模型在 TlbStorageWrapper_1 8682 / TLBFA_1 8663 / TLBFA_2 8233 /
#              TLBFA_3 8229 / DelayN_7 657 / DelayN_9 216 上逐位命中过, 本轮三个也逐位命中。

fm_target_vmucp_allow
