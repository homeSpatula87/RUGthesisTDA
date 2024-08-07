#!/usr/bin/env bash

# Copyright 2012-2015  Brno University of Technology (author: Karel Vesely),
#                 
# Apache 2.0.
#
# This script dumps fMLLR features in a new data directory, 
# which is later used for neural network training/testing.

# Begin configuration section.  
nj=4
cmd=run.pl

# End configuration section.

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

set -euo pipefail


data=$1
srcdata=$2
logdir=$3
feadir=$4
model_type=$5

sdata=$srcdata/split$nj;

# Get the config,

mkdir -p $data $logdir $feadir
[[ -d $sdata && $srcdata/feats.scp -ot $sdata ]] || split_data.sh $srcdata $nj || exit 1;

# Check files exist,
for f in $sdata/1/feats.scp $sdata/1/cmvn.scp; do
  [ ! -f $f ] && echo "$0: Missing $f" && exit 1;
done


# Hand-code the feature pipeline,
if [ $model_type -eq 2 ]
then
  feats="scp:$sdata/JOB/feats.scp";
else
  feats="ark:apply-cmvn --utt2spk=ark:$sdata/JOB/utt2spk --norm-vars=false scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- |";
fi

# Prepare the output dir,
utils/copy_data_dir.sh $srcdata $data; rm $data/{feats,cmvn}.scp 2>/dev/null
# Make $feadir an absolute pathname,
[ '/' != ${feadir:0:1} ] && feadir=$PWD/$feadir

# Store the output-features,
name=`basename $data`
$cmd JOB=1:$nj $logdir/make_fmllr_feats.JOB.log \
  copy-feats "$feats" \
  ark,scp:$feadir/feats_fmllr_$name.JOB.ark,$feadir/feats_fmllr_$name.JOB.scp || exit 1;

# Merge the scp,
for n in $(seq 1 $nj); do
  cat $feadir/feats_fmllr_$name.$n.scp 
done > $data/feats.scp

exit 0;
