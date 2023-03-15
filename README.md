# CashIO Backend

Application for study Ruby on Rails.

## Commands

### Create new model:

```
rails g model Client name:string phone:string last_purchase:date
```

### Create new database based on app/models/\*\*.rb:

```
rails db:create
```

### Migrate created database:

```
rails db:migrate
```

### Prepare tests for created database:

```
rails db:test:prepare
```

### Populate database based on db/seeds.rb:

```
rails db:seed RAILS_ENV=development
```

### Generate controller with CRUD operations:

```
rails g scaffold_controller Entry
```

### Show all api routes:

```
rails routes
```

### Serve app:

```
rails s
```

## Examples

### config/routes.rb:

```rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :entries
    end
  end
end
```

### app/models/entry.rb:

```rb
class Entry < ApplicationRecord
  validates :name, presence: true
  validates :date, presence: true
  validates :value, presence: true
end
```

### app/controllers/api/v1/entries_controller.rb:

```rb
class Api::V1::EntriesController < ApplicationController
  before_action :set_entry, only: %i[ show update destroy ]

  # GET /entries
  def index
    @entries = Entry.all

    render json: @entries
  end

  # GET /entries/1
  def show
    render json: @entry
  end

  # POST /entries
  def create
    @entry = Entry.new(entry_params)

    if @entry.save
      render json: @entry, status: :created
    else
      render json: @entry.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /entries/1
  def update
    if @entry.update(entry_params)
      render json: @entry
    else
      render json: @entry.errors, status: :unprocessable_entity
    end
  end

  # DELETE /entries/1
  def destroy
    @entry.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_entry
    @entry = Entry.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def entry_params
    params.require(:entry).permit(:name, :description, :date, :value)
  end
end
```

### db/seeds.rb:

```rb
50.times do
  Entry.create({
    name: Faker::Name.name,
    description: Faker::Lorem.paragraph,
    date: Faker::Date.between(from: 30.days.ago, to: Date.today),
    value: Faker::Number.between(from: -1000.0, to: 1000.0),
  })
end

```
