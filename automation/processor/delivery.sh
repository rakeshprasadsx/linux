#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		step=${1%% *}
		filename=$(basename $step)
		echo "[$scriptName][CDAF_DELIVERY_FAILURE.${filename%.*}] Execute FAILURE Returned $exitCode"
		exit $exitCode
	fi
}

# Entry point for Delivery automation.

scriptName=${0##*/}

echo
echo "[$scriptName] ================================="
echo "[$scriptName] Continuous Delivery (CD) Starting"
echo "[$scriptName] ================================="

unset CDAF_AUTOMATION_ROOT

ENVIRONMENT="$1"
if [[ $ENVIRONMENT == *'$'* ]]; then
	ENVIRONMENT=$(eval echo $ENVIRONMENT)
fi
if [ -z "$ENVIRONMENT" ]; then
	echo "[$scriptName] Environment required! EXiting code 1"; exit 1
fi 
echo "[$scriptName]   ENVIRONMENT      : $ENVIRONMENT"

RELEASE="$2"
if [[ $RELEASE == *'$'* ]]; then
	RELEASE=$(eval echo $RELEASE)
fi
if [ -z "$RELEASE" ]; then
	RELEASE='Release'
	echo "[$scriptName]   RELEASE          : $RELEASE (default)"
else
	echo "[$scriptName]   RELEASE          : $RELEASE"
fi 

OPT_ARG="$3"
echo "[$scriptName]   OPT_ARG          : $OPT_ARG"

WORK_DIR_DEFAULT="$4"
if [ -z "$WORK_DIR_DEFAULT" ]; then
	WORK_DIR_DEFAULT='TasksLocal'
fi 
echo "[$scriptName]   WORK_DIR_DEFAULT : $WORK_DIR_DEFAULT"

SOLUTION="$5"
if [[ $SOLUTION == *'$'* ]]; then
	SOLUTION=$(eval echo $SOLUTION)
fi
if [ -z "$SOLUTION" ]; then
	SOLUTION=$(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/manifest.txt" "SOLUTION")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Read of SOLUTION from ./$WORK_DIR_DEFAULT/manifest.txt failed! Returned $exitCode"
		exit $exitCode
	fi
	echo "[$scriptName]   SOLUTION         : $SOLUTION (derived from $WORK_DIR_DEFAULT/manifest.txt)"
else
	echo "[$scriptName]   SOLUTION         : $SOLUTION"
fi 

BUILDNUMBER="$6"
if [[ $BUILDNUMBER == *'$'* ]]; then
	BUILDNUMBER=$(eval echo $BUILDNUMBER)
fi
if [ -z "$BUILDNUMBER" ]; then
	BUILDNUMBER=$(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/manifest.txt" "BUILDNUMBER")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Read of BUILDNUMBER from ./$WORK_DIR_DEFAULT/manifest.txt failed! Returned $exitCode"
		exit $exitCode
	fi
	echo "[$scriptName]   BUILDNUMBER      : $BUILDNUMBER (derived from $WORK_DIR_DEFAULT/manifest.txt)"
else
	echo "[$scriptName]   BUILDNUMBER      : $BUILDNUMBER"
fi 

echo "[$scriptName]   whoami           : $(whoami)"
echo "[$scriptName]   hostname         : $(hostname)"
echo "[$scriptName]   CDAF Version     : $(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/CDAF.properties" "productVersion")"

# 2.5.5 default error diagnostic command as solution property
if [ -z "$CDAF_ERROR_DIAG" ]; then
	export CDAF_ERROR_DIAG=$(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/manifest.txt" "CDAF_ERROR_DIAG")
	if [ -z "$CDAF_ERROR_DIAG" ]; then
		echo "[$scriptName]   CDAF_ERROR_DIAG  : (not set or defined in ./$WORK_DIR_DEFAULT/manifest.txt)"
	else
		echo "[$scriptName]   CDAF_ERROR_DIAG  : $CDAF_ERROR_DIAG (defined in ./$WORK_DIR_DEFAULT/manifest.txt)"
	fi
else
	echo "[$scriptName]   CDAF_ERROR_DIAG  : $CDAF_ERROR_DIAG"
fi

workingDir=$(pwd)
echo "[$scriptName]   workingDir       : $workingDir"

processSequence=$(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/manifest.txt" "processSequence")
if [ -z "$processSequence" ]; then
	processSequence='remoteTasks.sh localTasks.sh containerTasks.sh'
else
	echo "[$scriptName]   processSequence  : $processSequence (override)"
fi

for step in $processSequence; do
	echo
	executeExpression "./$WORK_DIR_DEFAULT/${step} '$ENVIRONMENT' '$RELEASE' '$BUILDNUMBER' '$SOLUTION' '$WORK_DIR_DEFAULT' '$OPT_ARG'"
done


echo; echo "[$scriptName] ========================================="
echo "[$scriptName]        Delivery Process Complete"
echo "[$scriptName] ========================================="
