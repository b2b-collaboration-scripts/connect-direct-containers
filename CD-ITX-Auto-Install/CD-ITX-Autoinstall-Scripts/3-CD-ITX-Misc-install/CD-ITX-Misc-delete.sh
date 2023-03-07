#!/bin/bash
# sfg-misc-delete.sh

printf "\n\n########## Deleting SFG PV ##########\n\n"

oc delete -f $INSTALL_BASE_DIR/B2Bcontainerinstall/DeploySterlingSFGOpenShift/sfgsecrets.yaml

oc delete -f $INSTALL_BASE_DIR/B2Bcontainerinstall/DeploySterlingSFGOpenShift/sfgpv.yaml
