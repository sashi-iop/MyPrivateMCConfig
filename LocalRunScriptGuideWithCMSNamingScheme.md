Here is the fully corrected documentation and execution workflow updated for **`HWZTo3L`**.

All instances of `HWZTo4L` in the `--filein` and `--fileout` arguments of `cmsDriver.py` have been replaced with `HWZTo3L` so that the filenames match your `EOS_OUT` directory path and self-documenting naming standard.

---

## Local Dataset & File Naming Standard

In central CMS production, datasets follow the 3-field path `/PrimaryDataset/ProcessedDataset/DataTier`. For local production on EOS/local disk, we mirror this structure using structured directories and filenames:

| CMS Dataset Concept | Local Field Value | Explanation |
| --- | --- | --- |
| **Primary Dataset** | `HWZTo3L_5f_TuneCP5_13p6TeV_madgraph-pythia8` | Physics process, flavor scheme (`5f`), generator tune, center-of-mass energy, and generator chain. |
| **Step 1 Tag (GEN-SIM)** | `Run3Summer24-GENSIM-140X_mcRun3_2024_realistic_v26-v1` | Campaign, output tier, Global Tag, and iteration version. |
| **Step 2/3 Tag (DIGI/RECO)** | `Run3Summer24-AODSIM-140X_mcRun3_2024_realistic_v26-v1` | Identifies the reconstructed AOD step under 140X conditions. |
| **Step 4 Tag (MiniAOD)** | `Run3Summer24-MiniAODv6-150X_mcRun3_2024_realistic_v2-v1` | Slimmed PAT tier produced in CMSSW_15_0_2. |
| **Step 5 Tag (NanoAOD)** | `Run3Summer24-NanoAODv15-150X_mcRun3_2024_realistic_v2-v1` | Final flat ntuple tier produced in CMSSW_15_0_2. |

### Output Directory Structure

Organize your files on EOS using the Primary Dataset name as the root directory:

```text
/eos/user/s/sasahoo/MC_Production_Local/HWZTo3L_5f_TuneCP5_13p6TeV_madgraph-pythia8/
├── GENSIM/
│   └── HWZTo3L_5f_Run3Summer24-GENSIM-140X_v1.root
├── DIGI/
│   └── HWZTo3L_5f_Run3Summer24-DIGI-140X_v1.root
├── AODSIM/
│   └── HWZTo3L_5f_Run3Summer24-AODSIM-140X_v1.root
├── MINIAODSIM/
│   └── HWZTo3L_5f_Run3Summer24-MINIAODSIM-150X_v1.root
└── NANOAODSIM/
    └── HWZTo3L_5f_Run3Summer24-NANOAODSIM-150X_v1.root

```

---

## Local Execution Flow

### 1. Token Security & Prerequisites

Before launching a multi-step local job, verify your AFS Kerberos token. An expired token will crash `dasgoclient` during Step 2 (pileup lookup), causing downstream step failures.

```bash
# Verify/Renew ticket manually before running
kinit
aklog
klist -s || { echo "Error: No valid Kerberos ticket!"; exit 1; }

```

### 2. Set Up CMSSW_14 Environment & Inputs

Initialize `CMSSW_14_0_18` for Steps 1 through 3, create the output directory tree, and copy your physics fragment and gridpack.

```bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=el9_amd64_gcc12

# Set base output path on EOS
EOS_OUT="/eos/user/s/sasahoo/MC_Production_Local/HWZTo3L_5f_TuneCP5_13p6TeV_madgraph-pythia8"
mkdir -p ${EOS_OUT}/{GENSIM,DIGI,AODSIM,MINIAODSIM,NANOAODSIM}

cmsrel CMSSW_14_0_18
cd CMSSW_14_0_18/src
cmsenv

mkdir -p Configuration/GenProduction/python
cp -r ../../HWZ_LO_fragment.py Configuration/GenProduction/python/
cp -r ../../../TSM_HWZ_el9_amd64_gcc11_CMSSW_13_2_9_tarball.tar.xz .
scram b -j4

```

### 3. Step 1: GEN-SIM (CMSSW_14)

Generate LHE, run Pythia parton showering, and simulate detector interactions.

```bash
cmsDriver.py Configuration/GenProduction/python/HWZ_LO_fragment.py \
  --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --beamspot DBrealistic \
  --step LHE,GEN,SIM \
  --geometry DB:Extended \
  --conditions 140X_mcRun3_2024_realistic_v26 \
  --datatier GEN-SIM \
  --eventcontent RAWSIM \
  --python_filename HWZ_5f_GENSIM_cfg.py \
  --fileout file:${EOS_OUT}/GENSIM/HWZTo3L_5f_Run3Summer24-GENSIM-140X_v1.root \
  --number 5 --no_exec --mc

# Point the configuration to your local gridpack tarball
sed -i "s|.*args = cms.vstring.*|        args = cms.vstring('../../TSM_HWZ_el9_amd64_gcc11_CMSSW_13_2_9_tarball.tar.xz'),|g" HWZ_5f_GENSIM_cfg.py

# Execute GEN-SIM
cmsRun HWZ_5f_GENSIM_cfg.py

```

### 4. Step 2: DIGI-RAW-HLT (CMSSW_14)

Overlay PreMix background pileup and evaluate the 2024 HLT trigger menu.

```bash
cmsDriver.py \
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
  --python_filename HWZ_5f_DRPremix_cfg.py \
  --filein file:${EOS_OUT}/GENSIM/HWZTo3L_5f_Run3Summer24-GENSIM-140X_v1.root \
  --fileout file:${EOS_OUT}/DIGI/HWZTo3L_5f_Run3Summer24-DIGI-140X_v1.root \
  --number 5 --no_exec --mc

# Execute DIGI
cmsRun HWZ_5f_DRPremix_cfg.py

```

### 5. Step 3: RECO (CMSSW_14)

Run track reconstruction and event building to produce the AODSIM file.

```bash
cmsDriver.py \
  --step RAW2DIGI,L1Reco,RECO,RECOSIM \
  --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --conditions 140X_mcRun3_2024_realistic_v26 \
  --geometry DB:Extended \
  --datatier AODSIM \
  --eventcontent AODSIM \
  --python_filename HWZ_5f_RECO_cfg.py \
  --filein file:${EOS_OUT}/DIGI/HWZTo3L_5f_Run3Summer24-DIGI-140X_v1.root \
  --fileout file:${EOS_OUT}/AODSIM/HWZTo3L_5f_Run3Summer24-AODSIM-140X_v1.root \
  --number 5 --no_exec --mc

# Execute RECO
cmsRun HWZ_5f_RECO_cfg.py

```

### 6. Step 4: MiniAODv6 (CMSSW_15)

Switch to `CMSSW_15_0_2` and run physics object slimming (PAT).

```bash
cd ../../
cmsrel CMSSW_15_0_2
cd CMSSW_15_0_2/src
cmsenv

cmsDriver.py \
  --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --step PAT \
  --geometry DB:Extended \
  --conditions 150X_mcRun3_2024_realistic_v2 \
  --datatier MINIAODSIM \
  --eventcontent MINIAODSIM \
  --python_filename HWZ_5f_MiniAOD_cfg.py \
  --filein file:${EOS_OUT}/AODSIM/HWZTo3L_5f_Run3Summer24-AODSIM-140X_v1.root \
  --fileout file:${EOS_OUT}/MINIAODSIM/HWZTo3L_5f_Run3Summer24-MINIAODSIM-150X_v1.root \
  --number 5 --no_exec --mc

# Execute MiniAOD
cmsRun HWZ_5f_MiniAOD_cfg.py

```

### 7. Step 5: NanoAODv15 (CMSSW_15)

Produce the final flat ntuple tier for analysis frameworks (Coffea/ROOT).

```bash
cmsDriver.py \
  --scenario pp \
  --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --step NANO \
  --conditions 150X_mcRun3_2024_realistic_v2 \
  --datatier NANOAODSIM \
  --eventcontent NANOAODSIM \
  --python_filename HWZ_5f_NanoAOD_cfg.py \
  --filein file:${EOS_OUT}/MINIAODSIM/HWZTo3L_5f_Run3Summer24-MINIAODSIM-150X_v1.root \
  --fileout file:${EOS_OUT}/NANOAODSIM/HWZTo3L_5f_Run3Summer24-NANOAODSIM-150X_v1.root \
  --number 5 --no_exec --mc

# Execute NanoAOD
cmsRun HWZ_5f_NanoAOD_cfg.py

```

