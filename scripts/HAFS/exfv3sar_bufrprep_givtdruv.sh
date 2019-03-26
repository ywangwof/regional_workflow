#!/bin/ksh

################################################################################
#
# UNIX Script Documentation Block
#
# Script name:         exfv3sar_bufrprep_givuvtdr.sh
#
# Script description:  This script generates a Binary Universal Format
#                      (BUFR) file containing the NOAA/AOML/HRD G-IV
#                      reconnaisance tail-Doppler radar (TDR) u- and
#                      v-wind observations.
#
# Script history log:  2019-03-26  Henry Winterbottom -- Original version.
#
################################################################################

set -x

#----

# FUNCTION:

# format_observation_files.sh

# DESCRIPTION:

# This function determines the valid observation time for each
# available observation file and creates an external file to be used
# to create the PREPBUFR-formatted observation file.

format_observation_files (){

    # Create working directory for G-IV tail-Doppler radar (TDR) u-
    # and v-wind observations.

    mkdir -p ${BUFRPREPdir}/givtdruv/obs

    # Copy all available observation files to current working
    # directory.

    cp ${G4TDRUVdatapath}/*_xy.nc ${BUFRPREPdir}/givtdruv/obs/

    # Move to directory containing observations.

    cd ${BUFRPREPdir}/givtdruv/obs

    # Create a list of observation files.

    filenames=`ls ${BUFRPREPdir}/givtdruv/obs`

    # Remove any previous occurrances of external file list.

    rm ${BUFRPREPdir}/givtdruv/givtdruv.filelist >& /dev/null

    # Loop through all file names and retrieve time-stamp information.

    for filename in ${filenames}; do

	# Define the reference time stamp.

	refdate=`ncdump -h ${filename} | grep "seconds since" | awk '{print $5}' | sed 's/-//g'`
	refdate=${refdate}00

	# Define the offset number of seconds relative to the
	# reference time stamp.

	offset_seconds=`ncdump -v time ${filename} | grep "time" | tail -1 | awk '{print $3}'`
	
	# Create external file containing time-stamp attributes.

	python ${UTILdir}/date_time_format.py --date_string ${refdate} --offset_seconds ${offset_seconds} --output_file ${BUFRPREPdir}/givtdruv/obs/${filename}.timeinfo

	# Define observation valid time date string.

	date_string=`cat ${BUFRPREPdir}/givtdruv/obs/${filename}.timeinfo | grep "date_string" | awk '{print $2}'`

	# Update external file list.

	echo "${date_string} ${BUFRPREPdir}/givtdruv/obs/${filename}" >> ${BUFRPREPdir}/givtdruv/givtdruv.filelist

    done # for filename in ${filenames}
}

#----

# FUNCTION:

# create_obs_to_bufr_namelist.sh

# DESCRIPTION:

# This function creates the namelist file obs-to-bufr.input in the
# working directory.

create_obs_to_bufr_namelist (){

    # Create external file containing time-stamp attributes.

    python ${UTILdir}/date_time_format.py --date_string ${CYCLE} --output_file ${BUFRPREPdir}/givtdruv/cycle.info

    # Define analysis date relative to which to define observation
    # times.

    analdate=`cat ${BUFRPREPdir}/givtdruv/cycle.info | grep 'date_string' | awk '{print $2}'`

    # Create namelist file obs-to-bufr.input in working directory.

    cat << EOF > ${BUFRPREPdir}/givtdruv/obs-to-bufr.input
&share
analdate    = '${analdate}'
datapath    = './'
is_fcstmdl  = F
is_givtdruv = T
is_hsa      = F
is_nhcgtcm  = F
is_tcm      = F
obs_flag    = F
/

&bufr
bufr_tblpath = '${HSAprepbufrtbl_filepath}'
/

&fcstmdl
/

&flag
/

&givtdruv
givtdruv_bufr_info_filepath = '${G4TDRUVbufrinfo_filepath}'
givtdruv_obs_filepath       = '${BUFRPREPdir}/givtdruv/givtdruv.filelist'
/

&hsa
/

&nhcgtcm
/

&tcm
/

&topo
/ 
EOF
}    

#----

# FUNCTION:

# deliver_products.sh

# DESCRIPTION:

# This function copies (e.g., delivers) the relavant files to
# respective paths expected by the workflow.

deliver_products (){

    # Create directories to which to deliver products.

    mkdir -p ${COMROOT}/bufrprep
    mkdir -p ${ITRCROOT}/bufrprep

    # Copy (e.g., deliver) relevant file to respective paths.

    cp ${BUFRPREPdir}/givtdruv/prepbufr.givtdruv ${COMROOT}/bufrprep
    cp ${BUFRPREPdir}/givtdruv/prepbufr.givtdruv ${ITRCROOT}/bufrprep
}


#----

# FUNCTION:

# run_obs_to_bufr.sh

# DESCRIPTION:

# This function launches the executable to format the G-IV TDR u- and
# v-wind observations within a PREPBUFR-formatted file.

run_obs_to_bufr (){

    # Move to working directory.

    cd ${BUFRPREPdir}/givtdruv

    # Copy executable to local (e.g., working) directory.

    cp ${otb_exe} ${BUFRPREPdir}/givtdruv/otb.x

    # Define unique standard output file.

    pgmout=${BUFRPREPdir}/givtdruv/obs_to_bufr.out.${pid}

    # Launch executable and write standard output to external file.

    ${BUFRPREPdir}/givtdruv/otb.x > ${pgmout}
}

#----

script_name=`basename "$0"`
start_date=`date`
echo "START ${script_name}: ${start_date}"

# The following tasks are accomplished by this script:

# (1) Create local sub-directories.

export BUFRPREPdir=${EXPTROOT}/bufrprep

# (2) Format relevant observation files.

format_observation_files

# (3) Create the appropriate namelist and external files for the
#     creation fo the PREPBUFR file.

create_obs_to_bufr_namelist

# (4) Create the PREPBUFR formatted file containing the G-IV TDR u-
#     and v-wind sonde observations.

run_obs_to_bufr

# (5) Deliver the relevant files to the respective /intercom and /com
#     paths.

deliver_products

stop_date=`date`
echo "STOP ${script_name}: ${stop_date}"

exit
