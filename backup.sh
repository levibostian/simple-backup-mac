#!/bin/bash

# =============================================================================
# Git Backup Script for Unattended Operation via LaunchD
# =============================================================================

set -e  # Exit on any error

# =============================================================================
# Configuration
# =============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Generate unique log file with directory name and timestamp
DIR_NAME="$(basename "$SCRIPT_DIR")"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RANDOM_ID="$(openssl rand -hex 4)"
LOG_FILE="/tmp/backup_${DIR_NAME}_${TIMESTAMP}_${RANDOM_ID}.log"

# =============================================================================
# Logging Functions
# =============================================================================

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
}

log_error() {
    log "ERROR" "$@"
}

log_warn() {
    log "WARN" "$@"
}

log_debug() {
    log "DEBUG" "$@"
}

# =============================================================================
# Cleanup and Error Handling
# =============================================================================

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Script failed with exit code $exit_code"
    else
        log_info "Script completed successfully"
    fi
    log_info "Log file location: $LOG_FILE"
    exit $exit_code
}

trap cleanup EXIT

# =============================================================================
# Git Operations
# =============================================================================

check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not a git repository: $SCRIPT_DIR"
        exit 1
    fi
    log_info "Confirmed git repository at: $SCRIPT_DIR"
}

check_remote() {
    if ! git remote get-url origin > /dev/null 2>&1; then
        log_error "No remote 'origin' found"
        exit 1
    fi
    local remote_url=$(git remote get-url origin)
    log_info "Remote origin URL: $remote_url"
}

fetch_latest() {
    log_info "Fetching latest changes from remote..."
    if ! git fetch origin; then
        log_error "Failed to fetch from remote"
        exit 1
    fi
    log_info "Fetch completed successfully"
}

check_for_changes() {
    # Check if there are any unstaged changes
    if git diff --quiet && git diff --cached --quiet; then
        log_info "No changes detected in repository"
        return 1
    fi
    log_info "Changes detected in repository"
    return 0
}

stage_changes() {
    log_info "Staging all changes..."
    if ! git add -A; then
        log_error "Failed to stage changes"
        exit 1
    fi
    
    # Double-check that we have staged changes
    if git diff --cached --quiet; then
        log_info "No changes to commit after staging"
        return 1
    fi
    
    log_info "Successfully staged changes"
    return 0
}

create_commit() {
    local commit_message="Backup: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "Creating commit with message: $commit_message"
    
    if ! git commit -m "$commit_message"; then
        log_error "Failed to create commit"
        exit 1
    fi
    
    local commit_hash=$(git rev-parse HEAD)
    log_info "Commit created successfully: $commit_hash"
}

sync_with_remote() {
    local current_branch=$(git branch --show-current)
    log_info "Current branch: $current_branch"
    
    # Check if remote branch exists
    if git show-ref --verify --quiet "refs/remotes/origin/$current_branch"; then
        log_info "Remote branch exists, checking for conflicts..."
        
        # Check if we're behind the remote
        local local_commit=$(git rev-parse HEAD)
        local remote_commit=$(git rev-parse "origin/$current_branch")
        
        if [ "$local_commit" != "$remote_commit" ]; then
            log_info "Local and remote branches have diverged, attempting merge..."
            
            # Try to merge remote changes
            if ! git merge "origin/$current_branch" --no-edit; then
                log_error "Merge failed, attempting to resolve..."
                
                # Check if it's a merge conflict
                if git status --porcelain | grep -q "^UU\|^AA\|^DD"; then
                    log_warn "Merge conflicts detected, resolving automatically..."
                    
                    # For backup purposes, we'll favor our local changes
                    git checkout --ours .
                    git add -A
                    
                    if ! git commit --no-edit; then
                        log_error "Failed to resolve merge conflicts"
                        exit 1
                    fi
                    
                    log_info "Merge conflicts resolved automatically"
                else
                    log_error "Merge failed for unknown reason"
                    exit 1
                fi
            else
                log_info "Merge completed successfully"
            fi
        else
            log_info "Local and remote are in sync"
        fi
    else
        log_info "Remote branch does not exist, will be created on push"
    fi
}

push_changes() {
    local current_branch=$(git branch --show-current)
    log_info "Pushing changes to remote branch: $current_branch"
    
    # Push with upstream setting in case branch doesn't exist remotely
    if ! git push -u origin "$current_branch"; then
        log_error "Failed to push changes"
        exit 1
    fi
    
    log_info "Successfully pushed changes to remote"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    log_info "=== Git Backup Script Started ==="
    log_info "Script directory: $SCRIPT_DIR"
    log_info "Script name: $SCRIPT_NAME"
    log_info "Log file: $LOG_FILE"
    log_info "Current working directory: $(pwd)"
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    log_info "Changed working directory to: $SCRIPT_DIR"
    
    # Verify this is a git repository
    check_git_repo
    
    # Verify remote exists
    check_remote
    
    # Fetch latest changes from remote
    fetch_latest
    
    # Check for local changes
    if ! check_for_changes; then
        log_info "No changes to backup, exiting early"
        exit 0
    fi
    
    # Stage all changes
    if ! stage_changes; then
        log_info "No changes to commit after staging, exiting early"
        exit 0
    fi
    
    # Create commit
    create_commit
    
    # Sync with remote (handle merges)
    sync_with_remote
    
    # Push changes
    push_changes
    
    log_info "=== Git Backup Script Completed Successfully ==="
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Ensure we're running in the correct directory context
if [ -z "$SCRIPT_DIR" ]; then
    echo "ERROR: Unable to determine script directory" >&2
    exit 1
fi

# Create log file and start logging
touch "$LOG_FILE"
if [ ! -w "$LOG_FILE" ]; then
    echo "ERROR: Unable to write to log file: $LOG_FILE" >&2
    exit 1
fi

# Run main function
main "$@"
