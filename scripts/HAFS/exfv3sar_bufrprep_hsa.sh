#!/bin/ksh

################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:         exfv3sar_bufrprep_hsa.sh
# Script description:  This script generates a Binary Universal Format 
#                      (BUFR) file containing the NOAA/AOML/HRD dropsondes and 
#                      drift calculations to be appended to the 
#                      data-assimilation PREPBUFR files.
#
# Script history log:
# 2019-03-21  Henry Winterbottom -- Original version.
#
################################################################################

set -x

#----

# FUNCTION:

# _dump_tempdrop_history

# DESCRIPTION:

# This function dumps the contents of a tarball file containing
# available TEMP-DROP formatted observation files.

_dump_tempdrop_history ()
{
    # Define list of available tarball files; it is assumed that in
    # history (or retrospective) mode the observation files are
    # archived within a tarball file.

    filenames=`ls ${HSAdatapath} | grep ${CYCLE}`
    for filename in ${filenames}
    do
	# Copy tarball to working directory.
	
	cp ${HSAdatapath}/${filename} .

	# Unpack tarball in working directory.

	tar -zxvf ${filename}

	# Remove tarball within working directory

	rm ${filename}

    done # for filename in ${filenames}
}

#----

# FUNCTION:

# _strip_meta

# DESCRIPTION:

# This function strips meta-characters (including carriage returns)
# from the user specified input file, while preserving the end-of-line
# designations; this function replaces the user specified file with a
# file that is free of meta-characters and carriage returns.

# INPUT VARIABLES:

#  * infile; the path to the file possible containing meta-characters
#    and carriage returns.

_strip_meta ()
{
    # Get filename name from user arguments.

    infile=$1

    # Remove any meta-characters, including carriage returns from
    # file; preserve the end-line designations.

    cat ${infile} | tr -dc '[:print:]\n' > tmp.file

    # Replace original file with meta-character free file.

    mv tmp.file ${infile}
}

#----

dump_tempdrop ()
{
    # Create working directory for the TEMP-DROP formatted
    # observations.
    
    mkdir -p ${BUFRPREPdir}/tempdrop/obs

    # Move to the working directory for the TEMP-DROP formatted
    # observations.

    cd ${BUFRPREPdir}/tempdrop/obs

    # If running in history (or retrospective) mode, proceed
    # accordingly; otherwise, assume that forecast is running in
    # forecast (or real-time) mode and obtain the available files (if
    # any) accordingly.

    if [ ${FCSTtype} == 'history' ]; then
	_dump_tempdrop_history
    else # if [ ${FCSTtype} == 'history' ]
	_dump_tempdrop_realtime
    fi   # if [ ${FCSTtype} == 'history' ]
}

#----

format_tds ()
{
    # Create a list of observation files

    filenames=`ls ${BUFRPREPdir}/tempdrop/obs`

    # Loop through all file names and check for data non-usage flags.

    for filename in ${filenames}
    do
	check=`grep -cE 'COMM CHECK|TTAA|TTBB' ${filename}`
	if [ ${check} == 0 ]; then

	    # Remove all meta-characters from strings in file; this
	    # step is necessary as some of the archived files may have
	    # been generated on a non-UNIX platform.	    

            _strip_meta ${filename}

	    # Define strings within file to seek out.

	    srchstrs=( 'REL SPG SPL' )

	    # Define file contents as individual strings.

	    while IFS= read line

	    # Loop through search strings and proceed accordingly.

	    do

		echo ${line}
	    done < "${filename}"
		     
	fi # if [ ${check} == 0 ]

    done # for filename in ${filenames}
}

#----

# Create local sub-directories

export BUFRPREPdir=${EXPTROOT}/bufrprep

dump_tempdrop 
format_tds

exit
