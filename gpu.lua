#!/usr/bin/lua


--${font :size=8}${color2}${execi 999999 lspci | grep VGA | grep -o -E '\[.*\]'}${color}${font}
--\
--${font Montserrat Light:size=8}${color1}${goto 25}USED${goto 85}TEMP${goto 125}VRAM${color}${font}
--# ${lua_parse conky_mycpus}
--${goto 25}${execi 5 radeontop -d- -l1 | grep -o 'gpu [0-9]\{1,3\}' | cut -c 5-7 }% \
--#these (hwmon 0/1) switched between cpu/gpu  
--${goto 85}${hwmon 1 temp 1}°\
--${goto 125}${execi 5 radeontop -d- -l1 | grep -o 'vram [0-9]\{1,3\}' | cut -c 5-7 }%
--${color2}${execigraph 2 "radeontop -d- -l1 | grep -o 'gpu [0-9]\{1,3\}' | cut -c 5-7" 009BF9 281648 -t -l}${color}

