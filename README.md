# Platform Security GitHub Workflow

### Table of Contents
- [Getting Started](#getting-started)
- [Inputs (Optional Paramaters)](#inputs-optional-paramaters) | [Example](#inputs-example)
- [False Positives](#false-positives)
- [What about updates?](#what-about-updates)
- [Multiple Dockerfiles](#what-if-i-have-multiple-dockerfiles-that-i-want-to-scan)
- [Troubleshooting](#troubleshooting)
- [Jenkins](#jenkins)

---

This project aims to provide Red Hat ConsoleDot Teams with a way to scan the containers they create in a convenient, automated, and reliable manner within their GitHub repository. The `Platform Security Github Workflow` lets teams get security feedback as they open Pull Requests and fix any vulnerability before committing the code to a repository.

The `Platform Security Workflow` uses the free and open-source security tools Anchore's [Syft](https://github.com/anchore/syft/) and [Grype](https://github.com/anchore/grype/). 

* `Syft` generates a Software Bill of Materials (SBOM) from container images and filesystems.

* `Grype` conducts vulnerability scanning for container images and filesystems. Additionally, it uses [RedHat Linux Security Data](https://access.redhat.com/hydra/rest/securitydata/), making the scanning and reporting of vulnerabilities incredibly accurate regarding how we build our applications.


## Getting Started

Getting started with the `Platform Security Github Workflow` is as easy as copying the [security-workflow-template.yml](https://github.com/RedHatInsights/platform-security-gh-workflow/blob/master/security-workflow-template.yml) file from this repository and adding it to your GitHub repository's `.github/workflows` directory. Doing so will enable security scanning (via our reusable GitHub workflow) anytime a Pull-Request is opened or merged.

After the workflow has run, you can download artifacts of the results from the associated `workflow run`. The artifacts will contain the following files:

* grype-vuln-results-full.txt
* grype-vuln-results-fixable.txt
* syft-sbom-results.txt

Additionally, if the container image built and scanned contains any fixable vulnerabilities of `High` or `Critical` severity, the `Grype-Vulnerability-Scan` portion of the workflow will be flagged as a failure and let you know the reason. 

**Please Note:** You may have to enable the following in the `actions/general` settings:

**Private Repos**
* Fork pull request workflows
   * Run workflows from fork pull requests
   * Require approval for fork pull request workflows.

**Public Repos**
* Fork pull request workflows from outside collaborators
   * Require approval for first-time contributors.

## Inputs (Optional Paramaters)

If your `Dockerfile` is named in a standard fashion and is present in the `root` directory of your GitHub repo, then you can use the [security-workflow-template.yml](https://github.com/RedHatInsights/platform-security-gh-workflow/blob/master/security-workflow-template.yml) as it is. However, if your setup falls outside the defaults, you can use the following inputs to tailor the workflow to work for you. 

| Inputs      | Type | Description |
| ----------- | :-----------: | ----------- |
| `dockerbuild_path` | `String` | Path to your docker build within the GitHub repo. |
| `dockerfile_path` | `String` | Path to your Dockerfile within the GitHub repo. |
| `dockerfile_name` | `String`| Filename of your Dockerfile. |
| `base_image_build` | `Boolean` | Tells the workflow whether a preliminary Dockerfile should be built before the primary Dockerfile is built. |
| `base_dockerbuild_path` | `String` | Path to your docker build within the GitHub repo. |
| `base_dockerfile_path` | `String` | Path to your preliminary Dockerfile within the GitHub repo. |
| `base_dockerfile_name` | `String` | Filename of your preliminary Dockerfile. |
| `build_arg` | `String` | A Build Argument to be supplied at build-time. |
| `only_fixed` | `Boolean` | Set whether to output only vulnerabilities with fixes. |
| `fail_on_vulns` | `Boolean` | Set whether the job should fail if vulnerabilities are found. *(Based on severity_fail_cutoff)*|
| `severity_fail_cutoff` | `String` | Set the severity level at which the job should fail. *(negligible, low, medium, high or critical)* |

#### Inputs (Example)
```
jobs:
  PlatSec-Security-Workflow:
    uses: RedHatInsights/platform-security-gh-workflow/.github/workflows/platsec-security-scan-reusable-workflow.yml@master
    with:
      base_image_build: true
      base_dockerfile_path: './test'
      base_dockerfile_name: 'Dockerfile.base'
      build_arg: '--build-arg BASE_IMAGE="localbuild/baseimage:latest"'
      dockerfile_path: './test'
      dockerfile_name: 'Dockerfile.main'
```

## False Positives
If you encounter a False Positive, please reach out to the ConsoleDot Platform Security Team, and we can review and 
add the false positive to our tracker. Once a false positive is added to the tracker 
([grype-false-positives.yml](/false_positives/grype-false-positives.yml)), it will no longer show up in your scans.

*NOTE: `grype-false-positives.yml` - The false positive tracking file is used by both the GitHub and the Jenkins 
versions of the security workflow.*

## What about updates?
The `security-workflow-template.yml` file is pre-configured to use the reusable GitHub workflow in the `main/master` branch of this repository, so any updates to the scanners or functionality done by the Platform-Security Team will be automatically inherited. 

## What if I have multiple dockerfiles that I want to scan?
Super Easy! Just copy the `security-workflow-template.yml` file to your repository's `.github\workflows` directory and name it a different name and modify the custom settings at the bottom. There is no limit on how many a repo can have!

## Troubleshooting

**Unauthorized Error (During Docker Build):**
```
Unauthorized: Please login to the Red Hat Registry using your Customer Portal credentials.
Further instructions can be found here: https://access.redhat.com/RegistryAuthentication
```
**Solution:**
* The Dockerfile within the repo is likely pulling from a RH Registry that requires authentication. We recommend pulling from `registry.access.redhat.com`.

Please review the RH Registries below:


Registry | Content | Supports Unauthenticated Access | Supports Red Hat login | Supports Registry Tokens
-- | -- | -- | -- | --
registry.access.redhat.com | Red Hat products | Yes | No | No
registry.redhat.io | Red Hat products | No | Yes | Yes
registry.connect.redhat.com | Third-party products | No | Yes | Yes

REF: https://access.redhat.com/RegistryAuthentication

## Jenkins
In the event that an edge case prevents your repo from using the GitHub workflow, we have also created 
a Bash script that can be run on Jenkins and will provide the same level of support as the standard 
GitHub Workflow.

To use the Jenkins Job, all you need to do is add the [security-scan-source-template.sh](/jenkins/security-scan-source-template.sh) to your repo and add the (GitHub) `platsec-gh-vulnerability-scan` or 
(GitLab) `platsec-gl-vulnerability-scan` Jenkins Job to your app's build.yml in App-Interface.


- [GitHub - "platsec-gh-vulnerability-scan" | Example](https://gitlab.cee.redhat.com/service/app-interface/-/blob/master/data/services/insights/gateway/build.yml?ref_type=heads#L92-95)
- [GitLab - "platsec-gl-vulnerability-scan" | Example]()

#### Updates
Similar to the standard GitHub Workflow, we can accommodate feature requests and provide updates on the fly and 
with full transparency. The `security-scan-source-template.sh` script, which sources the main 
[security-scan.sh](/jenkins/security-scan.sh) script, allow us to support multiple teams without having to open 
up multiple PRs acroos multiple repos.
