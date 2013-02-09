deploy_to   = "/home/astronz/www/feedmn"
sinatra_root  = "#{deploy_to}/current"
pid_file    = "#{deploy_to}/shared/pids/unicorn.pid"
socket_file = "#{deploy_to}/shared/unicorn.sock"
log_file    = "#{sinatra_root}/log/unicorn.log"
err_log     = "#{sinatra_root}/log/unicorn_error.log"
old_pid     = pid_file + '.oldbin'

timeout 30
worker_processes 2 # Здесь тоже в зависимости от нагрузки, погодных условий и текущей фазы луны
working_directory sinatra_root
pid pid_file
stderr_path err_log
stdout_path log_file

listen socket_file, :backlog => 64
listen 8080, :tcp_nopush => true

# Мастер процесс загружает приложение, перед тем, как плодить рабочие процессы.
preload_app true

# Решительно не уверен, что значит эта строка, но я решил ее оставить.
# GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)


before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = "#{sinatra_root}/Gemfile"
end

before_fork do |server, worker|
  # Перед тем, как создать первый рабочий процесс, мастер отсоединяется от базы.
  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.connection.disconnect!

  # Ниже идет магия, связанная с 0 downtime deploy.
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end

end

after_fork do |server, worker|
  # После того как рабочий процесс создан, он устанавливает соединение с базой.
  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.establish_connection
end