
#! /bin/bash
# usage: ./makevcf.sh <ref_genome>
# so far produces a 4 column table with:
# c1 = locus name format chr_position (should match between RM_ and vcf c1_c2)
# c2 = chr
# c3 = adjusted position (according to orientation, keep the left or right TSD [match allele file])
# c4 = INFO field to appen to the vcf

# create a pre-vcf file, 1 line per locus, with all infos
#paste <(paste <(sed 's/:/\t/g;s/-/\t/g' RM_insertions_TSD_strands | cut -f 1-7) <(cut -f 4- RM_insertions_TSD_strands) | awk '{if ($8 == "noTSDs") {print $1"\t"$2"\t"$3"\tEND="$4";TSD="$8";"$9";SVTYPE="$10} else if ($9 == "+"){print $1"\t"$2"\t"$4"\tEND="$7";TSD="$8";"$9";SVTYPE="$10} else {print $1"\t"$2"\t"$3"\tEND="$6";TSD="$8";-;SVTYPE="$10}}' | sort -k1,1) <(grep -v '#' TypeREF.merged.genotypes.vcf | awk '{print $1"_"$2"\t"$0}' | sort -k1,1) > vcf.info
paste <(paste <(sed 's/:/\t/g;s/-/\t/g' RM_insertions_TSD_strands | cut -f 1-7) <(cut -f 4- RM_insertions_TSD_strands) | awk '{if ($8 == "noTSDs") {print $1"\t"$2"\t"$3"\tEND="$4";TSD="$8";MEINFO="$10","$3","$4","$9} else if ($9 == "+"){print $1"\t"$2"\t"$4"\tEND="$7";TSD="$8";MEINFO="$10","$4","$7","$9} else {print $1"\t"$2"\t"$3"\tEND="$6";TSD="$8";SVTYPE="$10","$3","$6",-"}}' | sort -k1,1) <(grep -v '#' TypeREF.merged.genotypes.vcf | awk '{print $1"_"$2"\t"$0}' | sort -k1,1) > vcf.info
# get reference sequences coordinates and extract to add to vcf | -1 to left coordinate is to inclue this base in the vcf
paste <(paste <(sed 's/:/\t/g;s/-/\t/g' RM_insertions_TSD_strands | cut -f 1-7) <(cut -f 4- RM_insertions_TSD_strands) | awk '{if ($8 == "noTSDs") {print $2"\t"($3-1)"\t"$4"\t"$1} else if ($9 == "+"){print $2"\t"($4-1)"\t"$7"\t"$1} else {print $2"\t"($3-1)"\t"$6"\t"$1}}') | sort -k4,4 > ref.bed
# rearange the columns to become a real vcf body
paste <(cut -f 2,3,8 vcf.info) <(bedtools getfasta -fi $1 -bed ref.bed | awk 'getline seq {print seq}') <(cut -f 10-12 vcf.info) <(awk '{print $13";"$4}' vcf.info) <(cut -f 14- vcf.info) > vcf.body
# ammend the header
grep '^##' TypeREF.merged.genotypes.vcf > pre.header
echo "##INFO=<ID=END,Number=1,Type=Integer,Description=\"End position of the variant described in this record\">" >> pre.header
echo "##INFO=<ID=TSD,Number=1,Type=String,Description=\"Target Site Duplication\">" >> pre.header
echo "##INFO=<ID=MEINFO,Number=4,Type=String,Description=\"Mobile element info of the form NAME,START,END,POLARITY\">" >> pre.header

# and merge everything
cat <(head -n 1 pre.header) <(echo "##fileDate="$(date "+%Y%m%d")) <(echo "##fileDate="$1) <(awk 'NR > 1' pre.header) <(grep -w '#CHROM' TypeREF.merged.genotypes.vcf) vcf.body

