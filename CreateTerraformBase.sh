#!/bin/bash

aws cloudformation create-stack \
--stack-name TerraformBaseStack \
--template-body file://TerraformBase.yaml \
--region eu-west-1 \
--profile alberto
