require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Item < Sequel::Model; end

describe "SequelSluggable" do
  before(:each) do
    Item.plugin :sluggable, :source => :name
  end

  it "should be loaded using Model.plugin" do
    Item.plugins.should include(Sequel::Plugins::Sluggable)
  end

  it "should add find_by_id_or_slug" do
    Item.should respond_to(:find_by_id_or_slug)
  end

  it "should accept extra options" do
    Item.slug_source_column.should eql :name
  end

  it "should generate slug when saved" do
    Item.create(:name => 'Pavel Kunc').slug.should eql 'pavel-kunc'
  end

  describe "::find_by_id_or_slug" do
    it "should find model by slug" do
      item = Item.create(:name => 'Pavel Kunc')
      Item.find_by_id_or_slug('pavel-kunc').should eql item
    end

    it "should find model by id" do
      item = Item.create(:name => 'Pavel Kunc')
      Item.find_by_id_or_slug(item.id).should eql item
    end
  end
end
