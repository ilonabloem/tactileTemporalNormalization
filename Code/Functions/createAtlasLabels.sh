#!/bin/bash -l


	
export SUBJID=${1}
export SESS=nyu3t01
export WORK_DIR=/Volumes/server/Projects/TemporalTactileCounting
export SUBJECTS_DIR=${WORK_DIR}/derivatives/freesurfer
export ROI_SAVE_DIR=${WORK_DIR}/Data/roiVols/sub-${SUBJID}
export FUNC_DIR=${WORK_DIR}/derivatives/fmriprep/sub-${SUBJID}/ses-${SESS}
export LABEL_DIR=${SUBJECTS_DIR}/sub-${SUBJID}/label

export DO_IMPORT_NATIVESPACE=0
export DO_CONVERT_ATLAS=1

if [ "$DO_IMPORT_NATIVESPACE" == 1 ]; then
	## DO_IMPORT_NATIVESPACE
	# Transform annotation file with Wang2015 atlas ROIs into labels in indv subject space
	mri_surf2surf --srcsubject fsaverage --trgsubject sub-$SUBJID --hemi rh --sval-annot $SUBJECTS_DIR/fsaverage/label/rh.Wang2015 --tval $SUBJECTS_DIR/sub-${SUBJID}/label/rh.Wang2015.annot
	mri_surf2surf --srcsubject fsaverage --trgsubject sub-$SUBJID --hemi lh --sval-annot $SUBJECTS_DIR/fsaverage/label/lh.Wang2015 --tval $SUBJECTS_DIR/sub-${SUBJID}/label/lh.Wang2015.annot

	mkdir -p $SUBJECTS_DIR/sub-${SUBJID}/label/Wang2015

	mri_annotation2label --subject sub-$SUBJID --hemi rh --annotation Wang2015 --outdir ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015
	mri_annotation2label --subject sub-$SUBJID --hemi lh --annotation Wang2015 --outdir ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015

	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V1v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V1d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V1.label
	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V1v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V1d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V1.label

	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V2v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V2d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V2.label
	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V2v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V2d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V2.label

	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V3v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V3d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/lh.V3.label
	mri_mergelabels -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V3v.label -i ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V3d.label -o ${SUBJECTS_DIR}/sub-${SUBJID}/label/Wang2015/rh.V3.label

	# Transform annotation file with Glasser2016 atlas ROIs into labels in indv subject space
	mri_surf2surf --srcsubject fsaverage --trgsubject sub-$SUBJID --hemi rh --sval-annot $SUBJECTS_DIR/fsaverage/label/rh.Glasser2016 --tval $SUBJECTS_DIR/sub-${SUBJID}/label/rh.Glasser2016.annot
	mri_surf2surf --srcsubject fsaverage --trgsubject sub-$SUBJID --hemi lh --sval-annot $SUBJECTS_DIR/fsaverage/label/lh.Glasser2016 --tval $SUBJECTS_DIR/sub-${SUBJID}/label/lh.Glasser2016.annot

	mkdir -p $SUBJECTS_DIR/sub-${SUBJID}/label/Glasser2016

	mri_annotation2label --subject sub-$SUBJID --hemi rh --annotation Glasser2016 --outdir ${SUBJECTS_DIR}/sub-${SUBJID}/label/Glasser2016
	mri_annotation2label --subject sub-$SUBJID --hemi lh --annotation Glasser2016 --outdir ${SUBJECTS_DIR}/sub-${SUBJID}/label/Glasser2016

fi

	## DO_CONVERT_ATLAS
	# Create folder to save volumes in
	mkdir -p ${ROI_SAVE_DIR}

	for hemi in lh rh
	do

		# Transform label/annotation into the volume. Template defines the functional data resolution of the 3D volume 
		# Here is used the first functional run boldref scan. Note: can not be a 4D volume (i.e. timeseries)
		mri_label2vol --o ${ROI_SAVE_DIR}/${hemi}.Wang2015.VOL.nii.gz \
		--annot ${LABEL_DIR}/${hemi}.Wang2015.annot \
		--temp ${FUNC_DIR}/func/sub-${SUBJID}_ses-${SESS}_task-tact_run-01_space-T1w_boldref.nii.gz \
		--fillthresh 0.5 --proj frac 0 1 .1 --subject sub-${SUBJID} --hemi $hemi \
		--regheader ${SUBJECTS_DIR}/sub-${SUBJID}/mri/T1.mgz

		mri_label2vol --o ${ROI_SAVE_DIR}/${hemi}.Glasser2016.VOL.nii.gz \
		--annot ${LABEL_DIR}/${hemi}.Glasser2016.annot \
		--temp ${FUNC_DIR}/func/sub-${SUBJID}_ses-${SESS}_task-tact_run-01_space-T1w_boldref.nii.gz \
		--fillthresh 0.5 --proj frac 0 1 .1 --subject sub-${SUBJID} --hemi $hemi \
		--regheader ${SUBJECTS_DIR}/sub-${SUBJID}/mri/T1.mgz

	done


