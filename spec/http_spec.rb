require "spec/helper/all"
require 'lib/em-synchrony/em-http'

URL = "http://localhost:8081/"
DELAY = 0.25

describe EventMachine::Synchrony::HttpRequest do
  it "should fire sequential requests" do
    EventMachine.synchrony do
      s = StubServer.new("HTTP/1.0 200 OK\r\nConnection: close\r\n\r\nFoo", DELAY)

      start = now
      order = []
      order.push :get  if EventMachine::Synchrony::HttpRequest.new(URL).get
      order.push :post if EventMachine::Synchrony::HttpRequest.new(URL).post
      order.push :head if EventMachine::Synchrony::HttpRequest.new(URL).head
      order.push :post if EventMachine::Synchrony::HttpRequest.new(URL).delete
      order.push :put  if EventMachine::Synchrony::HttpRequest.new(URL).put

      (now - start.to_f).should be_within(DELAY * order.size * 0.15).of(DELAY * order.size)
      order.should == [:get, :post, :head, :post, :put]

      s.stop
      EventMachine.stop
    end
  end

  it "should fire simultaneous requests via Multi interface" do
    EventMachine.synchrony do
      s = StubServer.new("HTTP/1.0 200 OK\r\nConnection: close\r\n\r\nFoo", DELAY)

      start = now

      multi = EventMachine::Synchrony::Multi.new
      multi.add :a, EventMachine::Synchrony::HttpRequest.new(URL).sget
      multi.add :b, EventMachine::Synchrony::HttpRequest.new(URL).spost
      multi.add :c, EventMachine::Synchrony::HttpRequest.new(URL).shead
      multi.add :d, EventMachine::Synchrony::HttpRequest.new(URL).sdelete
      multi.add :e, EventMachine::Synchrony::HttpRequest.new(URL).sput
      res = multi.perform

      (now - start.to_f).should be_within(DELAY * 0.15).of(DELAY)
      res.responses[:callback].size.should == 5
      res.responses[:errback].size.should == 0

      s.stop
      EventMachine.stop
    end
  end
end
