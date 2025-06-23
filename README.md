## DevOps Internship Assignment - Full Stack Deployment on AWS

## 📘 Project Overview

This project demonstrates a complete DevOps pipeline and infrastructure for a containerized full-stack application. It features automated CI/CD, scalable infrastructure provisioning using Terraform, monitoring with CloudWatch, and secure, resilient deployment on AWS ECS with Fargate and ALB.

---
## 🚀 Tech Stack

<p align="left">
  <img src="https://img.shields.io/badge/Terraform-623CE4?style=for-the-badge&logo=terraform&logoColor=white" />
  <img src="https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white" />
  <img src="https://img.shields.io/badge/ECS-Fargate-orange?style=for-the-badge&logo=amazon-ecs&logoColor=white" />
  <img src="https://img.shields.io/badge/CloudWatch-FF9900?style=for-the-badge&logo=amazoncloudwatch&logoColor=white" />
  <img src="https://img.shields.io/badge/GitHub%20Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" />
  <img src="https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=next.js&logoColor=white" />
  <img src="https://img.shields.io/badge/Cypress-17202C?style=for-the-badge&logo=cypress&logoColor=white" />
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
</p>


## 🧱 Tech Stack

* **Frontend**: Next.js (React)
* **Backend**: FastAPI (Python)
* **Containerization**: Docker
* **CI/CD**: GitHub Actions
* **Infrastructure as Code**: Terraform
* **Cloud Provider**: AWS (ECS Fargate, ALB, CloudWatch, ECR, S3)

---

## 🔁 CI/CD Workflow

### `develop` Branch Workflow (dev.yaml)

Triggered on every push to `develop`:

* ✅ Code checkout
* ✅ Backend unit tests (pytest)
* ✅ Frontend build and Cypress tests
* ✅ Docker image builds for frontend and backend
* ✅ Images pushed to Amazon ECR with Git SHA tag


### `main` Branch Workflow (main.yaml)

Triggered on merge to `main`:

* ✅ Uses the latest pushed images (from ECR)
* ✅ Destroys any previous infra
* ✅ Applies infrastructure using Terraform with production-ready configuration

---

## ☁️ AWS Infrastructure (via Terraform)

* ✅ **VPC** with public subnets across 2 AZs
* ✅ **ECS Cluster** using Fargate
* ✅ **Application Load Balancer (ALB)** with path-based routing

  * `/` → Frontend (port 3000)
  * `/api/*` → Backend (port 8000)
* ✅ **CloudWatch Dashboards & Alarms** for ECS CPU and memory monitoring
* ✅ **ALB Access Logs** stored in S3
* ✅ **Security Groups** with scoped ingress & egress rules
* ✅ **IAM Roles** with least privilege for ECS task execution

---

## 🧪 Testing Strategy

* 🔍 **Backend**: `pytest` runs unit tests on FastAPI endpoints
* 🌐 **Frontend**: `Cypress` performs end-to-end UI testing after building

---

## 🔒 Security Considerations

* Principle of least privilege IAM roles
* Proper SG rules between ALB and ECS containers
* ALB access logging enabled to an S3 bucket
* Secrets management ready for integration (e.g., SSM, skipped to stay within Free Tier)

---

## 📊 Monitoring & Logging

* CloudWatch Log Groups: `/ecs/frontend`, `/ecs/backend`
* CloudWatch Dashboard with widgets for ECS CPU/Memory per service
* Alarms:

  * 🚨 CPU > 70%
  * 🚨 Memory > 75%

---

## 🔄 Load Balancing Demonstration

* Load tested by scaling ECS services to 2 tasks each
* ALB successfully routes and balances requests between tasks
* One task manually stopped to demonstrate failover and high availability

---

## 📦 Folder Structure

```
├── backend
│   ├── api.py
│   ├── tests/
├── frontend
│   ├── pages/
│   └── ...
├── terraform
│   ├── main.tf
│   ├── cloudwatch.tf
│   └── variables.tf
├── .github/workflows
│   ├── dev.yaml
│   └── main.yaml
```

---

## ✅ How to Deploy

```bash
# Clone the repo
$ git clone https://github.com/YASHMAHAKAL/devops-assignment.git

# Push to develop to test in dev environment
$ git checkout develop
$ git push

# Merge to main for full infrastructure provisioning
$ git checkout main
$ git merge develop
$ git push origin main
```

---

## 🙌 Author

**Yash Mahakal**


---

## 📄 License

This project is for educational purposes as part of a DevOps Internship Assignment.

---

## 📌 Final Notes

* Built with Free Tier limits in mind
* Easily extendable with SSM, autoscaling, Route53, or HTTPS
* Shows real-world DevOps practices in a controlled environment
