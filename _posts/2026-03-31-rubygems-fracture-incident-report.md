---
title: "RubyGems Fracture Incident Report"
layout: post
published: true
date: 2026-03-31
permalink: /2026/03/31/rubygems-fracture-incident-report/
image_url: https://www.dropbox.com/scl/fi/1l6885wvgezoeqb3yxsl6/Screenshot-2026-03-31-at-9.43.23-AM.png?rlkey=yma4zkl0bq85fofu8xneoexmm&raw=1
categories:
    - ruby
---

This is a copy of the [canonical report I published on RubyCentral's site](https://rubycentral.org/news/rubygems-fracture-incident-report/). I recommend reading there for the most updated copy.  This document attempts to give closure to the Ruby community about the events that led to the incident,  September 10-18, 2025, which I’ve named “RubyGems Fracture.”

## Preamble

I joined Ruby Central’s Open Source Committee on October 22nd, 2025, after the GitHub access changes. I was adamant internally and externally from day one about performing a retrospective to try to wrap my head around the full, true picture of what happened and why.

In the pursuit of this task, I’ve spent 20+ hours interviewing and chasing up leads, easily quadrupling that time spent reviewing other artifacts such as chats and raw GitHub access logs. For any fact learned verbally, I’ve cross-referenced it with either another independent (important) account or hard evidence, such as a document or video, etc. This incident involved many people over a rather long time scale, and it was important to detangle how people perceived events from how they actually unfolded. The subject matter is deeply subjective, and multiple failed attempts at writing this doc came as a result of aiming for objectivity, for blameless representation. Therefore, those named in this report are:

- Full-time employees of Ruby Central
- Part-time consultants who were involved in access discussions
- Anyone who made an access change from September 10th-18th, 2025
- Those who have already been publicly identified in the discourse

Volunteer groups, including the Ruby Central Board and the Open Source Software (OSS) Committee, are listed, but their actions are represented as a group. Individual quotes from the OSS Committee are used without direct attribution when they represent a general consensus.

This document attempts to paint an accurate representation of what Ruby Central (staff and members, especially in the OSS Committee) experienced and did in the events leading up to and including GitHub access removal. It is not the only lens to view these events, and it’s not exhaustive, but the hope is that it will provide transparency and hopefully closure.

## Summary

Two engineers, André Arko and Samuel Giddens, were working on RV together. Each announced that they were leaving Ruby Central. Ruby Central, in turn, wanted to cleanly offboard them and sever ties with RubyGems.org production access, which was tightly coupled to GitHub access. However, Ruby Central lacked the structural ability to make this change directly (did not have admin controls on the GitHub Business/Enterprise). The resulting process was drawn out and poorly communicated internally and to the general public.

This led to the GitHub access changes between September 10th-18th, 2025, that resulted in the walkout of paid contributors: André Arko (`indirect`), David Rodríguez (`deivid-rodriguez`), Ellen Dash (`duckinator`), Josef Šimánek (`simi`), Martin Emde (`martinemde`), and Samuel Giddins (`segiddins`). A group that refers to itself as **the maintainers**.

This group asserted that they controlled administrative access to the `github.com/rubygems` organization via the Business/Enterprise permissions and that Ruby Central, the operator of the RubyGems.org service, does not have a right to those abilities or access. When Ruby Central's Open Source Director, Marty Haught, gained access to the GitHub Business/Enterprise and would not relinquish this control, they quit in protest.

## Incident Lessons

Here are some of the lessons from the timeline below:

**Policies and procedures are important**: Runbooks and other operational documents, technical and non-technical, were neglected for a long time. Efforts to document and standardize these efforts began shortly before this incident in July/August 2025\. At the time of the incident, there were no documented offboarding policies or checklists. There are now.

Many companies have an “Outside Business Activities” declaration process for full-time employees to formally let their employer know when they’re working with a foundation or pursuing an activity with compensation, such as writing a technical book. Ruby Central does not have a policy like this in place, but I’ve suggested we add one.

**Distinguish remarks from requests**: The initial access loss timing was accidental. This could have been prevented by clearly labeling requests for action.

**Access changes should always come with explanations**: When an access change event happens, the person affected should always know:

- What access was changed?
- Why?
- What can they do about it going forward? Is it permanent or temporary? Who can they talk to if they have questions or problems?

Ruby Central has reached out to some of the developers who were removed due to inactivity to let them know why. We will reach out to all of them.

Platforms with permissions management, such as GitHub and RubyGems.org, should consider adding an option for users to include messages when access changes occur.

**Teams need to know why access is changing:** Beyond letting the people affected know, those who work with them need to know. This is important not just for access removals but additions as well.

- Whose access changed?
- What is it now?
- Who should they talk to if they have questions or problems? It's not always appropriate to share specifics with everyone, but say as much as you can.

**Impacts of access changes should be clear:** Platforms with Role-Based Access Control (RBAC, such as team membership) and hierarchical access systems (such as a GitHub Business/Enterprise containing many Organizations) make it harder for the user making access changes to know the end result of their change. It is better to place the burden of understanding the impact on the system than on the user.

I suggest that these platforms consider adding the ability to preview the effect of access changes to reduce mistakes. A preview could help ensure that the Principle of Least Privilege (PoLP) is being followed without accidentally removing too much.

**Perform sensitive operations "out loud"**: The Japanese have a concept translated to "[pointing and calling](https://en.wikipedia.org/wiki/Pointing_and_calling)" for avoiding and recognizing mistakes. This can be repurposed for many contexts, such as access changes.

An example could be announcing "I'm going to change access now" in a new Slack thread, then following up with how you plan on changing it (such as posting a screenshot, hovering over the new status) before actually making the change. This gives a log so the person can remember individual actions and when they were taken. This is useful even if the system has a log to separate intentions from actions. Done in front of others, it also gives them time to react if the planned action is not desired. It won't stop every mistake, but it will stop some and make doing a retro on others easier.

**Decouple access from personal identity**: Access changes in open source are especially emotional experiences. Beyond losing capabilities, access reduction can affect perceived credit for and earned positions. For example, removing ownership on [RubyGems.org](http://RubyGems.org) has the side effect of removing gem download metrics from a user’s profile page.

Platforms that couple metrics with permissions management should consider ways to extend attribution that are decoupled from direct access. For example, preserving gem downloads for “alumni” of package owners even after they’re removed.

**Access shouldn't gatekeep contributions or getting paid**:  The way that **the maintainers** explained financial compensation came from early days of paid work on Bundler and Ruby Gems, where someone would make good contributions, be recognized with commit access, eventually promoted to “maintainer” status, and this would open the door for getting paid for maintenance or operations. The implication is that if commit access is taken away, it is perceived as removing both status and income. This pipeline also introduced an incentive problem where new members gaining status would be perceived as possible income competition.

**Public work and funding require public accountability**: The business of open source is not just doing the work, but making sure it’s done in a clear and appropriate way. That means more time and care need to be spent on drafting appropriate policies and communicating them internally and externally. It also means that foundations need to be fluent in engaging with their communities and communicating clearly.

## Timeline leading up to the Incident


**January 13, 2025**

- Marty Haught, the Ruby Central Open Source (OSS) Director, created a 2025 Roadmap document with funding ideas, including “Ruby one-line installer” and “Make RubyGems faster” proposals, both of which referenced UV, the Python package manager written in Rust.


**January 17, 2025**

- André Arko edited the 2025 Roadmap to add detail and change the title to “Ruby one-line installer/manager”.

Ultimately, neither project received funding (no grants or sponsors were found to directly hire for the project through Ruby Central), but the item was still in the foundation's technical roadmap of projects it was interested in.

**March 5, 2025**

- Marty Haught [introduced policy pages to RubyGems.org](https://github.com/rubygems/rubygems.org/pull/5497), including Acceptable Use Policy (AUP), Copyright Policy, Privacy Notice, and Terms of Service (TOS). This included policies such as how RubyGems.org [shared personal information with 3rd parties](https://rubygems.org/policies/privacy) and what personal information (PII) it collects.

**June 3, 2025**

- André Arko announced he was leaving Ruby Central with a message to the `#general` channel:

> *“After sitting with the DHH news for a few days, I’m sorry to say that I’m not going to be able to attend RailsConf, and I am resigning from my advisory role at Ruby Central.*
>
> *I plan to continue participating in and advising the RubyGems open source projects, but platforming DHH at RailsConf means I cannot continue as an official member or representative of Ruby Central. \[...\]”*

André announced that he is leaving his paid, part-time advisory role with Ruby Central. The OSS Committee read this post as indicating he desired to cut all financial ties with Ruby Central. However, that was not the case. Andre did not leave his secondary on-call rotation, which is also a paid part-time position.

The Ruby Central OSS Committee is a group of volunteers who have oversight of Ruby Central's OSS budget, as proposed by the Ruby Central OSS Director, Marty Haught. At the time, the committee consisted of Gabi Stefanini, Mike Dalessio, and Ufuk Kayserilioglu (who was also a board member). These members have since moved on, and today the committee is composed of one member, Richard Schneeman, the author of this document.

**June 27, 2025**

- Ruby Central OSS Committee meeting program updates. Raw notes from the meeting:

> - *Maintenance budget*
>   - *Cutting back from $22k to $12k per month to extend maintenance budget*
>     - *Eliminates secondary on call ($4k per mo)*
>     - *Cuts back maintenance 50% ($6k)*
> - *RubyGems.org supporter membership*
>   - *$2-5k per year for businesses*
>   - *All goes to maintenance and on call (after admin cut)*
>   - *Criteria*
>     - *Allows easy credit card signup with recurring monthly payments.*
>     - *Fully self-service for managing their subscriptions.*
>     - *Internationally friendly*
>     - *No contract to sign*
>     - *Minimal sign up data collected: name, email, organization, payment info.*
>     - *API so we can programmatically generate a list of members on RubyGems
>       and RubyCentral websites.*
> - *New contractor: \[...\]*
>   - *Former \[...\] - Used to work with \[Ruby Central paid bundler maintainer\]*


In this meeting, they discussed [balancing the maintenance budget](https://speakerdeck.com/mghaught/baltic-ruby-keynote-2025?slide=20) given a sponsorship gap by eliminating secondary on-call, as well as onboarding a new contractor. They planned to use this new contractor to support initiatives that can bring in more revenue to fund OSS maintenance, as spelled out in the middle bullet.

**July 7, 2025**

- Ruby Central published a blog post, [RubyGems.org Funding Model & A New Path For Community-Led Growth](https://rubycentral.org/news/rubygems-org-funding-model-a-new-path-for-community-led-growth/).

This blog post tried to drum up additional funds and diversify sponsors:

> ***“With roughly 110 supporters,** we would be able to fully fund our annual goals for operations and maintenance. In addition to our other funding sources, such as corporate sponsors, this level of community funding would enable us to expand beyond maintenance and focus on new features and enhancements that will benefit developers and gem creators.”*

**July 8, 2025**

- First day of ["The last RailsConf"](https://web.archive.org/web/20250703102317/https://railsconf.org/).

**July 9, 2025**

- First commit on Ruby Central "runbooks" (private) repository by the new contractor.

There was no documentation on how to run the RubyGems.org service (a.k.a "runbooks”), so in addition to doing scoped work, the new contractor was also tasked with documenting their onboarding process. This also means there was no documentation on how to revoke someone's access or offboard them from the RubyGems.org service.

**July 10th, 2025**

- The last day of “The last RailsConf”.


**July 11, 2025**

- Ruby Central "RubyGems maintainer offsite" was held in the same city as RailsConf, at a different venue. Travel for Marty Haught, Samuel Giddens (the full-time Security Engineer on staff for Ruby Central), André Arko, and one more were covered by Ruby Central.
- The [first commit on RV](https://github.com/spinel-coop/rv/commit/2fce7dd6a6659d16146672a3eab9871899203b91), a Rust tool for managing Ruby dependencies, was created by André Arko and Samuel Giddens.

**July 20, 2025**

- The [spinel-coop org](https://github.com/spinel-coop/.github/commit/10c4951376598a3745d9be1fca7c5fab31ec9524) where the RV project lives got a description:

<!--wrap-->
```
Spinel maintains the Ruby language packaging ecosystem, and acts as maintainer of last resort for the Ruby ecosystem. Our portfolio includes:

- rv, the ultimate Ruby version manager and gem tool

A Spinel retainer offers organizations the opportunity to ensure the sustainability of their foundational Ruby dependencies, and direct access to the expertise of the maintainers.

If you’re betting your business on a critical open source technology, you

1. want it to be sustainably and predictably maintained; and
2. need occasional access to expertise that would be blisteringly expensive to acquire and retain.

Getting maintainers on retainer solves both problems for a fraction of the cost of a fully-loaded full-time engineer. From the maintainers’ point of view, it’s steady income to keep doing what they do best. It’s a great deal for both sides.
```

Ruby Central was not aware of RV or either Sam or André's participation in this new Co-Op at this time. When they learned of it, the structure seemed similar to RubyTogether, which was created in 2015 by André Arko and merged with Ruby Central in 2021\. RubyTogether funded bundler and later [RubyGems.org](http://RubyGems.org) codebase maintenance and merged with Ruby Central in October 2021\. In the merger, the Ruby Central OSS Director position was created, and André Arko became the first acting director.

While he was only paid part-time to work with Ruby Central, he had intimate knowledge of the foundation roadmap and knew Ruby Central was interested in undertaking a similar project. He did not tell anyone in Ruby Central about this work until it launched later, on August 26, 2025\.

**July 28, 2025**

- André registers [Spinel Cooperative Corporation](https://www.bizprofile.net/ca/san-francisco/spinel-cooperative-corporation) in the state of California.

**August 1, 2025**

- Shan Cureton, Ruby Central's Executive Director, had a meeting with the Ruby Central board. Board members are: Ben Greenberg, David Corson-Knowles, Freedom Dumlao, Kinsey Ann Durham, Naijeria Toweett, Ufuk Kayserilioglu, and Valerie Woolard.
- Shan shared that a pledge to fund OSS at Ruby Central for $250,000 was withdrawn. Contributed Systems (Sidekiq) later publicly shared that they withdrew a pledge due to DHH speaking at the last RailsConf.

The forecast from **June 27, 2025**, included this pledge, meaning an already tight OSS budget got tighter. However, there was already a declared interest in reducing secondary on-call to slow the burn rate.

**August 4-22, 2025**

- OSS Committee Slack message from Marty in Slack regarding making money from the RubyGems.org server logs:

> *“André suggested a way that his consultancy could cover the cost of secondary on call by analyzing gem download access logs to provide usage data by companies.  Here's a quick write-up of the proposal in this thread. \[...\]”*

The proposal has André acting as a middleman between Ruby Central and a third party who would pay for the logs. It is unclear at that time who that third party was, how they would make money from the logs, or how much money those logs would be worth to them.

A OSS Committee member responds:

> *“\[...\] Do we really, truly need a secondary shift? I think I remember Marty saying that in that last few years, the secondary shift has never been escalated to. \[...\] It's not stated explicitly in André's message, but my understanding is that he will want to own any derived works based on the HTTP logs. If that's the case, then we need to make sure we're comfortable losing control of community PII in a way that may be unpleasantly surprising down the road. \[...\] Let's please make sure we're imagining the worst-case scenarios before going much further.”*

The cost of secondary on-call is $48,000 USD annually.

Marty responds:

>*“\[...\] Legally, we'll need to investigate this to be clear on what we can do here.  It is PII. We do care about GDPR. Our Privacy Policy specifically mentions this data:*
>*\[...\]*
> *The transparency and ownership points you bring up are the biggest in my mind.  In the end, it may not be worth allowing a third party to do this sort of thing.  RC may want to provide more visibility in how gems are consumed to publishers but that is separate from this discussion.*
>*\[...\]*
> *Though I am still keen to \[hear\] the committee's thoughts. I don't think we can proceed with this.  Long-term, we are better off not involving André with the operation of the platform.  Signing a deal with his consultancy to build a product with PII from the service isn't worth all the reputational risk we are likely to incur regardless if legal signs off on it.   While the short-term gains are attractive when we're tight on funding, it's not worth it in many aspects.”*

**August 18, 2025**

- Samuel Giddens gives Ruby Central his two-week notice that he will be terminating his full-time security position.
- André Arko creates an access token named `rubygems-github-backup` with access to all repos in the [`github.com/rubygems`](http://github.com/rubygems) organization, including private repos. This is the only access token of its kind.

**August 25, 2025**

- André releases RV, and it is [announced to the public](https://web.archive.org/web/20250826103745/https://andre.arko.net/2025/08/25/rv-a-new-kind-of-ruby-management-tool/). The post mentions Samuel Giddins as a team member.
- André follows up with Marty on his proposal to cover secondary on-call with access to the RubyGems.org logs.

**August 26, 2025 18:26 UTC**

- OSS Committee Slack message by Marty:

> *“I'm back and catching up after my mountain trip.  I'd love to hear any updates from the committee meeting.*

> *So the other new thing is [André's post about RV](https://andre.arko.net/2025/08/25/rv-a-new-kind-of-ruby-management-tool/).  I saw this mentioned in two slack channels.  I did not know of this until I read the post, which is disappointing.  Looks like Sam is leaving to work on that.  Both of which I learned through the post and not directly from either of them.  I'd love your thoughts on how we should respond.*

> *I had debated internally if we should make a public announcement about Sam's departure.  Does this push us more in a direction?*

> *I was already planning on accelerating removing André but this seems to put that at a higher priority for when I'm back from Rails World.  It would be easier if I had another 2 engineers to help with on call.”*

This message is the first recorded artifact that mentions a desire to offboard *André*. The framing “accelerating removing” also shows that the intent came prior to this message and the RV announcement.

**August 26, 2025 (follow-up)**

- OSS Committee Slack, a member responds:

> *“yes, agreed. we can add \[a previous RubyGems contributor\] to the rotation if \[they are\] ready for it, and i think we should accelerate the adoption of people from other companies that can do similar work (like \[another contributor from a different company\]).”*

Another member responds:

> *“I'd cut Sam and André's ties with the organization as soon as possible, announce the departures, and wish them the best of luck on their next endeavor.”*

The conversation quickly turns to operations of the RubyGems.org service, where on-call staffing is a concern. Previously, Samuel Giddens was part of the rotation; with his departure, they would need time to find a replacement.

**August 27, 2025**

- RV adds a license. It is now dual MIT/Apache-2 open source licensed.

**August 29, 2025**

- Message from Marty in the OSS Slack

> *“To follow up on the on call, the team discussed how to handle on call with Sam's departure.  We'll have André cover that in September. We're going to put together onboarding and improved documentation in September to train up several folks to be on call ready. \[new consultant\] and \[another developer\] has volunteered to be part of that group.  I'm looking to get 3-4 total people per time zone block (emea, americas, apac) so we can have a sustainable rotation.”*

At this point, the path to offboarding everyone cleanly was uncertain. The new consultant made progress on some runbook documentation, but still did not have server access.

At this time, Marty, as the Ruby Central OSS Director, did not have admin permissions on GitHub. Those permissions are held by Colby Swandale, Hiroshi Shibata, André Arko, Samuel Giddens, and Martin Emde. That means in order to offboard anyone, he needs to ask someone else to make a change.

**September 4, 2025**

- First day of RailsWorld conference.

There was a meeting at RailsWorld between Rails Core, including David Henimier Hanson (DHH), and Ruby Central representatives at the conference. I've interviewed five of the attendees independently. I believe the intent to offboard came from Marty, prior to this meeting on August 26th. Coordinating operators to take over on-call also started on August 26th.

I believe that if this meeting hadn't happened, some details may have changed, but the outcome would have been the same. However, not all present at the meeting would have known all of those pieces or come to the same conclusion.

Hiroshi was not at that meeting, but spoke to Marty at the conference. Marty did not request GitHub access at RailsWorld.

Overall, RV and André's involvement was a very popular "hallway track" topic, as it was released so recently. I had not yet joined Ruby Central, but I saw Marty, and I asked him about RV at the conference. Marty confirmed that RV was not a Ruby Central project. He didn't share any information regarding André's resignation from Ruby Central or access to RubyGems.org.

**September 5, 2025**

- Samuel Giddens' employment notice took effect, and he was no longer employed at Ruby Central.
- Last day of RailsWorld conference.

**September 8, 2025**

- André follows up with Marty on his proposal to cover secondary on-call with access to the RubyGems.org logs.

**September 9, 2025**

- Marty talked to Colby Swandale and Deivid Rodriguez about Sam and André leaving Ruby Central and their access permissions.

Both Colby and Deivid were paid part-time by Ruby Central. Colby is a paid part-time contractor who primarily works on the RubyGems.org service and codebase, while Deivid was the number one contributor to Bundler by commits. All of the self-described **the maintainers** have a financial relationship with Ruby Central in addition to their unpaid volunteer contributions.

Marty reported back to the committee:

> *“I have a quick update. Both Colby and David are not supportive of pushing André out on the OSS side of RubyGems without his consent. Removing André's access to the service does not seem to be an issue, so I'm proceeding with that planning.”*

A committee member clarified on the "pushing out" framing:

> *“We are not "pushing André out on the OSS side of RubyGems". I think that framing is wrong. André can continue to be a maintainer of RubyGems/Bundler as an open source contributor/committer, I have no problems about that. However, him having ownership of the organization and repos is not acceptable for the organization that is ultimately responsible for the security and reliability of those tools. In that sense, we are trying to make sure the repos have better homes in `ruby` and `rubycentral` orgs respectively. \[September 10, 17:01 UTC out of order, but wanted to mention it in case people stopped reading too soon\]*

> *The risk of handling operations in a world where André and Samuel don't have access to our ops is a risk I am willing to take, considering we can bring in people like \[contributor\], \[another contributor\], etc, into the fold if/when necessary. IMO, it is more important to swiftly and publicly cut ties with the folks that have already committed (semi-)publicly that they want to have nothing to do with RC, than worry about incidents.”*

The link between GitHub access and production access is not enumerated. As Deivid Rodriguez does not operate the RubyGems.org service, he wouldn't have known about the link between GitHub access controls and production server admin. Colby is more familiar with the service and would have known.

Another OSS Committee member responds:

> *“Now that you have already discussed with Colby & David  \[...\], I can guarantee you that André & Samuel already know. You should expect and be prepared for retaliation, be it a blog post that might post or that they remove your access from the repos. \[September 9, 2025\].”*

At this point, it was clear to the OSS Committee that even though André and Sam had "left Ruby Central," they did not want to reduce their permission levels. A sentiment that is consistent with most Ruby Open Source projects, where access is granted and rarely revoked. For example, [https://rubygems.org/gems/resque](https://rubygems.org/gems/resque) still has the founders of GitHub as gem owners on it, even though they've not pushed a new release for a very long time. For a community library, access is usually considered a "reward" and "earned."

RubyGems.org and other package registries are faced with an increased surface area of supply chain attacks. An extremely public [NPM supply chain attack](https://www.trendmicro.com/en_us/research/25/i/npm-supply-chain-attack.html) happened at roughly the same time as these access changes were happening (September 15, 2025). While this attack was not known to Ruby Central when the first access change occurred, the attack vector is one they were worried about: A targeted phishing campaign compromised a maintainer's access tokens. Ruby Central is actively engaged with [openssf.org](https://openssf.org/) and specifically their [Principles for Package Repository Security](https://repos.openssf.org/principles-for-package-repository-security.html), and is currently working towards level 3 security maturity.

With that context, Ruby Central (OSS Committee and Director) desired an access model closer to that of a professional organization, like the one I work for at my day job. I hold admin rights of a repository that I maintain, but do not have admin rights over the whole organization. With this strategy, the foundation can audit access and fully own completing offboarding from the RubyGems.org service. This strategy was a change from how things previously worked under other directors. The OSS committee believed that reducing Sam and Andre's access levels (at all, even temporarily) would be perceived as a demotion that risks retaliation.

The timeline of access changes is below, but to understand them fully, you need to understand what a GitHub Business/Enterprise is.

## GitHub Business/Enterprise explanation

Most GitHub repositories live under an organization. For example, `github.com/zombocom/rack-timeout` is the `rack-timeout` repository that lives in the `zombocom` organization. There is another hierarchical level that can contain many organizations, which is known as either a Business or an Enterprise. Most GitHub users aren't familiar with this level. I've been writing Ruby code since 2006, and I've never encountered it. It looks like this:

```
GitHub Business/Enterprise
	└── Organization(s)
	     └── Repositorie(s)
```

For the RubyGems GitHub Business/Enterprise, it holds a nearly empty `bundler` organization and the `rubygems` organization with many codebases:

```
RubyGems GitHub Business/Enterprise
	└── github.com/bundler [Organization]
	|   └── github.com/bundler/.github
	└── github.com/rubygems [Organization]
	    ├── github.com/rubygems/rubygems.org
	    ├── github.com/rubygems/shipit
	    ├── github.com/rubygems/terraform
	    ├── github.com/rubygems/rubygems-mirror
	    ├── [...]
	    └── github.com/rubygems/bundler-site
```

The RubyGems Business/Enterprise account was created by Hiroshi Shibata, `hsbt`, who promoted  the then current admins on the RubyGems organization to admins on the enterprise.

Confusingly, GitHub has another product called "GitHub Enterprise," which is different; that's a product that allows you to run a self-hosted version of GitHub on your own infrastructure. When "Enterprise" is used, it is in the "Business" context. These changes will show up in access logs with a prefix of `business`.

In addition to these levels, organizations also have teams as a way to control permissions.

## Incident timeline

This section was reconstructed based on [audit logs from the enterprise account](https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/reviewing-audit-logs-for-your-enterprise/audit-log-events-for-your-enterprise). The ability to audit access logs was not previously available for the OSS Director and the OSS committee. This was resolved when Marty gained access to the enterprise/business account.

**September 9, 2025** (continued)

- Marty requested Hiroshi Shibata `hsbt` make GitHub access changes on behalf of Ruby Central.

**September 10, 2:23:49 UTC** by `hsbt`

- business.remove\_admin: `indirect, segiddins, martinemde`
- business.invite\_admin: `mghaught`

**September 10, 2025, 3:32:27 UTC** by `hsbt`

- org.update\_member: `indirect`, `segiddins, martinemde` before: admin, after: read
- org.update\_member: `deivid-rodriguez`, before: read, after: admin (note that access increased)

André and Samuel were removed from the business, and their organization permissions were downgraded at the request of Ruby Central. Marty (OSS Director) was added to the business.

Hiroshi stated that Martin was granted this permission in 2023 by André, but he didn’t know why at the time. So, he reverted Martin’s Business/Enterprise owner status.

At this time, they could not transfer repositories outside of the organization, but they still had admin access to the RubyGems and Bundler repositories. They also still had the capacity to run [RubyGems.org](http://RubyGems.org) operations (such as deploying the service) through their team access.

Hiroshi believed that Deivid Rodriguez's access level was too low for the level of work he was performing, and increased his organization's access to admin.

This removal of `indirect`, `segiddins`, and `martinemde` was characterized externally as “a mistake,” but the only mistake was the timing, which was not properly communicated by Marty to Hiroshi.

**September 10, 2025**

- Message shared in Slack by Hiroshi with the RubyGems developers:

> *“I’m reviewing account permissions for rubygems now. I’ve assigned enterprise and org owner roles to only Marty, Colby, Deivid and me. The repository admin roles remains unchanged. Please let me know if you encounter any problems.”*

André asked why his permissions were downgraded in a DM, and Hiroshi shares:

> *“\[...\] Because you are \[leaving\] Ruby Central now. Owner can access billing and account control. I would like to align to minimum permission around that.”*

**September 11, 2025**

- OSS Committee Slack, Marty shared an update:

> *“\[...\], Colby, David Rodriguez, and hsbt are the owners in RubyGems. hsbt, Colby, and me are the enterprise owners.  Team access is still the same but with a quick check André only has member access in the places I've checked.”*

Committee members asked for clarification on the commit status. Marty responds:

> *“Let's discuss this tomorrow.  Forcing André out is likely to cause the team to defect.  Removing his administrative abilities less so.  I can share my thoughts on ways to keep him from blocking changes.”*

**September 11, 2025**

- André follows up with Marty on his proposal to cover secondary on-call with logs.


**September 14, 2025**

- Martin proposes a Governance RFC via PR [https://github.com/rubygems/rfcs/pull/61](https://github.com/rubygems/rfcs/pull/61) aimed at restoring access.

That RFC creates an “owner” definition, described as “A person with enterprise or organization owner permissions on GitHub for RubyGems/Bundler projects,” which would mirror the GitHub enterprise/billing owner. The high-level idea was to leave permissions as they were, but create a voting mechanism for removing permissions outside of “inactivity.”

While they didn’t know all the specifics of what Ruby Central desired (when they first drafted the RFC), they knew it had something to do with limiting access and thought this document would afford them the ability to have an official way to ask for permission/access removal, such that the OSS Director wouldn't need it directly.

Ruby Central wanted to make access control finer-grained and split [RubyGems.org](http://RubyGems.org) production server access controls out from the rest of the repositories. The top suggestion within the OSS committee was to move bundler/rubygems into the `github.com/ruby` organization.

**September 14, 2025**

- Andre stated he would seek someone else to restore his permissions, whether Ruby Central approved it or not.
- Upon hearing this ultimatum, the OSS director was alarmed. He expressed concerns internally about the possibility of not knowing who had access, or being removed in retaliation (or both). Ruby Central was not told who Andre expected to restore his access. This left a lingering doubt on all who held that structural access of whether or not they would assist Andre.
- For lack of a better word, there was a "truce" between the parties.
- Those who had been previously removed were asked not to remove Marty or Hiroshi.

**September 15, 2025, 8:59:39 UTC**  by `hsbt`

- The ability for enterprise members to delete repositories was turned off. Members cannot delete or transfer repositories in any organization in an enterprise at this time.


**September 16, 2025, 1:51:29 UTC** by `hsbt` at the request of Ruby Central

- org.update\_member: `indirect`,  `martinemde, segiddins` before: read, after: admin
- business.invite\_admin: `indirect, martinemde, segiddins`
- business.invite\_admin:  `deivid-rodriguez`

All access was returned to `indirect`, `segiddins`, and `martinemde`. Permissions for `mghaught`, the current OSS Director, and `deivid-rodriguez` gained on September 10, 2025, remained.

A meeting was scheduled.

**September 17, 2025**

- There was a Zoom meeting with Marty.
- The meeting was recorded by Ruby Central, a practice consistent with other "maintainer sync" meetings, for the purpose of privately sharing with maintainers who could not be present.
- André and Martin produced a list of thirteen developers who were invited. Five attend, and four speak: André (`indirect)`, Josef (`simi)`, Ellen (`duckinator)`, Martin (`martinemde)`.
- Two of these five had access changed (`indirect` and `martinemde`).
- Sam Giddens and Deivid Rodriguez did not attend.
- These four developers make it clear that they reject a Ruby Central employee retaining any access to the [`github.com/rubygems`](http://github.com/rubygems) GitHub organization or enterprise.
- They state their expectation that someone must gain administrative control via performing code contribution, and then, based on an internal selection criterion, only those who already have it will decide whose individual merit deserves administrative access to the `github.com/rubygems` organization or not.
- They express that they’re unhappy that Ruby Central hired a new contractor instead of offering work to one of them.
- Many alternatives are floated, and the developers acknowledge that private code and controls are intertwined in the public GitHub organization. They suggest that Ruby Central can fork the Ruby Gems repos that are needed for private control and access.
- Overall, the conversation is awkward and strained.

Context not present in the meeting: André and Martin were former acting OSS Directors and had `github.com/rubygems` organization and enterprise controls at the time. Prior to that, it was held by Evan Phoenix on behalf of Ruby Central until February 28, 2025 when it was removed by André Arko. So, they are not opposed to “Ruby Central” or the OSS Director having that control; they are opposed to someone getting that control without their input or buy-in as current Business/Enterprise admins.

**September 17, 2025** (cont.)

- After the public call, André met with Marty one-on-one and stated that he would quietly leave in exchange for a license to access and resell the RubyGems.org logs.

**September 17, 2025** (cont.)

- Marty released the video of the developer call to the OSS Committee members.
- The RFC from Martin was shared with the OSS Committee members.
- An OSS Committee member responded to the video privately in Slack:

> *“This call is mind-boggling to me. The lines between open-source work and paid work are blurry as hell and we need to fix this ASAP.  \[...\]”*

**September 18, 2025**

- Ruby Central Board meeting

On September 18th, there was a board meeting where an official decision was made on offboarding Sam and André. They decided to remove production access, including control of the `github.com/rubygems` organization, and their ability to commit. At the time, Ruby Central lacked legal agreements with all operators regarding their access to production servers and data.

It was thought that after offboarding efforts were finalized, they could work together to disentangle GitHub access. Ruby Central’s plan was to eventually present them with legal “operator agreements,” which would be enough to alleviate Ruby Central’s concerns and restore commit access. Followed by resolving proper homes for all repositories.

Internally in Ruby Central, the decision to remove commit access was met with dissension and debate. GitHub team access and Shipit access were explicitly talked about in the September 18th board session, but the full implication of that access (that it effectively meant that GitHub access and production infrastructure access were connected) was not fully spelled out.

This would mean that those with prior knowledge of those systems believe everyone understood the full links between access changes to `github.com/rubygems` and the RubyGems.org server, while those who were new to the information wouldn’t have intuitively understood all of the connections. Some felt that this was clearly a line too far, and some argued that their concerns merited an extended loss of access.

Due to the lack of a prior documented onboarding or offboarding procedure (runbooks), there was uncertainty around the minimum acceptable access changes to remove all [RubyGems.org](http://RubyGems.org) production server access.

**September 18, 2025, 17:56:19 UTC** by `mghaught`

- business.remove\_member: `indirect`, `segiddins, martinemde, deivid-rodriguez`

André and Sam are removed from the business again. From prior conversations, there was a worry that others would add their permissions back without warning, so while Martin is not being offboarded, his access is reduced. Deivid did not have business admin access prior to September 10th, and this change was an attempt to revert to that state.

When I came to Ruby Central, I was unfamiliar with the business/enterprise access level. So I did not know, as Marty didn't, that this action of removing a member here would remove them entirely. This total loss of access included all teams and repositories. This was a mistake. This action cannot be undone. Someone removed from a business must be invited back, and that person must accept.

While Ruby Central intended to remove commit access from André and Samuel temporarily, they did not intend to remove them completely from the business. Now, before any access can be given back, they need to be invited back to the org and accept. Their complete removal from the org was a mistake.

Further, Deivid was not supposed to have his access reduced below the September 10, 2025, levels. This was a mistake.

**September 18, 2025 18:04 UTC**

- Off-boarding emails sent to André and Sam from Marty.
- Both are similar. Here is the body of one:

> *“After consultation with the OSS Committee and the Ruby Central board, we have removed your RubyGems.org production access, given your departure from Ruby Central. We’re also pausing the on call rotations while we work through this transition. Please send a prorated invoice for on call services.*

> *I believe there are two remaining service accounts I never transferred, PagerDuty and HelpScout. I’d appreciate it if you’d transfer ownership to my email at your convenience.*

> *I’m deeply grateful for all you’ve done for the RubyGems and our community. I will be meeting with the OSS Committee shortly so I can resolve any open conversations.”*

Both emails contained a rationale for the access loss, but it was limited. Neither message acknowledged the GitHub access changes. Changes to commit access should have been listed along with the intention that those changes were intended to be temporary.

A strong concern from the start was that Ruby Central would lose developers beyond the two who were offboarded, due to a walkout. Rather than being direct and clear with actions and their motivations, Ruby Central tried to avoid the impression of conflict in hopes that others of **the maintainers** would not resign.

No other emails were prepared or sent to the other developers whose access was affected or their peers who still retained access. There were messages in Slack, but this communication was not pre-prepared.

**September 18, 2025 18:47 UTC**

- Email sent to `indirect`, `martinemde`, `segiddins`, `deivid-rodriguez`, by Marty:

> *“I'm terribly sorry about the GitHub removal. I messed up, and I accidentally removed all org access instead of downgrading. This is temporary as I work to fix the permissions structure. Martin's been helping me with this.*

> *I was forced by the board to take this action due to legal risk to Ruby Central. We're actively exploring how to move the specific repos (terraform, shipit, GitHub team control) out and adjust team control so that RubyGems, the code base, and GitHub organization can be controlled by least privilege by the agreed governance.*

> *I'll follow up more on this and engage with the governance rfc in good faith.”*

An email was sent apologizing for the mistake of removing developers from the GitHub organization. This apology was for the mechanics of the access removal, but not the intent.

Martin requested that Marty restore his permissions, and he would assist with restoring the rest. Marty inexplicably didn't see the controls he expected to invite someone to the `github.com/rubygems` organization. Martin was unable to identify the problem either. While being removed from a business/enterprise is inherited by the organization, being added as an admin is not. The issue was that he had to grant himself organization access, which he had not done.

**September 18, 2025, 21:45 UTC**

- A message from Marty to Colby asking for help restoring access to Samuel, Martin, and Deivid.

Colby was not directly involved in any of the GitHub removals and received the same communications as other team members. He was asked to help correct the accidental removal from the GitHub Business/Enterprise. Colby is in the AEST (Australia) time zone, so this was very early in his day (7:45 am). This request took some time to respond to.

**September 18, 2025, 23:17:32 UTC** taken by `hsbt`

- business.invite\_admin: `paracycle`

A Ruby Central board and OSS Committee member, Ufuk, was granted enterprise and organization access. He was asked to assist with access changes. This occurred roughly five hours after the `business.remove_member` changes went into effect.

**September 18, 2025, 23:19:49 UTC** taken by `mghaught`

- org.update\_member:	`mghaught` before: read, after: admin

The permissions issue with the Enterprise/Business was diagnosed and resolved. With this change, Marty could send out invites to the organization. However, communication in this time period between `business.remove_member`, and now could be described as a [conflict cycle](https://www.chadleyzobolastherapy.com/blog/the-cycle-why-couples-fight-from-an-eft-lens) where attempts to avoid conflict by one side have the opposite reaction and can perpetuate the cycle. While both sides share some similar goals and objectives, the built-up tension, lack of trust, and unclear communications prevented closure or repair.

Various grievances around how things unfolded would be added. The talks for resolution were counterproductive, and they ultimately pushed both parties further apart.

From this point forward, communication or requests/attempts to “restore all access” are interpreted by Ruby Central as including production access and therefore as attempts to reverse off-boarding measures and effectively take control of the service. From the point of view of those removed, Ruby Central had just kicked them out for a second time; whether the specific mechanics involved were intended or not wasn’t important, or wasn’t even believable, given the earlier hiding of motivations.

**September 18, 2025, 23:21:19 UTC**  taken by `colby-swandale`

- org.invite\_member: `martinemde`

Colby responded to Marty’s earlier message by inviting Martin back to the organization. He then requested more details from Marty and was asked to pause the task. Martin would have received the invitation at 4:21 pm (16:21) his local time.

**September 18, 2025, 23:31:42 UTC** taken by `paracycle`

- team.remove\_member(s): `rubygems/maintainers`

These changes were based on the previously stated risk that someone would add offboarded members back unexpectedly. Other changes were made based on inactivity.

Ellen Dash, `duckinator`, lost admin access to repositories in the `github.com/rubygems` organization due to removal from `rubygems/maintainers`. In addition, four other members were removed from the `rubygems/maintainers` team with the most recent commits to the `github.com/rubygems` organization in 2022, 2021, 2018, and 2016 (due to inactivity).

Notably, Josef Šimánek, `simi,` retained `rubygems/maintainers` team membership at this time.

**September 18, 2025 23:35:15 UTC**  by `hsbt`

- org.cancel\_invitation: `martinemde`

**September 18, 2025, 23:38:02 UTC**  by `paracycle`

- team.remove\_member(s): `rubygems/infrastructure`
- team.remove\_member(s): `rubygems/rubygems-org`
- team.remove\_member(s): `rubygems/rubygems-org-deployers`
- team.remove\_member(s): `rubygems/security`

The `rubygems/rubygems-org-deployers` team gates access to deploy RubyGems.org via Shipit. The `rubygems/rubygems-org` team gates access to the [RubyGems.org](http://Rubygems.org) admin panel. Users with admin access to that panel have significant capabilities such as: modifying owners on gems, blocking users, yanking gems, resetting credentials, managing feature flags, running arbitrary SQL queries, and running maintenance tasks.

All of these team-level access changes affected a total of fifteen developers, including `duckinator`. Aside from `duckinator,` who had been recently active in 2025, most changes were made due to inactivity. The remaining fourteen developers last contributed to `github.com/rubygems` in the year:

- 2022 (3 developers)
- 2021 (3 developers)
- 2019 (1 developer)
- 2018 (1 developer)
- 2016 (3 developers)
- 2015 (1 developer)
- Never, zero commits (2 developers)

You can see a list of the [`github.com/rubygems`](http://github.com/rubygems) organization members and their activity levels in Mike McQuaid’s post, [RubyGems Contribution Data with Homebrew's Tooling](https://mikemcquaid.com/rubygems-contribution-data-with-homebrews-tooling/) (September 24, 2025).

**September 19th, 2025 1:53:25 UTC**  by `hsbt`

- org.invite\_member: `deivid-rodriguez`

While most access changes have been about removal, the access of `deivid-rodriguez` has been consistently increased. However, removal from an organization cannot be reversed; you must re-invite them, and they must accept. Deivid was invited back again.

**September 19, 2025, 5:01:10 UTC**  by `hsbt`

- repo.remove\_member `rubygems/bundler-site`

This included one bot and three developers who last contributed to the bundler site in 2023, 2020, and 2016\.

**September 19, 2025, 8:59:40 UTC** by `hsbt`

- org.remove\_member: `duckinator`

This was the last organization removal via Ruby Central.

At this time, `simi` retained access, but the rest of **the maintainers** are no longer in the organization. None of those affected were contacted with an explanation of why the changes had been made.

**September 19, 2025**

- One of the earliest timestamps of a [social post linking](https://narrativ.es/@janl/115230600677063843) to "Ruby Central's Attack on RubyGems" (originally posted Sep 19, 2025, 05:57 AM CST and updated over time)
- [Wayback link to "Ruby Central's Attack on RubyGems"](https://web.archive.org/web/20250701000000*/https://pup-e.com/goodbye-rubygems.pdf).

The first public description of the incident is published by `duckinator`, though they did not yet name a concrete group or adopt the label **the maintainers**. At the time, Ruby Central had not delivered any description of the situation internally beyond those who played a part in it directly.

Ruby Central found itself in a similar situation to the September 10th, 2025, enterprise/business access changes, where they struggled to explain their motivations without discussing personnel matters. Later that day, Ruby Central would release a [blog post](https://rubycentral.org/news/strengthening-the-stewardship-of-rubygems-and-bundler/) that did not directly address the `duckinator` sequence of events laid out or the “takeover” claims.

A key point in the post said:

> *“In the near term we will temporarily hold administrative access to these projects \[...\].”*

Ruby Central would be unable to return any of the administrative access (or any access) to **the maintainers** without their participation. At this time, there have been two invitations delivered, and one canceled, which leaves one outstanding (`deivid-rodriguez`). Zero invitations have been accepted. In addition, Ruby Central would not relinquish administrative access to the `github.com/rubygems` organization.

In this time period, there were public blog posts by many of **the maintainers**. There were limited and sporadic private communications. Like before, these conversations were unproductive at best, counterproductive at worst. Ruby Central would not be restoring access controls to their state prior to September 10th, and **the maintainers** would not accept anything less.

**September 23, 2025, 20:28:03 UTC** by `simi`

- org.remove\_member: `simi`

This removal of `simi` was self-imposed as a protest after continued talks proved to be unproductive. Prior to this time, none of his access had been changed by Ruby Central.

**September 24, 2025 1:07:58 UTC** by `hsbt`

- org.cancel\_invitation: `deivid-rodriguez`

Deivid indicated in Slack that he would not be accepting the invitation, so it was canceled. The sentiment inside of Ruby Central was that they had “walked away.” This was later validated by a conversation with one of **the maintainers**.

> *“just reflecting a bit, I’m a little surprised you didn’t know that we all walked out on \[Ruby Central\]. That’s the whole situation. This was “you f\[...\]d up that bad and you want us to come groveling back to you, no” \[January 2, 2026\]”.*

As of September 24, two of the original community owners retained organization controls: `hsbt` and `colby-swandale`. Two added members, the Ruby Central Director of Open Source, `mghaught,` and a then Ruby Central Board member, `paracycle`, retained control on behalf of Ruby Central. None of **the maintainers** had membership in the `github.com/rubygems` organization nor any outstanding invitations.

Ufuk’s access was later passed to another board member when he left the Ruby Central board.

## Conclusion

Some execution failures and mistakes are individual, but the purpose of having a foundation and having an institution is that it can rise above individual limitations and provide robust, fault-tolerant systems. Therefore, these are our mistakes, collectively. And collectively we'll learn from them, but only if we face what happened, what we meant to do, and where we fell short.

The hope is that by sharing this, we can provide some closure to the community and increase transparency. It's also been a time to reflect internally and understand deeper issues that led up to this situation. You've likely been witness to some effects of this process, even if they seem mundane or unrelated. We have been going through a period of structural change, and that process will continue. It will not happen overnight. We want to face this and learn from it. You're welcome to judge us by our actions, and we hope you keep [calling us in](https://www.schneems.com/2025/12/19/non-violent-comments-calling-out-or-calling-in/) and calling us out when we don't live up to expectations.

