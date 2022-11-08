#!/bin/bash
# Janno Peilert, Nov 2022
# Run MetaG as batch, add SLURM


# Setup SLURM using data parsed from config.yaml
source $WOCHENENDE_DIR/scripts/parse_yaml.sh
eval $(parse_yaml $WOCHENENDE_DIR/config.yaml)
# Setup job scheduler
# use SLURM job scheduler (yes, no)
if [[ "${USE_CUSTOM_SCHED}" == "yes" ]]; then
    #echo USE_CUSTOM_SCHED set"
    scheduler=$CUSTOM_SCHED_CUSTOM_PARAMS       #_SINGLECORE
fi
if [[ "${USE_SLURM}" == "yes" ]]; then
    #echo USE_SLURM set"
    scheduler=$SLURM_CUSTOM_PARAMS              #_SINGLECORE
fi

echo "Starting MetaG"

# if growth rate directory is missing, MetaG will not start
if [[ ! -d "../growth_rate" ]]
then
    echo "ERROR: Growth rate directory missing. MetaG won't be started"
    exit
fi
# if no directories with _subsamples were found, MetaG will not start
count_subdic=$(ls -1 ../*_subsamples 2>/dev/null | wc -l)
if [[ -z "$count_subdic" ]]
then
  echo "ERROR: No _subsamples directories were found. MetaG won't be started"
  exit
fi

# update path of .csv's in MetaG.properties
#SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) # returns path of this script

# enter growth_rate directory
cd ../growth_rate/ #2>/dev/null

# primary loop for executing MetaG, starts it for every subdirectory
for d in *_subsamples/; do
    cd ./"$d"
    pwd_dir=$(pwd)

    # copys MetaG.properties to current folder
    cp ../../metaG/image/bin/MetaG.properties .

    # changes path in MetaG.properties to current folder
    sed -i "4s#.*#DIRECTORY=$pwd_dir#" ./MetaG.properties

    #head -4 ./MetaG.properties|tail -1 # gives line with directory path

    # executes MetaG
    bash ../../metaG/image/bin/MetaG

    cd ..
    echo
done


echo "Finished  MetaG"

