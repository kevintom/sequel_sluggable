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

  describe "options handling" do
    before(:each) do
      @sluggator = Proc.new {|value, model| value.chomp.downcase}
      class Item < Sequel::Model; end
      Item.plugin :sluggable,
                  :source    => :name,
                  :target    => :slug,
                  :sluggator => @sluggator
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

    it "should require source option" do
      class Item < Sequel::Model; end
      lambda { Item.plugin :sluggable }.should raise_error(ArgumentError, "You must provide :source column")
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
      SubItem.sluggable_options[:source] = :test
      SubItem.sluggable_options[:source].should eql :test
      Item.sluggable_options[:source].should eql :name
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

end
