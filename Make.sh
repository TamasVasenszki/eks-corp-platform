#!/bin/bash
set -e

AWS_ACCOUNT_ID="554422868760"
AWS_REGION="eu-central-1"
CLUSTER_NAME="tomi-eks-corp-platform-cluster"
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_NAME="tomi-eks-corp-platform-app"
IMAGE_TAG="v1"
STATIC_SITE_BUCKET="tomi-eks-corp-platform-static-site"
LAMBDA_FUNCTION="tomi-eks-corp-platform-health-check"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] $1${NC}"; }

case "$1" in

  up)
    log "Starting infrastructure setup..."

    log "1/10 Applying backend-setup..."
    terraform -chdir=terraform/backend-setup init -reconfigure
    terraform -chdir=terraform/backend-setup apply -auto-approve

    log "2/10 Applying infra..."
    terraform -chdir=terraform/infra init -reconfigure
    terraform -chdir=terraform/infra apply -auto-approve

    log "3/10 Updating kubeconfig..."
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

    log "4/10 ECR login and image push..."
    docker build --platform linux/amd64 -t $ECR_URL/$IMAGE_NAME:$IMAGE_TAG ./app
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL
    docker push $ECR_URL/$IMAGE_NAME:$IMAGE_TAG

    log "5/10 Installing AWS Load Balancer Controller..."
    helm repo add eks https://aws.github.io/eks-charts 2>/dev/null || true
    helm repo update
    VPC_ID=$(terraform -chdir=terraform/infra output -raw vpc_id)
    helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
      --namespace kube-system \
      --set clusterName=$CLUSTER_NAME \
      --set serviceAccount.create=true \
      --set serviceAccount.name=aws-load-balancer-controller \
      --set region=$AWS_REGION \
      --set vpcId=$VPC_ID

    log "6/10 Creating Kubernetes secrets..."
    kubectl create secret generic eks-corp-app-secrets \
      --from-env-file=.env \
      --dry-run=client -o yaml | kubectl apply -f -

    log "7/10 Waiting for Load Balancer Controller to be ready..."
    kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=120s

    log "8/10 Applying Kubernetes manifests..."
    kubectl apply -f k8s/

    log "9/10 Waiting for ingress ALB address and updating Lambda health URL..."
    ALB_URL=""
    while [ -z "$ALB_URL" ]; do
        ALB_URL=$(kubectl get ingress eks-corp-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        if [ -z "$ALB_URL" ]; then
            echo "Waiting for ALB address..."
            sleep 15
        fi
    done
    log "ALB URL found: $ALB_URL"
    terraform -chdir=terraform/infra apply -auto-approve \
        -var="health_url=http://${ALB_URL}/health"

    log "10/10 Syncing static site to S3..."
    aws s3 sync static-site/ s3://$STATIC_SITE_BUCKET --delete

    log "Done! Infrastructure is up."
    log "CloudFront URL: $(terraform -chdir=terraform/infra output -raw cloudfront_url)"
    ;;

  down)
    warn "Tearing down infrastructure..."

    warn "0/4 Deleting Kubernetes resources..."
    kubectl delete -f k8s/ --ignore-not-found=true || true

    warn "Waiting for ALB to be deleted (60s)..."
    sleep 60

    warn "1/4 Emptying ECR and S3 buckets..."
    aws ecr batch-delete-image \
      --repository-name tomi-eks-corp-platform-app \
      --image-ids "$(aws ecr list-images --repository-name tomi-eks-corp-platform-app --query 'imageIds[*]' --output json)" \
      --region $AWS_REGION || true
    aws ecr delete-repository \
      --repository-name tomi-eks-corp-platform-app \
      --region $AWS_REGION || true
    aws s3 rm s3://tomi-eks-corp-platform-company --recursive || true
    aws s3 rm s3://tomi-eks-corp-platform-static-site --recursive || true

    warn "2/4 Destroying infra..."
    terraform -chdir=terraform/infra destroy -auto-approve

    warn "3/4 Emptying Terraform state bucket..."
    aws s3 rm s3://tomi-eks-corp-terraform-state-111 --recursive || true

    warn "4/4 Destroying backend-setup..."
    terraform -chdir=terraform/backend-setup destroy -auto-approve

    warn "Removing state bucket..."
    aws s3 rb s3://tomi-eks-corp-terraform-state-111 --force || true

    log "Done! Infrastructure is down."
    ;;

  push)
    log "Building and pushing Docker image..."
    docker build --platform linux/amd64 -t $ECR_URL/$IMAGE_NAME:$IMAGE_TAG ./app
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL
    docker push $ECR_URL/$IMAGE_NAME:$IMAGE_TAG
    log "Done!"
    ;;

  lambda)
    log "Deploying Lambda function..."
    cd lambda/health-check && npm install
    zip -r ../health-check.zip .
    cd ../..
    aws lambda update-function-code \
      --function-name $LAMBDA_FUNCTION \
      --zip-file fileb://lambda/health-check.zip \
      --region $AWS_REGION \
      --no-cli-pager
    rm lambda/health-check.zip
    log "Done!"
    ;;

  secrets)
    log "Applying Kubernetes secrets..."
    kubectl create secret generic eks-corp-app-secrets \
      --from-env-file=.env \
      --dry-run=client -o yaml | kubectl apply -f -
    log "Done!"
    ;;

  *)
    echo "Usage: ./Make.sh [up|down|push|lambda|secrets]"
    echo ""
    echo "  up      - Full infrastructure setup (terraform + helm + kubectl + secrets + static site)"
    echo "  down    - Tear down all infrastructure"
    echo "  push    - Build and push Docker image to ECR"
    echo "  lambda  - Deploy updated Lambda function code"
    echo "  secrets - Apply Kubernetes secrets from .env file"
    ;;

esac