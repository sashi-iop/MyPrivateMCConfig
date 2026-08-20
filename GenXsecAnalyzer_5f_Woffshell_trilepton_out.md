Here is the formatted Markdown document ready to be committed to your GitHub repository. It captures the workflow, the script, and the explanation of the output so other analysts (or you in the future) can easily understand the process.

```markdown
# Extracting True Cross-Sections for Multi-Process MadGraph Gridpacks in CMSSW

When producing private Monte Carlo (MC) samples for CMS, especially for BSM signals with multiple decay channels (e.g., leptonic vs. hadronic $W/Z$ decays), a common trap is extracting the wrong cross-section directly from the LHE file. 

This guide demonstrates how to correctly extract the **After filter cross section** using CMSSW's `GenXSecAnalyzer`, ensuring proper normalization for downstream analysis in frameworks like Coffea or ROOT.

## The Problem: LHE File Merging Quirks

If your MadGraph `proc_card.dat` contains multiple `add process` lines, MadGraph generates these processes in temporary directories and merges them into a final `cmsgrid_final.lhe` file. 

Running a simple `grep` on the LHE file often yields an incorrect value:
```bash
grep "Integrated weight (pb)" cmsgrid_final.lhe
# Output: Integrated weight (pb)  :  2.203485731033459e-11

```

This number usually represents only the *last individual subprocess* that was merged into the file, not the total cross-section of your signal.

## The Solution: `GenXSecAnalyzer`

To get the true integrated cross-section, you must parse the strict XML `<init>` block inside the `.root` file metadata. This can be done at the GENSIM, AODSIM, or MiniAOD stage, as CMSSW preserves the `GenRunInfoProduct` metadata across all steps.

### 1. The Extraction Script

Create a script named `get_xsec.py`. Ensure your CMSSW environment matches the release used to produce the input `.root` file to avoid forward-compatibility errors.

```python
import FWCore.ParameterSet.Config as cms

process = cms.Process("XSEC")

process.source = cms.Source("PoolSource",
    # Point this to ANY single completed GENSIM, AODSIM, or MiniAOD file
    fileNames = cms.untracked.vstring(
        'root://eosuser.cern.ch//eos/user/s/sasahoo/MC_Production/5f/HWZTo3L_5f/.../HWZTo3L_5f_Run3Summer24-MINIAODSIM_1.root'
    )
)

# Process all events to read the metadata
process.maxEvents = cms.untracked.PSet(input = cms.untracked.int32(-1))

process.xsec = cms.EDAnalyzer("GenXSecAnalyzer")
process.p = cms.Path(process.xsec)
process.schedule = cms.Schedule(process.p)

```

Run the script:

```bash
cmsRun get_xsec.py

```

### 2. A simple and general method

1. download the code snippet of the `genXsecAnalyzer`,
```CLI
curl https://raw.githubusercontent.com/cms-sw/genproductions/master/Utilities/calculateXSectionAndFilterEfficiency/genXsec_cfg.py -o genXSecAnalyzer_cfg.py
```
2. Obtain the miniAOD root file path
```CLI
dasgoclient --query="parent dataset=NANOAOD DATASET PATH"
```
```CLI
dasgoclient --query="file dataset=MINIAOW DATASET PATH" | head -n 1
```

3. execute the `cmsRun` commaand (make sure that the `CMSSW` version must be matched with the **MINIAOD** data structure
```CLI
cmsRun genXSecAnalyzer_cfg.py maxEvents=-1 inputFiles="root://xrootd-cms.infn.it//{root file path}"
```

### 3. Output and Interpretation

At the end of the `cmsRun` execution, you will see a summary block like this:

```text
------------------------------------
GenXsecAnalyzer:
------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
Overall cross-section summary 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Process        xsec_before [pb]        passed    nposw    nnegw    tried    nposw    nnegw      xsec_match [pb]            accepted [%]     event_eff [%]
0        8.932e-12 +/- 7.065e-14        61    61    0    61    61    0    8.932e-12 +/- 7.065e-14        100.0 +/- 0.0    100.0 +/- 0.0
1        8.216e-12 +/- 7.417e-14        58    58    0    58    58    0    8.216e-12 +/- 7.417e-14        100.0 +/- 0.0    100.0 +/- 0.0
2        9.797e-12 +/- 7.500e-14        64    64    0    64    64    0    9.797e-12 +/- 7.500e-14        100.0 +/- 0.0    100.0 +/- 0.0
3        9.792e-12 +/- 7.496e-14        67    67    0    67    67    0    9.792e-12 +/- 7.496e-14        100.0 +/- 0.0    100.0 +/- 0.0
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
Total        3.674e-11 +/- 1.474e-13        250    250    0    250    250    0    3.674e-11 +/- 1.474e-13        100.0 +/- 0.0    100.0 +/- 0.0
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Before matching: total cross section = 3.674e-11 +- 1.474e-13 pb
After matching: total cross section = 3.674e-11 +- 1.474e-13 pb
Matching efficiency = 1.0 +/- 0.0   [TO BE USED IN MCM]
Filter efficiency (taking into account weights)= (250) / (250) = 1.000e+00 +- 0.000e+00
Filter efficiency (event-level)= (250) / (250) = 1.000e+00 +- 0.000e+00    [TO BE USED IN MCM]

After filter: final cross section = 3.674e-11 +- 1.474e-13 pb
After filter: final fraction of events with negative weights = 0.000e+00 +- 0.000e+00
After filter: final equivalent lumi for 1M events (1/fb) = 2.722e+13 +- 1.126e+11

```

### Key Takeaways for Analysis

* **Sub-process Breakdown:** Processes `0` through `3` correspond directly to the specific `generate` and `add process` commands defined in the MadGraph `proc_card.dat`. CMSSW successfully parses and evaluates them independently.
* **The Golden Number:** The total **After filter: final cross section** (in this case, `3.674e-11 pb`) is the exact value that must be hardcoded into your analysis framework to calculate global event weights. It correctly sums all sub-processes.
* **Filter Efficiency:** A filter efficiency of `1.000e+00` confirms no events were rejected at the generator/Pythia level, preserving the raw MadGraph cross-section.
* **Negative Weights:** A `0.000e+00` fraction confirms a Leading Order (LO) generation with no negative NLO weights to manage.

```

```
