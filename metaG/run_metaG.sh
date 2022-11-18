#!/bin/bash
# Janno Peilert, Nov 2022
# Run MetaG as batch, add SLURM
# based on MetaG by Arno Kappe et al. (https://github.com/ArnoKappe/MetaG)

# Setup SLURM using data parsed from config.yaml
source "$WOCHENENDE_DIR"/scripts/parse_yaml.sh
eval $(parse_yaml "$WOCHENENDE_DIR"/config.yaml)
# Setup job scheduler
# use SLURM job scheduler (yes, no)
if [[ "${USE_CUSTOM_SCHED}" == "yes" ]]; then
    scheduler=$CUSTOM_SCHED_CUSTOM_PARAMS #_SINGLECORE
fi
if [[ "${USE_SLURM}" == "yes" ]]; then
    scheduler=$SLURM_CUSTOM_PARAMS #_SINGLECORE
fi

echo "INFO: Starting MetaG"
echo "INFO: Current directory: $(pwd)"
# if growth rate directory is missing, MetaG will not start
if [[ ! -d "../growth_rate" ]]
then
    echo "ERROR: Growth rate directory missing. MetaG won't be started"
    exit 1
fi
# if no directories with _subsamples were found, MetaG will not start
count_subdic=$(find ../growth_rate/*subsamples/ -maxdepth 0 -type d 2>/dev/null | wc -l)
if [[ "$count_subdic" -eq 0 ]]
then
  echo "ERROR: No _subsamples directories were found in /growth_rate. MetaG won't be started"
  exit 1
fi
echo "INFO: Directories to process found: $count_subdic"

# enter growth_rate directory
cd ../growth_rate/ || { echo -e "ERROR: Can't enter /growth_rate \nERROR: Terminating MetaG" && exit 2; }

# primary loop for executing MetaG, starts it for every subdirectory
for d in *_subsamples/; do
    echo "INFO: Starting MetaG for $d"

    # enter subdirectory
    cd ./"$d" || { pwd ; echo -e "ERROR: Can't enter $d \nERROR: Terminating MetaG" && exit 2; }

    # checks number of csv files in subdirectory
    count_csv=$( find ./ -type f -name '*.csv' | wc -l )
    if [ "$count_csv" -eq "0" ]
    then
      echo -e "WARNING: Couldn't find .csv files. Skipping this directory"
      # exit subfolder
      cd .. || { echo -e "ERROR: Can't escape subdirectory \nERROR: Terminating MetaG" && exit 2; }
      echo
      continue
    else
      echo "INFO: Found $count_csv .csv files"
    fi

    pwd_dir=$(pwd)

    # copies MetaG.properties to current folder
    cp ../../metaG/image/bin/MetaG.properties .

    # changes path in MetaG.properties to current folder
    sed -i "4s#.*#DIRECTORY=$pwd_dir#" ./MetaG.properties


    # create valid name for log-file
    echo "metaG_log_$d.log" > temp.metaG
    # deletes /
    log_file_name=$(sed 's/\///g' temp.metaG)
    rm temp.metaG

    # executes MetaG, if you get errors regarding java, comment out the scheduler command with a #
    # and remove # before the bash command
    $scheduler --job-name=metaG bash ../../metaG/image/bin/MetaG &> "$log_file_name"
    #bash ../../metaG/image/bin/MetaG &> "$log_file_name"

    # TODO: Move loop back when bug with \ and / is solved
    # simplify output/ make output more readable
    # all MetaG analysis txt files in subdirectory
    cd ..   #temp
    for f in *_MetaG_analysis_*.txt; do
        # check if files were found
        if [ "$f" = "*_MetaG_analysis_*.txt" ]
        then
                echo "ERROR: No MetaG Analysis file found"
                continue
        fi

        echo "INFO: Simplifying on $f"

        if [[ $f == "cutted_"* ]]
        then
          echo "INFO: This file seems to be cutted already. Skipping this file"
          continue
        fi

        # cutting path and everything after scientific name
        sed -E 's/.*[^_]_([A-Z][a-z]{2,}_[a-z]{2,})_[^\/]*\.csv/\1/g' "$f" > cutted_"$f"

    done
    cd ./"$d" #temp

    # exit subfolder
    cd .. || { echo -e "ERROR: Can't escape subdirectory \nERROR: Terminating MetaG" && exit 2; }
    echo
done
