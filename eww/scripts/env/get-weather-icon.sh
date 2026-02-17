#!/bin/bash

#!/bin/bash

WEATHER_FILE="/tmp/environment-data.json"

if [ ! -f "$WEATHER_FILE" ]; then
    echo ""
    exit 0
fi

weather_id=$(jq -r '.weather[0].id' "$WEATHER_FILE" 2>/dev/null)

if [ "$weather_id" = "null" ] || [ -z "$weather_id" ]; then
    echo ""
    exit 0
fi

hour=$(date +%H)
is_day=true

if [ "$hour" -gt 18 ] || [ "$hour" -lt 6 ]; then
    is_day=false
fi

case "$weather_id" in
    800)
        if [ "$is_day" = true ]; then
            echo ""
        else
            echo ""
        fi
        ;;
    
    801)
        if [ "$is_day" = true ]; then
            echo ""   
        else
            echo ""
        fi
        ;;
    
    802)
        if [ "$is_day" = true ]; then
            echo ""
        else
            echo ""
        fi
        ;;
    
    803)
        if [ "$is_day" = true ]; then
            echo ""
        else
            echo ""
        fi
        ;;
    
    804)
        echo ""
        ;;
    
    200|201|202|210|211|212|221|230|231|232)
        echo ""
        ;;
    
    300|301|302|310|311|312|313|314|321)
        if [ "$is_day" = true ]; then
            echo "" 
        else
            echo ""
        fi
        ;;
    
    500)
        echo ""
        ;;
    
    501)
        echo ""
        ;;
    
    502)
        echo "" 
        ;;
    
    503|520|521)
        echo ""
        ;;
    
    504|522|531)
        echo ""
        ;;
    
    511)
        echo ""
        ;;
    
    600|601|602|611|612|613|615|616|620|621|622)
        echo ""
        ;;
    
    701|711|721|731|741|751|761|762|771|781)
        echo ""
        ;;
    
    *)
        echo ""
        ;;
esac
