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

## History

This project is based on scripts found within [GSI-utils](https://github.com/NOAA-EMC/GSI-utils).
