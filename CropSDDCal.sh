#!/bin/bash

for file; do
    echo aliroot -b -q CropSDDCal.C\(\"$file\"\)
    aliroot -b -q CropSDDCal.C\(\"$file\"\)
done
