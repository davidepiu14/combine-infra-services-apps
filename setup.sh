# Source: https://gist.github.com/fca66711eaf0440483eba42ee013311a

#####################################
# How to Apply GitOps to Everything #
# Combining Argo CD and Crossplane  #
# https://youtu.be/yrj4lmScKHQ      #
#####################################

# Referenced videos:
# - Argo CD - Applying GitOps Principles To Manage Production Environment In Kubernetes: https://youtu.be/vpWQeoaiRM4
# - Crossplane - GitOps-based Infrastructure as Code through Kubernetes API: https://youtu.be/n8KjVmuHm7A
# - kind - How to run local multi-node Kubernetes clusters: https://youtu.be/C0v5gJSWuSo
# - Terraform vs. Pulumi vs. Crossplane - Infrastructure as Code (IaC) Tools Compared: https://youtu.be/RaoKcJGchKM

# Using Google Cloud (GCP) for the examples

#########
# Setup #
#########

# Open https://github.com/vfarcic/combine-infra-services-apps.git

# Fork it!

# Replace `[...]` with the GitHub organization or the username
export GH_ORG=davidepiu14

git clone https://github.com/$GH_ORG/combine-infra-services-apps.git

cd combine-infra-services-apps

#############################
# Setup: Controller Cluster #
#############################

export KUBECONFIG=$PWD/kubeconfig.yaml

# Feel free to use any other Kubernetes cluster
kind create cluster --config kind.yaml

# NGINX Ingress installation might differ for your k8s provider
kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml

# If not using kind, replace `127.0.0.1.nip.io` with the base host accessible through NGINX Ingress
export BASE_HOST=127.0.0.1.nip.io

############################
# Setup: Deploy Crossplane #
############################

# Watch https://youtu.be/n8KjVmuHm7A if you are not familiar with Crossplane

helm repo add crossplane-stable \
    https://charts.crossplane.io/stable

helm repo update

helm upgrade --install \
    crossplane crossplane-stable/crossplane \
    --namespace crossplane-system \
    --create-namespace \
    --wait

helm upgrade --install argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm \
    --namespace argocd --create-namespace \
    --values argocd/helm-values.yaml --wait

##############
# Setup: GCP #
##############

export PROJECT_ID=devops-toolkit-$(date +%Y%m%d%H%M%S)

gcloud projects create $PROJECT_ID

echo https://console.cloud.google.com/marketplace/product/google/container.googleapis.com?project=$PROJECT_ID

# Open the URL and *ENABLE* the API

echo https://console.developers.google.com/apis/library/sqladmin.googleapis.com?project=$PROJECT_ID

# Open the URL and *ENABLE* the API

export SA_NAME=devops-toolkit

export SA="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts \
    create $SA_NAME \
    --project $PROJECT_ID

export ROLE=roles/admin

gcloud projects add-iam-policy-binding \
    --role $ROLE $PROJECT_ID \
    --member serviceAccount:$SA

gcloud iam service-accounts keys \
    create creds.json \
    --project $PROJECT_ID \
    --iam-account $SA
