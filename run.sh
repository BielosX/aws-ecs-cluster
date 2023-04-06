#!/bin/bash

function deploy_cluster() {
  pushd examples/cluster || exit
  terraform init && terraform apply -auto-approve
  popd || exit
}

function destroy_cluster() {
  pushd examples/cluster || exit
  terraform destroy -auto-approve
  popd || exit
}

function deploy_service() {
  pushd examples/service || exit
  terraform init && terraform apply -auto-approve
  popd || exit
}

function destroy_service() {
  pushd examples/service || exit
  terraform destroy -auto-approve
  popd || exit
}

case "$1" in
  "deploy-cluster") deploy_cluster ;;
  "destroy-cluster") destroy_cluster ;;
  "deploy-service") deploy_service ;;
  "destroy-service") destroy_service ;;
esac