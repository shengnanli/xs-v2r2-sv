# vmucp 白名单条目：Composer
#
# 本文件 = Composer 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   Composer 加入依据(2026-09-14, agent/composer)：本目标是本轮最大的目标。
#          不加强的 strict 基线(evidence/6a791d008f45/Composer_prepin)：
#          native SUCCEEDED / passing 519962 / failing 0 / unverified 0 /
#          aborted 0 / unmatched compare points 0 / 无黑盒 / 无 qualification
#          (dont_verify_objects、elab147、relaxed_appvars 三项皆空)，
#          只剩 unread 卡住 —— 共 6323 点 = 5923 matched_nc + 400(400)
#          unmatched unread。两类成因如下，全部是两侧同为死位：
#          (a) 5722 点：ref 与 impl 的**层次路径逐字相同**。Composer 的 5 个
#              预测器子模块(FTB/FauFTB/Tage_SC/RAS/ITTage)与 4 个 DelayN 都不是
#              本目标，按规范两侧同源用 golden(见该 UT Makefile 的
#              RTL_GOLDEN_DEPS)——ref 与 impl 读 G1-canonical 下**同一份文件**、
#              同一实例名，wrapper 也直接例化 golden 模块名，所以这批点的对称性
#              是按构造成立的，不是人工配出来的。死因分四类：
#                · 48 点 array_N_ext/reg_RW0_ren —— 厂商 SRAM 宏里只在
#                  RANDOMIZE_GARBAGE_ASSIGN 分支被读的寄存器,综合视图走 else;
#                · 103 点 MbistPipe* 的 addrReg/addrRdReg —— MBIST 写地址整条
#                  在本层无读者、读地址最高位超出宏深度(与 ITTageTable /
#                  ICacheMetaArray 已签核目标同一形态);
#                · 5556 点预测器内部宽值打拍寄存器的零扇出切片 —— 折叠历史
#                  update_ghist_r 2660 / 各预测器自己的 SegmentedAddrNext 影子
#                  PC 1684 / update_pc_r 等 483 / meta 打拍 433 / 索引打拍 230 /
#                  其它 66。共性是 firtool 把整条宽值打了一拍而下游只取其中若干位;
#                · 15 点 DelayN 的 REG_*_enable —— 每个 DelayN 只用得到 ctrl
#                  里自己那一路开关,其余路打了拍没人读。
#          (b) 601 点：Composer **本层自己**的影子 PC 流水，两侧路径不同。
#              modified_reset 1 + s1_pc 4x50 + s2_pc 4x50 + s3_pc 4x50。
#              死因：整条 cone-dead —— s3 段寄存器拼出的地址无消费者(真正送出的
#              io_out_s1_pc 由链头 uftb 驱动、io_out_s2/s3_pc 由链尾 ras 驱动)，
#              往回推 s2 段唯一读者是 s3 段、s1_pc 唯一读者是 s2 段、
#              modified_reset 唯一读者是 s1_pc，整条零扇出(自反馈不算被读)。
#              配不上的原因是命名：golden 是 firtool 展平名
#              s2_pc_dup_s2_pc_seg_0_value_1_reg[b]，可读核是二维数组
#              u_core/s2_pc_hi_reg[1][b]，词干与维度都对不上。
#              verif/ut/Composer/fm_pins_pre.tcl 在首次 match 之前按段布局
#              (seg_0=pc[49:24] 26 位 <-> hi、seg_1=pc[23:12] 12 位 <-> mid、
#              seg_2=pc[11:0] 12 位 <-> lo；dup 后缀无/_1/_2/_3 <-> 0/1/2/3；
#              位下标同号)逐位钉满 601 对，对应关系由结构唯一确定、无自由度。
#              钉不上任何一条即 error 退出(fail-closed)。
#              ★这里有个实测才暴露的坑★：基线里只有 s2/s3 那 400 点是
#              unmatched，s1_pc 的 200 点与 modified_reset 是 FM 自己配上的
#              matched unread；而一旦打开本加强(未读点升级成比对点)，s1_pc
#              那 200 点的配对**会掉**，变成新的 200(200) unmatched unread ——
#              只钉 400 的那一版实测 compare points 526085、判定仍 PARTIAL。
#              所以属于这条影子流水的点必须整条钉，不能只钉"当前报出来没配上的"。
#          钉点集合与实测未读点集合**精确相等**由脚本核对，不是眼看的：
#              tools/predictor_composer/check_pin_bijection.py <基线 unread_points.txt>
#          它同时核对 FM 自己已有的 201 对非同路径配对与生成配对逐对一致
#          (多钉会抢走已配好的点、漏钉会继续拦着 strict，只查"每条都钉上了"
#          抓不到这两种错)。
#          打开本项后必须复验「passing 恰好 +6323(519962 -> 526285)、failing
#          仍为 0、unread 归 0」—— passing 不增即 FM 没真去比，那是空转，不算过。

fm_target_vmucp_allow
