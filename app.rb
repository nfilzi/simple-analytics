require 'bundler/setup'

Bundler.require(:default)

require 'dry/events/publisher'
require 'dry/events/listener'

class Application
  include Dry::Events::Publisher[:analytics]

  register_event("UserSignedUpEvent")
end

class AnalyticEvent
  include Dry::Events::Listener[:analytics]

  def self.inherited(subclass)
    subscribe(subclass.to_s) do |event|
      subclass.record(event)
    end
  end
end

# module Analytics
#   class EventData
#     def initialize(elements)
#     end
#   end
# end

class UserSignedUpEvent < AnalyticEvent
  def self.record(event)
    puts "EVENT #{event.id}"
    puts "USER #{event[:user]}"
  end
end

app = Application.new
app.publish("UserSignedUpEvent", user: 'Jane')

# app.publish("UserSignedUpEvent", data: EventData.new(user: 'Jane'))
