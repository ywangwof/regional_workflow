#!/bin/sh -l

#
#----WCOSS_CRAY JOBCARD
#
##BSUB -L /bin/sh
#BSUB -P NAM-T2O
#BSUB -o log.chgres.%J
#BSUB -e log.chgres.%J
#BSUB -J chgres_fv3
#BSUB -q "debug"
#BSUB -W 00:30
#BSUB -M 1024
#BSUB -extsched 'CRAYLINUX[]'
#
#----WCOSS JOBCARD
#
##BSUB -L /bin/sh
##BSUB -P FV3GFS-T2O
##BSUB -oo log.chgres.%J
##BSUB -eo log.chgres.%J
##BSUB -J chgres_fv3
##BSUB -q devonprod
##BSUB -x
##BSUB -a openmp
##BSUB -n 24
##BSUB -R span[ptile=24]
#
#----THEIA JOBCARD
#
#PBS -N gen_IC_BC0_files_rgnl
#PBS -A gsd-fv3
#PBS -o out.$PBS_JOBNAME.$PBS_JOBID
#PBS -e err.$PBS_JOBNAME.$PBS_JOBID
#PBS -l nodes=1:ppn=24
#PBS -q debug
#PBS -l walltime=00:30:00
#PBS -W umask=022
#

#
#-----------------------------------------------------------------------
#
# This script generates:
#
# 1) A NetCDF initial condition (IC) file on a regional grid for the
#    date/time on which the analysis files in the directory specified by
#    INIDIR are valid.  Note that this file does not include data in the
#    halo of this regional grid (that data is found in the boundary con-
#    dition (BC) files).
#
# 2) A NetCDF surface file on the regional grid.  As with the IC file,
#    this file does not include data in the halo.
#
# 3) A NetCDF boundary condition (BC) file containing data on the halo
#    of the regional grid at the initial time (i.e. at the same time as
#    the one at which the IC file is valid).
#
# 4) A NetCDF "control" file named gfs_ctrl.nc that contains infor-
#    mation on the vertical coordinate and the number of tracers for
#    which initial and boundary conditions are provided.
#
# All four of these NetCDF files are placed in the directory specified
# by WORKDIR_ICBC_CDATE, defined as
#
#   WORKDIR_ICBC_CDATE="$WORKDIR_ICBC/$CDATE"
#
# where CDATE is the externally specified starting date and cycle hour
# of the current forecast.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
#
# Source the variable definitions script.
#
#-----------------------------------------------------------------------
#
. $SCRIPT_VAR_DEFNS_FP
#
#-----------------------------------------------------------------------
#
# Source function definition files.
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Set the name of and create the directory in which the output from this
# script will be placed (if it doesn't already exist).
#
#-----------------------------------------------------------------------
#
WORKDIR_ICBC_CDATE_ICS_WORK="$WORKDIR_ICBC/$CDATE/ICs_work"
mkdir_vrfy -p "$WORKDIR_ICBC_CDATE_ICS_WORK"
cd WORKDIR_ICBC_CDATE_ICS_WORK

#-----------------------------------------------------------------------
#
# Load modules and set machine-dependent parameters.
#
#-----------------------------------------------------------------------

case $MACHINE in
#
"WCOSS_C")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"WCOSS")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"DELL")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"THEIA")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

   ulimit -s unlimited
   ulimit -a

   module purge
   module load intel/18.1.163
   module load impi/5.1.1.109
   module load netcdf/4.3.0
   module load hdf5/1.8.14
   module load wgrib2/2.0.8

   APRUN="srun"

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"JET")
#
  { save_shell_opts; set +x; } > /dev/null 2>&1

  { restore_shell_opts; } > /dev/null 2>&1
  ;;
#
"ODIN")
#
  ;;
#
"CHEYENNE")
#
  ;;
#
esac

#-----------------------------------------------------------------------
#
# Create links to the grid and orography files with 4 halo cells.  These
# are needed by chgres_cube to create the boundary data.
#
#-----------------------------------------------------------------------
#
export HALO=${nh4_T7}

ln_vrfy -sf $WORKDIR_SHVE/${CRES}_grid.tile7.halo${HALO}.nc \
            $WORKDIR_SHVE/${CRES}_grid.tile7.nc

ln_vrfy -sf $WORKDIR_SHVE/${CRES}_oro_data.tile7.halo${HALO}.nc \
            $WORKDIR_SHVE/${CRES}_oro_data.tile7.nc

#
#-----------------------------------------------------------------------
#
# Build the namelist for chgres_cube.
#
#-----------------------------------------------------------------------
#

cat > fort.41 <<EOF
&config
 fix_dir_target_grid="${BASEDIR}/JP_grid_HRRR_like_fix_files_chgres_cube"
 mosaic_file_target_grid="${TMPDIR}/${EXPT_SUBDIR}/grid/${CRES}_mosaic.nc"
 orog_dir_target_grid="${TMPDIR}/${EXPT_SUBDIR}/shave"
 orog_files_target_grid="${CRES}_oro_data.tile7.halo${nh4_T7}.nc"
 vcoord_file_target_grid="${BASEDIR}/fv3sar_workflow/fix/fix_am/global_hyblev.l64.txt"
 mosaic_file_input_grid=""
 orog_dir_input_grid=""
 base_install_dir="${BASEDIR}/fv3sar_workflow/sorc/chgres_cube"
 wgrib2_path="$(which wgrib2)"
 data_dir_input_grid="/scratch3/BMC/det/beck/FV3-CAM/run_dirs/2019042800"
 grib2_file_input_grid="wrfnat_rr_${CDATE:8:2}.grib2"
 cycle_mon=${CDATE:4:2}
 cycle_day=${CDATE:6:2}
 cycle_hour=${CDATE:8:2}
 convert_atm=.true.
 convert_sfc=.true.
 convert_nst=.false.
 regional=1
 input_type="grib2"
 external_model="RAP"
 phys_suite="GSD"
/
EOF
#
#-----------------------------------------------------------------------
#
# Run chgres_cube.
#
#-----------------------------------------------------------------------
#
${APRUN} ${exec_dir}/global_chgres.exe || print_err_msg_exit "\
Call to script that generates surface, initial condition, and 00-h boundary condition files returned with nonzero exit code."

#--------------------------------------------------------------
# Move surface, control, and boundary file to ICs_BCs directory 
#--------------------------------------------------------------

mv gfs_bndy.nc ../gfs_bndy.tile7.000.nc
mv gfs_ctrl.nc ../
mv out.sfc.tile1.nc ../sfc_data.tile7.nc

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\

==============================================================================================
Surface field, initial condition, and 00-hr boundary condition files generated successfully!!!
=============================================================================================="
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
