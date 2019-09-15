# Get weather using DarkSky API since NOAA's RSS feeds are malformed and crappy

LOCATION="Thanksgiving Point, Lehi, UT"

RAWWEATHER=$(curl -s https://api.darksky.net/forecast/78b9daaaa172b761881d32aab266d1c2/40.429384,-111.903896 | jq -r '"\(.currently.summary)::\(.currently.temperature)::\(.currently.windSpeed)::\(.currently.windBearing)::\(.currently.humidity)::\(.currently.cloudCover)::\(.hourly.summary)::\(.daily.summary)::\(.alerts[0].title)::\(.alerts[0].description)"')

CURSUM=$(echo "${RAWWEATHER}" | awk -F "::" '{print $1}')
CURTEMP=$(echo "${RAWWEATHER}" | awk -F "::" '{print $2}')
CURWINDSPD=$(echo "${RAWWEATHER}" | awk -F "::" '{print $3}')
CURWINDDIR=$(echo "${RAWWEATHER}" | awk -F "::" '{print $4}')
CURHUM=$(echo "${RAWWEATHER}" | awk -F "::" '{print $5'})
CURCLOUD=$(echo "${RAWWEATHER}" | awk -F "::" '{print $6}')
HOURSUM=$(echo "${RAWWEATHER}" | awk -F "::" '{print $7}')
DAYSUM=$(echo "${RAWWEATHER}" | awk -F "::" '{print $8}')
ALRTITLE=$(echo "${RAWWEATHER}" | awk -F "::" '{print $9}')
ALRDSCR=$(echo "${RAWWEATHER}" | awk -F "::" '{print $10}')

# Determine wind direction from degrees
# Defined by http://snowfence.umn.edu/Components/winddirectionanddegreeswithouttable3.htm

if [[ "${CURWINDDIR}" -gt 349 && "${CURWINDDIR}" -le 360 ]] || [[ "${CURWINDDIR}" -ge 0 && "${CURWINDDIR}" -le 11 ]]; then
	CURWINDDIR="north"
elif [[ "${CURWINDDIR}" -gt 11 && "${CURWINDDIR}" -le 34 ]]; then
	CURWINDDIR="north northeast"
elif [[ "${CURWINDDIR}" -gt 34 && "${CURWINDDIR}" -le 56 ]]; then
	CURWINDDIR="northeast"
elif [[ "${CURWINDDIR}" -gt 56 && "${CURWINDDIR}" -le 79 ]]; then
       	CURWINDDIR="east northeast"
elif [[ "${CURWINDDIR}" -gt 79 && "${CURWINDDIR}" -le 101 ]]; then
 	CURWINDDIR="east"
elif [[ "${CURWINDDIR}" -gt 101 && "${CURWINDDIR}" -le 124 ]]; then
	CURWINDDIR="east southeast"
elif [[ "${CURWINDDIR}" -gt 124 && "${CURWINDDIR}" -le 146 ]]; then
	CURWINDDIR="southeast"
elif [[ "${CURWINDDIR}" -gt 146 && "${CURWINDDIR}" -le 169 ]]; then
	CURWINDDIR="south southeast"
elif [[ "${CURWINDDIR}" -gt 169 && "${CURWINDDIR}" -le 191 ]]; then
	CURWINDDIR="south"
elif [[ "${CURWINDDIR}" -gt 191 && "${CURWINDDIR}" -le 214 ]]; then
	CURWINDDIR="south southwest"
elif [[ "${CURWINDDIR}" -gt 214 && "${CURWINDDIR}" -le 236 ]]; then
	CURWINDDIR="southwest"
elif [[ "${CURWINDDIR}" -gt 236 && "${CURWINDDIR}" -le 259 ]]; then
	CURWINDDIR="west southwest"
elif [[ "${CURWINDDIR}" -gt 259 && "${CURWINDDIR}" -le 281 ]]; then
	CURWINDDIR="west"
elif [[ "${CURWINDDIR}" -gt 281 && "${CURWINDDIR}" -le 304 ]]; then
	CURWINDDIR="west northwest"
elif [[ "${CURWINDDIR}" -gt 304 && "${CURWINDDIR}" -le 326 ]]; then
	CURWINDDIR="northwest"
elif [[ "${CURWINDDIR}" -gt 326 && "${CURWINDDIR}" -le 349 ]]; then
	CURWINDDIR="north northwest"
else
	echo "ERROR: You shouldn't have been able to get to this point! This probably means the DarkSky API is failing."
	CURWINDDIR="ERROR"
fi

# Convert decimal output to percentages

CURHUM=$(echo "${CURHUM} * 100" | bc | cut -d '.' -f 1)
CURCLOUD=$(echo "${CURCLOUD} * 100" | bc | cut -d '.' -f 1)

echo "$(date '+%Y-%m-%d %H:%M:%S') Weather for ${LOCATION}:"
echo "Currently ${CURSUM}. Current temperature is ${CURTEMP} F with humidity of ${CURHUM} percent. ${CURCLOUD} percent cloudy. Wind ${CURWINDSPD} MPH from the ${CURWINDDIR}."
echo "${HOURSUM} ${DAYSUM}"
echo

#if [[ "${ALRTITLE}" != "null" ]]; then
#	# Print alert
#	printf "\a\a\a\a\a"
#	echo "${ALRTITLE}"
#	printf "%s\n" "${ALRDSCR}"
#	echo
#fi
