---
title: "Rails 5.2 Active Storage: Previews, Poppler, and Solving Licensing Pitfalls"
layout: post
published: true
date: 2018-05-11
permalink: /2018/05/11/rails-52-active-storage-previews-poppler-and-solving-licensing-pitfalls/
categories:
    - ruby
    - tutorial
    - example app
    - active storage
---

Rails 5.2 was just released last month with a major new feature: Active Storage. Active Storage provides file uploads and attachments for Active Record models with a variety of backing services (like AWS S3). While libraries like [Paperclip](https://github.com/thoughtbot/paperclip) exist to do similar work, this is the first time that such a feature has been shipped with Rails. At Heroku, we consider cloud storage a best practice, so we've ensured that it works on our platform. In this post, we'll share how we prepared for the release of Rails 5.2, and how you can deploy an app today using the new Active Storage functionality.

## Trust but Verify

At Heroku, trust is our number one value. When we learned that Active Storage was shipping with Rails 5.2, we began experimenting with all its features. One of the nicest conveniences of Active Storage is its ability to preview PDFs and videos. Instead of linking to assets via text, a small screenshot of the PDF or Video will be extracted from the file and rendered on the page.

The beta version of Rails 5.2 used the popular open source tools FFmpeg and MuPDF to generate video and PDF previews. We vetted these new binary dependencies through both our security and legal departments, where we found that MuPDF licensed under AGPL and requires a commercial license for some use. Had we simply added MuPDF to Rails 5.2+ applications by default, many of our customers would have been unaware that they needed to purchase MuPDF to use it commercially.

The limiting AGPL license was brought to [public attention](https://github.com/rails/rails/pull/30667#issuecomment-332276198) in September 2017. To prepare for the 5.2 release, our engineer [Terence Lee](https://twitter.com/hone02) worked to update Active Storage so that this PDF preview feature could also use an open-source backend without a commercial license. We opened a PR to Rails [introducing the ability to use poppler PDF as an alternative to MuPDF](https://github.com/rails/rails/pull/31906) in February of 2018. The PR was merged roughly a month later, and now any Rails 5.2 user - on or off Heroku - can render PDF previews without having to purchase a commercial license.

> This post was originally published [on the Heroku blog](https://blog.heroku.com/rails-active-storage)

## Active Storage on Heroku Example App

If you've already got an app that implements Active Storage you can [jump over to our DevCenter documentation on Active Storage](https://devcenter.heroku.com/articles/active-storage-on-heroku?preview=1).

Alternatively, you can use our example app. Here is a Rails 5.2 app that is a digital bulletin board allowing people to post videos, pdfs, and images. You can [view the source on GitHub](https://github.com/heroku/active_storage_with_previews_example) or deploy the app with the Heroku button:

<a href="https://heroku.com/deploy?template=https://github.com/heroku/active_storage_with_previews_example">
  <img src="https://www.herokucdn.com/deploy/button.svg" alt="Deploy">
</a>

> Note: This example app requires a paid S3 add-on.

Here's a video example of what the app does.

![](https://www.dropbox.com/s/nxnsidob5j8bwev/active-storage.gif?raw=1)

When you open the home page, select an appropriate asset, and then submit the form. In the video, the `mp4` file is uploaded to S3 and then a preview is generated on the fly by Rails with the help of `ffmpeg`. Pretty neat.

## Active Storage on Heroku

If you deployed the example app using the button, it's already configured to work on Heroku via the `app.json`, however if you've got your own app that you would like to deploy, how do you set it up so it works on Heroku?

Following the [DevCenter documentation for Active Storage](https://devcenter.heroku.com/articles/active-storage-on-heroku?preview=1), you will need a file storage service that all your dynos can talk to. The example uses a Heroku add-on for S3 called [Bucketeer](https://elements.heroku.com/addons/bucketeer), though you can also use existing S3 credentials.

To get started, add the AWS gem for S3 to the Gemfile, and if you’re modifying images as well add Mini Magick:

```ruby
gem "aws-sdk-s3", require: false
gem 'mini_magick', '~> 4.8'
```

Don't forget to `$ bundle install` after updating your Gemfile.

Next up, add an `amazon` option in your `config/storage.yml` file to point to the S3 config, we are using config set by Bucketeer in this example:

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV['BUCKETEER_AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['BUCKETEER_AWS_SECRET_ACCESS_KEY'] %>
  region: <%= ENV['BUCKETEER_AWS_REGION'] %>
  bucket: <%= ENV['BUCKETEER_BUCKET_NAME'] %>
```

Then make sure that your app is set to use the `:amazon` config store in production:

```ruby
config.active_storage.service = :amazon
```

If you forget this step, the default store is to use `:local` which saves files to disk. This is not a scalable way to handle uploaded files in production. If you accidentally deploy this to Heroku, it will appear that the files were uploaded at first, but then they will disappear on random requests if you're running more than one dyno. The files will go away altogether when the dynos are restarted. You can get more information about [ephemeral disk of Heroku in the DevCenter](https://devcenter.heroku.com/articles/active-storage-on-heroku?preview=1#ephemeral-disk).

Finally, the last thing you'll need to get this to work in production is to install a custom buildpack that installs the binary dependencies `ffmpeg` and `poppler` which are used to generate the asset previews:

```sh
$ heroku buildpacks:add -i 1 https://github.com/heroku/heroku-buildpack-activestorage-preview
```

Once you’re done you can deploy to Heroku!

## Adding Active Storage to an Existing App

If your app doesn't already have Active Storage, you can add it. First, you'll need to enable Active Storage blob storage by running:

```sh
$ bin/rails active_storage:install
```

This will add a migration that lets Rails track the uploaded files.

Next, you'll need a model to "attach" files onto. You can use an existing model, or create a new model. In the example app a mostly empty `bulletin` model is used:

```sh
$ bin/rails generate scaffold bulletin
```

Next, run the migrations on the application:

```sh
$ bin/rails db:migrate
```

After the database is migrated, update the model to let Rails know that you intend to be able to attach files to it:

```ruby
class Bulletin < ApplicationRecord
  has_one_attached :attachment
end
```

Once that's done, we will need three more pieces: a form for uploading attachments, a controller to save attachments, and then a view for rendering the attachments.

If you have an existing form you can add an attachment field via the `file_field` view helper like this:

```erb
    <%= form.file_field :attachment %>
```

You can see an example of a form with an attachment in [the example app](https://github.com/heroku/active_storage_with_previews_example/blob/ab0370f77f35f8eb0813727b8d49758926450f5e/app/views/welcome/_upload.html.erb#L14). Once you have a form, you will need to save the attachment.

In this example app, the home page contains the form and the view. In the [bulletin controller](https://github.com/heroku/active_storage_with_previews_example/blob/ab0370f77f35f8eb0813727b8d49758926450f5e/app/controllers/bulletins_controller.rb#L26-L32) the attachment is saved and then the user is redirected back to the main bulletin list:

```ruby
def create
  @bulletin = Bulletin.new()
  @bulletin.attachment.attach(params[:bulletin][:attachment])
  @bulletin.save!

  redirect_back(fallback_location: root_path)
end
```

Finally, in the [welcome view](https://github.com/heroku/active_storage_with_previews_example/blob/ab0370f77f35f8eb0813727b8d49758926450f5e/app/views/welcome/index.erb) we iterate through each of the bulletin items and, depending on the type of attachment we have, render it differently.

In Active Storage the `previewable?` method will return true for PDFs and Videos provided the system has the right binaries installed. The `variable?` method will return true for images if `mini_magick` is installed. If neither of these things is true then, the attachment is likely a file that is best viewed after being downloaded. Here's [how we can represent that logic](https://github.com/heroku/active_storage_with_previews_example/blob/ab0370f77f35f8eb0813727b8d49758926450f5e/app/views/welcome/index.erb#L24-L37):

```erb
<ul class="no-bullet">
  <% @bulletin_list.each do |bulletin| %>
    <li>
      <% if bulletin.attachment.previewable? %>
        <%= link_to(image_tag(bulletin.attachment.preview(resize: "200x200>")),  rails_blob_path(bulletin.attachment, disposition: "attachment"))
        %>
      <% elsif bulletin.attachment.variable? %>
        <%= link_to(image_tag(bulletin.attachment.variant(resize: "200x200")), rails_blob_path(bulletin.attachment, disposition: "attachment"))%>
      <% else %>
        <%= link_to "Download file", rails_blob_path(bulletin.attachment, disposition: "attachment") %>
      <% end %>
    </li>
  <% end %>
</ul>
```

Once you've got all these pieces in your app, and configured Active Storage to work in production, your users can enjoy uploading and downloading files with ease.