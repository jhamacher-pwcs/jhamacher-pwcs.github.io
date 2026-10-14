---
layout: home
title: Technical Notes
---

Welcome to my technical notes.

This site is a collection of things I've learned while working with Microsoft 365, Exchange Online, PowerShell, Active Directory, networking, and other IT systems.

The goal is simple: document the problems I run into, explain what I discovered, and record the solutions that actually worked.

A lot of IT knowledge comes from troubleshooting something that *should* have been simple and discovering there's much more happening behind the scenes. Rather than lose that knowledge after solving the problem, I'm documenting it here.

## Exchange Online

### [Replacing an Exchange Online Distribution List Without Breaking Old Outlook Recipients](./posts/exchange-legacydn-x500.md)

What started as a simple Distribution List to Mail-Enabled Security Group migration turned into a deeper look at how Exchange identifies recipients.

Topics covered:

- LegacyExchangeDN
- X500 proxy addresses
- SMTP proxy addresses
- Outlook autocomplete
- IMCEAEX addresses and NDRs
- Distribution Lists
- Mail-Enabled Security Groups
- Exchange Online PowerShell
- Safely replacing Exchange recipients

One of the biggest lessons:

> An Exchange recipient is more than its SMTP address.

Giving a replacement object the same email address doesn't necessarily give it the same Exchange identity.

---

## PowerShell

I'll also use this site to document PowerShell scripts and techniques that I've found useful for systems administration.

Topics will include:

- Exchange Online PowerShell
- Microsoft 365 administration
- Active Directory
- Microsoft Graph
- Bulk administration
- Reporting
- Migration scripts
- Troubleshooting scripts
- Script safety and validation

---

## Why I'm Writing This

Technical documentation often tells you **what command to run**, but not always **why it works**.

I'm interested in understanding what's actually happening underneath.

For example:

```text
SMTP address
    ↓
The email address people normally recognize.

LegacyExchangeDN
    ↓
An Exchange-specific identity that may still be referenced
by historical messages and cached recipients.

X500 proxy address
    ↓
Allows a replacement recipient to recognize an older
Exchange identity.
```

Understanding those relationships makes troubleshooting much easier than simply copying commands from a forum post.

This site is my attempt to document those discoveries as I encounter them.

---

## Disclaimer

These are personal technical notes based on my own research, testing, and experience.

Examples are sanitized and may be simplified for readability. Commands that modify production systems should always be reviewed and tested before use.
