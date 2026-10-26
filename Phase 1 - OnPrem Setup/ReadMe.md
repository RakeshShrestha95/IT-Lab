IT Support Lab - Phase 1: On-Prem 
==============================================
Simulated small business IT environment, built from scratch to practice real
sysadmin/support work

Domain: inprogress.local
DC: DC01 (Windows Server 2019 Standard, 192.168.1.110)
Client: PC-1 (Windows 11)
OU structure: InProgress > Staff (Sales, Finance, Marketing, IT, Management)
                         > Workstations (Desktops, Laptops)
                         > Groups 
				> Distribution
				> Security
					> SG-Finance-RW

------------------------------------------------------------
TASK 1: Domain join
------------------------------------------------------------
Joined PC-1 to inprogress.local, logged in as sarah.chen (one of my test
users) to prove it actually worked end to end, not just the join dialog
succeeding. Checked ipconfig /all to confirm it pulled an IP from my DHCP
scope and pointed at DC01 for DNS.

Screenshots in Phase 1/Screenshots:
1. [Task 1 -Join Windows 11 VM to the Domain.png]


------------------------------------------------------------
TASK 2: GPO - Staff-PasswordPolicy
------------------------------------------------------------
Created a password policy GPO and linked it to Staff. Spent a genuinely
long time troubleshooting this because gpresult /r kept showing N/A for
Applied Group Policy Objects no matter what I checked - OU placement,
link status, security filtering, WMI filters, Block Inheritance, all of it
looked fine.

Turned out the actual problem was nothing to do with the GPO at all:
I had ran gpresult /r run on a non-admin user (sarah.chen, not elevated) silently
hides the entire Computer Settings section instead of throwing an error.
Since Password Policy is a Computer Configuration setting, it was never
going to show up for a non-admin user no matter what I fixed. Logged in
directly as a domain admin and ran gpresult /r again - there it was,
Staff-PasswordPolicy and my Test-GPO both listed under Applied GPOs.

Lesson: when a config looks "obviously" fine but nothing's working, check
the diagnostic tool itself before re-checking the config for the fifth
time.

Screenshots in Phase 1/Screenshots:
1. [Task 2- Verify the GPO applies on the domain-joined client.png]

------------------------------------------------------------
TASK 3: Finance file share
------------------------------------------------------------
Created C:\Shares\Finance, made a security group SG-Finance-ReadWrite with
james.oconnor as the only member, shared the folder as \\DC01\Finance,
and set NTFS Modify permission for the group.

First test failed - sarah.chen (not in the group) could still get in.
Cause: the new folder inherited broad permissions (Authenticated Users/
Users with Read) from its parent folder, and adding my group on top
doesn't remove what's already inherited. Had to disable inheritance,
convert to explicit permissions, and manually strip out the inherited
entries, keeping only SYSTEM, Administrators, and my security group.

Also tried to use Access-Based Enumeration to hide the subfolders inside Finance 
itself from James when browsing \\DC01\Finance so Restructured to actually test ABE properly:
made two subfolders inside Finance (Payroll, locked down; Reports, open
to the group) and confirmed james only sees Reports when Payroll is
restricted. That's the real use case for ABE.

Final test: james.oconnor - full access, can create/edit files.
sarah.chen - access denied.

Screenshots in Phase 1/Screenshots:
1. [Task 3- File share with NTFS permissions -1.png]
2. [Task 3- File share with NTFS permissions -2.png]

------------------------------------------------------------
TASK 4: Print server - OfficePrinter
------------------------------------------------------------
Installed the Print and Document Services role (Print Server only).

Added Virtual Printer from Print Management's
Add Printer wizard, which is the more correct tool on a server.

Picked the FILE: port first, which turned out to make the printer
un-shareable - Windows greys out the Share option for printers on a FILE:
port since there's no sensible remote target. Recreated it using a Local
Port (NUL:, a null/discard port) with the Generic / Text Only driver,
which is the standard way to fake a shareable printer without real
hardware.

Shared it as \\DC01\OfficePrinter and restricted print permissions to
SG-Finance-ReadWrite only, same group as the file share.

Test results: james.oconnor connects and prints cleanly, gets the "test
page sent" success message. sarah.chen gets hit with a credential prompt
when trying to connect and is denied after re-entering her own
credentials - confirms the permission restriction works.

Also tested the spooler recovery scenario - paused the
spooler, sent a job so it got stuck, restarted the spooler, confirmed the
queue cleared.

Screenshots in Phase 1/Screenshots:
1. [Task 4- Print Server -access denied for unauthorized user.png]
2. [Task 4- Print Server- Print successful.png]
