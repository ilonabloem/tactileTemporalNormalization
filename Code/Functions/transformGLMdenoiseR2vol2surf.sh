#!/bin/bash -l

export SUBJID=${1}
export EXP_DIR=/Volumes/server/Projects/TemporalTactileCounting
export SUBJECTS_DIR=${EXP_DIR}/derivatives/freesurfer
export GLM_DIR=${EXP_DIR}/Data/GLMdenoise/corticalRibbon/sub-${SUBJID}/fir/volOutputs
export SURF_DIR=${GLM_DIR}/surfOverlays
export ROI_DIR=${EXP_DIR}/Data/roiVols/sub-${SUBJID}
export LABEL_DIR=${SUBJECTS_DIR}/sub-${SUBJID}/label

mkdir -p ${SURF_DIR}
mri_vol2surf --mov ${GLM_DIR}/sub-${SUBJID}_GLMdenoise_R2_fir.VOL.mgz \
--regheader sub-${SUBJID}  --hemi rh --projfrac 0.5 \
--o ${SURF_DIR}/rh.sub-${SUBJID}_GLMdenoise_R2_fir.nii.gz

freeview -f ${SUBJECTS_DIR}/sub-${SUBJID}/surf/rh.inflated:overlay=${SURF_DIR}/rh.sub-${SUBJID}_GLMdenoise_R2_fir.nii.gz


 # -f ${SUBJECTS_DIR}/sub-${SUBJID}/surf/rh.pial:overlay=${LABEL_DIR}/fingerROI/rh.localizerROI.label &