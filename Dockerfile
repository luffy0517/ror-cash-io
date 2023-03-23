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