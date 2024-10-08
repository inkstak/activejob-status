# ActiveJob::Status

Simple monitoring status for ActiveJob, independent of your queuing backend or cache storage.

[![Gem Version](https://badge.fury.io/rb/activejob-status.svg)](https://rubygems.org/gems/activejob-status)
[![CI Status](https://github.com/inkstak/activejob-status/actions/workflows/ci.yml/badge.svg)](https://github.com/inkstak/activejob-status/actions/workflows/ci.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Maintainability](https://api.codeclimate.com/v1/badges/a7b1ec1d3769e49021fd/maintainability)](https://codeclimate.com/github/inkstak/activejob-status/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a7b1ec1d3769e49021fd/test_coverage)](https://codeclimate.com/github/inkstak/activejob-status/test_coverage)

## Table of contents

- [Installation](#installation)
- [Configuration](#configuration)
  - [Cache Store](#cache-store)
  - [Select data to store by default](#select-data-to-store-by-default)
  - [Expiration time](#expiration-time)
  - [Throttling](#throttling)
- [Usage](#usage)
  - [Updating status](#updating-status)
  - [Data stored by default](#data-stored-by-default)
  - [Reading status](#reading-status)
  - [Serializing status to JSON](#serializing-status-to-json)
  - [Setting options per job](#setting-options-per-job)
  - [ActiveJob::Status and exceptions](#activejobstatus-and-exceptions)
  - [Race conditions](#race-conditions)
  - [[Beta] Batches](#beta-batches)

## Installation

```bash
gem install activejob-status
```
or
```bash
bundle add activejob-status
```

## Configuration

### Cache Store

By default, ActiveJob::Status use the <code>Rails.cache</code> to store data.
You can use any compatible ActiveSupport::Cache::Store you want (memory, memcache, redis, ..)
or any storage responding to <code>read/write/delete</code>

> **Note** : `Rails.cache` defaults to  `ActiveSupport::Cache::NullStore` which will result in empty status.
Setting a cache store for ActiveJob::Status is therefore mandatory.

You can set your own store:

```ruby
# config/initializers/activejob_status.rb

# Use an alternative cache store:
#   ActiveJob::Status.store = :file_store, "/path/to/cache/directory"
#   ActiveJob::Status.store = :redis_cache_store, { url: ENV['REDIS_URL'] }
#   ActiveJob::Status.store = :mem_cache_store
#
# You should avoid using cache store that are not shared between web and background processes
# (ex: :memory_store).
#
if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
  ActiveJob::Status.store = :mem_cache_store
end
```

### Select data to store by default

By default, ActiveJob::Status already stores a status key at each step of a job's life cycle.  
To understand what data are stored and what data to add, see [Usage > Data stored by default](#data-stored-by-default).

> **Warning** : adding more data means more memory consumed.  
> For example, adding `:serialized_job` might require as much memory for caching as your use for your job backend.

```ruby
# config/initializers/activejob_status.rb

# Select what data you want to store.
# Available options are: :status, :serialized_job, :exception
# Default is [:status]
#
ActiveJob::Status.options = { includes: %i[status exception] }
```

### Expiration time

Because ActiveJob::Status relies on cache store, all statuses come with an expiration time.  
It's set to 1 hour by default.

You can set a longer expiration:

```ruby
# config/initializers/activejob_status.rb

# Set your own status expiration time:
# Default is 1 hour.
#
ActiveJob::Status.options = { expires_in: 30.days.to_i }
```

### Throttling

Depending on the cache storage latency, updating a status too often can cause bottlenecks.  
To narrow this effect, you can force a time interval between each updates:

```ruby
# config/initializers/activejob_status.rb

# Apply a time interval in seconds between every status updates.
# Default is 0 - no throttling mechanism
#
ActiveJob::Status.options = { throttle_interval: 0.1 }
```


## Usage

### Updating status

Include the <code>ActiveJob::Status</code> module in your jobs.

```ruby
class MyJob < ActiveJob::Base
  include ActiveJob::Status
end
```

The module introduces two methods:

* <code>progress</code> to implement a progress status

```ruby
class MyJob < ActiveJob::Base
  include ActiveJob::Status

  def perform
    progress.total = 1000

    1000.time do
      # ...do something...
      progress.increment
    end
  end
end
```

* <code>status</code> to directly read/update status

```ruby
class MyJob < ActiveJob::Base
  include ActiveJob::Status

  def perform
    status[:step] = "A"

    # ...do something...

    status[:step]   = "B"
    status[:result] = "...."
  end
end
```

You can combine both to update status and progress in a single call.

```ruby
class MyJob < ActiveJob::Base
  include ActiveJob::Status

  def perform
    status.update(step: "A", total: 100)
    
    100.times do
      # ...do something...
      progress.increment
    end

    # Reset the progress for the next step
    status.update(step: "B", total: 50, progress: 0)

    50.times do
      # ...do something...
      progress.increment
    end
  end
end
```

Throttling mechanism (see configuration) is applied when doing:

```ruby
progress.increment
progress.decrement
status.update(foo: 'bar')
```

Throttling mechanism is not applied when doing:

```ruby
progress.total    = 100
progress.progress = 0
progress.finish
status[:foo]      = 'bar'
status.update({ foo: 'bar' }, force: true)
```

### Data stored by default


By default, ActiveJob::Status only stores a status key.  
You can add more information about the job using `includes` config.  
See [Configuration > Select data to store by default](#select-data-to-store-by-default) for more options.

Adding `:status` to `includes` (the default option) is equivalent to:

```ruby
before_enqueue { |job| job.status[:status] = :queued }
before_perform { |job| job.status[:status] = :working }
after_perform  { |job| job.status[:status] = :completed }

rescue_from(Exception) do |e|
  status[:status] = :failed
  raise e
end
```

Adding `:serialized_job` to `includes` is equivalent to:

```ruby
before_enqueue { |job| job.status[:serialized_job] = job.serialize }
```

Adding `:exception` to `includes` is equivalent to:

```ruby
rescue_from(Exception) do |e|
  status[:exception] = { class: e.class, message: e.message }
  raise e
end
```

### Reading status

Check the status of a job

```ruby
job    = MyJob.perform_later
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
loop do
  puts status
  break if status.completed?
end

# => { status: :queued }
# => { status: :working, progress: 0, total: 100, step: "A" }
# => { status: :working, progress: 60, total: 100, step: "A" }
# => { status: :working, progress: 90, total: 100, step: "A" }
# => { status: :working, progress: 0, total: 50, step: "B" }
# => { status: :completed, progress: 50, total: 50, step: "B" }
```

The status provides you getters:

```ruby
status.status     # => "working"
status.queued?    # => false
status.working?   # => true
status.completed? # => false
status.failed?    # => false
status.progress   # => 0.5 (progress / total)
status[:step]     # => "A"
```

... until it's completed

```ruby
status.status     # => "completed"
status.completed? # => true
status.progress   # => 1
```

### Serializing status to JSON

Within a controller, you can serialize a status to JSON:

```ruby
class JobsController
  def show
    status = ActiveJob::Status.get(params[:id])
    render json: status.to_json
  end
end
```

```
GET /jobs/status/d11b64e6-8631-4118-ae76-e19376769171.json

{
  "status":   "working",
  "progress": 50
  "total":    100,
  "step":     "A"
}
```

### Setting options per job

You can override default options per job:

```ruby
class MyJob < ActiveJob::Base
  include ActiveJob::Status

  def status
    @status ||= ActiveJob::Status::Status.new(self,
      expires_in: 3.days,
      throttle_interval: 0.5,
      includes: %i[status serialized_job])
  end

  def perform
    ...
  end
end
```

### ActiveJob::Status and exceptions

Internally, ActiveJob::Status uses `ActiveSupport#rescue_from` to catch every `Exception` to apply the `failed` status
before throwing the exception again.

[Rails](https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from) says:
> Handlers are inherited. They are searched from right to left, from bottom to top, and up the hierarchy. The handler of
the first class for which exception.is_a?(klass) holds true is the one invoked, if any.

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

2 - If you're rescuing any or all exceptions, the status will never be set to `failed`. You need to update it by
yourself:

```ruby
class ApplicationJob < ActiveJob::Base
  include ActiveJob::Status

  rescue_from Exception do |e|
    ExceptionMonitoring.notify(e)
    status.catch_exception(e)
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

### Race conditions

Updating status in different places is subject to race conditions.
Here is an example:

```ruby
class ExportController
  def create
    job = ExportJob.perform_later(some_args)
    job.status.update({ user_id: current_user.id })

    render json: { id: job.job_id }
  end

  def show
    status = ActiveJob::Status.get(params[:id])
    return not_found unless status[:user_id] == current_user.id
  end
end

class ExportJob
  def perform
    perform_some_export
    status.update({ path: path })
  end
end
````

| ExportController | ExportJob | Cached status |
| -- | -- | -- |
| 1. Status is created. | | `{ status: :queued }` |
| 2. We want to update the status by adding `user_id`. The `update` method will first read the status from the cache store. | | `{ status: :queued }` |
| | 3. The job is already performed and we want to add the `path` to the status. The `update` method will first read the status from the cache store. | `{ status: :completed }` |
| 4. We overwrite the status in the cache store with the `user_id`. |  | `{ status: :queued, user_id: 1 }` |
| | 5. We overwrite the status in the cache store with the `path`. | `{ status: :completed, path: "export.csv" }` |
| 6. When we read the status, `user_id` is missing. | | `{ status: :completed, path: "export.csv" }` |

ActivSupport cache stores doesn't offer lock mechanism ... because it's cache and it's volatile by definition.  
There is therefore no mechanism implemented to narrow this race condition.  

As a workaround, you better have to update status in only one place, inside the job:

```ruby
class ExportController
  def create
    job = ExportJob.perform_later(some_args, current_user.id)
    render json: { id: job.job_id }
  end

  def show
    status = ActiveJob::Status.get(params[:id])
    return not_found unless status[:user_id] == current_user.id && !status.queued?
  end
end

class ExportJob
  def perform(args, user_id)
    status.update({ user_id: user_id })
    perform_some_export
    status.update({ path: path })
  end
end
````


### [Beta] Batches

> **Warning** : The Batch API is available on [beta](https://github.com/inkstak/activejob-status/tree/beta):
>
> ```bash
> gem install activejob-status --pre
> # or
> bundle add activejob-status --version "~> 1.1.0.beta.1"
> ```
>
> It doesn't provide all features implemented by backends
> like [Sidekiq](https://github.com/sidekiq/sidekiq/wiki/Batches)
> or [GoodJob](https://github.com/bensheldon/good_job?tab=readme-ov-file#batches).  
> Moreover, it wasn't designed to support batches with hundreds of jobs (or you might experience performance issues).
>

ActiveJob::Status provides a naïve implementation of batches:

```ruby
job_1 = MyJob.perform_later
job_2 = MyJob.perform_later

batch = ActiveJob::Status::Batch.new([job_1, job_2])
batch.status # => "working"
```

The batch status is considered:

* `queued` if **all** of the jobs are `queued`
* `failed` if **one** of the jobs is `failed`
* `completed` if **all** of the jobs are `completed`
* `working` in all other circumstances


## Contributing

1. Don't hesitate to submit your feature/idea/fix in [issues](https://github.com/inkstak/activejob-status)
2. Fork the [repository](https://github.com/inkstak/activejob-status)
3. Create your feature branch
4. Ensure RSpec & Rubocop are passing
4. Create a pull request

### Tests & lint

```bash
bundle exec rspec
bundle exec rubocop
bundle exec standardrb
```

To run RSpec against various version of Rails dependencies:
```bash
bundle exec appraisal install
bundle exec appraisal rspec
```

All of them can be run with:

```bash
bundle exec rake
```

## License & credits

Please see [LICENSE](https://github.com/inkstak/activejob-status/blob/main/LICENSE) for further details.

Contributors: [./graphs/contributors](https://github.com/inkstak/activejob-status/graphs/contributors)
