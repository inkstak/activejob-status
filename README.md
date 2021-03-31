# ActiveJob::Status

Simple monitoring status for ActiveJob, independent of your queuing backend or cache storage.

```ruby
gem 'activejob-status'
```

## Configuration

### Cache Store

By default, ActiveJob::Status use the <code>Rails.cache</code> to store data.
You can use any compatible ActiveSupport::Cache::Store you want (memory, memcache, redis, ..)
or any storage responding to <code>read/write/delete</code>

> **Note** : In Rails 5, `Rails.cache` defaults to  `ActiveSupport::Cache::NullStore` which will result in empty status. Setting a cache store for ActiveJob::Status is therefore mandatory.

To set your own store:

```ruby
# config/initializers/activejob_status.rb

if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
  # Use an alternative cache store:
  # ActiveJob::Status.store = :file_store
  # ActiveJob::Status.store = :mem_cache_store
  # ActiveJob::Status.store = :redis_cache_store
  ActiveJob::Status.store = :file_store
    
  # Avoid using cache store that are not shared by processes (ex: memory_store).

  # The `store=` method doesn't handle multiple arguments like Rails.
  # If you need to pass argument, you should instantiate the store:
  # ActiveJob::Status.store = ActiveSupport::Cache::FileStore.new('tmp/cache')
  # ActiveJob::Status.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_CACHE_URL'])
end
```

### Expiration time

Because ActiveJob::Status relies on cache store, all statuses come with an expiration item.
It's set to 1 hour by default.

To set a longer expiration:

```ruby
# config/initializers/activejob_status.rb
ActiveJob::Status.options = { expires_in: 30.days.to_i }
```

## Usage

Include the <code>ActiveJob::Status</code> module in your jobs.

```ruby
class MyJob < ActiveJob::Base
  include ActiveJob::Status
end
```

The module introduces two methods:

* <code>status</code> to directly read/update status
* <code>progress</code> to implement a progress status

```ruby
class MyJob < ActiveJob::Base
  include ActiveJob::Status

  def perform
    status.update(foo: false)

    progress.total = 1000

    1000.time do |i|
      progress.increment
    end

    status.update(foo: true)
  end
end
```


Check the status of a job

```ruby
job = MyJob.perform_later
status = ActiveJob::Status.get(job)
# => { status: :queued }
```

You can also use the job_id

```ruby
status = ActiveJob::Status.get('d11b64e6-8631-4118-ae76-e19376769171')
# => { status: :queued }
```

Follow the progression of your job

```ruby
status
# => { status: :working, progress: 100, total: 1000, foo: false }

status.working?
# => true

status.progress
# => 0.1

status[:foo]
# => false
```

until it's completed

```ruby
status
# => { status: :completed, progress: 1000, total: 1000, foo: true }

status.completed?
# => true

status.progress
# => 1

status[:foo]
# => true
```

Within a controller

```ruby
def status
  status = ActiveJob::Status.get(params[:job])
  render json: status.to_json
end
```

## ActiveJob::Status and exceptions

Internally, ActiveJob::Status uses `ActiveSupport#rescue_from` to catch every `Exception` to apply the `failed`  status before throwing the exception again.

[Rails](https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from) says:
> Handlers are inherited. They are searched from right to left, from bottom to top, and up the hierarchy. The handler of the first class for which exception.is_a?(klass) holds true is the one invoked, if any.

Thus, there are a few points to consider when using `rescue_from`:

1 - Do not declare `rescue_from` handlers before including `ActiveJob::Status`. They cannot be called:

```ruby
class ApplicationJob < ActiveJob::Base
  rescue_from Exception do |e|
    ExceptionMonitoring.notify(e)
    raise e
  end
end

class MyJob < ApplicationJob
  # The rescue handlers from ApplicationJob won't ever be executed
  # and the exception monitoring won't be notified.

  include ActiveJob::Status
end
```

2 - If you're rescuing any or all exceptions, the status will never be set to `failed`. You need to update it by yourself:

```ruby
class ApplicationJob < ActiveJob::Base
  include ActiveJob::Status

  rescue_from Exception do |e|
    ExceptionMonitoring.notify(e)
    status.update(status: :failed)
    raise e
  end
end
```

3 - Subsequent handlers will stop the rescuing mechanism:

```ruby
class MyJob < ApplicationJob
  # With the exceptions handled below:
  # - the monitor won't be notified
  # - the job status will remains to `working`

  retry_on    'SomeTimeoutError', wait: 5.seconds
  discard_on  'DeserializationError'
  rescue_from 'AnotherCustomException' do |e|
    do_something_else
  end
end
```

## Contributing

1. Don't hesitate to submit your feature/idea/fix in [issues](https://github.com/inkstak/activejob-status)
2. Fork the [repository](https://github.com/inkstak/activejob-status)
3. Create your feature branch
4. Create a pull request

### Tests

Not yet provided.

## License & credits

Copyright (c) 2019 Savater Sebastien.  
See [LICENSE](https://github.com/inkstak/activejob-status/blob/master/LICENSE) for further details.

Contributors:
* Valentin Ballestrino [@vala](https://github.com/vala)
* Dennis van de Hoef [@dennisvandehoef](https://github.com/dennisvandehoef)
* Olle Jonsson [@olleolleolle](https://github.com/olleolleolle)
* Felipe Sateler [@fsateler](https://github.com/fsateler)
