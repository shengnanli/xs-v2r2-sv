# 有序分类器 vs 旧台账（migration_plan.tsv）对账

旧台账的 mode 与本分类器的 bucket 不是同一套词表；下表按「施工方案是否改变」列出差异。

- 台账行 199，其中施工方案**改变** 67，未变 132


## 分类改变的 target

| target | 旧台账 mode | 新 bucket | 依据 |
|---|---|---|---|
| `DivUnit` | E_LOGIC_S | **A2_IFACE_ONLY** | 全部 27 ADD / 0 DEL 行逐行归因通过：定义名只在本侧存在或属新增/删除端口 |
| `FDivSqrt` | E_LOGIC_S | **A2_IFACE_ONLY** | 全部 27 ADD / 0 DEL 行逐行归因通过：定义名只在本侧存在或属新增/删除端口 |
| `InstrUncache` | E_LOGIC_S | **A2_IFACE_ONLY** | 全部 5 ADD / 0 DEL 行逐行归因通过：定义名只在本侧存在或属新增/删除端口 |
| `NewPipelineConnectPipe_20` | E_LOGIC_S | **A2_IFACE_ONLY** | 全部 42 ADD / 0 DEL 行逐行归因通过：定义名只在本侧存在或属新增/删除端口 |
| `NewPipelineConnectPipe_27` | F_MORPH_S | **A2_IFACE_ONLY** | 全部 105 ADD / 0 DEL 行逐行归因通过：定义名只在本侧存在或属新增/删除端口 |
| `NewPipelineConnectPipe_33` | F_MORPH_S | **A2_IFACE_ONLY** | 全部 390 ADD / 0 DEL 行逐行归因通过：定义名只在本侧存在或属新增/删除端口 |
| `SRAMTemplate_185` | G_NEWFORM | **A2_IFACE_ONLY** | 全部 1 ADD / 0 DEL 行逐行归因通过：定义名只在本侧存在或属新增/删除端口 |
| `StorePfWrapper` | F_MORPH_S | **A2_IFACE_ONLY** | 全部 0 ADD / 3 DEL 行逐行归因通过：定义名只在本侧存在或属新增/删除端口 |
| `TLBuffer_15` | E_LOGIC_M | **A2_IFACE_ONLY** | 全部 4 ADD / 0 DEL 行逐行归因通过：定义名只在本侧存在或属新增/删除端口 |
| `SRAMTemplate_146` | G_NEWFORM | **A_BODY_IDENTICAL** | 安全归一化后模块体逐字相同，且 width_chg==0 && dir_chg==0 |
| `SRAMTemplate_152` | B2_HANDSHAKE_PARTIAL | **A_BODY_IDENTICAL** | 安全归一化后模块体逐字相同，且 width_chg==0 && dir_chg==0 |
| `DataPath` | U_INDETERMINATE | **B_HANDSHAKE** | 新增 12 个 ready 端口（G0 原有 37 个 => EXTENDED_HANDSHAKE）；归因有 1196 行不可归因 => B+E |
| `Scheduler_3` | U_INDETERMINATE | **B_HANDSHAKE** | 新增 7 个 ready 端口（G0 原有 16 个 => EXTENDED_HANDSHAKE）；归因有 628 行不可归因 => B+E |
| `WbDataPath` | U_INDETERMINATE | **B_HANDSHAKE** | 新增 9 个 ready 端口（G0 原有 4 个 => EXTENDED_HANDSHAKE）；归因有 802 行不可归因 => B+E |
| `FastArbiter_27` | B2_HANDSHAKE_PARTIAL | **E_F_RESIDUAL** | 兜底档：E_LOGIC_S，抹掉临时线编号后残余 diff 5 行（raw 5 行；差额=firtool 临时名重新发号） |
| `GrantBuffer` | A2_IFACE_DEEP | **E_F_RESIDUAL** | 兜底档：F_MORPH_S，抹掉临时线编号后残余 diff 1 行（raw 1 行；差额=firtool 临时名重新发号） |
| `TlbStorageWrapper` | A2_IFACE_DEEP | **E_F_RESIDUAL** | 兜底档：F_MORPH_S，抹掉临时线编号后残余 diff 1 行（raw 1 行；差额=firtool 临时名重新发号） |
| `TlbStorageWrapper_1` | A2_IFACE_DEEP | **E_F_RESIDUAL** | 兜底档：F_MORPH_S，抹掉临时线编号后残余 diff 1 行（raw 1 行；差额=firtool 临时名重新发号） |
| `AXI4Xbar_1` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、4 个端口位宽变化 (auto_out_1_ar_bits_addr:[28:0]->[29:0];auto_out_1_aw_bits_addr:[28:0]->[29:0];auto_out_2_ar_bits_addr:[30:0]->[28:0];auto_out_2_aw_bits_addr:[30:0]->[28:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `Backend` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、1 个端口位宽变化 (io_fromTop_msiInfo_bits:[10:0]->[11:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `Composer` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、8 个端口位宽变化 (boreChildrenBd_bore_2_addr:[8:0]->[7:0];boreChildrenBd_bore_2_addr_rd:[8:0]->[7:0];boreChildrenBd_bore_3_addr:[8:0]->[7:0];boreChildrenBd_bore_3_addr_rd:[8:0]->[7:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_L |
| `DCache` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (auto_cacheCtrlOpt_in_a_bits_source:[1:0]->[3:0];auto_cacheCtrlOpt_in_d_bits_source:[1:0]->[3:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `DCacheWrapper` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (auto_uncache_in_a_bits_source:[1:0]->[3:0];auto_uncache_in_d_bits_source:[1:0]->[3:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `DelayReg` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、18 个端口位宽变化 (i_otherwpdest_0:[7:0]->[8:0];i_otherwpdest_1:[7:0]->[8:0];i_otherwpdest_2:[7:0]->[8:0];i_otherwpdest_3:[7:0]->[8:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `ExuBlock` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、1 个端口位宽变化 (io_csrin_msiInfo_bits:[10:0]->[11:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `Frontend` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (auto_inner_icache_ctrlUnitOpt_in_a_bits_source:[2:0]->[4:0];auto_inner_icache_ctrlUnitOpt_in_d_bits_source:[2:0]->[4:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `HPTW` | B2_HANDSHAKE_PARTIAL | **F_PORTWIDTH** | 方向不变、1 个端口位宽变化 (io_resp_bits_id:[2:0]->[3:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `ICache` | F_MORPH_S | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (auto_ctrlUnitOpt_in_a_bits_source:[2:0]->[4:0];auto_ctrlUnitOpt_in_d_bits_source:[2:0]->[4:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `ICacheCtrlUnit` | D_DEPRENUM | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (auto_in_a_bits_source:[2:0]->[4:0];auto_in_d_bits_source:[2:0]->[4:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `IMSIC` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (msiio_data:[10:0]->[11:0];toCSR_pendings:[6:0]->[8:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `IMSICGateWay` | F_MORPH_S | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (msi_valid_o:[6:0]->[8:0];msiio_data:[10:0]->[11:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `L2DataStorage` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、11 个端口位宽变化 (mbist_array:[4:0]->[3:0];mbist_indata:[68:0]->[136:0];mbist_outdata:[68:0]->[136:0];toSRAM_0_rdata:[68:0]->[136:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `L2Slice` | F_MORPH_S | **F_PORTWIDTH** | 方向不变、6 个端口位宽变化 (mbist_array:[4:0]->[3:0];mbist_indata:[103:0]->[136:0];mbist_outdata:[103:0]->[136:0];toNextPipeline_1_array:[4:0]->[3:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `L2TLB` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、11 个端口位宽变化 (auto_out_a_bits_source:[2:0]->[3:0];auto_out_d_bits_source:[2:0]->[3:0];boreChildrenBd_bore_1_addr:[5:0]->[2:0];boreChildrenBd_bore_1_addr_rd:[5:0]->[2:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `L2TLBWrapper` | F_MORPH_S | **F_PORTWIDTH** | 方向不变、11 个端口位宽变化 (auto_out_a_bits_source:[2:0]->[3:0];auto_out_d_bits_source:[2:0]->[3:0];boreChildrenBd_bore_1_addr:[5:0]->[2:0];boreChildrenBd_bore_1_addr_rd:[5:0]->[2:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `L2Top` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、8 个端口位宽变化 (auto_inner_buffers_in_a_bits_source:[1:0]->[3:0];auto_inner_buffers_in_d_bits_source:[1:0]->[3:0];auto_inner_buffers_out_a_bits_source:[2:0]->[4:0];auto_inner_buffers_out_d_bits_source:[2:0]->[4:0])；位宽记号归 |
| `LLPTW` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (io_mem_req_bits_id:[2:0]->[3:0];io_out_bits_id:[2:0]->[3:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `LoadQueue` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、4 个端口位宽变化 (io_uncache_idResp_bits_sid:[1:0]->[3:0];io_uncache_resp_bits_id:[1:0]->[3:0];io_vecFeedback_0_bits_gpaddr:[49:0]->[63:0];io_vecFeedback_1_bits_gpaddr:[49:0]->[63:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LO |
| `LoadQueueUncache` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (io_uncache_idResp_bits_sid:[1:0]->[3:0];io_uncache_resp_bits_id:[1:0]->[3:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `LsqWrapper` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、6 个端口位宽变化 (io_ldvecFeedback_0_bits_gpaddr:[49:0]->[63:0];io_ldvecFeedback_1_bits_gpaddr:[49:0]->[63:0];io_stvecFeedback_0_bits_gpaddr:[49:0]->[63:0];io_stvecFeedback_1_bits_gpaddr:[49:0]->[63:0])；位宽记号归一后模块体仍有残余 diff |
| `MemBlock` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、10 个端口位宽变化 (auto_inner_buffers_out_a_bits_source:[1:0]->[3:0];auto_inner_buffers_out_d_bits_source:[1:0]->[3:0];auto_inner_frontendBridge_icachectrl_in_a_bits_source:[2:0]->[4:0];auto_inner_frontendBridge_icachectrl |
| `NewCSR` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、1 个端口位宽变化 (fromAIA_vseip:[4:0]->[6:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `Predictor` | F_MORPH_S | **F_PORTWIDTH** | 方向不变、8 个端口位宽变化 (boreChildrenBd_bore_2_addr:[8:0]->[7:0];boreChildrenBd_bore_2_addr_rd:[8:0]->[7:0];boreChildrenBd_bore_3_addr:[8:0]->[7:0];boreChildrenBd_bore_3_addr_rd:[8:0]->[7:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_L |
| `PtwCache` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、10 个端口位宽变化 (boreChildrenBd_bore_1_addr:[5:0]->[6:0];boreChildrenBd_bore_1_addr_rd:[5:0]->[6:0];boreChildrenBd_bore_1_array:[5:0]->[6:0];boreChildrenBd_bore_1_indata:[227:0]->[113:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_P |
| `Queue1_RegMapperInput_3` | F_MORPH_S | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (io_deq_bits_extra_tlrr_extra_source:[2:0]->[4:0];io_enq_bits_extra_tlrr_extra_source:[2:0]->[4:0])；位宽记号归一后模块体相同 => PURE_REPARAM |
| `SCTable` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (boreChildrenBd_bore_addr:[8:0]->[7:0];boreChildrenBd_bore_addr_rd:[8:0]->[7:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `SCTable_1` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (boreChildrenBd_bore_addr:[8:0]->[7:0];boreChildrenBd_bore_addr_rd:[8:0]->[7:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `SCTable_2` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (boreChildrenBd_bore_addr:[8:0]->[7:0];boreChildrenBd_bore_addr_rd:[8:0]->[7:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `SCTable_3` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (boreChildrenBd_bore_addr:[8:0]->[7:0];boreChildrenBd_bore_addr_rd:[8:0]->[7:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `SRAMTemplate_128` | G_NEWFORM | **F_PORTWIDTH** | 方向不变、12 个端口位宽变化 (boreChildrenBd_bore_addr:[5:0]->[2:0];boreChildrenBd_bore_addr_rd:[5:0]->[2:0];boreChildrenBd_bore_rdata:[227:0]->[130:0];boreChildrenBd_bore_selectedOH:[0:0]->[5:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_ |
| `SRAMTemplate_145` | G_NEWFORM | **F_PORTWIDTH** | 方向不变、1 个端口位宽变化 (boreChildrenBd_bore_array:[5:0]->[6:0])；位宽记号归一后模块体相同 => PURE_REPARAM |
| `SRAMTemplate_155` | G_NEWFORM | **F_PORTWIDTH** | 方向不变、4 个端口位宽变化 (boreChildrenBd_bore_rdata:[68:0]->[136:0];boreChildrenBd_bore_wdata:[68:0]->[136:0];io_r_resp_data_0:[68:0]->[136:0];io_w_req_bits_data_0:[68:0]->[136:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `SRAMTemplate_178` | G_NEWFORM | **F_PORTWIDTH** | 方向不变、4 个端口位宽变化 (boreChildrenBd_bore_rdata:[68:0]->[136:0];boreChildrenBd_bore_wdata:[68:0]->[136:0];io_r_resp_data_0:[68:0]->[136:0];io_w_req_bits_data_0:[68:0]->[136:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `Slice` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、3 个端口位宽变化 (boreChildrenBd_bore_array:[4:0]->[3:0];boreChildrenBd_bore_indata:[103:0]->[136:0];boreChildrenBd_bore_outdata:[103:0]->[136:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `StoreQueue` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (io_vecFeedback_0_bits_gpaddr:[49:0]->[63:0];io_vecFeedback_1_bits_gpaddr:[49:0]->[63:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `TL2CHICoupledL2` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、2 个端口位宽变化 (auto_mmioBridge_mmio_in_a_bits_source:[2:0]->[4:0];auto_mmioBridge_mmio_in_d_bits_source:[2:0]->[4:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `TLXbar_4` | F_MORPH_S | **F_PORTWIDTH** | 方向不变、6 个端口位宽变化 (auto_in_a_bits_source:[1:0]->[3:0];auto_in_d_bits_source:[1:0]->[3:0];auto_out_0_a_bits_source:[1:0]->[3:0];auto_out_0_d_bits_source:[1:0]->[3:0])；位宽记号归一后模块体相同 => PURE_REPARAM |
| `TLXbar_6` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、8 个端口位宽变化 (auto_in_1_a_bits_source:[1:0]->[3:0];auto_in_1_d_bits_source:[1:0]->[3:0];auto_out_0_a_bits_source:[2:0]->[4:0];auto_out_0_d_bits_source:[2:0]->[4:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `TageBTable` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、6 个端口位宽变化 (boreChildrenBd_bore_1_rdata:[15:0]->[7:0];boreChildrenBd_bore_1_wdata:[15:0]->[7:0];boreChildrenBd_bore_1_wmask:[7:0]->[3:0];boreChildrenBd_bore_rdata:[15:0]->[7:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LO |
| `Tage_SC` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、8 个端口位宽变化 (boreChildrenBd_bore_1_addr:[8:0]->[7:0];boreChildrenBd_bore_1_addr_rd:[8:0]->[7:0];boreChildrenBd_bore_2_addr:[8:0]->[7:0];boreChildrenBd_bore_2_addr_rd:[8:0]->[7:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_L |
| `Uncache` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、4 个端口位宽变化 (auto_client_out_a_bits_source:[1:0]->[3:0];auto_client_out_d_bits_source:[1:0]->[3:0];io_lsq_idResp_bits_sid:[1:0]->[3:0];io_lsq_resp_bits_id:[1:0]->[3:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `XSCore` | U_INDETERMINATE | **F_PORTWIDTH** | 方向不变、7 个端口位宽变化 (auto_memBlock_inner_buffers_out_a_bits_source:[1:0]->[3:0];auto_memBlock_inner_buffers_out_d_bits_source:[1:0]->[3:0];auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source:[2:0]->[4:0];auto_memBl |
| `XSTile` | F_MORPH_M | **F_PORTWIDTH** | 方向不变、1 个端口位宽变化 (io_msiInfo_bits:[10:0]->[11:0])；位宽记号归一后模块体仍有残余 diff => REPARAM_PLUS_LOGIC |
| `StorePipe` | I_IDENTICAL | **P_SHIM** | G1 模块体只剩纯 io->io 直通，无例化、无 always |
| `FastArbiter_31` | C_RENUMBER | **X_RETIRED** | G0 有该名字而 G1 没有 => 该名字下无 RTL 可交付；后继=FastArbiter_30（判据 site） |
| `FastArbiter_36` | C_RENUMBER | **X_RETIRED** | G0 有该名字而 G1 没有 => 该名字下无 RTL 可交付；后继=FastArbiter_35（判据 site） |
| `NewPipelineConnectPipe_31` | C_RENUMBER | **X_RETIRED** | G0 有该名字而 G1 没有 => 该名字下无 RTL 可交付；后继=NewPipelineConnectPipe_33（判据 site） |

## g1_name 映射与台账不一致的 target（例化点身份 vs 同名假设）

| target | 台账 g1_name | 身份判据 g1_name | 判据 |
|---|---|---|---|
| `FastArbiter_30` | FastArbiter_30 | **FastArbiter_29** | site |
| `SRAMTemplate_152` | SRAMTemplate_152 | **SRAMTemplate_162** | body_exact |
| `NewPipelineConnectPipe_27` | NewPipelineConnectPipe_27 | **NewPipelineConnectPipe_29** | site |
| `NewPipelineConnectPipe_33` | NewPipelineConnectPipe_33 | **NewPipelineConnectPipe_35** | site |
| `AXI4Xbar_1` | AXI4Xbar_1 | **AXI4Xbar_6** | site |
| `Queue1_RegMapperInput_3` | Queue1_RegMapperInput_3 | **Queue1_RegMapperInput_5** | site |
| `FastArbiter_27` | FastArbiter_27 | **FastArbiter_26** | site |
| `FastArbiter_46` | FastArbiter_46 | **FastArbiter_45** | site |
| `L1FlagMetaArray` | L1FlagMetaArray | **L1ErrorMetaArray** | site |
