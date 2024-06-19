#! /bin/sh

# Script to build the PrepBUFR decoder and encoder

# Passed arguments: 
#     1 - Machine (options = ORION, JET, HERCULES)

machine=$1
echo "machine: ${machine}"
echo

# Load proper environment
case ${machine} in
"ORION")
  source ./env/bufr_orion.env
  bufr_lib=bufr_4   # bufr from spack-stack
;;
"HERCULES")
  source ./env/bufr_hercules.env
  bufr_lib=bufr_4   # bufr from spack-stack
;;
"JET")
  source ./env/bufr_jet.env
  bufr_lib=bufr_4   # bufr/12.0.0 (in spack-stack v1.5.0)
;;
"")
  echo "no machine specified. Compilation will fail if environment is not already configured"
  echo
esac

module list

# Build programs
names=(prepbufr_decode_csv prepbufr_encode_csv)
error=0
for n in ${names[@]}; do
  echo "program = ${n}"
  ifort ./src/${n}.f90 -o ./bin/${n}.x -L${bufr_ROOT}/lib64 -l${bufr_lib}
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
