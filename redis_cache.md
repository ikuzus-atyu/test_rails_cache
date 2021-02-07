
# Railsでキャッシュ実装してみる

## Redis と mysql起動

```bash
$ wget https://github.com/ikuzus-atyu/mysql-redis/archive/redis6.0.7-mysql8.zip
$ uzip redis6.0.7-mysql8.zip
$ cd ./redis6.0.7-mysql8
$ sudo docker-compose up -d
```

## set up

### rails install
今回 javascript 使わないからwebpackerは除外
```
rails new -d mysql --skip-webpack-install
```

### Gemfile 修正
redis追加

```ruby
gem 'redis'
```

### Rails Cache の設定

config/environments/development.rb

```ruby
  config.action_controller.perform_caching = true
  config.cache_store = :redis_cache_store, {
    url: 'redis://127.0.0.1:6379/0/cache',
    expires_in: 1.minutes,
    namespace: 'redis-dev'
  }
```

## cache 接続

- redisにappからcacheをset

  ```ruby
  $ bundle exec rails c
  > Rails.cache.write 'hoge', 'foo'
  # OK
  ```

- redisにsetされているのを確認

  ```bash
  $ curl 'telnet://127.0.0.1:6379'
  > keys *
  # *0
  > keys *
  # *1
  # $14
  # redis-dev:hoge
  > get redis-dev:hoge
  # $113
  # o: ActiveSupport::Cache::Entry  :
  # @version0:@created_atf1612707177.945806:@expires_in6e1
  ```

- expire(有効期限)経過したらcacheが消える

  ```ruby
  $ bundle exec rails c
  > Rails.cache.read 'hoge'
  => nil
  ```

  ```bash
  > get redis-dev:hoge
  # $-1
  ```
 
