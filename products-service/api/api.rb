require 'grape'
class API < Grape::API
  format :json

  get '/' do
    'Hello World'
  end
end