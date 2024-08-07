import ripserplusplus as rpp_py

# Calculates the persistence diagram of the Vietoris-Rips
# filtration of a point-cloud, required GPU:
def VR_PD(point_cloud, until_h_dim):
  '''
    point_cloud: np.array([points])
    -------------------------------
    returns:
  '''
      # compute (birth, death) pairs:
  BDS = rpp_py.run(f"--format point-cloud --dim {until_h_dim}", point_cloud)
      # Convert dictionary of pairs (tuples) to dictionary of arrays
  return \
  {
       hom_dim : BDS[hom_dim].view(dtype=np.float32, type=np.ndarray).reshape(-1, 2)
       for hom_dim in range(until_h_dim + 1)
  }