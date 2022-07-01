#!/bin/bash

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--extension)
      export extr="$2"
      shift # past argument
      shift # past value
      ;;
	-b|--burst)
	  export doburst=1
	  shift
	  ;;
	-s|--sweep)
	  export dosweep=1
	  shift
	  ;;
	-d|--default)
	  export dodefault=1
	  shift
	  ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters
