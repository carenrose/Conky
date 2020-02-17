#!/usr/bin/lua

graph_green = "009BF9"
graph_red   = "281648"

g_h = 15
g_w = 300

tab1 = "${goto 75}"
tab2 = "${goto 125}"
tab3 = "${goto 175}"

-- can't open '/sys/class/hwmon/hwmon1/temp2_input': No such file or directory
-- test for existence of temp 2
function hwmon_number(foritem)
    f = io.open("/sys/class/hwmon/hwmon0/temp2_input", "r")
    if f~=nil then
        io.close(f)
        cputemp = 0
        gputemp = 1
    else 
        gputemp = 0
        cputemp = 1
    end

    if foritem == "cpu" then 
        return cputemp
    else
        return gputemp
    end
end

function make_titles(first,second,third,fourth)
    return "${font Montserrat Light:size=8}${color1}" ..
        first .. tab1 .. second .. tab2 .. third .. tab3 .. fourth ..
        "${color}${font}"
end

-- only makes basic graph, not exec graphs
function make_graph(type)
    return "\n" ..
        "${color2}${"..type.." "..g_h..","..g_w..", "..graph_green.." "..graph_red.." -t}${color}"
end

function make_execigraph(interval, command)
    return "\n" ..
        "${color2}${execigraph "..interval.. " \"" ..command.. "\" " ..
        graph_green.." "..graph_red.." -t -l}${color}"
end

-- ////////////////////////////////////////////////////////////////////////////////////////// --
-- ////////////////////////////////////////////////////////////////////////////////////////// --
-- ////////////////////////////////////////////////////////////////////////////////////////// --

--https://unix.stackexchange.com/questions/313630/is-it-possible-to-loop-in-conky

local proc_cpuinfo = io.popen("grep -c processor /proc/cpuinfo")
local numcpus = proc_cpuinfo:read("*n")
proc_cpuinfo:close()

listcpus =
    "${font :size=8}${color2}" ..
    [[${execi 999999 lscpu | sed -nr ':a;s/  / /;ta; /Model name/ s/.*: (.*) @ .*/\1/p'}${color}${font}]] .. "\n" ..
    make_titles("", "USED", "TEMP", "FREQ")

for i = 1,numcpus
do
    listcpus = listcpus .. "\n" ..
    -- Core number
    "${font Montserrat Light:size=8}${color1}Core " .. tostring(i) .. "${color}${font}" ..
    
    -- use %
    tab1 .. "${cpu cpu" ..tostring(i).. "}%" ..
    -- temp
    tab2 .. "${hwmon " .. hwmon_number("cpu") .. " temp "..tostring(i+1).. "}°" ..
    -- frequency
    tab3 .. "${freq_g " ..tostring(i).. "} GHz"
end

listcpus = listcpus .. make_graph("cpugraph")


-- ////////////////////////////////////////////////////////////////////////////////////////// --
-- ////////////////////////////////////////////////////////////////////////////////////////// --
-- ////////////////////////////////////////////////////////////////////////////////////////// --    

-- https://askubuntu.com/questions/569085/radeon-pm-info-what-are-vclk-dclk-sclk-mclk-vddc-and-vddci
-- http://centosquestions.com/determine-amd-gpu-clock-speed-ubuntu/

radeontop = "radeontop -d- -l1 | grep -o "
cut = " | cut -c 5-7"

gpuinfo = "${font :size=8}${color2}" ..
    [[${execi 999999 lspci | grep VGA | grep -o -E '\[.*\]'}${color}${font}]] .. "\n" ..
    -- Titles
    make_titles("USED", "TEMP", "VRAM", "FREQ") ..
    -- USED
    "\n${execi 5 " .. radeontop ..[['gpu [0-9]\{1,3\}']] .. cut .. " }%" ..
    -- TEMP
    tab1 .. "${hwmon " .. hwmon_number("gpu") .. " temp 1}°" ..
    -- VRAM
    tab2 .. "${execi 5 " .. radeontop .. [['vram [0-9]\{1,3\}']] .. cut .. "}%" ..
    -- FREQ
    tab3 .. "${execi 5 /home/carenrose/.config/conky/gfx_freq.sh} MHz" ..
    -- Graph
    make_execigraph(2, radeontop..[['gpu [0-9]\{1,3\}']]..cut)


-- ////////////////////////////////////////////////////////////////////////////////////////// --
-- ////////////////////////////////////////////////////////////////////////////////////////// --
-- ////////////////////////////////////////////////////////////////////////////////////////// --    

-- NAME [1]  PATH [2]    MOUNTPOINT [3]
local lsblk = io.popen("lsblk -l -n -o NAME,PATH,MOUNTPOINT -I 8")
local disk_devices = {}
for line in lsblk:lines() do
    local cols = {}
    for col in string.gmatch(line, "%S+") do
       table.insert(cols, col) 
    end
    table.insert(disk_devices, cols)
end
lsblk:close()

listdisks = make_titles("", "TEMP", "USED", "SIZE")

for _,dev in ipairs(disk_devices) do
    -- check if name doesn't contain a number (number means it's a partition)
    if not string.match(dev[1], "%d+") then
        listdisks = listdisks .. "\n" .. 
            dev[1] .. 
            tab1.."${execi 10 sudo hddtemp -u F -n "..dev[2].."}°"        --sudo hddtemp -u F -n /dev/sda
    else if dev[3] ~= nil and dev[3] ~= '' then
        listdisks = listdisks .. 
            tab2.."${fs_used_perc "..dev[3].."}%" .. 
            tab3.."${fs_size "     ..dev[3].."}"
    end end
end

-- ////////////////////////////////////////////////////////////////////////////////////////// --
-- ////////////////////////////////////////////////////////////////////////////////////////// --
-- ////////////////////////////////////////////////////////////////////////////////////////// --    

listmem = make_titles("", "USED", "TOTAL", "PERC") .. "\n" ..
    "RAM" .. tab1 .. "${mem}" .. tab2 .. "${memmax}" .. tab3 .. "${memperc}%\n" ..
    "SWAP".. tab1 .. "${swap}".. tab2 .. "${swapmax}".. tab3 .. "${swapperc}%" ..
    make_graph("memgraph")
    make_graph("swapgraph")

-- ////////////////////////////////////////////////////////////////////////////////////////// --
-- ////////////////////////////////////////////////////////////////////////////////////////// --
-- ////////////////////////////////////////////////////////////////////////////////////////// --    


function conky_cpus()
    return listcpus
end

function conky_gpu()
    return gpuinfo
end

function conky_hdds()
    return listdisks
end

function conky_mem()
    return listmem
end