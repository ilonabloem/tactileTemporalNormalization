#!/bin/bash -l

# Setup paths - subj ID should be passed as an argument when calling this function
export SUBJID=${1}


# Freesurfer directory
export SUBJECTS_DIR=""

# Main experimental directory
export EXP_DIR=Volumes/server/Projects/TemporalTactileCounting

# Localizer session
export LOC_DIR=Volumes/server/Projects/TemporalTactile
export OLD_DIR=/${LOC_DIR}/Data/phaseEncodedAnal/sub-${SUBJID}/TSeries/surfOverlays/TSeries_avg


export newSUBJECTS_DIR=${EXP_DIR}/derivatives/freesurfer

# Functional data directory
export FUNC_DIR=/${EXP_DIR}/Data/phaseEncodedAnal/sub-${SUBJID}/TSeries
export VOL_DIR=${FUNC_DIR}/volOverlays/TSeries_avg
export SURF_DIR=${FUNC_DIR}/surfOverlays/TSeries_avg
export TARG_DIR=/${EXP_DIR}/derivatives/fmriprep/sub-${SUBJID}/ses-nyu3t01/func

# Create surface overlay directory:
mkdir -p ${SURF_DIR}
mkdir -p ${VOL_DIR}

unset overlayNames
# Find all surface overlay names in the localizer session:
counter=0;
for file in ${OLD_DIR}/lh.*; do
  echo "${file##*/}"
  tmp="${file##*/}"
  overlayNames[$counter]="${tmp:3}" # remove hemi indicator from name
  counter=$((counter+1))
done

# To check if overlayNames really has all the file names:
# echo ${overlayNames[*]}


for map in "${overlayNames[@]}"
	do

	for hemi in lh rh
		do

		export SUBJECTS_DIR=""

		# First bring surface into other session
		mri_surf2surf --srcsubject ${LOC_DIR}/derivatives/freesurfer/sub-${SUBJID} --trgsubject ${newSUBJECTS_DIR}/sub-${SUBJID} --hemi ${hemi}\
	 --sval ${OLD_DIR}/${hemi}.${map} --tval ${SURF_DIR}/${hemi}.${map}

		# Then bring surfaces into anatomical space
		# Assume identity as reg method
		export SUBJECTS_DIR="/${newSUBJECTS_DIR}"


		mri_surf2vol --surfval ${SURF_DIR}/${hemi}.${map} --subject sub-${SUBJID} --hemi ${hemi} --fillribbon --template ${SUBJECTS_DIR}/sub-${SUBJID}/mri/T1.mgz --identity sub-${SUBJID} --o ${VOL_DIR}/${hemi}.${map}

	done

		# Combine hemispheres - Note: there will be some overlapping voxels
		t1Name="${map:0:${#map}-6}T1.VOL.nii.gz"
		fslmaths.fsl ${VOL_DIR}/rh.${map} -add ${VOL_DIR}/lh.${map} ${VOL_DIR}/${t1Name}


		# Second transform into native functional resolution
		# Assume identity as reg method
		mri_vol2vol --regheader --s sub-${SUBJID} \
		--interp nearest \
		--mov ${VOL_DIR}/${t1Name} \
		--targ ${TARG_DIR}/sub-${SUBJID}_ses-nyu3t01_task-tact_run-01_space-T1w_boldref.nii.gz \
		--o ${VOL_DIR}/${map}


done
