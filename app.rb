# frozen_string_literal: true

require 'byebug'
require 'sinatra'
require 'active_record'
require 'securerandom'
require 'json'

set :bind, '0.0.0.0'
set :port, 3000

### Connecting to the database ###
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'database.sqlite3')

### Creating models of each table ###
# User model
class User < ActiveRecord::Base
  has_many :stores, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :products, through: :purchases, dependent: :destroy

  def as_json(*)
    super(except: %i[password api_token])
  end
end

# Store model
class Store < ActiveRecord::Base
  belongs_to :user
  has_many :products, dependent: :destroy
end

# Product model
class Product < ActiveRecord::Base
  belongs_to :store
  has_many :purchases
end

# Purchase model
class Purchase < ActiveRecord::Base
  belongs_to :user
  belongs_to :product
end
### END of models creation ###

# Validate if the token was sent and if a user exists with that token
def validate_token
  @api_token = request.env['HTTP_AUTHORIZATION']
  !@api_token.nil? && User.exists?(api_token: @api_token)
end

# Give the current user
def current_user
  @current_user ||= User.find_by(api_token: @api_token)
end

# Give a json with not authorized error
def user_not_authorized
  { error: 'Not authorized' }.to_json
end

before do
  if (request.request_method == 'POST') && (request.content_type == 'application/json')
    body_parameters = request.body.read
    parsed = body_parameters && body_parameters.length >= 2 ? JSON.parse(body_parameters) : nil
    params.merge!(parsed)
  end
end

get '/' do
  'Hello World!'
end

get '/users' do
  status 200
  body User.all.to_json
end

post '/sign_up' do
  @user = User.create(
    first_name: params[:first_name],
    last_name: params[:last_name],
    email: params[:email],
    password: params[:password],
    api_token: SecureRandom.hex
  )
  response = { api_token: @user.api_token }.to_json
  status 200
  body response
end

post '/sign_in' do
  @user = User.find_by(email: params[:email], password: params[:password])
  if @user
    @user.update(api_token: SecureRandom.hex)
    response = { api_token: @user.api_token }.to_json
    status 200
    body response
  else
    response = { error: 'The email or the password is incorrect' }.to_json
    status 422
    body response
  end
end

get '/sign_out' do
  if validate_token
    current_user.update(api_token: nil)
    status 200
    body ''
  else
    status 422
    body user_not_authorized
  end
end

get '/stores' do
  if validate_token
    status 200
    body Store.all.to_json
  else
    status 422
    body user_not_authorized
  end
end

post '/stores' do
  if validate_token
    current_user.stores.create(
      name: params[:name],
      description: params[:description],
      address: params[:address]
    )
    status 200
    body ''
  else
    status 422
    body user_not_authorized
  end
end

get '/stores/:id/products' do |id|
  if validate_token
    @store = Store.find(id)
    status 200
    body @store.products.to_json
  else
    status 422
    body user_not_authorized
  end
end

post '/stores/:id/products' do |id|
  if validate_token
    @store = current_user.stores.find(id)
    if @store
      @store.products.create(
        name: params[:name],
        description: params[:description],
        price: params[:price]
      )
      status 200
      body ''
    else
      status 422
      response = { error: 'The store with that id does not exist' }.to_json
    end
  else
    status 422
    body user_not_authorized
  end
end

post '/stores/:id/purchases' do |_id|
  if validate_token
    @group = current_user.purchases.count > 0 ? current_user.purchases.order(group: :desc).first.group + 1 : 1
    @products = params[:products]
    @products.each do |product|
      current_user.purchases.create(
        product_id: product[:product_id],
        quantity: product[:quantity],
        group: @group
      )
    end
    status 200
    body ''
  else
    status 422
    body user_not_authorized
  end
end

get '/my_purchases' do
  if validate_token
    status 200
    body current_user.purchases.to_json
  else
    status 422
    body user_not_authorized
  end
end
