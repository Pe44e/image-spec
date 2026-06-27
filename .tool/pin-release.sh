#!/bin/sh

# Copyright the Open Container Initiative Contributors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
cd "$(dirname $0)/.."

if ! { command -v jq && command -v find && command -v sed; } > /dev/null; then
  echo "This command requires the following to run: find, jq, and sed" >&2
  exit 1
fi

runtime_tag=$(git ls-remote https://github.com/opencontainers/runtime-spec.git 'refs/tags/v[0-9]*' \
	| jq -rnR '
		[
			inputs
			| split("/")[2] # "commit-hash\trefs/tags/xxx^{}" -> "xxx^{}"
			| split("^")[0] # "xxx^{}" -> "xxx"
			| select(contains("-") | not) # ignore pre-releases
		]
		| unique_by(ltrimstr("v") | split(".") | map(tonumber? // .)) # very very rough version sorting (and dedupe)
		| .[-1] # we only care about "latest" (the last entry)
	')

distribution_tag=$(git ls-remote https://github.com/opencontainers/distribution-spec.git 'refs/tags/v[0-9]*' \
	| jq -rnR '
		[
			inputs
			| split("/")[2] # "commit-hash\trefs/tags/xxx^{}" -> "xxx^{}"
			| split("^")[0] # "xxx^{}" -> "xxx"
			| select(contains("-") | not) # ignore pre-releases
		]
		| unique_by(ltrimstr("v") | split(".") | map(tonumber? // .)) # very very rough version sorting (and dedupe)
		| .[-1] # we only care about "latest" (the last entry)
	')

find . -name '*.md' -exec sed -i \
  -e "s#https://github.com/opencontainers/runtime-spec/blob/main/#https://github.com/opencontainers/runtime-spec/blob/${runtime_tag}/#g" \
  -e "s#https://github.com/opencontainers/distribution-spec/blob/main/#https://github.com/opencontainers/distribution-spec/blob/${distribution_tag}/#g" \
  '{}' \;
