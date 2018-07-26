#!/bin/bash

aws cloudformation create-stack \
--stack-name TerraformServerStack \
--template-body file://TerraformServer.yaml \
--region eu-west-1 \
--profile alberto \
--parameters \
    ParameterKey=KeyNameParam,ParameterValue=StudentKeyPair
