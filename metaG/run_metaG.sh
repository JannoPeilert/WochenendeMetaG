#!/bin/bash
# Janno Peilert, Nov 2022
# Run MetaG as batch, add SLURM


# Setup SLURM using data parsed from config.yaml
source "$WOCHENENDE_DIR"/scripts/parse_yaml.sh
eval $(parse_yaml "$WOCHENENDE_DIR"/config.yaml)
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
    cd ./"$d" || { echo -e "ERROR: Can't enter $d \nERROR: Terminating MetaG" && exit 2; }
    pwd_dir=$(pwd)

    # copies MetaG.properties to current folder
    cp ../../metaG/image/bin/MetaG.properties .

    # changes path in MetaG.properties to current folder
    sed -i "4s#.*#DIRECTORY=$pwd_dir#" ./MetaG.properties

    # executes MetaG
    #sbatch -p normal -c 12 --job-name=metaG ../../metaG/image/bin/MetaG # not functioning
    echo "INFO: Starting MetaG for $d"

    # create valid name for log-file
    echo "metaG_log_$d.log" > temp.metaG
    # deletes /
    log_file_name=$(sed 's/\///g' temp.metaG)
    rm temp.metaG

    bash ../../metaG/image/bin/MetaG &> "$log_file_name"



    # exit subfolder
    cd .. || { echo -e "ERROR: Can't escape subdirectory \nERROR: Terminating MetaG" && exit 2; }
    echo
done

# TODO: Move loop back when bug with \ and / is solved
# simplify output/ make output more readable
    # all .txt files in subdirectory
    for f in *_MetaG_analysis_*.txt; do
        # check if files were found
        if [ "$f" = "*_MetaG_analysis_*.txt" ]
        then
                echo "ERROR: Not MetaG-Analysis-files found"
                break
        fi

        echo "INFO: Simplifying on $f"
        # soft cutting (careful cutting):
        # deletes in every line everything until inclusive "_1_" | removes "__complete_genome_BAC_pos.csv" | removes "_chromosome"
        #perl -p -e 's/^.*?_1_//' $f | sed 's/__complete_genome_BAC_pos.csv//g' |
        #sed 's/_chromosome//g' | sed 's/_...\t/\t/'| sed -E 's/(_strain)?(_[A-Z]{2,}[0-9]*)?//g' > tmpfile"$f" && mv tmpfile"$f" "$f"

        # hard cutting (may cause unexpected behavior)
        sed 's/.*_[0-9]_//g' "$f" | sed -E 's/(_strain)?_[A-Z]+.*\.csv//g' > tmpfile"$f" && mv tmpfile"$f" "$f"
    done

