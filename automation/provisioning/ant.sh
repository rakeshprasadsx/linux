#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  
scriptName='ant.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	version="$1"
	echo "[$scriptName]   version    : $version"
fi

# Set parameters
executeExpression "antVersion=\"apache-ant-${version}\""
executeExpression "antSource=\"$antVersion-bin.tar.gz\""

executeExpression "cp \"/vagrant/.provision/${antSource}\" ."
executeExpression "tar -xf $antSource"
executeExpression "sudo mv $antVersion /opt/"

# Configure to directory on the default PATH
executeExpression "sudo ln -s /opt/$antVersion/bin/ant /usr/bin/ant"

# Set environment (user default) variable
echo ANT_HOME=\"/opt/$antVersion\" > $scriptName
chmod +x $scriptName
sudo mv -v $scriptName /etc/profile.d/

echo "[$scriptName] List start script contents ..."
executeExpression "cat /etc/profile.d/$scriptName"

echo "[$scriptName] --- end ---"
