# Stale Guest User Cleanup Script

A PowerShell script that identifies and removes stale guest users from Microsoft Entra ID using the Microsoft Graph API.

## Problem

Organisations often invite external users (guests) to collaborate in Microsoft 365. Over time, these accounts become inactive but remain in the directory — creating unnecessary security risk and cluttering identity management.

## What This Script Does

- Connects to your Entra ID tenant using app-only authentication
- Queries all guest users in the tenant
- Checks last sign-in activity from audit logs
- Flags users inactive beyond a configurable threshold (default: 90 days)
- Exports a CSV report of stale users
- Optionally deletes stale accounts (controlled by a dry run flag)

## Prerequisites

- PowerShell 7.0 or higher
- Microsoft Graph PowerShell module (`Install-Module Microsoft.Graph`)
- An Entra ID app registration with the following permissions:
  - `User.Read.All`
  - `User.ReadWrite.All`
  - `AuditLog.Read.All`

## Configuration

Open the script and update the following variables:
```powershell
$tenantId      = "YOUR_TENANT_ID"
$clientId      = "YOUR_CLIENT_ID"
$clientSecret  = "YOUR_CLIENT_SECRET"
$thresholdDays = 90
$dryRun        = $true
$exportPath    = "/path/to/StaleGuestUsers.csv"
```

## Usage

Run in dry run mode first to review stale users before deleting:
```powershell
./GuestCleanup.ps1
```

To enable deletion, set `$dryRun = $false` in the script.

## Output

The script exports a CSV report with the following columns:

| Column | Description |
|--------|-------------|
| DisplayName | Guest user's display name |
| Email | Guest user's email address |
| LastSignIn | Date of last sign-in or "Never" |
| DaysInactive | Number of days since last sign-in |

## Author

Tom | https://helpdesq.tech | www.linkedin.com/in/tmugema