#!/usr/bin/env bash

# public scripts
source "${local_bashlava_addon_path}/templates.sh"
source "${local_bashlava_addon_path}/utilities.sh"

# private scripts
# this is a custom config
# by default bashlava does not come with the private DIR
if [[ -f "${local_bashlava_addon_path}/private/_entrypoint.sh" ]]; then
  source "${local_bashlava_addon_path}/private/_entrypoint.sh"
fi
