#!/bin/sh -l

#-----------------------------------------------------------
# Run test case on Theia.  MUST BE RUN WITH A 
# MULTIPLE OF SIX MPI TASKS.  Could not get it to
# work otherwise.
#-----------------------------------------------------------

#SBATCH -A gsd-fv3
#SBATCH -q batch
#SBATCH -J chgres_cube
#SBATCH -N 2 --ntasks-per-node=6
#SBATCH -t 00:30:00
#SBATCH -o ./chgres_cube.log
#SBATCH -e ./chgres_cube.log

##PBS -l nodes=2:ppn=6
##PBS -l walltime=0:10:00
##PBS -A fv3-cpu
##PBS -q debug
##PBS -N fv3
##PBS -o ./log
##PBS -e ./log

set -x

ulimit -s unlimited
ulimit -a

module purge
module load intel/18.1.163
module load impi/5.1.1.109
module load netcdf/4.3.0
module load hdf5/1.8.14

if [ -d $WORKDIR_ICBC ] ; then 

rm -rf $WORKDIR_ICBC

fi

mkdir -p temp #$WORKDIR_ICBC

cd temp #$WORKDIR_ICBC

#ln -fs ${PBS_O_WORKDIR}/config.C48.theia.nml ./fort.41
#ln -fs ${PBS_O_WORKDIR}/config.C48.gaussian.theia.nml ./fort.41
#ln -fs ${PBS_O_WORKDIR}/config.C384.theia.nml ./fort.41
#ln -fs ${PBS_O_WORKDIR}/config.C768.nest.atm.theia.nml ./fort.41
#ln -fs ${PBS_O_WORKDIR}/config.C768.nest.theia.nml ./fort.41
#ln -fs ${PBS_O_WORKDIR}/config.C768.atm.theia.nml ./fort.41
#ln -fs ${PBS_O_WORKDIR}/config.C768.l91.atm.theia.nml ./fort.41
#ln -fs ${PBS_O_WORKDIR}/config.C1152.l91.atm.theia.nml ./fort.41
#ln -fs ${PBS_O_WORKDIR}/config.C96.nest.theia.nml ./fort.41
#ln -sf $SORCDIR/chgres_cube/run/config.C3343.theia.nml ./fort.41
#ln -sf /scratch3/BMC/det/beck/FV3-CAM/fv3sar_workflow/sorc/chgres_cube/run/config.C768.theia.nml ./fort.41
ln -sf /scratch3/BMC/det/beck/FV3-CAM/fv3sar_workflow/sorc/chgres_cube/run/config.C3343.theia_JP.nml ./fort.41
#ln -fs ${PBS_O_WORKDIR}/config.C1152.theia.nml ./fort.41

#srun $FV3SAR_DIR/exec/global_chgres.exe
srun /scratch3/BMC/det/beck/FV3-CAM/fv3sar_workflow/exec/global_chgres.exe

exit 0