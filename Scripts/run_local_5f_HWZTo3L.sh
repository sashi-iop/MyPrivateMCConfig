#!/bin/bash
set -e # Exit immediately if any command fails

# 1. Token Safety Check
klist -s || { echo "Error: No valid Kerberos ticket. Run 'kinit && aklog' first."; exit 1; }

# 2. Output Paths
EOS_BASE="/eos/user/s/sasahoo/MC_Production_Local/HWZTo3L_5f_TuneCP5_13p6TeV_madgraph-pythia8"
mkdir -p ${EOS_BASE}/{GENSIM,DIGI,AODSIM,MINIAODSIM,NANOAODSIM}

echo "=== Starting CMSSW_14 Steps (GEN-SIM -> DIGI -> RECO) ==="
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=el9_amd64_gcc12

if [ ! -d "CMSSW_14_0_18" ]; then
    cmsrel CMSSW_14_0_18
fi
cd CMSSW_14_0_18/src
cmsenv

mkdir -p Configuration/GenProduction/python
cp -r ../../HWZ_LO_fragment.py Configuration/GenProduction/python/
cp -r ../../../TSM_HWZ_el9_amd64_gcc11_CMSSW_13_2_9_tarball.tar.xz .
scram b -j4

# Step 1: GEN-SIM
cmsDriver.py Configuration/GenProduction/python/HWZ_LO_fragment.py \
  --era Run3_2024 --customise Configuration/DataProcessing/Utils.addMonitoring \
  --beamspot DBrealistic --step LHE,GEN,SIM --geometry DB:Extended \
  --conditions 140X_mcRun3_2024_realistic_v26 --datatier GEN-SIM --eventcontent RAWSIM \
  --python_filename HWZ_5f_GENSIM_cfg.py \
  --fileout file:${EOS_BASE}/GENSIM/HWZTo3L_5f_Run3Summer24-GENSIM-140X_v1.root \
  --number 5 --no_exec --mc

sed -i "s|.*args = cms.vstring.*|        args = cms.vstring('../../TSM_HWZ_el9_amd64_gcc11_CMSSW_13_2_9_tarball.tar.xz'),|g" HWZ_5f_GENSIM_cfg.py
cmsRun HWZ_5f_GENSIM_cfg.py

# Step 2: DIGI-RAW-HLT
cmsDriver.py --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:2024v14 --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --conditions 140X_mcRun3_2024_realistic_v26 \
  --pileup_input "dbs:/Neutrino_E-10_gun/RunIIISummer24PrePremix-Premixlib2024_140X_mcRun3_2024_realistic_v26-v1/PREMIX" \
  --datamix PreMix --procModifiers premix_stage2 --geometry DB:Extended \
  --datatier GEN-SIM-RAW --eventcontent PREMIXRAW \
  --python_filename HWZ_5f_DRPremix_cfg.py \
  --filein file:${EOS_BASE}/GENSIM/HWZTo3L_5f_Run3Summer24-GENSIM-140X_v1.root \
  --fileout file:${EOS_BASE}/DIGI/HWZTo3L_5f_Run3Summer24-DIGI-140X_v1.root \
  --number 5 --no_exec --mc
cmsRun HWZ_5f_DRPremix_cfg.py

# Step 3: RECO
cmsDriver.py --step RAW2DIGI,L1Reco,RECO,RECOSIM --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --conditions 140X_mcRun3_2024_realistic_v26 --geometry DB:Extended \
  --datatier AODSIM --eventcontent AODSIM \
  --python_filename HWZ_5f_RECO_cfg.py \
  --filein file:${EOS_BASE}/DIGI/HWZTo3L_5f_Run3Summer24-DIGI-140X_v1.root \
  --fileout file:${EOS_BASE}/AODSIM/HWZTo3L_5f_Run3Summer24-AODSIM-140X_v1.root \
  --number 5 --no_exec --mc
cmsRun HWZ_5f_RECO_cfg.py

cd ../../

echo "=== Starting CMSSW_15 Steps (MiniAOD -> NanoAOD) ==="
if [ ! -d "CMSSW_15_0_2" ]; then
    cmsrel CMSSW_15_0_2
fi
cd CMSSW_15_0_2/src
cmsenv

# Step 4: MiniAOD
cmsDriver.py --era Run3_2024 --customise Configuration/DataProcessing/Utils.addMonitoring \
  --step PAT --geometry DB:Extended --conditions 150X_mcRun3_2024_realistic_v2 \
  --datatier MINIAODSIM --eventcontent MINIAODSIM \
  --python_filename HWZ_5f_MiniAOD_cfg.py \
  --filein file:${EOS_BASE}/AODSIM/HWZTo3L_5f_Run3Summer24-AODSIM-140X_v1.root \
  --fileout file:${EOS_BASE}/MINIAODSIM/HWZTo3L_5f_Run3Summer24-MINIAODSIM-150X_v1.root \
  --number 5 --no_exec --mc
cmsRun HWZ_5f_MiniAOD_cfg.py

# Step 5: NanoAOD
cmsDriver.py --scenario pp --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --step NANO --conditions 150X_mcRun3_2024_realistic_v2 \
  --datatier NANOAODSIM --eventcontent NANOAODSIM \
  --python_filename HWZ_5f_NanoAOD_cfg.py \
  --filein file:${EOS_BASE}/MINIAODSIM/HWZTo3L_5f_Run3Summer24-MINIAODSIM-150X_v1.root \
  --fileout file:${EOS_BASE}/NANOAODSIM/HWZTo3L_5f_Run3Summer24-NANOAODSIM-150X_v1.root \
  --number 5 --no_exec --mc
cmsRun HWZ_5f_NanoAOD_cfg.py

echo "=== 5-Flavor HWZTo3L Local Pipeline Successfully Finished! ==="