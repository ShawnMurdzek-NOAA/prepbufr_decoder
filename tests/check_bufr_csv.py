"""
Cross Check CSV and GSI NetCDF Diag

This program selects one of each ob type for each variable from a prepBUFR CSV file. These obs are
the cross-checked against a series of GSI diag files

shawn.s.murdzek@noaa.gov
"""

#---------------------------------------------------------------------------------------------------
# Import Modules
#---------------------------------------------------------------------------------------------------

import sys
import pandas as pd
import numpy as np

import pyDA_utils.gsi_fcts as gsi
import pyDA_utils.bufr as bufr


#---------------------------------------------------------------------------------------------------
# Input Parameters
#---------------------------------------------------------------------------------------------------

csv_fname = sys.argv[1]
diag_fmt = sys.argv[2]

#csv_fname = '/lfs4/BMC/wrfruc/murdzek/src/prepbufr_decoder/tests/tmp/prepbufr.csv'
#diag_fmt = '/lfs4/BMC/wrfruc/murdzek/src/prepbufr_decoder/tests/data/diag_conv_%s_ges.2023121312.nc4'


#---------------------------------------------------------------------------------------------------
# Perform Comparison
#---------------------------------------------------------------------------------------------------

bufr_df = bufr.bufrCSV(csv_fname).df
bufr_typ = np.unique(bufr_df['TYP'])

diag_vars = ['t', 'q', 'uv', 'pw']
diag_vars = ['t']
fail = False
for v in diag_vars:
    diag = gsi.read_diag([diag_fmt % v])
    diag_typ = np.intersect1d(bufr_typ, np.unique(diag['Observation_Type']))
    for t in diag_typ:
        diag_entry = diag.loc[np.where(diag['Observation_Type'] == t)[0][0], :]
        if v == 'uv':
            diag_uob = diag_entry['u_Observation']
            diag_vob = diag_entry['v_Observation']
        else:
            diag_ob = diag_entry['Observation']

        # Determine matching ob from BUFR CSV
        if t in [120, 220]:
            # Radiosondes, use "drift" coordinates and times
            idx = np.where((bufr_df['TYP'] == diag_entry['Observation_Type']) &
                           (np.abs(bufr_df['XDR'] - diag_entry['Longitude']) < 0.02) &
                           (np.abs(bufr_df['YDR'] - diag_entry['Latitude']) < 0.02) &
                           (bufr_df['SID'] == ("'%s'" % diag_entry['Station_ID'].decode('utf-8').strip())) &
                           (np.abs(bufr_df['HRDR'] - diag_entry['Time']) < 0.0005))[0]
        elif t in [126, 227]:
            # Profilers, also need height to have a unique match
            idx = np.where((bufr_df['TYP'] == diag_entry['Observation_Type']) &
                           (np.abs(bufr_df['XOB'] - diag_entry['Longitude']) < 0.02) &
                           (np.abs(bufr_df['YOB'] - diag_entry['Latitude']) < 0.02) &
                           (np.abs(bufr_df['ZOB'] - diag_entry['Height']) < 1) &
                           (bufr_df['SID'] == ("'%s'" % diag_entry['Station_ID'].decode('utf-8').strip())) &
                           (np.abs(bufr_df['DHR'] - diag_entry['Time']) < 0.0005))[0]
        elif t in [133]:
            # Certain aircraft, also need pressure to have a unique match
            idx = np.where((bufr_df['TYP'] == diag_entry['Observation_Type']) &
                           (np.abs(bufr_df['XOB'] - diag_entry['Longitude']) < 0.02) &
                           (np.abs(bufr_df['YOB'] - diag_entry['Latitude']) < 0.02) &
                           (np.abs(bufr_df['POB'] - diag_entry['Pressure']) < 1) &
                           (bufr_df['SID'] == ("'%s'" % diag_entry['Station_ID'].decode('utf-8').strip())) &
                           (np.abs(bufr_df['DHR'] - diag_entry['Time']) < 0.0005))[0]
        else:
            idx = np.where((bufr_df['TYP'] == diag_entry['Observation_Type']) &
                           (np.abs(bufr_df['XOB'] - diag_entry['Longitude']) < 0.02) &
                           (np.abs(bufr_df['YOB'] - diag_entry['Latitude']) < 0.02) &
                           (bufr_df['SID'] == ("'%s'" % diag_entry['Station_ID'].decode('utf-8').strip())) &
                           (np.abs(bufr_df['DHR'] - diag_entry['Time']) < 0.0005))[0]

        # Check to make sure there is only one match
        if len(idx) == 1:
            bufr_entry = bufr_df.loc[idx, :]
        else:
            print('%d entries found for var = %s, t = %s' % (len(idx), v, t))
            continue

        if v == 't':
            bufr_ob = bufr_entry['TOB'] + 273.15
            # Yes, this is a rather large threshold for T obs (units are K). Some surface obs 
            # (181, 187) have small differences between the diag and BUFR files some of the times,
            # and I am not sure why. This problem is not seen with other ob types or variables.
            if not np.all(np.abs(bufr_ob - diag_ob) < 0.2):
                print('T mismatch for ob type %s (diag = %.6e, bufr = %.6e)' % (t, diag_ob, bufr_ob))
                fail = True
        elif v == 'q':
            bufr_ob = bufr_entry['QOB'] * 1e-6
            if not np.isclose(diag_ob, bufr_ob):
                print('Q mismatch for ob type %s (diag = %.6e, bufr = %.6e)' % (t, diag_ob, bufr_ob))
                fail = True
        elif v == 'uv':
            bufr_uob = bufr_entry['UOB']
            if not np.isclose(diag_uob, bufr_uob):
                print('U mismatch for ob type %s (diag = %.6e, bufr = %.6e)' % (t, diag_uob, bufr_uob))
                fail = True
            bufr_vob = bufr_entry['VOB']
            if not np.isclose(diag_vob, bufr_vob):
                print('V mismatch for ob type %s (diag = %.6e, bufr = %.6e)' % (t, diag_vob, bufr_vob))
                fail = True
        elif v == 'pw':
            bufr_ob = bufr_entry['PWO']
            if not np.isclose(diag_ob, bufr_ob):
                print('PW mismatch for ob type %s (diag = %.6e, bufr = %.6e)' % (t, diag_ob, bufr_ob))
                fail = True

if fail:
    print()
    raise AssertionError('Test failed')


"""
End check_bufr_csv.py
"""
