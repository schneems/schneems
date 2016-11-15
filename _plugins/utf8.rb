# module Jekyll
#   module Commands
#     class Serve

#       class << self
#         alias :_original_webrick_options :webrick_options
#       end

#       def self.webrick_options(config)
#         options = _original_webrick_options(config)
#         options[:MimeTypes].merge!({'html' => 'text/html; charset=utf-8'})
#         options[:MimeTypes].merge!({'xml'  => 'text/xml; charset=utf-8'})
#         options
#       end

#     end
#   end
# end
