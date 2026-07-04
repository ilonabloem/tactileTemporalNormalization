#!/bin/bash -l

export SUBJID=${1}
export WORK_DIR=/Volumes/server/Projects/TemporalTactileCounting
export SUBJECTS_DIR=${WORK_DIR}/derivatives/freesurfer
export FUNC_DIR=${WORK_DIR}/Data/phaseEncodedAnal/sub-${SUBJID}
export SURF_DIR=${FUNC_DIR}/TSeries/surfOverlays/TSeries_avg
hemi=rh

unset overlayString
# Find all volume overlay names in the folder and save as a long string to open with freeview:
overlayString="freeview -f ${SUBJECTS_DIR}/sub-${SUBJID}/surf/${hemi}.inflated"
for file in ${SURF_DIR}/${hemi}.*; do
  	fileString=":overlay=${SURF_DIR}/${file##*/}"
  	overlayString="${overlayString}${fileString}"
done
annotString=":label=${SUBJECTS_DIR}/sub-${SUBJID}/label/fingerROI/${hemi}.localizerROI.label:annot=${SUBJECTS_DIR}/sub-${SUBJID}/label/${hemi}.Glasser2016.annot:annot=${SUBJECTS_DIR}/sub-${SUBJID}/label/${hemi}.fingerROI.annot"
overlayString="${overlayString}${annotString}"

${overlayString}

