# Step 3: NanoAODv15
cmsDriver.py \
    --scenario pp \
    --step NANO \
    --era Run3_2024 \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --conditions 150X_mcRun3_2024_realistic_v2 \
    --datatier NANOAODSIM \
    --eventcontent NANOAODSIM \
    --python_filename HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_NANOAODSIM_cfg.py \
    --filein file:HWZTo3L_5f_Run3Summer24-MINIAODSIM-140X_mcRun3_2024_realistic_v26_1.root \
    --fileout file:HWZTo3L_5f_Run3Summer24-NANOAODSIM-150X_mcRun3_2024_realistic_v2_1.root \
    --number 5 \
    --no_exec \
    --mc