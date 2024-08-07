  # the new timit directory to transform:
new_timit=/the_path/to/new/kaldi/timit/folder
[ ! -d $new_timit ] && echo "Incorrect new timit path!" && exit 1;

  # the old timit directory to link back to:
old_timit=/the_path/to/old/kaldi/timit/folder
[ ! -d $old_timit ] && echo "Incorrect old timit path!" && exit 1;


  # removing the old DNNs:
rm -r $new_timit/s5/exp/dnn*

  # removing the old mono/triphone models and
  # creating symbolic links:
for direc in $new_timit/s5/exp/*; do
  rm -r $direc
  ln -s $old_timit/s5/exp/$( basename $direc ) $direc
done  

  # Creat a directory to store the LDA transform for the TDA features
mkdir $new_timit/s5/data/TDA_transforms

  # Copying the TDA recepy files to the right places
cp -p runTDA.sh $new_timit/s5/runTDA.sh
cp -p prepareTDAfeats.sh $new_timit/s5/local/prepareTDAfeats.sh
cp -p run_dnnTDA.sh $new_timit/s5/local/nnet/run_dnnTDA.sh
cp -p make_fmllr_featsTDA.sh $new_timit/s5/local/nnet/make_fmllr_featsTDA.sh

echo 'Sucesfully prepared the new timit folder!'
exit 0
