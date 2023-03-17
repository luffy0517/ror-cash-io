source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.3"

gem "rails", "~> 7.0.4", ">= 7.0.4.3"

gem "pg", "~> 1.1"

gem "puma", "~> 5.0"

gem "bcrypt", "~> 3.1.7"

gem "jwt"

gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

gem "bootsnap", require: false

gem "rack-cors"

gem "kaminari"

gem "pg_search"

gem "carrierwave", ">= 3.0.0.beta", "< 4.0"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  gem "faker"
end
