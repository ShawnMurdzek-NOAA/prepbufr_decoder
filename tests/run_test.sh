
# Bash script to run the tests for prepbufr_decoder

# Why run prepbufr_decode_csv/prepbufr_encode_csv so many times? The goal is to
# compare BUFR CSVs to one another. Unfortunately, the message numbering gets
# changed by the program, so the first and second CSVs will differ. Thus, we
# must compare the second and third CSVs

################################################################################
# User-specified options
################################################################################

# Machine (can only those machines supported by prepbufr_decoder)
machine='JET'

# Inputs
bufr_in='./data/2023121312.rap_e.t12z.prepbufr.tm00'
diag_fmt='./data/diag_conv_%s_ges.2023121312.nc4'

# Location of bin directory
binDIR="`pwd`/../bin"
envDIR="`pwd`/../env"

# Option to delete temporary test directory after testing
clean=0

################################################################################
# Run Test
################################################################################

# First, check to make sure executables exist
echo "bin directory: ${binDIR}"
if [ -f ${binDIR}/prepbufr_decode_csv.x ] && [ -f ${binDIR}/prepbufr_encode_csv.x ]; then
  echo "Executables found!"
else
  echo "Executables do not exist. Please compile prepbufr_decoder using ../build.sh and try again"
  exit 1
fi

# Configure environment
source ${envDIR}/bufr_${machine,,}.env
case ${machine} in
"ORION")
  echo "Python testing environment not yet configured. Exiting..."
  exit 1
;;
"JET")
  module use -a /contrib/miniconda3/modulefiles
  module load miniconda3
  conda activate adb_graphics
  export PYTHONPATH=$PYTHONPATH:/mnt/lfs4/BMC/wrfruc/murdzek/src
esac

# Setup temporary testing directory
if [ -d ./tmp ]; then
  rm ./tmp/*
else
  mkdir tmp
fi
cp ${binDIR}/* ./tmp/
cp ${bufr_in} ./tmp/prepbufr
cp *.py ./tmp/
cd tmp

# Run prepbufr_decode_csv and prepbufr_encode_csv 3 times
suffix=(".ORIGINAL" ".INTERMEDIATE" "")
for i in ${!suffix[@]}; do

  echo
  echo "Running prepbufr_decode_csv (${i})..."
  ./prepbufr_decode_csv.x > prepbufr_decode_${i}.log
  err=$?
  if [ ${err} -ne 0 ]; then
    echo "error ${err} when running prepbufr_decode_csv.x (${i})"
    exit 2
  else
    echo "prepbufr_decode_csv.x completed successfully (${i})"
  fi 

  cp prepbufr prepbufr${suffix[i]}
  python open_close_csv.py prepbufr.csv
  echo
  echo "Running prepbufr_encode_csv (${i})..."
  ./prepbufr_encode_csv.x > prepbufr_encode_${i}.log
  err=$?
  if [ ${err} -ne 0 ]; then
    echo "error ${err} when running prepbufr_encode_csv.x (${i})"
    exit 3
  else
    echo "prepbufr_encode_csv.x completed successfully (${i})"
  fi 
  cp prepbufr.csv prepbufr.csv${suffix[i]}
  
done

# Compare prepbufr.csv files
# This test checks whether the any data is changed during the prepbufr_decode/prepbufr_encode 
# process. Success suggests that prepbufr_encode_csv is working properly. Another test is needed,
# however, to check that prepbufr_decode_csv is working properly
python open_close_csv.py prepbufr.csv
diff_lines=`diff prepbufr.csv prepbufr.csv.INTERMEDIATE | wc -l`
if [ ${diff_lines} -ne 0 ]; then
  echo "error: ${diff_lines} lines differ between prepbufr.csv and prepbufr.csv.INTERMEDIATE"
  exit 4
else
  echo "prepbufr CSV files are the same!"
fi

# Compare prepbufr.csv to GSI diag output
# This test checks whether prepbufr_decode_csv is working properly. Note that the GSI diag files
# might not be the best truth dataset. IODA output from JEDI should be used in the future.
python check_bufr_csv.py prepbufr.csv ../data/diag_conv_%s_ges.2023121312.nc4 > check_bufr_csv.log
err=$?
if [ err -ne 0 ]; then
  echo "error ${err} when running check_bufr_csv.py. Check check_bufr_csv.log for details"
  exit 5
else
  echo "No large differences detected between the prepbufr CSV and GSI diag files!"
fi

# Clean up
echo
echo "test completed successfully!!"
cd ..
if [ ${clean} -eq 1 ]; then
  rm -r ./tmp
fi
