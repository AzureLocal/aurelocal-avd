# Defender and Security Hardening

This guide defines baseline security controls for AVD control-plane and Azure Local session-host operations.

## 1) Defender for Cloud baseline

Enable and review:
- Defender plans required by the deployed resource mix.
- Secure Score recommendations for subscription/resource groups hosting AVD resources.
- Regulatory compliance mapping used by your organization.

Operational cadence:
- Daily triage of high-severity recommendations.
- Weekly review of unresolved medium-severity findings.

## 2) Session-host endpoint protection

Required controls:
- Defender for Endpoint onboarding for all session hosts.
- Tamper protection and cloud-delivered protection enabled.
- ASR (Attack Surface Reduction) rules tested in audit mode, then enforced.

FSLogix-aware considerations:
- Validate any process/path exclusions with security owners before rollout.
- Revalidate exclusions quarterly.

## 3) Identity and access hardening
- Require MFA and conditional access for privileged roles.
- Use PIM/JIT for elevated access.
- Assign least-privilege roles at resource-group or resource scope.

## 4) Policy recommendations
- Enforce diagnostics to Log Analytics for AVD resources.
- Require approved locations and tag policy.
- Block legacy auth where applicable.
- Audit public network exposure for related services.

## 5) Alerting and incident response

Alert classes:
- Suspicious sign-in and impossible travel.
- Malware/ransomware signals on session hosts.
- Repeated profile mount failures with security correlations.

Response runbook minimum:
1. Isolate impacted host.
2. Collect forensic artifacts.
3. Reimage host from trusted image.
4. Validate profile/container integrity.
5. Rotate credentials/tokens if needed.

## 6) Validation checklist
- Defender onboarding complete for 100% of session hosts.
- All critical recommendations triaged.
- Security alerts integrated into SOC workflow.
- Quarterly tabletop exercise completed for AVD incident scenario.

## References
- Defender for Cloud: https://learn.microsoft.com/azure/defender-for-cloud/
- Defender for Endpoint: https://learn.microsoft.com/microsoft-365/security/defender-endpoint/
