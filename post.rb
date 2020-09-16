#!/usr/bin/env ruby

# Generate a new jekyll blog post using prompts then place it in the _posts folder.

require 'active_support/inflector'

puts 'Enter the post title:'
title = gets.chomp
title.titleize

year = Time.now.strftime('%Y')
month = Time.now.strftime('%m')
day = Time.now.strftime('%d')

hyphen_date = "#{year.to_s}-#{month.to_s}-#{day.to_s}"
sanitized_title = title.downcase.gsub(/[^a-z0-9\s]/i, '')

dirty_slug = sanitized_title.split(' ')
clean_slug = []

dirty_slug.each do |s|
  clean_slug << s
  clean_slug << '-'
end

clean_slug.pop

final_slug = clean_slug.join('')

the_post_permalink = "/#{year}/#{month}/#{day}/#{final_slug}/"

# Create the _posts directory

system('mkdir', '_posts') unless File.exists?('_posts')

the_post_file_name = hyphen_date + '-' + final_slug.to_s + '.md'
the_post_file = File.new("_posts/#{the_post_file_name}", 'w')
the_post_file.puts('---')
the_post_file.puts("title: \"#{title}\"")
the_post_file.puts('layout: post')
the_post_file.puts('published: true')
the_post_file.puts("date: #{hyphen_date}")
the_post_file.puts("permalink: #{the_post_permalink}")
the_post_file.puts("image_url: <replaceme>")
the_post_file.puts('categories:')
the_post_file.puts("    - ruby")
the_post_file.puts('---')
the_post_file.puts('')
the_post_file.close

exec("$EDITOR _posts/#{the_post_file_name}")
