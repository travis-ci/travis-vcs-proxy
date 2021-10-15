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
RUN cd / && curl https://storage.googleapis.com/gatestxxx/p4api-glibc2.3-openssl1.1.1.tgz | tar xz
WORKDIR /app
COPY Gemfile* ./

RUN bundle config --global build.p4ruby --with-p4api_dir=/p4api-2020.1.2187281
RUN gem install bundler -v '2.1.4'
RUN bundle install

COPY . .

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
