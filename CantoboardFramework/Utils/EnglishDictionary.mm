//
//  leveldb.cpp
//  CantoboardFramework
//
//  Created by Alex Man on 3/22/21.
//

#include <fstream>
#include <string>
#include <algorithm>
#include <unordered_map>

#import <Foundation/Foundation.h>

#include <leveldb/db.h>
#include <leveldb/cache.h>
#include <leveldb/write_batch.h>

#include "Utils.h"

using namespace std;

@implementation EnglishDictionary {
    leveldb::DB* db;
}

- (id)init:(NSString*) dbPath {
    self = [super init];
    
    leveldb::Options options;
    options.block_cache = leveldb::NewLRUCache(1024); // Reduce cache size to 1kb.
    options.reuse_logs = true;
    leveldb::Status status = leveldb::DB::Open(options, [dbPath UTF8String], &db);
    
    if (!status.ok()) {
        NSLog(@"Failed to open DB %@. Error: %s", dbPath, status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to open DB." userInfo:nil];
    }
    
    NSLog(@"Opened English dictionary at %@.", dbPath);
    
    [FileUnlocker unlockAllOpenedFiles];
    
    return self;
}

- (void)dealloc {
    delete db;
    db = nullptr;
}

- (NSString*)getWords:(NSString*) word {
    leveldb::ReadOptions options;
    options.fill_cache = false;
    string val;
    leveldb::Status status;
    status = db->Get(options, [[word lowercaseString] UTF8String], &val);
    if (status.ok()) {
        return [NSString stringWithUTF8String:val.c_str()];
    }
    return nil;
}

+ (bool)createDb:(NSArray*) textFilePaths dbPath:(NSString*) dbPath {
    NSLog(@"createDbFromTextFile %@ -> %@", textFilePaths, dbPath);
    
    leveldb::DB* db;
    leveldb::Options options;
    options.create_if_missing = true;
    
    leveldb::Status status = leveldb::DB::Open(options, [dbPath UTF8String], &db);
    if (!status.ok()) {
        NSLog(@"Failed to open DB %@. Error: %s", dbPath, status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to open DB." userInfo:nil];
    }
    
    // lowercased key -> list of strings with original cases.
    unordered_map<string, string> wordCasesMap;
    string line;
    for (NSString* textFilePath in textFilePaths) {
        NSLog(@"Loading %@...", textFilePath);
        ifstream dictFile([textFilePath UTF8String]);
        
        [[NSFileManager defaultManager] createDirectoryAtPath:dbPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        while (getline(dictFile, line)) {
            if (*line.rbegin() == '\r') line.pop_back();
            if (line.empty() || line.find(',') != std::string::npos) continue;
            string key(line);
            transform(key.begin(), key.end(), key.begin(), [](unsigned char c){ return tolower(c); });
            
            auto it = wordCasesMap.find(key);
            if (it == wordCasesMap.end()) {
                wordCasesMap.insert(make_pair(string(key), string(line)));
            } else {
                it->second.append(",");
                it->second.append(line);
            }
        }
        dictFile.close();
    }
    
    leveldb::WriteBatch batch;
    for (auto it = wordCasesMap.begin(); it != wordCasesMap.end(); it++) {
        // NSLog(@"%s -> %s\n", it->first.c_str(), it->second.c_str());
        batch.Put(it->first, it->second);
    }
    leveldb::Status writeStatus = db->Write(leveldb::WriteOptions(), &batch);
    if (!writeStatus.ok()) {
        NSLog(@"Failed to insert into DB. Error: %s", status.ToString().c_str());
        @throw [NSException exceptionWithName:@"EnglishDictionaryException" reason:@"Failed to insert into DB." userInfo:nil];
    }
    
    db->CompactRange(nullptr, nullptr);
    delete db;
    
    return self;
}

@end
