#!/bin/bash -l

# Check functional alignment

export SUBJID=${1}
export SESSID=${2}
export TASK=tact

export WORK_DIR=/Volumes/server/Projects/TemporalTactileCounting
export SUBJECTS_DIR=${WORK_DIR}/derivatives/freesurfer
export ROI_DIR=${WORK_DIR}/Data/roiVols/sub-${SUBJID}

freeview -v ${SUBJECTS_DIR}/sub-${SUBJID}/mri/T1.mgz \
-v ${WORK_DIR}/derivatives/fmriprep/sub-${SUBJID}/ses-${SESSID}/func/sub-${SUBJID}_ses-${SESSID}_task-${TASK}_run-01_space-T1w_boldref.nii.gz \
-v ${ROI_DIR}/lh.Glasser2016.VOL.nii.gz -v ${ROI_DIR}/rh.Glasser2016.VOL.nii.gz \
-v ${ROI_DIR}/rh.fingerROI.VOL.nii.gz -v ${ROI_DIR}/rh.localizerROI.VOL.nii.gz \
-f ${SUBJECTS_DIR}/sub-${SUBJID}/surf/lh.white:annot=${SUBJECTS_DIR}/sub-${SUBJID}/label/lh.Glasser2016.annot \
-f ${SUBJECTS_DIR}/sub-${SUBJID}/surf/rh.white:annot=${SUBJECTS_DIR}/sub-${SUBJID}/label/rh.Glasser2016.annot \
-f ${SUBJECTS_DIR}/sub-${SUBJID}/surf/lh.pial:annot=${SUBJECTS_DIR}/sub-${SUBJID}/label/lh.Glasser2016.annot \
-f ${SUBJECTS_DIR}/sub-${SUBJID}/surf/rh.pial:annot=${SUBJECTS_DIR}/sub-${SUBJID}/label/rh.Glasser2016.annot &




