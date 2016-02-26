# ActiveJob::Status

Simple monitoring status for ActiveJob, independent of your queuing backend and cache storage.

## Configuration

By default, ActiveJob::Status use the Rails.cache to store data.
You can use any compatible ActiveSupport::Cache::Store you want (memory, memcache, redis, ..)
or any storage responding to <code>read/write/delete</code>

Set your store:

```
# config/initializers/activejob_status.rb
ActiveJob::Status.store = ActiveSupport::Cache::MemoryStore.new
```


## Usage

Include the <code>ActiveJob::Status</code> module in your jobs.

```
class MyJob < ActiveJob::Base
  include ActiveJob::Status
end
```

The module introduces two methods:

* <code>status</code> to directly read/update status
* <code>progress</code> to implement a progress status

```
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


Check the status a job

    job = MyJob.perform_later
    status = ActiveJob::Status.get(job)
    # => { status: :queued }

You can also use the job_id


    status = ActiveJob::Status.get('d11b64e6-8631-4118-ae76-e19376769171')
    # => { status: :queued }

Follow the progression of your job

    status
    # => { status: :working, progress: 100, total: 1000, foo: false }

    status.working?
    # => true

    status.progress
    # => 0.1

    status[:foo]
    # => false

until it's completed

    status
    # => { status: :completed, progress: 1000, total: 1000, foo: true }

    status.completed?
    # => true

    status.progress
    # => 1

    status[:foo]
    # => true
