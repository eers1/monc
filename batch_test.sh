#!/bin/bash

run_type=$1
ppe_no=$2
name_of_run="$run_type$ppe_no"
echo $name_of_run
base_mcf='/work/n02/n02/eers/monc_cu_a/sct_ppe_base.mcf'
base_sb='/work/n02/n02/eers/monc_cu_a/asubmonc_ppe_base.sb'

# make directories
mkdir /work/n02/n02/eers/monc_cu_a/$name_of_run
mkdir /work/n02/n02/eers/monc_cu_a/$name_of_run/monc_stdout
mkdir /work/n02/n02/eers/monc_cu_a/$name_of_run/checkpoint_files
mkdir /work/n02/n02/eers/monc_cu_a/$name_of_run/diagnostic_files

# copy mcf and sb files and replace strings with run name
cp $base_mcf /work/n02/n02/eers/monc_cu_a/$name_of_run/sct_$name_of_run.mcf
cp $base_sb /work/n02/n02/eers/monc_cu_a/$name_of_run/asubmonc_$name_of_run.sb
sed -i "s/run_name/$name_of_run/g" /work/n02/n02/eers/monc_cu_a/$name_of_run/sct_$name_of_run.mcf
sed -i "s/run_name/$name_of_run/g" /work/n02/n02/eers/monc_cu_a/$name_of_run/asubmonc_$name_of_run.sb

csv_file='/work/n02/n02/eers/monc_cu_a/string_master_array.csv'

i="1"
while read -r line #-r size rand_heights heights_prof theta_prof q_fields_prof b_aut
do
    if (($i==$ppe_no))
    then
	rand_heights=$(echo "$line" | awk -F'|' '{printf "%s", $1}' ) #| tr -d '"')
	heights_prof=$(echo "$line" | awk -F'|' '{printf "%s", $2}' ) #| tr -d '"')
	theta_prof=$(echo "$line" | awk -F'|' '{printf "%s", $3}' ) #| tr -d '"')
	q_fields_prof=$(echo "$line" | awk -F'|' '{printf "%s", $4}' ) #| tr -d '"')
	b_aut=$(echo "$line" | awk -F'|' '{printf "%s", $5}' ) #| tr -d '"')
    fi
    i=$[$i+1]
done < $csv_file

echo "random_heights: $rand_heights"
echo "heights_profile: $heights_prof"
echo "theta_profile: $theta_prof"
echo "q_fields_profile: $q_fields_prof"
echo "b_aut: $b_aut"

sed -i "s@rand_heights@$rand_heights@g" /work/n02/n02/eers/monc_cu_a/$name_of_run/sct_$name_of_run.mcf
sed -i "s@heights_profile@$heights_prof@g" /work/n02/n02/eers/monc_cu_a/$name_of_run/sct_$name_of_run.mcf
sed -i "s@theta_profile@$theta_prof@g" /work/n02/n02/eers/monc_cu_a/$name_of_run/sct_$name_of_run.mcf
sed -i "s@q_fields_profiles@$q_fields_prof@g" /work/n02/n02/eers/monc_cu_a/$name_of_run/sct_$name_of_run.mcf
sed -i "s@b_parameter@$b_aut@g" /work/n02/n02/eers/monc_cu_a/$name_of_run/sct_$name_of_run.mcf

echo $name_of_run "random_heights: $rand_heights" "heights_profile: $heights_prof" "theta_profile: $theta_prof" "q_fields_profile: $q_fields_prof" "b_aut: $b_aut" > /work/n02/n02/eers/monc_cu_a/$name_of_run/prof.txt

sbatch $name_of_run/asubmonc_$name_of_run.sb
