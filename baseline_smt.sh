#!/bin/bash 
#echo " ‐‐‐‐‐‐‐‐‐‐ cleaning (and lowercase the english only)‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐"; 
../moses/scripts/release/scripts‐20090111‐1339/training/clean‐corpus‐n.perl train hi en train.clean 1 50; 
 
#echo " ‐‐‐‐‐‐‐‐‐‐ Building language model  ‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐"; 
mkdir lm; 
../srilm/bin/i686‐m64/ngram‐count ‐order 3 ‐interpolate ‐kndiscount ‐text train.surface.hi ‐lm 
lm/surf.lm; 
 
#echo " ‐‐‐‐‐‐‐‐‐‐ Training model ‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐"; 
../moses/scripts/release/scripts‐20090111‐1339/training/train‐factored‐phrase‐model.perl ‐‐scripts‐
root‐dir ../moses/scripts/release/scripts‐20090111‐1339 ‐‐root‐dir . ‐‐corpus train.clean ‐‐e hi ‐‐f en ‐‐lm 
0:3:/home/hansraj/ddp_exp/surfaceLR/lm/surf.lm:0 ‐reordering distance,msd‐bidirectional‐fe; 
 
#echo " ‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐ Tuning ‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐" 
mkdir tuning 
cp tun.en tuning/input 
cp tun.hi tuning/reference 
/home/hansraj/ddp_exp/moses/scripts/release/scripts‐20090111‐1339/training/mert‐moses.pl tuning/input tuning/reference /home/hansraj/ddp_exp/moses/moses‐cmd/src/moses 
/home/hansraj/ddp_exp/surfaceLR/model/moses.ini ‐‐working‐dir 
/home/hansraj/ddp_exp/surfaceLR/tuning ‐‐rootdir 
/home/hansraj/ddp_exp/moses/scripts/release/scripts‐20090111‐1339 
 
#echo " ‐‐‐‐‐‐‐‐‐‐ Generating output ‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐"; 
mkdir evaluation; 
../moses/moses‐cmd/src/moses ‐config tuning/moses.ini ‐input‐file test.en >evaluation/test.output; 
 
echo " ‐‐‐‐‐‐‐‐‐‐ Adding tags ‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐"; 
awk ‐f addtag_tst.awk evaluation/test.output >out; 
awk ‐f addtag_ref.awk test.hi >ref; 
awk ‐f addtag_src.awk test.en >src; 
 
echo " ‐‐‐‐‐‐‐‐‐‐ Bleu Score Calculations ‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐"; 
../moses/scripts/mteval‐v11b.pl ‐r ref ‐t out ‐s src –c 