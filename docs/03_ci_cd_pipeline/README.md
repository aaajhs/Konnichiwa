# CI/CD Pipeline

This document outlines the design choices behind the GitHub Actions workflow architecture.

## GitHub Actions Secrets
The following secrets must be provided in the repository's settings page > Secrets and variables > Actions > Repository secrets.
- **`API_KEY`:** The API Key to be used by the test container. An arbitrary value may be used, as it is only needed for testing and does not impact the final deployment.
- **`AWS_ACCESS_KEY_ID`:** The AWS access key ID to use with the AWS workflows in the deploy job.
- **`AWS_SECRET_ACCESS_KEY`:** The AWS secret access key to use with the AWS workflows in the deploy job.

## Architecture

### Build Job
#### Steps Overview:
1. Build the Docker image and tag it with a shorthand (7 characters long) of the Git commit hash that triggered the workflow run.
2. Save the image as a .tar file.
3. Upload the image as a .tar file as an artifact, available for use by successive jobs.

---

### Test Job
This job will only run only if the build job is successful.

#### Steps Overview:
1. Download the image as a .tar file and load the image.
2. Run the docker container to test for functionality.
3. If the container starts successfully, test each exposed endpoint. If any test fails, exit immediately.
4. If the running of the container or the test fails, print the container logs for debugging.
5. Stop and delete the container.

---

### Deploy Job
This job will only run only if the test job is successful.

#### Steps Overview:
1. Download the image as a .tar file and load the image.
2. Save the image tag to step output for later use.
3. Login to ECR, re-tag the image for upload to ECR and push.
4. Create a new revision of the ECS task definition to use the newly pushed image.
5. Deploy the ECS service using the new task definition.
