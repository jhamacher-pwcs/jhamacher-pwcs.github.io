---
layout: page
title: Scripts
permalink: /scripts/
---

A collection of PowerShell scripts I've created or used while working with Microsoft 365, Exchange Online, Active Directory, and other IT systems.

## Exchange Online

### [DL2MESG.ps1](./DL2MESG.ps1)

Migrates an Exchange Online Distribution List to a pre-created Mail-Enabled Security Group while preserving important mail attributes such as SMTP addresses and the old `LegacyExchangeDN` as an X500 address.

[Read about LegacyExchangeDN and X500]({% post_url 2026-10-14-exchange-legacydn-x500 %})

---

> **Note:** Review and test scripts before running them in a production environment.
