# Events

### PLAYER_ENTERING_WORLD

Entering or leaving dungeon

[1]=false, (isInitialLogin)
[2]=false, (reloadUi)

C_ChallengeMode.IsChallengeModeActive() == true (until CHALLENGE_MODE_RESET)
GetWorldElapsedTime(1) == ""

### CHALLENGE_MODE_START

When starting 5s countdown or entering active CM

[1]=1004, (instanceId)

C_ChallengeMode.IsChallengeModeActive() == true
GetWorldElapsedTime(1) == ""

### CHALLENGE_MODE_RESET

When starting 5s countdown (before CHALLENGE_MODE_START) or resetting active CM

[1]=1004, (instanceId)

C_ChallengeMode.IsChallengeModeActive() == false
GetWorldElapsedTime(1) == ""

### WORLD_STATE_TIMER_START

After 5s countdown or entering active CM

[1]=1 (timerId)

C_ChallengeMode.IsChallengeModeActive() == true
GetWorldElapsedTime(1) == "Challenge Mode Time"

### WORLD_STATE_TIMER_STOP

Resetting CM

[1]=1 (timerId)

C_ChallengeMode.IsChallengeModeActive() == true
GetWorldElapsedTime(1) == ""

### SCENARIO_CRITERIA_UPDATE

On objective progression or entering active CM with progressed objectives:

[1]=1 (criteriaId)

GetWorldElapsedTime(1) == ""

# Functions

### GetWorldElapsedTime(1)

During active CM (excluding 5s countdown):

[1]="Challenge Mode Time",
[2]=2,
[3]=1

Otherwise:

[1]="",
[2]=0,
[3]=0

### GetInstanceInfo()

[1]="Scarlet Monastery",
[2]="party",
[3]=8,
[4]="Challenge Mode",
[5]=5,
[6]=0,
[7]=false,
[8]=1004,

## C_ChallengeMode.GetChallengeModeMapTimes(1004)

[1]={
  [1]=2700,
  [2]=1320,
  [3]=780,
  [4]=540
}

## C_ChallengeMode.GetChallengeCompletionInfo()

Active CM:

[1]={
  isEligibleForScore=false,
  practiceRun=false,
  mapChallengeModeID=0,
  members={
  },
  onTime=false,
  time=0, (ms)
  isMapRecord=false,
  isAffixRecord=false,
  level=0,
  keystoneUpgradeLevels=0
}

Completed CM:

isEligibleForScore=true,
practiceRun=false,
mapChallengeModeID=77,
members={
  [1]={
    memberGUID="Player-4440-065609FD",
    name="Caricfearz"
  },
  [2]={
    memberGUID="Player-4440-0667DDDF",
    name="Jrenh"
  },
  [3]={
    memberGUID="Player-4454-0609B282",
    name="Qucikarrow"
  },
  [4]={
    memberGUID="Player-4454-060E3EFC",
    name="Nightrock"
  },
  [5]={
    memberGUID="Player-4440-065223B6",
    name="Tradias"
  }
},
oldOverallDungeonScore=0,
onTime=true,
time=173953, (ms)
isMapRecord=false,
isAffixRecord=false,
level=1,
newOverallDungeonScore=0,
keystoneUpgradeLevels=4

## C_Scenario.GetStepInfo()

Inside CM dungeon, nil otherwise:

[1]="Scarlet Monastery",
[2]="Defeat the forces of the Scarlet Crusade inside their monastery.",
[3]=4,
[4]=false,
[5]=false,
[6]=false,
[7]=false,
[8]=0,
[9]={
},
[11]=0

## C_ScenarioInfo.GetCriteriaInfo(1)

During active CM:

[1]={
  criteriaID=19270,
  description="Thalnos the Soulrender", 
  quantityString="1",
  elapsed=100,
  duration=0,
  isWeightedProgress=false,
  completed=true,
  quantity=1,
  isFormatted=false,
  failed=false,
  assetID=59789,
  flags=0,
  criteriaType=0,
  totalQuantity=1
}

## C_ScenarioInfo.GetScenarioInfo()

Inside CM dungeon, nil otherwise:

[1]={
  type=1,
  money=0,
  xp=0,
  flags=1,
  scenarioID=53,
  name="Scarlet Monastery",
  numStages=1,
  currentStage=1,
  isComplete=false,
  area="UNKNOWN"
}

