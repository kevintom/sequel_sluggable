module Sequel::Plugins::Sluggable::SluggableRSpecHelper
  def it_should_behave_like_sluggable(klass)
    it "should have slug when created" do
      model = klass.make(klass.slug_source_column => 'Test String')
      model.slug.should eql 'test-string'
    end

    it "should update slug when #{klass.slug_source_column} is updated" do
      model = klass.make(klass.slug_source_column => 'Test String')
      lambda { model.update(klass.slug_source_column => 'Test String Two') }.should change(model,:slug).to('test-string-two')
    end

    it "should find #{klass} by it's ID" do
      model = klass.make(klass.slug_source_column => 'Test String')
      klass.find_by_id_or_slug(model.id).should eql model
    end

    it "should find #{klass} by it's slug" do
      model = klass.make(klass.slug_source_column => 'Test String')
      klass.find_by_id_or_slug('test-string').should eql model
    end
  end
end
