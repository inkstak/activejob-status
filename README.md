# ActiveJob::Status

Simple monitoring status for ActiveJob, independent of your queuing backend or cache storage.

```ruby
gem 'activejob-status'
```

## Configuration

By default, ActiveJob::Status use the <code>Rails.cache</code> to store data.
You can use any compatible ActiveSupport::Cache::Store you want (memory, memcache, redis, ..)
or any storage responding to <code>read/write/delete</code>

> **Note** : In Rails 5, `Rails.cache` defaults to  `ActiveSupport::Cache::NullStore` which will result in empty status. Setting a cache store for ActiveJob::Status is therefore mandatory.

Set your store:

```ruby
# config/initializers/activejob_status.rb
# By default
ActiveJob::Status.store = Rails.cache

# Set another storage
ActiveJob::Status.store = ActiveSupport::Cache::MemoryStore.new

# Use the ActiveSupport#lookup_store syntax
ActiveJob::Status.store = :redis_store
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

## Contributing

1. Don't hesitate to submit your feature/idea/fix in [issues](https://github.com/inkstak/musicbrainz)
2. Fork the [repository](https://github.com/inkstak/musicbrainz)
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
