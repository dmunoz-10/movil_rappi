# frozen_string_literal: true

require 'active_record'

# Connecting ActiveRecord to the database
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'database.sqlite3')

# Users table
ActiveRecord::Migration.drop_table(:users) if ActiveRecord::Base.connection.table_exists? :users
ActiveRecord::Migration.create_table(:users) do |t|
  t.string :first_name
  t.string :last_name
  t.string :email
  t.string :password
  t.string :api_token
end

# Stores table
ActiveRecord::Migration.drop_table(:stores) if ActiveRecord::Base.connection.table_exists? :stores
ActiveRecord::Migration.create_table(:stores) do |t|
  t.string :name
  t.string :description
  t.string :address
  t.references :user, foreign_key: true
end

# Products table
ActiveRecord::Migration.drop_table(:products) if ActiveRecord::Base.connection.table_exists? :products
ActiveRecord::Migration.create_table(:products) do |t|
  t.string :name
  t.string :description
  t.decimal :price, precision: 15, scale: 10
  t.references :store, foreign_key: true
end

# Purchases table
ActiveRecord::Migration.drop_table(:purchases) if ActiveRecord::Base.connection.table_exists? :purchases
ActiveRecord::Migration.create_table(:purchases) do |t|
  t.references :product, foreign_key: true
  t.references :user, foreign_key: true
  t.integer :group
  t.integer :quantity
end
