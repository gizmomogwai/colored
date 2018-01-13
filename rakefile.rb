desc 'format sources'
task :format do
  sh 'find . -name "*.d" | xargs dfmt'
end

desc 'build docs'
task :docs do
  sh "dub build -b ddox"
end

desc 'prepare docs'
task :prepare_docs do
  sh "rm -rf docs"
  sh "git clone -b gh-pages git@github.com:gizmomogwai/colored.git docs"
end

task :default => [:format, :prepare_docs, :docs]
