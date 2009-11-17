module Sequel
  module Plugins
    # The Sluggable plugin creates hook that automatically sets 'slug' field to
    # the slugged value of the column specified by :source option.
    #
    # You need to have "slug" column in your model.
    #
    module Sluggable
      # Set the source column for the model.
      # Options:
      # * :source - The column to get value to be slugged from.
      def self.configure(model, opts={})
        model.slug_source_column = opts[:source]
      end

      module ClassMethods
        attr_accessor :slug_source_column

        # Finds model by slug or id
        #
        # ==== Returns
        # PhotoGallery
        def find_by_id_or_slug(value)
          filter = value.to_s =~ /^\d+$/ ? {:id => value} : {:slug => value.chomp}
          self[filter]
        end
      end

      module InstanceMethods

        # Sets slug column to the slugged value
        def before_save
          super
          self.slug = self.send(self.class.slug_source_column)
        end

        private

        # Sets the slug to the normalized URL friendly string
        #
        # Compute slug for the value
        #
        # ==== Parameters
        # v<String>:: String to be slugged
        #
        # ==== Returns
        # String:: Slug
        def slug=(v)
          super(to_slug(v))
        end

        # Generate slug from the passed value
        #
        # ==== Parameters
        # v<String>:: String to be slugged
        #
        # ==== Returns
        # String:: Slug
        def to_slug(v)
          v.chomp.downcase.gsub(/[^a-z0-9]+/,'-')
        end

      end # InstanceMethods
    end # Sluggable
  end # Plugins
end # Sequel
