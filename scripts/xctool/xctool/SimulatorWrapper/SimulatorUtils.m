//
// Copyright 2014 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SimulatorUtils.h"

#import <launch.h>

#import "SimDevice.h"
#import "SimulatorInfo.h"
#import "SimulatorInfoXcode6.h"
#import "XCToolUtil.h"

static void GetJobsIterator(const launch_data_t launch_data, const char *key, void *context) {
  void (^block)(const launch_data_t, const char *) = context;
  block(launch_data, key);
}

void StopAndRemoveLaunchdJob(NSString *job)
{
  launch_data_t stopMessage = launch_data_alloc(LAUNCH_DATA_DICTIONARY);
  launch_data_dict_insert(stopMessage,
                          launch_data_new_string([job UTF8String]),
                          LAUNCH_KEY_REMOVEJOB);
  launch_data_t stopResponse = launch_msg(stopMessage);

  launch_data_free(stopMessage);
  launch_data_free(stopResponse);
}

static NSArray *GetLaunchdJobsForSimulator()
{
  launch_data_t getJobsMessage = launch_data_new_string(LAUNCH_KEY_GETJOBS);
  launch_data_t response = launch_msg(getJobsMessage);

  assert(launch_data_get_type(response) == LAUNCH_DATA_DICTIONARY);

  NSMutableArray *jobs = [NSMutableArray array];

  launch_data_dict_iterate(response,
                           GetJobsIterator,
                           ^(const launch_data_t launch_data, const char *keyCString)
                           {
                             NSString *key = [NSString stringWithCString:keyCString
                                                                encoding:NSUTF8StringEncoding];

                             NSArray *strings = @[@"com.apple.iphonesimulator",
                                                  @"UIKitApplication",
                                                  @"SimulatorBridge",
                                                  ];

                             BOOL matches = NO;
                             for (NSString *str in strings) {
                               if ([key rangeOfString:str options:NSCaseInsensitiveSearch].length > 0) {
                                 matches = YES;
                                 break;
                               }
                             }

                             if (matches) {
                               [jobs addObject:key];
                             }
                           });

  launch_data_free(response);
  launch_data_free(getJobsMessage);

  return jobs;
}

void KillSimulatorJobs()
{
  NSArray *jobs = GetLaunchdJobsForSimulator();

  // Tell launchd to remove each of them and trust that launchd will make sure
  // they're dead.  It'll be nice at first (sending SIGTERM) but if the process
  // doesn't die, it'll follow up with a SIGKILL.
  for (NSString *job in jobs) {
    StopAndRemoveLaunchdJob(job);
  }

  // It can take a moment for each them to die.
  while ([GetLaunchdJobsForSimulator() count] > 0) {
    [NSThread sleepForTimeInterval:0.1];
  }
}

BOOL RemoveSimulatorContentAndSettingsFolder(NSString *simulatorVersion, cpu_type_t cpuType, NSString **removedPath, NSString **errorMessage)
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *simulatorDirectory = [@"~/Library/Application Support/iPhone Simulator" stringByExpandingTildeInPath];
  NSError *error;

  [fileManager removeItemAtPath:[simulatorDirectory stringByAppendingPathComponent:@"Library"] error:nil];

  NSString *sdkDirectory = [simulatorVersion stringByAppendingString:cpuType == CPU_TYPE_X86_64 ? @"-64" : @""];
  NSString *simulatorContentsDirectory = [simulatorDirectory stringByAppendingPathComponent:sdkDirectory];

  if ([fileManager fileExistsAtPath:simulatorContentsDirectory]) {
    *removedPath = simulatorContentsDirectory;

    if (![fileManager removeItemAtPath:simulatorContentsDirectory error:&error]) {
      *errorMessage = [NSString stringWithFormat:@"%@; %@.",
                       error.localizedDescription ?: @"Unknown error.",
                       [error.userInfo[NSUnderlyingErrorKey] localizedDescription] ?: @""];
      return NO;
    }
  }

  return YES;
}

BOOL RemoveSimulatorContentAndSettings(SimulatorInfo *simulatorInfo, NSString **removedPath, NSString **errorMessage)
{
  if ([simulatorInfo isKindOfClass:[SimulatorInfoXcode6 class]]) {
    SimDevice *simulatedDevice = [(SimulatorInfoXcode6 *)simulatorInfo simulatedDevice];
    NSError *error = nil;
    *removedPath = [simulatedDevice dataPath];
    if ([simulatedDevice eraseContentsAndSettingsWithError:&error]) {
      return YES;
    } else {
      *errorMessage = [NSString stringWithFormat:@"%@; %@.",
                       error.localizedDescription ?: @"Unknown error.",
                       [error.userInfo[NSUnderlyingErrorKey] localizedDescription] ?: @""];
      return NO;
    }
  } else {
    return RemoveSimulatorContentAndSettingsFolder([simulatorInfo simulatedSdkShortVersion], [simulatorInfo cpuType], removedPath, errorMessage);
  }
}

BOOL ShutdownSimulator(SimulatorInfo *simulatorInfo, NSString **errorMessage)
{
  if ([simulatorInfo isKindOfClass:[SimulatorInfoXcode6 class]]) {
    SimDevice *simulatedDevice = [(SimulatorInfoXcode6 *)simulatorInfo simulatedDevice];
    NSError *error = nil;

    if (simulatedDevice.state != SimDeviceStateShutdown) {
      if (![simulatedDevice shutdownWithError:&error]) {
        *errorMessage = [NSString stringWithFormat:@"Tried to shutdown the simulator but failed: %@; %@.",
                         error.localizedDescription ?: @"Unknown error.",
                         [error.userInfo[NSUnderlyingErrorKey] localizedDescription] ?: @""];
        return NO;
      }
    }
  }
  return YES;
}
