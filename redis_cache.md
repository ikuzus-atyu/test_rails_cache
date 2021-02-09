
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
 

## DB vs cache

- DB access
  ```bash
  Started GET "/book" for ::1 at 2021-02-08 02:13:07 +0900
    (3.1ms)  SELECT `schema_migrations`.`version` FROM `schema_migrations` ORDER BY `schema_migrations`.`version` ASC
  Processing by BookController#index as HTML
    Book Load (3.9ms)  SELECT `books`.* FROM `books` ORDER BY `books`.`release` DESC, `books`.`volume` DESC
    ↳ app/controllers/book_controller.rb:6:in `block (2 levels) in index'
  0.1375256929999864 seconds
    Rendering layout layouts/application.html.erb
    Rendering book/index.html.erb within layouts/application
    Rendered book/index.html.erb within layouts/application (Duration: 52.3ms | Allocations: 6306)
    Rendered layout layouts/application.html.erb (Duration: 97.0ms | Allocations: 9408)
  Completed 200 OK in 286ms (Views: 112.8ms | ActiveRecord: 15.9ms | Allocations: 34807)
  ```

- cache access
  ```bash
  Started GET "/book" for ::1 at 2021-02-08 02:13:12 +0900
  Processing by BookController#index as HTML
  0.04879330600002163 seconds
    Rendering layout layouts/application.html.erb
    Rendering book/index.html.erb within layouts/application
    Rendered book/index.html.erb within layouts/application (Duration: 18.7ms | Allocations: 6002)
    Rendered layout layouts/application.html.erb (Duration: 23.1ms | Allocations: 6864)
  Completed 200 OK in 76ms (Views: 24.9ms | ActiveRecord: 0.0ms | Allocations: 17433)
  ```

```
0.1375256929999864 / 0.04879330600002163
=> 2.8185360713194028 (sec)
```
