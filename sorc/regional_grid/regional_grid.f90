!=============================================================================
program regional_grid
!=============================================================================

  use pkind, only: dp
  use pietc, only: dtor,rtod
  use netcdf

  implicit none

  ! namelist variables
  real(dp)                     :: plat,plon,pazi=0.0
  real(dp)                     :: delx,dely
  integer                      :: lx,ly
  real(dp)                     :: a,k
  namelist /regional_grid_nml/ plat,plon,delx,dely,lx,ly,a,k

  real(dp),parameter           :: re=6371000.0

  real(dp)                     :: redelx,redely
  integer                      :: nx,nxm, ny,nym
  logical                      :: ff

  real(dp),dimension(:,:),allocatable:: glat,glon
  real(dp),dimension(:,:),allocatable:: garea

  character(len=256)           :: nml_fname

  ! netcdf
  integer                      :: ncid
  integer                      :: nxp_dimid, nyp_dimid, nx_dimid, ny_dimid
  integer                      :: x_varid, y_varid, area_varid
  integer, dimension(2)        :: dimids

  integer :: i
  integer, parameter :: ntiles = 1
  integer, parameter :: string = 255
  integer                      :: ntiles_dimid, string_dimid, &
                                  mosaic_varid, gridlocation_varid, &
                                  gridfiles_varid, gridtiles_varid
  integer, dimension(1)        :: dimids1D
  integer, dimension(ntiles)   :: tile_inds
  character(len=string)        :: mosaic, gridlocation, &
                                  CRES_str, tmp_str
!  character(len=string), dimension(ntiles) :: gridfiles, gridtiles
!  character, dimension(string,ntiles) :: gridfiles, gridtiles
!  character, dimension(ntiles,string) :: gridfiles, gridtiles

!=============================================================================

  if (command_argument_count() == 2) then
    call get_command_argument(1, nml_fname)
    call get_command_argument(2, CRES_str)
  else
    nml_fname = "regional_grid.nml"
    CRES_str = "CNNN"
  end if

  open(10,file=trim(nml_fname),status="old",action="read")
  read(10,nml=regional_grid_nml)
  close(10)

  nx=-lx*2
  nxm=nx-1
  ny=-ly*2
  nym=ny-1

  redelx=re*(delx*dtor)
  redely=re*(dely*dtor)

  allocate(glat(0:nx,0:ny))
  allocate(glon(0:nx,0:ny))
  allocate(garea(0:nxm,0:nym))

  call hgrid_ak(lx,ly,nx,ny,a,k,plat*dtor,plon*dtor,pazi*dtor, &
                re,redelx,redely, glat,glon,garea, ff)
  if(ff)stop 'Failure flag raised in hgrid routine'

  glon = glon*rtod
  glat = glat*rtod
  where (glon < 0.0) glon = glon + 360.0

  call check( nf90_create("regional_grid.nc", NF90_64BIT_OFFSET, ncid) )
  call check( nf90_def_dim(ncid, "nx", nx, nx_dimid) )
  call check( nf90_def_dim(ncid, "ny", ny, ny_dimid) )
  call check( nf90_def_dim(ncid, "nxp", nx+1, nxp_dimid) )
  call check( nf90_def_dim(ncid, "nyp", ny+1, nyp_dimid) )

  dimids = (/ nxp_dimid, nyp_dimid /)
  call check( nf90_def_var(ncid, "x", NF90_DOUBLE, dimids, x_varid) )
  call check( nf90_put_att(ncid, x_varid, "standard_name", "geographic_longitude") )
  call check( nf90_put_att(ncid, x_varid, "units", "degree_east") )
  call check( nf90_put_att(ncid, x_varid, "hstagger", "C") )
  call check( nf90_def_var(ncid, "y", NF90_DOUBLE, dimids, y_varid) )
  call check( nf90_put_att(ncid, y_varid, "standard_name", "geographic_latitude") )
  call check( nf90_put_att(ncid, y_varid, "units", "degree_north") )
  call check( nf90_put_att(ncid, y_varid, "hstagger", "C") )
  dimids = (/ nx_dimid, ny_dimid /)
  call check( nf90_def_var(ncid, "area", NF90_DOUBLE, dimids, area_varid) )
  call check( nf90_put_att(ncid, area_varid, "standard_name", "grid_cell_area") )
  call check( nf90_put_att(ncid, area_varid, "units", "m2") )
  call check( nf90_put_att(ncid, area_varid, "hstagger", "H") )

  call check( nf90_put_att(ncid, NF90_GLOBAL, "history", "gnomonic_ed") )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "source", "FV3GFS") )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "grid", "akappa") )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "plat", plat) )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "plon", plon) )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "pazi", pazi) )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "delx", delx) )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "dely", dely) )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "lx", lx) )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "ly", ly) )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "a", a) )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "k", k) )

  call check( nf90_enddef(ncid) )

  call check( nf90_put_var(ncid, x_varid, glon) )
  call check( nf90_put_var(ncid, y_varid, glat) )
  call check( nf90_put_var(ncid, area_varid, garea) )

  call check( nf90_close(ncid) )
!
!=============================================================================
!
! Create the grid mosaic file that FV3 expects to be present in the IN-
! PUT subdirectory of the run directory.
!
!=============================================================================
!
  call check( nf90_create("regional_mosaic.nc", NF90_64BIT_OFFSET, ncid) )
  call check( nf90_def_dim(ncid, "ntiles", ntiles, ntiles_dimid) )
  call check( nf90_def_dim(ncid, "string", string, string_dimid) )

  dimids1D = (/ string_dimid /)
  call check( nf90_def_var(ncid, "mosaic", NF90_CHAR, dimids1D, mosaic_varid) )
  call check( nf90_put_att(ncid, mosaic_varid, "standard_name", "grid_mosaic_spec") )
  call check( nf90_put_att(ncid, mosaic_varid, "children", "gridtiles") )
  call check( nf90_put_att(ncid, mosaic_varid, "contact_regions", "contacts") )
  call check( nf90_put_att(ncid, mosaic_varid, "grid_descriptor", "") )

  dimids1D = (/ string_dimid /)
  call check( nf90_def_var(ncid, "gridlocation", NF90_CHAR, dimids1D, gridlocation_varid) )
  call check( nf90_put_att(ncid, gridlocation_varid, "standard_name", "grid_file_location") )

  dimids = (/ string_dimid, ntiles_dimid /)
  call check( nf90_def_var(ncid, "gridfiles", NF90_CHAR, dimids, gridfiles_varid) )
  call check( nf90_def_var(ncid, "gridtiles", NF90_CHAR, dimids, gridtiles_varid) )

  call check( nf90_put_att(ncid, NF90_GLOBAL, "grid_version", "") )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "code_version", "") )
  call check( nf90_put_att(ncid, NF90_GLOBAL, "history", "") )

  call check( nf90_enddef(ncid) )

  mosaic = trim(CRES_str) // "_mosaic"
  gridlocation = "/path/to/directory"

  call check( nf90_put_var(ncid, mosaic_varid, trim(mosaic)) )
  call check( nf90_put_var(ncid, gridlocation_varid, trim(gridlocation)) )

  tile_inds(1) = 7
  do i=1, ntiles
    write(tmp_str, 510) "tile", tile_inds(i)
    call check( nf90_put_var(ncid, gridtiles_varid, trim(tmp_str), start=(/1,i/)) )
    write(tmp_str, 520) trim(CRES_str), "_grid.", trim(tmp_str), ".nc"
    call check( nf90_put_var(ncid, gridfiles_varid, trim(tmp_str), start=(/1,i/)) )
  end do
510 FORMAT(A, I1)
520 FORMAT(4A)

  call check( nf90_close(ncid) )

end program regional_grid

subroutine check(status)
use netcdf
integer,intent(in) :: status
!
if(status /= nf90_noerr) then
  write(0,*)' check netcdf status=',status
  write(0,'("error ", a)')trim(nf90_strerror(status))
  stop "Stopped"
endif
end subroutine check