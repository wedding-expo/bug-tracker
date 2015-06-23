require 'sinatra'
require 'redis'
require 'json'
require 'http'

enable :sessions
redis = Redis.new

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

before '/dashboard' do
	unless session.has_key? 'token' then redirect to('/') end
end

get '/dashboard' do
	erb :dashboard
end

#bugs
get '/bugs' do
		@bugs = redis.smembers('bug:keys').map { |k| redis.hgetall "bug:#{k}" }
	erb :bugs
end

post '/bugs' do
	json = JSON.parse(request.body.read)
	title = json['bug']['title']
	type = json['bug']['type']
	key = redis.incr 'bug:max'
	redis.hmset "bug:#{key}", :title, title, :type, type
	redis.sadd 'bug:keys', key
end