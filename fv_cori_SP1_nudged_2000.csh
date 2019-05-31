#!/bin/csh

# This is the most general form of the build/submit script for SP/UP model.
# HP has also made other versions of this script for simpler model configurations.
# Questions? Please contact h.parish@uci.edu at UC Irvine ESS.

set run_time       = 16:59:00
set queue          = regular 
set priority       = premium 
set account        = m3306
set run_start_date = "2008-10-01"
#set start_tod      = "00000"
set start_tod      = "43200"
set Np             = 2048 
set Np_else        = 512 

## ====================================================================
#   define case
## ====================================================================

setenv CCSMTAG     UltraCAM-spcam2_0_cesm1_1_1-crterai-atm-ecpp_with_nudging 
#setenv CASE        nudgUVThole625bullseye_dlon120_UP2deg_32x1CRM_L125_20081001_$Np
#setenv CASE        nudgUVThole625bullseye_dlon120_UP4x5_8x8CRM_L253_20081001_$Np
#setenv CASE        nudgUVThole625bullseye_dlon120_r2_UP2deg_32x1CRM_L125_20081001_$Np
setenv CASE        nudgUVThole625_tphysbc_bullzi60_bot3_UP4x5_32x1CRM_L125_20081001_$Np
#setenv CASE        nudgingUVThole750hpa_UP_4x5_32x1CRM250m_L125_20081001_$Np
#setenv CASE        no_nudging_UP_4x5_32x1CRM250m_L125_20080901_$Np
#setenv CASESET     F_AMIP_CAM5
#setenv CASESET     F_AMIP_SPCAM_sam1mom_shortcrm 
#setenv CASESET     F_2000_SPCAM_m2005_ECPP
#setenv CASESET     F_2000_SPCAM_sam1mom_SP
setenv CASESET     F_2000_SPCAM_sam1mom_UP
#setenv CASERES     f09_g16
#setenv CASERES     f19_g16
setenv CASERES     f45_f45
setenv PROJECT     m3306 

## ====================================================================
#   define directories
## ====================================================================

setenv MACH      corip1 
setenv CCSMROOT  $HOME/$CCSMTAG
setenv CASEROOT  $HOME/cases/$CASE
setenv PTMP      $SCRATCH
setenv RUNDIR    $PTMP/$CASE/run
setenv ARCHDIR   $PTMP/archive/$CASE
setenv DATADIR   /global/project/projectdirs/PNNL-PJR/csm/inputdata
setenv DIN_LOC_ROOT_CSMDATA $DATADIR
#setenv mymodscam $HOME/mymods/$CCSMTAG/CAM
#mkdir -p $mymodscam

## ====================================================================
#   create new case, configure, compile and run
## ====================================================================

rm -rf $CASEROOT
rm -rf $PTMP/$CASE
#rm -rf $PTMP/$CASE

#------------------
## create new case
#------------------

cd  $CCSMROOT/scripts

./create_newcase -case $CASEROOT -mach $MACH -res $CASERES -compset $CASESET -compiler intel -v

#------------------
## set environment
#------------------

cd $CASEROOT

#set ntasks = $Np
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ATM  -val=$Np
./xmlchange  -file env_mach_pes.xml -id  NTASKS_LND  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ICE  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_OCN  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_CPL  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_GLC  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ROF  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  TOTALPES    -val=$Np

set-run-opts:
cd $CASEROOT

./xmlchange  -file env_run.xml -id  RESUBMIT      -val '0'
./xmlchange  -file env_run.xml -id  STOP_N        -val '30'
./xmlchange  -file env_run.xml -id  STOP_OPTION   -val 'ndays'
#./xmlchange  -file env_run.xml -id  REST_N        -val '1'
./xmlchange  -file env_run.xml -id  REST_OPTION   -val 'ndays'       # 'nhours' 'nmonths' 'nsteps' 'nyears' 
./xmlchange -file env_run.xml -id REST_N           -val '1'
./xmlchange  -file env_run.xml -id  RUN_STARTDATE -val $run_start_date
./xmlchange  -file env_run.xml -id  START_TOD     -val $start_tod
./xmlchange  -file env_run.xml -id  DIN_LOC_ROOT  -val $DATADIR
./xmlchange  -file env_run.xml -id  DOUT_S_ROOT   -val $ARCHDIR
./xmlchange  -file env_run.xml -id  RUNDIR        -val $RUNDIR

./xmlchange  -file env_run.xml -id  DOUT_S_SAVE_INT_REST_FILES     -val 'TRUE'
./xmlchange  -file env_run.xml -id  DOUT_L_MS                      -val 'FALSE'

./xmlchange  -file env_run.xml -id  ATM_NCPL              -val '96'    
#./xmlchange  -file env_run.xml -id  SSTICE_DATA_FILENAME  -val '$DATADIR/atm/cam/sst/sst_HadOIBl_bc_1x1_1850_2013_c140701.nc' 

cat <<EOF >! user_nl_cam

&camexp
npr_yz = 8,2,2,8
!npr_yz = 32,2,2,32
!prescribed_aero_model='bulk'
/

&aerodep_flx_nl
aerodep_flx_datapath           = '$DATADIR/atm/cam/chem/trop_mozart_aero/aero'
aerodep_flx_file               = 'aerosoldep_rcp2.6_monthly_1849-2104_1.9x2.5_c100402.nc'
/

&prescribed_volcaero_nl
prescribed_volcaero_datapath = '$DATADIR/atm/cam/volc'
prescribed_volcaero_file     = 'CCSM4_volcanic_1850-2011_prototype1.nc'
/


&solar_inparm
!solar_data_file = '$DATADIR/atm/cam/solar/spectral_irradiance_Lean_1610-2140_ann_c100408.nc'
solar_data_file = '$DATADIR/atm/cam/solar/spectral_irradiance_Lean_1950-2012_daily_Leap_c130227.nc'
/

&chem_surfvals_nl
bndtvghg = '$DATADIR/atm/cam/ggas/ghg_hist_1765-2012_c130501.nc'

ch4vmr = 1760.0e-9
co2vmr = 367.0e-6
f11vmr = 653.45e-12
f12vmr = 535.0e-12
n2ovmr = 316.0e-9
/

&cam_inparm
phys_loadbalance = 2

!ncdata = '/global/project/projectdirs/m2840/terai/IC_files/L125_1p9x2p5/regrid_EI_1p9x2p5_L125.cam2.i.2008-10-01-43200.nc'
!ncdata = '/global/project/projectdirs/m2840/terai/IC_files/L253_4x5/regrid_EI_4x5_L253.cam2.i.2008-10-01-43200.nc'
!ncdata = '/global/project/projectdirs/m2840/terai/IC_files/L125_4x5/regrid_EI_4x5_L125.cam2.i.2008-09-01-43200.nc'
ncdata = '/global/project/projectdirs/m2840/terai/IC_files/L125_4x5/regrid_EI_4x5_L125.cam2.i.2008-10-01-43200.nc'
!ncdata = '/global/project/projectdirs/m2840/terai/IC_files/L30_4x5/regrid_EI_4x5_L30.cam2.i.2008-10-01-43200.nc'

Nudge_Model = .true.
!Nudge_Path = '/global/project/projectdirs/m2840/terai/IC_files/L125_1p9x2p5/'
!Nudge_File_Template = 'regrid_EI_1p9x2p5_L125.cam2.i.%y-%m-%d-%s.nc'
!Nudge_Path = '/global/project/projectdirs/m2840/terai/IC_files/L253_4x5/'
!Nudge_File_Template = 'regrid_EI_4x5_L253.cam2.i.%y-%m-%d-%s.nc'
Nudge_Path = '/global/project/projectdirs/m2840/terai/IC_files/L125_4x5/'
Nudge_File_Template = 'regrid_EI_4x5_L125.cam2.i.%y-%m-%d-%s.nc'
!Nudge_Path = '/global/project/projectdirs/m2840/terai/IC_files/L30_4x5/'
!Nudge_File_Template = 'regrid_EI_4x5_L30.cam2.i.%y-%m-%d-%s.nc'
Nudge_Times_Per_Day = 4 
Model_Times_Per_Day = 96 
Nudge_Uprof = 1
Nudge_Ucoef = 1.     !this is a value between 0 and 1 and sets the timescal of nudging for this variable namely U. See nudging.F90 for details.
Nudge_Vprof = 1
Nudge_Vcoef = 1.
Nudge_Tprof = 1 
Nudge_Tcoef = 0.25      !standard 0.25 if tau=24hr 
Nudge_Qprof = 0
Nudge_Qcoef = 0.
Nudge_PSprof = 0
Nudge_PScoef = 0.
Nudge_Beg_Year = 2008
Nudge_Beg_Month = 10 
Nudge_Beg_Day = 01
Nudge_End_Year = 2009
Nudge_End_Month = 02
Nudge_End_Day = 04

iradsw = 2 
iradlw = 2
!iradae = 4 

empty_htapes = .true.

!fincl1 = 'cb_ozone_c', 'MSKtem', 'VTH2d', 'UV2d', 'UW2d', 'U2d', 'V2d', 'TH2d', 'W2d', 'UTGWORO'
fincl1='cb_ozone_c'

fincl2 = 'TGCLDLWP:A','TGCLDIWP:A','PS:A','T:A','Q:A','RELHUM:A','FLUT:A','FSNTOA:A','FLNS:A','FSNS:A','FLNT:A','FSDS:A','FSNT:A','FSUTOA:A',
         'SOLIN:A','LWCF:A','SWCF:A','CLOUD:A','CLDICE:A','CLDLIQ:A','CLDTOT:A','CLDHGH:A','CLDMED:A','CLDLOW:A','OMEGA:A','OMEGA500:A',
         'PRECT:A','U:A','V:A','LHFLX:A','SHFLX:A','SST:A','TS:A','PBLH:A',
         'TMQ:A',
         'Z3:A','CLDTOP:A','CLDBOT:A','FLDS:A','FLDSC:A',
         'FSDSC:A','FSNSC:A','FSNTC:A','FSNTOAC:A','FLNSC:A','FLNTC:A','FLUTC:A','QRL:A','QRS:A'

fincl3 = 'PS:A','SPQC:A','SPWW:A','SPBUOYA:A','SPTKE:A','SPTKES:A','U:A','UTEND:A','V:A','VTEND:A','T:A','TTEND:A','Q:A','UAP:I','VAP:I','TAP:I','QAP:I','PTTEND:A','PTEQ:A',
         'Nudge_U:A','Nudge_V:A','Nudge_T:A'     !This should be ON only for nudged cases. Add 'Nudge_T:A' when T is nudged.

!fincl3 = 'SPQRL:A','SPQRS:A','SPDT:A','SPDQ:A','SPDQC:A','SPDQI:A','SPMC:A','SPMCUP:A','SPMCDN:A','SPMCUUP:A','SPMCUDN:A','SPWW:A','SPBUOYA:A',
!         'SPQC:A','SPQI:A','SPQS:A','SPQG:A','SPQR:A','SPQTFLX:A','SPUFLX:A','SPVFLX:A','SPTKE:A',
!         'SPTKES:A','SPTK:A','SPQTFLXS:A','SPQPFLX:A','SPPFLX:A','SPQTLS:A','SPQTTR:A','SPQPTR:A','SPQPEVP:A','SPQPFALL:A','SPQPSRC:A','SPTLS:A'

!fincl4 = 'PS:A','QAP:I','TAP:I','QBP:I','TBP:I','CLDLIQAP:I','CLDLIQBP:I','DTCORE:A','PTTEND:A','PTEQ:A','SPDT:A','SPDQ:A','DTV:A','VD01:A','SHFLX:A',
!         'LHFLX:A','QRL:A','QRS:A','T:A','U:A','V:A','OMEGA:A','Q:A','VT:A','VU:A','VV:A','VQ:A','UU:A','OMEGAT:A'

nhtfrq = 0,12,12      !beware negative values dont work in this particular setup.
mfilt  = 0,8,8
/
EOF

cat <<EOF >! user_nl_clm
&clmexp
finidat = '/global/u1/h/hparish/ICs/ICs_from_Edison_scratch/NOSP_4x5_CTRL_eds_r2_25y_512.clm2.r.2025-01-01-00000.nc'
!finidat = '/global/u1/h/hparish/ICs/ICs_from_Edison_scratch/UP_4x_2deg_SAM1m_32x1CRM250m_10mrad_L125_20081001_12Z_1.clm2.r.2008-12-30-43200.nc'

hist_empty_htapes = .true.
hist_fincl1 = 'QSOIL:A', 'QVEGE:A', 'QVEGT:A', 'QIRRIG:A', 'FCEV:A', 'FCTR:A', 'FGEV:A', 'H2OCAN:A', 'H2OSOI:A', 'QDRIP:A', 'QINTR:A', 'QOVER:A', 
              'SOILICE:A', 'SOILLIQ:A', 'TSA:A', 'Q2M:A', 'RH2M:A' 
hist_nhtfrq = 4 
hist_mfilt  = 6 
/
EOF

cat <<EOF >! user_nl_cice
!stream_fldfilename = '$DATADIR/atm/cam/sst/sst_HadOIBl_bc_1x1_1850_2013_c140701.nc'
stream_fldfilename = '/global/project/projectdirs/PNNL-PJR/csm/inputdata/atm/cam/sst/sst_HadOIBl_bc_1x1_clim_c101029.nc'
EOF

#------------------
## configure
#------------------

config:
cd $CASEROOT
./cesm_setup
./xmlchange -file env_build.xml -id EXEROOT -val $PTMP/$CASE/bld

modify:
cd $CASEROOT
#if (-e $mymodscam) then
#    ln -s $mymodscam/* SourceMods/src.cam
#endif
#------------------
##  Interactively build the model
#------------------

build:
cd $CASEROOT
./$CASE.build

cd  $CASEROOT
sed -i 's/^#SBATCH --time=.*/#SBATCH --time='$run_time' /' $CASE.run
sed -i 's/^#SBATCH -p .*/#SBATCH -p '$queue' /' $CASE.run
sed -i 's/^#SBATCH --qos .*/#SBATCH --qos '$priority' /' $CASE.run
sed -i 's/^#SBATCH -A .*/#SBATCH -A '$account' /' $CASE.run

cd  $CASEROOT
set bld_cmp   = `grep BUILD_COMPLETE env_build.xml`
set split_str = `echo $bld_cmp | awk '{split($0,a,"="); print a[3]}'`
set t_or_f    = `echo $split_str | cut -c 2-5`

if ( $t_or_f == "TRUE" ) then
    sbatch $CASE.run
    echo '-------------------------------------------------'
    echo '----Build and compile is GOOD, job submitted!----'
else
    set t_or_f = `echo $split_str | cut -c 2-6`
    echo 'Build not complete, BUILD_COMPLETE is:' $t_or_f
endif

# NOTE for documenting this case
cat <<EOF >> $CASEROOT/README.case

---------------------------------
USER NOTE (by hparish)
---------------------------------

--- Modifications:

EOF
