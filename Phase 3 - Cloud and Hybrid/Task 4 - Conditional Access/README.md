\# Phase 3, Task 4: Conditional Access (Report-only)



\*\*Goal:\*\* control \*who can sign in, to what, and from what kind of device\*, and tie the Intune compliance policy from the previous task into access. 

All three policies were built in \*\*Report-only\*\* mode so I could see their effect without risking a lockout.



\*\*Environment:\*\* Microsoft 365 E3 trial tenant, PC-1 (hybrid joined, Intune enrolled, compliant), synced test users.



\## Before building any policy



1\. \*\*Test Global account:\*\* created a cloud-only Global Administrator, `testglobal`, with a long random password stored offline. No licence, not in the sync scope. 

It is excluded from every policy, so a bad policy can't lock me out of the tenant.



2\. \*\*Security Defaults:\*\* turned off. Conditional Access can't be used while Security Defaults is on, and the two are alternatives, not additions.



!\[Test Global account](screenshots/01-breakglass-account.png)

!\[Security Defaults disabled](screenshots/02-security-defaults-disabled.png)



\## The three policies



| Policy | Applies to | Target | Control |

|---|---|---|---|

| `CA01-Require-MFA-Admins` | Global Administrator, Intune Administrator, Security Administrator roles | All resources | Require MFA |

| `CA02-Require-Compliant-Device-M365` | All users, Windows only | Office 365 | Require device marked compliant |

| `CA03-Block-Legacy-Auth` | All users | All resources, client apps: Exchange ActiveSync and Other clients | Block access |



`testglobal` is excluded from all three. All three are set to \*\*Report-only\*\*.



\*\*Why these three:\*\*

\- \*\*CA01:\*\* an admin account without MFA puts the entire tenant at risk, so admins get the strictest rule first.

\- \*\*CA02:\*\* this is what makes the Intune compliance policy matter. Compliance on its own is a report. With CA02, a device that fails the baseline can't reach company email.

\- \*\*CA03:\*\* legacy protocols (IMAP, POP, basic-auth ActiveSync) can't do MFA or device checks, so attackers use them to bypass every other policy.



!\[Policies in Report-only](screenshots/03-ca-policies-report-only.png)

!\[CA01 summary](screenshots/03a-ca-policies-report-only.png)

!\[CA02 summary](screenshots/03b-ca-policies-report-only.png)

!\[CA03 summary](screenshots/03c-ca-policies-report-only.png)





\## Testing



I signed in to Outlook on the web as `james.oconnor` on PC-1 in two ways and read the result from \*\*Sign-in logs > the sign-in > Conditional Access tab\*\*.



| Policy | Edge normal profile | Edge InPrivate |

|---|---|---|

| CA01 | Not applied | Not applied |

| CA02 | \*\*Success\*\* | \*\*Failure\*\* |

| CA03 | Not applied | Not applied |



\- CA01 didn't apply because James isn't in an admin role.

\- CA03 didn't apply because a browser uses modern authentication, not a legacy protocol.

\- CA02 differs between the two sign-ins on the \*same PC\*. A normal Edge profile passes the device identity, so Entra sees a compliant device. 

InPrivate doesn't pass it, so Entra can't prove compliance. In production, that would block the user.



!\[CA02 failure, InPrivate](screenshots/04-ca-reportonly-unmanaged.png)

!\[CA02 success, normal mode](screenshots/05-ca-reportonly-result.png)











