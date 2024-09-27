### ConsoleDot Platform-Security
# Security Scanning - Managing False-Positives

### False-Positives
The false fositives list (`grype-false-positives.yml`) supports the `Insights-Tattler` Vulnerability Scanning tool and the `Pipeline Security Scanning Jobs` in GitHub and GitLab. The 
false positives list aids in ensuring the accurate detection of vulnerabilities within the ConsoleDot Platform.

All false positives within this list assume that the container image being scanned is built using Red Hat's UBI-8 or UBI-9 Base Images. If this false positive list is used against any 
images not using a UBI Base Image, results may be inaccurate and flag legitimate vulnerabilities as false positives.

Red Hat ConsoleDot Developers and Engineers can contact the Security team if they believe that their vulnerability scans contain false positives. The Security Team will investigate the 
potential false positives, and if it is determined to be a true false positive, they will be added to the list.
