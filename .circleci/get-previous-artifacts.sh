#!/bin/bash

# Script to download artifacts from the previous CircleCI pipeline run
# Usage: .circleci/get-previous-artifacts.sh [artifact-path] [output-dir]
#
# Example: .circleci/get-previous-artifacts.sh allure-report/history ./previous-artifacts

set -e

ARTIFACT_PATH="${1:-allure-report/history}"
OUTPUT_DIR="${2:-previous-artifacts}"

# CircleCI API configuration
CIRCLE_API_URL="https://circleci.com/api/v2"
PROJECT_SLUG="github/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
BRANCH="${CIRCLE_BRANCH:-main}"

# Check if API token is set
if [ -z "$CIRCLECI_TOKEN" ]; then
  echo "ERROR: CIRCLECI_TOKEN environment variable is not set"
  echo "Set it in CircleCI project settings or as a context variable"
  exit 1
fi

echo "Fetching previous pipeline artifacts..."
echo "Project: $PROJECT_SLUG"
echo "Branch: $BRANCH"
echo "Artifact path: $ARTIFACT_PATH"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Get list of pipelines for this branch
echo "Fetching pipelines for branch: $BRANCH"
PIPELINES_RESPONSE=$(curl -s -u "${CIRCLECI_TOKEN}:" \
  "${CIRCLE_API_URL}/project/${PROJECT_SLUG}/pipeline?branch=${BRANCH}")
echo "$PIPELINES_RESPONSE"

# Get the current pipeline number from API (most recent pipeline is the first in the list)
CURRENT_PIPELINE_NUMBER=$(echo "$PIPELINES_RESPONSE" | jq -r ".items[0].number")
CURRENT_PIPELINE_ID=$(echo "$PIPELINES_RESPONSE" | jq -r ".items[0].id")

if [ -z "$CURRENT_PIPELINE_NUMBER" ] || [ "$CURRENT_PIPELINE_NUMBER" = "null" ]; then
  echo "ERROR: Could not determine current pipeline number from API"
  exit 1
fi

echo "Current pipeline number: $CURRENT_PIPELINE_NUMBER"
echo "Current pipeline ID: $CURRENT_PIPELINE_ID"
echo ""

# Get previous pipeline (one before current)
PREVIOUS_PIPELINE_NUMBER=$((CURRENT_PIPELINE_NUMBER - 1))
echo "Looking for previous pipeline number: $PREVIOUS_PIPELINE_NUMBER"

# Find the previous pipeline
PREVIOUS_PIPELINE_ID=$(echo "$PIPELINES_RESPONSE" | \
  jq -r ".items[] | select(.number == ${PREVIOUS_PIPELINE_NUMBER}) | .id" | head -1)

if [ -z "$PREVIOUS_PIPELINE_ID" ] || [ "$PREVIOUS_PIPELINE_ID" = "null" ]; then
  echo "WARNING: Previous pipeline #${PREVIOUS_PIPELINE_NUMBER} not found"
  echo "Trying to find the most recent completed pipeline before current..."
  
  # Find the most recent pipeline before current
  PREVIOUS_PIPELINE_ID=$(echo "$PIPELINES_RESPONSE" | \
    jq -r ".items[] | select(.number < ${CURRENT_PIPELINE_NUMBER}) | .id" | head -1)
  
  if [ -z "$PREVIOUS_PIPELINE_ID" ] || [ "$PREVIOUS_PIPELINE_ID" = "null" ]; then
    echo "ERROR: No previous pipeline found"
    exit 1
  fi
  
  PREVIOUS_PIPELINE_NUMBER=$(echo "$PIPELINES_RESPONSE" | \
    jq -r ".items[] | select(.id == \"${PREVIOUS_PIPELINE_ID}\") | .number")
  echo "Found pipeline #${PREVIOUS_PIPELINE_NUMBER}"
fi

echo "Previous pipeline ID: $PREVIOUS_PIPELINE_ID"
echo ""

# Get workflows for the previous pipeline
echo "Fetching workflows for previous pipeline..."
WORKFLOWS_RESPONSE=$(curl -s -u "${CIRCLECI_TOKEN}:" \
  "${CIRCLE_API_URL}/pipeline/${PREVIOUS_PIPELINE_ID}/workflow")

# Get the first workflow ID (usually there's one main workflow)
WORKFLOW_ID=$(echo "$WORKFLOWS_RESPONSE" | jq -r ".items[0].id")

if [ -z "$WORKFLOW_ID" ] || [ "$WORKFLOW_ID" = "null" ]; then
  echo "ERROR: No workflow found for previous pipeline"
  exit 1
fi

echo "Workflow ID: $WORKFLOW_ID"
echo ""

# Get jobs for the workflow
echo "Fetching jobs for workflow..."
JOBS_RESPONSE=$(curl -s -u "${CIRCLECI_TOKEN}:" \
  "${CIRCLE_API_URL}/workflow/${WORKFLOW_ID}/job")

# Get all job numbers
JOB_NUMBERS=$(echo "$JOBS_RESPONSE" | jq -r ".items[].job_number")

if [ -z "$JOB_NUMBERS" ]; then
  echo "ERROR: No jobs found in previous workflow"
  exit 1
fi

echo "Found jobs in previous workflow:"
echo "$JOB_NUMBERS"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Download artifacts from each job
ARTIFACTS_FOUND=0
for JOB_NUMBER in $JOB_NUMBERS; do
  echo "Checking artifacts for job #${JOB_NUMBER}..."
  
  # Get artifacts for this job
  ARTIFACTS_RESPONSE=$(curl -s -u "${CIRCLECI_TOKEN}:" \
    "${CIRCLE_API_URL}/project/${PROJECT_SLUG}/${JOB_NUMBER}/artifacts")
  
  # Find artifacts matching the path
  ARTIFACT_URLS=$(echo "$ARTIFACTS_RESPONSE" | \
    jq -r ".items[] | select(.path | startswith(\"${ARTIFACT_PATH}\")) | .url")
  
  if [ -n "$ARTIFACT_URLS" ]; then
    echo "Found artifacts matching '${ARTIFACT_PATH}' in job #${JOB_NUMBER}"
    
    for ARTIFACT_URL in $ARTIFACT_URLS; do
      ARTIFACT_PATH_RELATIVE=$(echo "$ARTIFACTS_RESPONSE" | \
        jq -r ".items[] | select(.url == \"${ARTIFACT_URL}\") | .path")
      
      # Create directory structure preserving the artifact path
      OUTPUT_PATH="${OUTPUT_DIR}/${ARTIFACT_PATH_RELATIVE}"
      OUTPUT_DIR_PATH=$(dirname "$OUTPUT_PATH")
      mkdir -p "$OUTPUT_DIR_PATH"
      
      echo "Downloading: $ARTIFACT_PATH_RELATIVE"
      echo "  URL: $ARTIFACT_URL"
      echo "  To: $OUTPUT_PATH"
      
      # Download the artifact
      curl -s -u "${CIRCLECI_TOKEN}:" -o "$OUTPUT_PATH" "$ARTIFACT_URL"
      
      if [ -f "$OUTPUT_PATH" ]; then
        echo "  ✓ Downloaded successfully ($(du -h "$OUTPUT_PATH" | cut -f1))"
        ARTIFACTS_FOUND=$((ARTIFACTS_FOUND + 1))
      else
        echo "  ✗ Download failed"
      fi
      echo ""
    done
  fi
done

if [ $ARTIFACTS_FOUND -eq 0 ]; then
  echo "WARNING: No artifacts found matching path '${ARTIFACT_PATH}'"
  echo "Available artifact paths from previous pipeline:"
  for JOB_NUMBER in $JOB_NUMBERS; do
    ARTIFACTS_RESPONSE=$(curl -s -u "${CIRCLECI_TOKEN}:" \
      "${CIRCLE_API_URL}/project/${PROJECT_SLUG}/${JOB_NUMBER}/artifacts")
    echo "$ARTIFACTS_RESPONSE" | jq -r ".items[].path" | head -10
  done
  exit 1
else
  echo "Successfully downloaded $ARTIFACTS_FOUND artifact(s) to ${OUTPUT_DIR}/"
  echo ""
  echo "Downloaded artifacts:"
  find "$OUTPUT_DIR" -type f | head -20
fi

