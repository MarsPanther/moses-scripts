#!/bin/sh

LANG1="en"
LANG2="am"
START_DIR="$HOME/Desktop/data"
EXP_DIR="Factored-Trigram-$LANG2-$LANG1"

mkdir $HOME/$EXP_DIR
mkdir $HOME/$EXP_DIR/corpus
mkdir $HOME/$EXP_DIR/working
mkdir $HOME/$EXP_DIR/lm
mkdir $HOME/$EXP_DIR/pre_process

SRC="$START_DIR/$LANG1"_"$LANG2/"
SELECTOR_SCRIPS="$START_DIR/scripts/selector_test_tune.py"
COMBINE_FILES="$START_DIR/scripts/combine.py"
MOSSES_TOKEN="$HOME/mosesdecoder/scripts/tokenizer/tokenizer.perl"
MOSSES_TRUE_CASE_MOD="$HOME/mosesdecoder/scripts/recaser/train-truecaser.perl"
MOSSES_TRUE_CASE_BULD="$HOME/mosesdecoder/scripts/recaser/truecase.perl"
MOSSES_CLEAN="$HOME/mosesdecoder/scripts/training/clean-corpus-n.perl"
MOSSES_TRN="$HOME/mosesdecoder/scripts/training/train-model.perl"
MOSSES_MERT="$HOME/mosesdecoder/scripts/training/mert-moses.pl"
CORPUS="$HOME/$EXP_DIR/corpus"
PreProcess="$HOME/$EXP_DIR/pre_process"
SPACE_NORM="$START_DIR/scripts/amh_space_normalizor.py"
CHAR_NORM="$START_DIR/scripts/amh_char_normalizor_v2.py"
AMH_TAGGER="$START_DIR/scripts/amharic_tagger_with_model.py"
ENG_TAGGER="$START_DIR/scripts/english_tagger_with_model.py"
EXTRACT_TAGS="$START_DIR/scripts/extract_tag.py"
LM="$HOME/$EXP_DIR/lm"
WORKING="$HOME/$EXP_DIR/working"


cp "$SRC$LANG1.txt"  "$PreProcess/"
cp "$SRC$LANG2.txt"  "$PreProcess/"

cd $PreProcess
python3  "$SELECTOR_SCRIPS" $LANG1 $LANG2

# # English tokenization and truecasing
"$MOSSES_TOKEN"  -l en < "$PreProcess/train.$LANG1" > "$PreProcess/train.$LANG1.tok.$LANG1"
"$MOSSES_TRUE_CASE_MOD"  --model "$PreProcess/truecase-model.$LANG1" --corpus "$PreProcess/train.$LANG1.tok.$LANG1"
"$MOSSES_TRUE_CASE_BULD"  --model "$PreProcess/truecase-model.$LANG1" < "$PreProcess/train.$LANG1.tok.$LANG1" > "$PreProcess/train.true.$LANG1"


"$MOSSES_TOKEN" -l en < "$PreProcess/tune.$LANG1" > "$PreProcess/tune.$LANG1.tok.$LANG1"
"$MOSSES_TRUE_CASE_MOD"  --model "$PreProcess/truecase-model2.$LANG1" --corpus "$PreProcess/tune.$LANG1.tok.$LANG1"
"$MOSSES_TRUE_CASE_BULD"  --model "$PreProcess/truecase-model2.$LANG1" < "$PreProcess/tune.$LANG1.tok.$LANG1" > "$PreProcess/tune.true.$LANG1"


"$MOSSES_TOKEN" -l en < "$PreProcess/test.$LANG1" > "$PreProcess/test.$LANG1.tok.$LANG1"
"$MOSSES_TRUE_CASE_MOD"  --model "$PreProcess/truecase-model3.$LANG1" --corpus "$PreProcess/test.$LANG1.tok.$LANG1"
"$MOSSES_TRUE_CASE_BULD"  --model "$PreProcess/truecase-model3.$LANG1" < "$PreProcess/test.$LANG1.tok.$LANG1" > "$PreProcess/test.true.$LANG1"

#Return to 
# # Amharic tokenization and character normalaization
cd "$START_DIR/scripts/"

python2 "$SPACE_NORM" "$PreProcess/train."$LANG2
python2 "$SPACE_NORM" "$PreProcess/tune."$LANG2
python2 "$SPACE_NORM" "$PreProcess/test."$LANG2

python2 "$CHAR_NORM" "$PreProcess/train."$LANG2
python2 "$CHAR_NORM" "$PreProcess/tune."$LANG2
python2 "$CHAR_NORM" "$PreProcess/test."$LANG2

mv "$PreProcess/train.$LANG2" "$PreProcess/train.true."$LANG2 
mv "$PreProcess/tune.$LANG2" "$PreProcess/tune.true."$LANG2 
mv "$PreProcess/test.$LANG2" "$PreProcess/test.true."$LANG2


"$MOSSES_CLEAN" "$PreProcess/train.true" $LANG2 $LANG1 "$PreProcess/train.clean" 1 80

cp "$PreProcess/train.clean."$LANG1 "$PreProcess/train.clean."$LANG2 "$CORPUS"
cp "$PreProcess/tune.true."$LANG1 "$PreProcess/tune.true."$LANG2 "$CORPUS"
cp "$PreProcess/test.true."$LANG1 "$PreProcess/test.true."$LANG2 "$CORPUS"

# # # #Tagging with best model yet

cd $CORPUS
python3 "$ENG_TAGGER" "$CORPUS/train.clean.$LANG1"
python3 "$ENG_TAGGER" "$CORPUS/tune.true.$LANG1"
python3 "$AMH_TAGGER" "$CORPUS/train.clean.$LANG2"
python3 "$AMH_TAGGER" "$CORPUS/tune.true.$LANG2"


# # # # language model creation
cd $LM
python3 "$COMBINE_FILES" "$PreProcess/train.true."$LANG1  "$PreProcess/tune.true."$LANG1 "$LM/combined_lm.$LANG1"
python3 "$COMBINE_FILES" "$PreProcess/train.true."$LANG2  "$PreProcess/tune.true."$LANG2 "$LM/combined_lm.$LANG2"

python3 "$COMBINE_FILES" "$CORPUS/train.clean_tagged."$LANG1  "$CORPUS/tune.true_tagged."$LANG1 "$LM/combined_tagged_lm.$LANG1"
python3 "$COMBINE_FILES" "$CORPUS/train.clean_tagged."$LANG2  "$CORPUS/tune.true_tagged."$LANG2 "$LM/combined_tagged_lm.$LANG2"

python3 "$EXTRACT_TAGS" "$LM/combined_tagged_lm.$LANG1"
python3 "$EXTRACT_TAGS" "$LM/combined_tagged_lm.$LANG2"


python3 "$COMBINE_FILES" "combined_tagged_lm_tag_sets.$LANG1"  "combined_tagged_lm_tag_sets.$LANG1" "combined_tagged_lm_tag_sets_double.$LANG1"
python3 "$COMBINE_FILES" "combined_tagged_lm_tag_sets.$LANG2"  "combined_tagged_lm_tag_sets.$LANG2" "combined_tagged_lm_tag_sets_double.$LANG2"

# lang model
$HOME/mosesdecoder/bin/lmplz -o 3 --interpolate_unigrams 0 --discount_fallback <"$LM/combined_lm.$LANG1" >"$LM/surface.arpa.$LANG1"
$HOME/mosesdecoder/bin/lmplz -o 3 --interpolate_unigrams 0 --discount_fallback <"$LM/combined_lm.$LANG2" >"$LM/surface.arpa.$LANG2"
$HOME/mosesdecoder/bin/lmplz -o 3 --interpolate_unigrams 0 --discount_fallback <"$LM/combined_tagged_lm_tag_sets_double.$LANG1" >"$LM/pos.arpa.$LANG1"
$HOME/mosesdecoder/bin/lmplz -o 3 --interpolate_unigrams 0 --discount_fallback <"$LM/combined_tagged_lm_tag_sets_double.$LANG2" >"$LM/pos.arpa.$LANG2"

# # # ####Binarize LM-------------------------------------------------------------------------------------

"$HOME/mosesdecoder/bin/build_binary" "$LM/surface.arpa.$LANG1" "$LM/surface.blm.$LANG1"
"$HOME/mosesdecoder/bin/build_binary" "$LM/surface.arpa.$LANG2" "$LM/surface.blm.$LANG2"
"$HOME/mosesdecoder/bin/build_binary" "$LM/pos.arpa.$LANG1" "$LM/pos.blm.$LANG1"
"$HOME/mosesdecoder/bin/build_binary" "$LM/pos.arpa.$LANG1" "$LM/pos.blm.$LANG2"

# ##Translation Model-------------------------------------------------------------------------

cd $WORKING

"$MOSSES_TRN" -cores 4 \
-root-dir "$WORKING/train/model" \
-corpus "$CORPUS/train.clean_tagged" \
-f "$LANG2" -e "$LANG1" \
-lm 0:4:"$LM/surface.blm."$LANG1 \
-lm 2:4:"$LM/pos.blm."$LANG1 \
-translation-factors 0-0,2 \
-external-bin-dir "$HOME/mosesdecoder/tools"


cd $WORKING

"$MOSSES_MERT" "$CORPUS/tune.true.$LANG2" "$CORPUS/tune.true.$LANG1" \
    "$HOME/mosesdecoder/bin/moses" \
    "$WORKING/train/model/model/moses.ini" \
    -mertdir "$HOME/mosesdecoder/bin/" \
    -rootdir "$HOME/mosesdecoder/scripts" \
    -decoder-flags '-threads 4'

####Binaries-------------------------------------------------------------------------------



cd $WORKING

rm -rf "$WORKING/train/model/model/moses.ini"
cp "$WORKING/mert-work/moses.ini" "$WORKING/train/model/model"

"$HOME/mosesdecoder/bin/processPhraseTableMin" \
-in "$WORKING/train/model/model/phrase-table.0-0,2.gz" \
-nscores 4 \
-out "$WORKING/train/model/model/phrase-table.0-0,2.minphr"


sed -i -e "s/PhraseDictionaryMemory/PhraseDictionaryCompact/g" "$WORKING/train/model/model/moses.ini"
sed -i  -e "s#path=$WORKING/train/model/model/phrase-table.0-0,2.gz#path=$WORKING/train/model/model/phrase-table.0-0,2.minphr#g" "$WORKING/train/model/model/moses.ini"



# # # # ###bleu----------------------------------------------------------------------------------------------------------
cd $WORKING
"$HOME/mosesdecoder/bin/moses" -f "$WORKING/train/model/model/moses.ini" < "$CORPUS/test.true."$LANG2 > "$CORPUS/test.translated."$LANG1

# # # # # ##run blue script------------------------------------------------------------------------------------------------
"$HOME/mosesdecoder/scripts/generic/multi-bleu.perl" -lc "$CORPUS/test.true."$LANG1 < "$CORPUS/test.translated."$LANG1 > "$HOME/$EXP_DIR/blue_$LANG2_$LANG1.txt"

continue to bidirectional
echo "writting BLUE for EXP-$LANG2-$LANG1 Done!! "
echo "================================================================================"
echo "Starting EXP-$LANG1-$LANG2"
cd "$START_DIR/scripts/"

bash bi_factored_exp.sh

echo "writting BLUE for EXP-$LANG1-$LANG2 Done!! "
echo "Success !!! Two Experiment done"