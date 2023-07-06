#!/bin/sh

#SBATCH -A wrfruc
#SBATCH -t 06:00:00
#SBATCH --ntasks=1
#SBATCH --partition=orion

# Convert prepbufr files to CSVs that can be read by Python

# Machine (options = ORION)
machine='ORION'

# bin directory within prepbufr_decoder
bin_dir='../bin'

# environment directory within prepbufr_decoder
env_dir='../env'

# First and last BUFR times (YYYYMMDDHH)
first=2022020100
last=2022020112

# Directory containing CSV files
csv_dir='/work2/noaa/wrfruc/murdzek/nature_run_winter/synthetic_obs_csv/perfect_conv/data'

# Directory to place prepbufr files
prepbufr_dir='/work2/noaa/wrfruc/murdzek/nature_run_winter/synthetic_obs_bufr'

# All the different rap tags
all_tags=( 'rap' 'rap_e' 'rap_p' )

# Tag for real or fake obs
ob_type='fake'

#-------------------------------------------------------------------------------

case ${machine} in
'ORION')
  source ${env_dir}/bufr_orion.env
esac

cd ${bin_dir}
pwd

current=${first}
while [ ${current} -le ${last} ]; do

  echo "creating prepbufr file for ${current}"
  hr=${current:8:2}

  for tag in ${all_tags[@]}; do 
    if [ -e ${csv_dir}/${current}00.${tag}.${ob_type}.prepbufr.csv ]; then 
      cp ${csv_dir}/${current}00.${tag}.${ob_type}.prepbufr.csv ./prepbufr.csv
      ./prepbufr_encode_csv.x
      mv ./prepbufr ${prepbufr_dir}/${current}.${tag}.t${hr}z.prepbufr.tm00
      rm ./prepbufr.csv
    fi
  done

  current=`date '+%Y%m%d%H' --date="${current::8} ${current:8:2}00 1 hour"`
done
