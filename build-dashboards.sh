#!/bin/bash

for file in *.jsonnet; do
  dashboard=$(basename "${file}" .jsonnet)
  jsonnet -J vendor "${file}" -o "./provisioning/dashboards/${dashboard}.json"
done

exit 0
