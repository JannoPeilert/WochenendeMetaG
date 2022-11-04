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
    scheduler=$CUSTOM_SCHED_CUSTOM_PARAMS_SINGLECORE
fi
if [[ "${USE_SLURM}" == "yes" ]]; then
    #echo USE_SLURM set"
    scheduler=$SLURM_CUSTOM_PARAMS_SINGLECORE
fi

# if growth rate directory is missing, MetaG will not start
if [[ ! -d "../growth_rate" ]]
then
    echo "ERROR: Growth rate directory missing. MetaG won't be started"
    exit
fi

# Save output log in directory containing bams and preprocess script
output_log="plot_"$(date +%s)".log"
echo "INFO: output_log: " $output_log

echo "Finished  MetaG"

