-- Force A2DP and sensible codec policy
bluez_monitor.properties = {
  ["bluez5.enable-hsp"] = false,
  ["bluez5.enable-hfp-hf"] = false,
  ["bluez5.enable-hfp-ag"] = false,
  ["bluez5.headset-roles"] = "[ ]",
  ["bluez5.codecs"] = "[ sbc sbc_xq aac ldac aptx aptx_hd ]"
}
