If you are the owner of one of the few (four!) prototype boards (revision
1.0), remove the comment dashes in mp2.lua in this section, so it looks like
this: 

-- MPP range of FF-OpenMPPT-ESP32 v1.0
 Vmpp_max = 23.8 
 Vmpp_min = 14.45

Add comment dashes for the production hardware revision:


-- MPP range of FF-OpenMPPT-ESP32 v1.1 and v1.2
--  Vmpp_max = 27.2
--  Vmpp_min = 13.25