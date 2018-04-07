FROM ruby:2.4.1
MAINTAINER Rafael Chacon <rafaelchacon@gmail.com>

RUN  gem install bundler 

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
WORKDIR /app
RUN bundle install

# Now add the rest of the files
COPY . /app

# Run the server
EXPOSE 3000
ENV RACK_ENV=production
ENV DB_ADAPTER=mysql

CMD ["rackup", "--env", "${RACK_ENV}", "--port", "3000", "--server", "thin"]
