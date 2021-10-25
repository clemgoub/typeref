#! /bin/bash

# make the input table for reference insertion from a .bed file or a MELT .vcf/.vcf.gz
#
# USAGE: ./parse_input.sh <$1 = coordinates.bed/.vcf/.gzvcf> <$2 = TE_track>


if [[ $1 == *.bed ]]
then
	if grep -q "chr" $1
		then
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4"\t"$5"\t"$6}' $1 | sort -k1,1 -k2,2n) -b <(sort -k1,1 -k2,2n $2) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 2- > input_loci_correspondance
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4"\t"$5"\t"$6}' $1 | sort -k1,1 -k2,2n) -b <(sort -k1,1 -k2,2n $2) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 8- | sort | uniq | awk '!/^#/ {print $1"_"$2"\t"$1"\t"$2"\t"$4}'
		else
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4"\t"$5"\t"$6}' $1 | sort -k1,1 -k2,2n) -b <(sed -E 's/chr//g' $2) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 2- > input_loci_correspondance
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4"\t"$5"\t"$6}' $1 | sort -k1,1 -k2,2n) -b <(sed -E 's/chr//g' $2) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 8- | sort | uniq | awk '!/^#/ {print $1"_"$2"\t"$1"\t"$2"\t"$4}'
	fi
else
	testfile=$(file $1 | awk '{print $2}')
	if [[ $testfile == "gzip" ]]
	then

	headline=$(zcat $1 | grep -n "#CHROM" | cut -d : -f 1)
	MEINFO=$(zcat $1 | awk -v varline="$headline" -F $'\t' 'NR > varline {print $1,$2,$8}' | head -n 1 | sed 's/;/\t/g' |  awk '{for (i=1; i<=NF; ++i) { if ($i ~ "SVTYPE") printf i } } ')
	END=$(zcat $1 | awk -v varline="$headline" -F $'\t' 'NR > varline {print $1,$2,$8}' | head -n 1 | sed 's/;/\t/g' |  awk '{for (i=1; i<=NF; ++i) { if ($i ~ "END") printf i } } ')
	BED=$(zcat $1 | awk -v varline="$headline" -F $'\t' 'NR > varline {print $1,$2,$8}' | sed 's/;/\t/g' | awk -v end="$END" -v meifo="$MEINFO" '{print $1,$2,$end,$meifo}' | sed 's/,/\t/g;s/END=//g;s/SVTYPE=//g' |  awk '{print $1"\t"$2"\t"$3"\t"$4}' | sort -k1,1 -k2,2n -k3,3n)
		if grep -q "chr" $1
		then
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4}' <(echo "$BED") | sort -k1,1 -k2,2n) -b <(sort -k1,1 -k2,2n $2) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 2- > input_loci_correspondance
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4}' <(echo "$BED") | sort -k1,1 -k2,2n) -b <(sort -k1,1 -k2,2n $2) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 6- | sort | uniq | awk '!/^#/ {print $1"_"$2"\t"$1"\t"$2"\t"$4}'
		else
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4}' <(echo "$BED") | sort -k1,1 -k2,2n) -b <(sed -E 's/chr//g' $2) | sort -k1,1 -k2,2n) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 2- > input_loci_correspondance
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4}' <(echo "$BED") | sort -k1,1 -k2,2n) -b <(sed -E 's/chr//g' $2) | sort -k1,1 -k2,2n) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 6- | sort | uniq | awk '!/^#/ {print $1"_"$2"\t"$1"\t"$2"\t"$4}'
		fi

	else

	headline=$(cat $1 | grep -n "#CHROM" | cut -d : -f 1)
	MEINFO=$(cat $1 | awk -v varline="$headline" -F $'\t' 'NR > varline {print $1,$2,$8}' | head -n 1 | sed 's/;/\t/g' |  awk '{for (i=1; i<=NF; ++i) { if ($i ~ "SVTYPE") printf i } } ')
	END=$(cat $1 | awk -v varline="$headline" -F $'\t' 'NR > varline {print $1,$2,$8}' | head -n 1 | sed 's/;/\t/g' |  awk '{for (i=1; i<=NF; ++i) { if ($i ~ "END") printf i } } ')
	BED=$(cat $1 | awk -v varline="$headline" -F $'\t' 'NR > varline {print $1,$2,$8}' | sed 's/;/\t/g' | awk -v end="$END" -v meifo="$MEINFO" '{print $1,$2,$end,$meifo}' | sed 's/,/\t/g;s/END=//g;s/SVTYPE=//g' |  awk '{print $1"\t"$2"\t"$3"\t"$4}' | sort -k1,1 -k2,2n -k3,3n)
		if grep -q "chr" $1
		then
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4}' <(echo "$BED") | sort -k1,1 -k2,2n) -b <(sort -k1,1 -k2,2n $2) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 2- > input_loci_correspondance
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4}' <(echo "$BED") | sort -k1,1 -k2,2n) -b <(sort -k1,1 -k2,2n $2) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 6- | sort | uniq | awk '!/^#/ {print $1"_"$2"\t"$1"\t"$2"\t"$4}'
		else
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4}' <(echo "$BED") | sort -k1,1 -k2,2n) -b <(sed -E 's/chr//g' $2) | sort -k1,1 -k2,2n) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 2- > input_loci_correspondance
		bedtools intersect -wao -a <(awk '{print $1"\t"($2-50)"\t"($3+50)"\t"$4}' <(echo "$BED") | sort -k1,1 -k2,2n) -b <(sed -E 's/chr//g' $2) | sort -k1,1 -k2,2n) | awk '{print $1":"$2"-"$3"\t"$0}' | sort -k1,1 -k13,13nr | sort -u -k1,1 | cut -f 6- | sort | uniq | awk '!/^#/ {print $1"_"$2"\t"$1"\t"$2"\t"$4}'
		fi
	fi
fi