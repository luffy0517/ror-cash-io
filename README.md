# CashIO Backend

CashIO API built with Ruby on Rails.

[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

## Useful Commands

### Create new model:

```
$ rails g model Entry name:string phone:string last_purchase:date
```

### Create new database based on app/models/\*.rb:

```
$ rails db:create
```

### Migrate created database:

```
$ rails db:migrate
```

### Prepare tests for created database:

```
$ rails db:test:prepare
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

`gem 'dotenv-rails', groups: %i[development test]'` => Enables .env files.

## Code Examples

### Database config file with PostgreSQL setup:

#### ./config/database.yml

```yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: postgres
  password: root

development:
  <<: *default
  database: cash_io_development

test:
  <<: *default
  database: cash_io_test

production:
  <<: *default
  database: cash_io_production
  username: cash_io
  password: <%= ENV["CASH_IO_DATABASE_PASSWORD"] %>
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
  gem 'faker'
  gem 'rubocop-rails', require: false
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

### Entity models with pg_search gem setup and validation:

#### ./app/models/user.rb

```rb
# User entity model definition
class User < ApplicationRecord
  include PgSearch::Model
  has_secure_password
  has_many :entries, dependent: :destroy
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
      @decoded = JsonWebToken.decode(header)
      @current_user = User.find(@decoded[:user_id])
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

#### ./app/controllers/api/v1/entries_controller.rb

```rb
module Api
  module V1
    # Handles Entry entity API actions
    class EntriesController < ApplicationController
      before_action :authorize_request
      before_action :set_entry, only: %i[show update destroy]
      before_action :set_direction, :set_order_by, :set_page, :set_per_page, :set_search, only: %i[index]

      def index
        result = @current_user.entries.order("#{@order_by} #{@direction}").page(@page).per(@per_page)
        result = result.search_by_term(@search) if @search
        total = result.total_count
        last_page = total.fdiv(@per_page).ceil

        render json: {
          result:,
          direction: @direction,
          order_by: @order_by,
          page: @page,
          per_page: @per_page,
          search: @search,
          total:,
          last_page:
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

      def set_direction
        @direction = params[:direction] || 'ASC'
      end

      def set_order_by
        @order_by = params[:order_by] || 'id'
      end

      def set_page
        @page = params[:page].to_i.positive? ? params[:page].to_i : 1
      end

      def set_per_page
        @per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 25
      end

      def set_search
        @search = params[:search]
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

#### ./db/migrate/\*\*\*\_create_user.rb

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
User.create({
              first_name: 'root',
              last_name: 'admin',
              username: 'admin',
              email: 'root@admin.com',
              password: ENV['ROOT_ADMIN_PASSWORD']
            })

entry_categories = [
  {
    name: 'Other',
    user_id: 1
  },
  {
    name: 'Groceries',
    user_id: 1
  },
  {
    name: 'Transport',
    user_id: 1
  },
  {
    name: 'Health',
    user_id: 1
  },
  {
    name: 'Leisure',
    user_id: 1
  },
  {
    name: 'Habitation',
    user_id: 1
  },
  {
    name: 'Communication',
    user_id: 1
  }
]

entry_categories.each { |category| Category.create(category) }

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
