#!/bin/bash
echo "22 17280006 17280336" | sed 's/ /\t/g' > file.bed

bedtools getfasta -fi $1 -bed file.bed