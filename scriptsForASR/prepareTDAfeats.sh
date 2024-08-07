# creates TDA features and replaces feats.scp by them, similarly for cmvn.scp.
# For "fMLLR of TDA features" we will also remove the symbolic links of the
# tr_2/3 models created by "prepareTDA.sh", however we assume they exist initially
# to apply LDA (see "model_dir")

  # select the TDA model type:
  # 0 ~ TDA features only
  # 1 ~ TDA and MFCC combination
  # 2 ~ TDA and fMLLR combination
  # 3 ~ fMLLR of TDA features
model_type=$1

  # select TDA feature type.
  # Pick from TDAmel, TDAaud, TDAtakens or TDAall 
feat_name=$2

TDA_feats_path=$3

  # directories/paths/etc:
data_dir=$PWD/data
model_dir=$PWD/exp/tri3_ali


if [ $feat_name = TDAall ]
then
  temp_train_feats="ark:paste-feats scp:$TDA_feats_path/train_TDAmel.scp scp:$TDA_feats_path/train_TDAaud.scp scp:$TDA_feats_path/train_TDAtakens.scp ark:- |" 
else 
  temp_train_feats="scp:$TDA_feats_path/train_${feat_name}.scp"
fi
 


if [ $model_type -eq 1 ] # TDA and MFCC combination
then
  temp_train_feats="ark:paste-feats \"${temp_train_feats}\" scp:$data_dir/train/feats.scp ark:- |"
elif [ $model_type -eq 2 ] # TDA and fMLLR combination
then

    # computing the cmvn early:
  compute-cmvn-stats --spk2utt=ark:$data_dir/train/spk2utt "$temp_train_feats" ark,scp:$data_dir/TDA_transforms/train_TDAcmvn.ark,$data_dir/TDA_transforms/train_TDAcmvn.scp
  
    # computing the fMLLR transforms early:
  gmmdir=$PWD/exp/tri3
  transform_dir=${gmmdir}_ali
  D=$gmmdir
  
  [ -f $D/cmvn_opts ] && cmvn_opts=$(cat $D/cmvn_opts) || cmvn_opts=
  
  [ -f $D/splice_opts ] && splice_opts=$(cat $D/splice_opts) || splice_opts=
  
    temp_train_feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$data_dir/train/utt2spk scp:$data_dir/train/cmvn.scp scp:$data_dir/train/feats.scp ark:- | \
   splice-feats $splice_opts ark:- ark:- | \
   transform-feats $gmmdir/final.mat ark:- ark:- | \
   transform-feats --utt2spk=ark:$data_dir/train/utt2spk \"ark:cat $transform_dir/trans.* |\" ark:- ark:- | \
   paste-feats ark:- \"ark:apply-cmvn $cmvn_opts --utt2spk=ark:$data_dir/train/utt2spk --norm-vars=false scp:$data_dir/TDA_transforms/train_TDAcmvn.scp \\\"$temp_train_feats\\\" ark:- |\" ark:- |";
  
fi


  # source the kaldi path:
[ -f ./path.sh ] && . ./path.sh;
set -e

[ -d "$data_dir/TDA_transforms" ] || (echo "The directory '$data_dir/TDA_transforms' does not exist!"; exit 1);


lang=$data_dir/lang/
silphonelist=`cat $lang/phones/silence.csl` || exit 1;
 
  # LDA hyper parameters:
if [ $model_type -eq 3 ]
then
  dim=13
else
  dim=40
fi
randprune=4.0

  # concatenate alignments together: 
cat $model_dir/ali.*.gz > $data_dir/TDA_transforms/ali_all.gz
all_alignments="ark:gunzip -c $data_dir/TDA_transforms/ali_all.gz |"

  # compute statistics for LDA:
ali-to-post "$all_alignments" ark:- | \
weight-silence-post 0.0 $silphonelist $model_dir/final.mdl ark:- ark:- | \
acc-lda --rand-prune=$randprune $model_dir/final.mdl "$temp_train_feats" ark:- \
$data_dir/TDA_transforms/TDAlda.acc

  # compute LDA transform :
est-lda --write-full-matrix=$data_dir/TDA_transforms/full.mat --dim=$dim $data_dir/TDA_transforms/0.mat $data_dir/TDA_transforms/TDAlda.acc \
         2>$data_dir/TDA_transforms/lda_est.log || exit 1;
         
         
  # apply transform and create features:
for dataset in train test dev
do 
  # selecting the correct feature type:
  if [ $feat_name = TDAall ]
  then
    feats="ark:paste-feats scp:$TDA_feats_path/${dataset}_TDAmel.scp scp:$TDA_feats_path/${dataset}_TDAaud.scp scp:$TDA_feats_path/${dataset}_TDAtakens.scp ark:- |"
  else
    feats="scp:$TDA_feats_path/${dataset}_${feat_name}.scp"
  fi
  
  
  if [ $model_type -eq 1 ] # TDA and MFCC combination
  then
    feats="ark:paste-feats \"${feats}\" scp:$data_dir/$dataset/feats.scp ark:- |"
  elif [ $model_type -eq 2 ] # TDA and fMLLR combination
  then
    if [ $dataset = test ]
    then
      transform_dir=$gmmdir/decode_test
    elif [ $dataset = dev ]
    then
      transform_dir=$gmmdir/decode_dev
    else
      transform_dir=${gmmdir}_ali
    fi
  
      # computing the cmvn early:
    compute-cmvn-stats --spk2utt=ark:$data_dir/$dataset/spk2utt "$feats" ark,scp:$data_dir/TDA_transforms/${dataset}_TDAcmvn.ark,$data_dir/TDA_transforms/${dataset}_TDAcmvn.scp
    
      # computing the fMLLR transforms:   
    feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$data_dir/$dataset/utt2spk scp:$data_dir/$dataset/cmvn.scp scp:$data_dir/$dataset/feats.scp ark:- | \
     splice-feats $splice_opts ark:- ark:- | \
     transform-feats $gmmdir/final.mat ark:- ark:- | \
     transform-feats --utt2spk=ark:$data_dir/$dataset/utt2spk \"ark:cat $transform_dir/trans.* |\" ark:- ark:- | \
     paste-feats ark:- \"ark:apply-cmvn $cmvn_opts --utt2spk=ark:$data_dir/$dataset/utt2spk --norm-vars=false scp:$data_dir/TDA_transforms/${dataset}_TDAcmvn.scp \\\"$feats\\\" ark:- |\" ark:- |";    
  fi
    
  # for each model we will over-ride the regular features  
  # but we need a temporary ark file to coomplish this (for model_type 2):
  transform-feats $data_dir/TDA_transforms/0.mat "$feats" \
      ark:$data_dir/$dataset/TEMPfeats.ark

  copy-feats ark:$data_dir/$dataset/TEMPfeats.ark ark,scp:$data_dir/$dataset/feats.ark,$data_dir/$dataset/feats.scp

  rm $data_dir/$dataset/TEMPfeats.ark

  sort $data_dir/$dataset/feats.scp -o $data_dir/$dataset/feats.scp

  compute-cmvn-stats --spk2utt=ark:$data_dir/$dataset/spk2utt scp:$data_dir/$dataset/feats.scp ark,scp:$data_dir/$dataset/cmvn.ark,$data_dir/$dataset/cmvn.scp
  
done

  # removing the symbolic links for the tri_2/3 models
if [ $model_type -eq 3 ]
then
  rm tri2*
  rm tri3*
fi

echo "Sucefully prepared ${feat_name} features for model type ${model_type}!"
exit 0

