#!/bin/bash

# Copyright 2019 The Kubernetes Authors.
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
set -euo pipefail

if ! command -v kind --version &> /dev/null; then
  echo "kind is not installed. Use the package manager or visit the official site https://kind.sigs.k8s.io/"
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

echo "Kubernetes cluster:"
kubectl get nodes -o wide

echo -e "Granting permissions to e2e service account..."
kubectl create serviceaccount external-secrets-e2e || true
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --serviceaccount=default:external-secrets-e2e || true

echo -e "Granting anonymous access to service account issuer discovery"
kubectl create clusterrolebinding service-account-issuer-discovery-binding \
  --clusterrole=system:service-account-issuer-discovery \
  --group=system:unauthenticated || true

echo -e "Starting the e2e test pod ${E2E_IMAGE_NAME}:${VERSION}"
kubectl run --rm \
  --attach \
  --restart=Never \
  --pod-running-timeout=5m \
  --labels="app=eso-e2e,azure.workload.identity/use=true" \
  --env="ACK_GINKGO_DEPRECATIONS=2.9.5" \
  --env="GINKGO_LABELS=${GINKGO_LABELS:-.*}" \
  --env="GCP_SM_SA_JSON=${GCP_SM_SA_JSON:-}" \
  --env="GCP_PROJECT_ID=${GCP_PROJECT_ID:-}" \
  --env="GCP_GSA_NAME=${GCP_GSA_NAME:-}" \
  --env="GCP_KSA_NAME=${GCP_KSA_NAME:-}" \
  --env="GCP_GKE_ZONE=${GCP_GKE_ZONE:-}" \
  --env="GCP_GKE_CLUSTER=${GCP_GKE_CLUSTER:-}" \
  --env="AWS_REGION=${AWS_REGION:-}" \
  --env="AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-}" \
  --env="AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-}" \
  --env="AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN:-}" \
  --env="AWS_SA_NAME=${AWS_SA_NAME:-}" \
  --env="AWS_SA_NAMESPACE=${AWS_SA_NAMESPACE:-}" \
  --env="TFC_AZURE_CLIENT_ID=${TFC_AZURE_CLIENT_ID:-}" \
  --env="TFC_AZURE_CLIENT_SECRET=${TFC_AZURE_CLIENT_SECRET:-}" \
  --env="TFC_AZURE_TENANT_ID=${TFC_AZURE_TENANT_ID:-}" \
  --env="TFC_VAULT_URL=${TFC_VAULT_URL:-}" \
  --env="AKEYLESS_ACCESS_ID=${AKEYLESS_ACCESS_ID:-}" \
  --env="AKEYLESS_ACCESS_TYPE=${AKEYLESS_ACCESS_TYPE:-}" \
  --env="AKEYLESS_ACCESS_TYPE_PARAM=${AKEYLESS_ACCESS_TYPE_PARAM:-}" \
  --env="GITLAB_TOKEN=${GITLAB_TOKEN:-}" \
  --env="GITLAB_PROJECT_ID=${GITLAB_PROJECT_ID:-}" \
  --env="GITLAB_ENVIRONMENT=${GITLAB_ENVIRONMENT:-}" \
  --env="ORACLE_USER_OCID=${ORACLE_USER_OCID:-}" \
  --env="ORACLE_TENANCY_OCID=${ORACLE_TENANCY_OCID:-}" \
  --env="ORACLE_REGION=${ORACLE_REGION:-}" \
  --env="ORACLE_FINGERPRINT=${ORACLE_FINGERPRINT:-}" \
  --env="ORACLE_KEY=${ORACLE_KEY:-}" \
  --env="SCALEWAY_API_URL=${SCALEWAY_API_URL:-}" \
  --env="SCALEWAY_REGION=${SCALEWAY_REGION:-}" \
  --env="SCALEWAY_PROJECT_ID=${SCALEWAY_PROJECT_ID:-}" \
  --env="SCALEWAY_ACCESS_KEY=${SCALEWAY_ACCESS_KEY:-}" \
  --env="SCALEWAY_SECRET_KEY=${SCALEWAY_SECRET_KEY:-}" \
  --env="DELINEA_TLD=${DELINEA_TLD:-}" \
  --env="DELINEA_URL_TEMPLATE=${DELINEA_URL_TEMPLATE:-}" \
  --env="DELINEA_TENANT=${DELINEA_TENANT:-}" \
  --env="DELINEA_CLIENT_ID=${DELINEA_CLIENT_ID:-}" \
  --env="DELINEA_CLIENT_SECRET=${DELINEA_CLIENT_SECRET:-}" \
  --env="SECRETSERVER_USERNAME=${SECRETSERVER_USERNAME:-}" \
  --env="SECRETSERVER_PASSWORD=${SECRETSERVER_PASSWORD:-}" \
  --env="SECRETSERVER_URL=${SECRETSERVER_URL:-}" \
  --env="GRAFANA_URL=${GRAFANA_URL:-}" \
  --env="GRAFANA_TOKEN=${GRAFANA_TOKEN:-}" \
  --env="VERSION=${VERSION}" \
  --env="TEST_SUITES=${TEST_SUITES}" \
  --overrides='{ "apiVersion": "v1", "spec":{"serviceAccountName": "external-secrets-e2e"}}' \
  e2e --image=${E2E_IMAGE_NAME}:${VERSION}
