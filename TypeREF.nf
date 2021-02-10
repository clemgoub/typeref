#!/usr/bin/env nextflow

// GLOBAL PARAMETERS
date = new Date().format( 'yyyyMMdd' )

// USER INPUT PARAMETERS
params.meltvcf 	= 	null
params.RM_track = 	"Ressources/RepeatMasker_Alu_hg19.bed" // Default RM track is HG19 for ALU
params.TE 		  = 	"Alu" // SHOULD DISAPEAR TO ALLOW ALL TE AT THE SAME TIME
params.out		  = 	"TypeREF-${date}"
params.help		  =	  null
params.ref      =   null
params.version  =   "0.0-dev"

// SAY HELLO

log.info """




████████╗██╗   ██╗██████╗ ███████╗    ██████╗ ███████╗███████╗
╚══██╔══╝╚██╗ ██╔╝██╔══██╗██╔════╝    ██╔══██╗██╔════╝██╔════╝
   ██║    ╚████╔╝ ██████╔╝█████╗█████╗██████╔╝█████╗  █████╗  
   ██║     ╚██╔╝  ██╔═══╝ ██╔══╝╚════╝██╔══██╗██╔══╝  ██╔══╝  
   ██║      ██║   ██║     ███████╗    ██║  ██║███████╗██║     
   ╚═╝      ╚═╝   ╚═╝     ╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝   

                           V . ${params.version}

Genotyping mobile elements insertions included in a reference genome                                                

"""

//print usage
if (params.help) {
  log.info """
  ------------------------------------------------
    -|-  Type-REF v${params.version}. help   -|-
  ------------------------------------------------
  
  Usage:
  ./nextflow run  TypeREF.nf --meltvcf melt.del.vcf(.gz) --ref reference.genome.fasta [options]
  
  Input:
  --meltvcf       vcf (/vcf.gz) file preduced by MELT-DEL pipeline (Deletion-Merge command)
  --ref           reference genome used with MELT (.fasta)
  
  Options:
  --TE            TE type to be genotyped: Alu | LINE1 | SVA (default: Alu)
  --RM_track      RepeatMasker track for reference MEI (.bed) (default: Ressources/RepeatMasker_Alu_hg19.bed)
  --help          this message
  """
  exit 1
}

// VALIDATE INPUT
if ( params.meltvcf == null ) exit 1, "missing input (--meltvcf *vcf/vcf.gz)"
if ( params.RM_track == null ) exit 1, "missing Repeat Masker track (--RM_track *.bed)"
if ( params.TE == null ) exit 1, "missing TE type (any: \"Alu\", \"LINE1\", \"SVA\")"
if ( params.ref == null ) exit 1, "missing reference genome (--ref *.fasta)"


// ASSIGN INPUT CHANNELS WITH USER-DEFINED FILE PATH
meltvcf_ch       =   Channel.fromPath(params.meltvcf)
RMtrack_ch       =   Channel.fromPath(params.RM_track)
//ref_ch      =   Channel.fromPath(params.ref)
ref_TSD          =   Channel.fromPath(params.ref)
ref_genoinput    =   Channel.fromPath(params.ref)
// split the ref genome into independent input channels for each process
//ref_ch.into { ref_TSD; ref_genoinput } 

// ----------------------------------------
// STEP 1
// EXTRACT LOCI LIST AND INFO FROM MELT VCF
// ----------------------------------------

process inputFromMelt {
	input:
	file meltvcf from meltvcf_ch // takes the file from the path in the channel
    
    output:
    file "infile" into TypeDEL_in // will output in new channel TypeDEL_in

    script:
    """
   	input_from_melt_Del.sh $meltvcf > infile

	"""
}

// ----------------------------------------------
// STEP 2
// MATCH MELT LOCI WITH REPEAT MASKER COORDINATES
// ----------------------------------------------

process matchRMloci {

	input:
	file infile from TypeDEL_in // takes the imput from precedent step (TypeTE specific input)
	file RM_track from RMtrack_ch // takes the TE type
	//string TE from TE_ch

	output:
	file "file.correspondingRepeatMaskerTEs.txt" into RM_refTSD // RM channel to host the output file for next process
  file "file.correspondingRepeatMaskerTEs.txt" into RM_inGeno // RM channel to host the output file for geno process
	// if 'chr' in the vcf keep like that, otherwise, remove the 'chr' from the RM track for the bedtool intersct!
	script:
	"""
	if grep -q "chr" $infile
	then
	01_DelP_findcorrespondinginsertion_v3.3.pl -t $RM_track -f $infile -p . -te ${params.TE}
	else
	sed 's/chr//g' $RM_track > RM_track.alt
	01_DelP_findcorrespondinginsertion_v3.3.pl -t RM_track.alt -f $infile -p . -te ${params.TE}
	fi
	"""
}

// -------------
// STEP 3
// REFINE TSDs
// -------------

process findTSDs {

  input:
  file "file.correspondingRepeatMaskerTEs.txt" from RM_refTSD 
  file ref from ref_TSD

  output:
  file "output_TSD_Intervals.out" into TSD // TSD channel to host the output file
  //file "output_TSD_Intervals.out/TEcordinates_with_bothtsd_cordinates.v.3.4.txt" into TSD_1
  //file "output_TSD_Intervals.out/file.correspondingRepeatMaskerTEs.txt" into TSD_2

  script:
  """
  03_DelP_findTSD_forRMTEcordinates_v3.4.pl -t file.correspondingRepeatMaskerTEs.txt -p output_TSD_Intervals.out -g $ref
  """
  }

// -------------------------------------
// STEP 4
// CREATE INPUTS FOR insertion-genotype
// -------------------------------------

process inputGenotypes {

  input:
  file "output_TSD_Intervals.out" from TSD
  file "file.correspondingRepeatMaskerTEs.txt" from RM_inGeno
  file ref from ref_genoinput

  output:
  file "RM_insertions_TSD_strands" into interm_ch
  file "TypeREF.allele" into input_Geno_ch // TSD channel to host the output file
  //file 'inputGenotypes.log' into log_ch

  script:
  """
  paste <(sort -k1,1 output_TSD_Intervals.out/TEcordinates_with_bothtsd_cordinates.v.3.4.txt) <(sort -k1,1 file.correspondingRepeatMaskerTEs.txt) | cut -f 1-4,11 > RM_insertions_TSD_strands
  deletion_create_input.sh RM_insertions_TSD_strands $ref > TypeREF.allele
  """
  
  }