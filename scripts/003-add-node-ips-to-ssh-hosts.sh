#!/bin/bash

# Check if ip is already in known_hosts, if so, remove it and add it again
if ssh-keygen -F $TF_OUTPUT_MANAGER_IP > /dev/null; then
    ssh-keygen -f ~/.ssh/known_hosts -R $TF_OUTPUT_MANAGER_IP
fi

if  ssh-keygen -F $TF_OUTPUT_WORKER1_IP > /dev/null; then
    ssh-keygen -f ~/.ssh/known_hosts -R $TF_OUTPUT_WORKER1_IP
fi

if ssh-keygen -F $TF_OUTPUT_WORKER2_IP > /dev/null; then
    ssh-keygen -f ~/.ssh/known_hosts -R $TF_OUTPUT_WORKER2_IP
fi

ssh-keyscan -H $TF_OUTPUT_MANAGER_IP >> ~/.ssh/known_hosts
ssh-keyscan -H $TF_OUTPUT_WORKER1_IP >> ~/.ssh/known_hosts
ssh-keyscan -H $TF_OUTPUT_WORKER2_IP >> ~/.ssh/known_hosts
