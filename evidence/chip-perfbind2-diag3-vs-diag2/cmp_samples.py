import sys
def load(p):
    L=open(p).read().split('\n'); names=L[0][2:].split(); rows={}
    for l in L[1:]:
        if not l.strip(): continue
        p=l.split(); rows[int(p[0])]=dict(zip(names,p[1:]))
    return names,rows
na,A=load(sys.argv[1]); nb,B=load(sys.argv[2])
common=[n for n in na if n in nb]
def vec(r,pat,n): return ''.join(r.get(pat%i,'?')[-1] for i in range(n-1,-1,-1))
def fmt(r): return f"rst={r.get('reset')} rin={vec(r,'io_renameIn_%d_valid',6)} v={vec(r,'io_fromRename_%d_valid',6)} r={vec(r,'io_fromRename_%d_ready',6)} af={r.get('io_toRenameAllFire')} rob={vec(r,'io_enqRob_req_%d_valid',6)} robacc={r.get('io_enqRob_canAccept')} lsq={r.get('_lsqEnqCtrl_io_enq_canAccept')} lsqv={vec(r,'io_toMem_lsqEnqIO_req_%d_valid',6)} iqv#={vec(r,'io_toIssueQueues_%d_valid',34).count('1')} iqr={''.join(r.get('io_toIssueQueues_%d_ready'%i,'?')[-1] for i in range(32,-1,-2))} redir={r.get('io_redirect_valid')}"
key=['reset','io_toRenameAllFire','io_enqRob_canAccept','io_enqRob_isEmpty','_lsqEnqCtrl_io_enq_canAccept','io_redirect_valid']+[f'io_fromRename_{i}_{k}' for i in range(6) for k in ('valid','ready')]+[f'io_enqRob_req_{i}_valid' for i in range(6)]+[f'io_toMem_lsqEnqIO_req_{i}_valid' for i in range(6)]+[f'io_toIssueQueues_{i}_{k}' for i in range(34) for k in ('valid','ready')]
key=[k for k in key if k in common]
rst_off=next((c for c in sorted(A) if A[c].get('reset')=='0'),None)
print(f"采样 {len(A)}/{len(B)} 拍; reset 释放于拍 {rst_off}; 公共信号 {len(common)}")
fv=next((c for c in sorted(B) if '1' in vec(B[c],'io_fromRename_%d_valid',6)),None); print("golden 第一次 fromRename valid: 拍",fv)
fx=next((c for c in sorted(A) if any(ch in 'xXzZ' for k in key for ch in A[c][k])),None); print("重写侧握手信号首次含 X/Z: 拍",fx, [k for k in key if fx is not None and any(ch in 'xXzZ' for ch in A[fx][k])][:8])
div=next((c for c in sorted(A) if c in B and any(A[c][k]!=B[c][k] for k in key)),None)
print("第一次分叉: 拍",div, [k for k in key if div is not None and A[div][k]!=B[div][k]][:10])
def show(c0,lo,hi):
    for c in range(max(0,c0-lo),min(len(A),len(B),c0+hi)): print(f"拍{c:5d} 重写: {fmt(A[c])}"); print(f"      golden: {fmt(B[c])}")
if div is not None: show(div,2,8)
if fv is not None and (div is None or abs(fv-div)>12): print("--- golden 第一次有效附近"); show(fv,1,6)
r=A[div if div is not None else (fv or 0)]
print("重写侧内部(分叉拍):", {k:r.get(k) for k in ('core_fromRenameReady','core_firedVec','core_uopBlockByIQ','core_allowDispatch','core_thisCanActualOut','core_uopSelIQ','core_iqReady','_lsqEnqCtrl_io_lqFreeCount','_lsqEnqCtrl_io_sqFreeCount')})
g=B[div if div is not None else (fv or 0)]
print("golden 侧内部(同拍):", {k:g.get(k) for k in ('allowDispatch_0','allowDispatch_2','thisCanActualOut_2','uopBlockByIQ_2','conserveFlowTotal_2','_lsqEnqCtrl_io_lqFreeCount','_lsqEnqCtrl_io_sqFreeCount')})
# 从分叉起：重写侧 ready 恒 0 持续多少拍？
if div is not None:
    zero=sum(1 for c in range(div,len(A)) if vec(A[c],'io_fromRename_%d_ready',6)=='000000'); print(f"分叉后重写侧 ready 全 0 的拍数: {zero}/{len(A)-div}; golden 同区间 fire 拍数: {sum(1 for c in range(div,len(B)) if '1' in vec(B[c],'io_fromRename_%d_valid',6) and '1' in vec(B[c],'io_fromRename_%d_ready',6))}")
