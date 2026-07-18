<#
Pull new commits from upstream into a separate branch, without touching
the main branch.
#>

$ErrorActionPreference = "Stop"

$RemoteName = "upstream"
$MainBranch = "master"
$BuildCommand = "meson compile -C build"

# 1. Working tree must be clean (ignoring this script itself, which may be untracked).
$status = git status --porcelain | Where-Object { $_ -notmatch [regex]::Escape($MyInvocation.MyCommand.Name) }
if ($LASTEXITCODE -ne 0) {
    Write-Error "git status failed."
    exit 1
}
if ($status) {
    Write-Error "Working tree is not clean. Commit or stash your changes first."
    exit 1
}

# 2. Branch name from today's date.
$branchName = "sync-upstream-$(Get-Date -Format 'yyyy-MM-dd')"

# 3. Branch must not already exist.
git rev-parse --verify --quiet $branchName | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Error "Branch '$branchName' already exists. Aborting to avoid overwriting it."
    exit 1
}

# 4. Fetch upstream.
git fetch $RemoteName
if ($LASTEXITCODE -ne 0) {
    Write-Error "git fetch $RemoteName failed."
    exit 1
}

# 5. Create and switch to the new branch off the main branch.
git checkout -b $branchName $MainBranch
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create branch '$branchName' from '$MainBranch'."
    exit 1
}

# 6. Merge upstream/main branch into the new branch.
git merge "$RemoteName/$MainBranch" --no-edit

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "MERGE CONFLICT on branch '$branchName'." -ForegroundColor Red
    Write-Host "Resolve the conflicts manually:"
    Write-Host "  1. Edit the conflicting files."
    Write-Host "  2. git add <resolved files>"
    Write-Host "  3. git commit"
    Write-Host ""
    Write-Host "The main branch ('$MainBranch') was NOT touched." -ForegroundColor Yellow
    exit 1
}

# 7. Success.
Write-Host ""
Write-Host "Merge succeeded on branch '$branchName'." -ForegroundColor Green
Write-Host "The main branch ('$MainBranch') was NOT touched."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Build/test locally:"
Write-Host "     $BuildCommand"
Write-Host "  2. Once verified, merge back into '$MainBranch':"
Write-Host "     git checkout $MainBranch; git merge $branchName"
