#!/bin/bash

if command -v acpi &> /dev/null; then
  acpi -b | grep -oP '\d{2}:\d{2}?' | head -1 || echo "Calculando..."
else
  echo "N/A"
fi
