#!/bin/bash

# If run from crontab then the API key should be passed in
if [ -z "$1" ]; then
    # It wasn't, so load local config
    source config.sh
else
    phantKey="$1"
    phantURL="http://data.sparkfun.com/input/"
    phantStream="ZGKzMD9lv8uo89J6YdDp"
fi

# If it isn't set then we should exit
if [ -z "$phantKey" ]; then
    echo "Phant API key is not set"
    exit 1
fi

# Set sensor readings to error value
a=$".-62"
b=$".-62"
c=$".-62"

# Read sensors until we have a non error
until [ "$a" != '.-62' ]; do
    a=$((cat /sys/bus/w1/devices/28-0000057dc9ff/w1_slave | grep  -E -o ".{0,0}t=.{0,5}" | cut -c 3-) | sed 's/.\{3\}$/.&/')
done

until [ "$b" != '.-62' ]; do
    b=$((cat /sys/bus/w1/devices/28-0000057d78d8/w1_slave | grep  -E -o ".{0,0}t=.{0,5}" | cut -c 3-) | sed 's/.\{3\}$/.&/')
done

until [ "$c" != '.-62' ]; do
    c=$((cat /sys/bus/w1/devices/28-0000057ce4e4/w1_slave | grep  -E -o ".{0,0}t=.{0,5}" | cut -c 3-) | sed 's/.\{3\}$/.&/')
done

# Get DHT22 data (this is why we need sudo)
dht22="$(python /home/pi/pi_temps/AdafruitDHT.py 22 7)"
IFS=',' read -a dht22array <<< "$dht22"

# Get BMP180 data (this is why we need sudo)
bmp180="$(python /home/pi/pi_temps/AdafruitBMP.py)"
IFS=',' read -a bmp180array <<< "$bmp180"

# Submit data to remote storage
curl -X POST "$phantURL$phantStream" \
  -H 'Phant-Private-Key: '$phantKey \
  -d 'tempa='$a'&tempb='$b'&tempc='$c'&dht22temp='${dht22array[0]}'&humidity='${dht22array[1]}'&bmp180_temp='${bmp180array[0]}'&bmp180_pressure='${bmp180array[1]}'&bmp180_altitude='${bmp180array[2]}'&bmp180_sealevel='${bmp180array[3]}''
