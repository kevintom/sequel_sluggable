module Sequel::Plugins::Sluggable::RSpecHelper
  def it_should_behave_like_sluggable(klass)
    it "should have slug when created" do
      model = klass.make(klass.sluggable_options[:source] => 'Test String')
      model.slug.should eql 'test-string'
    end

    it "should not update slug by default when #{klass.sluggable_options[:source]} is updated" do
      model = klass.make(klass.sluggable_options[:source] => 'Test String')
      model.update(klass.sluggable_options[:source] => 'Test String Two')
      model.send(klass.sluggable_options[:target]).should eql 'test-string'
    end

    it "should find #{klass} by it's ID" do
      model = klass.make(klass.sluggable_options[:source] => 'Test String')
      klass.find_by_pk_or_slug(model.id).should eql model
    end

    it "should find #{klass} by it's slug" do
      model = klass.make(klass.sluggable_options[:source] => 'Test String')
      klass.find_by_pk_or_slug('test-string').should eql model
    end
  end
end
