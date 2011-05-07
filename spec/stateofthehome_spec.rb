require_relative 'spec_helper'

def app
  Sinatra::Application
end

describe "service" do
  before(:each) do
    State.destroy
    Chore.destroy
    Group.destroy
  end
  
  # GETs
  describe "GET on /api/v1" do
    before(:each) do
      group = Group.create(
        :code   => "ABCDEF",
        :name   => "The Tango Loft"
      )
      
      chore = Chore.create(:name => "Dishwasher", :group => group )
      states = %w[Clean Dirty].map {|s| State.create(:name => s, :chore => chore)}
      State.first(:name => "Clean",:chore => chore).update(:selected => true)
      
      chore = Chore.create(:name => "Laundry", :group => group )
      states = %w[Fresh Stinky].map {|s| State.create(:name => s, :chore => chore)}
      State.first(:name => "Stinky",:chore => chore).update(:selected => true)
      
    end
    
    describe "/group/:code" do
      it "should return a group by code" do
        get '/api/v1/group/ABCDEF'
        last_response.should be_ok
        attributes = JSON.parse(last_response.body)
        attributes["code"].should == "ABCDEF"
        attributes["name"].should == "The Tango Loft"
        attributes["created_at"].should_not be_blank      
        attributes["updated_at"].should_not be_blank
      end
      
      it "should return a 404 for a group that doesn't exist" do
        get '/api/v1/group/foo'
        last_response.status.should == 404
        last_response.body.should == "Group \"foo\" not found"        
      end
      
      describe "/chore" do
        
        it "should return all chores and all their states with selections" do
          get '/api/v1/group/ABCDEF/chores/all'
          last_response.should be_ok
          attributes = JSON.parse(last_response.body)
          puts attributes
        end
        
        it "should return all chores and their selected states" do
          get '/api/v1/group/ABCDEF/chores/selected'               
          last_response.should be_ok
          attributes = JSON.parse(last_response.body)
        end
        
        describe "/:name" do
          it "should return a chore with a specific name" do
            get '/api/v1/group/ABCDEF/chores/Dishwasher'       
            last_response.should be_ok
            attributes = JSON.parse(last_response.body)
          end
      
          it "should return the selected state of a chore with a specific name" do
            get '/api/v1/group/ABCDEF/chores/Dishwasher/selected'               
            last_response.should be_ok
            attributes = JSON.parse(last_response.body)
          end
          
        end
        
      end
      
    end
    
  end

  describe "POST on /api/v1/group" do
    it "should create a group" do
      post '/api/v1/group', {
        :name  => "The Tango Loft"
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      attributes["id"].should_not be_nil
      code = attributes["code"]
      code.length.should == 6

      get "/api/v1/group/#{code}"
      last_response.should be_ok
    end
  end
  
  describe "PUT on /api/v1/group/:code" do
    before(:each) do
      Group.create(
        :code   => "ABCDEF",
        :name   => "The Tango Loft"
      )
    end
    
    it "should update the name of a group" do
      put '/api/v1/group/ABCDEF', {
        :name  => "Our Tango Loft"
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      attributes["name"].should == "Our Tango Loft"
    end
   
    it "should not update the name of a group with a blank name" do
      put '/api/v1/group/ABCDEF', {
        :name  => ""
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      attributes["name"].should == "The Tango Loft"
    end
  
    it "should not update the code of a group" do
      put '/api/v1/group/ABCDEF', {
        :code  => "UVWXYA"
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      attributes["code"].should == "ABCDEF"
    end       
  end  
end
