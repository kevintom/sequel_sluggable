module Sequel
  module Plugins

    # The Sluggable plugin creates hook that automatically sets 
    # 'slug' field to the slugged value of the column specified
    # by :source option.
    #
    # You need to have "target" column in your model.
    module Sluggable
      DEFAULT_TARGET_COLUMN = :slug
      DEFAULT_SLUG_LENGTH = 5
      # Plugin configuration
      def self.configure(model, opts={})
        model.sluggable_options = opts
        model.sluggable_options.freeze

        model.class_eval do
          # Sets the slug to the normalized URL friendly string
          #
          # Compute slug for the value
          #
          # @param [String] String to be slugged
          # @return [String]
          define_method("#{sluggable_options[:target]}=") do |value|
            if value.nil? and self.class.sluggable_options[:random_slug]
              slug = random_slug
              until self.class[self.class.sluggable_options[:target] => slug].nil?
                slug = random_slug
                #puts "RANDOM #{slug}"
              end
              #slug = random_slug until self.class[self.class.sluggable_options[:target] => slug].nil? if self.class.sluggable_options[:unique]
              #slug ||= random_slug
            else
              sluggator = self.class.sluggable_options[:sluggator]
              slug = sluggator.call(value, self)   if sluggator.respond_to?(:call)
              slug ||= self.send(sluggator, value) if sluggator
              slug ||= to_slug(value)
            end
            super(slug)
          end
        end

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

        # Propagate settings to the child classes
        #
        # @param [Class] Child class
        def inherited(klass)
          super
          klass.sluggable_options = self.sluggable_options.dup
        end

        # Set the plugin options
        #
        # Options:
        # @param [Hash] plugin options
        # @option frozen    [Boolean]      :Is slug frozen, default true
        # @option sluggator [Proc, Symbol] :Algorithm to convert string to slug.
        # @option source    [Symbol] :Column to get value to be slugged from.
        # @option target    [Symbol] :Column to write value of the slug to.
        def sluggable_options=(options)
          sluggator = options[:sluggator]
          if sluggator && !sluggator.is_a?(Symbol) && !sluggator.respond_to?(:call)
            raise ArgumentError, "If you provide :sluggator it must be Symbol or callable." 
          end
          options[:source]    = options[:source].to_sym if options[:source]
          options[:target]    = options[:target] ? options[:target].to_sym : DEFAULT_TARGET_COLUMN
          options[:frozen]    = options[:frozen].nil? ? true : !!options[:frozen]
          options[:slug_length] = options[:slug_length] ? options[:slug_length].to_i : DEFAULT_SLUG_LENGTH
          options[:random_slug] = options[:source].nil? && options[:sluggator].nil?
          options[:unique] = options[:unique].class == TrueClass if options[:unique]
          raise ArgumentError, "You must provide :source column" if !options[:random_slug] and options[:source].nil?
          options[:before_validate] = options[:before_validate].class == TrueClass if options[:before_validate]
          @sluggable_options  = options
        end
      end

      module InstanceMethods

        # Sets a slug column to the slugged value
        def before_validation
          super
          if self.class.sluggable_options[:before_validate]
            target = self.class.sluggable_options[:target]
            set_target_column unless self.send(target)
          end
        end
        
        def before_create
          super
          target = self.class.sluggable_options[:target]
          set_target_column unless self.send(target)
        end
        
        # Sets a slug column to the slugged value
        def before_update
          super
          target = self.class.sluggable_options[:target]
          frozen = self.class.sluggable_options[:frozen]
          set_target_column if !self.send(target) || !frozen
        end

        private

        # Generate slug from the passed value
        #
        # @param [String] String to be slugged
        # @return [String]
        def to_slug(value)
          value.chomp.downcase.gsub(/[^a-z0-9]+/,'-')
        end

        def random_slug
          # rails or ruby 1.9 dependency. sorry.
          SecureRandom.hex(self.class.sluggable_options[:slug_length])
        end
        
        # Sets target column with source column which 
        # effectively triggers slug generation
        def set_target_column
          target = self.class.sluggable_options[:target]
          source = self.class.sluggable_options[:source]
          self.send("#{target}=", source ? self.send(source) : nil)
        end

      end # InstanceMethods
    end # Sluggable
  end # Plugins
end # Sequel
