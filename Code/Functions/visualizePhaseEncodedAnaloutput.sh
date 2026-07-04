#!/bin/bash -l

#visualizePhaseEncodedAnaloutput(){

export SUBJID=${1}
export WORK_DIR=/Volumes/server/Projects/TemporalTactileCounting
export SUBJECTS_DIR=${WORK_DIR}/derivatives/freesurfer
export FUNC_DIR=${WORK_DIR}/Data/phaseEncodedAnal/sub-${SUBJID}
export SURF_DIR=${FUNC_DIR}/TSeries/surfOverlays/TSeries_avg

unset overlayString

# Find all volume overlay names in the folder and save as a long string to open with freeview:
overlayString="freeview -f ${SUBJECTS_DIR}/sub-${SUBJID}/surf/lh.inflated"
for file in ${SURF_DIR}/lh.*; do
	fileString=":overlay=${SURF_DIR}/${file##*/}"
  	overlayString="${overlayString}${fileString}"
done
annotString=":annot=${SUBJECTS_DIR}/sub-${SUBJID}/label/lh.Glasser2016.annot:annot_outline=1"

rhString=" -f ${SUBJECTS_DIR}/sub-${SUBJID}/surf/rh.inflated"
overlayString="${overlayString}${annotString}${rhString}"
for file in ${SURF_DIR}/rh.*; do
  	fileString=":overlay=${SURF_DIR}/${file##*/}"
  	overlayString="${overlayString}${fileString}"
done
annotString=":annot=${SUBJECTS_DIR}/sub-${SUBJID}/label/rh.Glasser2016.annot:annot_outline=1"
overlayString="${overlayString}${annotString}"

echo ${overlayString}
${overlayString}

#}