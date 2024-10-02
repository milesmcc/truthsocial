class EventProvider::EventProvider
  def initialize(event, serializer, data, *forwarded_args)
    @event = event
    @serializer = serializer
    @data = data
    @event_bus = Events::EventBus.instance
    @forwarded_args, * = forwarded_args
  end

  def call
    if @forwarded_args
      @event_bus.publish(@serializer.new(@data, @forwarded_args).serialize, event)
    else
      @event_bus.publish(@serializer.new(@data).serialize, event)
    end
  end

  private

  attr_reader :event, :data, :serializer, :event_bus
end
