# PrepBUFR Decoder and Encoder

Shawn Murdzek  
NOAA/OAR/Global Systems Laboratory  
shawn.s.murdzek@noaa.gov  

## Decription

This repo contains two fortran programs for decoding prepBUFR files into CSVs and encoding CSVs into prepBUFR files.

## Building

Building the prepBUFR decoder and encoder requires the BUFR library. For supported machines, the programs can be compiled using the following (without having to configure the environment ahead of time):

`bash build.sh <MACHINE>`

The following machines are currently supported:

- ORION (hpc-stack v1.1.0)
- JET (spack-stack v1.5.0)

To add a new machine, add an environment configuration file to the `env` directory and add the machine and environment configuration file combination to the case block in build.sh.

## Testing

Before testing, the test data must be downloaded and linked (e.g., `ln -snf`) into the `tests/data` directory. Test data can be found on the MSU machines at `/work2/noaa/wrfruc/murdzek/src/bufr_test_data/prepbufr_decoder`. To test, run the following:

```
cd tests/
bash run_test.sh
```

See comments in `run_test.sh` for test details.

## History

This project is based on scripts found within [GSI-utils](https://github.com/NOAA-EMC/GSI-utils).
