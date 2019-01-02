#!/usr/bin/env bash

###################################################################
#   ✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡✡   #
###################################################################

###################################################################
# SPECIFIC MODULE HEADER
# This module performs basic structural data processing.
###################################################################
mod_name_short=antsCT
mod_name='STRUCTURAL PROCESSING MODULE'
mod_head=${XCPEDIR}/core/CONSOLE_MODULE_AFGR

###################################################################
# GENERAL MODULE HEADER
###################################################################
source ${XCPEDIR}/core/constants
source ${XCPEDIR}/core/functions/library.sh
source ${XCPEDIR}/core/parseArgsMod

###################################################################
# MODULE COMPLETION
###################################################################
completion() {
   if is_image ${referenceVolumeBrain[cxt]}
      then
      space_set   ${spaces[sub]}   ${space[sub]} \
            Map   ${referenceVolumeBrain[cxt]}
   fi

   exec_xcp spaceMetadata                       \
      -o    ${spaces[sub]}                      \
      -f    ${standard}:${template}             \
      -m    ${space[sub]}:${struct[cxt]}        \
      -x    ${xfm_affine[cxt]},${xfm_warp[cxt]} \
      -i    ${ixfm_warp[cxt]},${ixfm_affine[cxt]} \
      -s    ${spaces[sub]}

   source ${XCPEDIR}/core/auditComplete
   source ${XCPEDIR}/core/updateQuality
   source ${XCPEDIR}/core/moduleEnd
}





###################################################################
# OUTPUTS
###################################################################
derivative  corticalThickness       ${prefix}_CorticalThickness
derivative  mask                    ${prefix}_BrainExtractionMask
derivative  segmentation            ${prefix}_BrainSegmentation

for i in {1..6}
   do
   output   segmentationPosteriors  ${prefix}_BrainSegmentationPosteriors${i}.nii.gz
done

derivative_set corticalThickness    Statistic        mean
derivative_set mask                 Type             Mask

output      struct_std              ${prefix}_BrainNormalizedToTemplate.nii.gz
output      corticalThickness_std   ${prefix}_CorticalThicknessNormalizedToTemplate.nii.gz
output      ctroot                  ${prefix}_
output      referenceVolume         ${prefix}_BrainSegmentation0N4.nii.gz
output      referenceVolumeBrain    ${prefix}_ExtractedBrain0N4.nii.gz
output      meanIntensity           ${prefix}_BrainSegmentation0N4.nii.gz
output      meanIntensityBrain      ${prefix}_ExtractedBrain0N4.nii.gz
output      str2stdmask             ${prefix}_str2stdmask.nii.gz
output      xfm_affine              ${prefix}_SubjectToTemplate0GenericAffine.mat
output      xfm_warp                ${prefix}_SubjectToTemplate1Warp.nii.gz
output      ixfm_affine             ${prefix}_TemplateToSubject1GenericAffine.mat
output      ixfm_warp               ${prefix}_TemplateToSubject0Warp.nii.gz

configure   template_priors         $(space_get ${standard} Priors)
configure   template_head           $(space_get ${standard} MapHead)
configure   template_mask           $(space_get ${standard} Mask)
configure   template_mask_dil       $(space_get ${standard} MaskDilated)
configure   template_brain_prior    $(space_get ${standard} BrainPrior)

qc reg_cross_corr regCrossCorr      ${prefix}_regCrossCorr.txt
qc reg_coverage   regCoverage       ${prefix}_regCoverage.txt
qc reg_jaccard    regJaccard        ${prefix}_regJaccard.txt
qc reg_dice       regDice           ${prefix}_regDice.txt

input image mask
input image segmentation

add_reference                       template template

final       struct                  ${prefix}_ExtractedBrain0N4

<< DICTIONARY

corticalThickness
   The voxelwise map of cortical thickness values.
corticalThickness_std
   The voxelwise map of cortical thickness values following
   normalisation.
ctroot
   The base name of the path for all outputs of the ANTs Cortical
   Thickness pipeline.
ixfm_affine
   A matrix that defines an affine transformation from standard
   space to anatomical space.
ixfm_warp
   A distortion field that defines a nonlinear diffeomorphic warp
   from standard space to anatomical space.
mask
   A spatial mask of binary values, indicating whether a voxel
   should be analysed as part of the brain. This is the output of
   the skull-strip/brain extraction procedure.
meanIntensity,meanIntensityBrain
   For compatibility exporting to other modules.
referenceVolume,referenceVolumeBrain
   For compatibility exporting to other modules.
reg_coverage
   The percentage of the template image that is covered by the
   normalised anatomical image.
reg_cross_corr
   The spatial cross-correlation between the template image mask
   and the normalised anatomical mask.
reg_dice
   The Dice coefficient between the template and anatomical image.
reg_jaccard
   The Jaccard coefficient between the template and anatomical
   image.
segmentation
   The deterministic (hard) segmentation of the brain into tissue
   classes.
segmentationPosteriors
   Probabilistic (soft) maps specifying for each voxel the
   estimated probability that the voxel belongs to each tissue
   class.
struct
   The fully processed (bias-field corrected and skull-stripped)
   brain in native anatomical space.
struct_std
   The subject\'s brain following normalisation to a standard or
   template space. This should not be processed as a derivative.
xfm_affine
   A matrix that defines an affine transformation from anatomical
   space to standard space.
xfm_warp
   A distortion field that defines a nonlinear diffeomorphic warp
   from anatomical space to standard space.

DICTIONARY





#(( ${trace} > 1 )) && ants_verbose=1 || ants_verbose=0
priors_get=$(echo ${template_priors[cxt]//\%03d/\?\?\?})
priors_get=( $(eval ls ${priors_get}) )
for i in ${!priors_get[@]}
   do
   (( i++ ))
   priors[i]=$(printf ${template_priors[cxt]} ${i})
done
prior_space=${standard}
###################################################################
# The variable 'buffer' stores the processing steps that are
# already complete; it becomes the expected ending for the final
# image name and is used to verify that prestats has completed
# successfully.
###################################################################
unset buffer

subroutine                    @0.1

###################################################################
# Ensure that the input image is stored in the same orientation
# as the template. If not, reorient it to match
###################################################################
routine                 @0    Ensure matching orientation
subroutine              @0.1a Input: ${intermediate}.nii.gz
subroutine              @0.1b Template: ${template}
subroutine              @0.1c Output root: ${ctroot[cxt]}

native_orientation=$(${AFNI_PATH}/3dinfo -orient ${intermediate}.nii.gz)
template_orientation=$(${AFNI_PATH}/3dinfo -orient ${template})

echo "NATIVE:${native_orientation} TEMPLATE:${template_orientation}"
full_intermediate=$(ls ${intermediate}.nii* | head -n 1)
if [ "${native_orientation}" != "${template_orientation}" ]
then

    subroutine @0.1d "${native_orientation} -> ${template_orientation}"
    ${AFNI_PATH}/3dresample -orient ${template_orientation} \
              -inset ${full_intermediate} \
              -prefix ${intermediate}_${template_orientation}.nii.gz
    intermediate=${intermediate}_${template_orientation}
    intermediate_root=${intermediate}
else

    subroutine  @0.1d "NOT re-orienting T1w"

fi

###################################################################
# Parse the control sequence to determine what routine to run next.
# Available routines include:
#  * ACT: ANTs CT pipeline. This routine subsumes all others.
###################################################################




      #############################################################
      # ACT runs the complete ANTs cortical thickness pipeline.
      #############################################################
      routine                 @1    ANTs cortical thickness pipeline
      subroutine              @1.1a Input: ${intermediate}.nii.gz
      subroutine              @1.1b Template: ${template}
      subroutine              @1.1c Output root: ${ctroot[cxt]}
      subroutine              @1.x  Delegating control to ANTsCT
        ${ANTSPATH}/antsCorticalThickness.sh  \
        -d 3 \
        -a ${intermediate}.nii.gz \
        -e ${template_head[cxt]} \
        -m ${template_brain_prior[cxt]} \
        -f ${template_mask_dil[cxt]} \
        -p ${template_priors[cxt]} \
        -w ${antsCT_prior_weight[cxt]}  \
        -t ${template} \
        -o ${ctroot[cxt]}

        exec_sys ln -sf ${struct[cxt]} ${intermediate}.nii.gz
         intermediate=${intermediate}
    


###################################################################
# CLEANUP
#  * Test for the expected output. This should be the initial
#    image name with any routine suffixes appended.
#  * If the expected output is present, move it to the target path.
#  * If the expected output is absent, notify the user.
###################################################################
if is_image ${intermediate_root}${buffer}.nii.gz
   then
   subroutine                 @0.3
   processed=$(readlink -f    ${intermediate}.nii.gz)
   exec_sys imcp ${processed} ${struct[cxt]}
   ################################################################
   # Ensure that a mask is available for future modules. If one
   # hasn't been generated, assume that the input was already
   # masked.
   ################################################################
   if ! is_image ${mask[cxt]}
      then
      subroutine              @0.2
      exec_fsl fslmaths ${struct[cxt]} \
         -bin  ${mask[cxt]}
   fi
   completion
else
   subroutine                 @0.4
   abort_stream \
"Expected output not present.]
[Expected: ${buffer}]
[Check the log to verify that processing]
[completed as intended."
fi
