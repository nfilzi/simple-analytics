# Simple Analytics with dry-events

This setup relies on the `dry-events` [gem](https://dry-rb.org/gems/dry-events/) to enable the pub/sub behavior in a simple way.

Its goal is to enable analytics in a rails app **to be centralized in a harmonized folder** `app/events` which looks like this 👇

```
├── app
│   ├── controllers
│   ├── events
│   │   ├── content_watched.rb
│   │   ├── paid_content_landing_viewed.rb
│   │   ├── paid_content_purchased.rb
│   │   ├── signed_up.rb
│   │   └── signed_up_through_content.rb
│   ├── models
│   ├── services
│   └── views
└── lib
```

## Setup

### The Analytics Event bus

Simply define a class which will act as the publisher in your app, and register all analytics events you need.

```
class Analytics
  include Dry::Events::Publisher[:analytics]

  register_event("PaidContentPurchased")
end
```

### An event class defines 2 public methods - `record` && `export`
The `record` method is responsible for saving the event data in DB.

The `export` method is responsible for exporting the event and its data to external services such as Intercom or Mixpanel.

```
class PaidContentPurchased < Event
  def record
    puts "EVENT #{event.id}" # => Analytics::PaidContentPurchased
    puts
    #############################################################
    # data must be of class EventData to be working
    puts "USER ID      #{data.user_id}"
    puts "CONTENT ID   #{data.content_id}"
    puts "CONTENT TYPE #{data.content_type}"
    #############################################################
    puts
    puts "Saving event in DB, enqueuing background job for exporting to Intercom, Mixpanel, Mailchimp & Slack.."
  end

  def export
    # TODO
  end
end
```

### This setup relies on 2 base classes - `Event` && `EventData`

The `Event` class is a thin layer to automatically make any event class setup from the start
with a dry-events listener role, and some attr_readers which will always be used.

```
class Event
  include Dry::Events::Listener[:analytics]

  def self.inherited(subclass)
    subscribe(subclass.to_s) do |event|
      subclass.new(event).record
    end
  end

  attr_reader :event, :data

  def initialize(event)
    @event = event
    @data  = event[:data]
  end
end
```

The `EventData` class is a simple wrapper around `dry-events` event data hash,
in order to be able to access data in a more OO fashion.

```
class EventData
  def initialize(elements)
    elements.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_reader, key)
    end
  end
end
```

## Usage

Imagine being in the context of a rails app processing some content purchases..

```
class ApplicationController

  private
  def analytics
    Analytics.new
  end
end

class PurchasesController < ApplicationController
  def create
    if :success
      # [...]

      analytics.publish("PaidContentPurchased",
        data: EventData.new(
          user_id:      1,
          content_id:   1,
          content_type: :serie
        )
      )

      # [...]
    else
      # [...]
    end
  end
end
```


