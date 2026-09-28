# PipelineRegModule 家族 FM「匹配前」钉点 —— 自动生成：scripts/gen_pipelinereg.py（勿手改）
#
# 只消名差：golden 是按字段展平的寄存器 io_out_bits_r_<字段>_reg[b]，重写核是一根
# 向量 u_core/bits_q_reg[k]（k = 字段偏移 + b，偏移按 golden 端口表字段顺序、第一个字段在最高位）。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒、不 dont_verify。
# fail-closed：set_user_match 从不抛异常（没配上返回 0），所以逐条数返回值；
# 拒一条、或成功数不等于字面整数（= golden 寄存器位数），就 error（safe interp 里 exit 被隐藏）。
# 进 fm.log 的输出一律 ASCII。
proc prm_pin {r i} {
  if {[set_user_match $r $i]} { incr ::PRM_PIN_OK } else {
    incr ::PRM_PIN_BAD
    if {$::PRM_PIN_BAD <= 10} { puts "PRM_PIN_FAIL: $r <-> $i" }
  }
}
proc prm_field {top f w lsb} {
  if {$w == 1} {
    prm_pin "r:/WORK/$top/io_out_bits_r_${f}_reg" "i:/WORK/$top/u_core/bits_q_reg\[$lsb\]"
  } else {
    for {set b 0} {$b < $w} {incr b} {
      prm_pin "r:/WORK/$top/io_out_bits_r_${f}_reg\[$b\]" "i:/WORK/$top/u_core/bits_q_reg\[[expr {$lsb + $b}]\]"
    }
  }
}

if {$top eq "PipelineRegModule"} {
  set ::PRM_PIN_OK 0
  set ::PRM_PIN_BAD 0
  puts "PRM_PIN_BEGIN PipelineRegModule expect=194"
  prm_pin "r:/WORK/PipelineRegModule/pipeline_reg_valid_reg" "i:/WORK/PipelineRegModule/u_core/valid_q_reg"
  prm_field PipelineRegModule robIdx_flag 1 192
  prm_field PipelineRegModule robIdx_value 8 184
  prm_field PipelineRegModule cmd 5 179
  prm_field PipelineRegModule addr 48 131
  prm_field PipelineRegModule vaddr 50 81
  prm_field PipelineRegModule data 64 17
  prm_field PipelineRegModule mask 8 9
  prm_field PipelineRegModule id 7 2
  prm_field PipelineRegModule nc 1 1
  prm_field PipelineRegModule memBackTypeMM 1 0
  puts "PRM_PIN_END PipelineRegModule ok=$::PRM_PIN_OK bad=$::PRM_PIN_BAD"
  if {$::PRM_PIN_BAD != 0} { error "PRM_PIN_MISS=$::PRM_PIN_BAD" }
  if {$::PRM_PIN_OK != 194} { error "PRM_PIN_COUNT=$::PRM_PIN_OK expect=194" }
}

if {$top eq "PipelineRegModule_1"} {
  set ::PRM_PIN_OK 0
  set ::PRM_PIN_BAD 0
  puts "PRM_PIN_BEGIN PipelineRegModule_1 expect=1429"
  prm_pin "r:/WORK/PipelineRegModule_1/pipeline_reg_valid_reg" "i:/WORK/PipelineRegModule_1/u_core/valid_q_reg"
  prm_field PipelineRegModule_1 uop_instr 32 1396
  prm_field PipelineRegModule_1 uop_pc 50 1346
  prm_field PipelineRegModule_1 uop_foldpc 10 1336
  prm_field PipelineRegModule_1 uop_exceptionVec_0 1 1335
  prm_field PipelineRegModule_1 uop_exceptionVec_1 1 1334
  prm_field PipelineRegModule_1 uop_exceptionVec_2 1 1333
  prm_field PipelineRegModule_1 uop_exceptionVec_3 1 1332
  prm_field PipelineRegModule_1 uop_exceptionVec_4 1 1331
  prm_field PipelineRegModule_1 uop_exceptionVec_5 1 1330
  prm_field PipelineRegModule_1 uop_exceptionVec_6 1 1329
  prm_field PipelineRegModule_1 uop_exceptionVec_7 1 1328
  prm_field PipelineRegModule_1 uop_exceptionVec_8 1 1327
  prm_field PipelineRegModule_1 uop_exceptionVec_9 1 1326
  prm_field PipelineRegModule_1 uop_exceptionVec_10 1 1325
  prm_field PipelineRegModule_1 uop_exceptionVec_11 1 1324
  prm_field PipelineRegModule_1 uop_exceptionVec_12 1 1323
  prm_field PipelineRegModule_1 uop_exceptionVec_13 1 1322
  prm_field PipelineRegModule_1 uop_exceptionVec_14 1 1321
  prm_field PipelineRegModule_1 uop_exceptionVec_15 1 1320
  prm_field PipelineRegModule_1 uop_exceptionVec_16 1 1319
  prm_field PipelineRegModule_1 uop_exceptionVec_17 1 1318
  prm_field PipelineRegModule_1 uop_exceptionVec_18 1 1317
  prm_field PipelineRegModule_1 uop_exceptionVec_19 1 1316
  prm_field PipelineRegModule_1 uop_exceptionVec_20 1 1315
  prm_field PipelineRegModule_1 uop_exceptionVec_21 1 1314
  prm_field PipelineRegModule_1 uop_exceptionVec_22 1 1313
  prm_field PipelineRegModule_1 uop_exceptionVec_23 1 1312
  prm_field PipelineRegModule_1 uop_isFetchMalAddr 1 1311
  prm_field PipelineRegModule_1 uop_hasException 1 1310
  prm_field PipelineRegModule_1 uop_trigger 4 1306
  prm_field PipelineRegModule_1 uop_preDecodeInfo_valid 1 1305
  prm_field PipelineRegModule_1 uop_preDecodeInfo_isRVC 1 1304
  prm_field PipelineRegModule_1 uop_preDecodeInfo_brType 2 1302
  prm_field PipelineRegModule_1 uop_preDecodeInfo_isCall 1 1301
  prm_field PipelineRegModule_1 uop_preDecodeInfo_isRet 1 1300
  prm_field PipelineRegModule_1 uop_pred_taken 1 1299
  prm_field PipelineRegModule_1 uop_crossPageIPFFix 1 1298
  prm_field PipelineRegModule_1 uop_ftqPtr_flag 1 1297
  prm_field PipelineRegModule_1 uop_ftqPtr_value 6 1291
  prm_field PipelineRegModule_1 uop_ftqOffset 4 1287
  prm_field PipelineRegModule_1 uop_satpFlushFirstFetchFault 1 1286
  prm_field PipelineRegModule_1 uop_srcType_0 4 1282
  prm_field PipelineRegModule_1 uop_srcType_1 4 1278
  prm_field PipelineRegModule_1 uop_srcType_2 4 1274
  prm_field PipelineRegModule_1 uop_srcType_3 4 1270
  prm_field PipelineRegModule_1 uop_srcType_4 4 1266
  prm_field PipelineRegModule_1 uop_ldest 6 1260
  prm_field PipelineRegModule_1 uop_fuType 35 1225
  prm_field PipelineRegModule_1 uop_fuOpType 9 1216
  prm_field PipelineRegModule_1 uop_rfWen 1 1215
  prm_field PipelineRegModule_1 uop_fpWen 1 1214
  prm_field PipelineRegModule_1 uop_vecWen 1 1213
  prm_field PipelineRegModule_1 uop_v0Wen 1 1212
  prm_field PipelineRegModule_1 uop_vlWen 1 1211
  prm_field PipelineRegModule_1 uop_isXSTrap 1 1210
  prm_field PipelineRegModule_1 uop_waitForward 1 1209
  prm_field PipelineRegModule_1 uop_blockBackward 1 1208
  prm_field PipelineRegModule_1 uop_flushPipe 1 1207
  prm_field PipelineRegModule_1 uop_canRobCompress 1 1206
  prm_field PipelineRegModule_1 uop_selImm 4 1202
  prm_field PipelineRegModule_1 uop_imm 32 1170
  prm_field PipelineRegModule_1 uop_fpu_typeTagOut 2 1168
  prm_field PipelineRegModule_1 uop_fpu_wflags 1 1167
  prm_field PipelineRegModule_1 uop_fpu_typ 2 1165
  prm_field PipelineRegModule_1 uop_fpu_fmt 2 1163
  prm_field PipelineRegModule_1 uop_fpu_rm 3 1160
  prm_field PipelineRegModule_1 uop_vpu_vill 1 1159
  prm_field PipelineRegModule_1 uop_vpu_vma 1 1158
  prm_field PipelineRegModule_1 uop_vpu_vta 1 1157
  prm_field PipelineRegModule_1 uop_vpu_vsew 2 1155
  prm_field PipelineRegModule_1 uop_vpu_vlmul 3 1152
  prm_field PipelineRegModule_1 uop_vpu_specVill 1 1151
  prm_field PipelineRegModule_1 uop_vpu_specVma 1 1150
  prm_field PipelineRegModule_1 uop_vpu_specVta 1 1149
  prm_field PipelineRegModule_1 uop_vpu_specVsew 2 1147
  prm_field PipelineRegModule_1 uop_vpu_specVlmul 3 1144
  prm_field PipelineRegModule_1 uop_vpu_vm 1 1143
  prm_field PipelineRegModule_1 uop_vpu_vstart 8 1135
  prm_field PipelineRegModule_1 uop_vpu_frm 3 1132
  prm_field PipelineRegModule_1 uop_vpu_fpu_isFpToVecInst 1 1131
  prm_field PipelineRegModule_1 uop_vpu_fpu_isFP32Instr 1 1130
  prm_field PipelineRegModule_1 uop_vpu_fpu_isFP64Instr 1 1129
  prm_field PipelineRegModule_1 uop_vpu_fpu_isReduction 1 1128
  prm_field PipelineRegModule_1 uop_vpu_fpu_isFoldTo1_2 1 1127
  prm_field PipelineRegModule_1 uop_vpu_fpu_isFoldTo1_4 1 1126
  prm_field PipelineRegModule_1 uop_vpu_fpu_isFoldTo1_8 1 1125
  prm_field PipelineRegModule_1 uop_vpu_vxrm 2 1123
  prm_field PipelineRegModule_1 uop_vpu_vuopIdx 7 1116
  prm_field PipelineRegModule_1 uop_vpu_lastUop 1 1115
  prm_field PipelineRegModule_1 uop_vpu_vmask 128 987
  prm_field PipelineRegModule_1 uop_vpu_vl 8 979
  prm_field PipelineRegModule_1 uop_vpu_nf 3 976
  prm_field PipelineRegModule_1 uop_vpu_veew 2 974
  prm_field PipelineRegModule_1 uop_vpu_isReverse 1 973
  prm_field PipelineRegModule_1 uop_vpu_isExt 1 972
  prm_field PipelineRegModule_1 uop_vpu_isNarrow 1 971
  prm_field PipelineRegModule_1 uop_vpu_isDstMask 1 970
  prm_field PipelineRegModule_1 uop_vpu_isOpMask 1 969
  prm_field PipelineRegModule_1 uop_vpu_isMove 1 968
  prm_field PipelineRegModule_1 uop_vpu_isDependOldVd 1 967
  prm_field PipelineRegModule_1 uop_vpu_isWritePartVd 1 966
  prm_field PipelineRegModule_1 uop_vpu_isVleff 1 965
  prm_field PipelineRegModule_1 uop_vlsInstr 1 964
  prm_field PipelineRegModule_1 uop_wfflags 1 963
  prm_field PipelineRegModule_1 uop_isMove 1 962
  prm_field PipelineRegModule_1 uop_isDropAmocasSta 1 961
  prm_field PipelineRegModule_1 uop_uopIdx 7 954
  prm_field PipelineRegModule_1 uop_isVset 1 953
  prm_field PipelineRegModule_1 uop_firstUop 1 952
  prm_field PipelineRegModule_1 uop_lastUop 1 951
  prm_field PipelineRegModule_1 uop_numUops 7 944
  prm_field PipelineRegModule_1 uop_numWB 7 937
  prm_field PipelineRegModule_1 uop_commitType 3 934
  prm_field PipelineRegModule_1 uop_srcState_0 1 933
  prm_field PipelineRegModule_1 uop_srcState_1 1 932
  prm_field PipelineRegModule_1 uop_srcState_2 1 931
  prm_field PipelineRegModule_1 uop_srcState_3 1 930
  prm_field PipelineRegModule_1 uop_srcState_4 1 929
  prm_field PipelineRegModule_1 uop_srcLoadDependency_0_0 2 927
  prm_field PipelineRegModule_1 uop_srcLoadDependency_0_1 2 925
  prm_field PipelineRegModule_1 uop_srcLoadDependency_0_2 2 923
  prm_field PipelineRegModule_1 uop_srcLoadDependency_1_0 2 921
  prm_field PipelineRegModule_1 uop_srcLoadDependency_1_1 2 919
  prm_field PipelineRegModule_1 uop_srcLoadDependency_1_2 2 917
  prm_field PipelineRegModule_1 uop_srcLoadDependency_2_0 2 915
  prm_field PipelineRegModule_1 uop_srcLoadDependency_2_1 2 913
  prm_field PipelineRegModule_1 uop_srcLoadDependency_2_2 2 911
  prm_field PipelineRegModule_1 uop_srcLoadDependency_3_0 2 909
  prm_field PipelineRegModule_1 uop_srcLoadDependency_3_1 2 907
  prm_field PipelineRegModule_1 uop_srcLoadDependency_3_2 2 905
  prm_field PipelineRegModule_1 uop_srcLoadDependency_4_0 2 903
  prm_field PipelineRegModule_1 uop_srcLoadDependency_4_1 2 901
  prm_field PipelineRegModule_1 uop_srcLoadDependency_4_2 2 899
  prm_field PipelineRegModule_1 uop_psrc_0 8 891
  prm_field PipelineRegModule_1 uop_psrc_1 8 883
  prm_field PipelineRegModule_1 uop_psrc_2 8 875
  prm_field PipelineRegModule_1 uop_psrc_3 8 867
  prm_field PipelineRegModule_1 uop_psrc_4 8 859
  prm_field PipelineRegModule_1 uop_pdest 8 851
  prm_field PipelineRegModule_1 uop_useRegCache_0 1 850
  prm_field PipelineRegModule_1 uop_useRegCache_1 1 849
  prm_field PipelineRegModule_1 uop_regCacheIdx_0 5 844
  prm_field PipelineRegModule_1 uop_regCacheIdx_1 5 839
  prm_field PipelineRegModule_1 uop_robIdx_flag 1 838
  prm_field PipelineRegModule_1 uop_robIdx_value 8 830
  prm_field PipelineRegModule_1 uop_instrSize 3 827
  prm_field PipelineRegModule_1 uop_dirtyFs 1 826
  prm_field PipelineRegModule_1 uop_dirtyVs 1 825
  prm_field PipelineRegModule_1 uop_traceBlockInPipe_itype 4 821
  prm_field PipelineRegModule_1 uop_traceBlockInPipe_iretire 4 817
  prm_field PipelineRegModule_1 uop_traceBlockInPipe_ilastsize 1 816
  prm_field PipelineRegModule_1 uop_eliminatedMove 1 815
  prm_field PipelineRegModule_1 uop_snapshot 1 814
  prm_field PipelineRegModule_1 uop_debugInfo_eliminatedMove 1 813
  prm_field PipelineRegModule_1 uop_debugInfo_renameTime 64 749
  prm_field PipelineRegModule_1 uop_debugInfo_dispatchTime 64 685
  prm_field PipelineRegModule_1 uop_debugInfo_enqRsTime 64 621
  prm_field PipelineRegModule_1 uop_debugInfo_selectTime 64 557
  prm_field PipelineRegModule_1 uop_debugInfo_issueTime 64 493
  prm_field PipelineRegModule_1 uop_debugInfo_writebackTime 64 429
  prm_field PipelineRegModule_1 uop_debugInfo_runahead_checkpoint_id 64 365
  prm_field PipelineRegModule_1 uop_debugInfo_tlbFirstReqTime 64 301
  prm_field PipelineRegModule_1 uop_debugInfo_tlbRespTime 64 237
  prm_field PipelineRegModule_1 uop_debug_seqNum_seqNum 56 181
  prm_field PipelineRegModule_1 uop_debug_seqNum_uopIdx 8 173
  prm_field PipelineRegModule_1 uop_storeSetHit 1 172
  prm_field PipelineRegModule_1 uop_waitForRobIdx_flag 1 171
  prm_field PipelineRegModule_1 uop_waitForRobIdx_value 8 163
  prm_field PipelineRegModule_1 uop_loadWaitBit 1 162
  prm_field PipelineRegModule_1 uop_loadWaitStrict 1 161
  prm_field PipelineRegModule_1 uop_ssid 5 156
  prm_field PipelineRegModule_1 uop_lqIdx_flag 1 155
  prm_field PipelineRegModule_1 uop_lqIdx_value 7 148
  prm_field PipelineRegModule_1 uop_sqIdx_flag 1 147
  prm_field PipelineRegModule_1 uop_sqIdx_value 6 141
  prm_field PipelineRegModule_1 uop_singleStep 1 140
  prm_field PipelineRegModule_1 uop_replayInst 1 139
  prm_field PipelineRegModule_1 uop_debug_fuType 35 104
  prm_field PipelineRegModule_1 uop_debug_sim_trig 1 103
  prm_field PipelineRegModule_1 uop_numLsElem 5 98
  prm_field PipelineRegModule_1 debug_paddr 48 50
  prm_field PipelineRegModule_1 debug_vaddr 50 0
  puts "PRM_PIN_END PipelineRegModule_1 ok=$::PRM_PIN_OK bad=$::PRM_PIN_BAD"
  if {$::PRM_PIN_BAD != 0} { error "PRM_PIN_MISS=$::PRM_PIN_BAD" }
  if {$::PRM_PIN_OK != 1429} { error "PRM_PIN_COUNT=$::PRM_PIN_OK expect=1429" }
}

if {$top eq "PipelineRegModule_2"} {
  set ::PRM_PIN_OK 0
  set ::PRM_PIN_BAD 0
  puts "PRM_PIN_BEGIN PipelineRegModule_2 expect=1568"
  prm_pin "r:/WORK/PipelineRegModule_2/pipeline_reg_valid_reg" "i:/WORK/PipelineRegModule_2/u_core/valid_q_reg"
  prm_field PipelineRegModule_2 uop_instr 32 1535
  prm_field PipelineRegModule_2 uop_pc 50 1485
  prm_field PipelineRegModule_2 uop_foldpc 10 1475
  prm_field PipelineRegModule_2 uop_exceptionVec_0 1 1474
  prm_field PipelineRegModule_2 uop_exceptionVec_1 1 1473
  prm_field PipelineRegModule_2 uop_exceptionVec_2 1 1472
  prm_field PipelineRegModule_2 uop_exceptionVec_3 1 1471
  prm_field PipelineRegModule_2 uop_exceptionVec_4 1 1470
  prm_field PipelineRegModule_2 uop_exceptionVec_5 1 1469
  prm_field PipelineRegModule_2 uop_exceptionVec_6 1 1468
  prm_field PipelineRegModule_2 uop_exceptionVec_7 1 1467
  prm_field PipelineRegModule_2 uop_exceptionVec_8 1 1466
  prm_field PipelineRegModule_2 uop_exceptionVec_9 1 1465
  prm_field PipelineRegModule_2 uop_exceptionVec_10 1 1464
  prm_field PipelineRegModule_2 uop_exceptionVec_11 1 1463
  prm_field PipelineRegModule_2 uop_exceptionVec_12 1 1462
  prm_field PipelineRegModule_2 uop_exceptionVec_13 1 1461
  prm_field PipelineRegModule_2 uop_exceptionVec_14 1 1460
  prm_field PipelineRegModule_2 uop_exceptionVec_15 1 1459
  prm_field PipelineRegModule_2 uop_exceptionVec_16 1 1458
  prm_field PipelineRegModule_2 uop_exceptionVec_17 1 1457
  prm_field PipelineRegModule_2 uop_exceptionVec_18 1 1456
  prm_field PipelineRegModule_2 uop_exceptionVec_19 1 1455
  prm_field PipelineRegModule_2 uop_exceptionVec_20 1 1454
  prm_field PipelineRegModule_2 uop_exceptionVec_21 1 1453
  prm_field PipelineRegModule_2 uop_exceptionVec_22 1 1452
  prm_field PipelineRegModule_2 uop_exceptionVec_23 1 1451
  prm_field PipelineRegModule_2 uop_isFetchMalAddr 1 1450
  prm_field PipelineRegModule_2 uop_hasException 1 1449
  prm_field PipelineRegModule_2 uop_trigger 4 1445
  prm_field PipelineRegModule_2 uop_preDecodeInfo_valid 1 1444
  prm_field PipelineRegModule_2 uop_preDecodeInfo_isRVC 1 1443
  prm_field PipelineRegModule_2 uop_preDecodeInfo_brType 2 1441
  prm_field PipelineRegModule_2 uop_preDecodeInfo_isCall 1 1440
  prm_field PipelineRegModule_2 uop_preDecodeInfo_isRet 1 1439
  prm_field PipelineRegModule_2 uop_pred_taken 1 1438
  prm_field PipelineRegModule_2 uop_crossPageIPFFix 1 1437
  prm_field PipelineRegModule_2 uop_ftqPtr_flag 1 1436
  prm_field PipelineRegModule_2 uop_ftqPtr_value 6 1430
  prm_field PipelineRegModule_2 uop_ftqOffset 4 1426
  prm_field PipelineRegModule_2 uop_satpFlushFirstFetchFault 1 1425
  prm_field PipelineRegModule_2 uop_srcType_0 4 1421
  prm_field PipelineRegModule_2 uop_srcType_1 4 1417
  prm_field PipelineRegModule_2 uop_srcType_2 4 1413
  prm_field PipelineRegModule_2 uop_srcType_3 4 1409
  prm_field PipelineRegModule_2 uop_srcType_4 4 1405
  prm_field PipelineRegModule_2 uop_ldest 6 1399
  prm_field PipelineRegModule_2 uop_fuType 35 1364
  prm_field PipelineRegModule_2 uop_fuOpType 9 1355
  prm_field PipelineRegModule_2 uop_rfWen 1 1354
  prm_field PipelineRegModule_2 uop_fpWen 1 1353
  prm_field PipelineRegModule_2 uop_vecWen 1 1352
  prm_field PipelineRegModule_2 uop_v0Wen 1 1351
  prm_field PipelineRegModule_2 uop_vlWen 1 1350
  prm_field PipelineRegModule_2 uop_isXSTrap 1 1349
  prm_field PipelineRegModule_2 uop_waitForward 1 1348
  prm_field PipelineRegModule_2 uop_blockBackward 1 1347
  prm_field PipelineRegModule_2 uop_flushPipe 1 1346
  prm_field PipelineRegModule_2 uop_canRobCompress 1 1345
  prm_field PipelineRegModule_2 uop_selImm 4 1341
  prm_field PipelineRegModule_2 uop_imm 32 1309
  prm_field PipelineRegModule_2 uop_fpu_typeTagOut 2 1307
  prm_field PipelineRegModule_2 uop_fpu_wflags 1 1306
  prm_field PipelineRegModule_2 uop_fpu_typ 2 1304
  prm_field PipelineRegModule_2 uop_fpu_fmt 2 1302
  prm_field PipelineRegModule_2 uop_fpu_rm 3 1299
  prm_field PipelineRegModule_2 uop_vpu_vill 1 1298
  prm_field PipelineRegModule_2 uop_vpu_vma 1 1297
  prm_field PipelineRegModule_2 uop_vpu_vta 1 1296
  prm_field PipelineRegModule_2 uop_vpu_vsew 2 1294
  prm_field PipelineRegModule_2 uop_vpu_vlmul 3 1291
  prm_field PipelineRegModule_2 uop_vpu_specVill 1 1290
  prm_field PipelineRegModule_2 uop_vpu_specVma 1 1289
  prm_field PipelineRegModule_2 uop_vpu_specVta 1 1288
  prm_field PipelineRegModule_2 uop_vpu_specVsew 2 1286
  prm_field PipelineRegModule_2 uop_vpu_specVlmul 3 1283
  prm_field PipelineRegModule_2 uop_vpu_vm 1 1282
  prm_field PipelineRegModule_2 uop_vpu_vstart 8 1274
  prm_field PipelineRegModule_2 uop_vpu_frm 3 1271
  prm_field PipelineRegModule_2 uop_vpu_fpu_isFpToVecInst 1 1270
  prm_field PipelineRegModule_2 uop_vpu_fpu_isFP32Instr 1 1269
  prm_field PipelineRegModule_2 uop_vpu_fpu_isFP64Instr 1 1268
  prm_field PipelineRegModule_2 uop_vpu_fpu_isReduction 1 1267
  prm_field PipelineRegModule_2 uop_vpu_fpu_isFoldTo1_2 1 1266
  prm_field PipelineRegModule_2 uop_vpu_fpu_isFoldTo1_4 1 1265
  prm_field PipelineRegModule_2 uop_vpu_fpu_isFoldTo1_8 1 1264
  prm_field PipelineRegModule_2 uop_vpu_vxrm 2 1262
  prm_field PipelineRegModule_2 uop_vpu_vuopIdx 7 1255
  prm_field PipelineRegModule_2 uop_vpu_lastUop 1 1254
  prm_field PipelineRegModule_2 uop_vpu_vmask 128 1126
  prm_field PipelineRegModule_2 uop_vpu_vl 8 1118
  prm_field PipelineRegModule_2 uop_vpu_nf 3 1115
  prm_field PipelineRegModule_2 uop_vpu_veew 2 1113
  prm_field PipelineRegModule_2 uop_vpu_isReverse 1 1112
  prm_field PipelineRegModule_2 uop_vpu_isExt 1 1111
  prm_field PipelineRegModule_2 uop_vpu_isNarrow 1 1110
  prm_field PipelineRegModule_2 uop_vpu_isDstMask 1 1109
  prm_field PipelineRegModule_2 uop_vpu_isOpMask 1 1108
  prm_field PipelineRegModule_2 uop_vpu_isMove 1 1107
  prm_field PipelineRegModule_2 uop_vpu_isDependOldVd 1 1106
  prm_field PipelineRegModule_2 uop_vpu_isWritePartVd 1 1105
  prm_field PipelineRegModule_2 uop_vpu_isVleff 1 1104
  prm_field PipelineRegModule_2 uop_vlsInstr 1 1103
  prm_field PipelineRegModule_2 uop_wfflags 1 1102
  prm_field PipelineRegModule_2 uop_isMove 1 1101
  prm_field PipelineRegModule_2 uop_isDropAmocasSta 1 1100
  prm_field PipelineRegModule_2 uop_uopIdx 7 1093
  prm_field PipelineRegModule_2 uop_isVset 1 1092
  prm_field PipelineRegModule_2 uop_firstUop 1 1091
  prm_field PipelineRegModule_2 uop_lastUop 1 1090
  prm_field PipelineRegModule_2 uop_numUops 7 1083
  prm_field PipelineRegModule_2 uop_numWB 7 1076
  prm_field PipelineRegModule_2 uop_commitType 3 1073
  prm_field PipelineRegModule_2 uop_srcState_0 1 1072
  prm_field PipelineRegModule_2 uop_srcState_1 1 1071
  prm_field PipelineRegModule_2 uop_srcState_2 1 1070
  prm_field PipelineRegModule_2 uop_srcState_3 1 1069
  prm_field PipelineRegModule_2 uop_srcState_4 1 1068
  prm_field PipelineRegModule_2 uop_srcLoadDependency_0_0 2 1066
  prm_field PipelineRegModule_2 uop_srcLoadDependency_0_1 2 1064
  prm_field PipelineRegModule_2 uop_srcLoadDependency_0_2 2 1062
  prm_field PipelineRegModule_2 uop_srcLoadDependency_1_0 2 1060
  prm_field PipelineRegModule_2 uop_srcLoadDependency_1_1 2 1058
  prm_field PipelineRegModule_2 uop_srcLoadDependency_1_2 2 1056
  prm_field PipelineRegModule_2 uop_srcLoadDependency_2_0 2 1054
  prm_field PipelineRegModule_2 uop_srcLoadDependency_2_1 2 1052
  prm_field PipelineRegModule_2 uop_srcLoadDependency_2_2 2 1050
  prm_field PipelineRegModule_2 uop_srcLoadDependency_3_0 2 1048
  prm_field PipelineRegModule_2 uop_srcLoadDependency_3_1 2 1046
  prm_field PipelineRegModule_2 uop_srcLoadDependency_3_2 2 1044
  prm_field PipelineRegModule_2 uop_srcLoadDependency_4_0 2 1042
  prm_field PipelineRegModule_2 uop_srcLoadDependency_4_1 2 1040
  prm_field PipelineRegModule_2 uop_srcLoadDependency_4_2 2 1038
  prm_field PipelineRegModule_2 uop_psrc_0 8 1030
  prm_field PipelineRegModule_2 uop_psrc_1 8 1022
  prm_field PipelineRegModule_2 uop_psrc_2 8 1014
  prm_field PipelineRegModule_2 uop_psrc_3 8 1006
  prm_field PipelineRegModule_2 uop_psrc_4 8 998
  prm_field PipelineRegModule_2 uop_pdest 8 990
  prm_field PipelineRegModule_2 uop_useRegCache_0 1 989
  prm_field PipelineRegModule_2 uop_useRegCache_1 1 988
  prm_field PipelineRegModule_2 uop_regCacheIdx_0 5 983
  prm_field PipelineRegModule_2 uop_regCacheIdx_1 5 978
  prm_field PipelineRegModule_2 uop_robIdx_flag 1 977
  prm_field PipelineRegModule_2 uop_robIdx_value 8 969
  prm_field PipelineRegModule_2 uop_instrSize 3 966
  prm_field PipelineRegModule_2 uop_dirtyFs 1 965
  prm_field PipelineRegModule_2 uop_dirtyVs 1 964
  prm_field PipelineRegModule_2 uop_traceBlockInPipe_itype 4 960
  prm_field PipelineRegModule_2 uop_traceBlockInPipe_iretire 4 956
  prm_field PipelineRegModule_2 uop_traceBlockInPipe_ilastsize 1 955
  prm_field PipelineRegModule_2 uop_eliminatedMove 1 954
  prm_field PipelineRegModule_2 uop_snapshot 1 953
  prm_field PipelineRegModule_2 uop_debugInfo_eliminatedMove 1 952
  prm_field PipelineRegModule_2 uop_debugInfo_renameTime 64 888
  prm_field PipelineRegModule_2 uop_debugInfo_dispatchTime 64 824
  prm_field PipelineRegModule_2 uop_debugInfo_enqRsTime 64 760
  prm_field PipelineRegModule_2 uop_debugInfo_selectTime 64 696
  prm_field PipelineRegModule_2 uop_debugInfo_issueTime 64 632
  prm_field PipelineRegModule_2 uop_debugInfo_writebackTime 64 568
  prm_field PipelineRegModule_2 uop_debugInfo_runahead_checkpoint_id 64 504
  prm_field PipelineRegModule_2 uop_debugInfo_tlbFirstReqTime 64 440
  prm_field PipelineRegModule_2 uop_debugInfo_tlbRespTime 64 376
  prm_field PipelineRegModule_2 uop_debug_seqNum_seqNum 56 320
  prm_field PipelineRegModule_2 uop_debug_seqNum_uopIdx 8 312
  prm_field PipelineRegModule_2 uop_storeSetHit 1 311
  prm_field PipelineRegModule_2 uop_waitForRobIdx_flag 1 310
  prm_field PipelineRegModule_2 uop_waitForRobIdx_value 8 302
  prm_field PipelineRegModule_2 uop_loadWaitBit 1 301
  prm_field PipelineRegModule_2 uop_loadWaitStrict 1 300
  prm_field PipelineRegModule_2 uop_ssid 5 295
  prm_field PipelineRegModule_2 uop_lqIdx_flag 1 294
  prm_field PipelineRegModule_2 uop_lqIdx_value 7 287
  prm_field PipelineRegModule_2 uop_sqIdx_flag 1 286
  prm_field PipelineRegModule_2 uop_sqIdx_value 6 280
  prm_field PipelineRegModule_2 uop_singleStep 1 279
  prm_field PipelineRegModule_2 uop_replayInst 1 278
  prm_field PipelineRegModule_2 uop_debug_fuType 35 243
  prm_field PipelineRegModule_2 uop_debug_sim_trig 1 242
  prm_field PipelineRegModule_2 uop_numLsElem 5 237
  prm_field PipelineRegModule_2 vaddr 50 187
  prm_field PipelineRegModule_2 paddr 48 139
  prm_field PipelineRegModule_2 data 129 10
  prm_field PipelineRegModule_2 isvec 1 9
  prm_field PipelineRegModule_2 is128bit 1 8
  prm_field PipelineRegModule_2 vecActive 1 7
  prm_field PipelineRegModule_2 schedIndex 7 0
  puts "PRM_PIN_END PipelineRegModule_2 ok=$::PRM_PIN_OK bad=$::PRM_PIN_BAD"
  if {$::PRM_PIN_BAD != 0} { error "PRM_PIN_MISS=$::PRM_PIN_BAD" }
  if {$::PRM_PIN_OK != 1568} { error "PRM_PIN_COUNT=$::PRM_PIN_OK expect=1568" }
}
