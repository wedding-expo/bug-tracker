require 'sinatra'
require 'redis'
require 'json'
require 'http'

enable :sessions
redis = Redis.new

# login
get '/' do
	if session.has_key? 'token' then redirect to('/dashboard')
	else erb :login, layout: nil end
end

post '/' do
	response = HTTP.post('https://admin.winecountrybride.com/sessions.json', json: {email: params[:email], password: params[:password]})
	if response.status.code == 200
		json = JSON.parse response.body
		session['token'] = json['token']
		redirect to('/dashboard')
	else
		redirect to('/')
	end
end

post '/logout' do
	session.clear
	redirect to('/')
end

before /\/.+/ do
	unless session.has_key? 'token' then redirect to('/') end
end

get '/dashboard' do
	erb :dashboard
end

# bugs
get '/bugs' do
	@bugs = redis.smembers('bug:keys').map { |k| redis.hgetall("bug:#{k}").merge('id' => k) }
	erb :bugs
end

get %r{^/bugs/([0-9]+)/?$} do |id|
	@bug = redis.hgetall("bug:#{id}").merge('id' => id)
	erb :bug
end

get '/bugs/new' do
	erb :new_bug
end

post '/bugs' do
	key = redis.incr 'bug:max'
	redis.hmset "bug:#{key}", :title, params['title'], :type, params['type']
	redis.sadd 'bug:keys', key
	redirect to('/bugs')
end