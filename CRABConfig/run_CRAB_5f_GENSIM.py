from CRABClient.UserUtilities import config
config = config()

config.General.requestName = 'HWZ_5f_GENSIM_Run3Summer24_v1'
config.General.workArea = 'crab_projects'
config.General.transferOutputs = True
config.General.transferLogs = True

config.JobType.pluginName = 'PrivateMC'
config.JobType.psetName = 'HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_GENSIM_cfg.py'
config.JobType.inputFiles = ['/afs/cern.ch/user/s/sasahoo/genproduction/gridpacks/5f/TSM_HWZ_el9_amd64_gcc11_CMSSW_13_2_9_tarball.tar.xz']
config.JobType.maxMemoryMB = 2500
config.JobType.numCores = 1

config.Data.outputPrimaryDataset = 'HWZTo3L_5f_TuneCP5_13p6TeV_madgraph-pythia8'
config.Data.splitting = 'EventBased'
config.Data.unitsPerJob = 250
config.Data.totalUnits = 100000

config.Data.outLFNDirBase = '/store/user/sasahoo/MC_Production/5f/'
config.Data.publication = True
config.Data.outputDatasetTag = 'Run3Summer24-GENSIM-140X_mcRun3_2024_realistic_v26-v1'

config.Site.storageSite = 'T3_CH_CERNBOX'


'''
User command "crab submic -c HWZTo3L_5f_TuneCP5_13p6TeV_madgraph_LO_GENSIM_cfg.py"

For unsuccessful part do resubmit
"crab resubmit -d crab_projects/HWZ_5f_GENSIM_Run3Summer24_v1 --maxmemory=4500"
'''