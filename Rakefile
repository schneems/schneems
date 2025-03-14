task "assets:precompile" do
  exec("jekyll build --trace")
  raise "failed" unless $?.success?
end

# Monkeypatch for debugging
# module Sprockets
#   module HTTPUtils
#     def find_best_mime_type_match(q_value_header, available)
#       find_best_q_match(q_value_header, available) do |a, b|
#         match_mime_type?(a, b)
#       end
#     end
#   end
# end
