#! /bin/bash
# usage: ./makevcf.sh <ref_genome> <TypeREF_version>
# so far produces a 4 column table with:
# c1 = locus name format chr_position (should match between RM_ and vcf c1_c2)
# c2 = chr
# c3 = adjusted position (according to orientation, keep the left or right TSD [match allele file])
# c4 = INFO field to appen to the vcf

# test if required files have the same length (nb. of loci). If yes proceed, otherwise return error
VCF=$(grep -vc '#' TypeREF.merged.genotypes.vcf)
RM=$(wc -l RM_insertions_TSD_strands | awk '{print $1}')

if [[ $VCF -eq $RM ]]
then
	# create a pre-vcf file, 1 line per locus, with all infos
	paste <(paste <(sed 's/:/\t/g;s/-/\t/g' RM_insertions_TSD_strands | cut -f 1-7) <(cut -f 4- RM_insertions_TSD_strands) | awk '{if ($8 == "noTSDs") {print $1"\t"$2"\t"$3"\tEND="$4";TSD="$8";MEINFO="$10","$3","$4","$9} else if ($9 == "+"){print $1"\t"$2"\t"$4"\tEND="$7";TSD="$8";MEINFO="$10","$4","$7","$9} else {print $1"\t"$2"\t"$3"\tEND="$6";TSD="$8";MEINFO="$10","$3","$6",-"}}' | sort -k1,1) <(grep -v '#' TypeREF.merged.genotypes.vcf | awk '{print $1"_"$2"\t"$0}' | sort -k1,1) > vcf.info
	# get reference sequences coordinates and extract to add to vcf | -1 to left coordinate is to inclue this base in the vcf
	paste <(paste <(sed 's/:/\t/g;s/-/\t/g' RM_insertions_TSD_strands | cut -f 1-7) <(cut -f 4- RM_insertions_TSD_strands) | awk '{if ($8 == "noTSDs") {print $2"\t"($3-1)"\t"$4"\t"$1} else if ($9 == "+"){print $2"\t"($4-1)"\t"$7"\t"$1} else {print $2"\t"($3-1)"\t"$6"\t"$1}}') | sort -k4,4 > ref.bed
	# rearange the columns to become a real vcf body
	paste <(cut -f 2,3,4 vcf.info | sed 's/MEINFO=/\t/g;s/,/\t/g' | awk '{print $1"\t"$2"\tTypeREF_"$4"_"$1":"$5"-"$6}') <(bedtools getfasta -fi $1 -bed ref.bed | awk 'getline seq {print seq}') <(cut -f 10-12 vcf.info) <(awk '{print $13";"$4}' vcf.info) <(cut -f 14- vcf.info) | sort -k1,1 -k2,2n > vcf.body
	# ammend the header
	grep '^##' TypeREF.merged.genotypes.vcf > pre.header
	echo "##INFO=<ID=END,Number=1,Type=Integer,Description=\"End position of the variant described in this record\">" >> pre.header
	echo "##INFO=<ID=TSD,Number=1,Type=String,Description=\"Target Site Duplication\">" >> pre.header
	echo "##INFO=<ID=MEINFO,Number=4,Type=String,Description=\"Mobile element info of the form NAME,START,END,POLARITY\">" >> pre.header

	# and merge everything
	cat <(head -n 1 pre.header) <(echo "##fileDate="$(date "+%Y%m%d")) <(echo "##reference="$1) <(echo "##source=TypeREF.v"$2) <(awk 'NR > 1' pre.header) <(grep -w '#CHROM' TypeREF.merged.genotypes.vcf) vcf.body
else
	# exit and display error message
	echo -e >&2 "RM_insertions_TSD_strands and VCF files have different length... Exiting before creating a messy VCF!\nSomething went wrong. Does your RepeatMasker track includes something else than Alu, LINE1 or SVA?"
	exit 1
fi