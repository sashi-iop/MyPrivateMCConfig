#!/bin/bash

# 1. Setting up the environment for CMSSW14
source /cvmfs/cms.cern.ch/cmsset_default.sh 
export SCRAM_ARCH=el9_amd64_gcc12 
cmsrel CMSSW_14_0_18 
cd CMSSW_14_0_18/src
cmsenv 

# 2. Copying necessary files into the src area
cp /afs/cern.ch/user/s/sasahoo/genproduction/gridpacks/5f/TSM_HWZ_el9_amd64_gcc11_CMSSW_13_2_9_tarball.tar.xz . 
cp ../../run_CRAB_5f_GENSIM.py . 

# 3. Configuration setup
mkdir -p Configuration/GenProduction/python/
cp ../../HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_fragment.py Configuration/GenProduction/python/ 

scram b -j4 

# 4. Generating the python file via cmsDriver
# Note: No trailing comments allowed after '\'
cmsDriver.py Configuration/GenProduction/python/HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_fragment.py \
    --era Run3_2024 \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --beamspot DBrealistic \
    --step LHE,GEN,SIM \
    --geometry DB:Extended \
    --conditions 140X_mcRun3_2024_realistic_v26 \
    --datatier GEN-SIM \
    --eventcontent RAWSIM \
    --python_filename HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_GENSIM_cfg.py \
    --fileout file:HWZTo3L_5f_Run3Summer24-GENSIM-140X_mcRun3_2024_realistic_v26_1.root \
    --number 5 \
    --no_exec \
    --mc

# 5. Fix the gridpack path for CRAB
# CRAB places inputFiles in the same working directory, so we just need the filename, NOT relative paths like '../../'
sed -i "s|.*args = cms.vstring.*|        args = cms.vstring('../../TSM_HWZ_el9_amd64_gcc11_CMSSW_13_2_9_tarball.tar.xz'),|g" HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_GENSIM_cfg.py

echo "Setup complete! Ready to submit to CRAB."