---
layout: post
title: "Who Does your Gem Work For?"
date: 2015-09-30
published: true
author_name: Richard Schneeman
author_url: https://ruby.social/@Schneems
permalink: blogs/2015-09-30-reverse-rubygems
---
Have you ever wondered who out there is using a gem? Now there's an easy way.

Rubygems.org has a reverse dependencies API endpoint that's [documented here](https://guides.rubygems.org/rubygems-org-api/#get---apiv1gemsgem-namereversedependenciesjson). I wrote a simple Ruby script that finds all the reverse dependencies of a gem, and then weighs them by total downloads.

To get all the gems that depend on Sprockets you could run this:

```ruby
require 'net/http'
require 'json'

gem_name = "sprockets"

def rubygems_get(gem_name: "", endpoint: "")
  path = File.join("/api/v1/gems/", gem_name, endpoint).chomp("/") + ".json"
  uri      = URI(File.join('https://rubygems.org', path))
  response = Net::HTTP.get_response(uri)
  JSON.parse(response.body)
end

results = rubygems_get(gem_name: gem_name, endpoint: "reverse_dependencies")

weighted_results = {}
results.each do |name|
  begin
    weighted_results[name] = rubygems_get(gem_name: name)["downloads"]
  rescue => e
    puts "#{name} #{e.message}"
  end
end

weighted_results.sort {|(k1, v1), (k2, v2)| v2 <=> v1 }.first(50).each_with_index do |(k, v), i|
  puts "#{i}) #{k}: #{v}"
end
```

Why would you want to see what gems depend on a specific gem? I used this technique when the [mime-types gem got some huge memory savings](https://github.com/mime-types/ruby-mime-types/pull/96#issuecomment-101376539). We wanted consumers of the `mime-types` gem to update their libraries to take advantage of the savings. I opened pull requests for the top few gems.

You could use this to proactively reach out to other libraries to test out a pre-release of a gem. You could ask other library authors for feedback on an issue or a PR. Having a context around the ways that people use a library can help library maintainers to make better decisions and cause less headaches.

In the sprockets case, I was curious in how the major gems consume sprockets. I have some ideas on ways I can refactor sprockets internals to make it easier to work with, but I want to verify no one is using an edge case of one of the existing APIs. If you were wondering here's the list of all the gems that have ever dependend on sprockets:

```
0) actionpack: 50617186
1) sass-rails: 25637705
2) coffee-rails: 23370104
3) sprockets-rails: 15753940
4) simplecov-html: 11837362
5) compass-rails: 4425410
6) rails_serve_static_assets: 2864702
7) less-rails: 2446260
8) turbo-sprockets-rails3: 1299855
9) mailcatcher: 960752
10) handlebars_assets: 911169
11) sprockets-sass: 835099
12) middleman: 812834
13) roadie: 700814
14) haml_coffee_assets: 579639
15) cells: 571855
16) sprockets-helpers: 548555
17) gmaps4rails: 533378
18) bare_coffee: 531122
19) sidekiq-failures: 522648
20) middleman-sprockets: 504927
21) konacha: 376161
22) jasmine-headless-webkit: 311860
23) angular-rails-templates: 285348
24) middleman-more: 173457
25) hogan_assets: 159946
26) dashing: 143784
27) hamlbars: 137658
28) css_splitter: 133981
29) alchemy_cms: 124143
30) awestruct: 115661
31) bonethug: 88604
32) jekyll-assets: 86496
33) architecture-js: 86376
34) opal: 82256
35) trackman: 81761
36) sprockets-coffee-react: 80704
37) ruby-haml-js: 80659
38) stylus: 76422
39) rails-sass-images: 74455
40) sprockets-commonjs: 73804
41) fanforce-plugin-factory: 73218
42) alula: 66519
43) browserify-rails: 66436
44) sinatra-asset-pipeline: 64899
45) jquery.fileupload-rails: 64737
46) gumdrop: 64294
47) massimo: 63938
48) fanforce-app-factory: 62385
49) smt_rails: 61075
```

It's not perfect, but it's good enough for my needs.

---

Richard blogs here and tweets [@schneems](https://ruby.social/@Schneems), you should follow him because it's his birthday.
