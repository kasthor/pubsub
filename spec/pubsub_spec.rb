require Rails.root + 'lib/pubsub'

describe PubSub::XMPP do
  subject do 
    class Dummy < PubSub::XMPP
    end

    Dummy.new
  end
  let(:item){ 
    xml = REXML::Element.new 'entry' 
    xml.add_attribute 'xmlns' => 'http://www.w3.org/2005/Atom'
    entry_item = xml.add_element('test')
    entry_item.text = "test"
    xml
  }
  let(:hash){
    { "test" => "test" }  
  }
  let(:node){ 'home/decisiv/case/updates' }

  it do
    subject.should respond_to :subscribe 
  end
 
  it do
    subject.should respond_to :publish
  end

  it "should establish a connection to a server and enable pubsub thru xmpp4r" do
    client = Jabber::Client.new Jabber::JID.new("test@localhost")
    Jabber::Client.should_receive(:new).and_return(client)
    client.should_receive(:connect)
    client.should_receive(:auth_anonymous)
    client.should_receive(:send).with(an_instance_of(Jabber::Presence))
    subject.connect 
  end

  it "should enable pubsub" do
    Jabber::PubSub::ServiceHelper.should_receive(:new).with( an_instance_of(Jabber::Client), 'pubsub.localhost' )
    subject.connect 
  end

  it "should subscribe to a channel" do
    subject.connect
    Jabber::PubSub::ServiceHelper.any_instance.should_receive(:subscribe_to).with(node)
    subject.subscribe channel: node
  end

  it "should publish to a channel" do
    subject.connect
    Jabber::PubSub::ServiceHelper.any_instance.should_receive(:publish_item_to).with(node, an_instance_of(Jabber::PubSub::Item))
    subject.publish channel: node, message: hash
  end

  it "should do nothing if there's no message" do
    subject.connect
    expect {
      subject.publish channel: node
    }.not_to raise_exception
  end

  it "should convert the message from hash to atom object" do
    subject.connect
    PubSub::Atom.should_receive(:atomize).and_return(item)
    subject.publish channel: node, message: hash
  end

  it "should create a node" do
    subject.connect
    Jabber::PubSub::ServiceHelper.any_instance.should_receive(:create_node).with(node)
    subject.create_node channel: node
  end

  it "should receive a message just sent"  do
    test = false
    subject.connect
    subject.create_node channel: node
    subject.subscribe channel: node do |event|
      test = true
    end 
    subject.publish channel: node, message: hash
    test.should be_true
  end

  it "should set a different callback for different channels" 
end

describe PubSub::Atom do
  let(:hash){
    { "test" => "test" }  
  }
  let(:xml){ 
    xml = REXML::Element.new 'entry' 
    xml.add_attribute 'xmlns' => 'http://www.w3.org/2005/Atom'
    entry_item = xml.add_element('test')
    entry_item.text = "test"
    xml
  }
  it do
    PubSub::Atom.should respond_to :atomize
  end 

  it do
    PubSub::Atom.should respond_to :deatomize
  end

  describe "#atomize" do
    it "should return an xml document" do
      PubSub::Atom.atomize(hash).should be_an_instance_of REXML::Element
    end

    it "should return the proper xml document" do
      PubSub::Atom.atomize(hash).to_s.should == xml.to_s
    end
  end

  describe "#deatomize" do
    it "should return a hash" do
      PubSub::Atom.deatomize(xml).should be_an_instance_of Hash
    end

    it "should return the proper hash" do
      PubSub::Atom.deatomize(xml).should == hash
    end
  end

  it "should atomize a deep hash" 
  it "should deatomize a deep xml"

end
