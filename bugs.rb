require 'sinatra'
require 'redis'
require 'securerandom'
require 'json'

redis = Redis.new

get '/' do
	'This is the homepage.'
end