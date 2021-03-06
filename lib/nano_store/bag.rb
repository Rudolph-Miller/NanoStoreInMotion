module NanoStore
  module BagInstanceMethods
    def self.included(base)
      base.class_eval do
        alias_method :saved, :savedObjects
        alias_method :unsaved, :unsavedObjects
        alias_method :removed, :removedObjects
        alias_method :size, :count
        alias_method :clear, :removeAllObjects
        alias_method :inflate, :inflateBag
        alias_method :deflate, :deflateBag
      end
    end

    def originalClassString
      'NSFNanoBag'
    end
    
    def changed?
      self.hasUnsavedChanges
    end

    def to_a
      self.savedObjects.values + self.unsavedObjects.values
    end

    ## Adding and Removing Objects
    
    # Add an object to bag
    # @return self
    def <<(object)
      error_ptr = Pointer.new(:id)
      self.addObject(object, error:error_ptr)
      raise NanoStoreError, error_ptr[0].description if error_ptr[0]
      self
    end

    # Add an object or array of objects to bag
    # Return the bag
    def +(object_or_array)
      error_ptr = Pointer.new(:id)
      if object_or_array.is_a?(Array)
        self.addObjectsFromArray(object_or_array, error:error_ptr)
      else
        self.addObject(object_or_array, error:error_ptr)
      end
      raise NanoStoreError, error_ptr[0].description if error_ptr[0]
      self
    end

    # Remove object from bag
    def delete(object)
      self.removeObject(object)
      self
    end
    
    # Remove object from bag with key
    # params: 
    # key - a key or array of keys
    def delete_key(key)
      if key.is_a?(Array)
        self.removeObjectsWithKeysInArray(key)
      else
        self.removeObjectWithKey(key)
      end
      self
    end
    
    # Remove an object or array of objects from bag
    # Return the bag
    def -(object_or_array)
      error_ptr = Pointer.new(:id)
      if object_or_array.is_a?(Array)
        self.removeObjectsInArray(object_or_array, error:error_ptr)
      else
        self.removeObject(object, error_ptr)
      end
      raise NanoStoreError, error_ptr[0].description if error_ptr[0]
      self
    end
    
    ## Saving, Reloading and Undoing

    def store=(store)
      store.addObject(self, error:nil)
    end

    def save
      self.store = NanoStore.shared_store unless self.store
      error_ptr = Pointer.new(:id)
      result = self.saveAndReturnError(error_ptr)
      raise NanoStoreError, error_ptr[0].description if error_ptr[0]
      result
    end

    def reload
      error_ptr = Pointer.new(:id)
      result = self.reloadBagWithError(error_ptr)
      raise NanoStoreError, error_ptr[0].description if error_ptr[0]
      result
    end

    def undo
      error_ptr = Pointer.new(:id)
      result = self.undoChangesWithError(error_ptr)
      raise NanoStoreError, error_ptr[0].description if error_ptr[0]
      result
    end
  end

  Bag = ::NSFNanoBag
end

class NSFNanoBag
  include NanoStore::BagInstanceMethods
end