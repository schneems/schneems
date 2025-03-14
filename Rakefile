task "assets:precompile" do
  exec("jekyll build --trace")
  raise "failed" unless $?.success?
end
