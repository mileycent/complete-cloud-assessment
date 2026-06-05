# Project Bedrock — Production-Grade Microservices on AWS EKS
**Company:** InnovateMart Inc.  
**Project Classification:** Karatu 2025 Capstone Evaluation  

This repository contains the complete automated infrastructure-as-code (IaC) configuration, serverless event pipelines, and container deployment manifests required to establish a secure, observed, and highly resilient Kubernetes foundation for the InnovateMart Retail Store Application.

---

## 🏗️ Core Infrastructure Architecture

The system decouples stateful dependencies from the volatile compute cluster, leveraging native AWS managed services for critical enterprise tiers:
- **Networking:** Custom-built VPC (`project-bedrock-vpc`) spread over 2 Availability Zones in `us-east-1` featuring distinct Public, Private, and isolated Database subnets.
- **Compute:** Managed AWS EKS Cluster (`project-bedrock-cluster`) tracking Kubernetes version `v1.34.0+`.
- **Data Tier:** Decoupled architecture migrating out-of-cluster storage engines to Amazon RDS MySQL, Amazon RDS PostgreSQL, and Amazon DynamoDB.
- **Serverless Extension:** Asynchronous asset processing engine using an Amazon S3 event-driven architecture to invoke an AWS Lambda function (`bedrock-asset-processor`).
- **Security & RBAC:** Enforces strict least-privilege boundary rules. Connects the developer identity `bedrock-dev-view` to the native Kubernetes `view` ClusterRole via native EKS Access Entries.

---

## 🚀 Deployment Guide (How to Trigger the Pipeline)

This project features a fully automated GitOps deployment engine driven by GitHub Actions using secure OpenID Connect (OIDC) authentication. 

### Prerequisites & Step-by-Step Execution:
1. **AWS Console Configuration:** Ensure the AWS IAM OIDC Identity Provider for GitHub Actions is configured in your AWS management console. Create an IAM Role targeting your repository (`InnovateMartInc/Project-Bedrock`) with administrative capabilities.
2. **GitHub Repository Setup:** Store your target IAM execution Role ARN as a secure repository secret named `AWS_ROLE_ARN`.
3. **Triggering a Dry-Run (Terraform Plan):**
   - Create a feature branch and push changes to GitHub.
   - Open a **Pull Request (PR)** targeting the `main` branch.
   - The automation pipeline will instantly execute a code quality check and output a live `terraform plan` execution simulation directly into your PR comment logs.
4. **Triggering Deployment (Terraform Apply):**
   - Review the generated structural simulation.
   - **Merge the Pull Request** directly into the `main` branch.
   - The production pipeline will instantly trigger, executing `terraform apply` to provision all AWS resources, extract output parameters, and automatically commit the required metadata `grading.json` file back into the root of the repository.

---

## 🌐 Live Application Access

Once the pipeline successfully finishes processing the deployment phase, the application is publicly reachable via HTTPS.

- **Production Retail Store URL:** `https://retail.nip.io` *(Or your custom mapped active domain target)*
- **TLS Termination:** Managed via AWS Certificate Manager (ACM) with mandatory automated HTTP-to-HTTPS upgrade patterns enforced at the load balancer boundary layer.

---

## 📋 Grading Credentials & Audits

### Developer Access Reference
The following configurations have been provisioned to satisfy read-only access verification rules without exposing administrative credentials to external environments:
- **IAM User Identity:** `bedrock-dev-view`
- **AWS Console Security Policy:** Attached `ReadOnlyAccess` managed strategy wrapper.
- **Kubernetes Context Authority:** Bound directly to the internal cluster `view` RBAC ClusterRole.

### Automated Evaluation Assets
The compliance schema metadata required by automated evaluation grading harnesses is located at the root of the repository:
- **Grading File:** `./grading.json` *(Generated automatically during main branch pipeline evaluation steps)*