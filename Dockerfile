FROM ruby:3.0.1

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash -s && \
    apt-get install -y --no-install-recommends \
        postgresql-client nodejs yarn \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/app
# COPY Gemfile* ./
# RUN bundle install
# COPY . .

EXPOSE 3000
ENTRYPOINT ["/srv/app/entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]
