"""
Open and Close and prepBUFR CSV So It Is In The Proper Format

shawn.s.murdzek@noaa.gov
"""

#---------------------------------------------------------------------------------------------------
# Import Modules
#---------------------------------------------------------------------------------------------------

import sys
import os

import pyDA_utils.bufr as bufr


#---------------------------------------------------------------------------------------------------
# Open and Close CSV
#---------------------------------------------------------------------------------------------------

infile = sys.argv[1]

bufr_csv = bufr.bufrCSV(infile)
bufr.df_to_csv(bufr_csv.df, 'tmp.csv')

os.system('mv tmp.csv %s' % infile)


"""
End open_close_csv.py
"""
