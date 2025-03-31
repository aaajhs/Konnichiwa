# Containerization

This document outlines the design choices behind the Dockerfile architecture and explains its usage.

## Architecture

### Common
#### Multi-Stage Build
The build stage and runtime stage are managed separately, which provides the following benefits:
- **Storage Efficiency & Security**: The build stage is discarded entirely after completion, removing all tools and dependencies required for building the application. This reduces both the final image size and the attack surface by excluding unnecessary components from the runtime environment.
- **Maintainability**: The separation of concerns makes it easier to manage changes, and the clear distinction reduces the risk of unintended changes breaking the entire build process.

#### Base Image
Both stages use the lightweight Debian-based Python image `python:3.13.2-slim-bookworm` to:
- Keep the image pull time short and the final image small in size.
- Ensure consistency across the different stages.
- Provide essential tools for building and running the application without requiring manual installation. This minimizes maintenance complexity and reduces number of layers in the Docker build, potentially improving build times by preserving layer reusability.

---

### Build Stage
#### Environment Variables:
Detailed explanations are included directly in the Dockerfile for clarity, as they are not as self-explanatory as the other commands.

#### Installation Steps Overview:
1. Install `pipx` and `poetry`.
2. Create a `README.md` file, as `poetry install` will fail without one. It will be kept deliberately empty to prevent Docker from re-building the layer every time there is a change.
3. Copy the necessary files for Poetry from the repo. The `src/` directory is intentionally copied last, as it is expected to be updated more frequently than the dependency files. This allows Docker to leverage layer caching more efficiently.
4. Install dependencies for the project with only the absolutely necessary dependencies, and without storing package caches.

---

### Runtime Stage
#### Environment Variables:
- **`PATH`:** The path `/root/app/.venv/bin` must be present within `$PATH` for `poetry` to execute.

#### Installation Steps Overview:
1. Copy the source code and necessary dependencies from the build stage.
2. Run the application. The `--reload` flag is intentionally omitted to ensure that the server behavior remains immutable, preventing unauthorized modifications in case of a security breach.

## Usage
### Building the Image
```
docker build -t konnichiwa .
```
The flag `--platform linux/amd64` may be necessary to build an image to run on the cloud infrastructure.

### Running the Image Locally
```
docker run -d --rm -p 4000:4000 -e API_KEY=<THE_API_KEY> --name konnichiwa konnichiwa
```

### Accessing the API
```
curl -v http://localhost:4000/

curl -v http://localhost:4000/health

curl -H "Authorization: Bearer <THE_API_KEY>" http://127.0.0.1:4000/inspect
```
