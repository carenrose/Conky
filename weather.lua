#!/usr/bin/env lua
-- https://bbs.archlinux.org/viewtopic.php?id=222998
-- https://gist.github.com/meskarune/e415748a104f0479f54dd642d66011e8

-- load the http socket and json modules
http = require("socket.http")
json = require("json")

-- http://openweathermap.org/help/city_list.txt, http://bulk.openweathermap.org/sample/
zip = "68508"   --cityid = "5072006"

apiurl_current  = "http://api.openweathermap.org/data/2.5/weather?zip="  .. zip
apiurl_forecast = "http://api.openweathermap.org/data/2.5/forecast?zip=" .. zip             -- this is the 5 day/every 3 hours api - the daily is subscription only

-- metric or imperial
cf = "imperial"

-- get an open weather map api key: http://openweathermap.org/appid
apikey = "038a6b2ac31bf129c70d79f21ca055fd"

apiurl_current  = ("%s&APPID=%s&units=%s"):format(apiurl_current , apikey, cf)
apiurl_forecast = ("%s&APPID=%s&units=%s&cnt=%s"):format(apiurl_forecast, apikey, cf, 3)

-- measure is °C if metric and °F if imperial
measure = "°" .. (cf == "metric" and "C" or "F")
wind_units = (cf == "metric" and "kph" or "mph")

-- Unicode weather symbols to use
icons = {
    ["01"] = "☼" ,  -- 🌣 🌙 
    ["02"] = "🌤",  -- 
    ["03"] = "🌥",  -- 
    ["04"] = "☁",
    ["09"] = "🌧",
    ["10"] = "🌦",  -- 
    ["11"] = "🌩",
    ["13"] = "❄",
    ["50"] = "🌫"
    -- 🌪 	CLOUD WITH TORNADO
}

currenttime = os.date("!%Y%m%d%H%M%S")

read_file = function(file)
    f, err = io.open(file, "r")      -- open file read-only
    if f ~= nil then
        filetext = f:read()
        if filetext ~= nil and filetext ~= '' then 
            data = json.decode(filetext)
            f:close()
            return data
        end
    else
        print("Couldn't open file: "..err)
    end
    return nil
end

write_file = function(file, data)
    cache, err = io.open(file, "w+")     -- open file overwrite or create
    if cache ~= nil then
        data.timestamp = currenttime
        save = json.encode(data)
        cache:write(save)
        cache:close()
    else
        print("Couldn't open file: "..err)
    end
end

time_passed = function(data)
    if data == nil or data.timestamp == nil then
        return 6000
    else
        return os.difftime(currenttime, data.timestamp)
    end
end

run_request = function(file, url)
    data = read_file(file)
    
    -- if not enough time has passed, just use the data in the cache file
    timepassed = time_passed(data)

    if timepassed >= 3600 then
        response = http.request(url)        -- request
        if response then
            data = json.decode(response)
            write_file(file, data)
        end
    end

    return data
end

function replace_vars(str, vars)
    -- from http://lua-users.org/wiki/StringInterpolation
    -- Allow replace_vars{str, vars} syntax as well as replace_vars(str, {vars})
    if not vars then
      vars = str
      str = vars[1]
    end
    return (string.gsub(str, "({([^}]+)})",
      function(whole,i)
        return vars[i] or whole
      end))
end

math.round = function(n)
    return math.floor(n + 0.5)
end

is_night = function(sunrise, sunset)
    cur = os.time()
    if os.difftime(cur, sunset) >= 0 or os.difftime(cur, sunrise) < 0 then
        return true
    end
end

current  = run_request("/home/carenrose/.config/conky/weather.json" , apiurl_current)
--forecast = run_request("/home/carenrose/.config/conky/forecast.json", apiurl_forecast)
    
if current ~= nil and current.main ~= nil then
    -- since replace_vars relies on {} being used around the variables (yes, I tried changing it),
    -- the actual curlies for the conky vars are <> instead
    conky_text = replace_vars{
[[$<voffset 20>$<goto 15>$<font {font2}:size=36>{icon}]]..
[[$<goto 70>$<voffset -15>$<font :size=18>$<color1> {temp}$<voffset -10>$<font> {measure}$<color>$<voffset 10>]]..
[[$<color>$<font :size=8> (Feels like {feelslike}{measure})
$<goto 75>$<voffset 5>{conditions}$<font>
$<alignc>High: $<color1>{max}{measure}    $<color>Low: $<color1>{min}{measure}$<color>
$<alignc>Humidity: $<color1>{humidity}%$<color>
$<voffset 5>$<alignc>$<color1>{sunrise}$<color> $<font {font2}>─$<voffset -3> {sunicon} $<voffset 3>─$<font> $<color1>{sunset}$<color>]],
        font       = 'Droid Sans Mono',
        font2      = 'Symbola',
        icon       = icons[current.weather[1].icon:sub(1, 2)],
        measure    = measure,
        conditions = current.weather[1].main, --description,
        temp       = math.round(current.main.temp),
        min        = math.round(current.main.temp_min),
        max        = math.round(current.main.temp_max),
        feelslike  = math.round(current.main.feels_like),
        humidity   = current.main.humidity,
        wind       = math.round(current.wind.speed),
        sunrise    = os.date("%H:%M %p", current.sys.sunrise),
        sunset     = os.date("%H:%M %p", current.sys.sunset),
        sunicon    = is_night(sunrise, sunset) and '🌟' or '🌅'
    }

    --[[if forecast ~= nil and forecast.list ~= nil then
        fctext = "\n$<hr>\n"
        curdate = ""
        for idx, day in ipairs(forecast.list) do
            itemdate = day.dt_txt:sub(1, 10)        -- "dt_txt": "2020-01-07 15:00:00"
            if itemdate ~= curdate then
                fctext = fctext .. replace_vars{
                    "{date} {desc}: {high}{meas} | {low}{meas}\n",
                    --icon = icons[day.weather.icon:sub(1, 2)],
                    desc = day.weather.main,
                    high = math.round(day.main.temp_max),
                    low  = math.round(day.main.temp_min),
                    meas = measure,
                    date = os.date("%a %m/%d", day.dt)
                }
                curdate = itemdate
            end
        end
        conky_text = conky_text .. fctext
    end]]
        
    io.write(conky_text:gsub("<", "{"):gsub(">", "}"))
else
    print("Sorry, no weather at this time")
end
