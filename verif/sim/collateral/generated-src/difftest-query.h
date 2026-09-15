
#ifndef __DIFFTEST_QUERY_H__
#define __DIFFTEST_QUERY_H__

#include <cstdint>
#include "difftest-state.h"
#include "query.h"
#ifdef CONFIG_DIFFTEST_DELTA
#include "difftest-delta.h"
#endif // CONFIG_DIFFTEST_DELTA

#ifdef CONFIG_DIFFTEST_QUERY

class QueryStats: public QueryStatsBase {
public:
  Query* query_RefillEvent;
  Query* query_L1TLBEvent;
  Query* query_InstrCommit;
  Query* query_TrapEvent;
  Query* query_ArchEvent;
  Query* query_CriticalErrorEvent;
  Query* query_CSRState;
  Query* query_DebugMode;
  Query* query_TriggerCSRState;
  Query* query_VecCSRState;
  Query* query_FpCSRState;
  Query* query_HCSRState;
  Query* query_NonRegInterruptPendingEvent;
  Query* query_MhpmeventOverflowEvent;
  Query* query_SyncAIAEvent;
  Query* query_SyncCustomMflushpwrEvent;
  Query* query_UncacheMMStoreEvent;
  Query* query_L2TLBEvent;
  Query* query_AtomicEvent;
  Query* query_LrScEvent;
  Query* query_CMOInvalEvent;
  Query* query_SbufferEvent;
  Query* query_StoreEvent;
  Query* query_ArchFpRegState;
  Query* query_ArchIntRegState;
  Query* query_ArchVecRegState;
  Query* query_CommitData;
  
  QueryStats(char *path): QueryStatsBase(path) {
    RefillEvent_init();
    L1TLBEvent_init();
    InstrCommit_init();
    TrapEvent_init();
    ArchEvent_init();
    CriticalErrorEvent_init();
    CSRState_init();
    DebugMode_init();
    TriggerCSRState_init();
    VecCSRState_init();
    FpCSRState_init();
    HCSRState_init();
    NonRegInterruptPendingEvent_init();
    MhpmeventOverflowEvent_init();
    SyncAIAEvent_init();
    SyncCustomMflushpwrEvent_init();
    UncacheMMStoreEvent_init();
    L2TLBEvent_init();
    AtomicEvent_init();
    LrScEvent_init();
    CMOInvalEvent_init();
    SbufferEvent_init();
    StoreEvent_init();
    ArchFpRegState_init();
    ArchIntRegState_init();
    ArchVecRegState_init();
    CommitData_init();
    
  }
  
  void RefillEvent_init() {
    const char* createSql = " CREATE TABLE RefillEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "MY_INDEX INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "ADDR INTEGER NOT NULL," \
      "DATA_0 INTEGER NOT NULL," \
      "DATA_1 INTEGER NOT NULL," \
      "DATA_2 INTEGER NOT NULL," \
      "DATA_3 INTEGER NOT NULL," \
      "DATA_4 INTEGER NOT NULL," \
      "DATA_5 INTEGER NOT NULL," \
      "DATA_6 INTEGER NOT NULL," \
      "DATA_7 INTEGER NOT NULL," \
      "MASK INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO RefillEvent (STEP,COREID,MY_INDEX,VALID,ADDR,DATA_0,DATA_1,DATA_2,DATA_3,DATA_4,DATA_5,DATA_6,DATA_7,MASK) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_RefillEvent = new Query(mem_db, createSql, insertSql);
  }

  void L1TLBEvent_init() {
    const char* createSql = " CREATE TABLE L1TLBEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "MY_INDEX INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "SATP INTEGER NOT NULL," \
      "VPN INTEGER NOT NULL," \
      "PPN INTEGER NOT NULL," \
      "VSATP INTEGER NOT NULL," \
      "HGATP INTEGER NOT NULL," \
      "S2XLATE INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO L1TLBEvent (STEP,COREID,MY_INDEX,VALID,SATP,VPN,PPN,VSATP,HGATP,S2XLATE) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?);";
    query_L1TLBEvent = new Query(mem_db, createSql, insertSql);
  }

  void InstrCommit_init() {
    const char* createSql = " CREATE TABLE InstrCommit(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "MY_INDEX INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "SKIP INTEGER NOT NULL," \
      "ISRVC INTEGER NOT NULL," \
      "RFWEN INTEGER NOT NULL," \
      "FPWEN INTEGER NOT NULL," \
      "VECWEN INTEGER NOT NULL," \
      "V0WEN INTEGER NOT NULL," \
      "WPDEST INTEGER NOT NULL," \
      "WDEST INTEGER NOT NULL," \
      "OTHERWPDEST_0 INTEGER NOT NULL," \
      "OTHERWPDEST_1 INTEGER NOT NULL," \
      "OTHERWPDEST_2 INTEGER NOT NULL," \
      "OTHERWPDEST_3 INTEGER NOT NULL," \
      "OTHERWPDEST_4 INTEGER NOT NULL," \
      "OTHERWPDEST_5 INTEGER NOT NULL," \
      "OTHERWPDEST_6 INTEGER NOT NULL," \
      "OTHERWPDEST_7 INTEGER NOT NULL," \
      "OTHERWPDEST_8 INTEGER NOT NULL," \
      "OTHERWPDEST_9 INTEGER NOT NULL," \
      "OTHERWPDEST_10 INTEGER NOT NULL," \
      "OTHERWPDEST_11 INTEGER NOT NULL," \
      "OTHERWPDEST_12 INTEGER NOT NULL," \
      "OTHERWPDEST_13 INTEGER NOT NULL," \
      "OTHERWPDEST_14 INTEGER NOT NULL," \
      "OTHERWPDEST_15 INTEGER NOT NULL," \
      "PC INTEGER NOT NULL," \
      "INSTR INTEGER NOT NULL," \
      "ROBIDX INTEGER NOT NULL," \
      "LQIDX INTEGER NOT NULL," \
      "SQIDX INTEGER NOT NULL," \
      "ISLOAD INTEGER NOT NULL," \
      "ISSTORE INTEGER NOT NULL," \
      "NFUSED INTEGER NOT NULL," \
      "SPECIAL INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO InstrCommit (STEP,COREID,MY_INDEX,VALID,SKIP,ISRVC,RFWEN,FPWEN,VECWEN,V0WEN,WPDEST,WDEST,OTHERWPDEST_0,OTHERWPDEST_1,OTHERWPDEST_2,OTHERWPDEST_3,OTHERWPDEST_4,OTHERWPDEST_5,OTHERWPDEST_6,OTHERWPDEST_7,OTHERWPDEST_8,OTHERWPDEST_9,OTHERWPDEST_10,OTHERWPDEST_11,OTHERWPDEST_12,OTHERWPDEST_13,OTHERWPDEST_14,OTHERWPDEST_15,PC,INSTR,ROBIDX,LQIDX,SQIDX,ISLOAD,ISSTORE,NFUSED,SPECIAL) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_InstrCommit = new Query(mem_db, createSql, insertSql);
  }

  void TrapEvent_init() {
    const char* createSql = " CREATE TABLE TrapEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "HASTRAP INTEGER NOT NULL," \
      "CYCLECNT INTEGER NOT NULL," \
      "INSTRCNT INTEGER NOT NULL," \
      "HASWFI INTEGER NOT NULL," \
      "CODE INTEGER NOT NULL," \
      "PC INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO TrapEvent (STEP,COREID,HASTRAP,CYCLECNT,INSTRCNT,HASWFI,CODE,PC) " \
      " VALUES (?,?,?,?,?,?,?,?);";
    query_TrapEvent = new Query(mem_db, createSql, insertSql);
  }

  void ArchEvent_init() {
    const char* createSql = " CREATE TABLE ArchEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "INTERRUPT INTEGER NOT NULL," \
      "EXCEPTION INTEGER NOT NULL," \
      "EXCEPTIONPC INTEGER NOT NULL," \
      "EXCEPTIONINST INTEGER NOT NULL," \
      "HASNMI INTEGER NOT NULL," \
      "VIRTUALINTERRUPTISHVICTLINJECT INTEGER NOT NULL," \
      "IRTOHS INTEGER NOT NULL," \
      "IRTOVS INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO ArchEvent (STEP,COREID,VALID,INTERRUPT,EXCEPTION,EXCEPTIONPC,EXCEPTIONINST,HASNMI,VIRTUALINTERRUPTISHVICTLINJECT,IRTOHS,IRTOVS) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?);";
    query_ArchEvent = new Query(mem_db, createSql, insertSql);
  }

  void CriticalErrorEvent_init() {
    const char* createSql = " CREATE TABLE CriticalErrorEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "CRITICALERROR INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO CriticalErrorEvent (STEP,COREID,VALID,CRITICALERROR) " \
      " VALUES (?,?,?,?);";
    query_CriticalErrorEvent = new Query(mem_db, createSql, insertSql);
  }

  void CSRState_init() {
    const char* createSql = " CREATE TABLE CSRState(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "PRIVILEGEMODE INTEGER NOT NULL," \
      "MSTATUS INTEGER NOT NULL," \
      "SSTATUS INTEGER NOT NULL," \
      "MEPC INTEGER NOT NULL," \
      "SEPC INTEGER NOT NULL," \
      "MTVAL INTEGER NOT NULL," \
      "STVAL INTEGER NOT NULL," \
      "MTVEC INTEGER NOT NULL," \
      "STVEC INTEGER NOT NULL," \
      "MCAUSE INTEGER NOT NULL," \
      "SCAUSE INTEGER NOT NULL," \
      "SATP INTEGER NOT NULL," \
      "MIP INTEGER NOT NULL," \
      "MIE INTEGER NOT NULL," \
      "MSCRATCH INTEGER NOT NULL," \
      "SSCRATCH INTEGER NOT NULL," \
      "MIDELEG INTEGER NOT NULL," \
      "MEDELEG INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO CSRState (STEP,COREID,PRIVILEGEMODE,MSTATUS,SSTATUS,MEPC,SEPC,MTVAL,STVAL,MTVEC,STVEC,MCAUSE,SCAUSE,SATP,MIP,MIE,MSCRATCH,SSCRATCH,MIDELEG,MEDELEG) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_CSRState = new Query(mem_db, createSql, insertSql);
  }

  void DebugMode_init() {
    const char* createSql = " CREATE TABLE DebugMode(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "DEBUGMODE INTEGER NOT NULL," \
      "DCSR INTEGER NOT NULL," \
      "DPC INTEGER NOT NULL," \
      "DSCRATCH0 INTEGER NOT NULL," \
      "DSCRATCH1 INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO DebugMode (STEP,COREID,DEBUGMODE,DCSR,DPC,DSCRATCH0,DSCRATCH1) " \
      " VALUES (?,?,?,?,?,?,?);";
    query_DebugMode = new Query(mem_db, createSql, insertSql);
  }

  void TriggerCSRState_init() {
    const char* createSql = " CREATE TABLE TriggerCSRState(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "TSELECT INTEGER NOT NULL," \
      "TDATA1 INTEGER NOT NULL," \
      "TINFO INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO TriggerCSRState (STEP,COREID,TSELECT,TDATA1,TINFO) " \
      " VALUES (?,?,?,?,?);";
    query_TriggerCSRState = new Query(mem_db, createSql, insertSql);
  }

  void VecCSRState_init() {
    const char* createSql = " CREATE TABLE VecCSRState(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VSTART INTEGER NOT NULL," \
      "VXSAT INTEGER NOT NULL," \
      "VXRM INTEGER NOT NULL," \
      "VCSR INTEGER NOT NULL," \
      "VL INTEGER NOT NULL," \
      "VTYPE INTEGER NOT NULL," \
      "VLENB INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO VecCSRState (STEP,COREID,VSTART,VXSAT,VXRM,VCSR,VL,VTYPE,VLENB) " \
      " VALUES (?,?,?,?,?,?,?,?,?);";
    query_VecCSRState = new Query(mem_db, createSql, insertSql);
  }

  void FpCSRState_init() {
    const char* createSql = " CREATE TABLE FpCSRState(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "FCSR INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO FpCSRState (STEP,COREID,FCSR) " \
      " VALUES (?,?,?);";
    query_FpCSRState = new Query(mem_db, createSql, insertSql);
  }

  void HCSRState_init() {
    const char* createSql = " CREATE TABLE HCSRState(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VIRTMODE INTEGER NOT NULL," \
      "MTVAL2 INTEGER NOT NULL," \
      "MTINST INTEGER NOT NULL," \
      "HSTATUS INTEGER NOT NULL," \
      "HIDELEG INTEGER NOT NULL," \
      "HEDELEG INTEGER NOT NULL," \
      "HCOUNTEREN INTEGER NOT NULL," \
      "HTVAL INTEGER NOT NULL," \
      "HTINST INTEGER NOT NULL," \
      "HGATP INTEGER NOT NULL," \
      "VSSTATUS INTEGER NOT NULL," \
      "VSTVEC INTEGER NOT NULL," \
      "VSEPC INTEGER NOT NULL," \
      "VSCAUSE INTEGER NOT NULL," \
      "VSTVAL INTEGER NOT NULL," \
      "VSATP INTEGER NOT NULL," \
      "VSSCRATCH INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO HCSRState (STEP,COREID,VIRTMODE,MTVAL2,MTINST,HSTATUS,HIDELEG,HEDELEG,HCOUNTEREN,HTVAL,HTINST,HGATP,VSSTATUS,VSTVEC,VSEPC,VSCAUSE,VSTVAL,VSATP,VSSCRATCH) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_HCSRState = new Query(mem_db, createSql, insertSql);
  }

  void NonRegInterruptPendingEvent_init() {
    const char* createSql = " CREATE TABLE NonRegInterruptPendingEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "PLATFORMIRPMEIP INTEGER NOT NULL," \
      "PLATFORMIRPMTIP INTEGER NOT NULL," \
      "PLATFORMIRPMSIP INTEGER NOT NULL," \
      "PLATFORMIRPSEIP INTEGER NOT NULL," \
      "PLATFORMIRPSTIP INTEGER NOT NULL," \
      "PLATFORMIRPVSEIP INTEGER NOT NULL," \
      "PLATFORMIRPVSTIP INTEGER NOT NULL," \
      "FROMAIAMEIP INTEGER NOT NULL," \
      "FROMAIASEIP INTEGER NOT NULL," \
      "LOCALCOUNTEROVERFLOWINTERRUPTREQ INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO NonRegInterruptPendingEvent (STEP,COREID,VALID,PLATFORMIRPMEIP,PLATFORMIRPMTIP,PLATFORMIRPMSIP,PLATFORMIRPSEIP,PLATFORMIRPSTIP,PLATFORMIRPVSEIP,PLATFORMIRPVSTIP,FROMAIAMEIP,FROMAIASEIP,LOCALCOUNTEROVERFLOWINTERRUPTREQ) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_NonRegInterruptPendingEvent = new Query(mem_db, createSql, insertSql);
  }

  void MhpmeventOverflowEvent_init() {
    const char* createSql = " CREATE TABLE MhpmeventOverflowEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "MHPMEVENTOVERFLOW INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO MhpmeventOverflowEvent (STEP,COREID,VALID,MHPMEVENTOVERFLOW) " \
      " VALUES (?,?,?,?);";
    query_MhpmeventOverflowEvent = new Query(mem_db, createSql, insertSql);
  }

  void SyncAIAEvent_init() {
    const char* createSql = " CREATE TABLE SyncAIAEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "MTOPEI INTEGER NOT NULL," \
      "STOPEI INTEGER NOT NULL," \
      "VSTOPEI INTEGER NOT NULL," \
      "HGEIP INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO SyncAIAEvent (STEP,COREID,VALID,MTOPEI,STOPEI,VSTOPEI,HGEIP) " \
      " VALUES (?,?,?,?,?,?,?);";
    query_SyncAIAEvent = new Query(mem_db, createSql, insertSql);
  }

  void SyncCustomMflushpwrEvent_init() {
    const char* createSql = " CREATE TABLE SyncCustomMflushpwrEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "L2FLUSHDONE INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO SyncCustomMflushpwrEvent (STEP,COREID,VALID,L2FLUSHDONE) " \
      " VALUES (?,?,?,?);";
    query_SyncCustomMflushpwrEvent = new Query(mem_db, createSql, insertSql);
  }

  void UncacheMMStoreEvent_init() {
    const char* createSql = " CREATE TABLE UncacheMMStoreEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "MY_INDEX INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "ADDR INTEGER NOT NULL," \
      "DATA_0 INTEGER NOT NULL," \
      "DATA_1 INTEGER NOT NULL," \
      "DATA_2 INTEGER NOT NULL," \
      "DATA_3 INTEGER NOT NULL," \
      "DATA_4 INTEGER NOT NULL," \
      "DATA_5 INTEGER NOT NULL," \
      "DATA_6 INTEGER NOT NULL," \
      "DATA_7 INTEGER NOT NULL," \
      "MASK INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO UncacheMMStoreEvent (STEP,COREID,MY_INDEX,VALID,ADDR,DATA_0,DATA_1,DATA_2,DATA_3,DATA_4,DATA_5,DATA_6,DATA_7,MASK) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_UncacheMMStoreEvent = new Query(mem_db, createSql, insertSql);
  }

  void L2TLBEvent_init() {
    const char* createSql = " CREATE TABLE L2TLBEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "MY_INDEX INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "VALIDIDX_0 INTEGER NOT NULL," \
      "VALIDIDX_1 INTEGER NOT NULL," \
      "VALIDIDX_2 INTEGER NOT NULL," \
      "VALIDIDX_3 INTEGER NOT NULL," \
      "VALIDIDX_4 INTEGER NOT NULL," \
      "VALIDIDX_5 INTEGER NOT NULL," \
      "VALIDIDX_6 INTEGER NOT NULL," \
      "VALIDIDX_7 INTEGER NOT NULL," \
      "SATP INTEGER NOT NULL," \
      "VPN INTEGER NOT NULL," \
      "PBMT INTEGER NOT NULL," \
      "G_PBMT INTEGER NOT NULL," \
      "PPN_0 INTEGER NOT NULL," \
      "PPN_1 INTEGER NOT NULL," \
      "PPN_2 INTEGER NOT NULL," \
      "PPN_3 INTEGER NOT NULL," \
      "PPN_4 INTEGER NOT NULL," \
      "PPN_5 INTEGER NOT NULL," \
      "PPN_6 INTEGER NOT NULL," \
      "PPN_7 INTEGER NOT NULL," \
      "PERM INTEGER NOT NULL," \
      "LEVEL INTEGER NOT NULL," \
      "PF INTEGER NOT NULL," \
      "PTEIDX_0 INTEGER NOT NULL," \
      "PTEIDX_1 INTEGER NOT NULL," \
      "PTEIDX_2 INTEGER NOT NULL," \
      "PTEIDX_3 INTEGER NOT NULL," \
      "PTEIDX_4 INTEGER NOT NULL," \
      "PTEIDX_5 INTEGER NOT NULL," \
      "PTEIDX_6 INTEGER NOT NULL," \
      "PTEIDX_7 INTEGER NOT NULL," \
      "VSATP INTEGER NOT NULL," \
      "HGATP INTEGER NOT NULL," \
      "GVPN INTEGER NOT NULL," \
      "G_PERM INTEGER NOT NULL," \
      "G_LEVEL INTEGER NOT NULL," \
      "S2PPN INTEGER NOT NULL," \
      "GPF INTEGER NOT NULL," \
      "S2XLATE INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO L2TLBEvent (STEP,COREID,MY_INDEX,VALID,VALIDIDX_0,VALIDIDX_1,VALIDIDX_2,VALIDIDX_3,VALIDIDX_4,VALIDIDX_5,VALIDIDX_6,VALIDIDX_7,SATP,VPN,PBMT,G_PBMT,PPN_0,PPN_1,PPN_2,PPN_3,PPN_4,PPN_5,PPN_6,PPN_7,PERM,LEVEL,PF,PTEIDX_0,PTEIDX_1,PTEIDX_2,PTEIDX_3,PTEIDX_4,PTEIDX_5,PTEIDX_6,PTEIDX_7,VSATP,HGATP,GVPN,G_PERM,G_LEVEL,S2PPN,GPF,S2XLATE) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_L2TLBEvent = new Query(mem_db, createSql, insertSql);
  }

  void AtomicEvent_init() {
    const char* createSql = " CREATE TABLE AtomicEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "ADDR INTEGER NOT NULL," \
      "DATA_0 INTEGER NOT NULL," \
      "DATA_1 INTEGER NOT NULL," \
      "MASK INTEGER NOT NULL," \
      "CMP_0 INTEGER NOT NULL," \
      "CMP_1 INTEGER NOT NULL," \
      "FUOP INTEGER NOT NULL," \
      "OUT_0 INTEGER NOT NULL," \
      "OUT_1 INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO AtomicEvent (STEP,COREID,VALID,ADDR,DATA_0,DATA_1,MASK,CMP_0,CMP_1,FUOP,OUT_0,OUT_1) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?);";
    query_AtomicEvent = new Query(mem_db, createSql, insertSql);
  }

  void LrScEvent_init() {
    const char* createSql = " CREATE TABLE LrScEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "SUCCESS INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO LrScEvent (STEP,COREID,VALID,SUCCESS) " \
      " VALUES (?,?,?,?);";
    query_LrScEvent = new Query(mem_db, createSql, insertSql);
  }

  void CMOInvalEvent_init() {
    const char* createSql = " CREATE TABLE CMOInvalEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "ADDR INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO CMOInvalEvent (STEP,COREID,VALID,ADDR) " \
      " VALUES (?,?,?,?);";
    query_CMOInvalEvent = new Query(mem_db, createSql, insertSql);
  }

  void SbufferEvent_init() {
    const char* createSql = " CREATE TABLE SbufferEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "MY_INDEX INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "ADDR INTEGER NOT NULL," \
      "DATA_0 INTEGER NOT NULL," \
      "DATA_1 INTEGER NOT NULL," \
      "DATA_2 INTEGER NOT NULL," \
      "DATA_3 INTEGER NOT NULL," \
      "DATA_4 INTEGER NOT NULL," \
      "DATA_5 INTEGER NOT NULL," \
      "DATA_6 INTEGER NOT NULL," \
      "DATA_7 INTEGER NOT NULL," \
      "DATA_8 INTEGER NOT NULL," \
      "DATA_9 INTEGER NOT NULL," \
      "DATA_10 INTEGER NOT NULL," \
      "DATA_11 INTEGER NOT NULL," \
      "DATA_12 INTEGER NOT NULL," \
      "DATA_13 INTEGER NOT NULL," \
      "DATA_14 INTEGER NOT NULL," \
      "DATA_15 INTEGER NOT NULL," \
      "DATA_16 INTEGER NOT NULL," \
      "DATA_17 INTEGER NOT NULL," \
      "DATA_18 INTEGER NOT NULL," \
      "DATA_19 INTEGER NOT NULL," \
      "DATA_20 INTEGER NOT NULL," \
      "DATA_21 INTEGER NOT NULL," \
      "DATA_22 INTEGER NOT NULL," \
      "DATA_23 INTEGER NOT NULL," \
      "DATA_24 INTEGER NOT NULL," \
      "DATA_25 INTEGER NOT NULL," \
      "DATA_26 INTEGER NOT NULL," \
      "DATA_27 INTEGER NOT NULL," \
      "DATA_28 INTEGER NOT NULL," \
      "DATA_29 INTEGER NOT NULL," \
      "DATA_30 INTEGER NOT NULL," \
      "DATA_31 INTEGER NOT NULL," \
      "DATA_32 INTEGER NOT NULL," \
      "DATA_33 INTEGER NOT NULL," \
      "DATA_34 INTEGER NOT NULL," \
      "DATA_35 INTEGER NOT NULL," \
      "DATA_36 INTEGER NOT NULL," \
      "DATA_37 INTEGER NOT NULL," \
      "DATA_38 INTEGER NOT NULL," \
      "DATA_39 INTEGER NOT NULL," \
      "DATA_40 INTEGER NOT NULL," \
      "DATA_41 INTEGER NOT NULL," \
      "DATA_42 INTEGER NOT NULL," \
      "DATA_43 INTEGER NOT NULL," \
      "DATA_44 INTEGER NOT NULL," \
      "DATA_45 INTEGER NOT NULL," \
      "DATA_46 INTEGER NOT NULL," \
      "DATA_47 INTEGER NOT NULL," \
      "DATA_48 INTEGER NOT NULL," \
      "DATA_49 INTEGER NOT NULL," \
      "DATA_50 INTEGER NOT NULL," \
      "DATA_51 INTEGER NOT NULL," \
      "DATA_52 INTEGER NOT NULL," \
      "DATA_53 INTEGER NOT NULL," \
      "DATA_54 INTEGER NOT NULL," \
      "DATA_55 INTEGER NOT NULL," \
      "DATA_56 INTEGER NOT NULL," \
      "DATA_57 INTEGER NOT NULL," \
      "DATA_58 INTEGER NOT NULL," \
      "DATA_59 INTEGER NOT NULL," \
      "DATA_60 INTEGER NOT NULL," \
      "DATA_61 INTEGER NOT NULL," \
      "DATA_62 INTEGER NOT NULL," \
      "DATA_63 INTEGER NOT NULL," \
      "MASK INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO SbufferEvent (STEP,COREID,MY_INDEX,VALID,ADDR,DATA_0,DATA_1,DATA_2,DATA_3,DATA_4,DATA_5,DATA_6,DATA_7,DATA_8,DATA_9,DATA_10,DATA_11,DATA_12,DATA_13,DATA_14,DATA_15,DATA_16,DATA_17,DATA_18,DATA_19,DATA_20,DATA_21,DATA_22,DATA_23,DATA_24,DATA_25,DATA_26,DATA_27,DATA_28,DATA_29,DATA_30,DATA_31,DATA_32,DATA_33,DATA_34,DATA_35,DATA_36,DATA_37,DATA_38,DATA_39,DATA_40,DATA_41,DATA_42,DATA_43,DATA_44,DATA_45,DATA_46,DATA_47,DATA_48,DATA_49,DATA_50,DATA_51,DATA_52,DATA_53,DATA_54,DATA_55,DATA_56,DATA_57,DATA_58,DATA_59,DATA_60,DATA_61,DATA_62,DATA_63,MASK) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_SbufferEvent = new Query(mem_db, createSql, insertSql);
  }

  void StoreEvent_init() {
    const char* createSql = " CREATE TABLE StoreEvent(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "MY_INDEX INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "ADDR INTEGER NOT NULL," \
      "DATA INTEGER NOT NULL," \
      "HIGHDATA INTEGER NOT NULL," \
      "MASK INTEGER NOT NULL," \
      "WLINE INTEGER NOT NULL," \
      "VECNEEDSPLIT INTEGER NOT NULL," \
      "EEW INTEGER NOT NULL," \
      "OFFSET INTEGER NOT NULL," \
      "PC INTEGER NOT NULL," \
      "ROBIDX INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO StoreEvent (STEP,COREID,MY_INDEX,VALID,ADDR,DATA,HIGHDATA,MASK,WLINE,VECNEEDSPLIT,EEW,OFFSET,PC,ROBIDX) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_StoreEvent = new Query(mem_db, createSql, insertSql);
  }

  void ArchFpRegState_init() {
    const char* createSql = " CREATE TABLE ArchFpRegState(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALUE_0 INTEGER NOT NULL," \
      "VALUE_1 INTEGER NOT NULL," \
      "VALUE_2 INTEGER NOT NULL," \
      "VALUE_3 INTEGER NOT NULL," \
      "VALUE_4 INTEGER NOT NULL," \
      "VALUE_5 INTEGER NOT NULL," \
      "VALUE_6 INTEGER NOT NULL," \
      "VALUE_7 INTEGER NOT NULL," \
      "VALUE_8 INTEGER NOT NULL," \
      "VALUE_9 INTEGER NOT NULL," \
      "VALUE_10 INTEGER NOT NULL," \
      "VALUE_11 INTEGER NOT NULL," \
      "VALUE_12 INTEGER NOT NULL," \
      "VALUE_13 INTEGER NOT NULL," \
      "VALUE_14 INTEGER NOT NULL," \
      "VALUE_15 INTEGER NOT NULL," \
      "VALUE_16 INTEGER NOT NULL," \
      "VALUE_17 INTEGER NOT NULL," \
      "VALUE_18 INTEGER NOT NULL," \
      "VALUE_19 INTEGER NOT NULL," \
      "VALUE_20 INTEGER NOT NULL," \
      "VALUE_21 INTEGER NOT NULL," \
      "VALUE_22 INTEGER NOT NULL," \
      "VALUE_23 INTEGER NOT NULL," \
      "VALUE_24 INTEGER NOT NULL," \
      "VALUE_25 INTEGER NOT NULL," \
      "VALUE_26 INTEGER NOT NULL," \
      "VALUE_27 INTEGER NOT NULL," \
      "VALUE_28 INTEGER NOT NULL," \
      "VALUE_29 INTEGER NOT NULL," \
      "VALUE_30 INTEGER NOT NULL," \
      "VALUE_31 INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO ArchFpRegState (STEP,COREID,VALUE_0,VALUE_1,VALUE_2,VALUE_3,VALUE_4,VALUE_5,VALUE_6,VALUE_7,VALUE_8,VALUE_9,VALUE_10,VALUE_11,VALUE_12,VALUE_13,VALUE_14,VALUE_15,VALUE_16,VALUE_17,VALUE_18,VALUE_19,VALUE_20,VALUE_21,VALUE_22,VALUE_23,VALUE_24,VALUE_25,VALUE_26,VALUE_27,VALUE_28,VALUE_29,VALUE_30,VALUE_31) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_ArchFpRegState = new Query(mem_db, createSql, insertSql);
  }

  void ArchIntRegState_init() {
    const char* createSql = " CREATE TABLE ArchIntRegState(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALUE_0 INTEGER NOT NULL," \
      "VALUE_1 INTEGER NOT NULL," \
      "VALUE_2 INTEGER NOT NULL," \
      "VALUE_3 INTEGER NOT NULL," \
      "VALUE_4 INTEGER NOT NULL," \
      "VALUE_5 INTEGER NOT NULL," \
      "VALUE_6 INTEGER NOT NULL," \
      "VALUE_7 INTEGER NOT NULL," \
      "VALUE_8 INTEGER NOT NULL," \
      "VALUE_9 INTEGER NOT NULL," \
      "VALUE_10 INTEGER NOT NULL," \
      "VALUE_11 INTEGER NOT NULL," \
      "VALUE_12 INTEGER NOT NULL," \
      "VALUE_13 INTEGER NOT NULL," \
      "VALUE_14 INTEGER NOT NULL," \
      "VALUE_15 INTEGER NOT NULL," \
      "VALUE_16 INTEGER NOT NULL," \
      "VALUE_17 INTEGER NOT NULL," \
      "VALUE_18 INTEGER NOT NULL," \
      "VALUE_19 INTEGER NOT NULL," \
      "VALUE_20 INTEGER NOT NULL," \
      "VALUE_21 INTEGER NOT NULL," \
      "VALUE_22 INTEGER NOT NULL," \
      "VALUE_23 INTEGER NOT NULL," \
      "VALUE_24 INTEGER NOT NULL," \
      "VALUE_25 INTEGER NOT NULL," \
      "VALUE_26 INTEGER NOT NULL," \
      "VALUE_27 INTEGER NOT NULL," \
      "VALUE_28 INTEGER NOT NULL," \
      "VALUE_29 INTEGER NOT NULL," \
      "VALUE_30 INTEGER NOT NULL," \
      "VALUE_31 INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO ArchIntRegState (STEP,COREID,VALUE_0,VALUE_1,VALUE_2,VALUE_3,VALUE_4,VALUE_5,VALUE_6,VALUE_7,VALUE_8,VALUE_9,VALUE_10,VALUE_11,VALUE_12,VALUE_13,VALUE_14,VALUE_15,VALUE_16,VALUE_17,VALUE_18,VALUE_19,VALUE_20,VALUE_21,VALUE_22,VALUE_23,VALUE_24,VALUE_25,VALUE_26,VALUE_27,VALUE_28,VALUE_29,VALUE_30,VALUE_31) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_ArchIntRegState = new Query(mem_db, createSql, insertSql);
  }

  void ArchVecRegState_init() {
    const char* createSql = " CREATE TABLE ArchVecRegState(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "VALUE_0 INTEGER NOT NULL," \
      "VALUE_1 INTEGER NOT NULL," \
      "VALUE_2 INTEGER NOT NULL," \
      "VALUE_3 INTEGER NOT NULL," \
      "VALUE_4 INTEGER NOT NULL," \
      "VALUE_5 INTEGER NOT NULL," \
      "VALUE_6 INTEGER NOT NULL," \
      "VALUE_7 INTEGER NOT NULL," \
      "VALUE_8 INTEGER NOT NULL," \
      "VALUE_9 INTEGER NOT NULL," \
      "VALUE_10 INTEGER NOT NULL," \
      "VALUE_11 INTEGER NOT NULL," \
      "VALUE_12 INTEGER NOT NULL," \
      "VALUE_13 INTEGER NOT NULL," \
      "VALUE_14 INTEGER NOT NULL," \
      "VALUE_15 INTEGER NOT NULL," \
      "VALUE_16 INTEGER NOT NULL," \
      "VALUE_17 INTEGER NOT NULL," \
      "VALUE_18 INTEGER NOT NULL," \
      "VALUE_19 INTEGER NOT NULL," \
      "VALUE_20 INTEGER NOT NULL," \
      "VALUE_21 INTEGER NOT NULL," \
      "VALUE_22 INTEGER NOT NULL," \
      "VALUE_23 INTEGER NOT NULL," \
      "VALUE_24 INTEGER NOT NULL," \
      "VALUE_25 INTEGER NOT NULL," \
      "VALUE_26 INTEGER NOT NULL," \
      "VALUE_27 INTEGER NOT NULL," \
      "VALUE_28 INTEGER NOT NULL," \
      "VALUE_29 INTEGER NOT NULL," \
      "VALUE_30 INTEGER NOT NULL," \
      "VALUE_31 INTEGER NOT NULL," \
      "VALUE_32 INTEGER NOT NULL," \
      "VALUE_33 INTEGER NOT NULL," \
      "VALUE_34 INTEGER NOT NULL," \
      "VALUE_35 INTEGER NOT NULL," \
      "VALUE_36 INTEGER NOT NULL," \
      "VALUE_37 INTEGER NOT NULL," \
      "VALUE_38 INTEGER NOT NULL," \
      "VALUE_39 INTEGER NOT NULL," \
      "VALUE_40 INTEGER NOT NULL," \
      "VALUE_41 INTEGER NOT NULL," \
      "VALUE_42 INTEGER NOT NULL," \
      "VALUE_43 INTEGER NOT NULL," \
      "VALUE_44 INTEGER NOT NULL," \
      "VALUE_45 INTEGER NOT NULL," \
      "VALUE_46 INTEGER NOT NULL," \
      "VALUE_47 INTEGER NOT NULL," \
      "VALUE_48 INTEGER NOT NULL," \
      "VALUE_49 INTEGER NOT NULL," \
      "VALUE_50 INTEGER NOT NULL," \
      "VALUE_51 INTEGER NOT NULL," \
      "VALUE_52 INTEGER NOT NULL," \
      "VALUE_53 INTEGER NOT NULL," \
      "VALUE_54 INTEGER NOT NULL," \
      "VALUE_55 INTEGER NOT NULL," \
      "VALUE_56 INTEGER NOT NULL," \
      "VALUE_57 INTEGER NOT NULL," \
      "VALUE_58 INTEGER NOT NULL," \
      "VALUE_59 INTEGER NOT NULL," \
      "VALUE_60 INTEGER NOT NULL," \
      "VALUE_61 INTEGER NOT NULL," \
      "VALUE_62 INTEGER NOT NULL," \
      "VALUE_63 INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO ArchVecRegState (STEP,COREID,VALUE_0,VALUE_1,VALUE_2,VALUE_3,VALUE_4,VALUE_5,VALUE_6,VALUE_7,VALUE_8,VALUE_9,VALUE_10,VALUE_11,VALUE_12,VALUE_13,VALUE_14,VALUE_15,VALUE_16,VALUE_17,VALUE_18,VALUE_19,VALUE_20,VALUE_21,VALUE_22,VALUE_23,VALUE_24,VALUE_25,VALUE_26,VALUE_27,VALUE_28,VALUE_29,VALUE_30,VALUE_31,VALUE_32,VALUE_33,VALUE_34,VALUE_35,VALUE_36,VALUE_37,VALUE_38,VALUE_39,VALUE_40,VALUE_41,VALUE_42,VALUE_43,VALUE_44,VALUE_45,VALUE_46,VALUE_47,VALUE_48,VALUE_49,VALUE_50,VALUE_51,VALUE_52,VALUE_53,VALUE_54,VALUE_55,VALUE_56,VALUE_57,VALUE_58,VALUE_59,VALUE_60,VALUE_61,VALUE_62,VALUE_63) " \
      " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    query_ArchVecRegState = new Query(mem_db, createSql, insertSql);
  }

  void CommitData_init() {
    const char* createSql = " CREATE TABLE CommitData(" \
      "ID INTEGER PRIMARY KEY AUTOINCREMENT," \
      "STEP INTEGER NOT NULL," \
      "COREID INTEGER NOT NULL," \
      "MY_INDEX INTEGER NOT NULL," \
      "VALID INTEGER NOT NULL," \
      "DATA INTEGER NOT NULL);";
    const char* insertSql = "INSERT INTO CommitData (STEP,COREID,MY_INDEX,VALID,DATA) " \
      " VALUES (?,?,?,?,?);";
    query_CommitData = new Query(mem_db, createSql, insertSql);
  }

  
  void RefillEvent_write(int dut_zone, uint8_t coreid, uint8_t index, DifftestRefillEvent* packet) {
    query_RefillEvent->write(14, query_step + (query_zone != 0), coreid, index, packet->valid, packet->addr, packet->data[0], packet->data[1], packet->data[2], packet->data[3], packet->data[4], packet->data[5], packet->data[6], packet->data[7], packet->mask);
  }

  void L1TLBEvent_write(int dut_zone, uint8_t coreid, uint8_t index, DifftestL1TLBEvent* packet) {
    query_L1TLBEvent->write(10, query_step + (query_zone != 0), coreid, index, packet->valid, packet->satp, packet->vpn, packet->ppn, packet->vsatp, packet->hgatp, packet->s2xlate);
  }

  void InstrCommit_write(int dut_zone, uint8_t coreid, uint8_t index, DifftestInstrCommit* packet) {
    query_InstrCommit->write(37, query_step + (query_zone != 0), coreid, index, packet->valid, packet->skip, packet->isRVC, packet->rfwen, packet->fpwen, packet->vecwen, packet->v0wen, packet->wpdest, packet->wdest, packet->otherwpdest[0], packet->otherwpdest[1], packet->otherwpdest[2], packet->otherwpdest[3], packet->otherwpdest[4], packet->otherwpdest[5], packet->otherwpdest[6], packet->otherwpdest[7], packet->otherwpdest[8], packet->otherwpdest[9], packet->otherwpdest[10], packet->otherwpdest[11], packet->otherwpdest[12], packet->otherwpdest[13], packet->otherwpdest[14], packet->otherwpdest[15], packet->pc, packet->instr, packet->robIdx, packet->lqIdx, packet->sqIdx, packet->isLoad, packet->isStore, packet->nFused, packet->special);
  }

  void TrapEvent_write(int dut_zone, uint8_t coreid, DifftestTrapEvent* packet) {
    query_TrapEvent->write(8, query_step + (query_zone != 0), coreid, packet->hasTrap, packet->cycleCnt, packet->instrCnt, packet->hasWFI, packet->code, packet->pc);
  }

  void ArchEvent_write(int dut_zone, uint8_t coreid, DifftestArchEvent* packet) {
    query_ArchEvent->write(11, query_step + (query_zone != 0), coreid, packet->valid, packet->interrupt, packet->exception, packet->exceptionPC, packet->exceptionInst, packet->hasNMI, packet->virtualInterruptIsHvictlInject, packet->irToHS, packet->irToVS);
  }

  void CriticalErrorEvent_write(int dut_zone, uint8_t coreid, DifftestCriticalErrorEvent* packet) {
    query_CriticalErrorEvent->write(4, query_step + (query_zone != 0), coreid, packet->valid, packet->criticalError);
  }

  void CSRState_write(int dut_zone, uint8_t coreid, DifftestCSRState* packet) {
    query_CSRState->write(20, query_step + (query_zone != 0), coreid, packet->privilegeMode, packet->mstatus, packet->sstatus, packet->mepc, packet->sepc, packet->mtval, packet->stval, packet->mtvec, packet->stvec, packet->mcause, packet->scause, packet->satp, packet->mip, packet->mie, packet->mscratch, packet->sscratch, packet->mideleg, packet->medeleg);
  }

  void DebugMode_write(int dut_zone, uint8_t coreid, DifftestDebugMode* packet) {
    query_DebugMode->write(7, query_step + (query_zone != 0), coreid, packet->debugMode, packet->dcsr, packet->dpc, packet->dscratch0, packet->dscratch1);
  }

  void TriggerCSRState_write(int dut_zone, uint8_t coreid, DifftestTriggerCSRState* packet) {
    query_TriggerCSRState->write(5, query_step + (query_zone != 0), coreid, packet->tselect, packet->tdata1, packet->tinfo);
  }

  void VecCSRState_write(int dut_zone, uint8_t coreid, DifftestVecCSRState* packet) {
    query_VecCSRState->write(9, query_step + (query_zone != 0), coreid, packet->vstart, packet->vxsat, packet->vxrm, packet->vcsr, packet->vl, packet->vtype, packet->vlenb);
  }

  void FpCSRState_write(int dut_zone, uint8_t coreid, DifftestFpCSRState* packet) {
    query_FpCSRState->write(3, query_step + (query_zone != 0), coreid, packet->fcsr);
  }

  void HCSRState_write(int dut_zone, uint8_t coreid, DifftestHCSRState* packet) {
    query_HCSRState->write(19, query_step + (query_zone != 0), coreid, packet->virtMode, packet->mtval2, packet->mtinst, packet->hstatus, packet->hideleg, packet->hedeleg, packet->hcounteren, packet->htval, packet->htinst, packet->hgatp, packet->vsstatus, packet->vstvec, packet->vsepc, packet->vscause, packet->vstval, packet->vsatp, packet->vsscratch);
  }

  void NonRegInterruptPendingEvent_write(int dut_zone, uint8_t coreid, DifftestNonRegInterruptPendingEvent* packet) {
    query_NonRegInterruptPendingEvent->write(13, query_step + (query_zone != 0), coreid, packet->valid, packet->platformIRPMeip, packet->platformIRPMtip, packet->platformIRPMsip, packet->platformIRPSeip, packet->platformIRPStip, packet->platformIRPVseip, packet->platformIRPVstip, packet->fromAIAMeip, packet->fromAIASeip, packet->localCounterOverflowInterruptReq);
  }

  void MhpmeventOverflowEvent_write(int dut_zone, uint8_t coreid, DifftestMhpmeventOverflowEvent* packet) {
    query_MhpmeventOverflowEvent->write(4, query_step + (query_zone != 0), coreid, packet->valid, packet->mhpmeventOverflow);
  }

  void SyncAIAEvent_write(int dut_zone, uint8_t coreid, DifftestSyncAIAEvent* packet) {
    query_SyncAIAEvent->write(7, query_step + (query_zone != 0), coreid, packet->valid, packet->mtopei, packet->stopei, packet->vstopei, packet->hgeip);
  }

  void SyncCustomMflushpwrEvent_write(int dut_zone, uint8_t coreid, DifftestSyncCustomMflushpwrEvent* packet) {
    query_SyncCustomMflushpwrEvent->write(4, query_step + (query_zone != 0), coreid, packet->valid, packet->l2FlushDone);
  }

  void UncacheMMStoreEvent_write(int dut_zone, uint8_t coreid, uint8_t index, DifftestUncacheMMStoreEvent* packet) {
    query_UncacheMMStoreEvent->write(14, query_step + (query_zone != 0), coreid, index, packet->valid, packet->addr, packet->data[0], packet->data[1], packet->data[2], packet->data[3], packet->data[4], packet->data[5], packet->data[6], packet->data[7], packet->mask);
  }

  void L2TLBEvent_write(int dut_zone, uint8_t coreid, uint8_t index, DifftestL2TLBEvent* packet) {
    query_L2TLBEvent->write(43, query_step + (query_zone != 0), coreid, index, packet->valid, packet->valididx[0], packet->valididx[1], packet->valididx[2], packet->valididx[3], packet->valididx[4], packet->valididx[5], packet->valididx[6], packet->valididx[7], packet->satp, packet->vpn, packet->pbmt, packet->g_pbmt, packet->ppn[0], packet->ppn[1], packet->ppn[2], packet->ppn[3], packet->ppn[4], packet->ppn[5], packet->ppn[6], packet->ppn[7], packet->perm, packet->level, packet->pf, packet->pteidx[0], packet->pteidx[1], packet->pteidx[2], packet->pteidx[3], packet->pteidx[4], packet->pteidx[5], packet->pteidx[6], packet->pteidx[7], packet->vsatp, packet->hgatp, packet->gvpn, packet->g_perm, packet->g_level, packet->s2ppn, packet->gpf, packet->s2xlate);
  }

  void AtomicEvent_write(int dut_zone, uint8_t coreid, DifftestAtomicEvent* packet) {
    query_AtomicEvent->write(12, query_step + (query_zone != 0), coreid, packet->valid, packet->addr, packet->data[0], packet->data[1], packet->mask, packet->cmp[0], packet->cmp[1], packet->fuop, packet->out[0], packet->out[1]);
  }

  void LrScEvent_write(int dut_zone, uint8_t coreid, DifftestLrScEvent* packet) {
    query_LrScEvent->write(4, query_step + (query_zone != 0), coreid, packet->valid, packet->success);
  }

  void CMOInvalEvent_write(int dut_zone, uint8_t coreid, DifftestCMOInvalEvent* packet) {
    query_CMOInvalEvent->write(4, query_step + (query_zone != 0), coreid, packet->valid, packet->addr);
  }

  void SbufferEvent_write(int dut_zone, uint8_t coreid, uint8_t index, DifftestSbufferEvent* packet) {
    query_SbufferEvent->write(70, query_step + (query_zone != 0), coreid, index, packet->valid, packet->addr, packet->data[0], packet->data[1], packet->data[2], packet->data[3], packet->data[4], packet->data[5], packet->data[6], packet->data[7], packet->data[8], packet->data[9], packet->data[10], packet->data[11], packet->data[12], packet->data[13], packet->data[14], packet->data[15], packet->data[16], packet->data[17], packet->data[18], packet->data[19], packet->data[20], packet->data[21], packet->data[22], packet->data[23], packet->data[24], packet->data[25], packet->data[26], packet->data[27], packet->data[28], packet->data[29], packet->data[30], packet->data[31], packet->data[32], packet->data[33], packet->data[34], packet->data[35], packet->data[36], packet->data[37], packet->data[38], packet->data[39], packet->data[40], packet->data[41], packet->data[42], packet->data[43], packet->data[44], packet->data[45], packet->data[46], packet->data[47], packet->data[48], packet->data[49], packet->data[50], packet->data[51], packet->data[52], packet->data[53], packet->data[54], packet->data[55], packet->data[56], packet->data[57], packet->data[58], packet->data[59], packet->data[60], packet->data[61], packet->data[62], packet->data[63], packet->mask);
  }

  void StoreEvent_write(int dut_zone, uint8_t coreid, uint8_t index, DifftestStoreEvent* packet) {
    query_StoreEvent->write(14, query_step + (query_zone != 0), coreid, index, packet->valid, packet->addr, packet->data, packet->highData, packet->mask, packet->wLine, packet->vecNeedSplit, packet->eew, packet->offset, packet->pc, packet->robidx);
  }

  void ArchFpRegState_write(int dut_zone, uint8_t coreid, DifftestArchFpRegState* packet) {
    query_ArchFpRegState->write(34, query_step + (query_zone != 0), coreid, packet->value[0], packet->value[1], packet->value[2], packet->value[3], packet->value[4], packet->value[5], packet->value[6], packet->value[7], packet->value[8], packet->value[9], packet->value[10], packet->value[11], packet->value[12], packet->value[13], packet->value[14], packet->value[15], packet->value[16], packet->value[17], packet->value[18], packet->value[19], packet->value[20], packet->value[21], packet->value[22], packet->value[23], packet->value[24], packet->value[25], packet->value[26], packet->value[27], packet->value[28], packet->value[29], packet->value[30], packet->value[31]);
  }

  void ArchIntRegState_write(int dut_zone, uint8_t coreid, DifftestArchIntRegState* packet) {
    query_ArchIntRegState->write(34, query_step + (query_zone != 0), coreid, packet->value[0], packet->value[1], packet->value[2], packet->value[3], packet->value[4], packet->value[5], packet->value[6], packet->value[7], packet->value[8], packet->value[9], packet->value[10], packet->value[11], packet->value[12], packet->value[13], packet->value[14], packet->value[15], packet->value[16], packet->value[17], packet->value[18], packet->value[19], packet->value[20], packet->value[21], packet->value[22], packet->value[23], packet->value[24], packet->value[25], packet->value[26], packet->value[27], packet->value[28], packet->value[29], packet->value[30], packet->value[31]);
  }

  void ArchVecRegState_write(int dut_zone, uint8_t coreid, DifftestArchVecRegState* packet) {
    query_ArchVecRegState->write(66, query_step + (query_zone != 0), coreid, packet->value[0], packet->value[1], packet->value[2], packet->value[3], packet->value[4], packet->value[5], packet->value[6], packet->value[7], packet->value[8], packet->value[9], packet->value[10], packet->value[11], packet->value[12], packet->value[13], packet->value[14], packet->value[15], packet->value[16], packet->value[17], packet->value[18], packet->value[19], packet->value[20], packet->value[21], packet->value[22], packet->value[23], packet->value[24], packet->value[25], packet->value[26], packet->value[27], packet->value[28], packet->value[29], packet->value[30], packet->value[31], packet->value[32], packet->value[33], packet->value[34], packet->value[35], packet->value[36], packet->value[37], packet->value[38], packet->value[39], packet->value[40], packet->value[41], packet->value[42], packet->value[43], packet->value[44], packet->value[45], packet->value[46], packet->value[47], packet->value[48], packet->value[49], packet->value[50], packet->value[51], packet->value[52], packet->value[53], packet->value[54], packet->value[55], packet->value[56], packet->value[57], packet->value[58], packet->value[59], packet->value[60], packet->value[61], packet->value[62], packet->value[63]);
  }

  void CommitData_write(int dut_zone, uint8_t coreid, uint8_t index, DifftestCommitData* packet) {
    query_CommitData->write(5, query_step + (query_zone != 0), coreid, index, packet->valid, packet->data);
  }

  
  
};
#endif // CONFIG_DIFFTEST_QUERY
#endif // __DIFFTEST_QUERY_H__

