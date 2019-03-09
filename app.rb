require 'bundler/setup'

Bundler.require(:default)

require 'dry/events/publisher'
require 'dry/events/listener'

########################################################
# Event bus
########################################################

class Analytics
  include Dry::Events::Publisher[:analytics]

  register_event("Analytics::PaidContentPurchased")
end


########################################################
# Base event
########################################################

class Analytics
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
end

########################################################
# Events
########################################################

class Analytics
  class PaidContentPurchased < Analytics::Event
    def record
      puts "EVENT #{event.id}" # => Analytics::PaidContentPurchased
      puts
      #############################################################
      # data must be of class Analytics::EventData to be working
      puts "USER ID      #{data.user_id}"
      puts "CONTENT ID   #{data.content_id}"
      puts "CONTENT TYPE #{data.content_type}"
      #############################################################
      puts
      puts "Saving event in DB, enqueuing background job for exporting to Intercom, Mixpanel, Mailchimp & Slack.."
    end
  end
end

########################################################
# Modelizing event data
########################################################

class Analytics
  class EventData
    def initialize(elements)
      elements.each do |key, value|
        instance_variable_set("@#{key}", value)
        self.class.send(:attr_reader, key)
      end
    end
  end
end

# In the context of a rails controller..

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

      analytics.publish("Analytics::PaidContentPurchased",
        data: Analytics::EventData.new(
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

PurchasesController.new.create
