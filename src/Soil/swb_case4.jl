# INPUT:
# θ       -- soil water content, 3 layers
# I       -- total water enter into soil surface, mm
# pEc     -- potential ET allocate to plant, mm
# pEs     -- potential ET allocate to soil surface, mm
# soilpar -- soil-related parameters
# pftpar  -- plant-related parameters
# wet     -- wetness indice
# Δz      -- soil layer depth, 3 layers
# zwt     -- groundwater table depth, mm
function swb_case4(I, pEc, pEs, s_tem, s_vod, soilpar, pftpar, fwet, soil::Soil)
  (; θ_prev, θ, Δz, zwt, Ec_sm, Ec_gw, sink) = soil
  (; θ_sat, θ_wp) = soilpar
  d1, d2, d3 = Δz
  
  # # ====== Water Supplement ====== #
  wa1_unsat, wa2_unsat, wa3_unsat = θ # 需要更新
  vw3 = SM_recharge!(θ, I; Δz, θ_sat)
  wa1, wa2, wa3 = θ

  f_cons = s_tem * s_vod
  Tr, Es = Evapotranspiration!(soil, pEc, pEs, fwet, f_cons, soilpar, pftpar)

  # ====== Soil Water Drainage (Unsaturated Zone) ====== #
  sink[2] = clamp(Ec_sm[2] + Ec_gw[2], 0, d2 * (wa2 - θ_wp))
  sink[3] = clamp(Ec_sm[3] + Ec_gw[3], 0, d3 * (wa3 - θ_wp))

  ## 新方案  
  θ_unsat = [wa1_unsat, wa2_unsat, wa3_unsat]
  exceed = SM_discharge!(soil, θ_unsat, sink, soilpar)
  wa1, wa2, wa3_unsat = θ_unsat
  wa3 = wa3_unsat

  # ====== The Groundwater Table Depth ====== #
  sy = 0.2 # specific yield as 0.2
  Δw = exceed + vw3 - sum(Ec_gw) - GW_Rsb(zwt)
  zwt = zwt - Δw / sy
  uex = 0  # excess water to soil surface, mm

  # Update soil moisture and groundwater table depth
  if zwt > z₊ₕ[3]
    # "nothing"
  elseif z₊ₕ[2] < zwt <= z₊ₕ[3]
    wa3 = (wa3_unsat * (zwt - z₊ₕ[2]) + θ_sat * (z₊ₕ[3] - zwt)) / Δz[3]
  elseif z₊ₕ[1] < zwt <= z₊ₕ[2]
    wa2 = (wa2 * (zwt - z₊ₕ[1]) + θ_sat * (z₊ₕ[2] - zwt)) / Δz[2]
    wa3 = θ_sat
  elseif 0 < zwt <= z₊ₕ[1]
    wa1 = (wa1 * zwt + θ_sat * (Δz[1] - zwt)) / Δz[1]
    wa2 = θ_sat
    wa3 = θ_sat
  elseif zwt <= 0
    wa1 = θ_sat
    wa2 = θ_sat
    wa3 = θ_sat
    uex = -zwt * θ_sat  # excess water to soil surface, mm
  end

  # Updated soil water content
  soil.θ .= [wa1, wa2, wa3]
  soil.zwt = max(0, zwt)
  return Tr, Es, uex
end
