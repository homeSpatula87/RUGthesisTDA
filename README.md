# Demonstrator: Topological Featurization of Speech Data for Speech Recognition

Here you find the necessary code to replicate the experiments from my thesis.

## Code for featurization
In the folder "TDA_featurization" you find the python code used to extract TDA features from audio.
- The file ... contains the function for creating the Takens embedded signal.
- The file ... contains the function for a persistence diagram (uses GPU).
- The file ... contains the function for a persistence diagram for sub/suplevel set filtrations.
- The file ... contains the function for creating the statistical summary of a persistence diagram.
- The file ... contains the function for defining and training the DNNs used in the feature selection.
(We will not replicate the feature selection procedure, as this would require the TIMIT corpus).
- The file ... contains a Jupyter notebook, calculating the three types of features for an example audio file.




## Code for Kaldi model training
In the folder `scriptsForASR` you find the scripts fro preparing and training Kaldi models using TDA features.
For this you will need:
- An installation of Kaldi;
- The TIMIT corpus;
- A successfully trained Kaldi model for the TIMIT corpus, using the given recipe from `kaldi/egs/timit`, until (and including) the tri3 GMM-HMM model;
- TDA features, which you have extracted from the TIMIT corpus, wing a window size of 25 ms, with a step size of 10 ms.
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

