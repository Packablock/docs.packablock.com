FROM ruby:3.3-alpine

# Install build dependencies for compilation of native extensions (e.g. sassc)
RUN apk add --no-cache build-base gcc make musl-dev git

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 4000

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--incremental"]
