#!/bin/sh
# *****************************************************************************
# validateModel.sh
#
# Copyright (c) 2017, 2020, Oracle Corporation and/or its affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#     NAME
#       validateModel.sh - WLS Deploy tool to validate artifacts and print usage
#
#     DESCRIPTION
#       This script validates the model, archive structure and print usage
#
#
# This script uses the following command-line arguments directly, the rest
# of the arguments are passed down to the underlying python program:
#
#     -oracle_home
#
# This script uses the following variables:
#
# JAVA_HOME             - The location of the JDK to use.  The caller must set
#                         this variable to a valid Java 7 (or later) JDK.
#
# WLSDEPLOY_HOME        - The location of the WLS Deploy installation.
#                         If the caller sets this, the callers location will be
#                         honored provided it is an existing directory.
#                         Otherwise, the location will be calculated from the
#                         location of this script.
#
# WLSDEPLOY_PROPERTIES  - Extra system properties to pass to Java.  The caller
#                         can use this environment variable to add additional
#                         system properties to the Java environment.
#

usage() {
  echo ""
  echo "Usage: $1 [-help]"
  echo "          -oracle_home <oracle_home>"
  echo "          [-print_usage <context> [-attributes_only|-folders_only|-recursive] ]"
  echo "          [-model_file <model_file>]"
  echo "          [-variable_file <variable_file>]"
  echo "          [-archive_file <archive_file>]"
  echo "          [-target_version <target_version>]"
  echo "          [-target_mode <target_mode>]"
  echo "          [-method <method>]"
  echo ""
  echo "    where:"
  echo "        oracle_home     - the existing Oracle Home directory for the domain"
  echo ""
  echo "        print_usage     - specify the context for printing out the model structure."
  echo "                          By default, the specified folder attributes and subfolder"
  echo "                          names are printed.  Use one of the optional control"
  echo "                          switches to customize the behavior.  Note that the"
  echo "                          control switches are mutually exclusive."
  echo ""
  echo "        model_file      - the location of the model file to use if not using"
  echo "                          the -print_usage functionality.  This can also be specified as a"
  echo "                          comma-separated list of model locations, where each successive model layers"
  echo "                          on top of the previous ones.  If not specified, the tool will look for the"
  echo "                          model in the archive.  If the model is not found, validation will only"
  echo "                          validate the artifacts provided."
  echo ""
  echo "        variable_file   - the location of the property file containing"
  echo "                          the variable values for all variables used in"
  echo "                          the model if not using the -print_usage functionality."
  echo "                          If the variable file is not provided, validation will"
  echo "                          only validate the artifacts provided."
  echo ""
  echo "        archive_file    - the path to the archive file to use if not using the"
  echo "                          -print_usage functionality.  If the archive file is"
  echo "                          not provided, validation will only validate the"
  echo "                          artifacts provided.  This can also be specified as a"
  echo "                          comma-separated list of archive files.  The overlapping contents in"
  echo "                          each archive take precedence over previous archives in the list."
  echo ""
  echo "        target_version  - the target version of WebLogic Server the tool"
  echo "                          should use to validate the model content.  This"
  echo "                          version number can be different than the version"
  echo "                          being used to run the tool.  If not specified, the"
  echo "                          tool will validate against the version being used"
  echo "                          to run the tool."
  echo ""
  echo "        target_mode     - the target WLST mode that the tool should use to"
  echo "                          validate the model content.  The only valid values"
  echo "                          are online or offline.  If not specified, the tool"
  echo "                          defaults to WLST offline mode."
  echo ""
  echo "        method          - the validation method to apply. Options: lax, strict. "
  echo "                          The lax method will skip validation of external model references like @@FILE@@"
  echo ""
}

WLSDEPLOY_PROGRAM_NAME="validateModel"; export WLSDEPLOY_PROGRAM_NAME

scriptName=`basename $0`
scriptPath=$(dirname "$0")
scriptArgs=$*

. $scriptPath/shared.sh

umask 27

checkJythonArgs "$@"

# Java 7 is required, no encryption is used
javaSetup 7

runJython validate.py
