# encoding: utf-8
# Models
require './lib/url.rb'
# Application
class Feedmn < Sinatra::Base

  # Use rack flash
  use Rack::Flash
  # Load mongoid
  Mongoid.load!('./config/mongoid.yml', :production)

  # Configuration
  set :environment, :production
  if settings.environment == 'production'
    set :show_exceptions, false
  end

  set :sessions, true
  set :root, File.dirname(__FILE__)
  set :dump_errors, false

  set :views,  File.dirname(__FILE__) + '/views'
  set :slim, :pretty => true

  not_found do
    short = env["PATH_INFO"].match(/^\/\w+/).to_s[1..-1]
    url_any = Url.where(:short => short)
    if url_any.exists?
      external = url_any.first.url.match(/^(https?:\/\/)/) ? url_any.first.url : "http://#{url_any.first.url}"
      redirect external
    end
    send_file File.join(settings.public_folder, '404.html'), :layout => false
  end

  # Route Handlers
  get '/' do
    slim :index
  end

  post '/generate' do
    @url = Url.new(:url => params[:url])
    @url.short = generate_short
    if @url.save
      slim :generate
    else
      flash[:notice] = @url.errors
      redirect back
    end
  end

  get '/about' do
    slim :about
  end

  get '/policy' do
    slim :policy
  end

   helpers do
     def page_title(title)
       @title = title
     end

     # Short url generator
     def generate_short
       begin
       @short = if rand(1..2) == 1
                  rand(32**5).to_s(32).tap(&:upcase!)
                else
                  rand(32**5).to_s(32)
                end
       end until Url.where(:short => @short).blank? ; @short
     end

     def translate(what)
       translations = {
         "Url is too short (minimum is 4 characters)" => 'Адрес слишком короткий (минимум 4 символа)',
         "Url can't be blank" => 'Адрес не может быть пустым',
         "Url is too long (maximum is 800 characters)" => 'Адрес слишком большой (максимум 800 символов)',
         'Url is invalid' => 'К сожалению данный адрес Фидмэн укоротить не может'
       }

       if translations.has_key? what
         translations[what]
       else
         what
       end
     end
   end

end