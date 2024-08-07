# Defines the a statistical summary based on the one from [0] and in combination with parts from [1].
# Code written by Carolos, 2024

import numpy as np
from scipy.stats import iqr

  # function a dictionary with vectorizations per
  # homology dimension into a single array:
def merge_hom_dims(BD_feats_dict):
    return np.concatenate(list(BD_feats_dict.values()))


def stat_feats(BD_diagram, ext = False, red0 = True):
    '''
        calculates the statistical summary of a persistence diagram
        based on [0,1].
        ------------------------------------------------------------
        BD_diagram:
          a dictionary of the form {i : arr}, where i is the
          homology dimension and arr is the corresponding array of
          birth death pairs.
        hom_dims:
          a boolean, if true, we calculate some extra features (some
          from [1]),           if false, we only calculate the
          statistical summary from [0].
        red0:
          a boolean, if true, we do not copmute the full vectorization
          for the 0th           dimensional homological features
          (advisable if all those features are born at 0).
        -------------------------------------------------------------
        Output:
          a dictionary of the form {i : arr}, where i is the 
          homology dimension and arr is the summary.
    '''
    hom_dims = BD_diagram.keys()

      # the dictionary of features we will return:
    feats_dict = {}

    if ext:
          # function computing the selected features from [1]:
        def ext_stats(BDs):
            sorted_lengths = []
            feats_per_dim = []
            combined_feats = []
            
            for BD in BDs.values():
                sorted_lengths.append(np.sort(BD[:, 0] - BD[:, 1]))
            
            for lengths in sorted_lengths:
                inter_feats = []
                
                inter_feats += list(lengths[:5]) + [0] * (5 - len(lengths[:5]))
                
                safe_idx = 0 if lengths.size == 0 else lengths[0]
                safe_length = 1 if lengths.size == 0 else lengths.size
                inter_feats.append(safe_idx / safe_length)
                safe_mean = 1 if (len(lengths) == 0 or 
                                 np.mean(lengths) == 0) else np.mean(lengths)
                inter_feats.append(safe_idx / safe_mean)
                feats_per_dim.append(np.array(inter_feats))
                 
            if len(sorted_lengths) > 1:
                for idx in range(len(sorted_lengths) - 1):
                      # in case there are not enough birth/death pairs:
                    safe_lengths_idx = np.array(list(sorted_lengths[idx][:5]) + \
                                                [0] * (5 - len(sorted_lengths[idx][:5])))
                    safe_lengths_succ_idx = np.array(list(sorted_lengths[idx + 1][0:6]) + \
                                                [0] * (6 - len(sorted_lengths[idx + 1][:6])))
                    
                    combined_feats += list(safe_lengths_idx[:5] * safe_lengths_succ_idx[:5])
                    combined_feats += list(safe_lengths_idx[:5] * \
                                        (safe_lengths_succ_idx[:5] - safe_lengths_succ_idx[1:6]))
                                        
                    if sorted_lengths[idx + 1].size == 0 or np.mean(sorted_lengths[idx + 1]) == 0 \
                                                         or sorted_lengths[idx].size == 0:
                        safe_div_means = 0
                    else:
                        safe_div_means = np.mean(sorted_lengths[idx]) / np.mean(sorted_lengths[idx + 1])
                    combined_feats.append(safe_div_means)
                    
                if sorted_lengths[1].size < 2 or sorted_lengths[1][1] == 0:
                    periodicity = 0
                else:
                    periodicity = 1 - sorted_lengths[1][0] / sorted_lengths[1][1]

                feats_per_dim[1] = np.append(feats_per_dim[1], periodicity)
        
            return (feats_per_dim, np.array(combined_feats))

        ext_per_dim, ext_comb = ext_stats(BD_diagram)
        
        feats_dict['combination'] = ext_comb
         
         # Computing the features from [0] (Possible improvement: most computations
         # could be done for all hom_dims at once)
    for hom_dim in hom_dims:
    
        selected_hom = BD_diagram[hom_dim]
         # make sure we have at least one birth death pair so that the statistics
         #can be computed:
        if selected_hom.size == 0:
            selected_hom = np.array([[0, 0]])
            
            # in homology_dimension 0, all births start at 0, hence most statistics
            # are not interesting:
        to_be_analized = []
        
        if hom_dim != 0 or not red0:
            births = selected_hom[:, 0]
            midpoints = (selected_hom[:, 0] + selected_hom[:, 1]) / 2
            lengths = selected_hom[:, 1] - selected_hom[:, 0]
            to_be_analized = [births, midpoints, lengths]
            
        deaths = selected_hom[:, 1]
        to_be_analized += [deaths]
        arr_to_be_analized = np.stack(to_be_analized, axis = 1)
        
        def compute_stats(arr):
            return np.array([np.mean(arr, axis = 0), np.std(arr, axis = 0), np.median(arr, axis = 0),
                                iqr(arr, axis = 0), np.ptp(arr, axis = 0)] +
                                list(np.percentile(arr, [10, 25, 75, 90], axis = 0)))               

        def calc_enthropy(BD):
            diff = BD[:, 1] - BD[:, 0]
            L_sum = np.sum(diff)
            if L_sum == 0:
                return 0
            return - np.sum(diff / L_sum * np.log(diff / L_sum))

        if not ext:
            stats_arr = np.append(np.stack(compute_stats(arr_to_be_analized)),
                    [len(deaths), calc_enthropy(selected_hom)])
        else:
            stats_arr = np.concatenate((np.stack(compute_stats(arr_to_be_analized)).flatten(),
                    [len(deaths), calc_enthropy(selected_hom)], ext_per_dim[hom_dim]))
            

        feats_dict[hom_dim] = stats_arr
    
    return feats_dict 


# References:

# [0]: Ali, D., Asaad, A., Jimenez, M. J., Nanda, V.,
# Paluzo-Hidalgo, E., & Soriano-Trigueros, M. (2023).
# A survey of vectorization methods in topological data analysis.
# IEEE Transactions on Pattern Analysis and Machine Intelligence.

# [1]: Fireaizen, T., Ron, S., & Bobrowski, O. (2022, May).
# Alarm sound detection using topological signal processing.
# In ICASSP 2022-2022 IEEE International Conference on Acoustics,
# Speech and Signal Processing (ICASSP) (pp. 211-215). IEEE.