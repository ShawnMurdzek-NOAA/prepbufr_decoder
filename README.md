# PrepBUFR Decoder and Encoder

Shawn Murdzek  
CIRES CU Boulder  
Embedded in NOAA/OAR/Global Systems Laboratory  
shawn.s.murdzek@noaa.gov  

## Decription

This repo contains two fortran programs for decoding prepBUFR files into CSVs and encoding CSVs into prepBUFR files.

## Building

Building the prepBUFR decoder and encoder requires the BUFR library. For supported machines, the programs can be compiled using the following (without having to configure the environment ahead of time):

`bash build.sh <MACHINE>`

The following machines are currently supported:

- HERCULES (spack-stack v1.5.1)
- JET (spack-stack v1.5.0)
- ORION (spack-stack v1.6.0)


To add a new machine, add a BUFR environment configuration file and a python environment configuration file (optional, only needed to run the tests) to the `env` directory.

## Testing

Before testing, the test data must be downloaded and linked (e.g., `ln -snf`) into the `tests/data` directory. Test data can be found on the MSU machines at `/work2/noaa/wrfruc/murdzek/src/bufr_test_data/prepbufr_decoder`. To test, run the following:

```
cd tests/
bash run_test.sh
```

See comments in `run_test.sh` for test details.

## History

This project is based on scripts found within [GSI-utils](https://github.com/NOAA-EMC/GSI-utils).
