#!/bin/sh

LANG1="en"
LANG2="am"
START_DIR="$HOME/Desktop/data"
EXP_DIR="Factored-Trigram-$LANG1-$LANG2"

mkdir $HOME/$EXP_DIR
mkdir $HOME/$EXP_DIR/corpus
mkdir $HOME/$EXP_DIR/working
mkdir $HOME/$EXP_DIR/lm
mkdir $HOME/$EXP_DIR/pre_process

SRC="$START_DIR/tree_$LANG1"_"$LANG2/"
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

PREV_SRC="$HOME/Factored-Trigram-$LANG2-$LANG1"

cp -R "$PREV_SRC/corpus/." "$HOME/$EXP_DIR/corpus"
cp -R "$PREV_SRC/lm/." "$HOME/$EXP_DIR/lm"

rm -rf "$HOME/$EXP_DIR/blue_$LANG2_$LANG1.txt"

rm -rf "$HOME/$EXP_DIR/corpus/train.clean_tagged.0-0.$LANG1"
rm -rf "$HOME/$EXP_DIR/corpus/train.clean_tagged.0-0.$LANG2"
rm -rf "$HOME/$EXP_DIR/corpus/test.translated.$LANG1"





# ##Translation Model-------------------------------------------------------------------------

cd $WORKING

"$MOSSES_TRN" -cores 4 \
-root-dir "$WORKING/train/model" \
-corpus "$CORPUS/train.clean_tagged" \
-f "$LANG1" -e "$LANG2" \
-lm 0:3:"$LM/surface.blm."$LANG2 \
-lm 1:3:"$LM/pos.blm."$LANG2 \
-translation-factors 0-0,2 \
-external-bin-dir "$HOME/mosesdecoder/tools"


cd $WORKING

"$MOSSES_MERT" "$CORPUS/tune.true.$LANG1" "$CORPUS/tune.true.$LANG2" \
    "$HOME/mosesdecoder/bin/moses" \
    "$WORKING/train/model/model/moses.ini" \
    -mertdir "$HOME/mosesdecoder/bin/" \
    -rootdir "$HOME/mosesdecoder/scripts" \
    -decoder-flags '-threads 4'

# ####Binaries-------------------------------------------------------------------------------



cd $WORKING

rm -rf "$WORKING/train/model/model/moses.ini"
cp "$WORKING/mert-work/moses.ini" "$WORKING/train/model/model"

"$HOME/mosesdecoder/bin/processPhraseTableMin" \
-in "$WORKING/train/model/model/phrase-table.0-0,2.gz" \
-nscores 4 \
-out "$WORKING/train/model/model/phrase-table.0-0,2.minphr"


sed -i -e "s/PhraseDictionaryMemory/PhraseDictionaryCompact/g" "$WORKING/train/model/model/moses.ini"
sed -i  -e "s#phrase-table.0-0,2.gz#phrase-table.0-0,2.minphr#g" "$WORKING/train/model/model/moses.ini"



# # # # ###bleu----------------------------------------------------------------------------------------------------------
cd $WORKING
"$HOME/mosesdecoder/bin/moses" -f "$WORKING/train/model/model/moses.ini" < "$CORPUS/test.true."$LANG1 > "$CORPUS/test.translated."$LANG2

# # # # # # ##run blue script------------------------------------------------------------------------------------------------
"$HOME/mosesdecoder/scripts/generic/multi-bleu.perl" -lc "$CORPUS/test.true."$LANG2 < "$CORPUS/test.translated."$LANG2 > "$HOME/$EXP_DIR/blue_$LANG2_$LANG1.txt"

#continue to bidirectional
echo "writting BLUE for EXP-$LANG1-$LANG2 Done!! "
echo "Success !!! Two Experiment done"