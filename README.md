# Demonstrator: Topological Featurization of Speech Data for Speech Recognition

Here you find the necessary code to replicate the experiments from my thesis.

## Code for featurization
In the folder "TDA_featurization" you find the python code used to extract TDA features from audio.
- The file `make_pds.py` contains the functions for computing persistence diagrams for sub/suplevel set filtrations.
- The file `make_pds_VR.py` contains the function for computing a persistence diagram of a Viertoris-Rips filtration of a point-cloud. It is kept in a seperate file, as the used software requires GPU (in the notebook we give an example using an implementation, which does not require GPU).
- The file `stat_sum.py` contains the function for creating the statistical summary of a persistence diagram.
- The file `TDAexample.ipynb` contains a Jupyter notebook, computing the three types of features from the thesis, for an example audio file.
(We will not replicate the feature selection procedure, as this would require the TIMIT corpus).
Note that `requirements.txt` is only for teh code (not notebook) in `TDA_featurization`.



## Code for Kaldi model training
In the folder `scriptsForASR` you find the scripts for preparing and training Kaldi models using TDA features.
For this you will need:
- An installation of Kaldi;
- The TIMIT corpus;
- A successfully trained Kaldi model for the TIMIT corpus, using the given recipe from `kaldi/egs/timit`, until (and including) the tri3 GMM-HMM model;
- TDA features, which you have extracted from the TIMIT corpus, using a window size of 25 ms, with a step size of 10 ms (or at least using the same windowing as the trained Kaldi model).
The scripts assume the features are named `X_TDAmel.scp`, `X_TDAaud.scp`, `X_TDAtakens.scp`, for `X` in {`train`, `test`, `dev`}.

You will need to run `prepareTDA.sh` from within `scriptsForASR`, after having manually set the correct paths to the old Kaldi model, and to the new folder where you will train a TDA model.
This will prepare the folder accordingly.

Next you need to navigate to this newly prepared folder and edit `runTDA.sh` to select the model and feature type you wish to select. In addition, you will again have to give the path to the TDA features.

The possible model types are those from the thesis:
- TDA features only;
- TDA and MFCC combination;
- TDA and fMLLR combination;
- fMLLR of TDA features.

The possible feature types are also those from the thesis:
TDAmel, TDAaud, TDAtakens and TDAall.

To run the code, just run "runTDA.sh" from within it folder.

