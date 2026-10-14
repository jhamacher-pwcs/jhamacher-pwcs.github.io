---
layout: page
title: About
permalink: /about/
---

# About This Site

This site is my personal collection of technical notes, troubleshooting write-ups, scripts, and lessons learned while working in IT.

Most of the content comes from real problems I've encountered while administering systems, researching unexpected behavior, or trying to understand why something works the way it does.

My goal isn't just to document the final command that fixed a problem. I want to understand and document what was happening behind the scenes, what didn't work, and what I learned along the way.

## Topics

You'll primarily find notes related to:

- Microsoft 365
- Exchange Online
- PowerShell
- Active Directory
- Microsoft Entra ID
- Microsoft Graph
- Networking
- Systems administration
- Automation
- Troubleshooting

The topics will expand as I encounter new problems and technologies.

## Scripts

I also maintain a [`/scripts`](./scripts/) directory containing PowerShell scripts and other tools related to topics discussed on this site.

These scripts generally come from real administrative tasks or troubleshooting work.

Where possible, I'll include documentation explaining:

- What the script does
- Why I created it
- Requirements and prerequisites
- Important configuration options
- Potential risks
- Example usage

Scripts published here should be treated as examples rather than something to run blindly in a production environment.

Always review and understand a script before running it.

## Learning Through Troubleshooting

Some of the most useful things I've learned in IT started with a question like:

> Why did that happen?

A task that initially appears simple can expose a much larger system underneath.

For example, replacing an Exchange Online distribution list led me to learn more about:

```text
SMTP addresses
      ↓
LegacyExchangeDN
      ↓
X500 proxy addresses
      ↓
Outlook recipient caching
      ↓
Exchange recipient resolution
```

Understanding those relationships is much more useful than simply knowing which PowerShell command makes the immediate problem disappear.

That's the kind of information I want to capture here.

## Why Publish It?

Writing something down forces me to make sure I actually understand it.

Publishing these notes also gives me a searchable reference for problems I've already solved and, hopefully, provides something useful to another administrator troubleshooting the same issue.

This isn't intended to be authoritative vendor documentation. It's a record of what I've researched, tested, and learned.

When possible, I'll link to official documentation and other resources that helped me understand the subject.

## A Note About the Examples

Any examples from real environments are sanitized before being published.

Organization names, domains, tenant information, object identifiers, email addresses, usernames, and other environment-specific information may be replaced with example values.

## Disclaimer

Everything on this site represents personal notes, research, testing, and experience.

Commands and scripts that work in one environment may behave differently in another. Microsoft 365, Exchange Online, cloud services, APIs, and administrative tools also change over time.

Review commands and scripts carefully, understand what they modify, test when appropriate, and maintain a rollback plan before making changes to production systems.
