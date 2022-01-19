#!/usr/bin/env nextflow

// GLOBAL PARAMETERS
date = new Date().format( 'yyyyMMdd' )

// USER INPUT PARAMETERS
params.meltvcf 	    = 	null
params.bed          =   null
params.RM_track     = 	null // Default RM track for hg19 and hg38 are available in the "Ressources" folder
params.TE 		      = 	"Alu" // SHOULD DISAPEAR TO ALLOW ALL TE AT THE SAME TIME
params.outdir	      = 	"TypeREF-${date}"
params.help		      =	  null
params.ref          =   null
params.aln_path     =   null
params.aln_samples  =   null
params.maxr         =   10
params.exportBams   =   null
// params.cpu          =   1
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
  ./nextflow run  TypeREF.nf [--meltvcf melt.del.vcf(.gz)/--bed RefTE.coordinates.bed] --ref reference.genome.fasta --RM_track reference.TE.bed --aln_path path.to.bam.cram.dir --aln_samples samples.ID.filename.table [options]
  
  Input:
  --meltvcf       vcf (/vcf.gz) file preduced by MELT-DEL pipeline (Deletion-Merge command)
  or
  --bed           bed file with coordinates of Reference TE to genotype

  --ref           reference genome used with MELT (.fasta)
  --RM_track      RepeatMasker track for reference MEI (.bed) note: RM track for hg19 and hg38 are available in the "Ressources" folder
  --aln_path      path to bam/cram directory (all samples need to be in the same directory however, 
                  the files to analyse will be only those in the aln_samples table)
  --aln_samples   two columns (tab delimited) with header and samples ID in column 1 and associated samples file names (.bam/.cram) in column 2. 
                  ex: sampleId fileId
                      NA12878  NA12878.project.blah.bam
                      NA12831  NA12831.project.blah.bam
  --maxr          maximum number of fragments mapping to each allele (cap to avoid ref allele inflation)

  Output:
  --outdir        output directory to store results
  --exportBams    export re-alignments for each sample in a .tar.gz archive
  
  Options:
  --TE            TE type to be genotyped: Alu | L1 | SVA (default: Alu)
  --help          this message
  """
  exit 1
}

// VALIDATE INPUT
// if ( params.meltvcf == null ) exit 1, "missing input (--meltvcf *vcf/vcf.gz)"
if ( params.RM_track == null ) exit 1, "Error: missing Repeat Masker track (--RM_track *.bed)"
if ( params.TE == null ) exit 1, "Error: missing TE type (any: \"Alu (default)\", \"L1\", \"SVA\")"
if ( !( params.TE == "Alu" || params.TE == "L1" || params.TE == "SVA" )) exit 1, "Error: incorrect TE type entered (use any: \"Alu (default)\", \"L1\", \"SVA\")"
if ( params.ref == null ) exit 1, "Error: missing reference genome (--ref *.fasta)"
if ( params.meltvcf != null && params.bed != null ) exit 1, "Error: --meltvcf and --bed are exclusive"
if ( params.meltvcf == null && params.bed == null ) exit 1, "Error: no TE breakpoints provided (--meltvcf or --bed)"


// ASSIGN INPUT CHANNELS WITH USER-DEFINED FILE PATH
RMtrack_in        =   Channel.fromPath(params.RM_track)
RMtrack_ch        =   Channel.fromPath(params.RM_track)
alignPath_ch      =   Channel.fromPath(params.aln_path)
alignSamples_ch   =   Channel
                            .fromPath(params.aln_samples)
                            .splitCsv(sep: '\t', header:true)
                            .map { row -> tuple(row.sampleId, file(row.fileId)) }
alignSamples_ch2   =   Channel
                            .fromPath(params.aln_samples)
                            .splitCsv(sep: '\t', header:true)
                            .map { row -> value(row.sampleId) }                            
if ( params.meltvcf != null )
     in_ch = Channel.fromPath(params.meltvcf)
else
     in_ch = Channel.fromPath(params.bed)
// split the ref genome into independent input channels for each process
ref_TSD           =   Channel.fromPath(params.ref)
ref_genoinput     =   Channel.fromPath(params.ref)
ref_geno_gen_ch   =   Channel.fromPath(params.ref)
ref_vcf_ch        =   Channel.fromPath(params.ref)
// load insertion-genotype submodules into dedicated channels
insgen_prep_ch    =   Channel.fromPath( './bin/insertion-genotype/' )
insgen_gen_ch     =   Channel.fromPath( './bin/insertion-genotype/' )
// put maxreads in its channel
insgen_maxr       =   Channel.value(params.maxr)

// ----------------------------------------
// STEP 1
// EXTRACT LOCI LIST AND INFO FROM MELT VCF
// ----------------------------------------

process parse_input {

  publishDir "${params.outdir}/", mode: 'copy', glob: 'input_loci_correspondance'

	input:
	file inputfile from in_ch // takes the file from the path in the channel
  file RM_track from RMtrack_in // takes the TE type  

  output:
  file "infile" into TypeDEL_in // will output in new channel TypeDEL_in
  file "infile" into rescue_in // copy for process 3 (TSD) rescue (those who are not processed by step 3)
  file "input_loci_correspondance" into cor_ch
  file "input_loci_correspondance" into rescue_cor

  script:
  """
  parse_input.sh $inputfile $RM_track > infile
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
	sed -E 's/chr//g' $RM_track > RM_track.alt
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
  //file "infile" from rescue_in
  //file "input_loci_correspondance" from rescue_cor

  output:
  file "output_TSD_Intervals.out" into TSD // TSD channel to host the output file

  script:
  """
  03_DelP_findTSD_forRMTEcordinates_v3.4.pl -t file.correspondingRepeatMaskerTEs.txt -p output_TSD_Intervals.out -g $ref
  """
  }

// -------------------------------------
// STEP 4
// CREATE INPUTS FOR insertion-genotype
// -------------------------------------

process createAlleles {

  publishDir "${params.outdir}/", mode: 'copy', glob: 'TypeREF.allele'

  input:
  file "output_TSD_Intervals.out" from TSD
  file "file.correspondingRepeatMaskerTEs.txt" from RM_inGeno
  file ref from ref_genoinput
  file "infile" from rescue_in
  file "input_loci_correspondance" from rescue_cor

  output:
  file "RM_insertions_TSD_strands" into interm_ch
  file "RM_insertions_TSD_strands" into RM_ins_vcf_channel
  file "TypeREF.allele" into input_Geno_ch_1
  file "TypeREF.allele" into input_Geno_ch_2
  file "*.fai" into index_ch
  file "exclusion.bed" into exclusion_ch

  shell:
  """
  join -11 -21 <(sort -k1,1 output_TSD_Intervals.out/TEcordinates_with_bothtsd_cordinates.v.3.4.txt) <(sort -k1,1 file.correspondingRepeatMaskerTEs.txt) | sed 's/ /\t/g' | awk '{print \$1"\t"\$2"\t"\$3"\t"\$4"\t"\$10"\t"\$8}' > RM_insertions_TSD_strands
  grep -wf <(grep -vwf <(cut -f 1 RM_insertions_TSD_strands) infile | cut -f 1) <(awk '{print \$7"_"\$8"\t"\$0}' input_loci_correspondance) | awk '{print \$1"\t"\$8":"\$9"-"\$10"\t"\$8":"\$9"-"\$10"\tnoTSDs\t"\$13"\t"\$11}' >> RM_insertions_TSD_strands
  samtools faidx $ref
  deletion_create_input.sh RM_insertions_TSD_strands $ref > TypeREF.allele
  awk '{print \$1}' TypeREF.allele | sed 's/:/\t/g;s/-/\t/g' | awk '{print \$1":"\$2"-"\$3"_genome\t500\t"500+(\$3-\$2)}' > exclusion.bed
  """
  
  }

// --------------------------------------
// STEP 5 - (sub: INSERTION-GENOTYPE 1/2)
// CREATE alleles and index with bwa
// --------------------------------------
process insgen_indexAlleles {

  input:
  file "TypeREF.allele" from input_Geno_ch_1.splitText( by: 8 )
 
  output:
  file "genotyping" into allelebase_ch

  script:
  """
  mkdir genotyping
  python2.7 $workflow.projectDir/bin/insertion-genotype/create-alternative-alleles.py --allelefile TypeREF.allele --allelebase genotyping --bwa bwa
  """
  
  }

//----------------------------------
// STEP 6 
// Gather loci in a genotype folder
//----------------------------------

process insgen_gatherloc {

  input:
  file "genotyping" from allelebase_ch.collect()
 
  output:
  // file "genotyping/samples/${sampleId}/*.vcf.gz" into indexed_vcfs
  file "allelebase" into gathered_loc

  script:
  // check if we have multiple genotyping folder by searching for "genotyping1" -- otherwise folder is called "genotyping"
  // if multiple genotyping folders, make a new "genotyping" folder and copy the content of the different folders into it
  """
  mkdir -p allelebase
  if [[ -d ./genotyping1 ]]; then
    cp -r ./genotyping[0-9]*/* ./allelebase/
    else
    cp -r ./genotyping/* ./allelebase/
  fi
  """
  }

//--------------------------------------
// STEP 7 - (sub: INSERTION-GENOTYPE 2/2)
// GENOTYPE!!!!!!!
//--------------------------------------

process insgen_genotype {

  input:
  set sampleId, file(fileId) from alignSamples_ch
  file "TypeREF.allele" from input_Geno_ch_2.toList()
  file "allelebase" from gathered_loc.toList()
  file "alignments" from alignPath_ch.toList()
  file "ref" from ref_geno_gen_ch.toList()
  file "*.fai" from index_ch.toList()
  file "exclusion.bed" from exclusion_ch.toList()
  //val maxr from insgen_maxr.toList()

  output:
  // file "genotyping/samples/${sampleId}/*.vcf.gz" into indexed_vcfs
  file "*.vcf.gz*" into indexed_vcfs
  file "allelebase" into export_ch

  script:
  """
  python2.7 $workflow.projectDir/bin/insertion-genotype/process-sample.py --allelefile TypeREF.allele --allelebase allelebase --samplename ${sampleId} --bwa bwa --bam alignments/${fileId} --reference ref --excludefile exclusion.bed --maxreads ${params.maxr}
  bgzip -c allelebase/samples/${sampleId}/${sampleId}.vcf > ${sampleId}.vcf.gz
  tabix -p vcf ${sampleId}.vcf.gz
  """
  }

process exportBams {
    publishDir "." ,mode: 'copy' , pattern: "*.tar.gz"

    input:
    set sampleId from alignSamples_ch2
    file "allelebase" from export_ch.toList()
    // create a channel to duplicate sampleID from alignSamples_ch
    // create a channel to export the allelebase folder to a new channel + use .toList() to have it for each individual 

    output:
    file "*.bams.tar.gz" into TR_bams_ch

    when:
    params.exportBams // add params.exportBams on top

    """
    tar -czhvf ${sampleId}.bams.tar.gz allelebase/samples/${sampleID}/mapping
    """
}

//--------------------------------------
// STEP 8
// Merge vcfs
//--------------------------------------

process mergeVcfs {

  publishDir "${params.outdir}/", mode: 'copy'

  input:
  file vcfFile from indexed_vcfs.collect()
  file ref from ref_vcf_ch
  file "RM_insertions_TSD_strands" from RM_ins_vcf_channel
   
  output:
  file "TypeREF.merged.genotypes.vcf" into typeref_outputs
  file "TypeREF.final.genotypes.vcf" into typeref_outputs_2

  script:
  """
  vcf-merge *.vcf.gz > TypeREF.merged.genotypes.vcf
  makevcf.sh $ref ${params.version} > TypeREF.final.genotypes.vcf
  """
  }

