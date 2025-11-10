# Downloading the Clinic App Repository from GitHub

If you only need a local copy of the repository and do not plan to push changes, you can download the project as a ZIP archive di
rectly from GitHub. This repository includes a helper script to streamline the process.

## Quick download using the bundled script

Run the script from the repository root:

```bash
./scripts/download_repo_archive.sh
```

By default, the script downloads the `main` branch of `https://github.com/MohanadSamara/clinic_app` into `clinic_app-main.zip` in
your current directory. You can override the repository URL, branch, and output filename:

```bash
./scripts/download_repo_archive.sh https://github.com/your-org/your-repo develop my-project.zip
```

The script uses `curl`, so make sure it is installed on your system. After the download completes, unzip the archive with your pr
eferred tool:

```bash
unzip clinic_app-main.zip
```

## Manual alternative (without the script)

You can also download the archive directly with `curl` or `wget`:

```bash
curl -L https://github.com/MohanadSamara/clinic_app/archive/refs/heads/main.zip -o clinic_app-main.zip
```

Or visit the repository in your browser and use the **Code → Download ZIP** button.
