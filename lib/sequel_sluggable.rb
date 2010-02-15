module Sequel
  module Plugins

    # The Sluggable plugin creates hook that automatically sets 
    # 'slug' field to the slugged value of the column specified
    # by :source option.
    #
    # You need to have "target" column in your model.
    module Sluggable
      DEFAULT_TARGET_COLUMN = :slug

      # Plugin configuration
      def self.configure(model, opts={})
        model.sluggable_options = opts
      end

      module ClassMethods
        attr_reader :sluggable_options

        # Finds model by slug or PK
        #
        # @return [Sequel::Model, nil]
        def find_by_pk_or_slug(value)
          value.to_s =~ /^\d+$/ ? self[value] : self.find_by_slug(value)
        end

        # Finds model by Slug column
        #
        # @return [Sequel::Model, nil]
        def find_by_slug(value)
          self[@sluggable_options[:target] => value.chomp]
        end

        # Set the plugin options
        #
        # Options:
        # @param [Hash] plugin options
        # @option source    [Symbol] :Column to get value to be slugged from.       
        # @option target    [Symbol] :Column to write value of the slug to.
        # @option sluggator [Proc]   :Algorithm to convert string to slug.
        def sluggable_options=(options)
          raise ArgumentError, "You must provide :source column" unless options[:source]
          sluggator = options[:sluggator]
          if sluggator && !sluggator.is_a?(Symbol) && !sluggator.respond_to?(:call)
            raise ArgumentError, "If you provide :sluggator it must be Symbol or callable." 
          end
          options[:source]    = options[:source].to_sym
          options[:target]    = options[:target] ? options[:target].to_sym : DEFAULT_TARGET_COLUMN
          @sluggable_options  = options
        end
      end

      module InstanceMethods

        # Sets a slug column to the slugged value
        def before_save
          super
          target = "#{self.class.sluggable_options[:target]}="
          source = self.class.sluggable_options[:source]
          self.send(target, self.send(source))
        end

        private

        # Sets the slug to the normalized URL friendly string
        #
        # Compute slug for the value
        #
        # @param [String] String to be slugged
        # @return [String]
        def slug=(value)
          sluggator = self.class.sluggable_options[:sluggator]
          slug = sluggator ? sluggator.call(value, self) : to_slug(value)
          super(slug)
        end

        # Generate slug from the passed value
        #
        # @param [String] String to be slugged
        # @return [String]
        def to_slug(value)
          value.chomp.downcase.gsub(/[^a-z0-9]+/,'-')
        end

      end # InstanceMethods
    end # Sluggable
  end # Plugins
end # Sequel
