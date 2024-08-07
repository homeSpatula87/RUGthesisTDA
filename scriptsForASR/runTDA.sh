#!/usr/bin/env bash
#
# (TIMIT run.sh modified by Cárolos, 2024)
#
# Copyright 2013 Bagher BabaAli,
#           2014-2017 Brno University of Technology (Author: Karel Vesely)
#
# TIMIT, description of the database:
# http://perso.limsi.fr/lamel/TIMIT_NISTIR4930.pdf
#
# Hon and Lee paper on TIMIT, 1988, introduces mapping to 48 training phonemes,
# then re-mapping to 39 phonemes for scoring:
# http://repository.cmu.edu/cgi/viewcontent.cgi?article=2768&context=compsci
#

. ./cmd.sh
[ -f path.sh ] && . ./path.sh
set -e

# Acoustic model parameters
numLeavesTri1=2500
numGaussTri1=15000
numLeavesMLLT=2500
numGaussMLLT=15000
numLeavesSAT=2500
numGaussSAT=15000
numGaussUBM=400
numLeavesSGMM=7000
numGaussSGMM=9000

feats_nj=10
train_nj=30
decode_nj=5

echo ============================================================================
echo "               DNN Hybrid Training & Decoding (Karel's recipe)            "
echo ============================================================================

  # select the TDA model type:
  # 0 ~ TDA features only
  # 1 ~ TDA and MFCC combination
  # 2 ~ TDA and fMLLR combination
  # 3 ~ fMLLR of TDA features
model_type=0

feat_name=TDAmel

TDA_feats_path=/the_path/to/feats
[ ! -d $TDA_feats_path ] && echo "Incorrect path to TDA features!" && exit 1;

  # assume the .scp files are named a certain way:
if [ ! TDAall = TDAall ]
then
  for dataset in train test dev
  do
    [ ! -f $TDA_feats_path/${dataset}_${feat_name}.scp ] && echo "No file named \"${dataset}_${feat_name}.scp\" found" && exit 1;
  done
fi

local/prepareTDAfeats.sh $model_type $feat_name $TDA_feats_path


if [ $model_type -eq 3 ]
then
  echo ============================================================================
  echo "                 tri2 : LDA + MLLT Training & Decoding                    "
  echo ============================================================================
  
  exit 0
  
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
   --splice-opts "--left-context=3 --right-context=3" \
   $numLeavesMLLT $numGaussMLLT data/train data/lang exp/tri1_ali exp/tri2
  
  utils/mkgraph.sh data/lang_test_bg exp/tri2 exp/tri2/graph
  
  steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/tri2/graph data/dev exp/tri2/decode_dev
  
  steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/tri2/graph data/test exp/tri2/decode_test
  
  echo ============================================================================
  echo "              tri3 : LDA + MLLT + SAT Training & Decoding                 "
  echo ============================================================================
  
  # Align tri2 system with train data.
  steps/align_si.sh --nj "$train_nj" --cmd "$train_cmd" \
   --use-graphs true data/train data/lang exp/tri2 exp/tri2_ali
  
  # From tri2 system, train tri3 which is LDA + MLLT + SAT.
  steps/train_sat.sh --cmd "$train_cmd" \
   $numLeavesSAT $numGaussSAT data/train data/lang exp/tri2_ali exp/tri3
  
  utils/mkgraph.sh data/lang_test_bg exp/tri3 exp/tri3/graph
  
  steps/decode_fmllr.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/tri3/graph data/dev exp/tri3/decode_dev
  
  steps/decode_fmllr.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/tri3/graph data/test exp/tri3/decode_test
  
  steps/align_fmllr.sh --nj "$train_nj" --cmd "$train_cmd" \
   data/train data/lang exp/tri3 exp/tri3_ali
 
fi

local/nnet/run_dnnTDA.sh $model_type

echo ============================================================================
echo "                    Getting Results [see RESULTS file]                    "
echo ============================================================================

bash RESULTS dev
bash RESULTS test

echo ============================================================================
echo "Finished successfully on" `date`
echo ============================================================================

exit 0
