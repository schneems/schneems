task "assets:precompile" do
  exec("jekyll build")
  raise "failed" unless $?.success?
end
