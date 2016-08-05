class Model
  attr_reader :errors, :created_at, :updated_at

  def initialize(attributes = {})
    self.attributes = attributes
  end

  def attributes=(attributes)
    self.class.fields.each do |f|
      v = attributes[f.key]
      v = attributes[f.key.to_s] if v.nil?

      if !f.type.is_a?(Array) && f.type < Model
        if v.is_a?(Array)
          v = v.map do |vv|
            if vv.is_a?(Hash)
              f.type.new(vv)
            else
              vv
            end
          end
        elsif v.is_a?(Hash)
          v = f.type.new(v)
        end
      end

      send("#{f.key}=", v)
    end

    @errors = nil
    @updated_at = Time.now
    @created_at = @updated_at if @created_at.nil?
  end

  def valid?
    @errors = []
    self.class.fields.each do |f|
      v = send(f.key)
      if v.nil? || (v.is_a?(String) && v.strip == '')
        @errors << "#{f.key} is required" if f.required
      elsif f.list
        if v.is_a?(Array)
          if v.empty?
            @errors << "#{f.key} must contain at least one element" if f.required
          else
            v.each_with_index do |vv, i|
              validate_value(@errors, f, vv, i)
            end
          end
        else
          @errors << "#{f.key} must be a list"
        end
      else
        validate_value(@errors, f, v)
      end
    end
    @errors.empty?
  end

  def to_hash
    self.class.fields.each_with_object({}) do |f, h|
      v = send(f.key)
      if v.is_a?(Model)
        v = v.to_hash
      elsif v.is_a?(Array)
        v = v.map do |vv|
          if vv.is_a?(Model)
            vv.to_hash
          else
            vv
          end
        end
      end
      h[f.key] = v unless v.nil? || (v.is_a?(Array) && v.empty?)
    end
  end

  private

  def validate_value(errors, field, v, index = nil)
    types = field.type.is_a?(Array) ? field.type : [field.type]
    if !types.any? { |type| v.is_a?(type) }
      errors << "#{error_prefix(field, index)} is invalid (#{types.join(', ')} required, got #{v.class})"
    elsif v.is_a?(Model) && !v.valid?
      v.errors.each do |e|
        errors << "#{error_prefix(field, index)}: #{e}"
      end
    elsif field.date && v !~ /^\d\d\d\d-\d\d-\d\d$/
      errors << "#{error_prefix(field, index)} must match YYYY-MM-DD"
    elsif field.value_in && !field.value_in.include?(v)
      errors << "#{error_prefix(field, index)} must be one of: #{field.value_in.join(', ')}"
    elsif field.callback
      e = field.callback.call(v)
      errors << "#{error_prefix(field, index)} #{e}" if e
    end
  end

  def error_prefix(field, index = nil)
    "#{field.key}#{index.nil? ? '' : " (#{index + 1})"}"
  end

  class << self
    Field = Struct.new(:key, :type, :required, :list, :date, :value_in, :callback)
    attr_accessor :fields

    def field(key, type, required: true, list: false, date: false, value_in: nil, &block)
      (@fields ||= []) << Field.new(key, type, required, list, date, value_in, block)
      attr_accessor(key)
    end
  end
end
