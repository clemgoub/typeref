#! /bin/bash
# usage deletion_create_input.sh RM_insertions_TSD_strands ref_genome.fa

# change delimiter (IFS) to new line.
IFS_BAK=$IFS
IFS=$'\n'

insertions=$(cat $1)
for locus in $insertions
do

loc=$(echo "$locus" | awk '{print $1}')
left=$(echo "$locus" | awk '{print $2}')
right=$(echo "$locus" | awk '{print $3}')
TSD=$(echo "$locus" | awk '{print $4}')
strand=$(echo "$locus" | awk '{print $5}')

# echo "$locus"
# echo "$loc" 
# echo "$left" 
# echo "$right" 
# echo "$TSD" 

if [[ $TSD == "noTSDs" ]]
	
	then # VAL

	left_TE_del=$(sed 's/:/\t/g;s/-/\t/g' <(echo "$left") | awk '{print $1,($2-500),($2-1)}')
	right_TE_del=$(sed 's/:/\t/g;s/-/\t/g' <(echo "$right") | awk '{print $1,$3,($3+500)}')
	TE_loc=$(sed 's/:/\t/g;s/-/\t/g' <(echo "$left") | awk '{print $1,($2-500),($3+500)}') # the left and right TSD coordinates in case of "noTSDs" are actually the start and stop of the TE of the input file

	 #echo "$left_TE_del"
	 #echo "$right_TE_del"
	 #echo "$TE_loc"

	# extract the sequence of them | change the refgenome path by a user input
	leftsq=$(bedtools getfasta -fi $2 -bed <(echo "$left_TE_del" | sed 's/ /\t/g'))
	rightsq=$(bedtools getfasta -fi $2 -bed <(echo "$right_TE_del" | sed 's/ /\t/g'))
	# make the no TE sequence (new ref)
	noTE=$(paste -d "," <(echo "$leftsq" | awk 'getline seq {print seq}') <(echo "$rightsq" | awk 'getline seq {print seq}') | sed $'s/,//g')
	# make the TE sequence (alt)
	TE=$(bedtools getfasta -fi $2 -bed <(echo "$TE_loc" | sed 's/ /\t/g') | awk 'getline seq {print seq}')

	# generate the table
	paste <(echo "$left-$right" | sed 's/-/\t/g' | awk '{print $1"-"$4}') <(echo "$left" | sed 's/:/\t/g;s/-/\t/g' | awk '{print $1"\t"$2}') <(echo ".") <(echo "$left" | sed 's/:/\t/g;s/-/\t/g' | awk '{print ($2-500)}') <(echo "$right" | sed 's/:/\t/g;s/-/\t/g' | awk '{print ($3+500)}') <(echo "$TE") <(echo "$noTE") 

elif [[ $TSD == *.* ]] # if TSDs have mismatches, will keep the 5' one for the non TE

	then

	left_TE_del=$(sed 's/:/\t/g;s/-/\t/g' <(echo "$left") | awk '{print $1,($2-500),($2-1)}')
	right_TE_del=$(sed 's/:/\t/g;s/-/\t/g' <(echo "$right") | awk '{print $1,$3,($3+500)}')
	TE_loc=$(paste -d ","  <(sed 's/:/\t/g;s/-/\t/g' <(echo "$left") | awk '{print $1,($2-500)}') <(sed 's/:/\t/g;s/-/\t/g' <(echo "$right") | awk '{print ($3+500)}') | sed $'s/,/\t/g')

	 #echo "TWO TSD !!!!!!!!!!"
	 #cho "$left_TE_del"
	 #echo "$right_TE_del"
	 #echo "$TE_loc"

	# extract the sequence of them
	leftsq=$(bedtools getfasta -fi $2 -bed <(echo "$left_TE_del" | sed 's/ /\t/g'))
	rightsq=$(bedtools getfasta -fi $2 -bed <(echo "$right_TE_del" | sed 's/ /\t/g'))
	leftTSD=$(echo "$TSD" | sed 's/\./\t/g' | awk '{print $1}')
	rightTSD=$(echo "$TSD" | sed 's/\./\t/g' | awk '{print $2}')

	# make the no TE sequence (new ref)
	if [[ $strand == "+" ]] # keep left if + ; keep right if -
		
		then # keep left TSD
		
		noTE=$(paste -d "," <(echo "$leftsq" | awk 'getline seq {print seq}') <(echo "$leftTSD") <(echo "$rightsq" | awk 'getline seq {print seq}') | sed $'s/,//g')

		else # keep right TSD

		noTE=$(paste -d "," <(echo "$leftsq" | awk 'getline seq {print seq}') <(echo "$rightTSD") <(echo "$rightsq" | awk 'getline seq {print seq}') | sed $'s/,//g')
	

	fi

	# make the TE sequence (alt)
	TE=$(bedtools getfasta -fi $2 -bed <(echo "$TE_loc" | sed 's/ /\t/g') | awk 'getline seq {print seq}')
	# generate the table
	paste <(echo "$left-$right" | sed 's/-/\t/g' | awk '{print $1"-"$4}') <(echo "$left" | sed 's/:/\t/g;s/-/\t/g' | awk '{print $1"\t"$2}') <(echo ".") <(echo "$left" | sed 's/:/\t/g;s/-/\t/g' | awk '{print ($2-500)}') <(echo "$right" | sed 's/:/\t/g;s/-/\t/g' | awk '{print ($3+500)}') <(echo "$TE") <(echo "$noTE") 


else 

	left_TE_del=$(sed 's/:/\t/g;s/-/\t/g' <(echo "$left") | awk '{print $1,($2-500),($2-1)}')
    right_TE_del=$(sed 's/:/\t/g;s/-/\t/g' <(echo "$right") | awk '{print $1,$3,($3+500)}')
    TE_loc=$(paste -d ","  <(sed 's/:/\t/g;s/-/\t/g' <(echo "$left") | awk '{print $1,($2-500)}') <(sed 's/:/\t/g;s/-/\t/g' <(echo "$right") | awk '{print ($3+500)}') | sed $'s/,/\t/g')
	
	 #echo "$left_TE_del"
	 #echo "$right_TE_del"
     #echo "$TE_loc"

	# extract the sequence of them | change the refgenome path by a user input
	leftsq=$(bedtools getfasta -fi $2 -bed <(echo "$left_TE_del" | sed 's/ /\t/g'))
	rightsq=$(bedtools getfasta -fi $2 -bed <(echo "$right_TE_del" | sed 's/ /\t/g'))
	noTE=$(paste -d "," <(echo "$leftsq" | awk 'getline seq {print seq}') <(echo "$TSD") <(echo "$rightsq" | awk 'getline seq {print seq}') | sed $'s/,//g')
	TE=$(bedtools getfasta -fi $2 -bed <(echo "$TE_loc" | sed 's/ /\t/g') | awk 'getline seq {print seq}')
	
	#echo "$leftsq"
	#echo "$rightsq"
	#echo "$TE"
    #echo "$noTE"

	# generate the table
	paste <(echo "$left-$right" | sed 's/-/\t/g' | awk '{print $1"-"$4}') <(echo "$left" | sed 's/:/\t/g;s/-/\t/g' | awk '{print $1"\t"$2}') <(echo ".") <(echo "$left" | sed 's/:/\t/g;s/-/\t/g' | awk '{print ($2-500)}') <(echo "$right" | sed 's/:/\t/g;s/-/\t/g' | awk '{print ($3+500)}') <(echo "$TE") <(echo "$noTE")


fi


done

# return delimiter to previous value
IFS=$IFSq_BAK
IFS_BAK=
