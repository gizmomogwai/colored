desc 'format sources'
task :format do
  sh 'find . -name "*.d" | xargs dfmt'
end

desc 'build docs'
task :docs do
  sh "dub build -b ddox"
end

task :default => [:format, :docs]
