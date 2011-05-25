require_relative 'spec_helper'

def app
  Sinatra::Application
end

describe "service" do
  before(:each) do
    State.destroy
    Task.destroy
    Group.destroy
    Location.destroy
    Member.destroy
  end
  
  # GETs
  describe "GET on /api/v1" do
    before(:each) do
      @group = Group.create(:code   => "ABCDEF",:name   => "The Tango Loft")
      
      @task1 = Task.create(:name => "Dishwasher", :group => @group, :position => 1 )
      @states1 = %w[Clean Dirty].each_with_index {|s,i| State.create(:name => s, :task => @task1,:position => i+1)}
      @task1.update(:selected => 1)
      
      @task2 = Task.create(:name => "Laundry", :group => @group, :position => 2 )
      @states2 = %w[Fresh Stinky].each_with_index {|s,i| State.create(:name => s, :task => @task2,:position => i+1)}
      @task2.update(:selected => 2)

      @task3 = Task.create(:name => "Make tea", :group => @group, :position => 3, :priority => 3 )  
    end
    
    describe "/group/:code" do
      it "should return all info about a group by code" do
        get '/api/v1/group/ABCDEF/all'
        last_response.should be_ok
        attributes = JSON.parse(last_response.body)
        attributes["code"].should == "ABCDEF"
        attributes["name"].should == "The Tango Loft"
        attributes["created_at"].should_not be_blank      
        attributes["updated_at"].should_not be_blank

        tasks = attributes["tasks"]
        puts tasks
        tasks[0]["id"].should_not be_nil
        tasks[0]["name"].should == "Tasks"

        tasks[1]["id"].should_not be_nil
        tasks[1]["name"].should == "Dishwasher"
        tasks[1]["states"][0]["name"].should == "Clean"
        tasks[1]["states"][0]["position"].should == 1
        tasks[1]["selected"].should == 1
        tasks[1]["states"][1]["name"].should == "Dirty"
        tasks[1]["states"][1]["position"].should == 2
        
        tasks[2]["id"].should_not be_nil
        tasks[2]["name"].should == "Laundry"
        tasks[2]["states"][0]["name"].should == "Fresh"
        tasks[2]["states"][1]["name"].should == "Stinky"
        tasks[2]["states"][0]["position"].should == 1
        tasks[2]["states"][1]["position"].should == 2
        tasks[2]["selected"].should == 2
        
        tasks[3]["id"].should_not be_nil
        tasks[3]["name"].should == "Make tea"
        tasks[3]["priority"].should == 3
        tasks[3]["states"].should be_nil

      end
      
      it "should return only info about a group by code" do
        get '/api/v1/group/ABCDEF'
        last_response.should be_ok
        attributes = JSON.parse(last_response.body)
        attributes["code"].should == "ABCDEF"
        attributes["name"].should == "The Tango Loft"
        attributes["created_at"].should_not be_blank      
        attributes["updated_at"].should_not be_blank

        attributes["tasks"].should be_nil
      end

      it "should return only info about a group by code" do
        get '/group/ABCDEF/tasks'
        last_response.should be_ok
        #puts last_response.body
      end
            
      
      it "should return a 404 for a group that doesn't exist" do
        get '/api/v1/group/foo'
        last_response.status.should == 404
        last_response.body.should == "Group \"foo\" not found"        
      end
      
      describe "/task" do              
        it "should return a task with a specific id" do
          get "/api/v1/group/ABCDEF/task/#{@task1.id}"      
          last_response.should be_ok
          attributes = JSON.parse(last_response.body)
          #puts attributes
          attributes["name"].should == "Dishwasher"
          attributes["states"][0]["name"].should == "Clean"
          attributes["states"][1]["name"].should == "Dirty"
          attributes["selected"].should == 1
        end   
      end
     
      describe "/member" do
        before(:each) do
          @member1 = Member.create(:name => "Raj",   :group => @group)
          @member2 = Member.create(:name => "Dave",  :group => @group)
        end
        it "should return a member with a specific id" do
          get "/api/v1/group/ABCDEF/member/#{@member2.id}"      
          last_response.should be_ok
          attributes = JSON.parse(last_response.body)
          #puts attributes
          attributes["name"].should == "Dave"
        end   
      end      
    end
    
  end

  describe "POST on /api/v1/group" do
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


    it "should create a new task for a group" do
      post '/api/v1/group/ABCDEF/task/new', {
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

    it "should create a new location for a group" do
      post '/api/v1/group/ABCDEF/location/new', {
        :name  => "Home",
        :latitude => "10.573",
        :longitude => "50.224"
      }.to_json
      last_response.should be_ok
    
      attributes = JSON.parse(last_response.body)
      attributes["name"].should == "Home"
      attributes["latitude"].should == 10.573
      attributes["longitude"].should == 50.224
    end
    
    it "should create a new member for a group" do
      post '/api/v1/group/ABCDEF/member/new', {
        :name  => "Raj",
      }.to_json
      last_response.should be_ok
    
      attributes = JSON.parse(last_response.body)
      attributes["name"].should == "Raj"
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
  
  describe "PUT on /api/v1/group/:code/task" do
    before :each do
      @group = Group.create(
        :code   => "ABCDEF",
        :name   => "The Tango Loft"
      )
      
      @task1 = Task.create(:name => "Dishwasher", :group => @group, :position => 1 )
      @states1 = %w[Clean Dirty].each_with_index {|s,i| State.create(:name => s, :task => @task1,:position => i+1)}
      @task1.update(:selected => 1)
      
      @task2 = Task.create(:name => "Laundry", :group => @group, :position => 2 )
      @states2 = %w[Fresh Stinky].each_with_index {|s,i| State.create(:name => s, :task => @task2,:position => i+1)}
      @task2.update(:selected => 2)

      @task3 = Task.create(:name => "Make tea", :group => @group, :position => 3, :priority => 3 )
       
    end
    
    it "should update a task" do
      put "/api/v1/group/ABCDEF/task/#{@task1.id}", {
        :name  => "Our Dishwasher",
        :states => [
          {:name => "Sparkling",:position => 1},
          {:name => "Dirty",:position => 2 },
        ]
      }.to_json
      last_response.should be_ok

      attributes = JSON.parse(last_response.body)
      attributes["name"].should == "Our Dishwasher"
      attributes["states"][0]["name"].should == "Sparkling"
      attributes["states"][0]["position"].should == 1
      attributes["states"][1]["name"].should == "Dirty"
      attributes["states"][1]["position"].should == 2
    end    

    describe 'update member' do
      before(:each) do
        @member1 = Member.create(:name => "Raj",   :group => @group)
        @member2 = Member.create(:name => "Dave",  :group => @group)
      end
      it "should update a member" do
        put "/api/v1/group/ABCDEF/member/#{@member1.id}", {
          :name  => "Van"
        }.to_json
        last_response.should be_ok
  
        attributes = JSON.parse(last_response.body)
        attributes["name"].should == "Van"
      end    
    end
       
    it "should delete a task" do
      delete "/api/v1/group/ABCDEF/task/#{@task1.id}"
      last_response.should be_ok

      get "/api/v1/group/ABCDEF/task/#{@task1.id}"      
      last_response.status.should == 404
      last_response.body.should == "Task #{@task1.id} not found"        

    end
  
  end
  

end
