#!/bin/bash -l

#transformPhaseEncodedAnalVol2Surf(){

# Setup paths - subj ID should be passed as an argument when calling this function
export SUBJID=${1}
# Main experimental directory
export EXP_DIR=/Volumes/server/Projects/TemporalTactileCounting
# Freesurfer directory
export SUBJECTS_DIR=${EXP_DIR}/derivatives/freesurfer
# Functional data directory
export FUNC_DIR=${EXP_DIR}/Data/phaseEncodedAnal/sub-${SUBJID}/TSeries
export VOL_DIR=${FUNC_DIR}/volOverlays/TSeries_avg
export SURF_DIR=${FUNC_DIR}/surfOverlays/TSeries_avg

# Create surface overlay directory:
mkdir -p ${SURF_DIR}

unset overlayNames
# Find all volume overlay names in the folder:
counter=0;
for file in ${VOL_DIR}/*; do
  echo "${file##*/}"
  overlayNames[$counter]="${file##*/}"
  counter=$((counter+1))
done

# To check if overlayNames really has all the file names:
# echo ${overlayNames[*]}


for map in "${overlayNames[@]}"
	do

	for hemi in lh rh
		do

		mri_vol2surf --mov ${VOL_DIR}/${map} \
		--regheader sub-${SUBJID}  --hemi ${hemi} --projfrac 0.5 \
		--o ${SURF_DIR}/${hemi}.${map}

		#mri_vol2surf --mov ${FUNC_DIR}/volOverlays/vtGLM_unthresh_R2.nii.gz \
		#--regheader sub-${SUBJID}  --hemi ${hemi} --projfrac 0.5 \
		#--o ${FUNC_DIR}/surfOverlays/${hemi}.vtGLM_unthresh_R2.nii.gz 

		#mri_vol2surf --mov ${FUNC_DIR}/volOverlays/GLM_unthreshROI_highFreqhighAmpl_FingerMap.nii.gz \
		#--regheader sub-${SUBJID}  --hemi ${hemi} --projfrac 0.5 \
		#--o ${FUNC_DIR}/surfOverlays/${hemi}.GLM_unthreshROI_highFreqhighAmpl_FingerMap.nii.gz 

	done

done

#}