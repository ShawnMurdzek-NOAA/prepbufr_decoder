
# Bash script to run the tests for prepbufr_decoder

# Why run prepbufr_decode_csv/prepbufr_encode_csv so many times? The goal is to
# compare BUFR CSVs to one another. Unfortunately, the message numbering gets
# changed by the program, so the first and second CSVs will differ. Thus, we
# must compare the second and third CSVs

################################################################################
# User-specified options
################################################################################

# Machine (can only use those machines supported by prepbufr_decoder)
machine='ORION'

# Inputs
bufr_in='./data/2023121312.rap_e.t12z.prepbufr.tm00'
bufr_truth='./data/2023121312.rap_e.t12z.prepbufr.tm00.OUTPUT.TRUTH'  # Created using hash 48728b3
diag_fmt='./data/diag_conv_%s_ges.2023121312.nc4'

# Location of bin directory
binDIR="`pwd`/../bin"
envDIR="`pwd`/../env"

# Option to delete temporary test directory after testing
clean=1

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

# BUFR and python environment files
bufr_env=${envDIR}/bufr_${machine,,}.env
py_env=${envDIR}/py_${machine,,}.env

# Setup temporary testing directory
if [ -d ./tmp ]; then
  rm ./tmp/*
else
  mkdir tmp
fi
cp ${binDIR}/* ./tmp/
cp ${bufr_in} ./tmp/prepbufr
cp ${bufr_truth} ./tmp/prepbufr.TRUTH
cp *.py ./tmp/
cd tmp

# Run prepbufr_decode_csv
echo
echo "Running prepbufr_decode_csv..."
source ${bufr_env}
./prepbufr_decode_csv.x > prepbufr_decode_1.log
err=$?
if [ ${err} -ne 0 ]; then
  echo "error ${err} when running prepbufr_decode_csv.x"
  exit 2
else
  echo "prepbufr_decode_csv.x completed successfully"
fi 

# Run prepbufr_encode_csv
mv prepbufr prepbufr.ORIGINAL
source ${py_env}
python open_close_csv.py prepbufr.csv
echo
echo "Running prepbufr_encode_csv..."
source ${bufr_env}
./prepbufr_encode_csv.x > prepbufr_encode_1.log
err=$?
if [ ${err} -ne 0 ]; then
  echo "error ${err} when running prepbufr_encode_csv.x"
  exit 2
else
  echo "prepbufr_encode_csv.x completed successfully"
fi 

# Run prepbufr_decode_csv (second time)
mv prepbufr.csv prepbufr.csv.ORIGINAL
echo
echo "Running prepbufr_decode_csv (second time)..."
source ${bufr_env}
./prepbufr_decode_csv.x > prepbufr_decode_2.log
err=$?
if [ ${err} -ne 0 ]; then
  echo "error ${err} when running prepbufr_decode_csv.x (second time)"
  exit 2
else
  echo "prepbufr_decode_csv.x completed successfully (second time)"
fi 

# Run prepbufr_encode_csv (second time)
mv prepbufr prepbufr.INTERMEDIATE
source ${py_env}
python open_close_csv.py prepbufr.csv
echo
echo "Running prepbufr_encode_csv (second time)..."
source ${bufr_env}
./prepbufr_encode_csv.x > prepbufr_encode_2.log
err=$?
if [ ${err} -ne 0 ]; then
  echo "error ${err} when running prepbufr_encode_csv.x (second time)"
  exit 2
else
  echo "prepbufr_encode_csv.x completed successfully (second time)"
fi 

# Run prepbufr_decode_csv (third time)
mv prepbufr.csv prepbufr.csv.INTERMEDIATE
echo
echo "Running prepbufr_decode_csv (third time)..."
source ${bufr_env}
./prepbufr_decode_csv.x > prepbufr_decode_3.log
err=$?
if [ ${err} -ne 0 ]; then
  echo "error ${err} when running prepbufr_decode_csv.x (third time)"
  exit 2
else
  echo "prepbufr_decode_csv.x completed successfully (third time)"
fi

# Compare prepbufr.csv files
# This test checks whether the any data is changed during the prepbufr_decode/prepbufr_encode 
# process. Success suggests that prepbufr_encode_csv is working properly. Another test is needed,
# however, to check that prepbufr_decode_csv is working properly
source ${py_env}
python open_close_csv.py prepbufr.csv
diff_lines=`diff prepbufr.csv prepbufr.csv.INTERMEDIATE | wc -l`
if [ ${diff_lines} -ne 0 ]; then
  echo "error: ${diff_lines} lines differ between prepbufr.csv and prepbufr.csv.INTERMEDIATE"
  exit 3
else
  echo "prepbufr CSV files are the same!"
fi

# Compare prepbufr files
# This test compares prepbufr output from prepbufr_encode_csv to a "truth" prepbufr file.
# This test checks whether the prepbufr files are identical, so it may fail if there are small
# differences. Thus, failing this test does not return an error.
diff_lines=`diff  prepbufr.INTERMEDIATE prepbufr.TRUTH | wc -l`
if [ ${diff_lines} -ne 0 ]; then
  echo "error: prepbufr.INTERMEDIATE and prepbufr.TRUTH are not identical"
else
  echo "prepbufr files are the same!"
fi


# Compare prepbufr.csv to GSI diag output
# This test checks whether prepbufr_decode_csv is working properly. Note that the GSI diag files
# might not be the best truth dataset. IODA output from JEDI should be used in the future.
python check_bufr_csv.py prepbufr.csv ../data/diag_conv_%s_ges.2023121312.nc4 > check_bufr_csv.log
err=$?
if [ ${err} -ne 0 ]; then
  echo "error ${err} when running check_bufr_csv.py. Check check_bufr_csv.log for details"
  exit 3
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
