#!/bin/bash -l

export SUBJID=${1}
export SESS=${2}
#ses-nyu3t01
export PROJECT_DIR=/Volumes/server/Projects/tactileTemporalNormalization
export WORK_DIR=${PROJECT_DIR}/derivatives
export SUBJECTS_DIR=${WORK_DIR}/freesurfer
export FUNC_DIR=${WORK_DIR}/fmriprep/sub-${SUBJID}/${SESS}
export LUT_DIR=`pwd`/functions

export ROI_SAVE_DIR=${PROJECT_DIR}/Data/roiVols/sub-${SUBJID}
export LABEL_DIR=${SUBJECTS_DIR}/sub-${SUBJID}/label

mkdir -p ${ROI_SAVE_DIR}

# create annot file for finger ROIs and transform into the volume
# for all participants this was the RH
for hemi in rh
do

    mris_label2annot --s sub-${SUBJID} --h ${hemi} \
      --ctab ${LUT_DIR}/fingerROI_colorLUT.txt --a fingerROI \
      --l ${SUBJECTS_DIR}/sub-${SUBJID}/label/fingerROI/${hemi}.thumb.label \
      --l ${SUBJECTS_DIR}/sub-${SUBJID}/label/fingerROI/${hemi}.index.label \
      --l ${SUBJECTS_DIR}/sub-${SUBJID}/label/fingerROI/${hemi}.middle.label \
      --l ${SUBJECTS_DIR}/sub-${SUBJID}/label/fingerROI/${hemi}.ring.label \
      --l ${SUBJECTS_DIR}/sub-${SUBJID}/label/fingerROI/${hemi}.little.label 

    # Transform label/annotation into the volume. Template defines the functional data resolution of the 3D volume 
    # Here is used the first functional run boldref scan. Note: can not be a 4D volume (i.e. timeseries)
    mri_label2vol --o ${ROI_SAVE_DIR}/${hemi}.fingerROI.VOL.nii.gz \
    --annot ${LABEL_DIR}/${hemi}.fingerROI.annot \
    --temp ${FUNC_DIR}/func/sub-${SUBJID}_${SESS}_task-tact_run-01_space-T1w_boldref.nii.gz \
    --fillthresh 0.5 --proj frac 0 1 .1 --subject sub-${SUBJID} --hemi $hemi \
    --regheader ${SUBJECTS_DIR}/sub-${SUBJID}/mri/T1.mgz

     mri_label2vol --o ${ROI_SAVE_DIR}/${hemi}.localizerROI.VOL.nii.gz \
    --label ${LABEL_DIR}/fingerROI/${hemi}.localizerROI.label \
    --temp ${FUNC_DIR}/func/sub-${SUBJID}_${SESS}_task-tact_run-01_space-T1w_boldref.nii.gz \
    --fillthresh 0.5 --proj frac 0 1 .1 --subject sub-${SUBJID} --hemi $hemi \
    --regheader ${SUBJECTS_DIR}/sub-${SUBJID}/mri/T1.mgz

done


for hemi in lh rh
do
    mri_label2vol --o ${ROI_SAVE_DIR}/${hemi}.Glasser2016.VOL.nii.gz \
    --annot ${LABEL_DIR}/${hemi}.Glasser2016.annot \
    --temp ${FUNC_DIR}/func/sub-${SUBJID}_${SESS}_task-tact_run-01_space-T1w_boldref.nii.gz \
    --fillthresh 0.5 --proj frac 0 1 .1 --subject sub-${SUBJID} --hemi $hemi \
    --regheader ${SUBJECTS_DIR}/sub-${SUBJID}/mri/T1.mgz

done
