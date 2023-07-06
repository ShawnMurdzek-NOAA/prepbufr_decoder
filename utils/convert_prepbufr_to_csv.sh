#!/bin/sh

#SBATCH -A wrfruc
#SBATCH -t 08:00:00
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
last=2022020200

# Directory containing prepbufr files
prepbufr_dir='/work2/noaa/wrfruc/murdzek/real_obs/obs_rap_prepbufr'

# Directory to place prepbufr CSV files
csv_dir='/work2/noaa/wrfruc/murdzek/real_obs/obs_rap_csv'

# All the different rap tags
all_tags=( 'rap' 'rap_e' 'rap_p' )

# Alternate input parameters: Specify prepbufr file names
specify_filenames=false
in_files=( '2022020100.rap.t00z.prepbufr.tm00' )
out_files=( '202202010000.rap.prepbufr.csv' )

#-------------------------------------------------------------------------------

case ${machine} in
'ORION')
  source ${env_dir}/bufr_orion.env
esac

cd ${bin_dir}

if ${specify_filenames}; then

  for i in ${!in_files[@]}; do
    echo "creating CSV file for ${in_files[i]}"
    cp ${prepbufr_dir}/${in_files[i]} ${bin_dir}/prepbufr
    ${bin_dir}/prepbufr_decode_csv.x
    mv ${bin_dir}/prepbufr.csv ${csv_dir}/${out_files[i]}
    rm ${bin_dir}/prepbufr
  done

else

  current=${first}
  while [ ${current} -le ${last} ]; do

    echo "creating CSV file for ${current}"
    hr=${current:8:2}

    for tag in ${all_tags[@]}; do 
      if [ -e ${prepbufr_dir}/${current}.${tag}.t${hr}z.prepbufr.tm00 ]; then 
        cp ${prepbufr_dir}/${current}.${tag}.t${hr}z.prepbufr.tm00 ${bin_dir}/prepbufr
        ${bin_dir}/prepbufr_decode_csv.x
        mv ${bin_dir}/prepbufr.csv ${csv_dir}/${current}00.${tag}.prepbufr.csv
        rm ${bin_dir}/prepbufr
      fi
    done

    current=`date '+%Y%m%d%H' --date="${current::8} ${current:8:2}00 1 hour"`
  done
fi
