#!/bin/bash
for ses_dir in sourcedata/cneuromod.emotion-videos.fmriprep/sub-*/ses-*; do
 BIDS_SUB_SES_DIR=${ses_dir#*fmriprep/}; echo $BIDS_SUB_SES_DIR ; out_prefix=${BIDS_SUB_SES_DIR}/func/; 
 for f in sourcedata/*fmriprep*/${BIDS_SUB_SES_DIR}/func/*_echo-1_*desc-preproc_bold.nii.gz ; do  
        in_prefix=${f%_echo-1_*desc-preproc_bold.nii.gz};         file_prefix=${in_prefix##*/func/};         mkdir -p ${out_prefix%*};         echo_times=$(jq -j '.EchoTime*1000|tostring + " "' $(ls ${in_prefix}_echo-*_*.json | sort ));         first_echo_nii=$(ls ${in_prefix}_echo-1_*-preproc_bold.nii.gz);
       acq_duration=$(python -c "import nibabel; print(nibabel.load('${first_echo_nii}').shape[3])");         tedpca_value=$(jq -r "(${acq_duration} / .RepetitionTime / 2) | floor" "${in_prefix}"_echo-1_*-preproc_bold.json);         mask_nii=$(compgen -G ${in_prefix}'*'_desc-brain_mask.nii.gz | grep -v space);
       if [ -e ${out_prefix}/${file_prefix}_tedana_report.html ]; then continue ; fi
    echo "## running tedana on ${in_prefix}";
    eval "datalad containers-run -n containers/tedana \
           \
          -- \
          --out-dir ${out_prefix} \
          --prefix ${file_prefix} \
          --mask ${mask_nii} \
          -d ${in_prefix}_echo-*_desc-preproc_bold.nii.gz \
          -e $echo_times \
          --tedpca aic \
          --fittype curvefit --ica-method robustica --n-robust-runs 50 --tree code/tedana_decision_tree.json --external ${in_prefix}*_desc-confounds_timeseries.tsv" ;
  done ; done
