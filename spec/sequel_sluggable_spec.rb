require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Item < Sequel::Model; end

describe "SequelSluggable" do
  before(:each) do
    Item.plugin :sluggable,
                :source => :name,
                :target => :slug
  end

  it "should be loaded using Model.plugin" do
    Item.plugins.should include(Sequel::Plugins::Sluggable)
  end

  it "should add find_by_pk_or_slug" do
    Item.should respond_to(:find_by_pk_or_slug)
  end

  it "should add find_by_slug" do
    Item.should respond_to(:find_by_slug)
  end

  it "should generate slug when saved" do
    Item.create(:name => 'Pavel Kunc').slug.should eql 'pavel-kunc'
  end

  describe "lack of option handling" do
    before(:each) do
      class Item < Sequel::Model; end
      Item.plugin :sluggable
    end
    
    it 'should set a option for a random slug' do
      Item.sluggable_options[:random_slug].should be_true
    end
    
    it 'should have a slug length of 5' do
      Item.sluggable_options[:slug_length].should eql 5
    end
  end

  describe 'unique-ness handling' do
    before(:each) do
      class Item < Sequel::Model; end
      Item.plugin :sluggable, :unique => true
    end
    it 'should set a option for a unique slug' do
      Item.sluggable_options[:unique].should be_true
    end
  end
  
  describe 'before_validate handling' do
    before(:each) do
      class Item < Sequel::Model; end
      Item.plugin :sluggable, :before_validate => true
    end
    
    it 'should set an option for running in before_validation instead of before_create' do
      Item.sluggable_options[:before_validate].should be_true
    end
  end
  
  describe 'unique random slugs created in before_validate' do
    before(:each) do
      class Item < Sequel::Model; end
      Item.plugin :sluggable, :before_validate => true, :unique => true
    end
    
    it 'should have a unique slug' do
      Item.sluggable_options[:unique].should be_true
      SecureRandom = mock("fake random generator")
      SecureRandom.stub(:hex).and_return(rand(10))
      item1 = Item.create(:name => 'Pavel Kunc')
      item2 = Item.create(:name => 'Pavel Kunc')
      item1.slug.should_not eql item2.slug
    end
  end

  describe "options handling" do
    before(:each) do
      @sluggator = Proc.new {|value, model| value.chomp.downcase}
      class Item < Sequel::Model; end
      Item.plugin :sluggable,
                  :source    => :name,
                  :target    => :slug,
                  :sluggator => @sluggator,
                  :frozen    => false
    end

    it "should accept source option" do
      Item.sluggable_options[:source].should eql :name
    end

    it "should accept target option" do
      Item.sluggable_options[:target].should eql :slug
    end

    it "should accept sluggator option" do
      Item.sluggable_options[:sluggator].should eql @sluggator
    end

    it "should accept frozen option" do
      Item.sluggable_options[:frozen].should be_false
    end

    it "should have frozen true by default" do
      class Item < Sequel::Model; end
      Item.plugin :sluggable, :source => :name
      Item.sluggable_options[:frozen].should be_true
    end

    it "should require source option if not random" do
      class Item < Sequel::Model; end
      lambda { Item.plugin :sluggable, :sluggator => :does_not_exist }.should raise_error(ArgumentError, "You must provide :source column")
    end

    it "should default target option to :slug when not provided" do
      class Item < Sequel::Model; end
      Item.plugin :sluggable, :source => :name
      Item.sluggable_options[:target].should eql :slug
    end

    it "should require sluggator to be Symbol or callable" do
      class Item < Sequel::Model; end
      lambda { Item.plugin :sluggable, :source => :name, :sluggator => 'xy' }.should raise_error(ArgumentError, "If you provide :sluggator it must be Symbol or callable.")
    end

    it "should preserve options in sub classes" do
      class SubItem < Item; end
      SubItem.sluggable_options.should_not be_nil
    end

    it "should allow to change options for sub class" do
      class SubItem < Item; end
      SubItem.plugin :sluggable, :source => :test
      SubItem.sluggable_options[:source].should eql :test
    end

    it "should not mess with parent settings when inherited" do
      class SubItem < Item; end
      SubItem.plugin :sluggable, :source => :test
      SubItem.sluggable_options[:source].should eql :test
      Item.sluggable_options[:source].should eql :name
    end

    it "should not allow changing the options directly" do
      lambda { Item.sluggable_options[:source] = 'xy' }.should raise_error
    end
  end

  describe "#:target= method" do
    before(:each) do
      Item.plugin :sluggable,
                  :source => :name,
                  :target => :sluggie
    end

    it "should allow to set slug with Model#:target= method" do
      i = Item.new(:name => 'Pavel Kunc')
      i.sluggie = i.name
      i.sluggie.should eql 'pavel-kunc'
    end

    it "should work with different Model#:target= method than default" do
      Item.create(:name => 'Pavel Kunc').sluggie.should eql 'pavel-kunc'
    end
  end

  describe "::find_by_pk_or_slug" do
    it "should find model by slug" do
      item = Item.create(:name => 'Pavel Kunc')
      Item.find_by_pk_or_slug('pavel-kunc').should eql item
    end

    it "should find model by id" do
      item = Item.create(:name => 'Pavel Kunc')
      Item.find_by_pk_or_slug(item.id).should eql item
    end

    it "should return nil if model not found and searching by slug" do
      item = Item.create(:name => 'Pavel Kunc')
      Item.find_by_pk_or_slug('tonda-kunc').should be_nil
    end

    it "should return nil if model not found and searching by id" do
      item = Item.create(:name => 'Pavel Kunc')
      Item.find_by_pk_or_slug(1000).should be_nil
    end
  end

  describe "::find_by_slug" do
    it "should find model by slug" do
      item = Item.create(:name => 'Pavel Kunc')
      Item.find_by_slug('pavel-kunc').should eql item
    end

    it "should return nil if model not found" do
      item = Item.create(:name => 'Pavel Kunc')
      Item.find_by_slug('tonda-kunc').should be_nil
    end
  end

  describe "slug algorithm customization" do
    before(:each) do
      class Item < Sequel::Model; end
    end

    it "should use to_slug method on model if available" do
      Item.plugin :sluggable,
                  :source => :name,
                  :target => :slug
      Item.class_eval do
        def to_slug(v)
           v.chomp.downcase.gsub(/[^a-z0-9]+/,'_')
        end
      end
      Item.create(:name => 'Pavel Kunc').slug.should eql 'pavel_kunc'
    end

    it "should use only :sluggator proc if defined" do
      Item.plugin :sluggable,
                  :source    => :name,
                  :target    => :slug,
                  :sluggator => Proc.new {|value, model| value.chomp.downcase.gsub(/[^a-z0-9]+/,'_')}
      Item.create(:name => 'Pavel Kunc').slug.should eql 'pavel_kunc'
    end

    it "should use only :sluggator Symbol if defined" do
      Item.plugin :sluggable,
                  :source    => :name,
                  :target    => :slug,
                  :sluggator => :my_custom_sluggator
      Item.class_eval do
        def my_custom_sluggator(v)
           v.chomp.upcase.gsub(/[^a-zA-Z0-9]+/,'-')
        end
      end
      Item.create(:name => 'Pavel Kunc').slug.should eql 'PAVEL-KUNC'
    end
  end

  describe "slug generation and regeneration" do
    it "should generate slug when creating model and slug is not set" do
      Item.create(:name => 'Pavel Kunc').slug.should eql 'pavel_kunc'
    end

    it "should not regenerate slug when creating model and slug is set" do
      i = Item.new(:name => 'Pavel Kunc')
      i.slug = 'Kunc Pavel'
      i.save
      i.slug.should eql 'kunc_pavel'
    end

    it "should regenerate slug when updating model and slug is not frozen" do
      class Item < Sequel::Model; end
      Item.plugin :sluggable, :source => :name, :target => :slug, :frozen => false
      i = Item.create(:name => 'Pavel Kunc')
      i.update(:name => 'Kunc Pavel')
      i.slug.should eql 'kunc_pavel'
    end

    it "should not regenerate slug when updating model" do
      i = Item.create(:name => 'Pavel Kunc')
      i.update(:name => 'Kunc Pavel')
      i.slug.should eql 'pavel_kunc'
    end

  end
end
