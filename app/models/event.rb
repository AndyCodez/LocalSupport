class Event < ApplicationRecord
  validates :title, presence: true
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :organisation_id, presence: true, on: [:create]
  belongs_to :organisation

  scope :upcoming, lambda { |n|
                               where('start_date > ?', DateTime.current.midnight)
                              .order('created_at DESC')
                              .limit(n)
                   }

  def all_day_event?
    self.start_date == self.start_date.midnight && self.end_date == self.end_date.midnight
  end

  def self.build_by_coordinates(events = nil)
    events = event_with_coordinates(events)
    Location.build_hash(group_by_coordinates(events))
  end

  private

  def self.event_with_coordinates(events)
    events.map do |ev|
      ev.send(ev.organisation.nil? ? :lat_lng_default : :lat_lng_supplier)
    end
  end

  def lat_lng_default
    self.tap do |e|
      e.longitude = 0.0
      e.latitude = 0.0
    end
  end


  def lat_lng_supplier
    return self if latitude && longitude
    send(:with_organisation_coordinates)
  end

  def with_organisation_coordinates
    self.tap do |e|
      e.longitude = e.organisation.longitude
      e.latitude = e.organisation.latitude
    end
  end

  def self.group_by_coordinates(events)
    events.group_by do |event|
      [event.longitude, event.latitude]
    end
  end
end