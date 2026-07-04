#!/bin/bash -l

# Visualize electrode placement NY726
# source visualizeECoGelectrodes.sh from inside main project folder: <PATH>/TemporalTactileCounting

export WORK_DIR="$PWD"/derivatives
export SUBJECTS_DIR=${WORK_DIR}/freesurfer
export WARP_DIR=${SUBJECTS_DIR}/som726_warped
export MRI_DIR=${SUBJECTS_DIR}/sub-ny726

freeview -v ${WARP_DIR}/mri/T1.mgz \
-v ${MRI_DIR}/mri/T1.mgz \
-f ${WARP_DIR}/surf/rh.white:annot=${WARP_DIR}/label/rh.aparc.annot:annot=${WARP_DIR}/label/rh.Glasser2016.annot \
-v ${WORK_DIR}/NY726_2_elec/NY726_2_elec.nii.gz:colormap=LUT:lut=${WORK_DIR}/NY726_2_elec/NY726_elec_lut.txt


