#!/bin/bash
rm -rf ~/csv_export/*
cp -r *${1}/*.csv ~/csv_export
