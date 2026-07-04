#!/bin/bash -l

# compute tsnr maps

# Setup paths - subj ID should be passed as an argument when calling this function
export SUBJID=${1}
export SESID=${2}

# Main experimental directory
export EXP_DIR=/Volumes/server/Projects/TemporalTactileCounting
export WORK_DIR=${EXP_DIR}/sub-${SUBJID}/ses-${SESID}/func
export OUT_DIR=${EXP_DIR}/derivatives/tSNR/sub-${SUBJID}/ses-${SESID}

mkdir -p ${OUT_DIR}

# find all files
CURR_DIR="$PWD"

cd ${WORK_DIR}
# Find all file names in the folder and compute tsnr maps
for file in *bold.nii.gz; do
	
	echo "${file}"

  	# compute tsnr
  	fslmaths ${WORK_DIR}/${file} -Tmean ${OUT_DIR}/${file%_*}_mean.nii.gz
	fslmaths ${WORK_DIR}/${file} -Tstd ${OUT_DIR}/${file%_*}_std.nii.gz
	fslmaths ${OUT_DIR}/${file%_*}_mean.nii.gz -div ${OUT_DIR}/${file%_*}_std.nii.gz ${OUT_DIR}/${file%_*}_tSNR.nii.gz

done

cd $CURR_DIR

