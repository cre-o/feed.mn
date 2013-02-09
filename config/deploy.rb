# Подключаем необходимые библиотеки
require 'rvm/capistrano'         # Для работы RVM
require 'bundler/capistrano'     # Для работы Bundler
require 'capistrano/nginx/tasks' # Для работы Nginx

################
# Разные опции #
################
ssh_options[:forward_agent] = true # Для авторизации по ssh-ключам
default_run_options[:pty]   = true # Для настройки Nginx

######################
# Настройки серверов #
######################
set :user,                "astronz"         # Имя пользователя на сервере
set :server_master_host,  "feed.mn"      # Боевой сервер

# Для авторизации на сервере через ssh-ключ
set :server_master, "#{user}@#{server_master_host}"

### Для staging переопределяем настройки ###
set :branch, "master"
set :rails_env, "production"
set :server_name, "feed.mn"
server server_master, :web, :app, :db, primary: true

# Настройки для Nginx
set :sudo_user,           "astronz"

########################
# Настройки приложения #
########################
set :application,     "feedmn"                              # Название приложения
set :deploy_to,       "/home/#{user}/www/#{application}"      # Каталог приложения
set :use_sudo,        false                                   # Не используем sudo
set :bundle_dir,      File.join(fetch(:shared_path), 'gems')  # Каталог для гемов
set :bundle_without,  [:development, :test]                   # Не устанавливать пакеты для разработки и тестирования

#########################
# Настройки репозитория #
#########################
set :scm,                   :git                                  # Используем git
set :repository,            "git@github.com:astronz/feed.mn.git"  # Путь до репозитория
set :deploy_via,            :remote_cache                         # Используем кэш
set :git_enable_submodules, true                                  # Включаем поддержку sub-модулей

#################
# Настройки RVM #
#################
set :rvm_ruby_string,   '1.9.3-p362@feedman'                              # Какая версия Ruby и какой gemset будем использовать
set :rvm_type,          :user                                             # Если RVM установлен глобально, то стоит указать :system
set :bundle_cmd,        "rvm use #{rvm_ruby_string} do bundle"            # Используем RVM для запуска bundle
set :rake,              "rvm use #{rvm_ruby_string} do bundle exec rake --trace"  # Используем RVM для запуска rake


#####################
# Настройки Unicorn #
#####################
set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"   # Путь до конфига Unicorn
set :unicorn_pid,  "#{deploy_to}/shared/pids/unicorn.pid"     # Где храним PID-файл Unicorn


#################
# Все остальное #
#################

############
# Триггеры #
############
before "deploy:setup",                "rvm:install_rvm", "rvm:install_ruby"   # Устанавливаем RVM и Ruby
after "deploy:setup",                 "nginx:setup", "nginx:reload"           # Настраиваем и перезапускаем Nginx

after "deploy",               "deploy:cleanup"                        # Храним только 5 последних релизов

#####################
# Задачи capistrano #
#####################

# Команды управления Unicorn
namespace :deploy do
  desc "Restart Unicorn"
  task :restart do
    run "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{current_path} && rvm use #{rvm_ruby_string} do bundle exec unicorn -c #{unicorn_conf} -E #{rails_env} -D; fi"
  end

  desc "Start Unicorn"
  task :start do
    run "cd #{deploy_to}/current && rvm use #{rvm_ruby_string} do bundle exec unicorn -c #{unicorn_conf} -E #{rails_env} -D"
  end

  desc "Stop Unicorn"
  task :stop do
    run "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
  end

  desc "Copy ssh-key to server"
  task :copy_ssh_key_to_server do
    run "cat ~/.ssh/feedman.pub | ssh #{user}@#{server_name} 'cat >> ~/.ssh/authorized_keys'"
  end
end

# Разворачивание БД
namespace :db do
  desc "Run rake db:setup"
  task :setup, :roles => :db do
    run "cd #{current_path} && rvm use #{rvm_ruby_string} do bundle exec rake RAILS_ENV=#{rails_env} db:setup"
  end
  desc "Run rake db:seed"
  task :seed, :roles => :db do
    run "cd #{current_path} && rvm use #{rvm_ruby_string} do bundle exec rake RAILS_ENV=#{rails_env} db:seed"
  end
end

#################
# Разные методы #
#################

# Проверка на существование файла или директории
def remote_file_exists?(full_path)
  'true' == capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
end
