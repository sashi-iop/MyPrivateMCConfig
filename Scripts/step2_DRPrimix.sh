# Step 2: DIGI-RAW-HLT
cmsDriver.py \
    --nThreads 4 \
    --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:2024v14 \
    --era Run3_2024 \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --conditions 140X_mcRun3_2024_realistic_v26 \
    --pileup_input "dbs:/Neutrino_E-10_gun/RunIIISummer24PrePremix-Premixlib2024_140X_mcRun3_2024_realistic_v26-v1/PREMIX" \
    --datamix PreMix \
    --procModifiers premix_stage2 \
    --geometry DB:Extended \
    --datatier GEN-SIM-RAW \
    --eventcontent PREMIXRAW \
    --python_filename HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_DRPremix_cfg.py \
    --filein file:HWZTo3L_5f_Run3Summer24-GENSIM-140X_mcRun3_2024_realistic_v26_1.root \
    --fileout file:HWZTo3L_5f_Run3Summer24-DRPremix-140X_mcRun3_2024_realistic_v26_1.root \
    --number 5 \
    --no_exec \
    --mc