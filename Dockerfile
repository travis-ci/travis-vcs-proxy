FROM ruby:3.0.1

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash -s && \
    apt-get install -y --no-install-recommends \
        postgresql-client nodejs yarn \
    && rm -rf /var/lib/apt/lists/*

RUN bundle config --global frozen 1
RUN bundle config set deployment 'true'
RUN bundle config set without 'development test'

WORKDIR /app
COPY Gemfile* ./

RUN gem install bundler -v '2.1.4'
RUN bundle install

COPY . .

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
