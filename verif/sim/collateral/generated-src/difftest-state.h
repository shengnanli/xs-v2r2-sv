#ifndef __DIFFTEST_STATE_H__
#define __DIFFTEST_STATE_H__

#include <cstdint>

#define CONFIG_DIFFTEST_DPIC
#define CONFIG_DIFFTEST_ZONESIZE 1
#define CONFIG_DIFFTEST_BUFLEN 1

#define CPU_XIANGSHAN_KMHV2


#ifndef NUM_CORES
#define NUM_CORES 1
#endif

#define CONFIG_DIFFTEST_REFILLEVENT
#define CONFIG_DIFF_REFILL_WIDTH 5
typedef struct  {
  uint8_t  valid;
  uint64_t addr;
  uint64_t data[8];
  uint8_t  mask;
} DifftestRefillEvent;

#define CONFIG_DIFFTEST_STOREEVENT
#define CONFIG_DIFF_STORE_WIDTH 3
typedef struct  {
  uint8_t  valid;
  uint64_t addr;
  uint64_t data;
  uint64_t highData;
  uint16_t mask;
  uint8_t  wLine;
  uint8_t  vecNeedSplit;
  uint8_t  eew;
  uint16_t offset;
  uint64_t pc;
  uint16_t robidx;
} DifftestStoreEvent;

#define CONFIG_DIFFTEST_HCSRSTATE
typedef struct  {
  uint64_t virtMode;
  uint64_t mtval2;
  uint64_t mtinst;
  uint64_t hstatus;
  uint64_t hideleg;
  uint64_t hedeleg;
  uint64_t hcounteren;
  uint64_t htval;
  uint64_t htinst;
  uint64_t hgatp;
  uint64_t vsstatus;
  uint64_t vstvec;
  uint64_t vsepc;
  uint64_t vscause;
  uint64_t vstval;
  uint64_t vsatp;
  uint64_t vsscratch;
} DifftestHCSRState;

#define CONFIG_DIFFTEST_SYNCAIAEVENT
typedef struct  {
  uint8_t  valid;
  uint64_t mtopei;
  uint64_t stopei;
  uint64_t vstopei;
  uint64_t hgeip;
} DifftestSyncAIAEvent;

#define CONFIG_DIFFTEST_CRITICALERROREVENT
typedef struct  {
  uint8_t  valid;
  uint8_t  criticalError;
} DifftestCriticalErrorEvent;

#define CONFIG_DIFFTEST_SYNCCUSTOMMFLUSHPWREVENT
typedef struct  {
  uint8_t  valid;
  uint8_t  l2FlushDone;
} DifftestSyncCustomMflushpwrEvent;

#define CONFIG_DIFFTEST_DEBUGMODE
typedef struct  {
  uint8_t  debugMode;
  uint64_t dcsr;
  uint64_t dpc;
  uint64_t dscratch0;
  uint64_t dscratch1;
} DifftestDebugMode;

#define CONFIG_DIFFTEST_SBUFFEREVENT
#define CONFIG_DIFF_SBUFFER_WIDTH 1
typedef struct  {
  uint8_t  valid;
  uint64_t addr;
  uint8_t  data[64];
  uint64_t mask;
} DifftestSbufferEvent;

#define CONFIG_DIFFTEST_TRIGGERCSRSTATE
typedef struct  {
  uint64_t tselect;
  uint64_t tdata1;
  uint64_t tinfo;
} DifftestTriggerCSRState;

#define CONFIG_DIFFTEST_INSTRCOMMIT
#define CONFIG_DIFF_COMMIT_WIDTH 8
typedef struct  {
  uint8_t  valid;
  uint8_t  skip;
  uint8_t  isRVC;
  uint8_t  rfwen;
  uint8_t  fpwen;
  uint8_t  vecwen;
  uint8_t  v0wen;
  uint16_t wpdest;
  uint8_t  wdest;
  uint16_t otherwpdest[16];
  uint64_t pc;
  uint32_t instr;
  uint16_t robIdx;
  uint8_t  lqIdx;
  uint8_t  sqIdx;
  uint8_t  isLoad;
  uint8_t  isStore;
  uint8_t  nFused;
  uint8_t  special;
} DifftestInstrCommit;

#define CONFIG_DIFFTEST_L2TLBEVENT
#define CONFIG_DIFF_L2TLB_WIDTH 2
typedef struct  {
  uint8_t  valid;
  uint8_t  valididx[8];
  uint64_t satp;
  uint64_t vpn;
  uint8_t  pbmt;
  uint8_t  g_pbmt;
  uint64_t ppn[8];
  uint8_t  perm;
  uint8_t  level;
  uint8_t  pf;
  uint8_t  pteidx[8];
  uint64_t vsatp;
  uint64_t hgatp;
  uint64_t gvpn;
  uint8_t  g_perm;
  uint8_t  g_level;
  uint64_t s2ppn;
  uint8_t  gpf;
  uint8_t  s2xlate;
} DifftestL2TLBEvent;

#define CONFIG_DIFFTEST_MHPMEVENTOVERFLOWEVENT
typedef struct  {
  uint8_t  valid;
  uint64_t mhpmeventOverflow;
} DifftestMhpmeventOverflowEvent;

#define CONFIG_DIFFTEST_ARCHEVENT
typedef struct  {
  uint8_t  valid;
  uint32_t interrupt;
  uint32_t exception;
  uint64_t exceptionPC;
  uint32_t exceptionInst;
  uint8_t  hasNMI;
  uint8_t  virtualInterruptIsHvictlInject;
  uint8_t  irToHS;
  uint8_t  irToVS;
} DifftestArchEvent;

#define CONFIG_DIFFTEST_ARCHINTREGSTATE
typedef struct  {
  uint64_t value[32];
} DifftestArchIntRegState;

#define CONFIG_DIFFTEST_VECCSRSTATE
typedef struct  {
  uint64_t vstart;
  uint64_t vxsat;
  uint64_t vxrm;
  uint64_t vcsr;
  uint64_t vl;
  uint64_t vtype;
  uint64_t vlenb;
} DifftestVecCSRState;

#define CONFIG_DIFFTEST_NONREGINTERRUPTPENDINGEVENT
typedef struct  {
  uint8_t  valid;
  uint8_t  platformIRPMeip;
  uint8_t  platformIRPMtip;
  uint8_t  platformIRPMsip;
  uint8_t  platformIRPSeip;
  uint8_t  platformIRPStip;
  uint8_t  platformIRPVseip;
  uint8_t  platformIRPVstip;
  uint8_t  fromAIAMeip;
  uint8_t  fromAIASeip;
  uint8_t  localCounterOverflowInterruptReq;
} DifftestNonRegInterruptPendingEvent;

#define CONFIG_DIFFTEST_COMMITDATA
#define CONFIG_DIFF_COMMIT_DATA_WIDTH 8
typedef struct  {
  uint8_t  valid;
  uint64_t data;
} DifftestCommitData;

#define CONFIG_DIFFTEST_LRSCEVENT
typedef struct  {
  uint8_t  valid;
  uint8_t  success;
} DifftestLrScEvent;

#define CONFIG_DIFFTEST_L1TLBEVENT
#define CONFIG_DIFF_L1TLB_WIDTH 11
typedef struct  {
  uint8_t  valid;
  uint64_t satp;
  uint64_t vpn;
  uint64_t ppn;
  uint64_t vsatp;
  uint64_t hgatp;
  uint8_t  s2xlate;
} DifftestL1TLBEvent;

#define CONFIG_DIFFTEST_ATOMICEVENT
typedef struct  {
  uint8_t  valid;
  uint64_t addr;
  uint64_t data[2];
  uint16_t mask;
  uint64_t cmp[2];
  uint8_t  fuop;
  uint64_t out[2];
} DifftestAtomicEvent;

#define CONFIG_DIFFTEST_CMOINVALEVENT
typedef struct  {
  uint8_t  valid;
  uint64_t addr;
} DifftestCMOInvalEvent;

#define CONFIG_DIFFTEST_ARCHVECREGSTATE
typedef struct  {
  uint64_t value[64];
} DifftestArchVecRegState;

#define CONFIG_DIFFTEST_UNCACHEMMSTOREEVENT
#define CONFIG_DIFF_UNCACHE_MM_STORE_WIDTH 1
typedef struct  {
  uint8_t  valid;
  uint64_t addr;
  uint8_t  data[8];
  uint8_t  mask;
} DifftestUncacheMMStoreEvent;

#define CONFIG_DIFFTEST_ARCHFPREGSTATE
typedef struct  {
  uint64_t value[32];
} DifftestArchFpRegState;

#define CONFIG_DIFFTEST_CSRSTATE
typedef struct  {
  uint64_t privilegeMode;
  uint64_t mstatus;
  uint64_t sstatus;
  uint64_t mepc;
  uint64_t sepc;
  uint64_t mtval;
  uint64_t stval;
  uint64_t mtvec;
  uint64_t stvec;
  uint64_t mcause;
  uint64_t scause;
  uint64_t satp;
  uint64_t mip;
  uint64_t mie;
  uint64_t mscratch;
  uint64_t sscratch;
  uint64_t mideleg;
  uint64_t medeleg;
} DifftestCSRState;

#define CONFIG_DIFFTEST_TRAPEVENT
typedef struct  {
  uint8_t  hasTrap;
  uint64_t cycleCnt;
  uint64_t instrCnt;
  uint8_t  hasWFI;
  uint64_t code;
  uint64_t pc;
} DifftestTrapEvent;

#define CONFIG_DIFFTEST_FPCSRSTATE
typedef struct  {
  uint64_t fcsr;
} DifftestFpCSRState;

typedef struct {
  DifftestArchIntRegState        xrf;
  DifftestArchFpRegState         frf;
  DifftestCSRState               csr;
  DifftestHCSRState              hcsr;
  DifftestArchVecRegState        vrf;
  DifftestVecCSRState            vcsr;
  DifftestFpCSRState             fcsr;
  DifftestTriggerCSRState        triggercsr;
} DiffTestRegState;

typedef struct {
  DiffTestRegState regs;
  DifftestArchEvent              event;
  DifftestAtomicEvent            atomic;
  DifftestCMOInvalEvent          cmo_inval;
  DifftestCommitData             commit_data[8];
  DifftestCriticalErrorEvent     critical_error;
  DifftestDebugMode              dmregs;
  DifftestInstrCommit            commit[8];
  DifftestL1TLBEvent             l1tlb[11];
  DifftestL2TLBEvent             l2tlb[2];
  DifftestLrScEvent              lrsc;
  DifftestMhpmeventOverflowEvent mhpmevent_overflow;
  DifftestNonRegInterruptPendingEvent non_reg_interrupt_pending;
  DifftestRefillEvent            refill[5];
  DifftestSbufferEvent           sbuffer[1];
  DifftestStoreEvent             store[3];
  DifftestSyncAIAEvent           sync_aia;
  DifftestSyncCustomMflushpwrEvent sync_custom_mflushpwr;
  DifftestTrapEvent              trap;
  DifftestUncacheMMStoreEvent    uncache_mm_store[1];
} DiffTestState;


class DiffStateBuffer {
public:
  virtual ~DiffStateBuffer() {}
  virtual DiffTestState* get(int zone, int index) = 0;
  virtual DiffTestState* next() = 0;
  virtual void switch_zone() = 0;
};

extern DiffStateBuffer** diffstate_buffer;

extern void diffstate_buffer_init();
extern void diffstate_buffer_free();


#ifdef CONFIG_DIFFTEST_PERFCNT
void diffstate_perfcnt_init();
void diffstate_perfcnt_finish(long long msec);
#endif // CONFIG_DIFFTEST_PERFCNT


#ifdef CONFIG_DIFFTEST_QUERY
void difftest_query_init();
void difftest_query_step();
void difftest_query_finish();
#endif // CONFIG_DIFFTEST_QUERY

#endif // __DIFFTEST_STATE_H__

