#!/bin/bash

# --- Konfiguration ---
LOCATION="Linz,AT"
LANG="de"
URL="https://wttr.in/${LOCATION}?format=j1&lang=${LANG}"

# --- Skript Logik ---

# Hole die Daten von wttr.in und parse sie mit jq
# Extrahiert: Wettercode, Temperatur (C), Beschreibung, Ort, Land
# Nutzt // "N/A" als Fallback, falls ein Feld fehlt (obwohl bei wttr.in unwahrscheinlich)
weather_data=$(curl -s "${URL}")

# Prüfe, ob curl erfolgreich war
if [ $? -ne 0 ]; then
  echo '{"text": "Wetter Fehler", "tooltip": "Fehler: curl fehlgeschlagen"}'
  exit 1
fi

# Parse die benötigten Werte mit jq
# -r: raw output (keine Anführungszeichen für Strings)
code=$(echo "${weather_data}" | jq -r '.current_condition[0].weatherCode // "N/A"')
temp=$(echo "${weather_data}" | jq -r '.current_condition[0].temp_C // "N/A"')
desc=$(echo "${weather_data}" | jq -r '.current_condition[0].weatherDesc[0].value // "N/A"')
area=$(echo "${weather_data}" | jq -r '.nearest_area[0].areaName[0].value // "N/A"')
country=$(echo "${weather_data}" | jq -r '.nearest_area[0].country[0].value // "N/A"')


# Prüfe, ob jq erfolgreich war (zumindest für Code und Temp)
if [ -z "$code" ] || [ -z "$temp" ] || [ "$code" == "N/A" ] || [ "$temp" == "N/A" ]; then
   echo '{"text": "Wetter Fehler", "tooltip": "Fehler: Daten unvollständig"}'
   exit 1
fi


# Wähle das Icon basierend auf dem Wettercode
# Füge hier weitere Codes basierend auf der wttr.in Hilfe oder dem Python-Beispiel hinzu
icon=""
case "$code" in
    "113") icon="☀️";; # Clear/Sunny
    "116") icon="⛅";; # Partly cloudy
    "119"|"122") icon="☁️";; # Cloudy/Overcast
    "143"|"248"|"260") icon="🌫️";; # Mist/Fog
    "176"|"263"|"266"|"293"|"296") icon="🌧️";; # Patchy/Light Rain/Drizzle
    "299"|"302"|"308") icon="🌧️";; # Moderate/Heavy Rain
    "353"|"356"|"359") icon="🌧️";; # Rain Showers
    "311"|"314"|"317"|"320"|"350"|"362"|"365"|"374"|"377") icon="🌨️";; # Sleet/Ice pellets/Freezing rain/showers
    "323"|"326"|"329"|"332"|"335"|"338") icon="🌨️";; # Snow/Patchy Snow
    "368"|"371") icon="🌨️";; # Snow Showers
    "200"|"386"|"389"|"392"|"395") icon="⛈️";; # Thunder possible/with rain/snow
    *) icon="❓";; # Fallback
esac

# Text für Waybar (Icon + Temperatur)
display_text="${icon} ${temp}°C"

# Tooltip Text
# Beachte: Zeilenumbrüche \n müssen hier in printf nicht maskiert werden
tooltip_text="Aktuell: ${desc} in ${area}, ${country}\nTemperatur: ${temp}°C"

# Ausgabe im JSON-Format für Waybar
# printf wird verwendet, um das JSON korrekt zu formatieren
printf '{"text": "%s", "tooltip": "%s"}\n' "$display_text" "$tooltip_text"

exit 0