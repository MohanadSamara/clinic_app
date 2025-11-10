# Pushing the Clinic App Repository to GitHub

The development container does not have any Git remotes configured by default. To push the current branch to GitHub, follow these steps from your local machine:

1. Create a new repository on GitHub (or locate the existing remote URL).
   *If you are using MohanadSamara's public repository as requested, the URL is*
   `https://github.com/MohanadSamara/clinic_app`.
2. Add the remote to this project:
   ```bash
   git remote add origin https://github.com/MohanadSamara/clinic_app.git
   ```
3. Verify that the remote has been added:
   ```bash
   git remote -v
   ```
4. Push the current branch (named `work`) to GitHub:
   ```bash
   git push -u origin work
   ```

If GitHub requires authentication, supply a personal access token (PAT) when prompted. Ensure that the token has `repo` scope so the push can succeed.

### Example: pushing specifically to `github.com/MohanadSamara/clinic_app`

If you have permission to push to the repository shared with this project, you can skip the placeholder values above and run:

```bash
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/MohanadSamara/clinic_app.git
git push -u origin work
```

The `git remote remove` command is optional—it guarantees you can re-run these instructions even if a different remote already exists. Replace `work` with another branch name if you are working from a different branch locally.

## Commit and push workflow (when the remote is already connected)

Once a remote named `origin` exists, the quickest way to publish new work is:

```bash
# Review pending changes
git status

# Stage anything you want in the commit
git add <files>

# Create a commit message describing the change
git commit -m "<summary>"

# Push the updated branch to the previously configured remote
git push origin work
```

You can omit the branch name on subsequent pushes if you used `git push -u origin work` earlier—`git push` will automatically target the tracked remote branch.

### Convenience script included in this repository

For convenience, the repository now ships with `scripts/push_to_mohanad_repo.sh`. The script applies the remote URL above (or a URL you pass as the first argument) and then pushes the current branch—`work` by default—to that remote:

```bash
./scripts/push_to_mohanad_repo.sh                # uses the MohanadSamara URL and the work branch
./scripts/push_to_mohanad_repo.sh <url> <branch> # override either value
```

> **Note:** You must supply valid GitHub credentials (username + personal access token) when prompted; the script cannot bypass authentication.
