#!/usr/bin/env nextflow

// GLOBAL PARAMETERS
date = new Date().format( 'yyyyMMdd' )

// USER INPUT PARAMETERS
params.meltvcf 	    = 	null
params.RM_track     = 	null // Default RM track for hg19 and hg38 are available in the "Ressources" folder
params.TE 		      = 	"Alu" // SHOULD DISAPEAR TO ALLOW ALL TE AT THE SAME TIME
params.outdir	      = 	"TypeREF-${date}"
params.help		      =	  null
params.ref          =   null
params.aln_path     =   null
params.aln_samples  =   null
params.cpu          =   1
params.version      =   "0.0-dev"


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
  ./nextflow run  TypeREF.nf --meltvcf melt.del.vcf(.gz) --ref reference.genome.fasta --RM_track reference.TE.bed --aln_path path.to.bam.cram.dir --aln_samples samples.ID.filename.table [options]
  
  Input:
  --meltvcf       vcf (/vcf.gz) file preduced by MELT-DEL pipeline (Deletion-Merge command)
  --ref           reference genome used with MELT (.fasta)
  --RM_track      RepeatMasker track for reference MEI (.bed) note: RM track for hg19 and hg38 are available in the "Ressources" folder
  --aln_path      path to bam/cram directory (all samples need to be in the same directory however, 
                  the files to analyse will be only those in the aln_samples table)
  --aln_samples   two columns (tab delimited) with samples ID in column 1 and associated samples file names (.bam/.cram) in column 2. 
                  ex: NA12878  NA12878.project.blah.bam
                      NA12831  NA12831.project.blah.bam
  Output:
  --outdir        output directory to store results
  
  Options:
  --cpu           max number of cpu to use during parralelized tasks (default: 1)
  --TE            TE type to be genotyped: Alu | LINE1 | SVA (default: Alu)
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
meltvcf_ch        =   Channel.fromPath(params.meltvcf)
RMtrack_ch        =   Channel.fromPath(params.RM_track)
alignPath_ch      =   Channel.fromPath(params.aln_path)
alignSamples_ch   =   Channel
                            .fromPath(params.aln_samples)
                            .splitCsv(sep: '\t', header:true)
                            .map { row -> tuple(row.sampleId, file(row.fileId)) }

// split the ref genome into independent input channels for each process
ref_TSD           =   Channel.fromPath(params.ref)
ref_genoinput     =   Channel.fromPath(params.ref)
ref_geno_gen_ch   =   Channel.fromPath(params.ref)
// load insertion-genotype submodules into dedicated channels
insgen_prep_ch    =   Channel.fromPath( './bin/insertion-genotype/' )
insgen_gen_ch     =   Channel.fromPath( './bin/insertion-genotype/' )

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
  file "TypeREF.allele" into input_Geno_ch_1
  file "TypeREF.allele" into input_Geno_ch_2
  //file 'inputGenotypes.log' into log_ch

  script:
  """
  paste <(sort -k1,1 output_TSD_Intervals.out/TEcordinates_with_bothtsd_cordinates.v.3.4.txt) <(sort -k1,1 file.correspondingRepeatMaskerTEs.txt) | cut -f 1-4,11 > RM_insertions_TSD_strands
  deletion_create_input.sh RM_insertions_TSD_strands $ref > TypeREF.allele
  """
  
  }

// --------------------------------------
// STEP 5 - (sub: INSERTION-GENOTYPE 1/2)
// CREATE alleles and index with bwa
// --------------------------------------
process insgen_createAlleles {

  input:
  file "TypeREF.allele" from input_Geno_ch_1
 // file "insertion-genotype" from insgen_prep_ch


  output:
  file genotyping into allelebase_ch

  script:
  """
  mkdir genotyping
  python2.7 $workflow.projectDir/bin/insertion-genotype/create-alternative-alleles.py --allelefile TypeREF.allele --allelebase genotyping --bwa bwa
  """
  
  }

//--------------------------------------
//STEP 6 - (sub: INSERTION-GENOTYPE 2/2)
//GENOTYPE!!!!!!!
//--------------------------------------
// TO DO:

process insgen_genotype {

  publishDir "${params.outdir}/", mode: 'copy'

  input:
  set sampleId, file(fileId) from alignSamples_ch
  file "TypeREF.allele" from input_Geno_ch_2.collect()
  file "genotyping" from allelebase_ch.collect()
  file "alignments" from alignPath_ch.collect()
 
  output:
  file "genotyping/samples/$sampleId/*.vcf" into samplegeno_ch
  
  script:
  """
  python2.7 $workflow.projectDir/bin/insertion-genotype/process-sample.py --allelefile TypeREF.allele --allelebase genotyping --samplename ${sampleId} --bwa bwa --bam $alignments/${fileId} --reference ${params.ref}
  """
  }



