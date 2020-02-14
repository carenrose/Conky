#!/usr/bin/lua
-- https://unix.stackexchange.com/questions/313630/is-it-possible-to-loop-in-conky

local file = io.popen("grep -c processor /proc/cpuinfo")
local numcpus = file:read("*n")
file:close()

tab1 = "${goto 75}"
tab2 = "${goto 125}"
tab3 = "${goto 175}"

-- Titles
listcpus = "${font Montserrat Light:size=8}${color1}" ..
    tab1 .. "USED"  ..
    tab2 .. "TEMP" ..
    tab3 .. "FREQ" ..
    "${color}${font}"

for i = 1,numcpus
do
    listcpus = listcpus .. "\n" ..
    -- Core number
    "${font Montserrat Light:size=8}${color1}Core " .. tostring(i) .. "${color}${font}" ..
    
    -- use %
    tab1 .. "${cpu cpu" ..tostring(i).. "}%" ..
        -- temp
        tab2 .. "${hwmon 0 temp "..tostring(i+1).. "}°" ..
        -- frequency
        tab3 .. "${freq_g " ..tostring(i).. "} GHz"
end

function conky_mycpus()
    return listcpus
end
