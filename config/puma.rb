threads_count = ENV.fetch('MAX_THREADS') { 5 }.to_i
threads threads_count, threads_count

if ENV['SOCKET'] then
  bind 'unix://' + ENV['SOCKET']
else
  port ENV.fetch('PORT') { 3000 }
end

if "development" == ENV.fetch("RAILS_ENV") { "development" }
  ssl_bind '0.0.0.0', '9292', {
    key: "/home/yowasou/ssl/server.key",
    cert: "/home/yowasou/ssl/server.crt",
    #ca: "/file_path/ca", # オレオレ証明書の場合は必要ないです／中間証明書が必要な場合は指定してください
    verify_mode: "none"
  }
end

environment ENV.fetch('RAILS_ENV') { 'development' }
workers     ENV.fetch('WEB_CONCURRENCY') { 2 }

preload_app!

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

plugin :tmp_restart
