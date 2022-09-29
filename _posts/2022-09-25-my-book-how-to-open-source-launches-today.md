---
title: "My book 'How to Open Source' launches today!"
layout: post
published: true
date: 2022-09-26
permalink: /2022/09/26/my-book-how-to-open-source-launches-today/
image_url: https://howtoopensource.dev/images/HTOS_OG_book.png
categories:
    - open source
---


Today is the day. *How to Open Source* is now available for purchase at [howtoopensource.dev](https://howtoopensource.dev). As a reader of my blog, you can take $5 off with the discount code `opensource5`. Plus, purchase of the book will come with an invitation to join a **private Slack community**. You will get me as your open source coach (think writing coach and personal trainer!), watch me break down problems live, and have your questions answered so you can get your PRs merged.

<p><strong>Launch week:</strong>
<span class="countdown">[Calculating time...]</span> to claim access to <a href="https://howtoopensource.dev/#join_me_hacktoberfest">the Slack group</a>.</p>

<script type="text/javascript">
function countdownTimer() {
  // YYYY-MM-DDTHH:mm:ss.sssZ
  const deadlineUtc = new Date("2022-10-01T05:00:00.000-00:00");
  const now = new Date();
  const difference =  deadlineUtc - now;
  let remaining = "Time's up!";

  if (difference > 0) {
    const parts = {
      days: Math.floor(difference / (1000 * 60 * 60 * 24)),
      hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
      minutes: Math.floor((difference / 1000 / 60) % 60),
      seconds: Math.floor((difference / 1000) % 60),
    };
    remaining = Object.keys(parts).map(part => {
    return `${parts[part]} ${part}`;
    }).join(" ");
    remaining = `${remaining} left`
  }

  collection = document.getElementsByClassName("countdown");
  for (it of collection) {
    it.innerHTML = remaining;
  }
}

countdownTimer();
setInterval(countdownTimer, 1000);

</script>

<div align="center" >
  <a href="https://howtoopensource.dev">
    <img alt="book cover" style="" src="https://howtoopensource.dev/images/cover-email.png" />
  </a>
<p>
<a href="https://howtoopensource.dev" style="background-color: rgb(0, 123, 255);
background-image: linear-gradient(122deg, rgb(253, 55, 142) 0%, rgb(229, 69, 149) 100%);
border-bottom-color: rgb(255, 255, 255);
border-bottom-left-radius: 3px;
border-bottom-right-radius: 3px;
border-bottom-style: none;
border-bottom-width: 0px;
border-image-outset: 0;
border-image-repeat: stretch;
border-image-slice: 100%;
border-image-source: none;
border-image-width: 1;
border-left-color: rgb(255, 255, 255);
border-left-style: none;
border-left-width: 0px;
border-right-color: rgb(255, 255, 255);
border-right-style: none;
border-right-width: 0px;
border-top-color: rgb(255, 255, 255);
border-top-left-radius: 3px;
border-top-right-radius: 3px;
border-top-style: none;
border-top-width: 0px;
box-shadow: rgba(0, 0, 0, 0.3) 0px 9px 32px 0px;
box-sizing: border-box;
color: rgb(255, 255, 255);
display: inline-block;
font-family: 'Rubik', sans-serif;
font-size: 14px;
font-weight: 500;
line-height: 21px;
padding-bottom: 11.2px;
padding-left: 25.6px;
padding-right: 25.6px;
padding-top: 11.2px;
text-align: center;
text-decoration-color: rgb(255, 255, 255);
text-decoration-line: none;
text-decoration-style: solid;
text-decoration-thickness: auto;
text-transform: uppercase;
touch-action: manipulation;
transition-delay: 0s;
transition-duration: 0.3s;
transition-property: all;
transition-timing-function: ease;
user-select: none;
vertical-align: middle;
white-space: nowrap;
margin-top: 1.5rem;
">Buy the Book</a>

</p>
</div>


I shared a pre-release copy of the book with some community members, and here’s what they thought of the book:

>  "Richard is a rare voice in the open source community: skilled and experienced, but also empathetic, caring and welcoming. If you're venturing into the open-source bazaar, let Richard be your guide." - **Nate Berkopec, Maintainer of Puma webserver**

> "Richard does an excellent job of balancing the why of contributing to open source, with the how. This book will help you overcome common challenges folks face when navigating open source projects. If you find yourself on the other side of the table in the future, it will serve as a guide for how to make your project more welcoming to others. This book may be intended for those who already know how to code but is a useful read for anyone with a keen interest in open source." - **Anna Tumadóttir, Chief Operating Officer at Creative Commons**

> "How To Open Source provides practical, real world examples of getting started in Open Source. This book is a must read for anyone that wants to get started in the open source world." - **Aaron Patterson, Ruby core contributor & cat owner**

There’s no cap to the private Slack group, but both the `opensource5` discount code and the Slack invite are [limited-time offers for the book launch](https://howtoopensource.dev#join_me_hacktoberfest). They expire Friday, Sep 30, at [midnight (CST)](https://howtoopensource.dev#join_me_hacktoberfest).
