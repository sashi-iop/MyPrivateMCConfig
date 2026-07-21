## Pre-Flight Check: The AFS Token Trap

Before running the heavy simulation steps, you must ensure your AFS token is valid.

**The Error:** During Step 2 (DIGI), `cmsDriver.py` uses `dasgoclient` to look up the physical files for the pileup dataset (`--pileup_input`). DAS attempts to write a temporary cache file to your home directory (`~/.dasmaps/`). If your terminal session has been open too long, your AFS token silently expires, triggering a `permission denied` error. This results in an empty pileup list and a fatal `NoSecondaryFiles` error in CMSSW, crashing everything downstream.

**The Fix:** Always run these commands before starting a long local pipeline:

```bash
kinit
aklog
tokens

```

*Pro-tip: Include a defensive check at the very top of your master script to abort immediately if the token is invalid:*

```bash
klist -s || { echo "Fatal: No valid Kerberos ticket. Run 'kinit' and 'aklog' first."; exit 1; }

```

---

## The 5-Flavor Local Production Pipeline

1. **Initialize CMSSW_14 & Gridpack:**
Set up the environment for the core simulation steps and import your 5-flavor gridpack and fragment.

```bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=el9_amd64_gcc12
cmsrel CMSSW_14_0_18
cd CMSSW_14_0_18/src
cmsenv

mkdir -p Configuration/GenProduction/python
cp -r ../../HWZ_LO_fragment.py Configuration/GenProduction/python/
# Here I am using relative path of the gridpack but you are free to use any absolute path wherever it is located.
cp -r ../../../TSM_HWZ_el9_amd64_gcc11_CMSSW_13_2_9_tarball.tar.xz .
scram b -j4

```


2. **Generate Python Configs (Steps 1-3):**
Use `cmsDriver.py` to create the configuration files for generation, digitization (pileup mixing), and reconstruction.

```bash
# Step 1: GEN-SIM
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
--fileout file:TSM_HWZ_Trilepton_5f_GENSIM.root \
--number 5 --no_exec --mc

# Inject the tarball path into the Step 1 config
sed -i "s|.*args = cms.vstring.*|        args = cms.vstring('../../TSM_HWZ_el9_amd64_gcc11_CMSSW_13_2_9_tarball.tar.xz'),|g" HWZ_5f_GENSIM_cfg.py

# Step 2: DIGI-RAW-HLT
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
--filein file:TSM_HWZ_Trilepton_5f_GENSIM.root \
--fileout file:HWZ_5f_DIGI.root \
--number 5 --no_exec --mc

# Step 3: RECO
cmsDriver.py \
--step RAW2DIGI,L1Reco,RECO,RECOSIM \
--era Run3_2024 \
--customise Configuration/DataProcessing/Utils.addMonitoring \
--conditions 140X_mcRun3_2024_realistic_v26 \
--geometry DB:Extended \
--datatier AODSIM \
--eventcontent AODSIM \
--python_filename HWZ_5f_RECO_cfg.py \
--filein file:HWZ_5f_DIGI.root \
--fileout file:HWZ_5f_AODSIM.root \
--number 5 --no_exec --mc

```


3. **Execute CMSSW_14 Pipeline:**
Run the generated configurations sequentially. *If Step 2 crashes here, verify your AFS token.*

```bash
cmsRun HWZ_5f_GENSIM_cfg.py
cmsRun HWZ_5f_DRPremix_cfg.py
cmsRun HWZ_5f_RECO_cfg.py

```


4. **Transition to CMSSW_15:**
MiniAOD and NanoAOD formats for Run 3 require a newer CMSSW release. You must exit the current environment, set up the new one, and bring your AOD file with you.

```bash
cd ../../
export SCRAM_ARCH=el9_amd64_gcc12
cmsrel CMSSW_15_0_2
cd CMSSW_15_0_2/src
cmsenv

# Bring the Step 3 output into the new environment
cp ../../CMSSW_14_0_18/src/HWZ_5f_AODSIM.root .

```


5. **Generate Python Configs (Steps 4-5):**
Create the configurations for the final data tiers using the updated `150X` conditions.

```bash
# Step 4: MiniAODv6
cmsDriver.py \
--era Run3_2024 \
--customise Configuration/DataProcessing/Utils.addMonitoring \
--step PAT \
--geometry DB:Extended \
--conditions 150X_mcRun3_2024_realistic_v2 \
--datatier MINIAODSIM \
--eventcontent MINIAODSIM \
--python_filename HWZ_5f_MiniAOD_cfg.py \
--filein file:HWZ_5f_AODSIM.root \
--fileout file:HWZ_5f_MINIAODSIM.root \
--number 5 --no_exec --mc

# Step 5: NanoAODv15
cmsDriver.py \
--scenario pp \
--era Run3_2024 \
--customise Configuration/DataProcessing/Utils.addMonitoring \
--step NANO \
--conditions 150X_mcRun3_2024_realistic_v2 \
--datatier NANOAODSIM \
--eventcontent NANOAODSIM \
--python_filename HWZ_5f_NanoAOD_cfg.py \
--filein file:HWZ_5f_MINIAODSIM.root \
--fileout file:HWZ_5f_NANOAODSIM.root \
--number 5 --no_exec --mc

```


6. **Execute CMSSW_15 Pipeline:**
Run the final lightweight conversions to produce your analysis-ready flat ntuple.

```bash
cmsRun HWZ_5f_MiniAOD_cfg.py
cmsRun HWZ_5f_NanoAOD_cfg.py

```