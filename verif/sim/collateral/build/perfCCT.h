
#ifndef __CHISEL_PERFCCT_H__
#define __CHISEL_PERFCCT_H__

#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cassert>
#include <cstdint>
#include <cerrno>
#include <unistd.h>
#include <sqlite3.h>
#include <vector>
#include <mutex>
#include <map>
#include <sstream>

enum InstPos {
  AtFetch,
  AtDecode,
  AtRename,
  AtDispQue,
  AtIssueQue,
  AtIssueArb,
  AtIssueReadReg,
  AtFU,
  AtBypassVal,
  AtWriteVal,
  AtCommit
};

enum InstDetail {
  VAddress,
  PAddress,
  LastReplay,
  ReplayStr
};


static char ReplayReasonStr[] = {
   'C',
 'T',
 'B',
 'N',
 'S',
 'R',
 'W',
 'F',
 'O'        
};

struct InstMeta
{
  uint64_t sn;
  uint64_t pc;
  uint64_t instcode;
  std::vector< std::vector<uint64_t> > uopTick;
  std::mutex uopTickLock;
  // load meta not support split inst
  bool isload;
  uint64_t vaddr;
  uint64_t paddr;
  uint64_t lastReplay;
  std::stringstream replayStr;

  void reset(uint64_t sn, uint64_t pc, uint64_t instcode) {
    std::lock_guard<std::mutex> guard(uopTickLock);
    this->sn = sn;
    this->pc = pc;
    this->instcode = instcode;
    uopTick.clear();

    isload = false;
    vaddr = 0;
    paddr = 0;
    lastReplay = 0;
    replayStr.str(std::string());
  }

  void updateUopTick(uint64_t uopIdx, const InstPos pos, uint64_t tick) {
    std::lock_guard<std::mutex> guard(uopTickLock);
    if (uopTick.size() <= uopIdx) {
      size_t old_size = uopTick.size();
      for (size_t i = old_size; i <= uopIdx; i++) {
        uopTick.push_back(std::vector<uint64_t>());
        uopTick.back().resize(AtCommit + 1, 0);
        // uop shares same fetch and decode time
        if (uopIdx > 0) {
          uopTick.back().at(AtFetch) = uopTick[0].at(AtFetch);
          uopTick.back().at(AtDecode) = uopTick[0].at(AtDecode);
        }
      }
    }
    if (pos == AtCommit) {
      // each uop commits at the same time
      for (auto& it : uopTick)
        it.at(AtCommit) = tick;
    } else {
      if (!uopTick[uopIdx].at(pos))
        uopTick[uopIdx].at(pos) = tick;
    }
  }
};

// export to xspdb
extern std::vector<InstMeta*> lastCommittedInsts;

#endif
       