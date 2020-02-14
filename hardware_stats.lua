#!/usr/bin/lua

color5 = '#009BF9',  -- graph "green"
color6 = '#281648',  -- graph "red"

tab1 = "${goto 75}"
tab2 = "${goto 125}"
tab3 = "${goto 175}"

function conky_cpu_hwmon(core)
    -- can't open '/sys/class/hwmon/hwmon1/temp2_input': No such file or directory

    -- test for existence of temp 2

    local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end
