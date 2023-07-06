#! /bin/sh

# Script to build the PrepBUFR decoder and encoder

# Passed arguments: 
#     1 - Machine (options = ORION)

machine=$1
echo "machine: ${machine}"
echo

# Load proper environment
case ${machine} in
"ORION")
  source ./env/bufr_orion.env
esac

# Build programs
names=(prepbufr_decode_csv.f90 prepbufr_encode_csv.f90)
error=0
for n in ${names[@]}; do
  echo "program = ${n}"
  ifort ./src/${n} -o ./bin/${n}.x -L${bufr_ROOT}/lib64 -lbufr_d
  tmp=$?
  if [ ${tmp} -gt ${error} ]; then
    error=${tmp}
  fi
done 

echo
if [ ${error} -gt 0 ]; then
  echo "compilation failed, error code = ${error}"
else
  echo "compilation successful"
fi
