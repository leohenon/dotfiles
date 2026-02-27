#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy Local IP
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Utilities

ipconfig getifaddr en0 | pbcopy
