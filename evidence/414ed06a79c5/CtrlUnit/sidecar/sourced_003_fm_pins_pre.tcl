# CtrlUnit FM「匹配前」钉点 —— 由 scripts/gen_ctrlunit_pins.py 生成，勿手改。
# 只消命名鸿沟：不约束 ref、不放宽 appvar、不扩黑盒、不 dont_verify。
# 对象与依据见生成器文件头。ref  r:/WORK/CtrlUnit/<pipe>/data_<c>_{valid,mask}_reg[b]
#                          impl i:/WORK/CtrlUnit/<pipe>/u_core/data_reg[(7-c)*65 + (valid ? 64 : b)]
# fail-closed：每次 set_user_match 必须返回 1；配对数必须 == 1040。
# 本目录只有 CtrlUnit 一个 FM 目标；防御性地按 $top 限定。
if {$top ne "CtrlUnit"} { error "CU_PREPIN_WRONG_TOP=$top" }
set _cu_n 0
set _cu_fields {
    {data_0_valid 1 519}
    {data_0_mask 64 455}
    {data_1_valid 1 454}
    {data_1_mask 64 390}
    {data_2_valid 1 389}
    {data_2_mask 64 325}
    {data_3_valid 1 324}
    {data_3_mask 64 260}
    {data_4_valid 1 259}
    {data_4_mask 64 195}
    {data_5_valid 1 194}
    {data_5_mask 64 130}
    {data_6_valid 1 129}
    {data_6_mask 64 65}
    {data_7_valid 1 64}
    {data_7_mask 64 0}
}
foreach _cu_pipe {CtrlUnitPseudoErrorPipelineConnect0 CtrlUnitPseudoErrorPipelineConnect1} {
    foreach _cu_f $_cu_fields {
        lassign $_cu_f _cu_name _cu_w _cu_lo
        for {set _cu_b 0} {$_cu_b < $_cu_w} {incr _cu_b} {
            if {$_cu_w == 1} {
                set _cu_r "r:/WORK/CtrlUnit/$_cu_pipe/${_cu_name}_reg"
            } else {
                set _cu_r "r:/WORK/CtrlUnit/$_cu_pipe/${_cu_name}_reg\[$_cu_b\]"
            }
            set _cu_i "i:/WORK/CtrlUnit/$_cu_pipe/u_core/data_reg\[[expr {$_cu_lo + $_cu_b}]\]"
            if {![set_user_match $_cu_r $_cu_i]} {
                puts "CU_PREPIN_FAIL: set_user_match returned 0 for $_cu_r <-> $_cu_i"
                error "CU_PREPIN_MISS=$_cu_r"
            }
            incr _cu_n
        }
    }
}
puts "CU_PREPIN_END n=$_cu_n expect=1040"
if {$_cu_n != 1040} { error "CU_PREPIN_COUNT=$_cu_n" }
