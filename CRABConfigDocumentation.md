# CRAB3 Configuration setup dedicated to PrivateMC
## Core Setup

A CRAB3 configuration file is written in Python. It creates a `Configuration` object, which is then divided into distinct sections.

The most efficient way to initialize the skeleton is using the pre-defined utility:

```python
from CRABClient.UserUtilities import config
config = config()

```

---

## 1. General Section (`config.General`)

Handles metadata about the task itself, such as what to call it and what to do with the outputs.

* **`requestName`** (*String*): The name of your task. CRAB creates a project directory named `crab_<requestName>`. (Max 100 characters).
* **`workArea`** (*String*): The directory where the `crab_<requestName>` folder will be created. Defaults to your current working directory.
* **`transferOutputs`** (*Boolean*): Whether to transfer output files to your `storageSite`. Defaults to `True`.
* **`transferLogs`** (*Boolean*): Whether to transfer the job log files to your `storageSite`. Defaults to `False`.
* **`instance`** (*String*): The CRAB server instance. Always use `'prod'` for standard user tasks.

## 2. JobType Section (`config.JobType`)

Defines the technical requirements of the worker node and the CMSSW environment.

* **`pluginName`** (*String*): Set to `'Analysis'` when running over existing data (like your RECO step), or `'PrivateMC'` for event generation from scratch.
* **`psetName`** (*String*): The name of your CMSSW python configuration file (e.g., `'HWZ_4f_RECO_cfg.py'`).
* **`maxMemoryMB`** (*Integer*): Maximum RAM requested per job. Defaults to 2000. (Note: Requesting >2500 MB can delay your jobs as they wait for high-memory nodes).
* **`numCores`** (*Integer*): Number of CPU cores requested per job. Defaults to 1.
* **`maxJobRuntimeMin`** (*Integer*): The wall-clock time limit per job in minutes. Defaults to 1315 (~21 hours).

## 3. Data Section (`config.Data`)

Controls how CRAB reads inputs, splits the workload, and names the final outputs.

### Reading Data

* **`inputDataset`** (*String*): The official DBS dataset name to process.
* **`inputDBS`** (*String*): The DBS instance to read from. Use `'global'` for official datasets or `'phys03'` for private user datasets.
* **`userInputFiles`** (*List of Strings*): Bypasses DBS completely to process specific files directly. Can accept LFNs (`/store/user/...`) or direct XRootD PFNs (`root://eosuser.cern.ch//eos/user/...`).
* **`ignoreLocality`** (*Boolean*): *TWiki warns: DO NOT USE.* (Though sometimes required by experts to force jobs to run away from the data source).

### Splitting the Workload

* **`splitting`** (*String*): The algorithm CRAB uses to divide the events among jobs.
* `'FileBased'`: Best when using `userInputFiles`.
* `'LumiBased'` / `'EventAwareLumiBased'`: Standard for processing data/MC datasets.
* `'EventBased'`: Required when `pluginName = 'PrivateMC'`.
* `'Automatic'`: CRAB dynamically splits jobs to aim for a specific runtime.


* **`unitsPerJob`** (*Integer*): How many files, lumis, or events (depending on your splitting choice) go to a single job.
* **`totalUnits`** (*Integer*): The absolute total number of units to process. Mandatory for `PrivateMC`.

### Writing Data

* **`outLFNDirBase`** (*String*): The base directory on your storage site where files will land (e.g., `'/store/user/<username>/MC_Production'`).
* **`outputPrimaryDataset`** (*String*): Required if using `userInputFiles` or `PrivateMC`. Dictates the first part of the output dataset name.
* **`outputDatasetTag`** (*String*): The custom string appended to your final dataset name (e.g., `'Run3_2024_4f_DIGI_prod'`).
* **`publication`** (*Boolean*): Whether to register the output in the CMS database. Set to `True` if you need to feed this output into a subsequent CRAB step using `inputDataset`.
* **`publishDBS`** (*String*): Always `'phys03'` for user data.

## 4. Site Section (`config.Site`)

Controls the geographic location of your computation and storage.

* **`storageSite`** (*String*): **[MANDATORY]** The final resting place for your data. You must have write permissions here (e.g., `'T3_CH_CERNBOX'` or `'T2_IN_TIFR'`).
* **`whitelist`** (*List of Strings*): Forces jobs to execute *only* at these computing sites (e.g., `['T2_CH_CERN']`). Mandatory if using `userInputFiles` since CRAB cannot auto-locate the data.
* **`blacklist`** (*List of Strings*): Prevents jobs from running at specific problematic sites.

## Command Line Overrides

You do not have to edit the Python file for every minor change. You can override string, integer, or boolean parameters directly in the terminal during submission:

```bash
crab submit -c crabConfig.py General.requestName=my_test_v2 Data.unitsPerJob=5

```

---