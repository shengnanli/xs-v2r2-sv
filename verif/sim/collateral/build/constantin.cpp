
#include <map>
#include <string>
#include <stdint.h>
using namespace std;

map<string, uint64_t> constantinMap;

void constantinInit(){
  constantinMap["isWriteICacheSRAMTable0"] = 0;
  constantinMap["vbop_enable0"] = 1;
  constantinMap["StoreBufferThreshold_0"] = 7;
  constantinMap["pbop_enable0"] = 1;
  constantinMap["vbop_badScore"] = 2;
  constantinMap["isWriteBankConflictTable0"] = 0;
  constantinMap["CorrectMissTrain0"] = 0;
  constantinMap["isWriteL1MissQMissTable0"] = 0;
  constantinMap["isWriteL2TlbMissQueueTable0"] = 0;
  constantinMap["streamL1Depth0"] = 64;
  constantinMap["vbop_delayQueueLatency"] = 300;
  constantinMap["pbop_badScore"] = 1;
  constantinMap["isWritePageCacheTable0"] = 0;
  constantinMap["StoreBufferBase_0"] = 4;
  constantinMap["depth0"] = 32;
  constantinMap["isWriteLoadAccessTable0"] = 0;
  constantinMap["ColdDownThreshold_0"] = 12;
  constantinMap["ForceWriteUpper_0"] = 52;
  constantinMap["vbop_firstTlbReplayCnt"] = 10;
  constantinMap["l2DepthRatio0"] = 3;
  constantinMap["pfRcv_enable0"] = 1;
  constantinMap["LFSTEnable"] = 1;
  constantinMap["isWriteIfuWbToFtqTable0"] = 0;
  constantinMap["l3DepthRatio0"] = 3;
  constantinMap["streamL2Depth0"] = 640;
  constantinMap["always_update0"] = 1;
  constantinMap["enableL3StreamPrefetch0"] = 0;
  constantinMap["streamL3Depth0"] = 640;
  constantinMap["StreamStrictTrigger_0"] = 1;
  constantinMap["enableSMS0"] = 1;
  constantinMap["isWriteFetchToIBufferTable0"] = 0;
  constantinMap["EnableHybridUnitReplay"] = 1;
  constantinMap["isWritePTWTable0"] = 0;
  constantinMap["nMaxPrefetchEntry0"] = 14;
  constantinMap["EnableMdp"] = 1;
  constantinMap["enableDynamicPrefetcher0"] = 1;
  constantinMap["isFirstHitWrite0"] = 0;
  constantinMap["pbop_roundMax"] = 50;
  constantinMap["isWriteL2TlbPrefetchTable0"] = 0;
  constantinMap["l2_stride_ratio0"] = 5;
  constantinMap["isWriteL1TlbTable0"] = 0;
  constantinMap["isWriteLoadMissTable0"] = 0;
  constantinMap["l1_stride_ratio0"] = 2;
  constantinMap["isWriteFTQTable0"] = 0;
  constantinMap["ForceWriteLower_0"] = 47;
  constantinMap["enableL1StreamPrefetcher0"] = 1;
  constantinMap["pbop_delayQueueLatency"] = 300;
  constantinMap["vbop_roundMax"] = 50;
  constantinMap["StoreWaitThreshold_0"] = 0;

}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteICacheSRAMTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteICacheSRAMTable0"]){
    cout << "isWriteICacheSRAMTable0" << " = " << constantinMap["isWriteICacheSRAMTable0"] << endl;
    a = constantinMap["isWriteICacheSRAMTable0"];
  }
  return constantinMap["isWriteICacheSRAMTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t vbop_enable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["vbop_enable0"]){
    cout << "vbop_enable0" << " = " << constantinMap["vbop_enable0"] << endl;
    a = constantinMap["vbop_enable0"];
  }
  return constantinMap["vbop_enable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t StoreBufferThreshold_0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["StoreBufferThreshold_0"]){
    cout << "StoreBufferThreshold_0" << " = " << constantinMap["StoreBufferThreshold_0"] << endl;
    a = constantinMap["StoreBufferThreshold_0"];
  }
  return constantinMap["StoreBufferThreshold_0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t pbop_enable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["pbop_enable0"]){
    cout << "pbop_enable0" << " = " << constantinMap["pbop_enable0"] << endl;
    a = constantinMap["pbop_enable0"];
  }
  return constantinMap["pbop_enable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t vbop_badScore_constantin_read() {
  static int a = -1;
  if(a != constantinMap["vbop_badScore"]){
    cout << "vbop_badScore" << " = " << constantinMap["vbop_badScore"] << endl;
    a = constantinMap["vbop_badScore"];
  }
  return constantinMap["vbop_badScore"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteBankConflictTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteBankConflictTable0"]){
    cout << "isWriteBankConflictTable0" << " = " << constantinMap["isWriteBankConflictTable0"] << endl;
    a = constantinMap["isWriteBankConflictTable0"];
  }
  return constantinMap["isWriteBankConflictTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t CorrectMissTrain0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["CorrectMissTrain0"]){
    cout << "CorrectMissTrain0" << " = " << constantinMap["CorrectMissTrain0"] << endl;
    a = constantinMap["CorrectMissTrain0"];
  }
  return constantinMap["CorrectMissTrain0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteL1MissQMissTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteL1MissQMissTable0"]){
    cout << "isWriteL1MissQMissTable0" << " = " << constantinMap["isWriteL1MissQMissTable0"] << endl;
    a = constantinMap["isWriteL1MissQMissTable0"];
  }
  return constantinMap["isWriteL1MissQMissTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteL2TlbMissQueueTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteL2TlbMissQueueTable0"]){
    cout << "isWriteL2TlbMissQueueTable0" << " = " << constantinMap["isWriteL2TlbMissQueueTable0"] << endl;
    a = constantinMap["isWriteL2TlbMissQueueTable0"];
  }
  return constantinMap["isWriteL2TlbMissQueueTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t streamL1Depth0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["streamL1Depth0"]){
    cout << "streamL1Depth0" << " = " << constantinMap["streamL1Depth0"] << endl;
    a = constantinMap["streamL1Depth0"];
  }
  return constantinMap["streamL1Depth0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t vbop_delayQueueLatency_constantin_read() {
  static int a = -1;
  if(a != constantinMap["vbop_delayQueueLatency"]){
    cout << "vbop_delayQueueLatency" << " = " << constantinMap["vbop_delayQueueLatency"] << endl;
    a = constantinMap["vbop_delayQueueLatency"];
  }
  return constantinMap["vbop_delayQueueLatency"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t pbop_badScore_constantin_read() {
  static int a = -1;
  if(a != constantinMap["pbop_badScore"]){
    cout << "pbop_badScore" << " = " << constantinMap["pbop_badScore"] << endl;
    a = constantinMap["pbop_badScore"];
  }
  return constantinMap["pbop_badScore"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWritePageCacheTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWritePageCacheTable0"]){
    cout << "isWritePageCacheTable0" << " = " << constantinMap["isWritePageCacheTable0"] << endl;
    a = constantinMap["isWritePageCacheTable0"];
  }
  return constantinMap["isWritePageCacheTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t StoreBufferBase_0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["StoreBufferBase_0"]){
    cout << "StoreBufferBase_0" << " = " << constantinMap["StoreBufferBase_0"] << endl;
    a = constantinMap["StoreBufferBase_0"];
  }
  return constantinMap["StoreBufferBase_0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t depth0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["depth0"]){
    cout << "depth0" << " = " << constantinMap["depth0"] << endl;
    a = constantinMap["depth0"];
  }
  return constantinMap["depth0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteLoadAccessTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteLoadAccessTable0"]){
    cout << "isWriteLoadAccessTable0" << " = " << constantinMap["isWriteLoadAccessTable0"] << endl;
    a = constantinMap["isWriteLoadAccessTable0"];
  }
  return constantinMap["isWriteLoadAccessTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t ColdDownThreshold_0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["ColdDownThreshold_0"]){
    cout << "ColdDownThreshold_0" << " = " << constantinMap["ColdDownThreshold_0"] << endl;
    a = constantinMap["ColdDownThreshold_0"];
  }
  return constantinMap["ColdDownThreshold_0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t ForceWriteUpper_0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["ForceWriteUpper_0"]){
    cout << "ForceWriteUpper_0" << " = " << constantinMap["ForceWriteUpper_0"] << endl;
    a = constantinMap["ForceWriteUpper_0"];
  }
  return constantinMap["ForceWriteUpper_0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t vbop_firstTlbReplayCnt_constantin_read() {
  static int a = -1;
  if(a != constantinMap["vbop_firstTlbReplayCnt"]){
    cout << "vbop_firstTlbReplayCnt" << " = " << constantinMap["vbop_firstTlbReplayCnt"] << endl;
    a = constantinMap["vbop_firstTlbReplayCnt"];
  }
  return constantinMap["vbop_firstTlbReplayCnt"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t l2DepthRatio0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["l2DepthRatio0"]){
    cout << "l2DepthRatio0" << " = " << constantinMap["l2DepthRatio0"] << endl;
    a = constantinMap["l2DepthRatio0"];
  }
  return constantinMap["l2DepthRatio0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t pfRcv_enable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["pfRcv_enable0"]){
    cout << "pfRcv_enable0" << " = " << constantinMap["pfRcv_enable0"] << endl;
    a = constantinMap["pfRcv_enable0"];
  }
  return constantinMap["pfRcv_enable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t LFSTEnable_constantin_read() {
  static int a = -1;
  if(a != constantinMap["LFSTEnable"]){
    cout << "LFSTEnable" << " = " << constantinMap["LFSTEnable"] << endl;
    a = constantinMap["LFSTEnable"];
  }
  return constantinMap["LFSTEnable"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteIfuWbToFtqTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteIfuWbToFtqTable0"]){
    cout << "isWriteIfuWbToFtqTable0" << " = " << constantinMap["isWriteIfuWbToFtqTable0"] << endl;
    a = constantinMap["isWriteIfuWbToFtqTable0"];
  }
  return constantinMap["isWriteIfuWbToFtqTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t l3DepthRatio0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["l3DepthRatio0"]){
    cout << "l3DepthRatio0" << " = " << constantinMap["l3DepthRatio0"] << endl;
    a = constantinMap["l3DepthRatio0"];
  }
  return constantinMap["l3DepthRatio0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t streamL2Depth0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["streamL2Depth0"]){
    cout << "streamL2Depth0" << " = " << constantinMap["streamL2Depth0"] << endl;
    a = constantinMap["streamL2Depth0"];
  }
  return constantinMap["streamL2Depth0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t always_update0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["always_update0"]){
    cout << "always_update0" << " = " << constantinMap["always_update0"] << endl;
    a = constantinMap["always_update0"];
  }
  return constantinMap["always_update0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t enableL3StreamPrefetch0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["enableL3StreamPrefetch0"]){
    cout << "enableL3StreamPrefetch0" << " = " << constantinMap["enableL3StreamPrefetch0"] << endl;
    a = constantinMap["enableL3StreamPrefetch0"];
  }
  return constantinMap["enableL3StreamPrefetch0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t streamL3Depth0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["streamL3Depth0"]){
    cout << "streamL3Depth0" << " = " << constantinMap["streamL3Depth0"] << endl;
    a = constantinMap["streamL3Depth0"];
  }
  return constantinMap["streamL3Depth0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t StreamStrictTrigger_0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["StreamStrictTrigger_0"]){
    cout << "StreamStrictTrigger_0" << " = " << constantinMap["StreamStrictTrigger_0"] << endl;
    a = constantinMap["StreamStrictTrigger_0"];
  }
  return constantinMap["StreamStrictTrigger_0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t enableSMS0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["enableSMS0"]){
    cout << "enableSMS0" << " = " << constantinMap["enableSMS0"] << endl;
    a = constantinMap["enableSMS0"];
  }
  return constantinMap["enableSMS0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteFetchToIBufferTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteFetchToIBufferTable0"]){
    cout << "isWriteFetchToIBufferTable0" << " = " << constantinMap["isWriteFetchToIBufferTable0"] << endl;
    a = constantinMap["isWriteFetchToIBufferTable0"];
  }
  return constantinMap["isWriteFetchToIBufferTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t EnableHybridUnitReplay_constantin_read() {
  static int a = -1;
  if(a != constantinMap["EnableHybridUnitReplay"]){
    cout << "EnableHybridUnitReplay" << " = " << constantinMap["EnableHybridUnitReplay"] << endl;
    a = constantinMap["EnableHybridUnitReplay"];
  }
  return constantinMap["EnableHybridUnitReplay"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWritePTWTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWritePTWTable0"]){
    cout << "isWritePTWTable0" << " = " << constantinMap["isWritePTWTable0"] << endl;
    a = constantinMap["isWritePTWTable0"];
  }
  return constantinMap["isWritePTWTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t nMaxPrefetchEntry0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["nMaxPrefetchEntry0"]){
    cout << "nMaxPrefetchEntry0" << " = " << constantinMap["nMaxPrefetchEntry0"] << endl;
    a = constantinMap["nMaxPrefetchEntry0"];
  }
  return constantinMap["nMaxPrefetchEntry0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t EnableMdp_constantin_read() {
  static int a = -1;
  if(a != constantinMap["EnableMdp"]){
    cout << "EnableMdp" << " = " << constantinMap["EnableMdp"] << endl;
    a = constantinMap["EnableMdp"];
  }
  return constantinMap["EnableMdp"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t enableDynamicPrefetcher0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["enableDynamicPrefetcher0"]){
    cout << "enableDynamicPrefetcher0" << " = " << constantinMap["enableDynamicPrefetcher0"] << endl;
    a = constantinMap["enableDynamicPrefetcher0"];
  }
  return constantinMap["enableDynamicPrefetcher0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isFirstHitWrite0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isFirstHitWrite0"]){
    cout << "isFirstHitWrite0" << " = " << constantinMap["isFirstHitWrite0"] << endl;
    a = constantinMap["isFirstHitWrite0"];
  }
  return constantinMap["isFirstHitWrite0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t pbop_roundMax_constantin_read() {
  static int a = -1;
  if(a != constantinMap["pbop_roundMax"]){
    cout << "pbop_roundMax" << " = " << constantinMap["pbop_roundMax"] << endl;
    a = constantinMap["pbop_roundMax"];
  }
  return constantinMap["pbop_roundMax"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteL2TlbPrefetchTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteL2TlbPrefetchTable0"]){
    cout << "isWriteL2TlbPrefetchTable0" << " = " << constantinMap["isWriteL2TlbPrefetchTable0"] << endl;
    a = constantinMap["isWriteL2TlbPrefetchTable0"];
  }
  return constantinMap["isWriteL2TlbPrefetchTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t l2_stride_ratio0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["l2_stride_ratio0"]){
    cout << "l2_stride_ratio0" << " = " << constantinMap["l2_stride_ratio0"] << endl;
    a = constantinMap["l2_stride_ratio0"];
  }
  return constantinMap["l2_stride_ratio0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteL1TlbTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteL1TlbTable0"]){
    cout << "isWriteL1TlbTable0" << " = " << constantinMap["isWriteL1TlbTable0"] << endl;
    a = constantinMap["isWriteL1TlbTable0"];
  }
  return constantinMap["isWriteL1TlbTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteLoadMissTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteLoadMissTable0"]){
    cout << "isWriteLoadMissTable0" << " = " << constantinMap["isWriteLoadMissTable0"] << endl;
    a = constantinMap["isWriteLoadMissTable0"];
  }
  return constantinMap["isWriteLoadMissTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t l1_stride_ratio0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["l1_stride_ratio0"]){
    cout << "l1_stride_ratio0" << " = " << constantinMap["l1_stride_ratio0"] << endl;
    a = constantinMap["l1_stride_ratio0"];
  }
  return constantinMap["l1_stride_ratio0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t isWriteFTQTable0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["isWriteFTQTable0"]){
    cout << "isWriteFTQTable0" << " = " << constantinMap["isWriteFTQTable0"] << endl;
    a = constantinMap["isWriteFTQTable0"];
  }
  return constantinMap["isWriteFTQTable0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t ForceWriteLower_0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["ForceWriteLower_0"]){
    cout << "ForceWriteLower_0" << " = " << constantinMap["ForceWriteLower_0"] << endl;
    a = constantinMap["ForceWriteLower_0"];
  }
  return constantinMap["ForceWriteLower_0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t enableL1StreamPrefetcher0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["enableL1StreamPrefetcher0"]){
    cout << "enableL1StreamPrefetcher0" << " = " << constantinMap["enableL1StreamPrefetcher0"] << endl;
    a = constantinMap["enableL1StreamPrefetcher0"];
  }
  return constantinMap["enableL1StreamPrefetcher0"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t pbop_delayQueueLatency_constantin_read() {
  static int a = -1;
  if(a != constantinMap["pbop_delayQueueLatency"]){
    cout << "pbop_delayQueueLatency" << " = " << constantinMap["pbop_delayQueueLatency"] << endl;
    a = constantinMap["pbop_delayQueueLatency"];
  }
  return constantinMap["pbop_delayQueueLatency"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t vbop_roundMax_constantin_read() {
  static int a = -1;
  if(a != constantinMap["vbop_roundMax"]){
    cout << "vbop_roundMax" << " = " << constantinMap["vbop_roundMax"] << endl;
    a = constantinMap["vbop_roundMax"];
  }
  return constantinMap["vbop_roundMax"];
}

#include <map>
#include <string>
#include <iostream>
#include <stdint.h>
#include <assert.h>
using namespace std;
extern map<string, uint64_t> constantinMap;
extern "C" uint64_t StoreWaitThreshold_0_constantin_read() {
  static int a = -1;
  if(a != constantinMap["StoreWaitThreshold_0"]){
    cout << "StoreWaitThreshold_0" << " = " << constantinMap["StoreWaitThreshold_0"] << endl;
    a = constantinMap["StoreWaitThreshold_0"];
  }
  return constantinMap["StoreWaitThreshold_0"];
}
