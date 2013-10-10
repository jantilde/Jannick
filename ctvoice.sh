#!/bin/bash

# c't Hardware Hacks - Spracherkennung für den Raspberry Pi, GPL-Lizenz

count=1
lastsize=0
rec=0
first=1

# Der Soundchip des RPI erzeugt vor und nach der Wiedergabe ein Knacken. Deutlich bessere Ergebnisse liefert eine USB-Soundkarte, wie man sie bereits für rund fünf Euro bekommt. Damit mplayer die USB-Soundkarte benutzt, ändert man den Parameter "-ao alsa:device=hw=0.0" in "-ao alsa:device=hw=1.0".

function say {
mplayer -ao alsa:device=hw=0.0 -really-quiet -http-header-fields "User-Agent:Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22m" "http://translate.google.com/translate_tts?tl=de&q=$1";
} 
function say-en {
mplayer -ao alsa:device=hw=0.0 -really-quiet -http-header-fields "User-Agent:Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22m" "http://translate.google.com/translate_tts?tl=en&q=$1";
}
function say-title {
mpc pause
 
say-en "$(mpc current)"
mpc play
}
function remove_and {
current=$(mpc current)
#Das kaufmännische und in ein normales und verwandeln 
if [ -n "`echo $current | grep "&"`" ]; then
	echo "Ersetze kaufmännisches und."
	current=$(echo $current | sed 's/&/and/g')
fi
echo $current
}

sox -t alsa hw:1,0 test.wav silence 1 0 0.5% -1 1.0 1% &
sox_pid=$!

while [ $count -le 9 ]
do
   
size=$(stat --printf="%s" test.wav)

if [ $size -gt $lastsize ]
	then
		if [ $first -eq 0 ]
		then
			echo "Aufnahme!"
			rec=1
		else
			first=0
		fi
	else
		if [ $rec -eq 1 ]
			then
				echo "Abschicken"
				kill $sox_pid
				ffmpeg -loglevel panic -y -i test.wav -ar 16000 -acodec flac file.flac
				wget -q -U "Mozilla/5.0" --post-file file.flac --header "Content-Type: audio/x-flac; rate=16000" -O - "http://www.google.com/speech-api/v1/recognize?lang=de-de&client=chromium" | cut -d\" -f12 >stt.txt
				
			

				if [[ $(cat stt.txt) =~ "weiter" ]]
				then
					echo "Sprachbefehl 'weiter' erkannt!"
					say-en "$(mpc next | head -n 1)"
					
					
					
				elif [[ $(cat stt.txt) =~ "zurück" ]]
				then
					echo "Sprachbefehl 'zurück' erkannt!" 					
					say-en "$(mpc prev | head -n 1)"
						
				elif [[ $(cat stt.txt) =~ "Pause" ]]
				then
					echo "Sprachbefehl 'Pause' erkannt!"
					mpc pause 					
					say "Pausiere"
					
				elif [[ $(cat stt.txt) =~ "play" ]]
				then
					echo "Sprachbefehl 'zurück' erkannt!"
										
					say "$(mpc play | head -n 1)"
					
				elif [[ $(cat stt.txt) =~ "leiser" ]]
				then
					echo "Sprachbefehl 'leiser' erkannt!"
					mpc volume -5 					
					say "Leiser"
					
				elif [[ $(cat stt.txt) =~ "lauter" ]]
				then
					echo "Sprachbefehl 'lauter' erkannt!"
					mpc volume +5	 					
					say "Lauter"
				elif [[ $(cat stt.txt) =~ "Titel" ]]
				then 
					echo "Srachbefehl 'Titel' erkannt!"
					say-title				

					
					# mach was
				else
 					echo "Kein Kommando erkannt..."
				fi

			sleep 1
			bash ctvoice.sh
		else
			echo "Stille..."
		fi
		rec=0
fi

lastsize=$size

sleep 1

done

