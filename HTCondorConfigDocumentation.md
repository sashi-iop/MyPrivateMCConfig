# HTCondor Guide to manage PrivateMC Jobs

While CRAB manages global grid distribution, HTCondor manages local batch processing at CERN. It is ideal for jobs that read and write directly to your local EOS (`T3_CH_CERNBOX`) and do not require CMS database (DBS) publication.

---

## 1. The Execution Script (`.sh`)

HTCondor does not inherently know about CMS. You must provide a standard bash script that manually sets up your CMSSW environment and executes your code, exactly as you would type it in the terminal.

**Example: `run_nano.sh**`

```bash
#!/bin/bash
# 1. Navigate to your specific CMSSW release area
cd /eos/home-s/sasahoo/MC_Production/4f/CMSSW_15_0_2/src

# 2. Source the CMS environment
eval `scramv1 runtime -sh`

# 3. Execute the physics configuration
cmsRun HWZ_4f_MiniAOD_cfg.py
cmsRun HWZ_4f_NanoAOD_cfg.py

```

* **Permissions:** You must make this script executable before submitting it by running `chmod +x run_nano.sh`.

---

## 2. The Submission File (`.sub`)

This is the configuration file that tells HTCondor how to run your execution script, where to save the logs, and how much time to allocate.

**Example: `submit.sub**`

```condor
executable            = run_nano.sh
output                = logs/job_$(ClusterId)_$(ProcId).out
error                 = logs/job_$(ClusterId)_$(ProcId).err
log                   = logs/job_$(ClusterId).log
+JobFlavour           = "workday"
queue 1

```

### Core Parameters

* **`executable`** (*String*): The path to your bash script.
* **`output`** (*String*): Where to save the standard output (everything that would normally print to the terminal, like `cmsRun` progress).
* **`error`** (*String*): Where to save the standard error stream (crashes, Python tracebacks).
* **`log`** (*String*): The HTCondor system log. This tracks when the job was queued, started, and finished (or if it was killed by the system).
* **`queue`** (*Integer*): How many times to submit this exact job. For a simple conversion script, use `queue 1` (or just `queue`).

### Variables

Notice the use of `$(ClusterId)` and `$(ProcId)`. If you submit multiple jobs, Condor automatically replaces these variables with unique ID numbers so your log files do not overwrite each other.

---

## 3. CERN Job Flavours (Time Limits)

Unlike CRAB where you specify `maxJobRuntimeMin`, CERN's HTCondor system uses predefined "Job Flavours." If your job exceeds the time limit of the requested flavour, the system forcefully kills it.

You set this using the **`+JobFlavour = "flavour_name"`** parameter.

| Flavour Name | Maximum Wall-Clock Time | Best Used For |
| --- | --- | --- |
| `"espresso"` | 20 minutes | Quick tests, compilation, tiny datasets |
| `"microcentury"` | 1 hour | Fast skims, flat ntuple generation |
| `"longlunch"` | 2 hours | Medium-sized NanoAOD processing |
| `"workday"` | 8 hours | **Standard MiniAOD/NanoAOD conversions** |
| `"tomorrow"` | 1 day | Heavy analysis scripts |
| `"testmatch"` | 3 days | (Avoid unless necessary) |
| `"nextweek"` | 7 days | Absolute maximum limit at CERN |

*Note: Shorter flavours wait in the queue for less time. Requesting `"workday"` for a 5-minute task is inefficient because you will wait longer for a worker node.*

---

## 4. Essential HTCondor Commands

You interact with HTCondor directly from your standard `lxplus` terminal.

### Submitting

* **`condor_submit submit.sub`**: Submits your job to the cluster. It will return a `ClusterId` (e.g., `1234567`).

### Monitoring

* **`condor_q`**: Shows the status of all your current jobs.
* **IDLE (I):** Waiting for a worker node.
* **RUNNING (R):** Currently executing.
* **HELD (H):** The job encountered a system error (e.g., ran out of memory or could not find the executable) and is paused.


* **`condor_q -better-analyze 1234567`**: If your job is stuck in IDLE or HELD, this command provides a detailed diagnostic reason why.

### Managing

* **`condor_rm 1234567`**: Kills a specific job by its Cluster ID.
* **`condor_rm $USER`**: Instantly kills every HTCondor job you currently have running or queued.