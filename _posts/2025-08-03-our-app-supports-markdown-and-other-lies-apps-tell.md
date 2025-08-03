---
title: ""Our app supports Markdown" and other lies apps tell"
layout: post
published: true
date: 2025-08-03
permalink: /2025/08/03/our-app-supports-markdown-and-other-lies-apps-tell/
image_url: <replaceme>
categories:
    - rant
---

I'll make this plain and simple: If your app does not let me read back, the character-for-character raw text I put into the editor, it does NOT support markdown. 

Let's set the scene: Our protagonist is burning the midnight oil. They've got a great idea for an open source RFC, but they want to do some due-diligence first with some co-workers so they open up their employee encouraged document sharing solution, Slack Canvas and write a beautiful bit of carefully annotated markdown. It looks ... mostly right (why on earth do H3s look nearly identical to H2??) but it's good enough. They got some great feedback, made some edits and now it's time to go contribute to the great commons we call open source. They select all (CMD+a), they copy the text (CMD+c), they paste it into GitHub and hit enter. Slowly the blood drains from their face. It's all gone. All the backticks, all the bolds, all the links. It kinda looks like the original document, but is quietly, subtly, horrifically mangled.

In desperation, they reach first for the `Edit` menu, then `File`. Flashes of the crappy [https://quip.com/](https://quip.com/) markdown export feature flash through their memory. It had it's own problems, but at least it was there. Silence covers the room. An almost imperceptible evil laugh of Google doc's bastardized markdown support can be heard of the dawning realization: the app takes markdown synatax in. But it devours it. Destroys it. Vomiting rich text in in the place of where carefully currated backticks and astericks once shone brightly. The document is dead. Our hero weeps.

The whole point of markdown (as witnessed and confirmed in my headcannon as a developer since 2006) is that it provides a format that can be consumed as EITHER rendered text, OR as plain text. Markdown is not a format for styling a text document, it is a format that requires that the writer, can read the original text (not literally, you pedants, there's not exactly a spec that says that, but perhaps there should be). Without this guarantee we get a sea of "almost markdown" formats. We are mark-drowning in them. They all behave slightly differently. For apps that do a decently good job of letting developers "read your write" there's product-driven feature's like Notion's desire to embed rich objects such as spreadsheets and to add custom inter-notion document linking syntax that encourage users to subtly poison the portability of their original text. 

I don't begrudge them extending the syntax to meet their needs, but wish an export story was better thought out. Perhaps rich objects should be supported via iframes and exporting documents to markdown should support some kind of a "deep" export (i.e. it doesn't matter if the markdown it exports is perfect, if it links to a bunch of gated and internal documents. Such thoughts probably get your cyber-security sense tingling (as they should) and likely bore investors and product managers to tears, therefore it's a usecase that is sorely neglected given the millions/billions of dollors of "innovation" in the "markdown as a shared mangled RTF doc" apps that we're collectively burried under.

So forget "hard mode" all I'm asking for is simple. If you take markdown in, you should allow me to take my original markdown out **CHARACTER FOR CHARACTER**. So far the best tools I've found for this are: Vim, GitHub, and [Obsidian](https://obsidian.md/). (Yes, your favorite IDE too). These are all hacker tools, but why can't we live in a world where ALL tools respect our input enough to let us read it back? Perhaps you've been toiling like our hero. These document inflicted wounds aren't large, but they're never-ending. They create toil, and burn trust in tools. Perhaps like me, you've not had the words to enumerate what exactly is missing. Hopefully, now you do. If a company asks for some feedback, please let them know that to "read my markdown write" is a fundamental and inalienable right.

## Special bonus rant: Please add a newline after your markdown headers

Oh and while I'm ranting. I beg of you, please (please, please, please, please) add a newline after markdown headers. I.e. Don't do this:

```
## I really don't like when
People do this. Hard to read.
```

Instead, please do this:

```
## Everyone who does this is amazing

They are the coolest people I know.
```

Why? Remember when I said markdown was supposed to optimize for rendering and plain text? When someone is reading your plain text, the first example without the vertical whitespace provides no visual pause. It's notexactlythesamethingasreadingasentencewithnospaces. But you get how important white space can be when it comes to reading and comprehension speed. Yes, your favorite markdown (and markdown-ish) tools will render both of them the same, but to someone not viewing those docs in that same tool, they will appreciate you and star your github repos more and other vauge promises of things developers presumably want.

For some reason, I don't entirely comprehend, the first style is much more popular on GitHub. To the point that the vast majority of LLM produced markdown does not have vertical whitespace after headers. We're in a world now where "do what I do" (as opposed to do as I say) is fed back to us one token at a time. We might be past the point of no-return when it comes self-reinforcing behavior (as AI is now trained on the output that developers are committing as their own), but when skynet takes over and you're looking for a shibboleth to prove you're not a robot with an Austrian accent, you might remember this post and send a PR with some glorious, human, hand-crafted markdown.

