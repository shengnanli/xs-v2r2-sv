# MissEntry FM「匹配前」钉点 —— 自动生成：scripts/gen_missq.py（勿手改）
#
# 对象：(a) 值恒等的多份打拍（每个请求口一份 RegNext(primary_fire)/RegNext(id>=2)、
# 四份延迟秒表）—— 签名相同，首跑（lane 内 diagnostic）10(10) unmatched + 下游 7 failing；
# (b) 只喂断言/性能计数的死寄存器（REG_*、r_*、counter*）—— 无扇出、名字不同。
# 配对依据见 scripts/gen_missq.py 的 ME_PINS（逐项写死，不猜名字）。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数不等于字面整数就 error（safe interp 里不用 exit）。
# 进 fm.log 的输出一律 ASCII。
proc _me_pre_pin { } {
    set _expect 229
    set r "r:/WORK/MissEntry"
    set i "i:/WORK/MissEntry/u_core"
    set pairs [list \
        "$r/last_REG_reg"                                  "$i/prefetch_slot_q_reg\[0\]" \
        "$r/io_primary_ready_last_REG_reg"                 "$i/prim_fire_q_slot_reg\[0\]" \
        "$r/io_primary_ready_last_REG_1_reg"               "$i/prim_fire_q_other_reg\[0\]" \
        "$r/last_REG_1_reg"                                "$i/prefetch_slot_q_reg\[1\]" \
        "$r/io_queryME_0_primary_ready_last_REG_reg"       "$i/prim_fire_q_slot_reg\[1\]" \
        "$r/io_queryME_0_primary_ready_last_REG_1_reg"     "$i/prim_fire_q_other_reg\[1\]" \
        "$r/last_REG_2_reg"                                "$i/prefetch_slot_q_reg\[2\]" \
        "$r/io_queryME_1_primary_ready_last_REG_reg"       "$i/prim_fire_q_slot_reg\[2\]" \
        "$r/io_queryME_1_primary_ready_last_REG_1_reg"     "$i/prim_fire_q_other_reg\[2\]" \
        "$r/last_REG_3_reg"                                "$i/prefetch_slot_q_reg\[3\]" \
        "$r/io_queryME_2_primary_ready_last_REG_reg"       "$i/prim_fire_q_slot_reg\[3\]" \
        "$r/io_queryME_2_primary_ready_last_REG_1_reg"     "$i/prim_fire_q_other_reg\[3\]" \
        "$r/last_REG_4_reg"                                "$i/prefetch_slot_q_reg\[4\]" \
        "$r/io_queryME_3_primary_ready_last_REG_reg"       "$i/prim_fire_q_slot_reg\[4\]" \
        "$r/io_queryME_3_primary_ready_last_REG_1_reg"     "$i/prim_fire_q_other_reg\[4\]" \
        "$r/start_counting_last_REG_reg"                   "$i/acq_fire_q_reg" \
        "$r/start_counting_last_REG_1_reg"                 "$i/prim_fire_dly_reg\[0\]" \
        "$r/start_counting_last_REG_2_reg"                 "$i/prim_fire_dly_reg\[1\]" \
        "$r/io_latency_monitor_load_miss_refilling_r_reg"  "$i/lat_watch_q_reg\[0\]" \
        "$r/io_latency_monitor_store_miss_refilling_r_reg" "$i/lat_watch_q_reg\[1\]" \
        "$r/io_latency_monitor_amo_miss_refilling_r_reg"   "$i/lat_watch_q_reg\[2\]" \
        "$r/io_latency_monitor_pf_miss_refilling_r_reg"    "$i/lat_watch_q_reg\[3\]" \
        "$r/REG_reg"                                       "$i/chk_primary_valid_not_ready_reg" \
        "$r/REG_1_reg"                                     "$i/chk_primary_fire_d1_reg" \
        "$r/REG_2_reg"                                     "$i/chk_secondary_fire_d1_reg" \
        "$r/REG_3_reg"                                     "$i/chk_primary_fire_m1_reg" \
        "$r/REG_4_reg"                                     "$i/chk_primary_fire_m2_reg" \
        "$r/REG_5_reg"                                     "$i/chk_ready_onehot_reg" \
        "$r/REG_6_reg"                                     "$i/chk_grant_is_request_reg" \
        "$r/REG_7_reg"                                     "$i/w_grantlast_d1_reg" \
        "$r/r_reg"                                         "$i/perf_load_penalty_watch_reg" \
        "$r/r_3_reg"                                       "$i/perf_grantlast_release_watch_reg" \
        "$r/r_4_reg"                                       "$i/perf_mainpipe_watch_reg" \
        "$r/last_REG_5_reg"                                "$i/perf_prim_fire_dly_reg\[0\]" \
        "$r/last_REG_6_reg"                                "$i/perf_prim_fire_dly_reg\[1\]" \
        "$r/refill_finished_last_REG_reg"                  "$i/perf_refill_finished_d1_reg" \
        "$r/last_REG_7_reg"                                "$i/perf_last_beat_d1_reg" \
        "$r/counter_reg\[0\]"                              "$i/perf_mshr_penalty_reg\[0\]" \
        "$r/counter_reg\[1\]"                              "$i/perf_mshr_penalty_reg\[1\]" \
        "$r/counter_reg\[2\]"                              "$i/perf_mshr_penalty_reg\[2\]" \
        "$r/counter_reg\[3\]"                              "$i/perf_mshr_penalty_reg\[3\]" \
        "$r/counter_reg\[4\]"                              "$i/perf_mshr_penalty_reg\[4\]" \
        "$r/counter_reg\[5\]"                              "$i/perf_mshr_penalty_reg\[5\]" \
        "$r/counter_reg\[6\]"                              "$i/perf_mshr_penalty_reg\[6\]" \
        "$r/counter_reg\[7\]"                              "$i/perf_mshr_penalty_reg\[7\]" \
        "$r/counter_reg\[8\]"                              "$i/perf_mshr_penalty_reg\[8\]" \
        "$r/counter_reg\[9\]"                              "$i/perf_mshr_penalty_reg\[9\]" \
        "$r/counter_reg\[10\]"                             "$i/perf_mshr_penalty_reg\[10\]" \
        "$r/counter_reg\[11\]"                             "$i/perf_mshr_penalty_reg\[11\]" \
        "$r/counter_reg\[12\]"                             "$i/perf_mshr_penalty_reg\[12\]" \
        "$r/counter_reg\[13\]"                             "$i/perf_mshr_penalty_reg\[13\]" \
        "$r/counter_reg\[14\]"                             "$i/perf_mshr_penalty_reg\[14\]" \
        "$r/counter_reg\[15\]"                             "$i/perf_mshr_penalty_reg\[15\]" \
        "$r/counter_reg\[16\]"                             "$i/perf_mshr_penalty_reg\[16\]" \
        "$r/counter_reg\[17\]"                             "$i/perf_mshr_penalty_reg\[17\]" \
        "$r/counter_reg\[18\]"                             "$i/perf_mshr_penalty_reg\[18\]" \
        "$r/counter_reg\[19\]"                             "$i/perf_mshr_penalty_reg\[19\]" \
        "$r/counter_reg\[20\]"                             "$i/perf_mshr_penalty_reg\[20\]" \
        "$r/counter_reg\[21\]"                             "$i/perf_mshr_penalty_reg\[21\]" \
        "$r/counter_reg\[22\]"                             "$i/perf_mshr_penalty_reg\[22\]" \
        "$r/counter_reg\[23\]"                             "$i/perf_mshr_penalty_reg\[23\]" \
        "$r/counter_reg\[24\]"                             "$i/perf_mshr_penalty_reg\[24\]" \
        "$r/counter_reg\[25\]"                             "$i/perf_mshr_penalty_reg\[25\]" \
        "$r/counter_reg\[26\]"                             "$i/perf_mshr_penalty_reg\[26\]" \
        "$r/counter_reg\[27\]"                             "$i/perf_mshr_penalty_reg\[27\]" \
        "$r/counter_reg\[28\]"                             "$i/perf_mshr_penalty_reg\[28\]" \
        "$r/counter_reg\[29\]"                             "$i/perf_mshr_penalty_reg\[29\]" \
        "$r/counter_reg\[30\]"                             "$i/perf_mshr_penalty_reg\[30\]" \
        "$r/counter_reg\[31\]"                             "$i/perf_mshr_penalty_reg\[31\]" \
        "$r/counter_reg\[32\]"                             "$i/perf_mshr_penalty_reg\[32\]" \
        "$r/counter_reg\[33\]"                             "$i/perf_mshr_penalty_reg\[33\]" \
        "$r/counter_reg\[34\]"                             "$i/perf_mshr_penalty_reg\[34\]" \
        "$r/counter_reg\[35\]"                             "$i/perf_mshr_penalty_reg\[35\]" \
        "$r/counter_reg\[36\]"                             "$i/perf_mshr_penalty_reg\[36\]" \
        "$r/counter_reg\[37\]"                             "$i/perf_mshr_penalty_reg\[37\]" \
        "$r/counter_reg\[38\]"                             "$i/perf_mshr_penalty_reg\[38\]" \
        "$r/counter_reg\[39\]"                             "$i/perf_mshr_penalty_reg\[39\]" \
        "$r/counter_reg\[40\]"                             "$i/perf_mshr_penalty_reg\[40\]" \
        "$r/counter_reg\[41\]"                             "$i/perf_mshr_penalty_reg\[41\]" \
        "$r/counter_reg\[42\]"                             "$i/perf_mshr_penalty_reg\[42\]" \
        "$r/counter_reg\[43\]"                             "$i/perf_mshr_penalty_reg\[43\]" \
        "$r/counter_reg\[44\]"                             "$i/perf_mshr_penalty_reg\[44\]" \
        "$r/counter_reg\[45\]"                             "$i/perf_mshr_penalty_reg\[45\]" \
        "$r/counter_reg\[46\]"                             "$i/perf_mshr_penalty_reg\[46\]" \
        "$r/counter_reg\[47\]"                             "$i/perf_mshr_penalty_reg\[47\]" \
        "$r/counter_reg\[48\]"                             "$i/perf_mshr_penalty_reg\[48\]" \
        "$r/counter_reg\[49\]"                             "$i/perf_mshr_penalty_reg\[49\]" \
        "$r/counter_reg\[50\]"                             "$i/perf_mshr_penalty_reg\[50\]" \
        "$r/counter_reg\[51\]"                             "$i/perf_mshr_penalty_reg\[51\]" \
        "$r/counter_reg\[52\]"                             "$i/perf_mshr_penalty_reg\[52\]" \
        "$r/counter_reg\[53\]"                             "$i/perf_mshr_penalty_reg\[53\]" \
        "$r/counter_reg\[54\]"                             "$i/perf_mshr_penalty_reg\[54\]" \
        "$r/counter_reg\[55\]"                             "$i/perf_mshr_penalty_reg\[55\]" \
        "$r/counter_reg\[56\]"                             "$i/perf_mshr_penalty_reg\[56\]" \
        "$r/counter_reg\[57\]"                             "$i/perf_mshr_penalty_reg\[57\]" \
        "$r/counter_reg\[58\]"                             "$i/perf_mshr_penalty_reg\[58\]" \
        "$r/counter_reg\[59\]"                             "$i/perf_mshr_penalty_reg\[59\]" \
        "$r/counter_reg\[60\]"                             "$i/perf_mshr_penalty_reg\[60\]" \
        "$r/counter_reg\[61\]"                             "$i/perf_mshr_penalty_reg\[61\]" \
        "$r/counter_reg\[62\]"                             "$i/perf_mshr_penalty_reg\[62\]" \
        "$r/counter_reg\[63\]"                             "$i/perf_mshr_penalty_reg\[63\]" \
        "$r/counter_1_reg\[0\]"                            "$i/perf_load_miss_penalty_reg\[0\]" \
        "$r/counter_1_reg\[1\]"                            "$i/perf_load_miss_penalty_reg\[1\]" \
        "$r/counter_1_reg\[2\]"                            "$i/perf_load_miss_penalty_reg\[2\]" \
        "$r/counter_1_reg\[3\]"                            "$i/perf_load_miss_penalty_reg\[3\]" \
        "$r/counter_1_reg\[4\]"                            "$i/perf_load_miss_penalty_reg\[4\]" \
        "$r/counter_1_reg\[5\]"                            "$i/perf_load_miss_penalty_reg\[5\]" \
        "$r/counter_1_reg\[6\]"                            "$i/perf_load_miss_penalty_reg\[6\]" \
        "$r/counter_1_reg\[7\]"                            "$i/perf_load_miss_penalty_reg\[7\]" \
        "$r/counter_1_reg\[8\]"                            "$i/perf_load_miss_penalty_reg\[8\]" \
        "$r/counter_1_reg\[9\]"                            "$i/perf_load_miss_penalty_reg\[9\]" \
        "$r/counter_1_reg\[10\]"                           "$i/perf_load_miss_penalty_reg\[10\]" \
        "$r/counter_1_reg\[11\]"                           "$i/perf_load_miss_penalty_reg\[11\]" \
        "$r/counter_1_reg\[12\]"                           "$i/perf_load_miss_penalty_reg\[12\]" \
        "$r/counter_1_reg\[13\]"                           "$i/perf_load_miss_penalty_reg\[13\]" \
        "$r/counter_1_reg\[14\]"                           "$i/perf_load_miss_penalty_reg\[14\]" \
        "$r/counter_1_reg\[15\]"                           "$i/perf_load_miss_penalty_reg\[15\]" \
        "$r/counter_1_reg\[16\]"                           "$i/perf_load_miss_penalty_reg\[16\]" \
        "$r/counter_1_reg\[17\]"                           "$i/perf_load_miss_penalty_reg\[17\]" \
        "$r/counter_1_reg\[18\]"                           "$i/perf_load_miss_penalty_reg\[18\]" \
        "$r/counter_1_reg\[19\]"                           "$i/perf_load_miss_penalty_reg\[19\]" \
        "$r/counter_1_reg\[20\]"                           "$i/perf_load_miss_penalty_reg\[20\]" \
        "$r/counter_1_reg\[21\]"                           "$i/perf_load_miss_penalty_reg\[21\]" \
        "$r/counter_1_reg\[22\]"                           "$i/perf_load_miss_penalty_reg\[22\]" \
        "$r/counter_1_reg\[23\]"                           "$i/perf_load_miss_penalty_reg\[23\]" \
        "$r/counter_1_reg\[24\]"                           "$i/perf_load_miss_penalty_reg\[24\]" \
        "$r/counter_1_reg\[25\]"                           "$i/perf_load_miss_penalty_reg\[25\]" \
        "$r/counter_1_reg\[26\]"                           "$i/perf_load_miss_penalty_reg\[26\]" \
        "$r/counter_1_reg\[27\]"                           "$i/perf_load_miss_penalty_reg\[27\]" \
        "$r/counter_1_reg\[28\]"                           "$i/perf_load_miss_penalty_reg\[28\]" \
        "$r/counter_1_reg\[29\]"                           "$i/perf_load_miss_penalty_reg\[29\]" \
        "$r/counter_1_reg\[30\]"                           "$i/perf_load_miss_penalty_reg\[30\]" \
        "$r/counter_1_reg\[31\]"                           "$i/perf_load_miss_penalty_reg\[31\]" \
        "$r/counter_1_reg\[32\]"                           "$i/perf_load_miss_penalty_reg\[32\]" \
        "$r/counter_1_reg\[33\]"                           "$i/perf_load_miss_penalty_reg\[33\]" \
        "$r/counter_1_reg\[34\]"                           "$i/perf_load_miss_penalty_reg\[34\]" \
        "$r/counter_1_reg\[35\]"                           "$i/perf_load_miss_penalty_reg\[35\]" \
        "$r/counter_1_reg\[36\]"                           "$i/perf_load_miss_penalty_reg\[36\]" \
        "$r/counter_1_reg\[37\]"                           "$i/perf_load_miss_penalty_reg\[37\]" \
        "$r/counter_1_reg\[38\]"                           "$i/perf_load_miss_penalty_reg\[38\]" \
        "$r/counter_1_reg\[39\]"                           "$i/perf_load_miss_penalty_reg\[39\]" \
        "$r/counter_1_reg\[40\]"                           "$i/perf_load_miss_penalty_reg\[40\]" \
        "$r/counter_1_reg\[41\]"                           "$i/perf_load_miss_penalty_reg\[41\]" \
        "$r/counter_1_reg\[42\]"                           "$i/perf_load_miss_penalty_reg\[42\]" \
        "$r/counter_1_reg\[43\]"                           "$i/perf_load_miss_penalty_reg\[43\]" \
        "$r/counter_1_reg\[44\]"                           "$i/perf_load_miss_penalty_reg\[44\]" \
        "$r/counter_1_reg\[45\]"                           "$i/perf_load_miss_penalty_reg\[45\]" \
        "$r/counter_1_reg\[46\]"                           "$i/perf_load_miss_penalty_reg\[46\]" \
        "$r/counter_1_reg\[47\]"                           "$i/perf_load_miss_penalty_reg\[47\]" \
        "$r/counter_1_reg\[48\]"                           "$i/perf_load_miss_penalty_reg\[48\]" \
        "$r/counter_1_reg\[49\]"                           "$i/perf_load_miss_penalty_reg\[49\]" \
        "$r/counter_1_reg\[50\]"                           "$i/perf_load_miss_penalty_reg\[50\]" \
        "$r/counter_1_reg\[51\]"                           "$i/perf_load_miss_penalty_reg\[51\]" \
        "$r/counter_1_reg\[52\]"                           "$i/perf_load_miss_penalty_reg\[52\]" \
        "$r/counter_1_reg\[53\]"                           "$i/perf_load_miss_penalty_reg\[53\]" \
        "$r/counter_1_reg\[54\]"                           "$i/perf_load_miss_penalty_reg\[54\]" \
        "$r/counter_1_reg\[55\]"                           "$i/perf_load_miss_penalty_reg\[55\]" \
        "$r/counter_1_reg\[56\]"                           "$i/perf_load_miss_penalty_reg\[56\]" \
        "$r/counter_1_reg\[57\]"                           "$i/perf_load_miss_penalty_reg\[57\]" \
        "$r/counter_1_reg\[58\]"                           "$i/perf_load_miss_penalty_reg\[58\]" \
        "$r/counter_1_reg\[59\]"                           "$i/perf_load_miss_penalty_reg\[59\]" \
        "$r/counter_1_reg\[60\]"                           "$i/perf_load_miss_penalty_reg\[60\]" \
        "$r/counter_1_reg\[61\]"                           "$i/perf_load_miss_penalty_reg\[61\]" \
        "$r/counter_1_reg\[62\]"                           "$i/perf_load_miss_penalty_reg\[62\]" \
        "$r/counter_1_reg\[63\]"                           "$i/perf_load_miss_penalty_reg\[63\]" \
        "$r/counter_2_reg\[0\]"                            "$i/perf_a_to_d_penalty_reg\[0\]" \
        "$r/counter_2_reg\[1\]"                            "$i/perf_a_to_d_penalty_reg\[1\]" \
        "$r/counter_2_reg\[2\]"                            "$i/perf_a_to_d_penalty_reg\[2\]" \
        "$r/counter_2_reg\[3\]"                            "$i/perf_a_to_d_penalty_reg\[3\]" \
        "$r/counter_2_reg\[4\]"                            "$i/perf_a_to_d_penalty_reg\[4\]" \
        "$r/counter_2_reg\[5\]"                            "$i/perf_a_to_d_penalty_reg\[5\]" \
        "$r/counter_2_reg\[6\]"                            "$i/perf_a_to_d_penalty_reg\[6\]" \
        "$r/counter_2_reg\[7\]"                            "$i/perf_a_to_d_penalty_reg\[7\]" \
        "$r/counter_2_reg\[8\]"                            "$i/perf_a_to_d_penalty_reg\[8\]" \
        "$r/counter_2_reg\[9\]"                            "$i/perf_a_to_d_penalty_reg\[9\]" \
        "$r/counter_2_reg\[10\]"                           "$i/perf_a_to_d_penalty_reg\[10\]" \
        "$r/counter_2_reg\[11\]"                           "$i/perf_a_to_d_penalty_reg\[11\]" \
        "$r/counter_2_reg\[12\]"                           "$i/perf_a_to_d_penalty_reg\[12\]" \
        "$r/counter_2_reg\[13\]"                           "$i/perf_a_to_d_penalty_reg\[13\]" \
        "$r/counter_2_reg\[14\]"                           "$i/perf_a_to_d_penalty_reg\[14\]" \
        "$r/counter_2_reg\[15\]"                           "$i/perf_a_to_d_penalty_reg\[15\]" \
        "$r/counter_2_reg\[16\]"                           "$i/perf_a_to_d_penalty_reg\[16\]" \
        "$r/counter_2_reg\[17\]"                           "$i/perf_a_to_d_penalty_reg\[17\]" \
        "$r/counter_2_reg\[18\]"                           "$i/perf_a_to_d_penalty_reg\[18\]" \
        "$r/counter_2_reg\[19\]"                           "$i/perf_a_to_d_penalty_reg\[19\]" \
        "$r/counter_2_reg\[20\]"                           "$i/perf_a_to_d_penalty_reg\[20\]" \
        "$r/counter_2_reg\[21\]"                           "$i/perf_a_to_d_penalty_reg\[21\]" \
        "$r/counter_2_reg\[22\]"                           "$i/perf_a_to_d_penalty_reg\[22\]" \
        "$r/counter_2_reg\[23\]"                           "$i/perf_a_to_d_penalty_reg\[23\]" \
        "$r/counter_2_reg\[24\]"                           "$i/perf_a_to_d_penalty_reg\[24\]" \
        "$r/counter_2_reg\[25\]"                           "$i/perf_a_to_d_penalty_reg\[25\]" \
        "$r/counter_2_reg\[26\]"                           "$i/perf_a_to_d_penalty_reg\[26\]" \
        "$r/counter_2_reg\[27\]"                           "$i/perf_a_to_d_penalty_reg\[27\]" \
        "$r/counter_2_reg\[28\]"                           "$i/perf_a_to_d_penalty_reg\[28\]" \
        "$r/counter_2_reg\[29\]"                           "$i/perf_a_to_d_penalty_reg\[29\]" \
        "$r/counter_2_reg\[30\]"                           "$i/perf_a_to_d_penalty_reg\[30\]" \
        "$r/counter_2_reg\[31\]"                           "$i/perf_a_to_d_penalty_reg\[31\]" \
        "$r/counter_2_reg\[32\]"                           "$i/perf_a_to_d_penalty_reg\[32\]" \
        "$r/counter_2_reg\[33\]"                           "$i/perf_a_to_d_penalty_reg\[33\]" \
        "$r/counter_2_reg\[34\]"                           "$i/perf_a_to_d_penalty_reg\[34\]" \
        "$r/counter_2_reg\[35\]"                           "$i/perf_a_to_d_penalty_reg\[35\]" \
        "$r/counter_2_reg\[36\]"                           "$i/perf_a_to_d_penalty_reg\[36\]" \
        "$r/counter_2_reg\[37\]"                           "$i/perf_a_to_d_penalty_reg\[37\]" \
        "$r/counter_2_reg\[38\]"                           "$i/perf_a_to_d_penalty_reg\[38\]" \
        "$r/counter_2_reg\[39\]"                           "$i/perf_a_to_d_penalty_reg\[39\]" \
        "$r/counter_2_reg\[40\]"                           "$i/perf_a_to_d_penalty_reg\[40\]" \
        "$r/counter_2_reg\[41\]"                           "$i/perf_a_to_d_penalty_reg\[41\]" \
        "$r/counter_2_reg\[42\]"                           "$i/perf_a_to_d_penalty_reg\[42\]" \
        "$r/counter_2_reg\[43\]"                           "$i/perf_a_to_d_penalty_reg\[43\]" \
        "$r/counter_2_reg\[44\]"                           "$i/perf_a_to_d_penalty_reg\[44\]" \
        "$r/counter_2_reg\[45\]"                           "$i/perf_a_to_d_penalty_reg\[45\]" \
        "$r/counter_2_reg\[46\]"                           "$i/perf_a_to_d_penalty_reg\[46\]" \
        "$r/counter_2_reg\[47\]"                           "$i/perf_a_to_d_penalty_reg\[47\]" \
        "$r/counter_2_reg\[48\]"                           "$i/perf_a_to_d_penalty_reg\[48\]" \
        "$r/counter_2_reg\[49\]"                           "$i/perf_a_to_d_penalty_reg\[49\]" \
        "$r/counter_2_reg\[50\]"                           "$i/perf_a_to_d_penalty_reg\[50\]" \
        "$r/counter_2_reg\[51\]"                           "$i/perf_a_to_d_penalty_reg\[51\]" \
        "$r/counter_2_reg\[52\]"                           "$i/perf_a_to_d_penalty_reg\[52\]" \
        "$r/counter_2_reg\[53\]"                           "$i/perf_a_to_d_penalty_reg\[53\]" \
        "$r/counter_2_reg\[54\]"                           "$i/perf_a_to_d_penalty_reg\[54\]" \
        "$r/counter_2_reg\[55\]"                           "$i/perf_a_to_d_penalty_reg\[55\]" \
        "$r/counter_2_reg\[56\]"                           "$i/perf_a_to_d_penalty_reg\[56\]" \
        "$r/counter_2_reg\[57\]"                           "$i/perf_a_to_d_penalty_reg\[57\]" \
        "$r/counter_2_reg\[58\]"                           "$i/perf_a_to_d_penalty_reg\[58\]" \
        "$r/counter_2_reg\[59\]"                           "$i/perf_a_to_d_penalty_reg\[59\]" \
        "$r/counter_2_reg\[60\]"                           "$i/perf_a_to_d_penalty_reg\[60\]" \
        "$r/counter_2_reg\[61\]"                           "$i/perf_a_to_d_penalty_reg\[61\]" \
        "$r/counter_2_reg\[62\]"                           "$i/perf_a_to_d_penalty_reg\[62\]" \
        "$r/counter_2_reg\[63\]"                           "$i/perf_a_to_d_penalty_reg\[63\]" ]
    puts "ME_PREPIN_BEGIN MissEntry expect=$_expect"
    set n 0
    foreach {rp ip} $pairs {
        if {![set_user_match $rp $ip]} {
            puts "ME_PREPIN_FAIL: set_user_match returned 0 for $rp <-> $ip"
            error "ME_PREPIN_MISS=$rp"
        }
        incr n
    }
    puts "ME_PREPIN_END MissEntry n=$n expect=$_expect"
    if {$n != $_expect} {
        puts "ME_PREPIN_ERROR: pinned $n but expected $_expect"
        error "ME_PREPIN_COUNT=$n"
    }
}
_me_pre_pin
