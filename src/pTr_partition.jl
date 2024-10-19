# Potential transpiration partition
function pTr_partition(pEc, wa1, wa2, wa3, soilpar, pftpar, fwet, zm)
  # INPUT:
  # pEc    :  Potential Evaporation on canopy
  # w      :  Initialized values for soil moisture
  # pftpar :  PFT parameters
  #
  # OUTPUT:
  # Tr_p :  separate potential Transpiration
  b = soilpar[4]
  D50 = pftpar[2]
  D95 = pftpar[3]
  c = -2.944 / log(D95 / D50)

  θ_sat = soilpar[3]

  r1 = (1 / (1 + (zm[1] / D50)^c))
  r2 = (1 / (1 + (zm[2] / D50)^c)) - (1 / (1 + (zm[1] / D50)^c))
  r3 = (1 / (1 + (zm[3] / D50)^c)) - (1 / (1 + (zm[2] / D50)^c))

  # the maximum transpiration rate of each soil layer, Tr_p
  # Get all available water contents through root distribution
  wr = r1 * (wa1 / θ_sat)^b + r2 * (wa2 / θ_sat)^b + r3 * (wa3 / θ_sat)^b

  # Root distribution adjusted by soil water content
  beta1 = r1 * (wa1 / θ_sat)^b / wr
  beta2 = r2 * (wa2 / θ_sat)^b / wr
  beta3 = r3 * (wa3 / θ_sat)^b / wr

  # potential transpiration rate for different layers
  Tr_p1 = (1 - fwet) * beta1 * pEc
  Tr_p2 = (1 - fwet) * beta2 * pEc
  Tr_p3 = (1 - fwet) * beta3 * pEc

  return Tr_p1, Tr_p2, Tr_p3
end