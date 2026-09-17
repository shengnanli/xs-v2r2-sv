
// performanceCounter commitTrace

#include "perfCCT.h"
#include "chisel_db.h"
#include <string>

extern sqlite3 *mem_db;
extern char *zErrMsg;
extern int rc;
int callback_temp(void *NotUsed, int argc, char **argv, char **azColName) { return 0; }

// must define these
extern std::string riscv_disasm(uint64_t code, uint64_t pc);

bool enable_dump_lifetime = false;
uint64_t global_tick_acc = 0;

std::vector<InstMeta*> lastCommittedInsts;

class PerfCCT
{
  uint64_t cur_tick = 0;
  uint64_t sn_acc = 10;
  uint64_t last_max_sn = sn_acc;
  uint64_t commitSN = 0;
  uint64_t last_commitSN = 0;

  std::map <uint64_t, InstMeta> metas;
  // never replace with unordered_map, we need ordered RB-Tree
  std::string sql_insert_cmd, ld_insert_cmd;

  std::mutex commitLock; // guard commitSN
  std::mutex metaLock;   // guard metas
  std::stringstream ss;

  uint64_t id = 0;

  std::map<uint64_t, InstMeta>::iterator getMeta(uint64_t sn) {
    if (sn == 0) [[unlikely]] return metas.end();
    else {
      std::lock_guard<std::mutex> guardMeta(metaLock);
      metas[sn];
      return metas.find(sn);
    }
  }

public:
  PerfCCT() {
#if false
    ss << "INSERT INTO LifeTimeCommitTrace(SN,UopIdx,";
    ss << "AtFetch,AtDecode,AtRename,AtDispQue,AtIssueQue,AtIssueArb,AtIssueReadReg,AtFU,AtBypassVal,AtWriteVal,AtCommit,DisAsm,PC";
    ss << ") VALUES (";
    sql_insert_cmd = ss.str();
    ss.str(std::string());

    ld_insert_cmd = "insert into LoadLifeTimeCommitTrace(ID, VAddress, PAddress, LastReplay, ReplayStr) Values (";

    const char* createTable=
    "CREATE TABLE LifeTimeCommitTrace( \
    ID INTEGER PRIMARY KEY AUTOINCREMENT, \
    SN INTEGER NOT NULL, \
    UopIdx INT NOT NULL, \
    AtFetch bigint unsigned NOT NULL, \
    AtDecode bigint unsigned NOT NULL, \
    AtRename bigint unsigned NOT NULL, \
    AtDispQue bigint unsigned NOT NULL, \
    AtIssueQue bigint unsigned NOT NULL, \
    AtIssueArb bigint unsigned NOT NULL, \
    AtIssueReadReg bigint unsigned NOT NULL, \
    AtFU bigint unsigned NOT NULL, \
    AtBypassVal bigint unsigned NOT NULL, \
    AtWriteVal bigint unsigned NOT NULL, \
    AtCommit bigint unsigned NOT NULL, \
    DisAsm int unsigned NOT NULL, \
    PC bigint unsigned NOT NULL \
    ); \
    CREATE TABLE LoadLifeTimeCommitTrace( \
      ID int unsigned PRIMARY KEY, \
      VAddress bigint unsigned not null, \
      PAddress bigint unsigned not null, \
      LastReplay bigint unsigned not null, \
      ReplayStr char(10) not null, \
      constraint fk_id \
        foreign key (ID) references LifeTimeCommitTrace(ID) \
    );";

    rc = sqlite3_exec(mem_db, createTable, callback_temp, 0, &zErrMsg);
    if (rc != SQLITE_OK) {
      printf("PerfCCT SQL error: %s\n", zErrMsg);
      exit(1);
    }

#endif
  }

  void tick() { // negedge trigger
#if false
    if (!enable_dump_lifetime) [[likely]] return;
    if (cur_tick != global_tick_acc) {
      cur_tick = global_tick_acc;
      // update last_max_sn
      last_max_sn = sn_acc + 1;

      std::lock_guard<std::mutex> guardMeta(metaLock);
      std::lock_guard<std::mutex> guardCommit(commitLock);
      // clear old insts from last cycle
      lastCommittedInsts.clear();
      for (auto it = metas.begin(); it != metas.end() && it->first <= last_commitSN; it = metas.erase(it));
      // dump last commmitted insts
      for (auto it = metas.begin(); it != metas.end() && it->first <= commitSN; it++) {
        for (size_t uopidx = 0; uopidx < it->second.uopTick.size(); uopidx++) {
          ss << sql_insert_cmd;
          ss << it->second.sn << "," << uopidx;
          for (auto pos_it = it->second.uopTick[uopidx].begin();
            pos_it != it->second.uopTick[uopidx].end();
            pos_it++) {
            ss << "," << *pos_it;
          }
          ss << "," << it->second.instcode;
          ss << "," << it->second.pc; 
          ss << ");";

          id ++;

          if (it->second.isload) {
            ss << ld_insert_cmd;
            ss << id << ',';
            ss << it->second.vaddr << ',';
            ss << it->second.paddr << ',';
            ss << it->second.lastReplay << ',';
            ss << '\'' << it->second.replayStr.str() << '\'';
            ss << ");";
          }

          rc = sqlite3_exec(mem_db, ss.str().c_str(), callback_temp, 0, &zErrMsg);
          if (rc != SQLITE_OK) {
            printf("commitMeta SQL error: %s\n", zErrMsg);
            exit(1);
          }
          ss.str(std::string());
        }
        if (it->second.uopTick[0].at(AtCommit) != 0)
          lastCommittedInsts.push_back(&(it->second));
      }
      last_commitSN = commitSN;
    }
#endif
  }

  uint64_t createInstMeta(uint64_t order_id, uint64_t pc, uint64_t instcode) {
#if false
    if (!enable_dump_lifetime) [[likely]] return 0;

    uint64_t sn = last_max_sn + order_id;
    sn_acc = std::max(sn_acc, sn);
    auto meta = getMeta(sn);
    meta->second.reset(sn, pc, instcode);
    meta->second.updateUopTick(0, AtFetch, global_tick_acc);

    return sn;
#endif
    return 0;
  }

  void updateInstPos(uint64_t sn, uint64_t uopIdx, const InstPos pos) {
#if false
    if (!enable_dump_lifetime) [[likely]] return;

    auto meta = getMeta(sn);
    if (meta == metas.end()) [[unlikely]] return;
    meta->second.updateUopTick(uopIdx, pos, global_tick_acc);
#endif
  }

  // interface example
  void updateInstMeta(uint64_t sn, uint64_t uopIdx, uint64_t detail, uint64_t val) {
#if false
    if (!enable_dump_lifetime) [[likely]] return;
     
     auto meta = getMeta(sn);
     if (meta == metas.end()) [[unlikely]] return;
     switch (detail) {
       case InstDetail::VAddress: {
         meta->second.isload = true;
         meta->second.vaddr = val;
         break;
       }
       case InstDetail::PAddress: {
         meta->second.paddr = val;
         break;
       }
       case InstDetail::LastReplay:{
         meta->second.lastReplay = val;
         break;
       }
       case InstDetail::ReplayStr:{
         assert(val < sizeof(ReplayReasonStr));
         meta->second.replayStr << ReplayReasonStr[val];
         break;
       }
     }

#endif
  }

  void commitMeta(uint64_t order_id, uint64_t sn, uint64_t block_size) {
#if false
    if (sn == 0) [[unlikely]] return;

    for (int i=0;i<block_size;i++) {
      auto meta = getMeta(sn + i);
      meta->second.updateUopTick(0, AtCommit, global_tick_acc);
    }
    std::lock_guard<std::mutex> guardCommit(commitLock);
    commitSN = std::max(commitSN, sn + block_size - 1);
#endif
  }
}*perfCCT;

void init_perfcct(char *((*select_db_list)[256]), int select_db_num) {
  perfCCT = new PerfCCT();

  const char *table_name = "lifetime";
  for (int idx = 0; idx < select_db_num; idx++) {
    char *str_p = (*select_db_list)[idx];
    int s_idx = 0;
    bool match = true;
    for (; (str_p[s_idx] != '\0') && (table_name[s_idx] != '\0'); s_idx ++) {
      if (str_p[s_idx] != table_name[s_idx]) {
        match = false;
        break;
      }
    }
    if (!match || (str_p[s_idx] != '\0')) continue;

    enable_dump_lifetime = true;
    break;
  }
}

extern "C" {
  // dpic function name must same as HasDPICUtils subclass's name
  // here add your new interface

  void globalSimNegedge() {
    global_tick_acc++;
    perfCCT->tick();
  }

  uint64_t createInstMeta(uint64_t order_id, uint64_t pc, uint64_t instcode) {
    return perfCCT->createInstMeta(order_id, pc, instcode);
  }

  void updateInstPos(uint64_t sn, uint64_t uopIdx, const InstPos pos) {
    perfCCT->updateInstPos(sn, uopIdx, pos);
  }

  void updateInstMeta(uint64_t sn, uint64_t uopIdx, uint64_t meta, uint64_t data) {
    perfCCT->updateInstMeta(sn, uopIdx, meta, data);
  }

  void commitInstMeta(uint64_t order_id, uint64_t sn, uint64_t block_size) {
    perfCCT->commitMeta(order_id, sn, block_size);
  }
}
       