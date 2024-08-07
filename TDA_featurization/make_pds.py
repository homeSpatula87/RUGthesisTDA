# functions for computing persistence diagrams:
import numpy as np
import scipy
from gtda.time_series import SlidingWindow
from gtda.time_series import SingleTakensEmbedding
from ripser import ripser
from ripser import lower_star_img


# windows a time-series:
def create_windows(audio, window_size, step_size):
  windows_tf = SlidingWindow(size=window_size, stride=step_size)
  return windows_tf.fit_transform(audio)
 

# perform Takens embedding:
def single_takens_embed(window, delay, dimension):   
  takens_tf = SingleTakensEmbedding(parameters_type = 'fixed', dimension = dimension, time_delay = delay)
  return takens_tf.fit_transform(window)

  
# Calculates the persistence diagram of the sub/suplevel
# set filtration of a 1D signal:
def sub_lvl_1d(ts):
    # Code closely follows ripser example
    Is = np.concatenate(( np.arange(ts.size - 1), np.arange(ts.size)))
    Js = np.concatenate((np.arange(1, ts.size), np.arange(ts.size)))
    vertices = np.concatenate((np.maximum(ts[0 : -1], ts[1 ::]), ts))

    distance_mat = scipy.sparse.coo_matrix((vertices, (Is, Js)), shape=(ts.size, ts.size)).tocsr()

    dgm0 = ripser(distance_mat, maxdim = 0, distance_matrix = True)['dgms'][0]
    return { 0 : dgm0[:-1] }
    
    
# Calculates the persistence diagram of the sub/suplevel
# set filtration of a surface:
def sub_lvl_2d(img):
    # We return the PD as a dictionary and throw away
    # the point that lives forever:
    return {0 : lower_star_img(img)[:-1]}
        
