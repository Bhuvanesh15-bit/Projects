https://roadmap.sh/projects/github-actions-deployment-workflow

# GitHub Pages Deployment Workflow

This project demonstrates continuous deployment with GitHub Actions and GitHub Pages. A push to the `main` branch that changes `index.html` starts the workflow and publishes the site.

## Setup

1. Create a GitHub repository named `gh-deployment-workflow`.
2. Push this project to the repository's `main` branch.
3. In the repository settings, open **Pages** and set the source to **GitHub Actions** if GitHub has not enabled it automatically.
4. After a successful workflow run, visit

'https://github.com/Bhuvanesh15-bit/Projects/edit/main/gh-deployment-workflow'

Changes to files other than `index.html` do not trigger the deployment workflow.
