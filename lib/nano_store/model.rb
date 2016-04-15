module NanoStore
  module ModelInstanceMethods
    def save
      raise NanoStoreError, 'No store provided' unless self.class.store

      error_ptr = Pointer.new(:id)
      self.store.addObject(self, error:error_ptr)
      raise NanoStoreError, error_ptr[0].description if error_ptr[0]
      self
    end
  
    def delete
      raise NanoStoreError, 'No store provided' unless self.class.store

      error_ptr = Pointer.new(:id)
      self.store.removeObject(self, error: error_ptr)
      raise NanoStoreError, error_ptr[0].description if error_ptr[0]
      self
    end

    def store
      super || self.class.store
    end
  end

  module ModelClassMethods
    # initialize a new object
    def new(data={})
      data.keys.each { |k|
        unless self.attributes.member? k.to_sym
          raise NanoStoreError, "'#{k}' is not a defined attribute for this model"
        end
      }

      object = self.nanoObjectWithDictionary(data)
      object
    end
    
    # initialize a new object and save it
    def create(data={})
      object = self.new(data)
      object.save
    end

    def attribute(name)
      @attributes ||= []
      @attributes << name

      define_method(name) do |*args, &block|
        self.info[name]
      end

      define_method((name + "=").to_sym) do |*args, &block|
        self.info[name] = args[0]
      end
    end
    
    def attributes(*attrs)
      if attrs.size > 0
        attrs.each{|attr| attribute attr}
      else
        @attributes ||= []
      end
    end

    def store
      if @store.nil?
        return NanoStore.shared_store 
      end
      @store
    end

    def store=(store)
      @store = store
    end
    
    def count
      self.store.count(self)
    end
    
    def delete(*args)
      keys = find_keys(*args)
      self.store.delete_keys(keys)
    end
  end

  class Model < NSFNanoObject
    include NanoStore::ModelInstanceMethods
    extend NanoStore::ModelClassMethods
    extend NanoStore::FinderMethods

    include NanoStore::AssociationInstanceMethods
    extend NanoStore::AssociationClassMethods
  end
end
