import os
import glob
from CRABClient.UserUtilities import config

# Make sure to change the path
path = "/eos/user/s/sasahoo/MC_Production/5f/HWZTo3L_5f_TuneCP5_13p6TeV_madgraph-pythia8/Run3Summer24-DRPremix-140X_mcRun3_2024_realistic_v26-v2/260722_100200/0000/"
xrootd = "root://eosuser.cern.ch/"

local_files = glob.glob(os.path.join(path, '*.root'))
xrootd_paths = [xrootd + path for path in local_files]

config = config()

config.General.requestName = 'HWZ_5f_RECO_AODSIM_Run3Summer24_v1'
config.General.workArea = 'crab_projects'
config.General.transferOutputs = True
config.General.transferLogs = True

config.JobType.pluginName = 'Analysis'
config.JobType.psetName = 'HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_RECO_AODSIM_cfg.py'
config.JobType.maxMemoryMB = 5500
config.JobType.numCores = 2

config.Data.userInputFiles = xrootd_paths

config.Data.outputPrimaryDataset = 'HWZTo3L_5f_TuneCP5_13p6TeV_madgraph-pythia8'
config.Data.splitting = 'FileBased'
config.Data.unitsPerJob = 1
config.Data.outLFNDirBase = '/store/user/sasahoo/MC_Production/5f/'
config.Data.publication = True
config.Data.outputDatasetTag = 'Run3Summer24-AODSIM-140X_mcRun3_2024_realistic_v26-v1'

config.Site.storageSite = 'T3_CH_CERNBOX'
config.Site.whitelist = ['T2_CH_CERN']
