# CashIO Backend

CashIO API built with Ruby on Rails.

[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

## Useful Commands

### Create new model:

```
$ rails g model Entry name:string description:string date:date value:decimal
```

### Create new database based on app/models/\*.rb:

```
$ rails db:create
```

### Migrate created database:

```
$ rails db:migrate
```

### Populate database based on db/seeds.rb:

```
$ rails db:seed RAILS_ENV=development
```

### Generate controller with CRUD operations:

```
$ rails g scaffold_controller Entry
```

### Generate Kaminari gem config file, to implement pagination:

```
$ rails g kaminari:config
```

### Generate uploader:

```
$ rails g uploader Avatar
```

### Show all api routes:

```
$ rails routes
```

### Serve app:

```
$ rails s
```

## Useful gems

`gem 'rack-cors'` => Makes cross-origin AJAX possible.

`gem 'kaminari'` => Pagination.

`gem 'pg_search'` => PostgreSQL search.

`gem 'carrierwave', '>= 3.0.0.beta', '< 4.0'` => File upload.

`gem 'rubocop-rails', require: false` => Good pratices and code style.

`gem 'dotenv-rails', groups: %i[development test]` => Enables .env files.

## Code Examples

### Database config file with PostgreSQL setup:

#### ./config/database.yml

```yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  port: 5432

development:
  <<: *default
  database: cash_io_development
  username: <%= ENV['POSTGRES_USER'] %>
  password: <%= ENV['POSTGRES_PASSWORD'] %>

test:
  <<: *default
  database: cash_io_test
  username: <%= ENV['POSTGRES_USER'] %>
  password: <%= ENV['POSTGRES_PASSWORD'] %>

production:
  <<: *default
  host: <%= ENV['POSTGRES_HOST'] %>
  database: <%= ENV['POSTGRES_DB'] %>
  username: <%= ENV['POSTGRES_USER'] %>
  password: <%= ENV['POSTGRES_PASSWORD'] %>
```

### Gemfile:

### ./Gemfile

```rb
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.3'

gem 'bcrypt', '~> 3.1.7'
gem 'bootsnap', require: false
gem 'carrierwave', '>= 3.0.0.beta', '< 4.0'
gem 'dotenv-rails', groups: %i[development test]
gem 'jwt'
gem 'kaminari'
gem 'pg', '~> 1.1'
gem 'pg_search'
gem 'puma', '~> 5.0'
gem 'rack-cors'
gem 'rails', '~> 7.0.4', '>= 7.0.4.3'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  gem 'rubocop-rails', require: false
  gem 'faker'
end
```

### Routes:

#### ./config/routes.rb

```rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :entries
      resources :users
      post '/auth/login', to: 'authentication#login'
      get '/auth/me', to: 'authentication#me'
      get '/*a', to: 'application#not_found'
    end
  end
end
```

### Entity models with validation and pg_search gem setup:

#### ./app/models/user.rb

```rb
# User entity model definition
class User < ApplicationRecord
  include PgSearch::Model
  has_secure_password
  has_many :entries, dependent: :destroy
  has_many :categories, dependent: :destroy
  mount_uploader :avatar, UserAvatarUploader
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true, on: :create
  validates :password, length: { minimum: 6, maximum: 20 }, on: :create
  pg_search_scope :search_by_term, against: %i[first_name last_name email username], using: {
    tsearch: {
      any_word: true,
      prefix: true
    }
  }
end
```

#### ./app/models/category.rb

```rb
# Category entity model definition
class Category < ApplicationRecord
  include PgSearch::Model
  belongs_to :user
  has_many :entries, dependent: :destroy
  mount_uploader :image, CategoryImageUploader
  validates :name, presence: true, uniqueness: true
  pg_search_scope :search_by_term, against: :name, using: {
    tsearch: {
      any_word: true,
      prefix: true
    }
  }
end
```

#### ./app/models/entry.rb

```rb
# Entry entity model definition
class Entry < ApplicationRecord
  include PgSearch::Model
  belongs_to :user
  belongs_to :category
  validates :name, presence: true
  validates :date, presence: true
  validates :value, presence: true
  pg_search_scope :search_by_term, against: %i[name description], using: {
    tsearch: {
      any_word: true,
      prefix: true
    }
  }
  pg_search_scope :search_by_category_id, against: :category_id, using: {
    tsearch: {
      any_word: true,
      prefix: true
    }
  }
end
```

### Controllers:

#### ./app/controllers/application_controller.rb

```rb
# Application Controller class definition
class ApplicationController < ActionController::API
  def not_found
    render json: { error: 'not_found' }
  end

  def authorize_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header

    begin
      decoded = JsonWebToken.decode(header)
      @current_user = User.find(decoded[:user_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: e.message }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { errors: e.message }, status: :unauthorized
    end
  end
end
```

#### ./app/controllers/api/v1/authentication_controller.rb

```rb
module Api
  module V1
    # Handles API authentication
    class AuthenticationController < ApplicationController
      before_action :authorize_request, except: :login
      before_action :set_user, only: :login

      def login
        if @user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: @user.id)
          time = Time.now + 24.hours.to_i

          render json: {
            token:,
            exp: time.strftime('%m-%d-%Y %H:%M'),
            user: @user
          }, except: [:password_digest], status: :ok
        else
          render json: {
            error: 'unauthorized'
          }, status: :unauthorized
        end
      end

      def me
        render json: @current_user, except: [:password_digest]
      end

      private

      def set_user
        @user = User.find_by_email(params[:email])
      end

      def login_params
        params.permit(:email, :password)
      end
    end
  end
end
```

#### ./app/controllers/api/v1/users_controller.rb

```rb
module Api
  module V1
    # Handles User entity API actions
    class UsersController < ApplicationController
      before_action :authorize_request, except: :create
      before_action :set_user, only: %i[show update destroy]
      before_action :set_page_params, :set_order_params, :set_search_params, only: :index

      def index
        result = User.order("#{@order_by} #{@direction}").page(@page).per(@per_page)
        result = result.search_by_term(@search) if @search

        render json: {
          direction: @direction,
          last_page: result.total_count.fdiv(@per_page).ceil,
          order_by: @order_by,
          page: @page,
          per_page: @per_page,
          search: @search,
          total: result.total_count,
          result:
        }
      end

      def show
        render json: @user, except: :password_digest
      end

      def create
        @user = User.new(user_params)

        if @user.save
          render json: @user, except: :password_digest, status: :created
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      def update
        if @user.update(user_params)
          render json: @user, except: :password_digest
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @user.destroy
      end

      private

      def set_page_params
        @page = params[:page].to_i.positive? ? params[:page].to_i : 1
        @per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 25
      end

      def set_order_params
        @direction = params[:direction] || 'ASC'
        @order_by = params[:order_by] || 'id'
      end

      def set_search_params
        @search = params[:search]
      end

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.permit(:first_name, :last_name, :avatar, :username, :email, :password, :password_confirmation)
      end
    end
  end
end
```

#### ./app/controllers/api/v1/categories_controller.rb

```rb
module Api
  module V1
    # Handles Category entity API actions
    class CategoriesController < ApplicationController
      before_action :authorize_request
      before_action :set_category, only: %i[show update destroy]
      before_action :set_page_params, :set_order_params, :set_search_params, only: :index

      def index
        result = @current_user.categories.order("#{@order_by} #{@direction}").page(@page).per(@per_page)
        result = result.search_by_term(@search) if @search

        render json: {
          direction: @direction,
          last_page: result.total_count.fdiv(@per_page).ceil,
          order_by: @order_by,
          page: @page,
          per_page: @per_page,
          search: @search,
          total: result.total_count,
          result:
        }
      end

      def show
        render json: @category
      end

      def create
        @category = @current_user.categories.new(category_params)

        if @category.save
          render json: @category, status: :created
        else
          render json: @category.errors, status: :unprocessable_entity
        end
      end

      def update
        if @category.update(category_params)
          render json: @category
        else
          render json: @category.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @category.destroy
      end

      private

      def set_page_params
        @page = params[:page].to_i.positive? ? params[:page].to_i : 1
        @per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 25
      end

      def set_order_params
        @direction = params[:direction] || 'ASC'
        @order_by = params[:order_by] || 'id'
      end

      def set_search_params
        @search = params[:search]
      end

      def set_category
        @category = @current_user.categories.find(params[:id])
      end

      def category_params
        params.permit(:name, :image)
      end
    end
  end
end
```

#### ./app/controllers/api/v1/entries_controller.rb

```rb
module Api
  module V1
    # Handles Entry entity API actions
    class EntriesController < ApplicationController
      before_action :authorize_request
      before_action :set_entry, only: %i[show update destroy]
      before_action :set_page_params, :set_order_params, :set_search_params, only: :index

      def index
        result = @current_user.entries.order("#{@order_by} #{@direction}").page(@page).per(@per_page)
        result = result.search_by_term(@search) if @search
        result = result.search_by_category_id(@category_id) if @category_id

        render json: {
          category_id: @category_id,
          direction: @direction,
          last_page: result.total_count.fdiv(@per_page).ceil,
          order_by: @order_by,
          page: @page,
          per_page: @per_page,
          search: @search,
          total: result.total_count,
          result:
        }
      end

      def show
        render json: @entry
      end

      def create
        @entry = @current_user.entries.new(entry_params)

        if @entry.save
          render json: @entry, status: :created
        else
          render json: @entry.errors, status: :unprocessable_entity
        end
      end

      def update
        if @entry.update(entry_params)
          render json: @entry
        else
          render json: @entry.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @entry.destroy
      end

      private

      def set_page_params
        @page = params[:page].to_i.positive? ? params[:page].to_i : 1
        @per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 25
      end

      def set_order_params
        @direction = params[:direction] || 'ASC'
        @order_by = params[:order_by] || 'id'
      end

      def set_search_params
        @search = params[:search]
        @category_id = params[:category_id]
      end

      def set_entry
        @entry = @current_user.entries.find(params[:id])
      end

      def entry_params
        params.permit(:name, :description, :date, :value)
      end
    end
  end
end
```

### Migrations:

#### ./db/migrate/\*\*\*\_create_users.rb

```rb
# User entity model migration
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :avatar
      t.string :username
      t.string :email
      t.string :password_digest

      t.timestamps
    end
  end
end
```

#### ./db/migrate/\*\*\*\_create_categories.rb

```rb
# Category entity model migration
class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :image
      t.belongs_to :user, foreign_key: true

      t.timestamps
    end
  end
end
```

#### ./db/migrate/\*\*\*\_create_entries.rb

```rb
# Entry entity model migration
class CreateEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :entries do |t|
      t.string :name
      t.string :description
      t.date :date
      t.decimal :value
      t.belongs_to :user, foreign_key: true
      t.belongs_to :category, foreign_key: true

      t.timestamps
    end
  end
end
```

### Seeds:

#### ./db/seeds.rb

```rb
ActiveRecord::Base.transaction do
  ['common', Rails.env].each do |seed_file_name|
    seed_file = "#{Rails.root}/db/seeds/#{seed_file_name}.rb"
    if File.exist?(seed_file)
      puts "-- Seeding data from file: #{seed_file_name}"
      require seed_file
    end
  end
end
```

#### ./db/seeds/common.rb

```rb
root_user = User.create({
                          first_name: 'root',
                          last_name: 'user',
                          username: 'user',
                          email: 'root@user.com',
                          password: ENV['ROOT_USER_PASSWORD']
                        })

entry_categories = %w[
  Other
  Groceries
  Transport
  Health
  Leisure
  Habitation
  Communication
]

entry_categories.each { |category| root_user.categories.create({ name: category }) }
```

#### ./db/seeds/development.rb

```rb
1800.times do
  Entry.create({
                 category_id: Faker::Number.between(from: 1, to: 7),
                 user_id: 1,
                 name: Faker::Name.name,
                 description: Faker::Lorem.paragraph,
                 date: Faker::Date.between(from: 180.days.ago, to: Date.today),
                 value: Faker::Number.between(from: -1000, to: 1000)
               })
end
```

### Docker setup files:

#### ./Dockerfile

```Dockerfile
ARG RUBY_VERSION=3.1.3
FROM ruby:$RUBY_VERSION

RUN apt-get update -qq && \
  apt-get install -y postgresql nodejs && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

WORKDIR /rails

ENV RAILS_LOG_TO_STDOUT="1" \
  RAILS_SERVE_STATIC_FILES="true" \
  RAILS_ENV="production" \
  BUNDLE_WITHOUT="development"

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

RUN bundle exec bootsnap precompile --gemfile app/ lib/

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000

CMD ["./bin/rails", "server"]
```

#### ./docker-compose.yml

```yml
version: "3"
services:
  db:
    image: postgres:14.2-alpine
    container_name: postgres-14.2
    volumes:
      - postgres_data:/var/lib/postgresql/data
    command: "postgres -c 'max_connections=500'"
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
  web:
    build: .
    command: "./bin/rails server"
    environment:
      - RAILS_ENV=${RAILS_ENV}
      - POSTGRES_HOST=${POSTGRES_HOST}
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
      - ROOT_USER_PASSWORD=${ROOT_USER_PASSWORD}
    volumes:
      - app-storage:/rails/storage
    depends_on:
      - db
    ports:
      - "3000:3000"
volumes:
  postgres_data: {}
  app-storage: {}
```

#### ./bin/docker-entrypoint

```bash
#!/bin/bash

if [ "${*}" == "./bin/rails server" ]; then
  ./bin/rails db:create
  ./bin/rails db:prepare
  ./bin/rails db:seed
fi

exec "${@}"
```

#### ./.dockerignore

```
/.git/
/.bundle
/config/master.key
/config/credentials/*.key
/.env*
!/.env.example
/log/*
/tmp/*
!/log/.keep
!/tmp/.keep
/tmp/pids/*
!/tmp/pids/
!/tmp/pids/.keep
/storage/*
!/storage/.keep
/tmp/storage/*
!/tmp/storage/
!/tmp/storage/.keep
/node_modules/
/app/assets/builds/*
!/app/assets/builds/.keep
/public/assets
```
