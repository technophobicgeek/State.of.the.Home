require_relative 'spec_helper'

def app
  Sinatra::Application
end

describe "service" do
  before do
    State.destroy
    Chore.destroy
    Group.destroy
  end
  
  # GETs
  describe "GET on /api/v1" do
    before do
      @group = Group.create(
        :code   => "ABCDEF",
        :name   => "The Tango Loft"
      )
      
      @chore1 = Chore.create(:name => "Dishwasher", :group => @group, :position => 1 )
      @states1 = %w[Clean Dirty].each_with_index {|s,i| State.create(:name => s, :chore => @chore1,:position => i+1)}
      @chore1.update(:selected => 1)
      @chore2 = Chore.create(:name => "Laundry", :group => @group, :position => 2 )
      @states2 = %w[Fresh Stinky].each_with_index {|s,i| State.create(:name => s, :chore => @chore2,:position => i+1)}
      @chore2.update(:selected => 2)   
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
          chores = attributes["chores"]
          #puts chores
          chores[0]["id"].should_not be_nil
          chores[0]["name"].should == "Dishwasher"
          chores[0]["states"][0]["name"].should == "Clean"
          chores[0]["states"][0]["position"].should == 1
          chores[0]["selected"].should == 1
          chores[0]["states"][1]["name"].should == "Dirty"
          chores[0]["states"][1]["position"].should == 2
          
          chores[1]["id"].should_not be_nil
          chores[1]["name"].should == "Laundry"
          chores[1]["states"][0]["name"].should == "Fresh"
          chores[1]["states"][1]["name"].should == "Stinky"
          chores[1]["states"][0]["position"].should == 1
          chores[1]["states"][1]["position"].should == 2
          chores[1]["selected"].should == 2
        end
        
        it "should return all chores and their selected states" do
          get '/api/v1/group/ABCDEF/chores/selected'               
          last_response.should be_ok
          attributes = JSON.parse(last_response.body)
          chores = attributes["chores"]
          chores[0]["id"].should_not be_nil
          chores[0]["selected"].should == 1
          chores[1]["id"].should_not be_nil
          chores[1]["selected"].should == 2
        end
        
        describe "/:name" do
          it "should return a chore with a specific id" do
            get "/api/v1/group/ABCDEF/chore/#{@chore1.id}"      
            last_response.should be_ok
            attributes = JSON.parse(last_response.body)
            attributes["name"].should == "Dishwasher"
            attributes["states"][0]["name"].should == "Clean"
            attributes["states"][1]["name"].should == "Dirty"
            attributes["selected"].should == 1
          end
      
          it "should return the selected state of a chore with a specific id" do
            get "/api/v1/group/ABCDEF/chore/#{@chore2.id}/selected"               
            last_response.should be_ok
            attributes = JSON.parse(last_response.body)
            attributes["selected"].should == 2
          end
          
        end
        
      end
      
    end
    
  end

  describe "POST on /api/v1/group" do
    before do
      State.destroy
      Chore.destroy
      Group.destroy
    end
    it "should create a group" do
      post '/api/v1/group/new', {
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

  describe "POST on /api/v1/group/:code" do
    before(:each) do
      group = Group.create(
        :code   => "ABCDEF",
        :name   => "The Tango Loft"
      )
    end


    it "should create a new chore for a group" do
      post '/api/v1/group/ABCDEF/chore/new', {
        :name  => "Dishwasher",
        :states => [
          {:name => "Clean",:position => 1},
          {:name => "Dirty",:position => 2 },
        ]
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      attributes["name"].should == "Dishwasher"
      attributes["states"][0]["name"].should == "Clean"
      attributes["states"][1]["name"].should == "Dirty"
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
  
  describe "PUT on /api/v1/group/:code/chore" do
    before :each do
      @group = Group.create(
        :code   => "ABCDEF",
        :name   => "The Tango Loft"
      )
      
      @chore1 = Chore.create(:name => "Dishwasher", :group => @group, :position => 1 )
      @states1 = %w[Clean Dirty].each_with_index {|s,i| State.create(:name => s, :chore => @chore1,:position => i+1)}
      @chore1.update(:selected => 1)
      @chore2 = Chore.create(:name => "Laundry", :group => @group,:position => 2 )
      @states2 = %w[Fresh Stinky].each_with_index {|s,i| State.create(:name => s, :chore => @chore2,:position => i+1)}
      @chore2.update(:selected => 2)  
    end
    
    it "should update a chore" do
      put "/api/v1/group/ABCDEF/chore/#{@chore1.id}", {
        :name  => "Our Dishwasher",
        :states => [
          {:name => "Sparkling",:position => 1},
          {:name => "Dirty",:position => 2 },
        ]
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      #puts attributes
      attributes["name"].should == "Our Dishwasher"
      attributes["states"][0]["name"].should == "Sparkling"
      attributes["states"][0]["position"].should == 1
      attributes["states"][1]["name"].should == "Dirty"
      attributes["states"][1]["position"].should == 2
    end    
   
 
  end
  
  describe "DEL on /api/v1/group/:code/chore" do
    before(:each) do
      Group.create(
        :code   => "ABCDEF",
        :name   => "The Tango Loft"
      )
      
      chore1 = Chore.create(:name => "Dishwasher", :group => group )
      %w[Clean Dirty].map {|s| State.create(:name => s, :chore => chore1)}
      chore1.update(:selected => 1)
      chore2 = Chore.create(:name => "Laundry", :group => group )
      %w[Fresh Stinky].map {|s| State.create(:name => s, :chore => chore2)}
      state = State.first(:name => "Stinky",:chore => chore2)
    end
    
    it "should delete a chore" 
   
 
  end 
end
