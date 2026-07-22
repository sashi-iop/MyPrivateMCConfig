# Step 3: RECO-AODSIM
cmsDriver.py \
    --nThreads 2 \
    --step RAW2DIGI,L1Reco,RECO,RECOSIM \
    --era Run3_2024 \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --conditions 140X_mcRun3_2024_realistic_v26 \
    --geometry DB:Extended \
    --datatier AODSIM \
    --eventcontent AODSIM \
    --python_filename HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_RECO_AODSIM_cfg.py \
    --filein file:HWZTo3L_5f_Run3Summer24-DRPremix-140X_mcRun3_2024_realistic_v26_1.root \
    --fileout file:HWZTo3L_5f_Run3Summer24-AODSIM-140X_mcRun3_2024_realistic_v26_1.root \
    --number 5 \
    --no_exec \
    --mc
