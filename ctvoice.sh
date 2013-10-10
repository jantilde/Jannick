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
remove_and 
say-en "$(echo $current)"
mpc play
}
function remove_and {
current=$(mpc current)
#Das kaufmännische und in ein normales und verwandeln 
if [ -n "`echo $current | grep "&"`" ]; then
	echo "[Musik] Ersetze kaufmännisches und."
	current=$(echo $current | sed 's/&/and/g')
	echo $current
fi
}
function output_file_remove {
	if [ $(sed $= -n /var/www/voice/output.txt) >= "15" ]
	then 
		rm /var/www/voice/output.txt
		touch /var/www/voice/output.txt
	fi
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
			echo "Aufnahme!" && echo -e "Aufnahme\n\r" >> /var/www/voice/output.txt
			rec=1
		else
			first=0
		fi
	else
		if [ $rec -eq 1 ]
			then
				echo "Abschicken" && echo -e "Identifiziere das Gesprochene\n\r" >> /var/www/voice/output.txt
				kill $sox_pid
				ffmpeg -loglevel panic -y -i test.wav -ar 16000 -acodec flac file.flac
				wget -q -U "Mozilla/5.0" --post-file file.flac --header "Content-Type: audio/x-flac; rate=16000" -O - "http://www.google.com/speech-api/v1/recognize?lang=de-de&client=chromium" | cut -d\" -f12 >stt.txt
				
			

				if [[ $(cat stt.txt) =~ "weiter" ]]
				then
					echo "[Musik] Sprachbefehl 'weiter' erkannt!" && echo -e "[Musik] Sprachbefehl 'weiter' erkannt!\n\r" >> /var/www/voice/output.txt
					mpc next
					say-title
					
					
					
				elif [[ $(cat stt.txt) =~ "zurück" ]]
				then
					echo "[Musik] Sprachbefehl 'zurück' erkannt!" && echo -e "[Musik] Sprachbefehl 'zurück' erkannt!\n\r" >> /var/www/voice/output.txt 					
					mpc next					
					say-title
						
				elif [[ $(cat stt.txt) =~ "Pause" ]]
				then
					echo "[Musik] Sprachbefehl 'Pause' erkannt!" && echo -e "[Musik] Sprachbefehl 'Pause' erkannt!\n\r" >> /var/www/voice/output.txt
					mpc pause 					
					say "Pausiere"
					
				elif [[ $(cat stt.txt) =~ "play" ]]
				then
					echo "[Musik] Sprachbefehl 'zurück' erkannt!" && echo -e "[Musik] Sprachbefehl 'zurück' erkannt!\n\r" >> /var/www/voice/output.txt
										
					say-title
					
				elif [[ $(cat stt.txt) =~ "leiser" || $(cat stt.txt) =~ "leise" ]]
				then
					echo "[Musik] Sprachbefehl 'leiser' erkannt!" && echo -e "[Musik] Sprachbefehl 'leiser' erkannt!\n\r" >> /var/www/voice/output.txt
					mpc volume -5 					
					say "Leiser"
					
				elif [[ $(cat stt.txt) =~ "lauter" || $(cat stt.txt) =~ "laut" ]]
				then
					echo "[Musik] Sprachbefehl 'lauter' erkannt!" && echo -e "[Musik] Sprachbefehl 'lauter' erkannt!\n\r" >> /var/www/voice/output.txt
					mpc volume +5	 					
					say "Lauter"
				elif [[ $(cat stt.txt) =~ "Titel" ]]
				then 
					echo "[Musik] Srachbefehl 'Titel' erkannt!" && echo -e "[Musik] Srachbefehl 'Titel' erkannt!\n\r" >> /var/www/voice/output.txt
					say-title				
				elif [[ $(cat stt.txt) =~ "Zufall" ]]
				then
					random=$(mpc random | head -n 3)
					if [ -n "`echo $random | grep "random: on"`" ]; then
						echo "[Musik] Zufallswiedergabe an." && echo -e "[Musik] Zufallswiedergabe an.\n\r" >> /var/www/voice/output.txt
						say "Zufallswiedergabe an."
					else
						echo "[Musik] Zufallswiedergabe aus." && echo -e "[Musik] Zufallswiedergabe aus.\n\r" >> /var/www/voice/output.txt
						say "Zufallswiedergabe aus."
						fi	
				elif [[ $(cat stt.txt) =~ "Wiederholung" ]]
				then
					repeat=$(mpc random | head -n 3)
					if [ -n "`echo $repeat | grep "repeat: on"`" ]; then
						echo "[Musik] Wiederholung an." && echo -e "[Musik] Wiederholung an.\n\r" >> /var/www/voice/output.txt
						say "Wiederholung an."
					else
						echo "[Musik] Wiederholung aus." && echo -e "[Musik] Wiederholung aus.\n\r" >> /var/www/voice/output.txt
						say "Wiederholung aus."
						fi
					# mach was
				else
 					echo "Kein Kommando erkannt..." && echo -e "Kein Kommando erkannt.\n\r" >> /var/www/voice/output.txt
				fi

			output_file_remove			
			sleep 1
			bash ctvoice.sh
		else
			echo "Bereit"
		fi
		rec=0
fi

lastsize=$size

sleep 1

done

