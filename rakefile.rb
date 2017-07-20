desc 'format sources'
task :format do
  sh 'find . -name "*.d" | xargs dfmt'
end

task :default => [:format]