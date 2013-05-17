module Keymaker::Serialization
  include ActiveModel::Serialization

  def self.included(base)
    base.define_model_callbacks :save, :create
  end

# TODO the problem is that it assumes you want to store a time stamp in anything with date, time etc
# but this breaks some things like Devise that creates null time stamps to verify user reg process
# commenting the the else/Time.now.utc prevents the created_at/updated_at to be initialized.
  COERCION_PROCS = Hash.new(->(v){v}).tap do |procs|
    procs[Integer] = ->(v){ v.to_i }
    procs[DateTime] = ->(v) do
      case v
      when Time
        Time.at(v)
      when String
        v.to_time
      else
        #Time.now.utc
      end
    end
  end

  def process_attrs(attrs)
    attrs = attrs.symbolize_keys
    self.class.properties.delete_if{|p| p == :node_id}.each do |property|
      if property == :active_record_id
        process_attr(property, attrs[:id].present? ? attrs[:id] : attrs[:active_record_id])
      else
        if attrs[property]
          process_attr(property, attrs[property])
        end
      end
    end
  end

  def process_attr(key, value)
    
    if key == 'updated_at' || key == 'created_at'
      value = Time.now.utc
    else
      send("#{key}=", coerce(value,self.class.property_traits[key]))
    end
  end

  def coerce(value,type)
    COERCION_PROCS[type].call(value)
  end

  def attributes
    Hash.new{|h,k| h[k] = send(k) }.tap do |hash|
      self.class.properties.each{|property| hash[property.to_s] }
    end
  end

end
