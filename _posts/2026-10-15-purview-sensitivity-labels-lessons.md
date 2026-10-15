---
layout: post
title: "15 Million Labels Later: Lessons from Deploying Microsoft Purview Sensitivity Labels"
date: 2026-10-15
categories:
  - Microsoft 365
  - Purview
tags:
  - Microsoft Purview
  - Sensitivity Labels
  - Auto-Labeling
  - Exact Data Match
  - DLP
  - Microsoft 365
---

# 15 Million Labels Later: Lessons from Deploying Microsoft Purview Sensitivity Labels

When we started working with Microsoft Purview sensitivity labels, our problem wasn't that we didn't have rules about protecting sensitive information.

We had plenty of rules.

The problem was that we had a lot of PII floating around the organization and very little visibility into it.

We didn't really know how much sensitive data we had, where all of it was stored, or how it was being shared.

Before we could start protecting that data consistently, we needed a way to classify it.

That started what became a much larger project involving sensitivity labels, auto-labeling policies, Sensitive Information Types (SITs), trainable classifiers, Exact Data Match (EDM), encryption, and eventually DLP.

After months of simulation, testing, refinement, and deployment, we've now applied labels to close to **15 million items**.

Here are some of the things I learned along the way.

## Designing the Labels

One of the first challenges was deciding what our labels should actually mean.

We needed a classification model that mapped back to regulatory requirements without simply copying regulatory language into Microsoft Purview. The labels also had to make sense to the people using them and support legitimate business workflows.

At a high level, our model distinguishes between content intended for broad use, ordinary internal information, confidential business information, and information requiring stronger protection.

Some classifications primarily identify or visually mark information. Others can apply controls such as encryption, access restrictions, or limitations on actions like forwarding, copying, and printing.

We also learned that one level of protection wasn't enough for every situation. Sensitive information sometimes needs to remain internal, while in other cases there is a legitimate business need to securely share it with specific people outside the organization.

That led us to create different protection options depending on how the information needed to be handled rather than treating every sensitive document exactly the same.

This was one of my first big lessons:

> Your label taxonomy needs to satisfy your regulatory requirements, but it also needs to support how your organization actually works.

## Classification Doesn't Always Mean Encryption

Another thing I came to appreciate was that classification and encryption aren't the same thing.

Some information needs to be identified as protected and handled accordingly without necessarily being encrypted. Other information warrants stronger technical controls.

Depending on the classification, our labels can do things such as:

- Apply visual markings
- Apply encryption
- Restrict access
- Limit forwarding, copying, or printing

The important part is that a sensitivity label isn't necessarily just a tag saying that something is sensitive. At higher levels, it can become an enforcement mechanism.

That distinction becomes extremely important once you start auto-labeling.

## Auto-Labeling Took Months, Not Days

Once we had the beginnings of our classification system, the next challenge was figuring out how to identify the content automatically.

We were looking across:

- Exchange Online
- SharePoint Online
- OneDrive

Some of Microsoft's built-in Sensitive Information Types worked very well.

The **U.S. Social Security Number** SIT, for example, was useful essentially out of the box.

We also found several built-in trainable classifiers that worked well for identifying particular types of documents.

Other data was considerably harder.

We started every auto-labeling policy in simulation.

And they stayed there for a while.

It took **months of simulation, testing, reviewing matches, adjusting policies, and trying again** before we were comfortable allowing some of these policies to actually apply labels in production.

That time wasn't wasted.

A policy finding thousands of matches doesn't mean it found thousands of things you actually wanted it to find.

## The Employee ID Problem

Employee IDs became one of our biggest blockers.

An employee ID is ultimately just a short string of numbers.

Imagine trying to identify a five-digit employee ID using a regular expression.

Something like:

```text
12345
```

isn't inherently an employee ID.

It's just five numbers.

We tried combining patterns with secondary evidence such as Microsoft's **All Full Names** SIT.

Conceptually, the detection was something like:

```text
Five-digit number
        +
Person's name nearby
        =
Possibly an employee ID
```

The result was a huge number of false positives.

We experimented with confidence levels.

We experimented with the distance between primary and secondary detectors.

We refined the detection logic.

None of it really solved the underlying problem.

The issue wasn't that our regex needed another adjustment.

The issue was that a pattern couldn't tell us whether `12345` was **actually an employee ID**.

## Exact Data Match Changed Everything

Exact Data Match was the breakthrough.

Instead of asking:

> Does this look like an employee ID?

EDM allowed us to effectively ask:

> Is this an actual employee ID from our data?

Even better, we could associate that ID with additional information about the employee.

For example, suppose my employee ID appeared in a document next to a coworker's name.

That shouldn't necessarily trigger.

But if my employee ID appeared with information associated with **me**, such as my:

- Name
- Email address
- Department
- Location

then we had much stronger evidence that we'd actually found an employee record.

That's exactly what we had been trying to accomplish with regex, proximity, and confidence tuning.

Once we implemented EDM, it was immediately much closer to what we needed.

Several auto-labeling policies had been blocked because we didn't have a sufficiently reliable way to identify employee and student IDs.

After EDM was working, it only took a few more weeks of testing and refinement before those policies were ready for production.

If I were starting this project again, **I would investigate EDM much earlier**.

## Detection Thresholds Matter

Finding sensitive information doesn't necessarily mean every occurrence needs the same level of protection.

We found that context, type of information, confidence, and quantity all matter. A small amount of one type of information might warrant classification and visual markings, while a larger collection of the same information might justify encryption. Other particularly sensitive data might justify stronger protection even when only a single instance is detected.

We therefore built different policies and thresholds for different risk levels rather than using a simple rule of:

```text
Sensitive information detected
        ↓
Encrypt everything
```

The exact thresholds were organizational risk decisions, not merely technical ones.

Purview gave us the ability to detect information and enforce controls, but deciding where those boundaries should sit required input from leadership.

## Leadership Was Critical

One of the most important parts of this project had nothing to do with Purview.

Early in the project, we met with leadership every week or two.

Those meetings were incredibly useful.

We could explain:

- What we'd discovered
- What was working
- What wasn't working
- What decisions we needed
- What risks came with each option

The technical team could answer:

> Can Purview detect this?

But that's different from answering:

> What should the organization do when Purview detects this?

Should one SSN cause encryption?

Should 20 employee IDs?

Should a user be able to override that classification?

Those aren't purely technical decisions.

Having leadership regularly available to make those decisions kept the project moving.

If I were starting over, establishing a regular decision-making cadence with leadership would be one of the first things I'd do.

## Rolling Out Encryption Carefully

We didn't deploy our encrypted auto-labeling policy organization-wide on day one.

Our rollout of automatic encryption was gradual.

We started with a small department.

Then we expanded to four departments.

Then central office.

Finally, we deployed it across the organization.

That gradual rollout gave us a chance to discover how automatic encryption affected real users before exposing everyone to it.

Once we had experience with that rollout, deploying policies that **didn't** automatically encrypt content was much easier. Those could generally be rolled out organization-wide much more quickly.

## Users Notice Encryption

Users generally didn't notice when content received classifications that didn't materially change how they worked with it.

They definitely noticed when it started being encrypted.

One surprisingly visible example was PDFs.

Encrypted PDFs could be opened using supported applications such as Adobe or Microsoft Edge, which meant users accustomed to opening PDFs in Chrome immediately noticed a change.

There were also issues when users sent encrypted content externally without understanding what the label meant.

From the system's perspective, everything might be working perfectly.

The document contained protected information.

The policy detected it.

The label was applied.

The document was encrypted.

Then the user emailed it to someone outside the organization who couldn't open it.

From the user's perspective:

> Why can't they open my file?

That's where the technical implementation meets user education.

## Documentation Doesn't Mean Users Read It

We had documentation.

That didn't mean everyone had read it.

Some users didn't know auto-labeling and encryption were coming. Others didn't understand what a particular label meant when it appeared.

We also encountered a support problem.

When Tier 1 and Tier 2 support weren't able to answer some of these questions, tickets came directly to our team.

That reinforced another lesson:

> A security control isn't fully deployed when the technology is enabled. Support staff and users need to understand what changed too.

Communication and support readiness need to be part of the rollout plan.

## Bring the Classification Closer to the User

Service-side auto-labeling solved an important problem for us.

It allowed Purview to find and classify content across Exchange Online, SharePoint, and OneDrive.

But it also meant users could discover the consequences of a label **after** they had already tried to do something.

We've since configured client-side labeling to align as closely as possible with our service-side policies.

Now, for example, if someone drafts an email containing enough sensitive information to meet one of our policy conditions, the appropriate label can be applied **while they're composing the message**.

The user sees the label before clicking Send.

That's a much better experience than having the service apply protection later without the user understanding what happened.

## DLP Is the Next Part of the Puzzle

We're also working on DLP policies to help educate users when information is shared incorrectly.

The goal isn't simply:

```text
You did something wrong.
BLOCKED.
```

We want the controls to help users understand:

- What sensitive information was detected
- Why the current sharing method may be inappropriate
- Which classification should be used
- How the information can be shared correctly

Ideally, the security controls become part of teaching people how to handle data rather than something they only encounter when the system stops them.

## The Scale Surprised Me

Over the last several months, we've automatically labeled a couple million files.

Another approximately **12 million items** received our organization's default classification.

Overall, we're approaching **15 million labeled items**.

That's a very different place from where we started.

Initially, one of the fundamental problems was:

> We don't really know what's out there.

Now we have a classification system being applied across millions of items, along with increasingly reliable ways to identify sensitive information.

Classification isn't the end goal.

It's what gives us a foundation for everything that comes next.

## What I Would Do Differently

If I had to start this project again tomorrow, there are several things I'd change.

### Start the Label Discussion with Leadership Immediately

I would start by asking:

> What classifications does the organization actually need?

And then:

> Do the names of our labels need to exactly match the language in our regulations?

Those sound like simple questions, but they have long-term consequences.

Once millions of items and thousands of users are using a taxonomy, changing it becomes considerably more complicated.

### Design for Business Needs, Not Just Regulatory Language

Our regulations gave us the foundation, but they couldn't anticipate every legitimate business workflow.

We found that the classification model sometimes needed to account for business requirements that weren't explicitly described in the regulations, including different ways of securely sharing sensitive information.

I've looked at approaches used by other organizations, including [Stanford University's sensitivity label model](https://uit.stanford.edu/service/microsoft365/sensitivity-labels), and I like the idea of keeping the user-facing classification system as straightforward as possible.

If I were starting fresh, I'd spend more time exploring whether we could meet our regulatory requirements with a simpler taxonomy.

### Start EDM Earlier

I wouldn't spend nearly as long trying to make regex and proximity rules solve a problem they fundamentally weren't suited to solve.

For identifiers tied to authoritative organizational data, I'd investigate Exact Data Match much earlier.

EDM removed one of our largest technical blockers.

### Treat User Experience as Part of the Security Design

I would also think about client-side labeling, DLP, communications, and help-desk readiness much earlier.

The question isn't only:

> Can we automatically protect this?

It's also:

> Does the user understand what just happened and what they're supposed to do next?

Those are different problems, and both matter.

## What I Learned

My biggest takeaway from this project is that implementing sensitivity labels isn't primarily about creating some labels in Microsoft Purview.

It's a data governance project.

You have to figure out:

```text
What data do we have?
        ↓
How should we classify it?
        ↓
Can we reliably detect it?
        ↓
What protection should each classification receive?
        ↓
When should automation override the user?
        ↓
How can users legitimately share the information?
        ↓
How do we teach users what the controls mean?
```

Purview provides the technical mechanisms for answering many of those questions.

It doesn't make the decisions for you.

And sometimes the most important discovery isn't another setting buried in the Purview portal.

For us, one of those discoveries was that **five digits that look like an employee ID aren't the same thing as knowing they're an employee ID**.

Once we stopped trying to make pattern matching answer that question and started using Exact Data Match, several pieces of the project finally fell into place.

Nearly 15 million labels later, we're still refining the system.

But we now have something we didn't have when we started: visibility into our data, a consistent way to classify it, and controls we can build on to protect it.
