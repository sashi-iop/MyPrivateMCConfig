# First need to setup the environment. Come out of the CMSSW14 environment
cd ../..
source /cvmfs/cms.cern.ch/cmsset_default.sh 
export SCRAM_ARCH=el9_amd64_gcc12 
cmsrel CMSSW_15_0_2
cd CMSSW_15_0_2/src
cmsenv 

# Step 3: MiniAODv6
cmsDriver.py \
    --step PAT \
    --era Run3_2024 \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --conditions 150X_mcRun3_2024_realistic_v2 \
    --geometry DB:Extended \
    --datatier MINIAODSIM \
    --eventcontent MINIAODSIM \
    --python_filename HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_MINIAODSIM_cfg.py \
    --filein file:HWZTo3L_5f_Run3Summer24-AODSIM-140X_mcRun3_2024_realistic_v26_1.root \
    --fileout file:HWZTo3L_5f_Run3Summer24-MINIAODSIM-150X_mcRun3_2024_realistic_v2_1.root \
    --number 5 \
    --no_exec \
    --mc