#!/bin/bash -l

export SUBJID=${1}
export SESS=${2}
export WORK_DIR=/Volumes/server/Projects/tactileTemporalNormalization
export SUBJECTS_DIR=${WORK_DIR}/derivatives/freesurfer
export ROI_SAVE_DIR=${WORK_DIR}/Data/roiVols/sub-${SUBJID}
export FUNC_DIR=${WORK_DIR}/derivatives/fmriprep/sub-${SUBJID}/ses-${SESS}
export FUNCTION_DIR=$(pwd)/functions

export LABEL_FILE=${SUBJECTS_DIR}/sub-${SUBJID}/label/Glasser2016/lh.1.label
export SURF_FILE=${WORK_DIR}/Data/phaseEncodedAnal/sub-${SUBJID}/TSeries/surfOverlays/TSeries_avg/lh.thresCo_sub-${SUBJID}_allRuns_wholeBrain.nii.gz
export ROI_FILE=${SUBJECTS_DIR}/sub-${SUBJID}/label/rh.fingerROI.annot

# If Glasser2016 labels do not exist, call createAtlasLabels.sh
if [ -f "${LABEL_FILE}" ] ; then
    echo "Glasser2016 labels already exist."
else
    echo "Creating labels..."
    source ${FUNCTION_DIR}/createAtlasLabels.sh ${SUBJID}
    createAtlasLabels ${SUBJID}    
fi

# If surface file do not exist, call transformPhaseEncodedAnalVol2Surf.sh
if [ -f "${SURF_FILE}" ] ; then
    echo "Surface files already exist."
else   
    echo "Transform phase encoded analysis outputs from volumes to surface..."
    source ${FUNCTION_DIR}/transformPhaseEncodedAnalVol2Surf.sh ${SUBJID}
    transformPhaseEncodedAnalVol2Surf ${SUBJID}
fi

# Visualize phase encoded analysis output with ROIs if exists
if [ -f "${ROI_FILE}" ] ; then
    source ${FUNCTION_DIR}/visualizePhaseEncodedAnaloutput.sh ${SUBJID}
    visualizePhaseEncodedAnaloutput ${SUBJID}
else
    echo "Loading ROIs..."
    source ${FUNCTION_DIR}/visualizeFingerROIs.sh ${SUBJID}
    visualizeFingerROIs ${SUBJID}

fi